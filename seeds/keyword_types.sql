-- Seed data for keyword_types
BEGIN;
INSERT INTO "keyword_types" ("id", "name", "description") VALUES (1, 'block', NULL);
INSERT INTO "keyword_types" ("id", "name", "description") VALUES (2, 'attribute', NULL);
INSERT INTO "keyword_types" ("id", "name", "description") VALUES (4, 'grammar_keyword', 'A2ML grammar construction keyword.');
INSERT INTO "keyword_types" ("id", "name", "description") VALUES (5, 'primitive_type', 'A2ML primitive data type.');
INSERT INTO "keyword_types" ("id", "name", "description") VALUES (6, 'operator', 'A2ML grammar operator.');
COMMIT;
