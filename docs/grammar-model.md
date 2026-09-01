# Grammar Model

## Core Modeling Principles

The grammar model captures the structure and relationships of A2L/A2ML constructs.

Two distinct but complementary models work together:

1. **Positional Parameters** (`keyword_parameters`)
   - The parameters/arguments that belong to a keyword itself
   - Fixed positions in the keyword's argument list
   - Does not model repetition or nesting

2. **Definitions and Children** (`definitions` + `definition_children`)
   - The nested keywords allowed inside a keyword block
   - Parent-child grammar relationships
   - Cardinality (optional, required, repeated)
   - Grammar domain separation (A2L vs A2ML)

These are **complementary, not redundant**:

```
PROJECT
├── name (parameter)           ← keyword_parameters
├── version (parameter)        ← keyword_parameters
└── MODULE {...}              ← definition_children
    ├── name (parameter)       ← keyword_parameters (MODULE's)
    └── CHARACTERISTIC {...}  ← definition_children (MODULE's)
```

## Grammar Domains

### A2L (AUTOSAR to List)

The primary A2L 1.71 grammar defines standard keywords and their structure.

Key concepts:
- **Keyword catalog**: Defined set of keywords (roughly 120–130 in current research)
- **Positional parameters**: Fixed argument positions with types (STRING, INTEGER, ENUM, REFERENCE, etc.)
- **Grammar hierarchy**: Parent-child relationships between keywords

### A2ML (AUTOSAR to Meta Language)

A2ML is used by constructs like `IF_DATA` to define custom data structures.

**Architectural rule:**

```
ordinary A2L keyword
    → keyword_parameters (standard positional model)

IF_DATA
    → select/use applicable A2ML grammar
```

A2L and A2ML grammar domains must remain separate.

- A2ML tokens (`module`, `struct`, `enum`, `typedef`, `array`, `record`, etc.) are in the keyword catalog but handled in a dedicated phase
- A2ML parameter modeling differs from A2L
- Grammar validation considers domains separately

## Repeated Parameters

### The Problem

Many A2L keywords accept zero or more repeated instances of the same logical parameter.

Example:
```
FUNCTION_LIST identifier -> FUNCTION
FUNCTION_LIST identifier -> FUNCTION
FUNCTION_LIST identifier -> FUNCTION
(repeated as many times as needed)
```

### The Solution

Store **one logical parameter row** with `required = 0`.

```sql
INSERT INTO keyword_parameters
    (keyword_id, position, name, parameter_type, required, reference_keyword_id)
VALUES
    (FUNCTION_LIST_id, 1, 'identifier', 'REFERENCE', 0, FUNCTION_id);
```

### Why Not Multiply Rows?

❌ **Wrong approach:** Add multiple positional rows for the same semantic parameter

```sql
-- ❌ DO NOT DO THIS
INSERT INTO keyword_parameters VALUES (NULL, function_list_id, 1, 'identifier', 'REFERENCE', 0, NULL, FUNCTION_id);
INSERT INTO keyword_parameters VALUES (NULL, function_list_id, 2, 'identifier', 'REFERENCE', 0, NULL, FUNCTION_id);
INSERT INTO keyword_parameters VALUES (NULL, function_list_id, 3, 'identifier', 'REFERENCE', 0, NULL, FUNCTION_id);
```

This creates false "positional" constraints and obscures the semantic model.

### Cardinality Belongs in Definitions

Richer repetition and cardinality semantics belong in the `definition_children` schema:

```sql
INSERT INTO definition_children
    (parent_id, child_keyword_id, min_occurs, max_occurs, grammar_domain, version)
VALUES
    (FUNCTION_LIST_def_id, FUNCTION_id, 1, NULL, 'A2L', '1.71');
```

Here:
- `min_occurs = 1`: At least one FUNCTION is required
- `max_occurs = NULL`: Unbounded (zero or more additional instances)

## Reference Modeling

### Conservative Reference Assignment

The `reference_keyword_id` in `keyword_parameters` should be set **only when**:

