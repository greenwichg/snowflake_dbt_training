# Day 5 Concepts — Explained from Zero

Read this *before* the [Day 5 lab](README.md). You have all the pieces; today is about assembling them into a pipeline you'd trust in production.

---

## 1. Medallion architecture — Bronze, Silver, Gold

The industry's favorite mental model for organizing a warehouse, and just a metals-themed rename of what you've already been doing:

```
BRONZE                      SILVER                       GOLD
raw data, exactly as        cleaned, typed, dedup'd,     business-ready answers:
received. Immutable.        consistent names/units.      dims, facts, aggregates.
(your RAW schema,           (your dbt staging models)    (your dbt marts)
 COPY INTO / Snowpipe)
```

Each layer has one promise. **Bronze:** "nothing was touched — we can always replay from here." **Silver:** "trustworthy ingredients — types right, duplicates gone." **Gold:** "ready to eat — an analyst can use this without asking anyone."

The two rules that make it work: data flows **one way** (gold never reaches back into bronze), and **bronze is append-only** (never edited — it's your replay button). In Snowflake these become literal schemas (`BRONZE`/`SILVER`/`GOLD`) with layer-aligned permissions: loaders write bronze, dbt owns silver+gold, analysts read gold only.

## 2. Idempotency — the property that lets you sleep

A pipeline step is **idempotent** if running it twice gives the same result as once. Why care? Because reruns are *normal* — jobs crash mid-way, schedulers double-fire, humans click twice. If a rerun duplicates rows or double-counts revenue, every incident becomes surgery.

You've already collected idempotent tools without noticing: `COPY INTO` remembers loaded files; dbt models rebuild with `CREATE OR REPLACE`; incremental models guard with `unique_key`; `--full-refresh` is the nuclear rebuild. Design question for *every* step you add: **"what happens if this runs twice?"**

## 3. Choosing a load pattern: full vs incremental

- **Full load** (`table`): rebuild the whole thing each run. Always correct, zero bookkeeping. Use it **until it's actually too slow** — for most tables, that's never. Don't optimize prematurely.
- **Incremental append**: only add rows newer than the latest already present. For event/log data that never changes after the fact.
- **Incremental merge** (with `unique_key`): upsert — update existing rows, insert new ones. For data where past rows *can* change (order status updates, late corrections).

Costs of going incremental: state to reason about, edge cases (late-arriving data, backfills), and you must keep `--full-refresh` working as the escape hatch. That's why the default answer is full load.

## 4. Debugging a broken pipeline — the workflow

Things break in two places, and the error tells you which:

- **Compile-time** (dbt catches it before Snowflake is touched): typo'd `ref()`, bad Jinja. Fast to find — dbt names the file.
- **Run-time** (Snowflake rejects the SQL): usually **schema drift** — a source column was renamed/retyped upstream. Error says `invalid identifier 'AMOUNT'`.

The debugging loop that always works:

1. Read the error — dbt names the failing model.
2. `dbt compile -s that_model`, open the result in `target/compiled/` — it's plain SQL now.
3. Run that SQL in Snowsight, poke at it interactively (`DESCRIBE TABLE` the source…).
4. Fix — schema drift gets absorbed **in the staging model** (alias the new name back), which is exactly why staging exists.
5. `dbt build -s that_model+` (the `+` = "and everything downstream") until green.

And the defenses that catch drift *before* 9am: source tests, contracts, `dbt source freshness`, and CI running `dbt build` on every change.

## 5. Orchestration & environments — who pushes the button, and where

A pipeline isn't a pipeline until something runs it on schedule. Realistic options, simplest first: **cron / Snowflake task** calling `dbt build` (fine for one project), **dbt Cloud** scheduled jobs, or **Airflow/Dagster** when dbt is one step among many (ingest → dbt → exports). Whatever runs it, the command is just `dbt build` — which does seed + snapshot + run + test in DAG order and **stops downstream of any failure**, so one bad model never poisons the gold layer.

Environments keep experiments away from dashboards: **dev** = your personal schema (`DBT_SAI`), where you break things freely; **CI** = a throwaway schema built per change to prove it works; **prod** = the blessed schemas, written only by the scheduler, with its own role and warehouse. Same code everywhere — `ref()` re-points automatically per environment. (That's also why Day 5's lab wires silver/gold schemas through config, not hardcoded names.)

## 6. Watching cost & performance — the production habit

Two habits cover 90% of it:

1. **Tag dbt's queries** (`query_tag: dbt` in profiles.yml) → Snowflake's `QUERY_HISTORY` can then show exactly what your pipeline spends, separated from humans clicking around.
2. **Find your slowest model** — dbt prints per-model timings every run. For the worst one, open its Query Profile (Day 2 skills): full scan? spilling? Then the fix is the usual menu — incremental instead of rebuild, right-size the warehouse, prune better.

Plus the guardrails from Day 2: auto-suspend, XS-first, resource monitors.

## 7. The mental model to leave with

```
files land (COPY/Snowpipe) → BRONZE (immutable raw)
        → dbt staging → SILVER (clean ingredients)
        → dbt marts   → GOLD (answers)
   with: tests at every layer, docs+lineage generated,
         everything idempotent, one command (dbt build) runs it all
```

If you can draw that and defend each arrow — why bronze is immutable, why staging never joins, why tests gate downstream — you understand modern ELT. That's exactly what the capstone (and its presentation) asks you to prove.

## Mini-glossary for Day 5

| Term | Plain meaning |
|---|---|
| Medallion / Bronze / Silver / Gold | Raw → cleaned → business-ready layering |
| Idempotent | Running twice = running once; reruns are safe |
| Append vs merge | Add-only vs update-or-insert incremental loading |
| Schema drift | Upstream changed a column; staging absorbs it |
| `dbt build` | seed+snapshot+run+test in DAG order, fail-fast |
| Orchestrator | Whatever runs the pipeline on schedule |
| dev / CI / prod | Your sandbox / per-change proof / the real thing |
| `query_tag` | Label on queries so you can see pipeline spend |

➡️ Now do the [Day 5 lab](README.md#hands-on-practice), then take on the [capstone](../capstone/README.md).
