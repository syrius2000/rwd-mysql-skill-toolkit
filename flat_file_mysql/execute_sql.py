"""ステップ 3: 完成版 SQL の指定 DB への実行（標準ライブラリのみ、mysql CLI を subprocess で呼ぶ）。

目的:
  SQL ファイルを指定 DB で実行し、オプションでテーブル件数を取得する。
  mysql コマンドが PATH にあることが前提。仮想環境・pip 不要。

使い方:
  from flat_file_mysql.execute_sql import run_sql_file, get_table_count

  ok, err = run_sql_file(Path("complete.sql"), "mydb", host="localhost", password=os.environ.get("MYSQL_PASSWORD"))
  cnt, err = get_table_count("mydb", "mytbl")  # 失敗時 (None, エラーメッセージ)
"""

from pathlib import Path
import os
import subprocess


def run_sql_file(
    sql_path: Path,
    database: str,
    *,
    host: str = "localhost",
    port: int = 3306,
    user: str = "root",
    password: str = "",
) -> tuple[bool, str]:
    """SQL ファイルを指定 DB で実行。成功時 (True, '')、失敗時 (False, エラーメッセージ)。"""
    try:
        content = sql_path.read_text(encoding="utf-8")
    except Exception as e:
        return False, f"ファイル読み込み: {e}"
    cmd = [
        "mysql",
        "-h",
        host,
        "-P",
        str(port),
        "-u",
        user,
        database,
    ]
    env = os.environ.copy()
    if password:
        env["MYSQL_PWD"] = password
    else:
        env.pop("MYSQL_PWD", None)
    try:
        proc = subprocess.run(
            cmd,
            input=content,
            text=True,
            capture_output=True,
            check=False,
            env=env,
        )
    except FileNotFoundError:
        return False, "mysql コマンドが見つかりません（PATH を確認してください）"
    except Exception as e:
        return False, f"実行失敗: {e}"
    if proc.returncode != 0:
        return False, (proc.stderr or proc.stdout or "mysql 実行エラー").strip()
    return True, ""


def get_table_count(
    database: str,
    table: str,
    *,
    host: str = "localhost",
    port: int = 3306,
    user: str = "root",
    password: str = "",
) -> tuple[int | None, str]:
    """指定テーブルのレコード数を返す。table に 'db.tbl' 形式可。失敗時 (None, エラーメッセージ)。"""
    if "." in table:
        db, tbl = table.split(".", 1)
        database, table = db, tbl
    safe = "`" + table.replace("`", "``") + "`"
    query = f"SELECT COUNT(*) FROM {safe};"
    cmd = [
        "mysql",
        "-h",
        host,
        "-P",
        str(port),
        "-u",
        user,
        "-N",
        "-B",
        "-e",
        query,
        database,
    ]
    env = os.environ.copy()
    if password:
        env["MYSQL_PWD"] = password
    else:
        env.pop("MYSQL_PWD", None)
    try:
        proc = subprocess.run(cmd, text=True, capture_output=True, check=False, env=env)
    except FileNotFoundError:
        return None, "mysql コマンドが見つかりません（PATH を確認してください）"
    except Exception as e:
        return None, str(e)
    if proc.returncode != 0:
        return None, (proc.stderr or proc.stdout or "mysql 実行エラー").strip()
    out = proc.stdout.strip().splitlines()
    if not out:
        return None, "count 取得結果が空です"
    try:
        return int(out[0].strip()), ""
    except ValueError:
        return None, f"count のパース失敗: {out[0].strip()}"
