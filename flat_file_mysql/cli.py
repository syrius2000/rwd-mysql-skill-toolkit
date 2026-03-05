#!/usr/bin/env python3
"""CP932 CSV → MySQL 投入パイプラインの CLI エントリ。

目的:
  ステップ 1（サンプル SQL＋レポート）とステップ 3（SQL 実行・件数比較）を
  一つのエントリで実行する。ステップ 2 は手動（プロンプトで完成版 SQL 生成）。

使い方（プロジェクトルートを cwd に推奨）:
  # ステップ 1: サンプル SQL とレポート出力（既定: ./skill_output/step1_sample_sql）
  python3 -m flat_file_mysql.cli step1 a.csv b.csv
  python3 -m flat_file_mysql.cli step1 a.csv -o ./out

  # ステップ 3: 完成版 SQL を DB で実行（mysql が PATH にあること）
  python3 -m flat_file_mysql.cli step3 complete.sql -d mydb
  python3 -m flat_file_mysql.cli step3 complete.sql -d mydb --table mytbl --expected-count 100

  # パイプライン: step1 のみ、または --run-step3 で step3 まで
  python3 -m flat_file_mysql.cli pipeline a.csv
  python3 -m flat_file_mysql.cli pipeline a.csv --run-step3 --sql complete.sql -d mydb
"""

import argparse
from pathlib import Path


def _cmd_step1(args: argparse.Namespace) -> int:
    """ステップ 1: サンプル SQL 生成＋レコード数・重複数レポート。"""
    from flat_file_mysql.sample_sql import run_step1

    for p in args.csv_paths:
        if not p.exists():
            print(f"Error: not found: {p}")
            return 1
    out_dir = args.out_dir.resolve()
    out_dir.mkdir(parents=True, exist_ok=True)
    reports = run_step1(list(args.csv_paths), out_dir)
    has_error = False
    for r in reports:
        if r.get("error"):
            print(f"Error: {r['path']} -> {r['error']}")
            has_error = True
        else:
            print(f"  {r['path'].name} -> {r['out_sql'].name} (encoding={r['encoding']}, total={r['total']}, duplicates={r['duplicates']}, unique={r['unique']})")
    print("--- レポート ---")
    for r in reports:
        if r.get("error"):
            print(f"  {r['path'].name}: エラー")
        else:
            print(f"  {r['path'].name}: レコード数={r['total']}, 重複数={r['duplicates']}, ユニーク数={r['unique']}")
    return 1 if has_error else 0