1. The parameter clearly and exclusively refers to a single keyword class, **AND**
2. The specification or reference implementation confirms this

### Examples of Intentional `NULL` References

Some parameters can refer to multiple object classes. These are intentionally left `NULL`:

- **`STRUCTURE_COMPONENT.component_type`**
  - Can refer to multiple component types (not a single keyword target)
  - Type resolution depends on context

- **`TRANSFORMER_IN_OBJECTS.identifier`**
  - Can reference multiple input object classes
  - Flexibility required by the grammar

- **`TRANSFORMER_OUT_OBJECTS.identifier`**
  - Can reference multiple output object classes
  - Flexibility required by the grammar

### Rule

Do **not** invent a single target merely to make `reference_keyword_id` non-null.

If the grammar permits multiple classes, leave it `NULL` and document the flexibility.

## A2L/A2ML Separation

### Architectural Rule

A2L and A2ML grammar domains must remain separate.

- **A2L keywords** use the standard `keyword_parameters` and `definition_children` model
- **A2ML tokens** are handled in a dedicated phase with their own grammar rules
- **`IF_DATA`** blocks do not have ordinary A2L positional parameters; they use A2ML constructs instead

### Why Separate?

1. **Different grammars**: A2L has fixed positional parameters; A2ML uses declarations and type definitions
2. **Different validation rules**: Enum values, reference targets, and parameter types differ between domains
3. **Clarity**: Keeps models from becoming overly complex with conditional logic
4. **Extensibility**: Allows A2ML grammar to evolve independently

### Implementation

Definitions and keywords store a `grammar_domain` field:

```sql
CREATE TABLE definitions (
    ...
    grammar_domain TEXT NOT NULL,  -- 'A2L' or 'A2ML'
    ...
);

CREATE TABLE keywords (
    ...
    domain TEXT NOT NULL DEFAULT 'A2L',  -- 'A2L' or 'A2ML'
    ...
);
```

A2ML tokens in the keyword catalog (IDs 130–139) are reserved and handled separately.

## Keyword Behavior

### Intentionally Parameterless Keywords

Some keywords legitimately have zero positional parameters:

- **`ROOT`**: A container; no parameters
- **`ANNOTATION`**: Metadata; no position-specific arguments
- **`STATIC_ADDRESS_OFFSETS`**: A container; structured nested keywords
- **`VARIANT_CODING`**: A container; complex nested structure
- **`IF_DATA`**: Uses A2ML grammar, not A2L parameters
- **`READ_WRITE`**: An access flag; no parameters
- **`READ_ONLY`**: An access flag; no parameters

**Rule:** Do not treat empty parameter sets as missing data. Some keywords are intentionally parameterless containers or flags.

### Zero-Parameter Container Keywords

Keywords that have no positional parameters but contain nested grammar should still have `definition_children` records:

```sql
-- IF_DATA has no keyword_parameters
-- But it can contain A2ML-governed nested constructs
INSERT INTO definition_children
    (parent_id, child_keyword_id, min_occurs, max_occurs, grammar_domain, version)
VALUES
    (IF_DATA_def_id, SOME_A2ML_CONSTRUCT_id, 1, NULL, 'A2ML', '1.71');
```

## Enum Values and Ordinals

### Explicit Ordinals Required

Every enum value must have an explicit `ordinal` in the `enum_values` table.

**Do not rely on insertion order.**

```sql
INSERT INTO enum_values (enum_type_id, value, ordinal, description)
VALUES
    (transformer_trigger_id, 'ON_USER_REQUEST', 1, 'Triggered by user action'),
    (transformer_trigger_id, 'ON_CHANGE', 2, 'Triggered on value change');
```

### Verification Against Specification

Ordinals must match the specification exactly. Even if the implementation uses 0-based or 1-based numbering, the ordinals must reflect what the specification says.

### Known Outstanding Work

- **`ReadWrite` enum**: Currently has 0 values; requires verification against the specification
- **`FloatFormat` enum**: Currently has 0 values; requires verification against the specification

