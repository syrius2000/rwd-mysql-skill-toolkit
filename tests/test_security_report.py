"""
test_security_report.py
security-vulnerability-check スキルのレポート生成テスト
TDD RED: run_static_analysis.py の JSON 出力 + security_report.Rmd のレンダリング検証
"""
import json
import os
import subprocess
import sys
import tempfile
from pathlib import Path

WS = Path(__file__).resolve().parent.parent
SCRIPT = WS / ".agent" / "skills" / "security-vulnerability-check" / "scripts" / "run_static_analysis.py"
REPORT_RMD = WS / ".agent" / "skills" / "security-vulnerability-check" / "templates" / "security_report.Rmd"

pass_count = 0
fail_count = 0


def check(cond: bool, msg: str) -> None:
    global pass_count, fail_count
    if cond:
        print(f"[PASS] {msg}")
        pass_count += 1
    else:
        print(f"[FAIL] {msg}")
        fail_count += 1


def test_json_output_mode() -> None:
    """run_static_analysis.py が --json フラグで JSON ファイルを出力できること"""
    # テスト用の安全なPythonファイルを作成
    with tempfile.TemporaryDirectory() as tmpdir:
        sample_py = Path(tmpdir) / "sample.py"
        sample_py.write_text(
            'import os\npassword = "hardcoded_secret"\nprint(password)\n',
            encoding="utf-8",
        )
        json_out = Path(tmpdir) / "result.json"

        result = subprocess.run(
            [sys.executable, str(SCRIPT), str(sample_py), "--json", str(json_out)],
            capture_output=True,
            text=True,
            timeout=60,
        )

        check(json_out.exists(), "JSON output file created")

        if json_out.exists():
            data = json.loads(json_out.read_text(encoding="utf-8"))
            check("results" in data, "JSON has 'results' key")
            check("metrics" in data, "JSON has 'metrics' key")
            # hardcoded_secret は bandit B105 で検出されるはず
            if data.get("results"):
                severities = {r.get("issue_severity", "") for r in data["results"]}
                check(len(severities) > 0, "At least one severity level found")


def test_summary_csv_output() -> None:
    """run_static_analysis.py が --summary-csv で CSV 行を出力できること"""
    with tempfile.TemporaryDirectory() as tmpdir:
        sample_py = Path(tmpdir) / "sample.py"
        sample_py.write_text(
            'import subprocess\nsubprocess.call("ls -la", shell=True)\n',
            encoding="utf-8",
        )
        csv_out = Path(tmpdir) / "summary.csv"

        result = subprocess.run(
            [sys.executable, str(SCRIPT), str(sample_py), "--summary-csv", str(csv_out)],
            capture_output=True,
            text=True,
            timeout=60,
        )

        check(csv_out.exists(), "Summary CSV file created")

        if csv_out.exists():
            import csv
            with open(csv_out, encoding="utf-8") as f:
                reader = csv.DictReader(f)
                rows = list(reader)

            expected_cols = {"target_path", "n_high", "n_medium", "n_low", "top3_issues", "scan_tool"}
            actual_cols = set(rows[0].keys()) if rows else set()
            for col in expected_cols:
                check(col in actual_cols, f"CSV column '{col}' exists")

            if rows:
                row = rows[0]
                check(row["scan_tool"] == "bandit", "scan_tool is 'bandit'")
                check(int(row["n_high"]) >= 0, "n_high is non-negative")
                check(int(row["n_medium"]) >= 0, "n_medium is non-negative")
                check(int(row["n_low"]) >= 0, "n_low is non-negative")


def test_report_rmd_exists() -> None:
    """security_report.Rmd テンプレートが存在し必要なチャンクを含むこと"""
    check(REPORT_RMD.exists(), "security_report.Rmd exists")

    if REPORT_RMD.exists():
        txt = REPORT_RMD.read_text(encoding="utf-8")
        check("severity" in txt.lower(), "Rmd mentions severity")
        check("params" in txt, "Rmd has params section")
        check("ggplot" in txt, "Rmd uses ggplot")


def test_report_render() -> None:
    """security_report.Rmd が実際にレンダリングできること"""
    if not REPORT_RMD.exists():
        check(False, "security_report.Rmd not found, skip render test")
        return

    with tempfile.TemporaryDirectory() as tmpdir:
        # bandit JSON サンプルを作成
        sample_json = Path(tmpdir) / "bandit_result.json"
        sample_data = {
            "results": [
                {
                    "filename": "/tmp/sample.py",
                    "issue_severity": "HIGH",
                    "issue_confidence": "HIGH",
                    "issue_text": "Possible hardcoded password",
                    "issue_cwe": {"id": 259, "link": ""},
                    "test_id": "B105",
                    "test_name": "hardcoded_password_string",
                    "line_number": 2,
                    "line_range": [2],
                },
                {
                    "filename": "/tmp/sample.py",
                    "issue_severity": "MEDIUM",
                    "issue_confidence": "HIGH",
                    "issue_text": "subprocess call with shell=True",
                    "issue_cwe": {"id": 78, "link": ""},
                    "test_id": "B602",
                    "test_name": "subprocess_popen_with_shell_equals_true",
                    "line_number": 5,
                    "line_range": [5],
                },
            ],
            "metrics": {
                "_totals": {
                    "SEVERITY.HIGH": 1,
                    "SEVERITY.MEDIUM": 1,
                    "SEVERITY.LOW": 0,
                    "CONFIDENCE.HIGH": 2,
                    "loc": 10,
                    "nosec": 0,
                }
            },
        }
        sample_json.write_text(json.dumps(sample_data), encoding="utf-8")

        html_out = Path(tmpdir) / "report.html"
        render_cmd = [
            "Rscript", "-e",
            f'rmarkdown::render("{REPORT_RMD}", output_file="{html_out}", '
            f'params=list(json_path="{sample_json}", target_label="test_sample"), '
            f'quiet=TRUE)',
        ]
        result = subprocess.run(render_cmd, capture_output=True, text=True, timeout=120)

        check(html_out.exists(), "HTML report rendered successfully")

        if html_out.exists():
            html_txt = html_out.read_text(encoding="utf-8")
            check("HIGH" in html_txt, "HTML contains HIGH severity")
            check("B105" in html_txt or "hardcoded" in html_txt.lower(),
                  "HTML contains issue detail")


if __name__ == "__main__":
    test_json_output_mode()
    test_summary_csv_output()
    test_report_rmd_exists()
    test_report_render()

    print(f"\n--- Results: {pass_count} passed, {fail_count} failed ---")
    if fail_count > 0:
        print("FAIL: some security report tests failed.")
        sys.exit(1)
    else:
        print("OK: security report tests passed.")
