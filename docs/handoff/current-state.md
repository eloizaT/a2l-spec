# A2L/A2ML Parser Database — Current Project State

> **Purpose:** This document is the handoff/source-of-context for future ChatGPT, Codex, or human development sessions.
>
> When starting a new session, provide this file together with the current SQLite database and relevant schema/migration files, then instruct the session to continue from the current project state.
>
> **Important:** Treat the repository and database as the source of truth. This document records project decisions and known state, but counts and schema details should be verified against the current database before making changes.

## 1. Project Goal

Build a SQLite-backed grammar and metadata model for an A2L/A2ML parser.

The ultimate deliverable is the SQLite database. Repository tooling, migrations, seeds, validation scripts, and documentation exist to make that database reproducible, reviewable, and maintainable.

The project should model:

- A2L keywords and metadata
- positional keyword parameters
- enum types and explicit enum ordinals
- keyword references
- parent/child grammar relationships
- optionality and cardinality
- grammar ordering semantics
- A2L/A2ML grammar-domain separation
- eventually, A2ML grammar used by constructs such as `IF_DATA`

---

## 2. Repository Direction

Recommended repository structure:

```text
a2l-spec-db/
├── README.md
├── LICENSE
├── .gitignore
├── db/
│   ├── a2l_spec.db
│   └── schema.sql
├── migrations/
├── seeds/
│   ├── keywords.sql
│   ├── enum_types.sql
│   ├── enum_values.sql
│   ├── keyword_parameters.sql
│   └── definitions.sql
├── validation/
│   ├── validate_schema.sql
│   ├── validate_keywords.sql
│   ├── validate_enums.sql
│   ├── validate_parameters.sql
│   └── validate_definitions.sql
├── scripts/
│   ├── build_db.py
│   └── validate_db.py
├── docs/
│   ├── architecture.md
│   ├── schema.md
│   ├── grammar-model.md
│   ├── sources.md
│   ├── handoff/
│   │   └── current-state.md
│   └── decisions/
└── tests/
    ├── expected_counts.sql
    └── integrity_checks.sql
```

Desired canonical workflow:

```text
migrations + seeds
        |
        v
scripts/build_db.py
        |
        v
db/a2l_spec.db
```

The generated SQLite database may remain committed to GitHub for convenient consumption, but it should be reproducible from source-controlled inputs.

---

## 3. Current Development Phase

The `keyword_parameters` phase is essentially complete.

The next parser-data phase is:

**Definitions — parent/child grammar relationships.**

Before large-scale definitions population, repository organization and Milestones 0–2 should be completed.

Do not resume bulk definition insertion until the definitions schema/cardinality/ordering model is considered stable.

---

## 4. `keyword_parameters` Schema

The established schema is conceptually:

```sql
CREATE TABLE keyword_parameters (
    id INTEGER PRIMARY KEY,
    keyword_id INTEGER NOT NULL,
    position INTEGER NOT NULL,
    name TEXT NOT NULL,
    parameter_type TEXT NOT NULL,
    required INTEGER NOT NULL DEFAULT 1,
    description TEXT,
    enum_type_id INTEGER,
    reference_keyword_id INTEGER,

    FOREIGN KEY (keyword_id)
        REFERENCES keywords(id),

    FOREIGN KEY (enum_type_id)
        REFERENCES enum_types(id),

    FOREIGN KEY (reference_keyword_id)
        REFERENCES keywords(id),

    UNIQUE (keyword_id, position)
);
```

Current expected count:

```sql
SELECT COUNT(*) FROM keyword_parameters;
-- expected: 156
```

This expected count should become a regression check rather than remaining only documentation.

---

## 5. Parameter Types

Parameter types currently used/designed:

- `STRING`
- `IDENTIFIER`
- `INTEGER`
- `FLOAT`
- `ADDRESS`
- `ENUM`
- `REFERENCE`
- `BOOLEAN`

`required` currently means:

- `1` = mandatory
- `0` = optional or zero-or-more logical parameter

### Known limitation

`keyword_parameters` does **not** properly express repetition/cardinality.

For repeated lists, the current model stores one logical parameter with `required = 0`.

Do not multiply positional rows merely to represent repeated values.

Richer repetition/cardinality belongs in grammar metadata where applicable.

---

## 6. Repeated Reference Modeling

Repeated-reference keywords are represented as **one logical parameter row** with `required = 0`.

Examples:

