# A2L/A2ML Specification Database

A SQLite-backed grammar and metadata database for building parsers and tooling around the **ASAM MCD-2 MC (ASAP2/A2L)** format and its embedded **A2ML** grammar.

The goal of this project is to represent the structure of A2L/A2ML in a machine-readable relational model rather than embedding specification knowledge directly into parser code.

The database models concepts such as:

- A2L keywords and their metadata
- positional keyword parameters and data types
- enumeration types and values
- references between A2L objects
- parent/child grammar relationships
- required and optional grammar elements
- minimum and maximum cardinality
- repeatable constructs
- grammar ordering metadata
- A2L and A2ML grammar domains
- specification/version-specific definitions

The resulting SQLite database is intended to act as a reusable **source of grammar metadata** for parsers, validators, code generators, editors, analysis tools, and other applications that need to understand A2L structure.

## Project Philosophy

The SQLite database is the primary artifact of this repository.

Supporting migrations, seed data, validation queries, scripts, and documentation exist to make the database:

- **Reproducible** — the database can be rebuilt from version-controlled sources.
- **Traceable** — grammar relationships and modeling decisions can be tied back to researched specification behavior.
- **Validated** — foreign keys, enum values, parameter relationships, cardinalities, and grammar relationships are checked automatically.
- **Incremental** — grammar metadata is added in small, independently verifiable batches.
- **Conservative** — uncertain constructs are documented and researched rather than inferred from keyword names.
- **Extensible** — the model can evolve as additional A2L versions and A2ML grammar requirements are incorporated.

## Grammar Model

The project separates two important aspects of the language.

`keyword_parameters` describes the positional values belonging directly to a keyword:

```text
TRANSFORMER
    name
    version
    dllname_32bit
    dllname_64bit
    timeout
    trigger
    inverse_transformer
```

Grammar definitions describe which keywords may occur inside another construct:

```text
PROJECT
├── HEADER
└── MODULE*

MODULE
├── MOD_COMMON
├── MOD_PAR
├── MEASUREMENT*
├── CHARACTERISTIC*
├── FUNCTION*
├── GROUP*
└── ...
```

This distinction allows the database to describe both the **syntax of an individual keyword** and the **structure of an A2L document**.

Child grammar relationships can additionally carry cardinality information such as:

```text
?    optional
*    zero or more
+    one or more
1    exactly once
```

rather than reducing repetition to a simple required/optional flag.

## A2L and A2ML

A2L and A2ML are modeled as separate grammar domains.

Ordinary A2L constructs use the A2L keyword and definition metadata. Constructs such as `IF_DATA`, whose contents are governed by an applicable A2ML description, form the integration point between the two grammar systems.

A2ML grammar support is intentionally treated as a separate phase rather than modeling A2ML tokens as ordinary A2L keywords.

## Database-First Design

The project is intentionally not tied to a particular parser implementation or programming language.

Conceptually:

```text
A2L/A2ML specification knowledge
              │
              ▼
       SQLite metadata DB
              │
      ┌───────┼─────────┐
      ▼       ▼         ▼
   Parser  Validator   Tools
```

A consumer can query the database to determine, for example:

- which parameters a keyword accepts;
- the expected parameter types;
- whether a parameter references another A2L object;
- which enum values are valid;
- which child keywords are permitted inside a block;
- whether a child is optional, required, or repeatable;
- which grammar domain or specification version a definition belongs to.

## Repository Structure

```text
.
├── db/             # Canonical generated SQLite database and schema snapshot
├── migrations/     # Database schema evolution
├── seeds/          # Version-controlled grammar and metadata
├── validation/     # SQL integrity and coverage checks
├── scripts/        # Database build and validation utilities
├── docs/           # Architecture, grammar, sources, and decisions
└── tests/          # Regression and expected-state checks
```

## Canonical Database Workflow

The authoritative build inputs are the SQL files under `migrations/` and `seeds/`.
The repository also keeps a schema snapshot at `db/schema.sql` and the generated canonical database at `db/a2l_spec.db`.

```text
migrations + seeds
        │
        ▼
   scripts/build_db.py
        │
        ▼
 db/a2l_spec.db
```

A contributor can rebuild the canonical database with:

```bash
python3 scripts/build_db.py
```

This produces the database at `db/a2l_spec.db` by default. The generated database may remain committed to the repository for direct consumption while remaining reproducible from source-controlled inputs.

## Development Status

The project is under active development.

The positional `keyword_parameters` model has reached its initial baseline, and current work is focused on formalizing and populating the **definitions grammar**: the parent/child relationships, cardinalities, ordering semantics, and version/domain metadata required to describe complete A2L document structure.

A2ML grammar modeling will follow once the A2L grammar model is stable.

See `docs/handoff/current-state.md` for the detailed current development state, known issues, modeling decisions, and the recommended next steps.