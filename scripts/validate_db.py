#!/usr/bin/env python3
"""Run validation SQL files against the canonical SQLite database."""

from __future__ import annotations

import argparse
import sqlite3
import sys
from pathlib import Path


def repo_root() -> Path:
    return Path(__file__).resolve().parents[1]


def validation_files(directory: Path) -> list[Path]:
    if not directory.exists():
        return []
    return sorted(path for path in directory.glob("*.sql") if path.is_file())


def run_validation_query(conn: sqlite3.Connection, sql_path: Path) -> tuple[bool, list[tuple]]:
    sql_text = sql_path.read_text(encoding="utf-8")
    statements = [part.strip() for part in sql_text.split(";") if part.strip()]
    if not statements:
        return False, [("no_result_rows", 0, None, None)]

    results: list[tuple] = []
    for statement in statements:
        rows = conn.execute(statement).fetchall()
        if not rows:
            continue
        for row in rows:
            if len(row) < 2:
                return False, [(sql_path.name, 0, row, None)]
            check_name = str(row[0])
            passed = bool(row[1])
            actual = row[2] if len(row) > 2 else None
            expected = row[3] if len(row) > 3 else None
            results.append((check_name, passed, actual, expected))

    return all(item[1] for item in results), results


def parse_args() -> argparse.Namespace:
    default_db = repo_root() / "db" / "a2l_spec.db"
    default_validation_dir = repo_root() / "validation"

    parser = argparse.ArgumentParser(description="Run validation checks against the A2L/A2ML SQLite database.")
    parser.add_argument("--database", type=Path, default=default_db, help=f"Database to validate (default: {default_db})")
    parser.add_argument(
        "--validation-dir",
        type=Path,
        default=default_validation_dir,
        help=f"Directory containing validation SQL files (default: {default_validation_dir})",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    files = validation_files(args.validation_dir)
    if not files:
        print(f"No validation SQL files found in {args.validation_dir}", file=sys.stderr)
        return 1

    conn = sqlite3.connect(args.database)
    conn.execute("PRAGMA foreign_keys = ON")
    failed = 0

    try:
        for validation_file in files:
            success, results = run_validation_query(conn, validation_file)
            if not success:
                failed += 1
                print(f"FAIL {validation_file.name}")
                for check_name, passed, actual, expected in results:
                    print(f"  - {check_name}: passed={passed}, actual={actual}, expected={expected}")
            else:
                print(f"PASS {validation_file.name}")
                for check_name, passed, actual, expected in results:
                    print(f"  - {check_name}: passed={passed}, actual={actual}, expected={expected}")
    finally:
        conn.close()

    if failed:
        print(f"Validation failed: {failed} file(s) did not pass.", file=sys.stderr)
        return 1

    print("All validation checks passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
