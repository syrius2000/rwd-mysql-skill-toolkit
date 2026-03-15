"""ステップ 1 の E2E: サンプル CSV で step1 実行し、出力 SQL とレポートを検証。"""

import sys
import tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

# pyre-ignore[21]: Could not find import of flat_file_mysql.sample_sql
from flat_file_mysql.sample_sql import run_step1


def test_step1_sample_utf8():
    data_dir = Path(__file__).resolve().parent
    csv_path = data_dir / "sample_utf8.csv"
    assert csv_path.exists()
    with tempfile.TemporaryDirectory() as tmp:
        out = Path(tmp)
        reports = run_step1([csv_path], out)
        assert len(reports) == 1
        r = reports[0]
        assert r.get("error") is None
        assert r["total"] == 4
        assert r["duplicates"] == 1
        assert r["unique"] == 3
        sql_path = out / "sample_utf8Import.sql"
        assert sql_path.exists()
        content = sql_path.read_text(encoding="utf-8")
        assert "LOAD DATA" in content
        assert "id,name,value" in content or "foo" in content


if __name__ == "__main__":
    test_step1_sample_utf8()
    print("E2E step1: OK")