```text
DEF_CHARACTERISTIC.identifier -> CHARACTERISTIC
FUNCTION_LIST.identifier      -> FUNCTION
IN_MEASUREMENT.identifier     -> MEASUREMENT
LOC_MEASUREMENT.identifier    -> MEASUREMENT
OUT_MEASUREMENT.identifier    -> MEASUREMENT
REF_CHARACTERISTIC.identifier -> CHARACTERISTIC
REF_GROUP.identifier          -> GROUP
REF_MEASUREMENT.identifier    -> MEASUREMENT
SUB_FUNCTION.identifier       -> FUNCTION
```

`reference_keyword_id` must be used conservatively.

If an identifier can refer to several object/type classes, leave `reference_keyword_id` as `NULL`.

Known intentional examples include:

```text
STRUCTURE_COMPONENT.component_type
TRANSFORMER_IN_OBJECTS.identifier
TRANSFORMER_OUT_OBJECTS.identifier
```

Do not invent a single target merely to make the reference non-null.

---

## 7. Keyword Catalog State

The main A2L keyword range was processed through:

```text
123 SYMBOL_LINK
```

A2ML-domain tokens currently include:

```text
130 module
131 struct
132 enum
133 typedef
134 array
135 record
136 uchar
137 uint16
138 uint32
139 char
```

These were intentionally **not** processed as ordinary A2L `keyword_parameters`.

Handle them during the later A2ML phase.

Additional catalog rows:

```text
140 ATTRIBUTE
141 CALIBRATION_ACCESS
142 CHARACTERISTIC_TYPE
143 FLOAT_FORMAT
144 INDEX_ORDER
```

`CALIBRATION_ACCESS` has already been handled and, during early definitions work, was assigned to the A2L domain after confirmation.

No new parameter rows were added for:

```text
ATTRIBUTE
CHARACTERISTIC_TYPE
FLOAT_FORMAT
INDEX_ORDER
```

because they had not been confirmed as independent parameterized constructs in the public grammar being traced.

These rows require explicit audit rather than assumption.

---

## 8. Suspect / Unverified Catalog Rows

The following rows exist in `keywords` but were not confirmed as standalone A2L grammar constructs in the public implementation used during research:

```text
103 TRANSFORMER_IN_OBJECT
104 TRANSFORMER_OUT_OBJECT
107 TRANSFORMER_TYPE
108 TRIGGER
110 READ
111 WRITE
116 LONG_IDENTIFIER
117 SHORT_IDENTIFIER
```

No `keyword_parameters` were added for them.

Confirmed transformer constructs include:

```text
TRANSFORMER
TRANSFORMER_IN_OBJECTS
TRANSFORMER_OUT_OBJECTS
```

Confirmed access flags include:

```text
READ_WRITE
READ_ONLY
```

### Rule

Do **not** automatically create definitions or parameters for suspect catalog rows merely because they exist in the catalog.

Each must be traced and classified first.

---

## 9. Important Special Cases

### `CURVE_AXIS_REF`

`CURVE_AXIS_REF` does not exist in the current keywords table.

Do not create relationships to it unless the keyword catalog is intentionally expanded after research.

### `IF_DATA`

`IF_DATA` has no ordinary A2L positional parameters.

Its contents are governed by A2ML.

Architectural rule:

```text
ordinary A2L keyword
    -> keyword_parameters

IF_DATA
    -> select/use applicable A2ML grammar
```

A2L and A2ML grammar domains must remain separate.

### Intentionally parameterless/container keywords

Known examples include:

```text
STATIC_ADDRESS_OFFSETS
ROOT
VARIANT_CODING
IF_DATA
ANNOTATION
READ_WRITE
READ_ONLY
```

Zero parameter rows for these constructs must not automatically be treated as missing data.

---

## 10. `TRANSFORMER`

`TRANSFORMER` has seven positional parameters:

```text
1 name
2 version
3 dllname_32bit
4 dllname_64bit
5 timeout
6 trigger
7 inverse_transformer
```

`trigger` is modeled as:

```text
parameter_type = ENUM
enum_type      = TransformerTrigger
```

Intended `TransformerTrigger` values:

```text
1 ON_USER_REQUEST
2 ON_CHANGE
```

---

## 11. Enum Types

Known enum types include:

```text
CharacteristicType
DataType
ByteOrder
AddressType
IndexOrder
Monotony
ConversionType
MemoryType
MemoryAttribute
CalibrationAccess
DepositMode
ReadWrite
FloatFormat
AxisDescrAttribute
TransformerTrigger
```

