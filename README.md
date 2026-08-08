# A2L / ASAP2 Specifications Database — Project Context & Roadmap

## 1. Project Goal

Build a complete, maintainable **A2L / ASAP2 lexer and parser** by creating a community-derived machine-readable representation of the A2L language specification.

The project should eventually provide:

- A comprehensive A2L keyword catalog
- Enumeration types and values
- Keyword grammar definitions
- Keyword parameters and parameter types
- Parent/child relationships
- Version-specific grammar differences
- Evidence/provenance for every definition
- Public A2L examples
- Generated lexer/parser artifacts
- Eventually support for ANTLR, C++, Rust, Python, etc.

The authoritative ASAM MCD-2 MC specification is useful as a reference, but the current project deliberately proceeds **without requiring the proprietary ASAM specification**. Instead, the grammar is reconstructed from:

- Public A2L files
- Open-source A2L parsers
- Open-source grammar implementations
- Public documentation
- Multiple independent implementations for cross-validation

The database is intended to become the **canonical normalized representation** of the reconstructed grammar.

---

# 2. Overall Architecture

The intended architecture is:

```text
Public A2L files
       │
       ├───────────────┐
       │               │
       ▼               ▼
Open-source parsers   Public grammars
       │               │
       └───────┬───────┘
               ▼
       Extraction / Import
               │
               ▼
        Normalized SQLite DB
               │
       ┌───────┼─────────┐
       ▼       ▼         ▼
     Lexer   Parser   Documentation
    tables   grammar
```

SQLite is intended to be the **source of truth**.

JSON, ANTLR grammars, generated source code, documentation, etc. are considered generated artifacts rather than authoritative data.

---

# 3. Phase 1 — Build the Specification Database

## Goal

Create a normalized SQLite database capable of representing the A2L language.

The original idea was a `keywords.json` catalog, but this was intentionally changed to SQLite because the project will eventually contain relationships between:

- keywords
- versions
- parameters
- enum types
- enum values
- parent/child grammar rules
- source implementations
- evidence
- examples

A relational database is better suited to this information.

---

# 4. Phase 1 Database Schema

The current finalized schema consists of these tables.

## Lookup tables

```text
keyword_types
parameter_types
versions
source_types
definition_status
```

## Grammar tables

```text
keywords
definitions
definition_parameters
definition_children
```

## Enumeration tables

```text
enum_types
enum_values
```

## Provenance tables

```text
sources
definition_sources
definition_evidence
```

## Supporting tables

```text
examples
notes
```

---

# 5. Database Relationships

The conceptual model is:

```text
keyword_types
      │
      ▼
keywords
      │
      │ 1:N
      ▼
definitions
      │
      ├───────────────┐
      │               │
      ▼               ▼
definition_parameters definition_children
      │               │
      ▼               ▼
parameter_types     definitions
```

Definitions are version-specific.

For example:

```text
MEASUREMENT
    │
    ├── A2L 1.60 definition
    │
    └── A2L 1.71 definition
```

This allows grammar differences between A2L versions without duplicating the lexical keyword itself.

---

# 6. Important Concept: Keyword vs Definition

A **keyword** represents the lexical concept:

```text
MEASUREMENT
```

A **definition** represents its grammar in a specific version:

```text
MEASUREMENT
A2L 1.71
parameters = ...
children   = ...
```

Therefore:

```text
keywords
    |
    +---- definitions
             |
             +---- parameters
             +---- children
             +---- evidence
             +---- sources
```

This distinction is fundamental to the project.

---

# 7. Final Phase 1 SQL Schema

The current schema contains approximately:

```sql
keyword_types
parameter_types
versions
source_types
definition_status

sources

keywords
definitions

definition_parameters
definition_children

enum_types
enum_values

definition_sources
definition_evidence

examples
notes
```

The schema uses:

- foreign keys
- cascading deletes where appropriate
- unique constraints
- check constraints
- indexes
- `NULL` for unbounded cardinality
- transactions
- version-specific definitions

SQLite foreign keys are enabled using:

```sql
PRAGMA foreign_keys = ON;
```

---

# 8. Important Schema Decisions

## `max_occurs`

`NULL` means unlimited.

For example:

