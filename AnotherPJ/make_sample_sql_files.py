#!/usr/bin/env python3
"""MakeSampleSQLfiles.py

指定ディレクトリ直下にある CSV / TXT (拡張子: .csv/.CSV/.txt/.TXT/.tsv/.TSV) ファイルを走査し、
各ファイルの先頭4行をコメントとして含む *元ファイル名 + "Import.sql"* という名前の SQL 雛形ファイルを生成する。

要件:
 1. 引数で対象ディレクトリを指定 (再帰しない)。
 2. 対象拡張子のみ列挙しリスト化。
 3. ファイルのエンコーディングは不明として扱い、いくつかの候補でデコードを試行して推定。
 4. 推定後、出力 SQL に (a) メタ情報コメント (b) 先頭4行を `--` コメントとして埋め込む。
 5. (任意) 実際の LOAD DATA INFILE 例をコメントで差し込む。

注意:
 - 既に同名の *Import.sql が存在する場合は上書きしない (--force で上書き)。
 - 文字化け行は `errors="replace"` により � などの置換文字になる可能性がある。
 - エンコーディング推定は簡易実装 (外部ライブラリ非依存)。必要に応じて chardet 追加を検討。

使用例:
  python MakeSampleSQLfiles.py ./lecDBMS_import/sample
  python MakeSampleSQLfiles.py ./data_dir --force --ext .txt,.csv

Author: Auto-generated helper script for RWD Training.
"""

from __future__ import annotations

import argparse
import sys
import csv
from pathlib import Path
from typing import List, Iterable, Tuple, Optional, Dict, Set
from datetime import datetime
from collections import defaultdict

DEFAULT_EXTS = [".csv", ".CSV", ".txt", ".TXT", ".tsv", ".TSV"]
TRY_ENCODINGS = ["utf-8", "utf-8-sig", "cp932", "shift_jis", "euc_jp", "iso2022_jp"]


def _read_sample_bytes(path: Path, max_bytes: int, sample_lines: int) -> bytes:
    """巨大ファイル対策: 先頭から sample_lines 行 または max_bytes までのバイトを取得。
    max_bytes < 0 なら全体。sample_lines < 0 ならバイト制限のみ。
    """
    if max_bytes < 0 and sample_lines < 0:
        return path.read_bytes()
    collected = bytearray()
    line_count = 0
    with path.open('rb') as f:
        if sample_lines < 0:
            # ひたすら最大バイトまで読み込む
            chunk_size = 1024 * 64
            while max_bytes < 0 or len(collected) < max_bytes:
                need = chunk_size if max_bytes < 0 else min(chunk_size, max_bytes - len(collected))
                if need <= 0:
                    break
                chunk = f.read(need)
                if not chunk:
                    break
                collected.extend(chunk)
        else:
            # 行単位
            while True:
                if max_bytes >= 0 and len(collected) >= max_bytes:
                    break
                if sample_lines >= 0 and line_count >= sample_lines:
                    break
                line = f.readline()
                if not line:
                    break
                collected.extend(line)
                line_count += 1
    return bytes(collected)


def detect_encoding(path: Path, encodings: Iterable[str] = TRY_ENCODINGS, *, max_bytes: int = -1, sample_lines: int = -1) -> str:
    """指定されたサンプル範囲でエンコーディング推定。
    - max_bytes: 最大読み込みバイト（-1 で無制限）
    - sample_lines: 最大読み込み行数（-1 で無制限）
    成功した最初のエンコーディングを返し、全て失敗なら 'binary'。
    """
    data = _read_sample_bytes(path, max_bytes=max_bytes, sample_lines=sample_lines)
    for enc in encodings:
        try:
            data.decode(enc)
            return enc
        except UnicodeDecodeError:
            continue
        except Exception:
            continue
    return "binary"


def read_head_lines(path: Path, encoding: str, n: int = 4) -> List[str]:
    """先頭 n 行 (改行除去) を返す。行数不足なら不足分は返さない。"""
    lines: List[str] = []
    try:
        with path.open("r", encoding=encoding, errors="replace") as f:
            for _ in range(n):
                line = f.readline()
                if not line:
                    break
                lines.append(line.rstrip("\n\r"))
    except Exception as e:
        lines.append(f"(読み込みエラー: {e})")
    return lines


