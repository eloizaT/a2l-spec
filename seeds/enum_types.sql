-- Seed data for enum_types
BEGIN;
INSERT INTO "enum_types" ("id", "name", "description", "is_flags", "created_at") VALUES (1, 'CharacteristicType', NULL, 0, '2026-08-07 13:47:38');
INSERT INTO "enum_types" ("id", "name", "description", "is_flags", "created_at") VALUES (2, 'DataType', NULL, 0, '2026-08-07 13:47:38');
INSERT INTO "enum_types" ("id", "name", "description", "is_flags", "created_at") VALUES (3, 'ByteOrder', NULL, 0, '2026-08-07 13:47:38');
INSERT INTO "enum_types" ("id", "name", "description", "is_flags", "created_at") VALUES (4, 'AddressType', NULL, 0, '2026-08-07 13:47:38');
INSERT INTO "enum_types" ("id", "name", "description", "is_flags", "created_at") VALUES (5, 'IndexOrder', NULL, 0, '2026-08-07 13:47:38');
INSERT INTO "enum_types" ("id", "name", "description", "is_flags", "created_at") VALUES (6, 'Monotony', NULL, 0, '2026-08-07 13:47:38');
INSERT INTO "enum_types" ("id", "name", "description", "is_flags", "created_at") VALUES (7, 'ConversionType', NULL, 0, '2026-08-07 13:47:38');
INSERT INTO "enum_types" ("id", "name", "description", "is_flags", "created_at") VALUES (8, 'MemoryType', NULL, 0, '2026-08-07 13:47:38');
INSERT INTO "enum_types" ("id", "name", "description", "is_flags", "created_at") VALUES (9, 'MemoryAttribute', NULL, 0, '2026-08-07 13:47:38');
INSERT INTO "enum_types" ("id", "name", "description", "is_flags", "created_at") VALUES (10, 'CalibrationAccess', NULL, 0, '2026-08-07 13:47:38');
INSERT INTO "enum_types" ("id", "name", "description", "is_flags", "created_at") VALUES (11, 'DepositMode', NULL, 0, '2026-08-07 13:47:38');
INSERT INTO "enum_types" ("id", "name", "description", "is_flags", "created_at") VALUES (12, 'ReadWrite', NULL, 0, '2026-08-07 17:05:17');
INSERT INTO "enum_types" ("id", "name", "description", "is_flags", "created_at") VALUES (13, 'FloatFormat', NULL, 0, '2026-08-07 17:05:32');
INSERT INTO "enum_types" ("id", "name", "description", "is_flags", "created_at") VALUES (14, 'AxisDescrAttribute', 'Axis description attribute type.', 0, '2026-08-10 11:39:38');
INSERT INTO "enum_types" ("id", "name", "description", "is_flags", "created_at") VALUES (15, 'TransformerTrigger', 'Trigger condition for execution of a TRANSFORMER.', 0, '2026-08-14 10:49:44');
COMMIT;
