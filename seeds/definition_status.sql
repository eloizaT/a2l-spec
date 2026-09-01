-- Seed data for definition_status
BEGIN;
INSERT INTO "definition_status" ("id", "name") VALUES (1, 'draft');
INSERT INTO "definition_status" ("id", "name") VALUES (2, 'verified');
INSERT INTO "definition_status" ("id", "name") VALUES (3, 'deprecated');
COMMIT;