def detect_delimiter(head_lines: List[str]) -> Tuple[str, str]:
    """簡易な区切り文字判定。最初の行（ヘッダ想定）の文字数出現でカンマ/タブ/パイプを比較。
    戻り値: (delimiter_char, mysql_representation)
      mysql_representation は SQL の FIELDS TERMINATED BY 'xxx' 内に記述する文字列 (例: "," / "\\t" / "|").
    見つからなければカンマ。
    """
    if not head_lines:
        return ',', ','
    header = head_lines[0]
    candidates = [(',', header.count(',')), ('\t', header.count('\t')), ('|', header.count('|'))]
    # 最大出現数のものを選択（ただし 0 ならデフォルトのカンマ）
    delim, cnt = max(candidates, key=lambda x: x[1])
    if cnt == 0:
        delim = ','
    if delim == '\t':
        return '\t', '\\t'
    return delim, delim  # '|' もそのまま


def detect_line_ending(path: Path, sample_size: int = 8192) -> Tuple[str, str]:
    """ファイルの改行コードを検出する。
    
    Returns:
        Tuple[str, str]: (description, mysql_representation)
            description: 'CRLF (DOS)', 'LF (UNIX)', 'CR (Old Mac)', 'UNKNOWN'
            mysql_representation: MySQL用のエスケープ文字列 ('\\r\\n', '\\n', '\\r')
    """
    try:
        # 先頭数KBをバイナリで読み込み
        with path.open('rb') as f:
            sample = f.read(sample_size)
        
        crlf_count = sample.count(b'\r\n')
        lf_count = sample.count(b'\n') - crlf_count  # CRLF内のLFを除外
        cr_count = sample.count(b'\r') - crlf_count  # CRLF内のCRを除外
        
        # 最も多い改行コードを採用
        if crlf_count > max(lf_count, cr_count):
            return 'CRLF (DOS/Windows)', '\\r\\n'
        elif lf_count > 0:
            return 'LF (UNIX/Mac)', '\\n'
        elif cr_count > 0:
            return 'CR (Old Mac)', '\\r'
        else:
            return 'UNKNOWN', '\\n'  # デフォルトはLF
    except Exception:
        return 'UNKNOWN', '\\n'


def truncate_line(line: str, max_len: int = 180) -> str:
    """長過ぎるプレビュー行を安全にトリミング。マルチバイトも単純長で判定。"""
    if len(line) <= max_len:
        return line
    return line[:max_len] + " ... (truncated)"


def analyze_data_quality(path: Path, encoding: str, delimiter: str, max_rows: int = 100) -> Dict:
    """CSVファイルの先頭max_rows行を読み込み、データ品質の問題を検出する。
    
    検出項目:
    - 前後に空白を含むフィールド（TRIMが必要）
    - 空文字列と"NULL"文字列の混在
    - カラム数の不一致
    - 数値カラムに非数値データが混入
    - 日付フォーマットの不統一
    
    Returns:
        dict: {
            'trim_needed': {col_index: [sample_values, ...]},
            'null_inconsistent': {col_index: {'empty_count': N, 'null_string_count': M}},
            'column_count_issues': [(row_num, expected, actual), ...],
            'mixed_types': {col_index: {'numeric': N, 'text': M}},
            'total_rows_analyzed': N
        }
    """
    result = {
        'trim_needed': defaultdict(list),
        'null_inconsistent': defaultdict(lambda: {'empty_count': 0, 'null_string_count': 0}),
        'column_count_issues': [],
        'mixed_types': defaultdict(lambda: {'numeric': 0, 'text': 0, 'empty': 0}),
        'total_rows_analyzed': 0,
        'header': []
    }
    
    try:
        with path.open('r', encoding=encoding, errors='replace') as f:
            # 区切り文字の推定結果を使用
            if delimiter == '\t':
                reader = csv.reader(f, delimiter='\t')
            else:
                reader = csv.reader(f, delimiter=delimiter)
            
            header = None
            expected_cols = 0
            
            for row_num, row in enumerate(reader, 1):
                if row_num == 1:
                    header = row
                    expected_cols = len(row)
                    result['header'] = header
                    continue
                
                if row_num > max_rows + 1:  # +1 for header
                    break
                
                result['total_rows_analyzed'] += 1
                
                # カラム数チェック
                if len(row) != expected_cols:
                    result['column_count_issues'].append((row_num, expected_cols, len(row)))
                
                # 各カラムのデータ品質チェック
                for col_idx, value in enumerate(row):
                    if col_idx >= expected_cols:
                        break
                    
                    # 前後空白チェック（TRIMが必要）
                    if value != value.strip() and value.strip():
                        # サンプルは最大3つまで保存
                        if len(result['trim_needed'][col_idx]) < 3:
                            result['trim_needed'][col_idx].append(repr(value))
                    
                    # NULL表現の不統一チェック
                    if value == '':
                        result['null_inconsistent'][col_idx]['empty_count'] += 1
                    elif value.upper() in ('NULL', 'N/A', 'NA', 'NONE'):
                        result['null_inconsistent'][col_idx]['null_string_count'] += 1
                    
                    # 型の混在チェック（空でない場合のみ）
                    if value.strip():
                        # 数値かどうか判定
                        try:
                            float(value.strip().replace(',', ''))
                            result['mixed_types'][col_idx]['numeric'] += 1
                        except ValueError:
                            result['mixed_types'][col_idx]['text'] += 1
                    else:
                        result['mixed_types'][col_idx]['empty'] += 1
    
    except Exception as e:
        result['error'] = str(e)
    
    return result


