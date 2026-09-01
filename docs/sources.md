# Sources and Research

## Primary Sources

### AUTOSAR to List (A2L) Specification

**A2L 1.71 (AUTOSAR 4.2+)**

- Official specification for A2L grammar and structure
- Defines keywords, parameters, parameter types, and nesting rules
- Authority for cardinality, version-specific features, and enum values
- Used for:
  - Keyword catalog verification
  - Positional parameter definitions
  - Enum value ordinals and meanings
  - Grammar hierarchy and cardinality
  - Version-specific behavior differences

All keywords and parameter definitions in this project should be traceable to the A2L specification.

### AUTOSAR to Meta Language (A2ML)

- Grammar definition language used by `IF_DATA` blocks in A2L
- Defines custom data structures within A2ML-governed blocks
- Separate from the core A2L positional parameter model
- Handled in a dedicated grammar phase

## Reference Implementations

### Public Reference Parser

Reference implementations are used to verify that:

1. Keywords and parameters exist as modeled in the specification
2. Nesting relationships match the actual grammar
3. Enum values and their ordinals are correct
4. Version-specific differences are properly captured

### Verification Procedure

When modeling a keyword or parameter:

1. Consult the A2L specification
2. Verify the construct in a public reference implementation
3. Document the source (specification section, example code, or reference implementation)
4. Add evidence record to the `sources` and `definition_evidence` tables

**Example:**

```sql
INSERT INTO sources (title, url, publication_date, description)
VALUES
    ('AUTOSAR 4.2 A2L Specification', 'https://...', '2020-01-01',
     'Official A2L 1.71 grammar definition');

INSERT INTO definition_evidence
    (definition_id, source_id, notes)
VALUES
    (characteristic_def_id, (SELECT id FROM sources WHERE title LIKE 'AUTOSAR%'),
     'Confirmed in AUTOSAR 4.2, section 8.3.2');
```

## Known Gaps and Outstanding Audits

### Enum Values Requiring Specification Review

| Enum Type | Status | Notes |
|-----------|--------|-------|
| `ReadWrite` | 0 values | Requires spec verification before population |
| `FloatFormat` | 0 values | Requires spec verification before population |

Do not populate these until the specification has been explicitly consulted and values confirmed.

### Keyword Catalog Rows Requiring Audit

The following rows exist in the keyword catalog but were not confirmed as standalone parameterized constructs in the research materials consulted:

| ID | Keyword | Status | Action Required |
|----|---------|--------|-----------------|
| 103 | TRANSFORMER_IN_OBJECT | Suspect | Verify against spec; plural form TRANSFORMER_IN_OBJECTS confirmed |
| 104 | TRANSFORMER_OUT_OBJECT | Suspect | Verify against spec; plural form TRANSFORMER_OUT_OBJECTS confirmed |
| 107 | TRANSFORMER_TYPE | Suspect | Trace to specification or reference implementation |
| 108 | TRIGGER | Suspect | Determine if internal impl detail or public grammar |
| 110 | READ | Suspect | Verify; READ_WRITE and READ_ONLY confirmed instead |
| 111 | WRITE | Suspect | Verify; READ_WRITE and READ_ONLY confirmed instead |
| 116 | LONG_IDENTIFIER | Suspect | Audit for standalone parameterized role |
| 117 | SHORT_IDENTIFIER | Suspect | Audit for standalone parameterized role |

**Rule:** Do not automatically add parameters or definitions for these rows. Each requires explicit audit and verification.

Track audit status in the `keywords` table or in a separate audit log.

### Attributes and Special Constructs Requiring Audit

Rows 140–144 exist in the keyword catalog but require explicit audit:

| ID | Keyword | Processed | Status |
|----|---------|-----------|--------|
| 140 | ATTRIBUTE | No | Requires spec verification |
| 141 | CALIBRATION_ACCESS | Yes | Confirmed and assigned to A2L domain |
| 142 | CHARACTERISTIC_TYPE | No | Requires spec verification |
| 143 | FLOAT_FORMAT | No | Requires spec verification (enum values missing) |
| 144 | INDEX_ORDER | No | Requires spec verification (enum values missing) |

`CALIBRATION_ACCESS` has already been confirmed and modeled. The others require research before inclusion.

## Research Procedures

### Grammar Tracing

When tracing parent-child grammar relationships:

1. Consult the A2L specification for allowed nesting
2. Verify in a public reference implementation or parser
3. Check example A2L files for real-world usage patterns
4. Document the source and any edge cases discovered

