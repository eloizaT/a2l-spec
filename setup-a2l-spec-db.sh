#!/usr/bin/env bash
set -euo pipefail

# A2L/A2ML Spec DB — GitHub bootstrap for Milestones 0–2
#
# Creates:
#   - labels used by the database project
#   - milestones:
#       0 — Repository Foundation
#       1 — Current Database Cleanup
#       2 — Definition Grammar Model
#   - GitHub Project: "A2L/A2ML Spec DB"
#   - project field: "Work Status"
#   - issues for Milestones 0–2
#   - adds each issue to the project
#
# Requirements:
#   - GitHub CLI (gh)
#   - authenticated GitHub CLI session
#   - project scope:
#       gh auth refresh -s project
#
# Usage:
#   ./setup-a2l-spec-db.sh
#   ./setup-a2l-spec-db.sh --repo OWNER/REPO
#   ./setup-a2l-spec-db.sh --repo OWNER/REPO --project-owner OWNER

PROJECT_TITLE="A2L/A2ML Spec DB"
PROJECT_FIELD="Work Status"
PROJECT_OPTIONS="Backlog,Ready,In Progress,Blocked,Review,Done"

M0_TITLE="Milestone 0 — Repository Foundation"
M1_TITLE="Milestone 1 — Current Database Cleanup"
M2_TITLE="Milestone 2 — Definition Grammar Model"

REPO=""
PROJECT_OWNER=""

usage() {
  cat <<'USAGE'
Usage:
  setup-a2l-spec-db.sh [--repo OWNER/REPO] [--project-owner OWNER]

Options:
  --repo OWNER/REPO       Target GitHub repository.
                          Defaults to the current repository.
  --project-owner OWNER   User or organization that owns the GitHub Project.
                          Defaults to the repository owner.
  -h, --help              Show this help.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo)
      REPO="${2:-}"
      shift 2
      ;;
    --project-owner)
      PROJECT_OWNER="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

command -v gh >/dev/null 2>&1 || {
  echo "Error: GitHub CLI (gh) is required." >&2
  exit 1
}

gh auth status >/dev/null 2>&1 || {
  echo "Error: GitHub CLI is not authenticated. Run: gh auth login" >&2
  exit 1
}

if [[ -z "$REPO" ]]; then
  REPO="$(gh repo view --json nameWithOwner --jq '.nameWithOwner')"
fi

