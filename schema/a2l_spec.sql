BEGIN TRANSACTION;
DROP TABLE IF EXISTS "definition_children";
CREATE TABLE "definition_children" (
	"id"	INTEGER,
	"parent_definition_id"	INTEGER NOT NULL,
	"child_definition_id"	INTEGER NOT NULL,
	"min_occurs"	INTEGER NOT NULL DEFAULT 0,
	"max_occurs"	INTEGER,
	"display_order"	INTEGER,
	PRIMARY KEY("id"),
	UNIQUE("parent_definition_id","child_definition_id"),
	FOREIGN KEY("child_definition_id") REFERENCES "definitions"("id") ON DELETE CASCADE,
	FOREIGN KEY("parent_definition_id") REFERENCES "definitions"("id") ON DELETE CASCADE,
	CHECK("max_occurs" IS NULL OR "max_occurs" >= "min_occurs")
);
DROP TABLE IF EXISTS "definition_evidence";
CREATE TABLE "definition_evidence" (
	"id"	INTEGER,
	"definition_id"	INTEGER NOT NULL,
	"source_id"	INTEGER NOT NULL,
	"confidence"	REAL NOT NULL CHECK("confidence" BETWEEN 0.0 AND 1.0),
	"note"	TEXT,
	PRIMARY KEY("id"),
	FOREIGN KEY("definition_id") REFERENCES "definitions"("id") ON DELETE CASCADE,
	FOREIGN KEY("source_id") REFERENCES "sources"("id")
);
DROP TABLE IF EXISTS "definition_parameters";
CREATE TABLE "definition_parameters" (
	"id"	INTEGER,
	"definition_id"	INTEGER NOT NULL,
	"position"	INTEGER NOT NULL,
	"name"	TEXT NOT NULL,
	"parameter_type_id"	INTEGER NOT NULL,
	"required"	INTEGER NOT NULL CHECK("required" IN (0, 1)),
	"default_value"	TEXT,
	UNIQUE("definition_id","position"),
	PRIMARY KEY("id"),
	FOREIGN KEY("definition_id") REFERENCES "definitions"("id") ON DELETE CASCADE,
	FOREIGN KEY("parameter_type_id") REFERENCES "parameter_types"("id")
);
DROP TABLE IF EXISTS "definition_sources";
CREATE TABLE "definition_sources" (
	"definition_id"	INTEGER NOT NULL,
	"source_id"	INTEGER NOT NULL,
	PRIMARY KEY("definition_id","source_id"),
	FOREIGN KEY("definition_id") REFERENCES "definitions"("id") ON DELETE CASCADE,
	FOREIGN KEY("source_id") REFERENCES "sources"("id") ON DELETE CASCADE
);
DROP TABLE IF EXISTS "definition_status";
CREATE TABLE "definition_status" (
	"id"	INTEGER,
	"name"	TEXT NOT NULL UNIQUE,
	PRIMARY KEY("id")
);
DROP TABLE IF EXISTS "definitions";
CREATE TABLE "definitions" (
	"id"	INTEGER,
	"keyword_id"	INTEGER NOT NULL,
	"version_id"	INTEGER NOT NULL,
	"status_id"	INTEGER NOT NULL,
	"description"	TEXT,
	"is_canonical"	INTEGER NOT NULL DEFAULT 1 CHECK("is_canonical" IN (0, 1)),
	"created_at"	TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
	PRIMARY KEY("id"),
	UNIQUE("keyword_id","version_id","is_canonical"),
	FOREIGN KEY("keyword_id") REFERENCES "keywords"("id") ON DELETE CASCADE,
	FOREIGN KEY("status_id") REFERENCES "definition_status"("id"),
	FOREIGN KEY("version_id") REFERENCES "versions"("id")
);
DROP TABLE IF EXISTS "enum_types";
CREATE TABLE "enum_types" (
	"id"	INTEGER,
	"name"	TEXT NOT NULL UNIQUE,
	"description"	TEXT,
	"is_flags"	INTEGER NOT NULL DEFAULT 0,
	"created_at"	TEXT DEFAULT CURRENT_TIMESTAMP,
	PRIMARY KEY("id")
);
DROP TABLE IF EXISTS "enum_values";
CREATE TABLE "enum_values" (
	"id"	INTEGER,
	"enum_type_id"	INTEGER NOT NULL,
	"name"	TEXT NOT NULL,
	"value"	INTEGER,
	"ordinal"	INTEGER NOT NULL,
	"description"	TEXT,
	UNIQUE("enum_type_id","name"),
	UNIQUE("enum_type_id","ordinal"),
	PRIMARY KEY("id"),
	FOREIGN KEY("enum_type_id") REFERENCES "enum_types"("id") ON DELETE CASCADE
);
DROP TABLE IF EXISTS "examples";
CREATE TABLE "examples" (
	"id"	INTEGER,
	"definition_id"	INTEGER NOT NULL,
	"title"	TEXT,
	"a2l_snippet"	TEXT NOT NULL,
	"source_id"	INTEGER,
	PRIMARY KEY("id"),
	FOREIGN KEY("definition_id") REFERENCES "definitions"("id") ON DELETE CASCADE,
	FOREIGN KEY("source_id") REFERENCES "sources"("id")
);
DROP TABLE IF EXISTS "grammar_modes";
CREATE TABLE "grammar_modes" (
	"id"	INTEGER,
	"name"	TEXT UNIQUE,
	"domain_id"	INTEGER,
	PRIMARY KEY("id"),
	FOREIGN KEY("domain_id") REFERENCES "keyword_domains"("id")
);
DROP TABLE IF EXISTS "keyword_categories";
CREATE TABLE "keyword_categories" (
	"id"	INTEGER,
	"name"	TEXT NOT NULL UNIQUE,
	"description"	TEXT,
	PRIMARY KEY("id")
);
DROP TABLE IF EXISTS "keyword_domains";
CREATE TABLE "keyword_domains" (
	"id"	INTEGER,
	"name"	TEXT NOT NULL UNIQUE,
	"description"	TEXT,
	PRIMARY KEY("id")
);
DROP TABLE IF EXISTS "keyword_enum_mapping";
CREATE TABLE "keyword_enum_mapping" (
	"id"	INTEGER,
	"keyword_id"	INTEGER NOT NULL,
	"enum_type_id"	INTEGER NOT NULL,
	PRIMARY KEY("id"),
	UNIQUE("keyword_id","enum_type_id"),
	FOREIGN KEY("enum_type_id") REFERENCES "enum_types"("id"),
	FOREIGN KEY("keyword_id") REFERENCES "keywords"("id")
);
DROP TABLE IF EXISTS "keyword_parameters";
CREATE TABLE "keyword_parameters" (
	"id"	INTEGER,
	"keyword_id"	INTEGER NOT NULL,
	"position"	INTEGER NOT NULL,
	"name"	TEXT NOT NULL,
	"parameter_type"	TEXT NOT NULL,
	"required"	INTEGER NOT NULL DEFAULT 1,
	"description"	TEXT,
	"enum_type_id"	INTEGER,
	"reference_keyword_id"	INTEGER,
	PRIMARY KEY("id"),
	UNIQUE("keyword_id","position"),
	FOREIGN KEY("enum_type_id") REFERENCES "enum_types"("id"),
	FOREIGN KEY("keyword_id") REFERENCES "keywords"("id"),
	FOREIGN KEY("reference_keyword_id") REFERENCES "keywords"("id")
);
DROP TABLE IF EXISTS "keyword_types";
CREATE TABLE "keyword_types" (
	"id"	INTEGER,
	"name"	TEXT NOT NULL UNIQUE,
	"description"	TEXT,
	PRIMARY KEY("id")
);
DROP TABLE IF EXISTS "keywords";
CREATE TABLE "keywords" (
	"id"	INTEGER,
	"name"	TEXT NOT NULL UNIQUE,
	"keyword_type_id"	INTEGER NOT NULL,
	"description"	TEXT,
	"created_at"	TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
	"category_id"	INTEGER,
	"domain_id"	INTEGER,
	PRIMARY KEY("id"),
	FOREIGN KEY("category_id") REFERENCES "keyword_categories"("id"),
	FOREIGN KEY("domain_id") REFERENCES "keyword_domains"("id"),
	FOREIGN KEY("keyword_type_id") REFERENCES "keyword_types"("id")
);
DROP TABLE IF EXISTS "lexer_tokens";
CREATE TABLE "lexer_tokens" (
	"id"	INTEGER,
	"token_name"	TEXT NOT NULL UNIQUE,
	"literal"	TEXT,
	"regex"	TEXT,
	"precedence"	INTEGER,
	PRIMARY KEY("id")
);
DROP TABLE IF EXISTS "notes";
CREATE TABLE "notes" (
	"id"	INTEGER,
	"definition_id"	INTEGER NOT NULL,
	"note_type"	TEXT NOT NULL,
	"note"	TEXT NOT NULL,
	PRIMARY KEY("id"),
	FOREIGN KEY("definition_id") REFERENCES "definitions"("id") ON DELETE CASCADE
);
DROP TABLE IF EXISTS "parameter_constraints";
CREATE TABLE "parameter_constraints" (
	"id"	INTEGER,
	"parameter_id"	INTEGER NOT NULL,
	"constraint_type"	TEXT NOT NULL,
	"constraint_value"	TEXT NOT NULL,
	PRIMARY KEY("id"),
	FOREIGN KEY("parameter_id") REFERENCES "definition_parameters"("id")
);
DROP TABLE IF EXISTS "parameter_types";
CREATE TABLE "parameter_types" (
	"id"	INTEGER,
	"name"	TEXT NOT NULL UNIQUE,
	PRIMARY KEY("id")
);
DROP TABLE IF EXISTS "source_types";
CREATE TABLE "source_types" (
	"id"	INTEGER,
	"name"	TEXT NOT NULL UNIQUE,
	PRIMARY KEY("id")
);
DROP TABLE IF EXISTS "sources";
CREATE TABLE "sources" (
	"id"	INTEGER,
	"source_type_id"	INTEGER NOT NULL,
	"name"	TEXT NOT NULL,
	"url"	TEXT,
	"version"	TEXT,
	PRIMARY KEY("id"),
	UNIQUE("name","version"),
	FOREIGN KEY("source_type_id") REFERENCES "source_types"("id")
);
DROP TABLE IF EXISTS "versions";
CREATE TABLE "versions" (
	"id"	INTEGER,
	"version"	TEXT NOT NULL UNIQUE,
	PRIMARY KEY("id")
);
DROP VIEW IF EXISTS "vw_definition_children";
CREATE VIEW vw_definition_children AS
SELECT

    pk.name      AS parent,

    ck.name      AS child,

    dc.min_occurs,

    dc.max_occurs,

    dc.display_order

