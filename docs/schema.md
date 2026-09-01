# Schema Documentation

## Core Tables

### `keywords`

Stores A2L keywords and language tokens.

```sql
CREATE TABLE keywords (
    id INTEGER PRIMARY KEY,
    keyword TEXT NOT NULL UNIQUE,
    description TEXT,
    domain TEXT NOT NULL DEFAULT 'A2L',  -- A2L or A2ML
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

**Domain:** Organizes keywords into grammar spaces:
- `A2L`: Standard A2L grammar constructs (PROJECT, MODULE, CHARACTERISTIC, etc.)
- `A2ML`: A2ML tokens and constructs (module, struct, enum, etc.)

A2L and A2ML domains must remain separate. A2ML is handled in a dedicated grammar phase.

**Catalog state:**
- Main A2L keyword range: IDs 1–123
- A2ML tokens: IDs 130–139 (reserved; handled in A2ML phase)
- Special audits: IDs 140–144 (unconfirmed; require explicit verification before modeling)

**Known special cases:**
- `IF_DATA`: No ordinary A2L parameters; switches to A2ML grammar
- Parameterless keywords: `ROOT`, `ANNOTATION`, `STATIC_ADDRESS_OFFSETS`, `VARIANT_CODING`, `READ_WRITE`, `READ_ONLY` — these are intentional and do not indicate missing data

### `keyword_parameters`

Stores positional parameters for A2L keywords.

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

    FOREIGN KEY (keyword_id) REFERENCES keywords(id),
    FOREIGN KEY (enum_type_id) REFERENCES enum_types(id),
    FOREIGN KEY (reference_keyword_id) REFERENCES keywords(id),

    UNIQUE (keyword_id, position)
);
```

**Position:** 1-based index of the parameter in the keyword argument list.

**Parameter types:**
- `STRING`: Text data
- `IDENTIFIER`: Names and identifiers
- `INTEGER`: Numeric values
- `FLOAT`: Floating-point numbers
- `ADDRESS`: Memory addresses
- `ENUM`: Enumerated values (requires `enum_type_id`)
- `REFERENCE`: Keyword references (optionally `reference_keyword_id`)
- `BOOLEAN`: True/false values

**Required field:**
- `1` (true): Mandatory parameter
- `0` (false): Optional or zero-or-more logical parameter (for repeated lists)

**Important modeling rule — Repeated parameters:**

When a keyword accepts zero or more repeated values of the same logical parameter, store **one row** with `required = 0`.

Example:
```
FUNCTION_LIST identifier -> FUNCTION (repeated)
Stored as: one keyword_parameters row for FUNCTION_LIST.identifier with required=0
```

Do not multiply positional rows. Richer repetition/cardinality belongs in the definitions schema.

**Reference modeling:**

- `reference_keyword_id` is used conservatively
- Only set it if the parameter refers to a single, well-defined keyword class
- Leave it `NULL` if an identifier can refer to multiple classes

Examples of intentionally `NULL` references:
- `STRUCTURE_COMPONENT.component_type` (can reference multiple classes)
- `TRANSFORMER_IN_OBJECTS.identifier` (can reference multiple object types)
- `TRANSFORMER_OUT_OBJECTS.identifier` (can reference multiple object types)

**Baseline count:** 156 keyword_parameters rows (regression baseline)

**Validation rules:**
- No duplicate `(keyword_id, position)` pairs
- All `keyword_id` values must reference valid keywords
- ENUM parameters must have `enum_type_id` set
- Non-ENUM parameters must not have `enum_type_id`
- `reference_keyword_id` must be used conservatively (verified case-by-case)
- `required` must be 0 or 1
- Positions must be contiguous (no gaps) within a keyword
- Parameter names must not be empty

### `enum_types`

Stores enumeration type definitions.