if [[ "$REPO" != */* ]]; then
  echo "Error: --repo must be in OWNER/REPO format." >&2
  exit 1
fi

REPO_OWNER="${REPO%%/*}"
if [[ -z "$PROJECT_OWNER" ]]; then
  PROJECT_OWNER="$REPO_OWNER"
fi

echo "Repository:    $REPO"
echo "Project owner: $PROJECT_OWNER"
echo

gh repo view "$REPO" >/dev/null

create_label() {
  local name="$1"
  local color="$2"
  local description="$3"

  gh label create "$name" \
    --repo "$REPO" \
    --color "$color" \
    --description "$description" \
    --force >/dev/null
}

echo "Creating/updating labels..."

create_label "type: research"   "D4C5F9" "Grammar/specification research"
create_label "type: data"       "0E8A16" "Database content and seed data"
create_label "type: bug"        "D73A4A" "Incorrect or incomplete database content"
create_label "type: design"     "5319E7" "Schema or modeling design work"
create_label "type: validation" "FBCA04" "Integrity and coverage validation"
create_label "type: docs"       "0075CA" "Documentation"
create_label "type: tooling"    "C5DEF5" "Build and validation tooling"

create_label "area: schema"      "BFDADC" "SQLite schema and migrations"
create_label "area: a2l"         "1D76DB" "ASAP2/A2L grammar and metadata"
create_label "area: a2ml"        "7057FF" "A2ML grammar and metadata"
create_label "area: parameters"  "FEF2C0" "Keyword parameter metadata"
create_label "area: definitions" "F9D0C4" "Parent/child grammar definitions"
create_label "area: enums"       "D4E5F7" "Enum types and values"
create_label "area: validation"  "C2E0C6" "Database validation"
create_label "area: docs"        "DDEBF7" "Project and architecture documentation"
create_label "area: tooling"     "EDEDED" "Scripts and automation"

create_label "priority: high"   "B60205" "Blocking or foundational work"
create_label "priority: medium" "FBCA04" "Important but not immediately blocking"
create_label "priority: low"    "0E8A16" "Can be deferred"

echo "Labels ready."
echo

ensure_milestone() {
  local title="$1"
  local description="$2"

  local milestone_number
  milestone_number="$(
    gh api "repos/$REPO/milestones?state=all&per_page=100" \
      --jq ".[] | select(.title == \"$title\") | .number" \
      | head -n 1
  )"

  if [[ -z "$milestone_number" ]]; then
    milestone_number="$(
      gh api --method POST "repos/$REPO/milestones" \
        -f title="$title" \
        -f description="$description" \
        --jq '.number'
    )"
    echo "Created milestone #$milestone_number: $title"
  else
    echo "Milestone already exists (#$milestone_number): $title"
  fi
}

echo "Ensuring milestones exist..."
ensure_milestone "$M0_TITLE" "Make the SQLite database project reproducible, documented, and easy to validate before further grammar population."
ensure_milestone "$M1_TITLE" "Close known data-quality gaps from the keyword-parameters phase without blocking definitions work."
ensure_milestone "$M2_TITLE" "Finalize the parent/child grammar model, cardinality semantics, ordering semantics, and validation before large-scale definition population."

echo
echo "Ensuring GitHub Project exists..."

PROJECT_NUMBER="$(
  gh project list \
    --owner "$PROJECT_OWNER" \
    --format json \
    --jq ".projects[] | select(.title == \"$PROJECT_TITLE\") | .number" \
    2>/dev/null | head -n 1 || true
)"

if [[ -z "$PROJECT_NUMBER" ]]; then
  PROJECT_NUMBER="$(
    gh project create \
      --owner "$PROJECT_OWNER" \
      --title "$PROJECT_TITLE" \
      --format json \
      --jq '.number'
  )"
  echo "Created project #$PROJECT_NUMBER."
else
  echo "Project already exists (#$PROJECT_NUMBER)."
fi

echo "Ensuring project status field exists..."

FIELD_EXISTS="$(
  gh project field-list "$PROJECT_NUMBER" \
    --owner "$PROJECT_OWNER" \
    --format json \
    --jq ".fields[] | select(.name == \"$PROJECT_FIELD\") | .name" \
    2>/dev/null | head -n 1 || true
)"

if [[ -z "$FIELD_EXISTS" ]]; then
  gh project field-create "$PROJECT_NUMBER" \
    --owner "$PROJECT_OWNER" \
    --name "$PROJECT_FIELD" \
    --data-type SINGLE_SELECT \
    --single-select-options "$PROJECT_OPTIONS" >/dev/null
  echo "Created '$PROJECT_FIELD' field."
else
  echo "'$PROJECT_FIELD' field already exists."
fi

create_issue() {
  local milestone="$1"
  local title="$2"
  local labels="$3"
  local body="$4"

  local existing_url
  existing_url="$(
    gh issue list \
      --repo "$REPO" \
      --state all \
      --limit 300 \
      --json title,url \
      --jq ".[] | select(.title == \"$title\") | .url" \
      | head -n 1
  )"

  if [[ -n "$existing_url" ]]; then
    echo "Exists:  $title"
    echo "$existing_url"
    return 0
  fi

  local args=()
  IFS=',' read -ra label_array <<< "$labels"
  for label in "${label_array[@]}"; do
    args+=(--label "$label")
  done

  local issue_url
  issue_url="$(
    gh issue create \
      --repo "$REPO" \
      --title "$title" \
      --milestone "$milestone" \
      "${args[@]}" \
      --body "$body"
  )"

  gh project item-add "$PROJECT_NUMBER" \
    --owner "$PROJECT_OWNER" \
    --url "$issue_url" >/dev/null

  echo "Created: $title"
  echo "$issue_url"
}

echo
echo "Creating Milestone 0 issues..."

create_issue "$M0_TITLE" "Initialize repository structure" "type: tooling,area: tooling,area: docs,priority: high" '## Goal

Create a small repository structure centered on the SQLite database while keeping the project reproducible and easy to navigate.

## Tasks

- [ ] Add `README.md`.
- [ ] Add `LICENSE`.
- [ ] Add `.gitignore`.
- [ ] Create `db/`.
- [ ] Create `migrations/`.
- [ ] Create `seeds/`.
- [ ] Create `validation/`.
- [ ] Create `scripts/`.
- [ ] Create `docs/`.
- [ ] Create `docs/decisions/`.
- [ ] Create `tests/`.
- [ ] Place the current canonical database at `db/a2l_spec.db`.
- [ ] Place the current schema snapshot at `db/schema.sql`.

## Acceptance criteria

- A new contributor can understand where schema, seed data, validation SQL, documentation, and the generated database belong.
- The repository remains database-focused rather than becoming an application project.

## Estimate

1 hour.'

create_issue "$M0_TITLE" "Establish canonical database build workflow" "type: design,area: schema,area: tooling,priority: high" '## Goal

Define which files are authoritative and how `db/a2l_spec.db` is produced.

## Proposed workflow

```text
migrations + seeds
      ↓
  build_db.py
      ↓
db/a2l_spec.db
```

The SQLite database may remain committed for convenient consumption, but it must be reproducible from source-controlled inputs.

## Tasks

- [ ] Define authoritative source files.
- [ ] Decide whether `db/schema.sql` is generated or maintained.
- [ ] Define seed application order.
- [ ] Define migration application order.
- [ ] Define rebuild behavior for an existing DB.
- [ ] Document the workflow in the README.

## Acceptance criteria

- There is one documented canonical path for rebuilding the database.
- Manual edits to the binary DB are not required to reproduce the project state.
- The committed DB can be regenerated deterministically from repository inputs.

## Estimate

1–2 hours.'

create_issue "$M0_TITLE" "Create baseline schema migration" "type: design,area: schema,priority: high" '## Goal

Capture the current SQLite schema as a reproducible baseline migration before further grammar-model changes.

## Tasks

- [ ] Review the current live schema.
- [ ] Capture tables, indexes, constraints, and foreign keys.
- [ ] Preserve current A2L/A2ML domain modeling.
- [ ] Preserve `keyword_parameters`.
- [ ] Preserve the current definitions-related tables.
- [ ] Add comments describing any intentionally deferred cleanup.
- [ ] Verify that applying the migration to an empty SQLite DB succeeds.

## Acceptance criteria

- A fresh SQLite database can be created from the baseline migration.
- The resulting schema matches the intended current project state.
- No grammar data is silently changed as part of this issue.

## Estimate

1–2 hours.'

create_issue "$M0_TITLE" "Extract existing database content into seed files" "type: data,area: tooling,area: schema,priority: high" '## Goal

Represent the current logical database content as reviewable source-controlled seed SQL.

## Seed areas

- [ ] grammar domains / modes
- [ ] versions
- [ ] keywords
- [ ] enum types
- [ ] enum values
- [ ] keyword parameters
- [ ] current verified definitions
- [ ] current verified definition children
- [ ] supporting evidence/source metadata where applicable

## Constraints

- Preserve explicit enum ordinals.
- Preserve intentional `NULL` reference targets.
- Preserve the known zero-parameter keywords.
- Do not invent missing enum values or grammar relationships while extracting.

## Acceptance criteria

- Seed files rebuild the current logical data without manual intervention.
- Seed ordering is deterministic.
- Known outstanding issues remain explicit rather than being silently “fixed”.

## Estimate

2–4 hours.'

create_issue "$M0_TITLE" "Create database build script" "type: tooling,area: tooling,area: schema,priority: high" '## Goal

Create `scripts/build_db.py` to rebuild the canonical SQLite database from migrations and seed files.

## Tasks

- [ ] Create a fresh output database.
- [ ] Enable foreign keys.
- [ ] Apply migrations in deterministic order.
- [ ] Apply seed files in deterministic order.
- [ ] Fail immediately on SQL errors.
- [ ] Run `PRAGMA foreign_key_check`.
- [ ] Write the DB to `db/a2l_spec.db` by default.
- [ ] Support an alternate output path for testing.
- [ ] Print a concise build summary.

## Acceptance criteria

- `python scripts/build_db.py` creates a usable database from scratch.
- A failed migration or seed produces a non-zero exit status.
- Foreign-key violations make the build fail.

## Estimate

2–3 hours.'

create_issue "$M0_TITLE" "Create database validation runner" "type: validation,area: validation,area: tooling,priority: high" '## Goal

Create `scripts/validate_db.py` as one command that runs project validation against the canonical database.

## Tasks

- [ ] Discover validation SQL in deterministic order.
- [ ] Execute every validation query.
- [ ] Treat unexpected rows as failures where appropriate.
- [ ] Print pass/fail results per validation file.
- [ ] Return non-zero when validation fails.
- [ ] Support an alternate database path.
- [ ] Include `PRAGMA foreign_key_check`.
- [ ] Keep validation logic simple and SQL-first.

## Acceptance criteria

- `python scripts/validate_db.py` gives a clear overall pass/fail result.
- The command is suitable for future CI use.
- Validation failures identify which check failed.

## Estimate

2–3 hours.'

create_issue "$M0_TITLE" "Document current modeling decisions" "type: docs,area: docs,area: schema,priority: high" '## Goal

Move important modeling decisions out of handoff notes and into durable repository documentation.

## Documents

- [ ] `docs/architecture.md`
- [ ] `docs/schema.md`
- [ ] `docs/grammar-model.md`
- [ ] `docs/sources.md`

## Decision records

At minimum document:

- [ ] repeated logical parameters use one `keyword_parameters` row
- [ ] `reference_keyword_id` is conservative
- [ ] multi-class references remain `NULL`
- [ ] `IF_DATA` switches to A2ML grammar
- [ ] A2L and A2ML grammar domains stay separate
- [ ] zero-parameter container keywords are intentional
- [ ] `CURVE_AXIS_REF` is absent from the current catalog
- [ ] suspect/unverified keyword rows are not automatically modeled
- [ ] enum values require explicit ordinals
- [ ] definitions own nested grammar/cardinality, not positional parameters

## Acceptance criteria

- A future contributor can understand why the schema contains its current compromises.
- Important project rules no longer depend on chat history.

## Estimate

2–3 hours.'

echo
echo "Creating Milestone 1 issues..."

create_issue "$M1_TITLE" "Validate the 156 keyword-parameter baseline" "type: validation,area: parameters,area: validation,priority: high" '## Goal

Turn the completed keyword-parameters phase into a reproducible baseline.

## Checks

- [ ] `keyword_parameters` count is 156.
- [ ] No duplicate `(keyword_id, position)`.
- [ ] No broken keyword foreign keys.
- [ ] No broken enum foreign keys.
- [ ] No broken reference-keyword foreign keys.
- [ ] ENUM parameters have `enum_type_id`.
- [ ] Non-ENUM parameters do not have `enum_type_id`.
- [ ] `required` contains only valid values.
- [ ] Parameter positions are valid and non-gapped.
- [ ] Parameter names are non-empty.
- [ ] Expected parameterless/container keywords remain at zero rows.

## Acceptance criteria

- All checks are represented in version-controlled validation SQL.
- The current expected count is explicit.
- Known enum-value gaps do not incorrectly fail parameter integrity checks.

## Estimate

1 hour.'

create_issue "$M1_TITLE" "Complete ReadWrite enum values" "type: research,type: data,area: enums,area: a2l,priority: medium" '## Goal

Resolve the known `ReadWrite` enum gap using a traceable public A2L grammar source.

## Current state

`ReadWrite` is known to exist but currently has zero enum values.

## Tasks

- [ ] Trace the applicable public grammar/specification implementation.
- [ ] Confirm the complete value set.
- [ ] Confirm explicit ordinal assignments.
- [ ] Insert enum values.
- [ ] Record source/evidence.
- [ ] Add validation for the expected values and ordinals.

## Acceptance criteria

- `ReadWrite` has no missing enum values.
- Every value has an explicit ordinal.
- The values are source-traceable.

## Estimate

1–2 hours.'

create_issue "$M1_TITLE" "Complete FloatFormat enum values" "type: research,type: data,area: enums,area: a2l,priority: medium" '## Goal

Resolve the known `FloatFormat` enum gap using a traceable public A2L grammar source.

## Current state

`FloatFormat` is known to exist but currently has zero enum values.

## Tasks

- [ ] Trace the applicable public grammar/specification implementation.
- [ ] Confirm whether the catalog entry is truly an enum in the modeled grammar.
- [ ] Confirm the complete value set if applicable.
- [ ] Confirm explicit ordinal assignments.
- [ ] Insert enum values if confirmed.
- [ ] Record source/evidence.
- [ ] Add validation.

## Acceptance criteria

- The `FloatFormat` catalog representation is verified.
- Any enum values added have explicit ordinals.
- If the current modeling assumption is wrong, the decision is documented rather than forced.

## Estimate

1–2 hours.'

create_issue "$M1_TITLE" "Audit suspect keyword catalog rows" "type: research,area: a2l,area: validation,priority: medium" '## Goal

Determine the status of catalog rows that were not confirmed as standalone A2L grammar constructs.

## Rows to audit

- [ ] 103 `TRANSFORMER_IN_OBJECT`
- [ ] 104 `TRANSFORMER_OUT_OBJECT`
- [ ] 107 `TRANSFORMER_TYPE`
- [ ] 108 `TRIGGER`
- [ ] 110 `READ`
- [ ] 111 `WRITE`
- [ ] 116 `LONG_IDENTIFIER`
- [ ] 117 `SHORT_IDENTIFIER`

## Tasks

For each row:

- [ ] Trace the public grammar.
- [ ] Classify as confirmed keyword, alias/token, obsolete/version-specific construct, or unsupported catalog artifact.
- [ ] Record source/evidence.
- [ ] Decide whether the row should remain, be deprecated, or eventually be removed.
- [ ] Do not create parameters or definitions merely because a row exists.

## Acceptance criteria

- Every suspect row has an explicit classification.
- No suspect row enters definitions without grammar evidence.

## Estimate

2–4 hours.'

create_issue "$M1_TITLE" "Audit unclassified keyword catalog rows 140–144" "type: research,area: a2l,area: schema,priority: medium" '## Goal

Verify the domain and grammar role of additional catalog rows 140–144.

## Rows

- [ ] 140 `ATTRIBUTE`
- [ ] 141 `CALIBRATION_ACCESS`
- [ ] 142 `CHARACTERISTIC_TYPE`
- [ ] 143 `FLOAT_FORMAT`
- [ ] 144 `INDEX_ORDER`

## Tasks

- [ ] Confirm A2L vs A2ML domain for each row.
- [ ] Confirm whether each is a standalone keyword, parameter enum/token, or other grammar artifact.
- [ ] Preserve the existing decision that unconfirmed constructs do not receive parameter rows.
- [ ] Record source/evidence.
- [ ] Update domain metadata only when confirmed.

## Acceptance criteria

- Every row has an explicit domain/role classification.
- No row is promoted to a grammar construct without evidence.

## Estimate

1–2 hours.'

create_issue "$M1_TITLE" "Add parameter and reference regression checks" "type: validation,area: parameters,area: validation,priority: high" '## Goal

Formalize the manual checks used during the keyword-parameters phase so future schema/data changes cannot silently regress them.

## Checks

- [ ] duplicate parameter positions
- [ ] invalid required values
- [ ] empty parameter names
- [ ] broken `keyword_id`
- [ ] broken `enum_type_id`
- [ ] broken `reference_keyword_id`
- [ ] ENUM parameter without enum type
- [ ] non-ENUM parameter with enum type
- [ ] enum type without values
- [ ] enum value without ordinal
- [ ] duplicate enum ordinals
- [ ] repeated-reference logical parameter conventions
- [ ] intentionally unresolved multi-class references remain allowed

## Acceptance criteria

- All checks can run from `scripts/validate_db.py`.
- A regression produces a clear validation failure.
- Known intentional exceptions are documented rather than globally ignored.

## Estimate

2–3 hours.'

echo
echo "Creating Milestone 2 issues..."

create_issue "$M2_TITLE" "Finalize definitions schema" "type: design,area: definitions,area: schema,priority: high" '## Goal

Finalize the schema used to represent actual A2L/A2ML parent-child grammar relationships before large-scale population.

## Required capabilities

- [ ] parent definition
- [ ] child definition
- [ ] grammar/domain separation
- [ ] version separation
- [ ] minimum cardinality
- [ ] maximum cardinality / unbounded repetition
- [ ] ordering metadata
- [ ] source/evidence traceability

## Constraints

- Positional keyword arguments remain in `keyword_parameters`.
- Nested grammar belongs in definitions/definition-children.
- A2L and A2ML edges must not mix accidentally.
- Missing catalog keywords must not be fabricated merely to satisfy a public implementation.

## Acceptance criteria

- The schema can represent `?`, `*`, `+`, and exact-one child cardinalities.
- Cross-version/domain relationships are prevented or detected.
- The model is documented before further bulk population.

## Estimate

2–3 hours.'

create_issue "$M2_TITLE" "Finalize definition cardinality semantics" "type: design,area: definitions,priority: high" '## Goal

Define unambiguous database semantics for required, optional, and repeatable child grammar.

## Semantics to define

- [ ] required single child → `min_occurs = 1`, `max_occurs = 1`
- [ ] optional child → `min_occurs = 0`, `max_occurs = 1`
- [ ] zero-or-more child → `min_occurs = 0`, unbounded maximum
- [ ] one-or-more child → `min_occurs = 1`, unbounded maximum
- [ ] bounded repetition if encountered

## Tasks

- [ ] Choose the canonical representation for “unbounded”.
- [ ] Add constraints/checks for negative values.
- [ ] Reject `max_occurs < min_occurs`.
- [ ] Decide whether any redundant `required` field should remain.
- [ ] Document the semantics with examples.

## Acceptance criteria

- Every child edge has one unambiguous cardinality interpretation.
- Repetition no longer depends on the `keyword_parameters.required` workaround.

## Estimate

1–2 hours.'

create_issue "$M2_TITLE" "Define grammar ordering semantics" "type: research,type: design,area: definitions,area: a2l,priority: high" '## Goal

Define what ordering metadata means without accidentally enforcing source declaration order as parser order.

## Questions to resolve

- [ ] Is child order strict for the relevant A2L grammar?
- [ ] Are optional sub-keywords freely reorderable within blocks?
- [ ] Does `order_index` mean grammar declaration order, parser order, or display order?
- [ ] Do we need an explicit ordering mode such as `unordered`, `source_order`, or `strict`?
- [ ] Can ordering vary by parent definition/version?

## Tasks

- [ ] Trace representative public grammar implementations.
- [ ] Document observed ordering behavior.
- [ ] Define database semantics.
- [ ] Update constraints/schema if required.
- [ ] Add examples for `PROJECT`, `MODULE`, `CHARACTERISTIC`, and `FUNCTION`.

## Acceptance criteria

- Consumers cannot reasonably mistake metadata order for mandatory textual parse order.
- Any strict-order claim is backed by grammar evidence.

## Estimate

2–4 hours.'

create_issue "$M2_TITLE" "Add definition integrity validation" "type: validation,area: definitions,area: validation,priority: high" '## Goal

Add validation that makes malformed grammar edges difficult to introduce.

## Checks

- [ ] broken parent definition foreign keys
- [ ] broken child definition foreign keys
- [ ] duplicate parent/child edges
- [ ] negative cardinality
- [ ] `max_occurs < min_occurs`
- [ ] invalid unbounded representation
- [ ] cross-version parent/child relationships
- [ ] cross-domain parent/child relationships
- [ ] missing order metadata where required
- [ ] suspect catalog keywords used without explicit review
- [ ] A2ML tokens accidentally modeled as ordinary A2L children

## Acceptance criteria

- All definition integrity checks run from the standard validation command.
- Invalid relationships fail validation clearly.
- Intentional exceptions require explicit documentation.

## Estimate

2–3 hours.'

create_issue "$M2_TITLE" "Document the definitions grammar model" "type: docs,area: definitions,area: docs,priority: high" '## Goal

Document how nested grammar is represented and how it differs from keyword positional parameters.

## Topics

- [ ] `keyword_parameters` vs `definition_children`
- [ ] parent and child definition identity
- [ ] version/domain handling
- [ ] cardinality semantics
- [ ] ordering semantics
- [ ] source/evidence handling
- [ ] A2L vs A2ML separation
- [ ] `IF_DATA` handoff to A2ML
- [ ] catalog-gap policy
- [ ] suspect-keyword policy

## Examples

Include at least:

- [ ] `PROJECT`
- [ ] `MODULE`
- [ ] `CHARACTERISTIC`
- [ ] `FUNCTION`

Examples must be illustrative and clearly distinguish verified relationships from conceptual examples.

## Acceptance criteria

- A contributor can add a new definition relationship without needing chat-history context.
- The document explains when not to create a definition edge.

## Estimate

1–2 hours.'

echo
echo "Bootstrap complete."
echo
echo "Milestones:"
echo "  - $M0_TITLE"
echo "  - $M1_TITLE"
echo "  - $M2_TITLE"
echo
echo "Project: $PROJECT_TITLE (#$PROJECT_NUMBER)"
echo
echo "Next:"
echo "  1. Open the project:"
echo "     gh project view \"$PROJECT_NUMBER\" --owner \"$PROJECT_OWNER\" --web"
echo
echo "  2. In the GitHub Project UI, create a Board view grouped by '$PROJECT_FIELD'."
echo "     Options: $PROJECT_OPTIONS"
echo
echo "  3. Start with: Initialize repository structure"
