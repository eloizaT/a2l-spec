#!/usr/bin/env python3
"""Export the current SQLite data into deterministic seed SQL files."""

from __future__ import annotations

import sqlite3
from pathlib import Path


def repo_root() -> Path:
    return Path(__file__).resolve().parents[1]


def quote_ident(name: str) -> str:
    return '"' + name.replace('"', '""') + '"'


def sql_literal(value):
    if value is None:
        return "NULL"
    if isinstance(value, str):
        return "'" + value.replace("'", "''") + "'"
    if isinstance(value, (int, float)):
        return str(value)
    return "'" + str(value).replace("'", "''") + "'"


def ordered_tables(conn: sqlite3.Connection) -> list[str]:
    table_names = [
        "keyword_domains",
        "keyword_categories",
        "keyword_types",
        "versions",
        "source_types",
        "parameter_types",
        "definition_status",
        "enum_types",
        "keyword_enum_mapping",
        "keywords",
        "enum_values",
        "keyword_parameters",
        "sources",
        "definitions",
        "definition_sources",
        "definition_parameters",
        "definition_children",
        "definition_evidence",
        "examples",
        "notes",
        "grammar_modes",
        "lexer_tokens",
    ]
    existing = {
        row[0]
        for row in conn.execute("SELECT name FROM sqlite_master WHERE type = 'table' AND name NOT LIKE 'sqlite_%'")
    }
    return [table for table in table_names if table in existing]


def export_table(conn: sqlite3.Connection, table_name: str, output_dir: Path) -> None:
    columns = [
        row[1]
        for row in conn.execute(f"PRAGMA table_info({quote_ident(table_name)})")
    ]
    rows = conn.execute(f"SELECT * FROM {quote_ident(table_name)} ORDER BY 1").fetchall()

    file_path = output_dir / f"{table_name}.sql"
    with file_path.open("w", encoding="utf-8") as handle:
        handle.write(f"-- Seed data for {table_name}\n")
        handle.write("BEGIN;\n")
        if rows:
            for row in rows:
                values = ", ".join(sql_literal(value) for value in row)
                cols = ", ".join(quote_ident(column) for column in columns)
                handle.write(f"INSERT INTO {quote_ident(table_name)} ({cols}) VALUES ({values});\n")
        else:
            handle.write("-- No rows\n")
        handle.write("COMMIT;\n")


def main() -> int:
    root = repo_root()
    source_db = root / "db" / "a2l_spec.db"
    output_dir = root / "seeds"
    output_dir.mkdir(parents=True, exist_ok=True)

    conn = sqlite3.connect(source_db)
    try:
        tables = ordered_tables(conn)
        for table_name in tables:
            export_table(conn, table_name, output_dir)
    finally:
        conn.close()

    print(f"Exported seed SQL for {len(tables)} tables to {output_dir}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