**Example:** During definitions research, grammar tracing revealed that `FUNCTION_LIST` is a child of `CHARACTERISTIC` and other constructs, **not** a child of `FUNCTION`. This required correction from early conceptual assumptions.

### Specification Review

When populating enum values, parameter types, or cardinality:

1. Locate the relevant section in the A2L specification
2. Extract the exact ordinals, values, and constraints
3. Compare against reference implementations
4. Add to the database with full source documentation

### Validation Against Reference Code

Reference implementations (parser libraries, test fixtures, example programs) provide concrete evidence:

- Example A2L files showing actual grammar usage
- Test suites validating parser behavior
- Reference implementations demonstrating correct interpretation

Use these to verify:
- Keyword existence and naming
- Parameter positions and types
- Allowed nesting (definition_children relationships)
- Enum values and ordinals
- Version-specific differences

## Documentation Guidelines for Contributors

When adding new keywords, parameters, or definitions:

1. **Trace the source:** Document which section of the spec or which reference implementation confirms this construct
2. **Add evidence:** Create a `sources` record and link it via `definition_evidence`
3. **Audit suspect rows:** If modeling a suspect row, document the audit and decision
4. **Verify cardinality:** Trace parent-child relationships against the actual grammar, not conceptual assumptions
5. **Check enum values:** Ensure all enum values have explicit ordinals from the specification

Example workflow:

```sql
-- 1. Add or verify source
INSERT INTO sources (title, url, description)
    VALUES ('A2L 1.71 Spec - Section 9.2', NULL, 'Keyword FOO definition');

-- 2. Add definition with domain
INSERT INTO definitions (keyword_id, version, grammar_domain)
    VALUES (foo_keyword_id, '1.71', 'A2L');

-- 3. Link to source
INSERT INTO definition_evidence (definition_id, source_id)
    VALUES (LAST_INSERT_ROWID(), (SELECT id FROM sources WHERE title LIKE '%Section 9.2%'));

-- 4. Add parameters with evidence
INSERT INTO keyword_parameters (keyword_id, position, name, parameter_type, enum_type_id, reference_keyword_id)
    VALUES (foo_keyword_id, 1, 'name', 'IDENTIFIER', NULL, NULL);

-- 5. If child keywords exist, add definitions with cardinality
INSERT INTO definition_children (parent_id, child_keyword_id, min_occurs, max_occurs, grammar_domain, version)
    VALUES (foo_def_id, bar_keyword_id, 1, NULL, 'A2L', '1.71');
```

All rows should be traceable to documented sources.

## Project-Specific Decisions

### Intentional Compromises

The following are documented project decisions (not gaps):

1. **`IF_DATA` and A2ML:** A2ML grammar is handled in a dedicated phase, not embedded in A2L positional parameters
2. **Repeated parameters:** Stored as single rows with `required = 0`, not multiplied positional rows
3. **Suspect rows:** Not automatically modeled; each requires explicit audit
4. **Zero-parameter keywords:** Intentional for containers and flags
5. **Conservative references:** `reference_keyword_id` only set when a single class is clear

These are documented in:
- `docs/architecture.md` - High-level principles
- `docs/schema.md` - Specific schema rationales
- `docs/grammar-model.md` - Detailed modeling rules
- `docs/handoff/current-state.md` - Project state and phase tracking

### Version Handling

The database models version-specific differences:

- `keyword_parameters` may vary by version
- `definitions` include version field
- Enum values may be version-specific

Research and model version differences explicitly, not as implicit assumptions.

## Getting Started as a Contributor

1. **Read the architecture:** `docs/architecture.md` for project goals and principles
2. **Read the schema:** `docs/schema.md` for table design and constraints
3. **Read grammar rules:** `docs/grammar-model.md` for modeling patterns
4. **Check sources:** This file for research materials and procedures
5. **Consult handoff notes:** `docs/handoff/current-state.md` for current project state

When adding new content:

- Always verify against the A2L specification
- Document sources in the `sources` and `definition_evidence` tables
- Follow the modeling rules documented in `docs/grammar-model.md`
- Do not assume; verify and trace everything

## Future Research Areas

- **A2ML grammar**: Dedicated modeling phase for A2ML-governed constructs
- **Enum value completion**: Review and populate `ReadWrite` and `FloatFormat` ordinals
- **Suspect keyword audit**: Classify all suspect catalog rows
- **Version differences**: Model version-specific parameter and grammar changes
- **Ordering semantics**: Verify strict parsing order vs. declaration order
- **Extended validation**: Add parser-side validation checks (parent-child consistency, parameter constraints)