FROM definition_children dc

JOIN definitions pd
ON dc.parent_definition_id = pd.id

JOIN definitions cd
ON dc.child_definition_id = cd.id

JOIN keywords pk
ON pd.keyword_id = pk.id

JOIN keywords ck
ON cd.keyword_id = ck.id

ORDER BY
    parent,
    display_order;
DROP VIEW IF EXISTS "vw_definition_complete";
CREATE VIEW vw_definition_complete AS

SELECT

    d.id,

    k.name AS keyword,

    kt.name AS keyword_type,

    v.version,

    ds.name AS status,

    d.is_canonical,

    GROUP_CONCAT(DISTINCT
        p.position || ':' ||
        p.name || ' (' || pt.name || ')'
    ) AS parameters,

    GROUP_CONCAT(DISTINCT
        ck.name
    ) AS child_keywords,

    GROUP_CONCAT(DISTINCT
        s.name
    ) AS sources

FROM definitions d

JOIN keywords k
ON d.keyword_id = k.id

JOIN keyword_types kt
ON k.keyword_type_id = kt.id

JOIN versions v
ON d.version_id = v.id

JOIN definition_status ds
ON d.status_id = ds.id

LEFT JOIN definition_parameters p
ON d.id = p.definition_id

LEFT JOIN parameter_types pt
ON p.parameter_type_id = pt.id