### Enum rule

Every `enum_values` row must have an explicit ordinal.

Do not rely on insertion order.

### Known outstanding validation issue

At the original handoff point:

```text
ReadWrite   -> 0 enum_values
FloatFormat -> 0 enum_values
```

These are tracked as cleanup tasks.

They should not block the definitions phase.

Before changing either one, verify the public grammar and whether the catalog's enum interpretation is correct.

---

## 12. `MATRIX_DIM`

Current representation:

```text
position       = 1
name           = dimension
parameter_type = INTEGER
required       = 0
```

It represents a variable-length dimension list rather than fixed `x`, `y`, and `z` positional parameters.

Do not expand it into fixed dimensions without grammar evidence.

---

## 13. Display / Long / Short Identifier

`DISPLAY_IDENTIFIER` has:

```text
1 display_identifier IDENTIFIER required=1
```

No parameter rows were added for:

```text
LONG_IDENTIFIER
SHORT_IDENTIFIER
```

because they were not confirmed as standalone parameterized grammar constructs.

They remain part of the suspect catalog audit.

---

## 14. Keyword-Parameter Validation Requirements

The project should maintain automated checks for:

- expected `keyword_parameters` count (`156` at this baseline)
- duplicate `(keyword_id, position)`
- broken keyword foreign keys
- broken enum foreign keys
- broken `reference_keyword_id` foreign keys
- ENUM parameters missing `enum_type_id`
- non-ENUM parameters incorrectly having `enum_type_id`
- invalid `required` values
- invalid/gapped parameter positions
- empty parameter names
- enum types without values
- enum values without explicit ordinals
- duplicate enum ordinals
- parameter-to-enum relationships
- parameter-to-keyword reference relationships

Known enum gaps should be handled explicitly rather than by weakening validation globally.

---

## 15. Definitions Phase — Purpose

Definitions model nested grammar such as:

```text
parent keyword
    -> allowed child keyword
```

They should capture at least:

- parent keyword/definition
- child keyword/definition
- grammar domain
- applicable version
- minimum cardinality
- maximum cardinality / repeatability
- ordering metadata
- source/evidence where possible

Do not duplicate positional keyword arguments in the definitions model.

Conceptually:

```text
keyword_parameters
    = tokens/arguments belonging to the keyword itself

definition_children
    = nested keywords allowed inside the keyword/block
```

---

## 16. Definitions Schema Work Already Performed

During the initial definitions investigation, the live DB was found to distinguish:

- `definitions`
- `definition_children`
- `definition_parameters`
- evidence/source-related tables

`definitions` itself is a per-keyword/version definition record rather than directly being the parent-child edge table.

A writable working copy was created because the originally uploaded database was mounted read-only.

Working artifact name from that session:

```text
a2l_spec_definitions_work.db
```

A schema snapshot was also produced:

```text
schema_definitions_phase.sql
```

### Initial schema direction

The working model was tightened so that:

- definitions have explicit grammar-mode/domain association
- child edges contain `min_occurs`
- child edges contain `max_occurs`
- child edges contain an explicit order index
- ordering semantics are distinguished from simple display/source order
- same-version/same-domain safeguards are applied or validated

### Ordering warning

An `order_index` must **not** automatically mean:

> The parser must encounter child keywords in this strict textual order.

It may instead represent declaration/source order.

Ordering behavior must be verified against the actual grammar before strict parsing semantics are encoded.

---

## 17. Initial Definitions Seed

An initial verified ASAP2/A2L 1.71 slice was seeded into the working database.

At that point the working copy contained approximately:

```text
55 definition records
57 verified parent -> child edges
```

and `PRAGMA foreign_key_check` was clean.

These numbers are historical handoff state, **not permanent invariants**. Verify the current DB before relying on them.

The initial work included high-level grammar such as `PROJECT`, `MODULE`, `CHARACTERISTIC`, and `FUNCTION` relationships where confirmed.

---

## 18. Important Grammar Correction Discovered

Do not blindly trust conceptual examples from early handoff notes.

One concrete correction found while tracing the public grammar:

`FUNCTION_LIST` should **not** simply be assumed to be a child of `FUNCTION`.

The traced public grammar placed it under other applicable objects such as `CHARACTERISTIC`, while `FUNCTION` contains constructs such as:

```text
DEF_CHARACTERISTIC
IN_MEASUREMENT
LOC_MEASUREMENT
OUT_MEASUREMENT
REF_CHARACTERISTIC
SUB_FUNCTION
```