```sql
CREATE TABLE enum_types (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

**Known enum types:**
- `CharacteristicType`
- `DataType`
- `ByteOrder`
- `AddressType`
- `IndexOrder`
- `Monotony`
- `ConversionType`
- `MemoryType`
- `MemoryAttribute`
- `CalibrationAccess`
- `DepositMode`
- `ReadWrite`
- `FloatFormat`
- `AxisDescrAttribute`
- `TransformerTrigger`

**Known outstanding work:**
- `ReadWrite`: Currently 0 enum_values (verify spec and populate)
- `FloatFormat`: Currently 0 enum_values (verify spec and populate)

These gaps should not block other work. They must be verified against the specification before values are added.

### `enum_values`

Stores individual values for each enumeration type.

```sql
CREATE TABLE enum_values (
    id INTEGER PRIMARY KEY,
    enum_type_id INTEGER NOT NULL,
    value TEXT NOT NULL,
    ordinal INTEGER NOT NULL,
    description TEXT,

    FOREIGN KEY (enum_type_id) REFERENCES enum_types(id),
    UNIQUE (enum_type_id, ordinal)
);
```

**Important rule:** Every enum value must have an explicit `ordinal`.

Do not rely on insertion order. Ordinals must match the specification.

**Validation rules:**
- All `enum_type_id` values must reference valid enum types
- Ordinals must not be duplicated within an enum type
- Ordinals should match the specification exactly
- Enum types without any values are flagged as incomplete

## Definitions Schema

### `definitions`

Stores grammar definitions for keywords and versions.

```sql
CREATE TABLE definitions (
    id INTEGER PRIMARY KEY,
    keyword_id INTEGER NOT NULL,
    version TEXT NOT NULL,
    grammar_domain TEXT NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (keyword_id) REFERENCES keywords(id),
    UNIQUE (keyword_id, version, grammar_domain)
);
```

**Grammar domain:** Categorizes definitions by grammar space:
- `A2L`: Standard A2L grammar
- `A2ML`: A2ML grammar (used by constructs like `IF_DATA`)

**Important note:** Definitions own nested grammar/cardinality, not positional parameters.

Do not duplicate positional keyword arguments in the definitions model. `keyword_parameters` captures the keyword's own parameters; `definition_children` captures allowed nested keywords.

### `definition_children`

Stores parent-child grammar relationships.

```sql
CREATE TABLE definition_children (
    id INTEGER PRIMARY KEY,
    parent_id INTEGER NOT NULL,
    child_keyword_id INTEGER NOT NULL,
    min_occurs INTEGER NOT NULL DEFAULT 0,
    max_occurs INTEGER,  -- NULL = unbounded
    order_index INTEGER,
    grammar_domain TEXT NOT NULL,
    version TEXT NOT NULL,
    description TEXT,

    FOREIGN KEY (parent_id) REFERENCES definitions(id),
    FOREIGN KEY (child_keyword_id) REFERENCES keywords(id)
);
```

**Cardinality:**
- `min_occurs`: Minimum number of times the child can appear (0 = optional, 1+ = required)
- `max_occurs`: Maximum number of times (NULL = unbounded/repeated)

**Order semantics:** `order_index` represents declaration/source order.

⚠️ **Important:** `order_index` does **not** automatically mean strict textual parsing order. Ordering behavior must be verified against the actual grammar before strict parsing semantics are encoded.

### `definition_parameters`

Stores additional parameter metadata for definition-specific parameters (future use).

Allows capturing version-specific or context-specific parameter variations.

## Related Tables

### `sources`

Stores research materials and verification sources.

```sql
CREATE TABLE sources (
    id INTEGER PRIMARY KEY,
    title TEXT NOT NULL,
    url TEXT,
    publication_date TEXT,
    description TEXT
);
```

All keywords and definitions should be traceable to sources (specification, reference implementations, or explicit project decisions).

### `definition_evidence`

Links definitions and parameters to their sources.

```sql
CREATE TABLE definition_evidence (
    id INTEGER PRIMARY KEY,
    definition_id INTEGER,
    parameter_id INTEGER,
    source_id INTEGER NOT NULL,
    notes TEXT,

    FOREIGN KEY (definition_id) REFERENCES definitions(id),
    FOREIGN KEY (parameter_id) REFERENCES keyword_parameters(id),
    FOREIGN KEY (source_id) REFERENCES sources(id)
);
```

Allows auditing and tracing where each decision came from.

## Special Cases & Workarounds

### `CURVE_AXIS_REF` (Absent)

This keyword does not exist in the current keyword catalog.

Do not create relationships to it unless the catalog is intentionally expanded after research.

### `TRANSFORMER` Special Case

Has seven positional parameters:
1. name (IDENTIFIER)
2. version (STRING)
3. dllname_32bit (STRING)
4. dllname_64bit (STRING)
5. timeout (INTEGER)
6. trigger (ENUM: TransformerTrigger)
7. inverse_transformer (REFERENCE: TRANSFORMER)

The `trigger` parameter references the `TransformerTrigger` enum with values:
- `1`: ON_USER_REQUEST
- `2`: ON_CHANGE

### `MATRIX_DIM` (Variable-length)

```
position = 1
name = dimension
parameter_type = INTEGER
required = 0
```

Represents a variable-length dimension list, not fixed x/y/z positional parameters.

Do not expand it without grammar evidence.

### Suspect Catalog Rows

The following rows exist in `keywords` but were **not** confirmed as standalone A2L grammar constructs:

```
103 TRANSFORMER_IN_OBJECT
104 TRANSFORMER_OUT_OBJECT
107 TRANSFORMER_TYPE
108 TRIGGER
110 READ
111 WRITE
116 LONG_IDENTIFIER
117 SHORT_IDENTIFIER
```

Confirmed constructs include `TRANSFORMER`, `TRANSFORMER_IN_OBJECTS`, `TRANSFORMER_OUT_OBJECTS` (plural), and `READ_WRITE`, `READ_ONLY` (as access flags).

**Rule:** Do not automatically create definitions or parameters for suspect catalog rows merely because they exist. Each must be traced to the specification and classified first.

## Validation Strategy

All constraints are enforced at the database level:
- Foreign key integrity checks
- Unique constraints on primary keys and important combinations
- Explicit ordinals for enums (no reliance on insertion order)

Automated validation queries verify:
- Expected row counts (regression baselines)
- Broken foreign keys
- Missing enum values
- Duplicate enum ordinals
- Parameter position gaps
- Invalid parameter types
- Orphaned enum/reference associations

See `validation/validate_schema.sql` for the complete validation suite.
