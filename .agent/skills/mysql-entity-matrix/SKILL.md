---
name: mysql-entity-matrix
description: Target MySQL databases to cross-check existence of a specific ID column across all tables. Generates a robust matrix SQL containing `[1, 0]` values to show presence in corresponding tables. Use when the user requests generating a query tracking an identifier (like PATIENTNO, user_id) presence over all tables in a Database schema, or requests an "entity presence matrix".
license: Complete terms in LICENSE.txt
---

# MySQL Entity Presence Matrix Generator

This skill leverages Python to dynamically construct and execute a comprehensive `WITH` CTE block, `LEFT JOIN` aggregations, and `CASE WHEN` flags representing whether a target ID string exists in any relevant table of a MySQL database.

## Workflow

1. You should ALWAYS use the provided deterministic script located in `scripts/generate_matrix_sql.py`. Do NOT attempt to build this SQL via plain DB tools because the number of tables might be excessively large.
2. The user will specify the target Database. If they specify `FUGA`, use `--database FUGA`.
3. The user may specify an ID column (default: `PATIENTNO`). Overwrite it using `--id_column <ColumnName>` if needed.
4. Pass the `--execute` argument to have the script connect and save the resulting cross-matrix CSV locally. The default generated SQL query will be saved into the standard output path (`./skill_output/mysql-entity-matrix`).

## Execution

The script relies on the system `mysql` command line tool and your local `~/.my.cnf` file for authentication. Therefore, if you are running against your default locale, no credentials need to be passed.

Run the following command pattern via the terminal:

```bash
python3 .agent/skills/mysql-entity-matrix/scripts/generate_matrix_sql.py --database <Database> --id_column <IdColumn> --execute
```

If you need to target a remote host or override defaults (e.g., the NAS DB at `192.168.0.110:3307`), you can provide standard connect flags:
```bash
python3 .agent/skills/mysql-entity-matrix/scripts/generate_matrix_sql.py -d <Database> -H 192.168.0.110 -P 3307 -u <User> -p <Password> --execute
```

> [!NOTE]
> Review `references/output_format_example.md` to see exactly what pattern A SQL format the script writes out.