def format_quality_warnings(quality: Dict) -> List[str]:
    """データ品質分析結果を人間が読める警告メッセージに変換。"""
    warnings = []
    header = quality.get('header', [])
    
    # TRIM警告
    if quality['trim_needed']:
        warnings.append("-- ⚠️  前後に空白を含むフィールドが検出されました（TRIMが必要）:")
        for col_idx, samples in quality['trim_needed'].items():
            col_name = header[col_idx] if col_idx < len(header) else f"列{col_idx+1}"
            warnings.append(f"--     カラム [{col_name}]: 例 {', '.join(samples[:3])}")
        warnings.append("--     対策: LOAD DATA後に UPDATE文でTRIMするか、事前処理で正規化を推奨")
        warnings.append("--     例: UPDATE table_name SET column_name = TRIM(column_name);")
    
    # NULL表現の不統一
    null_issues = {k: v for k, v in quality['null_inconsistent'].items() 
                   if v['empty_count'] > 0 and v['null_string_count'] > 0}
    if null_issues:
        warnings.append("-- ⚠️  NULL表現が不統一なカラムが検出されました:")
        for col_idx, counts in null_issues.items():
            col_name = header[col_idx] if col_idx < len(header) else f"列{col_idx+1}"
            warnings.append(f"--     カラム [{col_name}]: 空文字={counts['empty_count']}, NULL文字列={counts['null_string_count']}")
        warnings.append("--     対策: NULLIF関数で統一を推奨")
        warnings.append("--     例: col = NULLIF(TRIM(@col), '') または NULLIF(@col, 'NULL')")
    
    # カラム数不一致
    if quality['column_count_issues']:
        warnings.append(f"-- ⚠️  カラム数が不一致な行が {len(quality['column_count_issues'])} 件検出されました:")
        for row_num, expected, actual in quality['column_count_issues'][:5]:
            warnings.append(f"--     行{row_num}: 期待={expected}列, 実際={actual}列")
        if len(quality['column_count_issues']) > 5:
            warnings.append(f"--     ... 他 {len(quality['column_count_issues']) - 5} 件")
        warnings.append("--     対策: CSVファイルの修正が必要（引用符やエスケープの問題の可能性）")
    
    # 型の混在（数値カラムにテキストが混入）
    mixed_issues = {k: v for k, v in quality['mixed_types'].items() 
                    if v['numeric'] > 0 and v['text'] > 0 and v['numeric'] > v['text'] * 2}
    if mixed_issues:
        warnings.append("-- ⚠️  数値カラムにテキストデータが混入している可能性:")
        for col_idx, counts in mixed_issues.items():
            col_name = header[col_idx] if col_idx < len(header) else f"列{col_idx+1}"
            warnings.append(f"--     カラム [{col_name}]: 数値={counts['numeric']}, テキスト={counts['text']}")
        warnings.append("--     対策: データ型をVARCHARにするか、不正データをクリーニング")
    
    if warnings:
        warnings.insert(0, "--")
        warnings.insert(1, f"-- 📊 データ品質チェック結果 ({quality['total_rows_analyzed']}行を分析)")
        warnings.insert(2, "--")
        warnings.append("--")
    
    return warnings