```text
MODULE -> MEASUREMENT

min_occurs = 0
max_occurs = NULL
```

means zero or more measurements.

Do NOT use `-1`.

---

## Canonical definitions

`definitions.is_canonical` identifies the normalized grammar definition selected after comparing multiple sources.

This allows us to retain conflicting or alternative definitions without losing evidence.

---

## Source classification

`source_types` currently supports:

```text
parser
grammar
sample
vendor
documentation
```

This allows provenance to distinguish, for example:

```text
a2ltool             -> parser
ANTLR grammar       -> grammar
production A2L      -> sample
Vector A2L          -> vendor
public documentation -> documentation
```

---

# 9. Provenance Model

A key design principle is:

> Every important grammar fact should be traceable to its source.

The database therefore has:

```text
sources
    │
    ▼
definition_sources
    │
    ▼
definitions
```

and:

```text
definition_evidence
```

which can contain:

```text
definition
source
confidence
note
```

For example:

```text
MEASUREMENT / A2L 1.71

Sources:
    a2ltool          confidence 1.00
    a2l-grpc         confidence 1.00
    calibrationReader confidence 0.95
    public A2L files confidence 1.00
```

This is important because this project is reconstructing the specification from public evidence rather than directly importing the ASAM specification.

---

# 10. Database Views

Several views were proposed to make the database easy to inspect.

## `vw_definitions`

One row per definition.

Expected columns:

```text
definition_id
keyword
keyword_type
version
status
is_canonical
description
created_at
```

---

## `vw_definition_parameters`

Shows:

```text
keyword
position
parameter
parameter_type
required
default_value
```

---

## `vw_definition_children`

Shows:

```text
parent
child
min_occurs
max_occurs
display_order
```

---

## `vw_definition_complete`

Aggregates a definition into a convenient overview:

```text
keyword
version
status
parameters
child_keywords
sources
```

This is intended as the primary human-readable overview.

---

# 11. Tables Deliberately Deferred

Two additional tables were discussed but intentionally **not added yet**.

## `lexer_tokens`

Would eventually represent:

```text
BEGIN
END
INCLUDE
IDENTIFIER
INTEGER
FLOAT
STRING
...
```

This is intentionally separate from grammar keywords.

---

## `parameter_constraints`

Would eventually represent semantic constraints such as:

```text
parameter must use an enum
parameter must reference another keyword
integer range
string pattern
etc.
```

These are deferred until the core catalog has been populated.

---

# 12. Phase 1.1 — Enumerations

The next immediate task is populating:

```text
enum_types
enum_values
```

This was chosen as the starting point because enumeration values are relatively finite and will later be referenced by keyword parameters.

Examples include:

```text
CharacteristicType
DataType
ByteOrder
AddressType
IndexOrder
Monotony
ConversionType
MemoryType
CalibrationAccess
DepositMode
...
```

Example conceptual representation:

```text
enum_types

CharacteristicType
DataType
ByteOrder
```

and:

```text
enum_values

CharacteristicType:
    VALUE
    CURVE
    MAP
    CUBOID
    CUBE_4
    CUBE_5

DataType:
    UBYTE
    SBYTE
    UWORD
    SWORD
    ULONG
    SLONG
    A_UINT64
    A_INT64
    FLOAT32_IEEE
    FLOAT64_IEEE
```

These values still need to be systematically verified against public sources.

---

# 13. Important Enumeration Schema Consideration

The existing schema is:

```sql
enum_types
-----------
id
name
description
```

```sql
enum_values
-----------
id
enum_type_id
name
ordinal
```

An improvement was proposed to add:

```text
enum_types.is_flags
enum_types.created_at
```

and:

```text
enum_values.value
enum_values.description
```

The reason is that `ordinal` and semantic numeric value are potentially different concepts.

For example:

```text
ordinal = position in specification
value   = actual numeric value
```

This should be decided before bulk-populating enums.

---

# 14. Phase 2 — Keyword Catalog

After enumerations, populate:

```text
keywords
```

The original objective was approximately 180–200 A2L keywords, but the final catalog should be **evidence-driven**, not based on an assumed number.

Potential sources include:

```text
DanielT/a2ltool
a2lfile
a2l-grpc
calibrationReader
public A2L files
other open-source ASAP2 implementations
```

