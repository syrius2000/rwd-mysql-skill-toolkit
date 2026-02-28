"""エンコーディング検出・検証（標準ライブラリのみ、TRY_ENCODINGS 方式）。

目的:
  CSV 等のテキストファイルが CP932/UTF-8 等で読めるか検証し、
  サンプル SQL 生成や step1 パイプラインで利用する。

使い方:
  from flat_file_mysql.encoding import validate_encoding, detect_encoding

  ok, enc = validate_encoding(Path("data.csv"))   # 検証のみ
  enc = detect_encoding(Path("data.csv"))        # 推定エンコーディング取得（失敗時 'binary'）
"""

from pathlib import Path
from typing import Iterable

TRY_ENCODINGS = ["utf-8", "utf-8-sig", "cp932", "shift_jis", "euc_jp", "iso2022_jp"]


def validate_encoding(path: Path, encoding: str | None = None) -> tuple[bool, str]:
    """パイプライン用: ファイルが指定 encoding でデコード可能か検証。encoding 未指定時は TRY_ENCODINGS で試す。成功時 (True, enc)、失敗時 (False, '')。"""
    encodings = [encoding] if encoding else TRY_ENCODINGS
    data = _read_sample_bytes(path, sample_lines=10)
    for enc in encodings:
        try:
            data.decode(enc)
            return True, enc
        except (UnicodeDecodeError, LookupError):
            continue
    return False, ""


def _read_sample_bytes(path: Path, max_bytes: int = -1, sample_lines: int = 4) -> bytes:
    """先頭 sample_lines 行または max_bytes バイトを取得。"""
    if max_bytes < 0 and sample_lines < 0:
        return path.read_bytes()
    collected = bytearray()
    line_count = 0
    with path.open("rb") as f:
        while True:
            if sample_lines >= 0 and line_count >= sample_lines:
                break
            if max_bytes >= 0 and len(collected) >= max_bytes:
                break
            line = f.readline()
            if not line:
                break
            collected.extend(line)
            line_count += 1
    return bytes(collected)


def detect_encoding(
    path: Path,
    encodings: Iterable[str] | None = None,
    *,
    max_bytes: int = -1,
    sample_lines: int = 4,
) -> str:
    """指定パスのファイルを encodings の順に試し、最初に成功したものを返す。全て失敗なら 'binary'。"""
    encodings = encodings or TRY_ENCODINGS
    data = _read_sample_bytes(path, max_bytes=max_bytes, sample_lines=sample_lines)
    for enc in encodings:
        try:
            data.decode(enc)
            return enc
        except (UnicodeDecodeError, Exception):
            continue
    return "binary"
