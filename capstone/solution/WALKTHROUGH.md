# Capstone Solution — Execution Walkthrough (start to end)

A beginner-friendly narrative of **what actually happens** when you run the solution: every command, what it does behind the scenes, what exists in Snowflake afterwards, and the numbers that prove each step worked. Read it side-by-side with running the steps.

**The journey in one picture (10-second version):**

```
 you upload 3 CSVs          COPY INTO              dbt build
┌──────────────┐      ┌──────────────────┐      ┌─────────────────────────────────┐
│ orders.csv   │      │ CAPSTONE_DB.RAW  │      │ CAPSTONE_DB.ANALYTICS           │
│ customers.csv│ ───▶ │  ORDERS      60  │ ───▶ │  stg_orders / _customers /      │
│ products.csv │      │  CUSTOMERS   15  │      │  _products        (Silver)      │
└──────────────┘      │  PRODUCTS    10  │      │  mart_daily_sales /             │
   (Bronze input)     └──────────────────┘      │  mart_customer_summary /        │
                         exactly as received    │  mart_product_performance (Gold)│
                                                └─────────────────────────────────┘
```

**The same journey, zoomed in** — every arrow above hides a step. Here is the full flow with the gates, mechanics, and expected numbers; each numbered phase is a section of this document:

```
 PHASE 1 ── Snowsight: run snowflake_setup/01_setup_and_load.sql
 ────────────────────────────────────────────────────────────────────────────
   orders.csv   customers.csv   products.csv          (files on your laptop)
        │
        │  upload ("+ Files" in Snowsight)
        ▼
   @RAW.CSV_STAGE ............ the file "in-box": staged, but in NO table yet
        │
        │  COPY INTO ×3 — parsed via FILE FORMAT FF_CSV (skip header, ''→NULL)
        │  (re-running loads 0 rows: Snowflake remembers files for 64 days)
        ▼
 ┌─ CAPSTONE_DB.RAW = Bronze (immutable, exactly as received) ──────────────┐
 │  ORDERS     60   status still messy: 'COMPLETED' / 'Completed' / ...     │
 │  CUSTOMERS  15   city & segment contain NULLs                            │
 │  PRODUCTS   10   supplier_id contains a NULL                             │
 └───────────────────────────────────────────────────────────────────────────┘

 PHASE 2 ── terminal: dbt debug   (connection check only — builds nothing)

 PHASE 3 ── terminal: dbt build   (parse refs → DAG → run in dependency order)
 ────────────────────────────────────────────────────────────────────────────
        │
        │  🚧 GATE 1: source tests — unique + not_null on the 3 raw PKs
        │             (bad input stops here, before anything is built)
        ▼
 ┌─ CAPSTONE_DB.ANALYTICS = Silver (cleaned & typed — dbt staging) ─────────┐
 │  stg_customers  VIEW         15   segment NULL → 'unassigned'            │
 │  stg_products   VIEW         10   supplier NULL → 'unknown'              │
 │  stg_orders     INCREMENTAL  60   lower(trim(status)), gross_revenue     │
 │                 1st run = full CREATE TABLE; later runs APPEND only      │
 │                 rows where order_date > max already loaded  (task 36)    │
 └───────────────────────────────────────────────────────────────────────────┘
        │
        │  🚧 GATE 2: 13 staging tests — PKs + accepted_values on status &
        │             segment. ANY failure ⇒ marts are SKIPPED (fail-fast)
        ▼
 ┌─ CAPSTONE_DB.ANALYTICS = Gold (business-ready TABLEs — dbt marts) ───────┐
 │  mart_daily_sales          60   revenue / orders / AOV per day           │
 │  mart_customer_summary     15   LTV per customer; zero-order customers   │
 │                                 kept by LEFT JOIN (total LTV ≈ 8,708.92) │
 │  mart_product_performance  10   revenue / margin / below-cost units      │
 │  every PK built by the surrogate_key() macro → expands to md5(...) at    │
 │  compile time (see target/compiled/)                                     │
 └───────────────────────────────────────────────────────────────────────────┘
        │
        │  🚧 GATE 3: mart tests — unique keys + relationships back to staging
        ▼
   ✅ dbt build summary: PASS=38   (6 models + 32 tests, one command)

 PHASE 4 ── dbt docs generate && dbt docs serve → docs site + lineage graph

 PHASE 5 ── the live demo loop:
   INSERT new raw order ('COMPLETED', today) ─▶ dbt build ─▶ stg_orders gains
   the is_incremental() filter and APPENDS just that row (cleaned to
   'completed') ─▶ marts rebuild ─▶ new order visible in daily sales & LTV
```

