-- Seed data for source_types
BEGIN;
INSERT INTO "source_types" ("id", "name") VALUES (1, 'parser');
INSERT INTO "source_types" ("id", "name") VALUES (2, 'grammar');
INSERT INTO "source_types" ("id", "name") VALUES (3, 'sample');
INSERT INTO "source_types" ("id", "name") VALUES (4, 'vendor');
INSERT INTO "source_types" ("id", "name") VALUES (5, 'documentation');
COMMIT;
