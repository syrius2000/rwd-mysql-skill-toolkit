"""ステップ 1: 数行の DDL 用サンプル SQL 生成とレコード数・重複数レポート。

目的:
  CP932 等の CSV を読み、LOAD DATA INFILE 雛形のサンプル SQL を出力する。
  あわせてレコード数と重複数をカウントし、ステップ 2 の完成版 SQL 生成の入力とする。
  レポートの duplicates は重複出現回数（余分な行の数）。ユニーク行数 = total − duplicates。

使い方:
  from flat_file_mysql.sample_sql import run_step1

  reports = run_step1([Path("a.csv"), Path("b.csv")], Path("./out"))
  # 各 CSV に対し out_dir に <stem>Import.sql を出力し、reports に total/duplicates/unique を返す。
"""

from datetime import datetime
from pathlib import Path
from typing import Any

def _read_head_lines(path: Path, encoding: str, n: int = 4) -> list[str]:
    lines: list[str] = []
    with path.open("r", encoding=encoding, errors="replace") as f:
        for _ in range(n):
            line = f.readline()
            if not line:
                break
            lines.append(line.rstrip("\n\r"))
    return lines


def _detect_delimiter(head_lines: list[str]) -> tuple[str, str]:
    if not head_lines:
        return ",", ","
    header = head_lines[0]
    candidates = [(",", header.count(",")), ("\t", header.count("\t")), ("|", header.count("|"))]
    delim, _ = max(candidates, key=lambda x: x[1])
    if delim == "\t":
        return "\t", "\\t"
    return delim, delim


def _detect_line_ending(path: Path, sample_size: int = 8192) -> tuple[str, str]:
    with path.open("rb") as f:
        sample = f.read(sample_size)
    crlf = sample.count(b"\r\n")
    lf = sample.count(b"\n") - crlf
    cr = sample.count(b"\r") - crlf
    if crlf > max(lf, cr):
        return "CRLF (DOS/Windows)", "\\r\\n"
    if lf > 0:
        return "LF (UNIX/Mac)", "\\n"
    if cr > 0:
        return "CR (Old Mac)", "\\r"
    return "UNKNOWN", "\\n"


def _truncate(line: str, max_len: int = 180) -> str:
    return line[:max_len] + " ... (truncated)" if len(line) > max_len else line


_CHARSET_MAP = {
    "utf-8": "utf8mb4", "utf8": "utf8mb4", "utf-8-sig": "utf8mb4",
    "cp932": "cp932", "shift_jis": "cp932", "shift-jis": "cp932",
    "euc_jp": "ujis", "euc-jp": "ujis",
}


def build_sample_sql(path: Path, encoding: str, head_lines: list[str]) -> str:
    """先頭行とエンコーディング・改行から LOAD DATA INFILE 用サンプル SQL 文字列を生成する。"""
    abs_path = path.resolve()
    line_ending_desc, line_ending_mysql = _detect_line_ending(path)
    delim_char, mysql_delim = _detect_delimiter(head_lines)
    enc_lower = (encoding or "").lower()
    mysql_charset = _CHARSET_MAP.get(enc_lower, "utf8mb4")
    fields = f"FIELDS TERMINATED BY '{mysql_delim}' OPTIONALLY ENCLOSED BY '\"' ESCAPED BY '\\\\'"
    parts = [
        f"-- 元ファイル: {abs_path}",
        f"-- 推定エンコーディング: {encoding}",
        f"-- 改行: {line_ending_desc}",
        f"-- 生成: {datetime.now().isoformat(timespec='seconds')}",
        "-- 先頭4行プレビュー:",
    ]
    for i, line in enumerate(head_lines, 1):
        parts.append(f"-- [{i}] {_truncate(line)}")
    parts.extend([
        "--",
        f"-- LOAD DATA INFILE '{abs_path}' INTO TABLE your_table_name",
        f"-- CHARACTER SET {mysql_charset}",
        f"-- {fields}",
        f"-- LINES TERMINATED BY '{line_ending_mysql}'",
        "-- IGNORE 1 LINES",
        "-- (col1, col2, ...);",
    ])
    return "\n".join(parts) + "\n"


def count_rows_and_duplicates(path: Path, encoding: str, delimiter: str) -> tuple[int, int]:
    """CSV のデータ行数（ヘッダ除く）と重複行数を返す。(total, duplicates)。
    duplicates は重複している出現回数（余分な行の数）。ユニーク行数 = total − duplicates。
    """
    import csv
    total = 0
    seen: set[tuple[str, ...]] = set()
    dup_count = 0
    with path.open("r", encoding=encoding, errors="replace") as f:
        reader = csv.reader(f, delimiter=delimiter)
        first = True
        for row in reader:
            if first:
                first = False
                continue
            total += 1
            key = tuple(row)
            if key in seen:
                dup_count += 1
            else:
                seen.add(key)
    return total, dup_count


def run_step1(csv_paths: list[Path], out_dir: Path) -> list[dict[str, Any]]:
    """各 CSV についてエンコード検証・サンプル SQL 出力・レコード数・重複数を返す。"""
    reports: list[dict[str, Any]] = []
    from flat_file_mysql.encoding import validate_encoding

    for path in csv_paths:
        ok, enc = validate_encoding(path)
        if not ok:
            reports.append({"path": path, "error": "エンコード検証失敗", "total": 0, "duplicates": 0, "unique": 0})
            continue
        head = _read_head_lines(path, enc, 4)
        delim_char, _ = _detect_delimiter(head)
        content = build_sample_sql(path, enc, head)
        out_name = f"{path.stem}Import.sql"
        out_path = out_dir / out_name
        out_path.write_text(content, encoding="utf-8")
        total, dups = count_rows_and_duplicates(path, enc, delim_char)
        reports.append({
            "path": path,
            "out_sql": out_path,
            "encoding": enc,
            "total": total,
            "duplicates": dups,
            "unique": total - dups,
            "error": None,
        })
    return reports