and other grammar-confirmed children.

### General rule

Every definition edge must come from traced grammar evidence.

Conceptual examples are useful for orientation but are not authoritative.

---

## 19. Public Grammar Research Policy

The definitions phase should trace a public A2L grammar implementation/source rather than infer relationships from keyword names.

A public implementation used during the initial work was the `a2lfile` project, which models ASAP2/A2L grammar and advertises A2L 1.71 support.

Record the exact sources used in:

```text
docs/sources.md
```

and, where supported by the database, source/evidence metadata.

### Catalog-gap policy

If the public grammar contains a valid construct that is absent from the local keyword catalog:

1. do not fabricate a relationship to a nonexistent keyword;
2. record the catalog gap;
3. decide separately whether the catalog should be expanded;
4. only then add the missing keyword and dependent grammar edges.

---

## 20. Cardinality Semantics

The definitions model should eventually express:

```text
required exactly once:
    min_occurs = 1
    max_occurs = 1

optional:
    min_occurs = 0
    max_occurs = 1

zero or more:
    min_occurs = 0
    max_occurs = UNBOUNDED

one or more:
    min_occurs = 1
    max_occurs = UNBOUNDED
```

The canonical representation of `UNBOUNDED` must be explicitly documented and validated.

Invalid cardinality such as:

```text
max_occurs < min_occurs
```

must fail validation.

---

## 21. Potential Future Grammar-Model Limitation

Simple parent-child cardinality may eventually be insufficient for grammar constructs involving:

- alternatives
- mutually exclusive children
- "exactly one of these"
- repeated ordered groups
- conditional productions

Do **not** prematurely add a complex production-rule model.

Continue with simple parent-child cardinality while it accurately represents the grammar.

Only redesign when actual traced A2L/A2ML grammar requires it.

---

## 22. Planned Definitions Population Order

Once repository organization and Milestones 0–2 are complete, resume definitions approximately in this order:

```text
PROJECT
   |
   v
MODULE
   |
   +--> MOD_COMMON
   |
   +--> MOD_PAR
   |
   +--> MEASUREMENT
   |
   +--> CHARACTERISTIC
   |
   +--> AXIS_PTS
   |
   +--> COMPU_METHOD
   |
   +--> FUNCTION
   |
   +--> GROUP
   |
   +--> RECORD_LAYOUT
   |
   +--> TYPEDEF_*
   |
   +--> TRANSFORMER
   |
   `--> remaining confirmed MODULE children
```

Then work downward through each object's child grammar.

Immediate grammar work after Milestone 2 should begin by completing/verifying the `MODULE` child set, followed by `MOD_COMMON` and `MOD_PAR`.

---

## 23. GitHub Project Organization

Recommended workflow statuses:

```text
Backlog
Ready
In Progress
Blocked
Review
Done
```

Recommended label families:

```text
area: schema
area: a2l
area: a2ml
area: parameters
area: definitions
area: enums
area: validation
area: docs
area: tooling

type: research
type: data
type: bug
type: design
type: validation
type: docs
type: tooling

