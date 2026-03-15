---
name: mysql-entity-matrix
description: Target MySQL databases to cross-check existence of a specific ID column across all tables. Generates a robust matrix SQL containing `[1, 0]` values to show presence in corresponding tables. Use when the user requests generating a query tracking an identifier (like PATIENTNO, user_id) presence over all tables in a Database schema, or requests an "entity presence matrix".
license: Complete terms in LICENSE.txt
---

# MySQL Entity Presence Matrix Generator

This skill enables Cursor to generate and execute complex SQL code to map an ID's presence across all designated tables in a MySQL Database natively via a pre-built Antigravity interoperable script.

## Core Action

To execute this skill, call the deterministic Python script provided within this skill's scripts directory, rather than attempting to write out the dynamic SQL structure directly.

**Target Execution Script Path:** 
`.cursor/skills/mysql-entity-matrix/scripts/generate_matrix_sql.py`

## Usage Examples

If the user says: "Make me an ID map for the FUGA database covering PATIENTNO."

Execute the Python script in the terminal (It natively relies on `~/.my.cnf` for authentication by default):
```bash
python3 .cursor/skills/mysql-entity-matrix/scripts/generate_matrix_sql.py -d FUGA -i PATIENTNO --execute
```

If the user relies on the local MariaDB instances in the QNAP NAS, specify the port and credentials flag if they differ from `~/.my.cnf`:
```bash
python3 .cursor/skills/mysql-entity-matrix/scripts/generate_matrix_sql.py -d FUGA -i PATIENTNO -H 192.168.0.110 -P 3307 -u my_user -p my_pass --execute
```

> [!TIP]
> This command systematically places resulting CSV rows resolving Pattern A (Base ID maps to TABLE_A, TABLE_B [1/0 flags]) under the target local namespace: `./skill_output/mysql-entity-matrix/`.
