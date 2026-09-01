-- Seed data for parameter_types
BEGIN;
INSERT INTO "parameter_types" ("id", "name") VALUES (1, 'Identifier');
INSERT INTO "parameter_types" ("id", "name") VALUES (2, 'String');
INSERT INTO "parameter_types" ("id", "name") VALUES (3, 'Integer');
INSERT INTO "parameter_types" ("id", "name") VALUES (4, 'UnsignedInteger');
INSERT INTO "parameter_types" ("id", "name") VALUES (5, 'Float');
INSERT INTO "parameter_types" ("id", "name") VALUES (6, 'HexInteger');
INSERT INTO "parameter_types" ("id", "name") VALUES (7, 'Enum');
INSERT INTO "parameter_types" ("id", "name") VALUES (8, 'KeywordReference');
INSERT INTO "parameter_types" ("id", "name") VALUES (9, 'IdentifierReference');
COMMIT;