LEFT JOIN definition_children dc
ON d.id = dc.parent_definition_id

LEFT JOIN definitions cd
ON dc.child_definition_id = cd.id

LEFT JOIN keywords ck
ON cd.keyword_id = ck.id

LEFT JOIN definition_sources dsrc
ON d.id = dsrc.definition_id

LEFT JOIN sources s
ON dsrc.source_id = s.id

GROUP BY
    d.id;
DROP VIEW IF EXISTS "vw_definition_parameters";
CREATE VIEW vw_definition_parameters AS
SELECT

    d.id                     AS definition_id,

    k.name                   AS keyword,

    p.position,

    p.name                   AS parameter,

    pt.name                  AS parameter_type,

    p.required,

    p.default_value

FROM definition_parameters p

JOIN definitions d
ON p.definition_id = d.id

JOIN keywords k
ON d.keyword_id = k.id

JOIN parameter_types pt
ON p.parameter_type_id = pt.id

ORDER BY
    keyword,
    position;
DROP VIEW IF EXISTS "vw_definitions";
CREATE VIEW vw_definitions AS
SELECT

    d.id                           AS definition_id,

    k.name                         AS keyword,

    kt.name                        AS keyword_type,

    v.version,

    ds.name                        AS status,

    d.is_canonical,

    d.description,

    d.created_at