The process should be:

```text
source
  ↓
extract candidate keywords
  ↓
normalize spelling
  ↓
deduplicate
  ↓
classify
  ↓
insert into keywords
  ↓
attach evidence
```

---

# 15. Keyword Normalization

A2L names should generally be normalized to uppercase.

For example:

```text
alignment_byte
Alignment_Byte
ALIGNMENT_BYTE
```

becomes:

```text
ALIGNMENT_BYTE
```

The lexical identity should therefore be stored once in:

```text
keywords.name
```

---

# 16. Keyword Classification

Each keyword will eventually receive a `keyword_type`.

Initial categories:

```text
block
attribute
enum_literal
```

However, this classification should be based on observed grammar behavior rather than assumptions.

Examples:

```text
PROJECT          -> block
MODULE           -> block
MEASUREMENT      -> block
FORMAT           -> attribute
```

Enumeration values such as:

```text
VALUE
CURVE
MAP
```

should normally be represented in `enum_values`, not duplicated as grammar keywords.

---

# 17. Phase 3 — Keyword Definitions

Once keywords exist, create version-specific definitions.

Example:

```text
keywords
---------
MEASUREMENT
```

then:

```text
definitions
-----------
MEASUREMENT / 1.60
MEASUREMENT / 1.71
```

Each definition can contain:

```text
description
status
is_canonical
```

and is connected to:

```text
definition_parameters
definition_children
definition_sources
definition_evidence
```

---

# 18. Phase 3 — Parameters

For a keyword definition, parameters are stored in positional order.

Conceptually:

```text
MEASUREMENT

1  Identifier
2  String
3  DataType
4  ...
```

Database representation:

```text
definition_parameters

definition_id
position
name
parameter_type_id
required
default_value
```

The `position` is important because A2L syntax is positional.

---

# 19. Phase 3 — Child Relationships

Nested A2L blocks are represented by:

```text
definition_children
```

Example:

```text
PROJECT
 ├── HEADER
 └── MODULE

MODULE
 ├── MEASUREMENT
 └── CHARACTERISTIC
```

Each relationship contains:

```text
parent_definition_id
child_definition_id
min_occurs
max_occurs
display_order
```

Example:

```text
PROJECT -> MODULE

min_occurs = 1
max_occurs = NULL
```

means one or more modules.

---

# 20. Phase 4 — Grammar / Parser Generation

After the database contains enough verified definitions, use it to generate parser artifacts.

The intended pipeline is:

```text
SQLite
   │
   ├── keyword catalog
   ├── enums
   ├── parameters
   └── child relationships
          │
          ▼
     Grammar generator
          │
      ┌───┴────┐
      ▼        ▼
   Lexer     Parser
```

Potential outputs:

```text
ANTLR grammar
C++ parser tables
Rust parser
Python parser
JSON grammar export
Markdown reference
HTML documentation
```

---

# 21. Proposed Phase 4 Grammar Model

Ultimately a definition should be convertible to something conceptually like:

```text
MEASUREMENT
    ::= "MEASUREMENT"
        Identifier
        String
        DataType
        ...
        ChildRules*
```

while:

```text
PROJECT
    ::= "PROJECT"
        Identifier
        String
        HEADER?
        MODULE+
```

The exact grammar should only be generated after the database has enough evidence.

---

# 22. Lexer Architecture

The eventual lexer should distinguish:

```text
/begin
/end
/include
```

from:

```text
PROJECT
MODULE
MEASUREMENT
CHARACTERISTIC
...
```

and from generic lexical tokens:

```text
IDENTIFIER
STRING
INTEGER
FLOAT
HEX
COMMENT
WHITESPACE
```

A key design decision was made:

> `/begin` and `/end` should eventually be treated as lexical tokens/directives rather than ordinary A2L grammar keywords.

The `lexer_tokens` table was discussed but intentionally deferred.

---

# 23. Parser Architecture

The parser should eventually be **table-driven** as much as practical.

Rather than hard-coding hundreds of parser rules independently, use:

```text
SQLite grammar definition
        ↓
parser generator
        ↓
generated parser
```

This makes it possible to update the parser when new A2L versions or vendor extensions are discovered.

---

# 24. Version Handling