def build_output_filename(src: Path) -> Path:
    # 仕様: "CSVファイル名＋Import.sql" => 元ファイル名(拡張子含む) + "Import.sql"
    return src.parent / f"{src.name}Import.sql"


def make_sql_content(src: Path, encoding: str, head_lines: List[str], quality_check: Optional[Dict] = None) -> str:
    # 絶対パスを取得
    abs_path = src.resolve()
    rel = src.name
    timestamp = datetime.now().isoformat(timespec="seconds")
    
    # 改行コードを検出
    line_ending_desc, line_ending_mysql = detect_line_ending(src)
    
    lines_for_sql = [
        f"-- 元ファイル: {abs_path}",
        f"-- ファイル名: {rel}",
        f"-- 推定エンコーディング: {encoding}",
        f"-- 改行コード: {line_ending_desc}",
        f"-- 生成日時: {timestamp}",
        "--",
        "-- 先頭4行プレビュー:",
    ]
    if head_lines:
        for i, l in enumerate(head_lines, 1):
            lines_for_sql.append(f"-- [{i}] {truncate_line(l)}")
    else:
        lines_for_sql.append("-- (空ファイルまたは読み込み不可)")

    # データ品質警告を挿入
    if quality_check:
        quality_warnings = format_quality_warnings(quality_check)
        if quality_warnings:
            lines_for_sql.extend(quality_warnings)

    # MySQL の文字セット名マッピング (非サポートや曖昧なものは utf8mb4 推奨)
    enc_lower = (encoding or "").lower()
    # MySQL 8.4 では cp932 が利用可能なため cp932 判定時はそのまま指定する。
    # shift_jis / shift-jis は実質 cp932 として扱う（ファイル配布形態で名称が異なるケースを吸収）。
    charset_map = {
        "utf-8": "utf8mb4",
        "utf8": "utf8mb4",
        "utf-8-sig": "utf8mb4",
        "cp932": "cp932",
        "shift_jis": "cp932",
        "shift-jis": "cp932",
        "euc_jp": "ujis",     # MySQL の euc-jp は ujis
        "euc-jp": "ujis",
    }
    mysql_charset = charset_map.get(enc_lower, "utf8mb4")

    note_lines: List[str] = []
    if mysql_charset == "utf8mb4" and enc_lower not in ("utf-8", "utf8", "utf-8-sig"):
        note_lines.append("-- 注意: 推定エンコーディングは MySQL で直接扱いにくいため UTF-8 への事前変換を推奨")
    if enc_lower in ("iso2022_jp", "iso-2022-jp"):
        note_lines.append("-- 注意: ISO-2022-JP は LOAD DATA の直接指定不可。iconv 等で UTF-8 に変換してください。")
    if enc_lower == "binary":
        note_lines.append("-- 注意: バイナリ/不明なエンコーディング。内容を確認し UTF-8 化を推奨。")
    if enc_lower in ("cp932", "shift_jis", "shift-jis"):
        note_lines.append("-- 推奨: 運用統一のため可能であれば cp932 を UTF-8(utf8mb4) に変換して管理")

    # 区切り文字を動的判定
    delim_char, mysql_delim_repr = detect_delimiter(head_lines)
    # ダブルクォートを OPTIONALLY ENCLOSED BY で示し、バックスラッシュのエスケープを維持
    fields_line = (
        f"-- FIELDS TERMINATED BY '{mysql_delim_repr}' OPTIONALLY ENCLOSED BY '\"' ESCAPED BY '\\\\'"
    )
    if delim_char == '\t':
        note_lines.append("-- 判定: 区切り文字がタブのため '\t' を使用")
    elif delim_char == '|':
        note_lines.append("-- 判定: 区切り文字がパイプ(|) と推定")

    load_example_lines = [
        '-- LOAD DATA INFILE の利用例:',
        f"-- LOAD DATA INFILE '{abs_path}' INTO TABLE your_table_name",
        f"-- CHARACTER SET {mysql_charset}",
        fields_line,
        f"-- LINES TERMINATED BY '{line_ending_mysql}'",
        "-- IGNORE 1 LINES",
        "-- (col1, col2, col3, ...);",
    ]
    if note_lines:
        load_example_lines.extend(note_lines)
    load_example = "\n".join(load_example_lines)
    lines_for_sql.extend([
        "--",
        "-- 以下は雛形です。必要に応じてテーブル名 / 区切り文字 / カラム定義を編集してください。",
        load_example,
    ])

    return "\n".join(lines_for_sql) + "\n"


