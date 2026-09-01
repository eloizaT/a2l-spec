import os
import sqlite3

path = 'tmp_issue3_check.db'
if os.path.exists(path):
    os.remove(path)

conn = sqlite3.connect(path)
with open('migrations/001_baseline_schema.sql', 'r', encoding='utf-8') as fh:
    conn.executescript(fh.read())

print('tables', conn.execute("SELECT COUNT(*) FROM sqlite_master WHERE type='table'").fetchone()[0])
print('views', conn.execute("SELECT COUNT(*) FROM sqlite_master WHERE type='view'").fetchone()[0])
print('fk_violations', len(conn.execute('PRAGMA foreign_key_check').fetchall()))

conn.close()
os.remove(path)