def _cmd_step3(args: argparse.Namespace) -> int:
    """ステップ 3: 完成版 SQL の指定 DB への実行。オプションで件数比較。"""
    import os
    from flat_file_mysql.execute_sql import get_table_count, run_sql_file

    password = getattr(args, "password", None) or os.environ.get("MYSQL_PASSWORD", "")
    ok, err = run_sql_file(
        args.sql_file,
        args.database,
        host=args.host,
        port=args.port,
        user=args.user,
        password=password,
    )
    if not ok:
        print(f"Error: {err}")
        return 1
    print(f"OK: {args.sql_file} -> {args.database}")
    table = getattr(args, "table", None)
    expected = getattr(args, "expected_count", None)
    if table:
        cnt, err2 = get_table_count(
            args.database, table, host=args.host, port=args.port, user=args.user, password=password,
        )
        if err2:
            print(f"Warning: 件数取得失敗 ({table}): {err2}")
        else:
            print(f"投入件数: {cnt}")
            if expected is not None and cnt != expected:
                print(f"Error: 期待値={expected}, 実際={cnt}")
                return 1
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(
        description="CP932 CSV を MySQL に投入する CLI（ステップ 1 / 3）"
    )
    subparsers = parser.add_subparsers(dest="command", required=True)

    p1 = subparsers.add_parser("step1", help="サンプル SQL 生成＋レポート（複数 CSV 対応）")
    p1.add_argument("csv_paths", type=Path, nargs="+", help="対象 CSV ファイル")
    p1.add_argument(
        "-o",
        "--out-dir",
        type=Path,
        default=Path("./skill_output/step1_sample_sql"),
        help="出力ディレクトリ（既定: ./skill_output/step1_sample_sql）",
    )
    p1.set_defaults(handler=_cmd_step1)

    p3 = subparsers.add_parser("step3", help="完成版 SQL を指定 DB に実行")
    p3.add_argument("sql_file", type=Path, help="完成版 SQL ファイル")
    p3.add_argument("-d", "--database", required=True, help="対象 DB 名")
    p3.add_argument("--host", default="localhost", help="MySQL host")
    p3.add_argument("--port", type=int, default=3306, help="MySQL port")
    p3.add_argument("-u", "--user", default="root", help="MySQL user")
    p3.add_argument("-p", "--password", default="", help="MySQL password (or MYSQL_PASSWORD)")
    p3.add_argument("--table", help="投入後件数取得用テーブル名 (例: tbl または db.tbl)")
    p3.add_argument("--expected-count", type=int, help="期待投入件数（不一致で exit 1）")
    p3.set_defaults(handler=_cmd_step3)

    pipe = subparsers.add_parser("pipeline", help="ステップ 1 実行。オプションでステップ 3 まで実行")
    pipe.add_argument("csv_paths", type=Path, nargs="+", help="対象 CSV")
    pipe.add_argument(
        "-o",
        "--out-dir",
        type=Path,
        default=Path("./skill_output/step1_sample_sql"),
        help="出力ディレクトリ（既定: ./skill_output/step1_sample_sql）",
    )
    pipe.add_argument("--run-step3", action="store_true", help="ステップ 2 完了後、step3 を実行する場合に指定")
    pipe.add_argument("--sql", type=Path, help="完成版 SQL（--run-step3 時必須）")
    pipe.add_argument("-d", "--database", help="対象 DB（--run-step3 時必須）")
    pipe.add_argument("--table", help="投入後件数取得用テーブル")
    pipe.add_argument("--host", default="localhost")
    pipe.add_argument("--port", type=int, default=3306)
    pipe.add_argument("-u", "--user", default="root")
    pipe.add_argument("-p", "--password", default="")
    pipe.set_defaults(handler=_cmd_pipeline)

    args = parser.parse_args()
    return args.handler(args)


def _cmd_pipeline(args: argparse.Namespace) -> int:
    """一括パイプライン: ステップ 1 →（ステップ 2 は手動）→ オプションでステップ 3。"""
    import os
    from flat_file_mysql.sample_sql import run_step1

    for p in args.csv_paths:
        if not p.exists():
            print(f"Error: not found: {p}")
            return 1
    out_dir = args.out_dir.resolve()
    out_dir.mkdir(parents=True, exist_ok=True)
    reports = run_step1(list(args.csv_paths), out_dir)
    has_error = False
    for r in reports:
        if r.get("error"):
            print(f"Error: {r['path']} -> {r['error']}")
            has_error = True
        else:
            print(f"  {r['path'].name}: total={r['total']}, duplicates={r['duplicates']}, unique={r['unique']} -> {r['out_sql'].name}")
    if has_error:
        return 1
    if not getattr(args, "run_step3", False):
        print("--- ステップ 2 を実施後、step3 または pipeline --run-step3 --sql ... -d ... で投入")
        return 0
    sql_path = getattr(args, "sql", None)
    database = getattr(args, "database", None)
    if not sql_path or not sql_path.exists() or not database:
        print("Error: --run-step3 時は --sql と -d/--database を指定してください")
        return 1
    password = getattr(args, "password", None) or os.environ.get("MYSQL_PASSWORD", "")
    from flat_file_mysql.execute_sql import get_table_count, run_sql_file
    ok, err = run_sql_file(sql_path, database, host=args.host, port=args.port, user=args.user, password=password)
    if not ok:
        print(f"Error step3: {err}")
        return 1
    print(f"OK: {sql_path} -> {database}")
    table = getattr(args, "table", None)
    if table:
        cnt, err2 = get_table_count(database, table, host=args.host, port=args.port, user=args.user, password=password)
        if err2:
            print(f"Warning: 件数取得失敗: {err2}")
        else:
            expected = sum(r["unique"] for r in reports if not r.get("error"))
            print(f"投入件数: {cnt}, 期待（ユニーク数）: {expected}, 一致: {cnt == expected}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