priority: high
priority: medium
priority: low
```

Recommended optional GitHub Project fields:

```text
Estimate
Confidence
```

Possible estimate scale:

```text
1h
2h
4h
1d
2d
3d+
```

Possible confidence values:

```text
High
Medium
Low
```

---

## 24. Milestone 0 — Repository Foundation

Goal: make the project reproducible and organized before further grammar population.

Tracked tasks:

1. **Initialize repository structure** — estimate: 1 h
2. **Establish canonical database build workflow** — estimate: 1–2 h
3. **Create baseline schema migration** — estimate: 1–2 h
4. **Extract existing database content into seed files** — estimate: 2–4 h
5. **Create database build script** — estimate: 2–3 h
6. **Create database validation runner** — estimate: 2–3 h
7. **Document current modeling decisions** — estimate: 2–3 h

Estimated milestone total:

```text
11–18 hours
```

---

## 25. Milestone 1 — Current Database Cleanup

Goal: close known loose ends from the keyword-parameters phase without blocking definitions.

Tracked tasks:

1. **Validate the 156 keyword-parameter baseline** — estimate: 1 h
2. **Complete `ReadWrite` enum values** — estimate: 1–2 h
3. **Complete `FloatFormat` enum values / verify its modeling** — estimate: 1–2 h
4. **Audit suspect keyword catalog rows** — estimate: 2–4 h
5. **Audit unclassified keyword rows 140–144** — estimate: 1–2 h
6. **Add parameter and reference regression checks** — estimate: 2–3 h

Estimated milestone total:

```text
8–14 hours
```

---

## 26. Milestone 2 — Definition Grammar Model

Goal: stabilize the grammar-edge model before large-scale definition population.

Tracked tasks:

1. **Finalize definitions schema** — estimate: 2–3 h
2. **Finalize definition cardinality semantics** — estimate: 1–2 h
3. **Define grammar ordering semantics** — estimate: 2–4 h
4. **Add definition integrity validation** — estimate: 2–3 h
5. **Document the definitions grammar model** — estimate: 1–2 h

Estimated milestone total:

```text
8–14 hours
```

---

## 27. GitHub Bootstrap Script

A bootstrap script was created during project organization:

```text
setup-a2l-spec-db.sh
```

Its purpose is to create the GitHub organization for Milestones 0–2, including:

- project labels
- Milestone 0
- Milestone 1
- Milestone 2
- GitHub Project
- workflow status field
- Milestone 0–2 issues
- estimates in issue bodies
- acceptance criteria
- project item assignment
- duplicate-issue avoidance/idempotent behavior

Before running it, review it against the target repository and current GitHub CLI behavior.

Typical prerequisites:

```bash
gh auth login
gh auth refresh -s project
```

---

## 28. Validation Philosophy

The database should prefer explicit validation over assumptions.

After each logical data batch, check at least:

- foreign-key integrity
- duplicate relationships
- cardinality validity
- version consistency
- grammar-domain consistency
- unexpected catalog use
- enum integrity
- expected counts where counts are meaningful invariants

Do not make validation pass by weakening rules around known problems.

Represent known exceptions explicitly and resolve them through tracked issues.

---

## 29. A2L / A2ML Boundary

Keep A2L and A2ML separate throughout the schema and grammar model.

A2ML catalog tokens currently include:

```text
module
struct
enum
typedef
array
record
uchar
uint16
uint32
char
```

They should not be treated as ordinary A2L keyword constructs.

A2ML work is a later milestone.

The important integration point is:

```text
A2L IF_DATA
      |
      v
applicable A2ML grammar
```

The exact selection/switching mechanism still needs to be designed.

---

## 30. Current Next Action

Do **not** immediately continue adding more definition rows.

The current priority is project organization:

```text
Milestone 0
    |
    v
Milestone 1 cleanup can proceed
    |
    v
Milestone 2 definitions model stabilization
    |
    v
resume A2L definition population
```

Once Milestone 2 is stable:

1. verify the current DB/schema rather than trusting historical counts;
2. trace the complete `MODULE` child grammar;
3. insert only confirmed catalog-backed relationships;
4. validate the batch;
5. continue to `MOD_COMMON`;
6. continue to `MOD_PAR`;
7. then proceed into `MEASUREMENT`, `CHARACTERISTIC`, and other major objects.

---

## 31. Instructions for Future AI Sessions

When continuing this project in a new ChatGPT/Codex session:

1. Read this handoff first.
2. Inspect the **actual current SQLite database** before making assumptions.
3. Inspect current migrations/schema.
4. Run existing validation before modifying data.
5. Treat repository state as newer than this handoff if they disagree.
6. Do not invent missing keywords, enum values, references, or definition edges.
7. Trace public grammar evidence before adding grammar relationships.
8. Keep A2L and A2ML domains separate.
9. Preserve intentional `NULL` references.
10. Preserve intentional zero-parameter constructs.
11. Use explicit enum ordinals.
12. Add changes incrementally and validate each logical batch.
13. Update this handoff after significant architectural or milestone changes.

Suggested opening instruction:

> Continue the A2L/A2ML parser database project. Read `docs/handoff/current-state.md`, inspect the current SQLite database and schema/migrations, run the existing validation, and treat the repository as the source of truth. Do not make grammar changes until you have reconciled the handoff with the actual database state.

---

## 32. Handoff Maintenance Rule

This file is a **living summary**, not a raw chat transcript.

Update it when:

- a milestone is completed;
- schema semantics change;
- an important modeling decision changes;
- expected counts change;
- a suspect keyword is resolved;
- a catalog gap is intentionally filled;
- A2ML architecture is established;
- the canonical next action changes.

Do not fill it with routine implementation details that already belong in commits, issues, migrations, or decision records.

The goal is that a future development session can understand the project in minutes without needing access to the original ChatGPT conversation.
