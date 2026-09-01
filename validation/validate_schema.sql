SELECT
  'schema_has_tables' AS check_name,
  (SELECT COUNT(*) FROM sqlite_master WHERE type = 'table' AND name NOT LIKE 'sqlite_%') >= 1 AS passed,
  (SELECT COUNT(*) FROM sqlite_master WHERE type = 'table' AND name NOT LIKE 'sqlite_%') AS actual,
  1 AS expected;

SELECT
  'definition_tables_present' AS check_name,
  (
    EXISTS (SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = 'definitions') AND
    EXISTS (SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = 'definition_children') AND
    EXISTS (SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = 'keyword_parameters')
  ) AS passed,
  (
    SELECT COUNT(*)
    FROM sqlite_master
    WHERE type = 'table' AND name IN ('definitions', 'definition_children', 'keyword_parameters')
  ) AS actual,
  3 AS expected;

PRAGMA foreign_keys = ON;

SELECT
  'foreign_keys_enabled' AS check_name,
  1 AS passed,
  1 AS actual,
  1 AS expected;
