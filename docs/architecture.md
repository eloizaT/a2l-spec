# Architecture

## Project Goal

Build a SQLite-backed grammar and metadata model for an A2L/A2ML parser.

The ultimate deliverable is the **SQLite database**. Repository tooling, migrations, seeds, validation scripts, and documentation exist to make that database reproducible, reviewable, and maintainable.

The project models:

- A2L keywords and metadata
- Positional keyword parameters
- Enum types with explicit ordinals
- Keyword references and relationships
- Parent/child grammar relationships
- Cardinality and optionality
- Grammar ordering semantics
- A2L/A2ML grammar-domain separation
- A2ML grammar used by constructs such as `IF_DATA`

## Repository Structure

```text
a2l-spec/
├── README.md
├── LICENSE
├── .gitignore
├── db/
│   ├── a2l_spec.db              (canonical database)
│   └── schema.sql               (schema snapshot)
├── migrations/
│   └── 001_baseline_schema.sql  (baseline schema)
├── seeds/
│   ├── keywords.sql             (keyword data)
│   ├── enum_types.sql
│   ├── enum_values.sql
│   ├── keyword_parameters.sql
│   ├── definitions.sql
│   ├── definition_children.sql
│   └── ...                      (22 tables total)
├── validation/
│   └── validate_schema.sql      (integrity checks)
├── scripts/
│   ├── build_db.py              (rebuild from migrations + seeds)
│   ├── export_seeds.py          (dump table data to SQL)
│   └── validate_db.py           (run validation checks)
├── docs/
│   ├── architecture.md          (this file)
│   ├── schema.md                (schema decisions)
│   ├── grammar-model.md         (grammar modeling rules)
│   ├── sources.md               (research sources)
│   ├── handoff/
│   │   └── current-state.md     (project handoff notes)
│   └── decisions/               (archived decision records)
└── tests/                        (future: test scripts)
```

## Canonical Workflow

```
migrations + seeds
        ↓
scripts/build_db.py
        ↓
db/a2l_spec.db (canonical database)
```

**Design principle:** The generated SQLite database should be reproducible from source-controlled SQL inputs (migrations and seeds).

Key files:
- **Migrations** (`migrations/*.sql`): Schema creation, table definitions, structure
- **Seeds** (`seeds/*.sql`): Data population, keyword/enum/parameter records
- **Build script** (`scripts/build_db.py`): Applies migrations + seeds in order to reconstruct the DB
- **Validation** (`validation/*.sql`): Checks schema integrity and constraints

## Development Phases

**Phase 1: Keyword Parameters** (COMPLETE)
- Established core schema for keywords and their positional parameters
- Baseline: 156 keyword_parameters rows
- Validation: Foreign key consistency, enum associations, reference integrity

**Phase 2: Definitions** (IN PROGRESS)
- Modeling parent/child grammar relationships
- Capturing cardinality, ordering, and grammar domains
- Separating A2L and A2ML grammar spaces

**Phase 3+**: Extended grammar, validation rules, parser integration

## Design Decisions

### Database-First Approach

The SQLite database is the project's source of truth. All tooling, documentation, and validation serve to maintain that database.

- Migrations capture schema evolution
- Seeds provide logical data that can be reviewed and audited
- Validation ensures consistency and completeness
- Rebuild workflow ensures reproducibility

### No Schema in Code

Schema changes are expressed as SQL migrations in `migrations/`, not generated from Python models or ORMs. This ensures:

- Schema decisions are transparent and reviewable
- Migrations can be inspected and understood independently
- Database state is reproducible without runtime code generation

### Source Verification

All database content must be traceable to:

1. **The A2L/A2ML specification** (grammar definition)
2. **Public reference implementations** (proof that constructs exist and behave as modeled)
3. **Explicit project decisions** (documented in this architecture)

Suspect or unverified catalog rows are documented but not automatically populated with parameters or definitions.

## Important Rules

1. **Repeated logical parameters** are stored as a single `keyword_parameters` row with `required = 0`
   - Do not multiply positional rows for repeated values
   - Cardinality belongs in grammar metadata, not positional parameter multiplication

2. **Reference relationships** use `reference_keyword_id` conservatively
   - Only set it if the parameter refers to a single, well-defined class
   - Leave it `NULL` if an identifier can refer to multiple classes

3. **A2L and A2ML remain separate**
   - A2L keywords and parameters use the standard keyword model
   - A2ML tokens and constructs are handled in a dedicated phase
   - `IF_DATA` switches to A2ML grammar, not A2L parameters

4. **Zero-parameter keywords are intentional**
   - Keywords like `ROOT`, `ANNOTATION`, `READ_WRITE` legitimately have no parameters
   - Do not treat empty parameter sets as missing data

5. **Every enum value must have an explicit ordinal**
   - Do not rely on insertion order
   - Ordinals must be verified against the specification

6. **Suspect catalog rows require audit**
   - Rows in the keyword catalog that were not confirmed in public implementations are not automatically modeled
   - Each must be traced and classified before parameters/definitions are added

## Contributors

When starting work on this repository:

1. Read `docs/architecture.md` (this file) for the big picture
2. Read `docs/schema.md` for table design and constraints
3. Read `docs/grammar-model.md` for grammar modeling rules
4. Read `docs/sources.md` for research materials and verification sources
5. Consult `docs/handoff/current-state.md` for the latest project state

All important design rules and compromises are documented here. Do not rely on chat history or previous session notes.
