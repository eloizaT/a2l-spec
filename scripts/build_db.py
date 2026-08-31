#!/usr/bin/env python3
"""Build the canonical A2L/A2ML SQLite database from repo-managed SQL inputs."""

from __future__ import annotations

import argparse
import sqlite3
import sys
from pathlib import Path


def repo_root() -> Path:
    return Path(__file__).resolve().parents[1]


def sorted_sql_files(directory: Path) -> list[Path]:
    if not directory.exists():
        return []
    return sorted(path for path in directory.iterdir() if path.is_file() and path.suffix.lower() == ".sql")


def apply_sql_file(conn: sqlite3.Connection, sql_path: Path) -> None:
    sql_text = sql_path.read_text(encoding="utf-8")
    conn.executescript(sql_text)


def build_database(output_path: Path) -> tuple[int, int, int]:
    root = repo_root()
    migrations_dir = root / "migrations"
    seeds_dir = root / "seeds"
    schema_snapshot = root / "db" / "schema.sql"
    fallback_schema = root / "schema" / "a2l_spec.sql"

    sql_inputs: list[Path] = []
    sql_inputs.extend(sorted_sql_files(migrations_dir))
    sql_inputs.extend(sorted_sql_files(seeds_dir))

    if not sql_inputs:
        if schema_snapshot.exists():
            sql_inputs = [schema_snapshot]
        elif fallback_schema.exists():
            sql_inputs = [fallback_schema]
        else:
            raise FileNotFoundError("No SQL build inputs were found in migrations/, seeds/, db/schema.sql, or schema/a2l_spec.sql")

    output_path.parent.mkdir(parents=True, exist_ok=True)
    if output_path.exists():
        output_path.unlink()

    conn = sqlite3.connect(output_path)
    try:
        conn.execute("PRAGMA foreign_keys = ON")
        for sql_path in sql_inputs:
            apply_sql_file(conn, sql_path)

        fk_violations = conn.execute("PRAGMA foreign_key_check").fetchall()
        if fk_violations:
            raise RuntimeError(f"Foreign key violations detected: {fk_violations}")

        table_count = conn.execute("SELECT COUNT(*) FROM sqlite_master WHERE type = 'table'").fetchone()[0]
        index_count = conn.execute("SELECT COUNT(*) FROM sqlite_master WHERE type = 'index'").fetchone()[0]
        view_count = conn.execute("SELECT COUNT(*) FROM sqlite_master WHERE type = 'view'").fetchone()[0]
    finally:
        conn.close()

    return table_count, index_count, view_count


def parse_args() -> argparse.Namespace:
    root = repo_root()
    default_output = root / "db" / "a2l_spec.db"

    parser = argparse.ArgumentParser(description="Build the canonical A2L/A2ML SQLite database.")
    parser.add_argument(
        "--output",
        type=Path,
        default=default_output,
        help=f"Target database path (default: {default_output})",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    try:
        table_count, index_count, view_count = build_database(args.output)
    except Exception as exc:  # pragma: no cover - CLI surface
        print(f"Build failed: {exc}", file=sys.stderr)
        return 1

    print(f"Built database: {args.output}")
    print(f"Tables: {table_count} | Indexes: {index_count} | Views: {view_count}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