FROM definitions d

JOIN keywords k
ON d.keyword_id = k.id

JOIN keyword_types kt
ON k.keyword_type_id = kt.id

JOIN versions v
ON d.version_id = v.id

JOIN definition_status ds
ON d.status_id = ds.id;
DROP VIEW IF EXISTS "vw_grammar_rules";
CREATE VIEW vw_grammar_rules AS
SELECT
    k.name AS keyword,
    GROUP_CONCAT(DISTINCT ck.name, ' | ') AS allowed_children
FROM definitions d
JOIN keywords k ON d.keyword_id = k.id
LEFT JOIN definition_children dc ON d.id = dc.parent_definition_id
LEFT JOIN definitions cd ON dc.child_definition_id = cd.id
LEFT JOIN keywords ck ON cd.keyword_id = ck.id
GROUP BY d.id;
DROP INDEX IF EXISTS "idx_definition_children_child";
CREATE INDEX "idx_definition_children_child" ON "definition_children" (
	"child_definition_id"
);
DROP INDEX IF EXISTS "idx_definition_children_parent";
CREATE INDEX "idx_definition_children_parent" ON "definition_children" (
	"parent_definition_id"
);
DROP INDEX IF EXISTS "idx_definition_evidence";
CREATE INDEX "idx_definition_evidence" ON "definition_evidence" (
	"definition_id"
);
DROP INDEX IF EXISTS "idx_definition_parameters";
CREATE INDEX "idx_definition_parameters" ON "definition_parameters" (
	"definition_id"
);
DROP INDEX IF EXISTS "idx_definition_sources";
CREATE INDEX "idx_definition_sources" ON "definition_sources" (
	"source_id"
);
DROP INDEX IF EXISTS "idx_definitions_keyword";
CREATE INDEX "idx_definitions_keyword" ON "definitions" (
	"keyword_id"
);
DROP INDEX IF EXISTS "idx_keywords_name";
CREATE INDEX "idx_keywords_name" ON "keywords" (
	"name"
);
COMMIT;
