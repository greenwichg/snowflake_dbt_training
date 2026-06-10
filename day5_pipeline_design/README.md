# Day 5 — Building the End-to-End Pipeline (Snowflake + DBT Only)

## Topics Covered

### Medallion Architecture (Bronze → Silver → Gold)

```
  Sources           BRONZE                 SILVER                  GOLD
 ─────────      ──────────────        ─────────────────      ──────────────
  files,        raw data exactly      cleaned, typed,        business-ready
  app DBs,  ──→ as received      ──→  deduplicated,     ──→  dims & facts,
  APIs          (immutable,           conformed              aggregates for
                replayable)           entities               BI / ML
                COPY INTO/Snowpipe    dbt staging models     dbt mart models
```

### Raw → Staging → Curated layer mapping in Snowflake

| Medallion | Snowflake schema | dbt layer | Materialization |
|---|---|---|---|
| Bronze | `BRONZE` (our Day 1 `RAW`) | sources only — dbt never builds here | loaded tables |
| Silver | `SILVER` | `models/staging/` (+ ephemeral `intermediate/`) | `view` |
| Gold | `GOLD` | `models/marts/` | `table` / `incremental` |

### DBT project best practices & folder conventions

- `staging/` is 1:1 with sources, prefix `stg_`, only rename/cast/clean — **no joins, no business logic**
- `intermediate/` (`int_`) for reusable steps; `marts/` (`dim_`/`fct_`) for consumables
- One `_sources.yml` per source system; `_<folder>.yml` for model docs/tests
- Every PK tested `unique` + `not_null`; every model documented
- Folder-level configs in `dbt_project.yml` (materializations, schemas), model-level overrides only when needed

### Incremental load patterns in DBT

- **Full load** (`table`): rebuild everything — simplest, correct by construction; fine until build time hurts
- **Incremental append** (`is_incremental()` + timestamp filter): immutable event data — see `fct_web_events`
- **Incremental merge** (`unique_key`): mutable rows, late-arriving updates
- Always design for `--full-refresh` recovery, and know your dedup strategy

### Error handling & debugging DBT models

`dbt run` failure workflow: read the error → `dbt compile -s <model>` → run the compiled SQL from `target/compiled/` directly in Snowsight → fix → `dbt build -s <model>+`. Common classes: **bad ref** (typo / model renamed), **schema drift** (source column renamed/dropped — caught early by source `not_null` tests and contracts), **type mismatch** (contract or incremental schema change; see `on_schema_change`).

### Cost monitoring & query optimization for DBT-generated SQL

- Tag dbt's queries: `query_tag: dbt` in `profiles.yml`, then filter `ACCOUNT_USAGE.QUERY_HISTORY` by tag to see exactly what dbt spends
- Find the slowest models from dbt's own timing output (`dbt run` prints per-model timing; `target/run_results.json` has it machine-readable)
- Optimize the worst offenders with the Day 2 toolkit: Query Profile → pruning/spilling → right-size the warehouse, prefer incremental over full rebuilds, avoid `select *` in staging of very wide tables

## Hands-On Practice

| # | Exercise |
|---|---|
| 25 | **Design Bronze / Silver / Gold schemas in Snowflake** — run [`sql/01_medallion_schemas.sql`](sql/01_medallion_schemas.sql) |
| 26 | **Wire DBT models to each Medallion layer** — uncomment the `+schema: silver` / `+schema: gold` configs in [`dbt_project.yml`](../dbt_training/dbt_project.yml), `dbt run`, and verify staging views land in `..._SILVER` and marts in `..._GOLD` (dbt appends the custom schema to your target schema — read about `generate_schema_name` to control this in prod) |
| 27 | **Implement full-load and incremental strategies** — compare `dim_customers` (full rebuild) vs `fct_web_events` (incremental append): run each twice and inspect the SQL dbt generated in Query History; then convert `fct_orders` to incremental with `unique_key='order_id'` and test `--full-refresh` |
| 28 | **Debug a broken model (schema drift, bad ref)** — follow [`exercises/28_debug_broken_model.md`](exercises/28_debug_broken_model.md) |
| 29 | **Profile queries and reduce warehouse spend** — set `query_tag: dbt` in `profiles.yml`, `dbt run`, then use the queries in the exercise file + Day 2's cost queries to find dbt's most expensive model; check its Query Profile |
| 30 | **Run dbt build end-to-end and verify results** — from a clean schema: `dbt build` (seed → snapshot → models → tests in DAG order, fail-fast); verify in Snowsight that every layer exists and `dbt build` exits green |

## Learning Outcomes

- ✅ Design a clean Medallion pipeline in Snowflake + DBT
- ✅ Choose the right materialization per layer
- ✅ Identify and fix common DBT + Snowflake issues
- ✅ Monitor costs and optimize query performance

➡️ Next: the [2-day capstone project](../capstone/README.md) — a Retail Sales Analytics Platform built end-to-end on Days 6–7, demoed on Day 8.