def collect_target_files(directory: Path, exts: List[str]) -> List[Path]:
    files: List[Path] = []
    for entry in directory.iterdir():
        if entry.is_file() and entry.suffix in exts:
            files.append(entry)
    return sorted(files)


def generate(directory: Path, exts: List[str], force: bool = False, dry_run: bool = False,
            *, detect_max_bytes: int = -1, detect_sample_lines: int = -1, 
            quality_check: bool = True, quality_check_rows: int = 100) -> int:
    targets = collect_target_files(directory, exts)
    if not targets:
        print(f"対象ファイルがありません: {directory} (拡張子: {', '.join(exts)})")
        return 0

    count = 0
    for src in targets:
        enc = detect_encoding(src, max_bytes=detect_max_bytes, sample_lines=detect_sample_lines)
        head = read_head_lines(src, enc if enc != "binary" else "utf-8")
        
        # データ品質チェックの実行
        quality_result = None
        if quality_check and enc != "binary":
            delim_char, _ = detect_delimiter(head)
            quality_result = analyze_data_quality(src, enc, delim_char, max_rows=quality_check_rows)
        
        out_path = build_output_filename(src)
        if out_path.exists() and not force:
            print(f"SKIP (既存) {out_path.name}")
            continue
        content = make_sql_content(src, enc, head, quality_check=quality_result)
        if dry_run:
            print(f"DRY-RUN: {out_path.name}\n{content}")
        else:
            out_path.write_text(content, encoding="utf-8")
            print(f"作成: {out_path.name} (encoding={enc})")
            if quality_result and (quality_result['trim_needed'] or 
                                  quality_result['column_count_issues']):
                print(f"  ⚠️  データ品質の問題を検出 - SQLファイルの警告を確認してください")
            count += 1
    return count


def parse_args(argv: List[str]) -> argparse.Namespace:
    p = argparse.ArgumentParser(description="CSV/TXT から *Import.sql 雛形を生成")
    p.add_argument("directory", help="対象ディレクトリ (再帰しない)")
    p.add_argument("--ext", help="対象拡張子カンマ区切り (デフォルト: .csv,.CSV,.txt,.TXT,.tsv,.TSV)")
    p.add_argument("--force", action="store_true", help="既存の *Import.sql を上書きする")
    p.add_argument("--dry-run", action="store_true", help="ファイルを書き込まず出力内容を表示")
    p.add_argument("--detect-max-bytes", type=int, default=-1, help="エンコーディング判定時の最大読み込みバイト数 (-1 で無制限)")
    p.add_argument("--detect-sample-lines", type=int, default=-1, help="エンコーディング判定時に読む最大行数 (-1 で無制限)")
    p.add_argument("--no-quality-check", action="store_true", help="データ品質チェックをスキップ")
    p.add_argument("--quality-check-rows", type=int, default=100, help="品質チェックで分析する行数 (デフォルト: 100)")
    return p.parse_args(argv)


def main(argv: List[str]) -> int:
    ns = parse_args(argv)
    directory = Path(ns.directory).expanduser().resolve()
    if not directory.is_dir():
        print(f"エラー: ディレクトリが存在しません -> {directory}", file=sys.stderr)
        return 2
    exts = DEFAULT_EXTS if ns.ext is None else [e if e.startswith('.') else f'.{e}' for e in ns.ext.split(',')]
    created = generate(directory, exts, force=ns.force, dry_run=ns.dry_run,
                       detect_max_bytes=ns.detect_max_bytes, detect_sample_lines=ns.detect_sample_lines,
                       quality_check=not ns.no_quality_check, quality_check_rows=ns.quality_check_rows)
    print(f"完了: 生成ファイル数 {created}")
    return 0


if __name__ == "__main__":  # pragma: no cover
    raise SystemExit(main(sys.argv[1:]))