Do not populate these until the specification has been consulted and values confirmed.

## Ordering Semantics

### Position vs. Order

`keyword_parameters.position` is the position in the keyword's positional argument list. This is a **structural fact**, not a semantic rule.

`definition_children.order_index` represents declaration or source order of nested keywords. This is **not automatically** a strict textual parsing requirement.

### Important Warning

An `order_index` in `definition_children` must **not** be interpreted as:

> The parser must encounter child keywords in this strict textual order.

It may instead represent:
- Declaration/source order
- Documentation order
- Logical flow order (for human understanding)

**Before encoding strict parsing order semantics, verify the actual grammar behavior** against the specification or reference implementation.

### Example

```
PROJECT
  name
  version
  MODULE (or other...)
```

The source order might be "name, version, then MODULE", but the actual parser might accept keywords in any order as long as required ones are present.

## Definition Cardinality

### Occurs Semantics

```sql
CREATE TABLE definition_children (
    ...
    min_occurs INTEGER NOT NULL DEFAULT 0,  -- Minimum count
    max_occurs INTEGER,                      -- Maximum count (NULL = unbounded)
    ...
);
```

**Examples:**

- `min_occurs = 0, max_occurs = 1`: Optional (0 or 1)
- `min_occurs = 1, max_occurs = 1`: Required exactly once
- `min_occurs = 1, max_occurs = NULL`: Required, and can repeat
- `min_occurs = 0, max_occurs = NULL`: Optional, and can repeat

### Verification

Cardinality must be verified against the specification and reference implementations, not assumed from naming or documentation.

**Example correction found during research:**

> `FUNCTION_LIST` should **not** simply be assumed to be a child of `FUNCTION`.

The traced public grammar placed it under other applicable objects such as `CHARACTERISTIC`, while `FUNCTION` contains:
- `DEF_CHARACTERISTIC`
- `IN_MEASUREMENT`
- `LOC_MEASUREMENT`
- `OUT_MEASUREMENT`
- `REF_CHARACTERISTIC`
- `SUB_FUNCTION`

Always verify relationships against traced grammar, not conceptual examples.

## Suspect Rows and Audit Requirements

Certain keywords exist in the catalog but were not confirmed as standalone parameterized constructs in the public implementations researched:

```
103 TRANSFORMER_IN_OBJECT   (suspect; plural form TRANSFORMER_IN_OBJECTS confirmed)
104 TRANSFORMER_OUT_OBJECT  (suspect; plural form TRANSFORMER_OUT_OBJECTS confirmed)
107 TRANSFORMER_TYPE        (suspect; requires audit)
108 TRIGGER                 (suspect; possibly internal implementation detail)
110 READ                    (suspect; READ_WRITE and READ_ONLY confirmed instead)
111 WRITE                   (suspect; READ_WRITE and READ_ONLY confirmed instead)
116 LONG_IDENTIFIER         (suspect; requires audit)
117 SHORT_IDENTIFIER        (suspect; requires audit)
```

### Rule

Do **not** automatically create definitions or parameters for suspect catalog rows merely because they exist in the catalog.

**Each must be traced to the specification and classified first.** Only then should parameters/definitions be added.

Track audit status in comments or a separate tracking table.

## Grammar Correction Example

**Do not blindly trust early conceptual examples.**

One concrete correction discovered during grammar tracing:

**Incorrect conceptual model:**
```
FUNCTION
  └── FUNCTION_LIST (assumed child)
```

**Verified actual grammar:**
```
CHARACTERISTIC
  └── FUNCTION_LIST (actual parent)

FUNCTION
  ├── DEF_CHARACTERISTIC
  ├── IN_MEASUREMENT
  ├── LOC_MEASUREMENT
  ├── OUT_MEASUREMENT
  ├── REF_CHARACTERISTIC
  └── SUB_FUNCTION
```

**Lesson:** Always trace against the public grammar specification before finalizing parent-child relationships. Correct early; iterate as needed.