---

## Phase 1 — Snowflake setup & raw load (task 31)

**You run:** `snowflake_setup/01_setup_and_load.sql` in a Snowsight worksheet, top to bottom, uploading the three files from `capstone/data/` when the script says so.

**What each block actually does:**

1. `CREATE WAREHOUSE CAPSTONE_WH … AUTO_SUSPEND = 60` — creates a *compute engine* (remember: in Snowflake a "warehouse" runs queries, it doesn't store anything). It starts suspended and switches itself off 60s after you stop querying, so it can't quietly burn credits.
2. `CREATE DATABASE CAPSTONE_DB` + `SCHEMA RAW` — empty containers. `RAW` is our Bronze layer: data lands here exactly as received and is never edited afterwards.
3. Three `CREATE TABLE` statements — empty tables whose columns mirror the CSV headers. Note `STATUS VARCHAR(30)` is deliberately loose: the messy values (`COMPLETED`, `Completed`…) are loaded *as-is*; cleaning is dbt's job, not the loader's. That separation is the whole ELT idea.
4. `CREATE FILE FORMAT FF_CSV` — saved parsing instructions: comma-separated, skip the header row, `''` becomes NULL (this is how the blank `city`/`segment`/`supplier_id` cells in the CSVs turn into proper NULLs).
5. `CREATE STAGE CSV_STAGE` — the "file in-box". Your upload puts the 3 files *into Snowflake* but **not yet into any table**. `LIST @RAW.CSV_STAGE` should show 3 files.
6. Three `COPY INTO … PATTERN = '…'` — the actual bulk load: Snowflake reads each staged file, parses it per the file format, and appends the rows to the matching table. Each COPY reports `LOADED` per file. Run a COPY a second time and it loads **0 rows** — Snowflake remembers which files a table already consumed (64 days), making loads safely re-runnable.

**Checkpoint — you should see:**

| Query | Expect |
|---|---|
| `SELECT COUNT(*) FROM RAW.ORDERS` | **60** |
| `SELECT COUNT(*) FROM RAW.CUSTOMERS` | **15** |
| `SELECT COUNT(*) FROM RAW.PRODUCTS` | **10** |
| `SELECT DISTINCT STATUS FROM RAW.ORDERS` | 6 messy variants (`completed`, `COMPLETED`, `Completed`, `cancelled`, `CANCELLED`, `returned`, …) |

---

## Phase 2 — connecting dbt (tasks 13-style setup)

**You run:**

```bash
cp dbt_capstone/profiles.yml.example ~/.dbt/profiles.yml   # then edit account/user/password
cd capstone/solution/dbt_capstone
dbt debug
```

**What's happening:** dbt itself stores nothing and computes nothing — it's a program on *your machine* that will log into Snowflake (as defined in `profiles.yml`, kept outside the repo so credentials never reach Git) and send SQL. `dbt debug` checks: config files parse, the account is reachable, login works, and the role can see `CAPSTONE_DB`. All green = you're connected. The profile's `schema: ANALYTICS` means everything dbt builds will land in `CAPSTONE_DB.ANALYTICS` — Bronze (`RAW`) is read, never written, by dbt.

---

## Phase 3 — the build (tasks 32–42): `dbt build`

**You run:** `dbt build` — one command that does *parse → order → create models → test them*, stopping downstream of any failure.

### 3a. Before any SQL is sent: parse & plan

dbt reads every file in `models/`, finds the `{{ source() }}` / `{{ ref() }}` calls, and derives the dependency graph (DAG):

```
source raw.orders ───▶ stg_orders ──┬─▶ mart_daily_sales
source raw.customers ─▶ stg_customers ─┬─▶ mart_customer_summary
source raw.products ──▶ stg_products ──┴─▶ mart_product_performance
```

This is why nothing in the project hardcodes `CAPSTONE_DB.ANALYTICS.STG_ORDERS` — `ref('stg_orders')` resolves to the right object *for your target*, and the graph guarantees staging always builds before marts.

### 3b. Execution order (what you'll watch scroll by)

1. **Source tests first** — `unique`/`not_null` on the three raw primary keys. These guard the *input*: if a CSV was double-loaded, you find out now, not after the marts are built on duplicated revenue.
2. **`stg_customers`, `stg_products` (views)** — dbt wraps each SELECT in `CREATE VIEW`. Views store nothing; they're saved queries, always reflecting current raw data. This is where cleaning happens: `lower(trim(status))`, `segment → 'unassigned'`, `supplier_id → 'unknown'`. Open the *exact* SQL dbt sent in `target/run/` — it's just SQL, no magic.
3. **`stg_orders` (incremental — task 36)** — **first run**: there's no table yet, so the `{% if is_incremental() %}` filter is skipped and dbt does a plain `CREATE TABLE AS SELECT` → 60 rows. The append-by-`order_date` behavior only kicks in on *later* runs (Phase 5).
4. **Staging tests** — the 13 declared in `_staging.yml` run now, including `accepted_values` on status. They pass *because* step 2 normalized the casing — the same test against raw would fail with 6 variants. If any test failed here, `dbt build` would **skip the marts** (fail-fast: bad data never propagates to Gold).
5. **The three marts (tables)** — physically stored results, rebuilt from staging every run. Each uses the `surrogate_key()` macro (task 41) — peek at `target/compiled/` and you'll see the macro expanded into a literal `md5(coalesce(cast(…)))` expression before Snowflake ever saw it. That's all Jinja is: text generation before execution.
6. **Mart tests** — uniqueness of every key, plus the `relationships` tests (task 42) proving every mart `customer_id`/`product_id` still exists in staging.

**Checkpoint — `dbt build` summary line:** `PASS=38 ERROR=0` (6 models + 32 tests). In Snowsight, `CAPSTONE_DB.ANALYTICS` now contains 2 views, 4 tables:

| Object | Rows | Why that number |
|---|---|---|
| `stg_orders` | 60 | one per raw order line |
| `stg_customers` / `stg_products` | 15 / 10 | 1:1 with raw |
| `mart_daily_sales` | 60 | one per distinct order date (every order in the sample falls on its own day) |
| `mart_customer_summary` | 15 | one per customer — **including** the never-ordered ones with LTV 0 (that's the LEFT JOIN) |
| `mart_product_performance` | 10 | one per product, even if never sold |

Sanity numbers: 52 of the 60 orders are `completed`; total lifetime value across all customers ≈ **8,708.92**.

---

## Phase 4 — docs & lineage (task 43)

**You run:** `dbt docs generate && dbt docs serve`

`generate` compiles every YAML description plus the DAG into a static website (in `target/`); `serve` opens it at `localhost:8080`. Click `mart_daily_sales` → the lineage graph draws the exact diagram from section 3a, clickable from raw source to mart. Every column description you read there came from `_staging.yml` / `_marts.yml` — documentation lives next to the code it describes, so it can't silently go stale in a wiki.

---

## Phase 5 — proving the pipeline is alive (the Day 8 demo)

This is the moment that shows it's a *pipeline*, not a one-off load:

```sql
-- 1. a new order arrives (note: a date NEWER than anything loaded)
INSERT INTO CAPSTONE_DB.RAW.ORDERS VALUES
  (5061, 1, 101, CURRENT_DATE, 2, 89.99, 'COMPLETED');
```

```bash
dbt build        # 2. re-run the pipeline
```

**What's different on this run:** `stg_orders` now *exists*, so `is_incremental()` is true and the compiled SQL gains the filter `where order_date > (select max(order_date) …)` — dbt **appends only the new order** instead of rebuilding (check the INSERT in Snowsight's query history; that's task 36 working). The marts (plain tables) rebuild fully — fine at this size — and the new order is now visible in `mart_daily_sales` (today's row) and customer 1's `lifetime_value`. Note the messy `'COMPLETED'` came out as `completed` — cleaning is automatic because it's *in the model*, not a manual step.

Then run the three insight queries from the [README](README.md#task-44--the-5-minute-walkthrough) — best revenue day, segment value, and the below-cost tent.

---

## When something fails — the 3-step debug loop

1. **Read dbt's error** — it names the failing model/test.
2. **Open the compiled SQL** — `target/compiled/dbt_capstone/models/...` (pure SQL, the Jinja already expanded) and run it in Snowsight to poke at it interactively.
3. **Fix in the model file, then** `dbt build -s <model>+` — the `+` rebuilds everything downstream of your fix.

Most first-run failures are: profile typos (`dbt debug` fails), the CSVs loaded into a different database than `_sources.yml` expects (`Object … does not exist`), or a role that can't read `RAW` (re-check grants).

## Command cheat-sheet

| Command | What it does |
|---|---|
| `dbt debug` | Verify connection + config |
| `dbt build` | Models + tests, DAG order, fail-fast — the one command to rule them all |
| `dbt run -s stg_orders` | Build just one model |
| `dbt test -s staging` | Just the staging tests |
| `dbt run -s stg_orders --full-refresh` | Rebuild the incremental table from scratch (the escape hatch) |
| `dbt docs generate && dbt docs serve` | The documentation site + lineage graph |
| `dbt compile -s <model>` | Render Jinja → SQL without executing (debugging) |