Versions already represented in the database include:

```text
1.30
1.40
1.50
1.60
1.61
1.70
1.71
```

The database should support:

```text
keyword exists in version
keyword definition changes between versions
parameter changes between versions
child relationship changes between versions
```

without duplicating the lexical keyword itself.

---

# 25. Vendor Extensions

The architecture is intentionally designed to support vendor-specific extensions.

For example:

```text
standard definition
       +
vendor definition
       +
vendor source
       +
evidence
```

The `sources.source_type` field can identify:

```text
vendor
```

and `definitions.is_canonical` can distinguish the normalized definition from alternatives.

---

# 26. Evidence / Confidence Model

Do not immediately assume that every extracted construct is correct.

Instead:

```text
candidate
   ↓
observed in one source
   ↓
observed in multiple sources
   ↓
cross-validated against A2L files
   ↓
canonical
```

Suggested confidence interpretation:

```text
1.00  strongly verified
0.90+ multiple independent sources
0.70+ plausible
<0.70 candidate / needs investigation
```

The exact policy can be refined later.

---

# 27. Source Strategy

The project should prioritize multiple independent implementations.

Candidate sources:

```text
DanielT/a2ltool
a2lfile
a2l-grpc
calibrationReader
public A2L examples
other public ASAP2 implementations
```

Each source should be recorded in:

```text
sources
```

with:

```text
source_type
name
url
version
```

Never silently merge conflicting definitions.

Instead:

```text
source A -> definition A
source B -> definition B
```

then determine which one is canonical.

---

# 28. Recommended Data Population Order

The current recommended order is:

```text
PHASE 1
│
├── database schema
│
├── enum_types
│
├── enum_values
│
├── keyword_types
│
├── parameter_types
│
├── versions
│
└── sources
        │
        ▼
PHASE 2
│
└── keywords
        │
        ▼
PHASE 3
│
├── definitions
├── definition_parameters
├── definition_children
├── definition_sources
└── definition_evidence
        │
        ▼
PHASE 4
│
├── grammar validation
├── parser generation
├── lexer generation
└── public A2L test corpus
```

---

# 29. Current Status

Completed conceptually:

- Project objective defined
- Public-source strategy selected
- SQLite selected as canonical database
- Relational architecture designed
- Version-specific definitions introduced
- Provenance/evidence model introduced
- Database views designed
- Lexer/parser generation architecture outlined
- Phase 1–4 roadmap established

Current active task:

> **Populate `enum_types` and `enum_values` from public A2L/parser sources.**

---

# 30. Important Deferred Work

Do not add these yet unless required:

```text
lexer_tokens
parameter_constraints
```

They will be considered after the core specification catalog is populated.

Also defer:

- complete semantic validation
- cross-reference resolution
- A2ML parsing
- vendor-specific extensions
- parser implementation
- lexer implementation
- generated ANTLR grammar

until the underlying grammar data is sufficiently mature.

---

# 31. Immediate Next Step

Start with enumeration extraction.

For each discovered enum type, record:

```text
enum type name
description
source
```

For each value:

```text
enum type
value name
ordinal
semantic numeric value, if known
description
source/evidence
```

The first pass should focus on **discovery**, not prematurely deciding what is canonical.

The workflow should be:

```text
Public parser source
        ↓
Extract enum candidates
        ↓
Normalize names
        ↓
Group into enum types
        ↓
Cross-check against other sources
        ↓
Insert into SQLite
        ↓
Mark confidence/evidence
```

The ultimate objective is a database that can answer questions such as:

```sql
-- What enum values exist?
SELECT *
FROM enum_values;

-- What values belong to DataType?
SELECT ev.*
FROM enum_values ev
JOIN enum_types et
  ON ev.enum_type_id = et.id
WHERE et.name = 'DataType';

-- Which definitions use a particular enum?
-- (Once parameter enum references are modeled.)
```

---

# 32. Guiding Principle

The most important project principle is:

> **The SQLite database is the canonical representation of the reconstructed A2L language; parsers, grammars, JSON, documentation, and source code are generated or derived artifacts.**

Do not optimize for quickly producing a 200-keyword list.

Optimize for producing a **traceable, version-aware, normalized grammar database** that can eventually generate a reliable parser.
