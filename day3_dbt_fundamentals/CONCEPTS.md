# Day 3 Concepts — Explained from Zero

Read this *before* the [Day 3 lab](README.md). You know Snowflake basics now; today is about dbt.

---

## 1. The problem dbt solves

By Day 2 you could already transform data: write a `CREATE VIEW cleaned AS SELECT …` in a worksheet. So why a whole tool?

Because on a real team, "a pile of SQL in worksheets" rots fast. Nobody knows which script built which table, in what order they must run, whether yesterday's edit broke the revenue numbers, or which version is current. There's no review, no testing, no history.

Software engineers solved these exact problems decades ago — with version control, automated tests, and documentation. **dbt (data build tool)** applies that discipline to SQL transformations. This mindset has a name: **analytics engineering**.

**What dbt actually is:** a command-line program that reads a folder of `SELECT` statements, figures out their correct order, wraps them in the right `CREATE TABLE/VIEW` commands, and runs them in Snowflake. **dbt has no database and stores no data** — Snowflake does all the work; dbt is the organized foreman. (dbt **Core** is the free CLI we use; dbt **Cloud** is a paid hosted version with a browser IDE and scheduler.)

## 2. A model = one SELECT in one file

The unit of work in dbt is a **model**: a `.sql` file containing **only a `SELECT`** — no CREATE, no INSERT:

```sql
-- models/staging/stg_customers.sql
select customer_id, lower(email) as email, upper(country) as country_code
from raw.customers
```

Run `dbt run`, and dbt turns each file into a database object named after the file (here: a view called `stg_customers`). You write *what* the data should be; dbt handles *how it gets built*. Change a file, `dbt run` again — the object is rebuilt. The exact SQL dbt sent to Snowflake is always visible in the `target/` folder.

## 3. `ref()` and `source()` — the magic that builds the pipeline

The most important idea in dbt. Models don't hardcode table names; they declare what they depend on:

- `{{ source('raw', 'customers') }}` → "the raw table `customers` that something else loaded" (declared once in a YAML file)
- `{{ ref('stg_customers') }}` → "the output of my model file `stg_customers.sql`"

```sql
-- models/marts/dim_customers.sql
select * from {{ ref('stg_customers') }}
```

Because dbt can read every file's refs, it learns the entire dependency graph — the **DAG** (directed acyclic graph; just "a flowchart of what feeds what"):

```
source: raw.customers → stg_customers → dim_customers
```

So `dbt run` **always builds things in the correct order** (and parallelizes what's independent). A typo'd ref fails immediately at compile time, before touching Snowflake. And when you run in a different environment, `ref()` automatically points at *that environment's* copies — same code in dev and prod.

## 4. Materializations — what kind of object each model becomes

The same `SELECT` can be saved into Snowflake in four ways. One config line chooses:

| Materialization | dbt builds… | When to use |
|---|---|---|
| **view** | `CREATE VIEW` — saved query, re-computed when read | Cheap, always fresh. Default for light cleanup (staging) |
| **table** | `CREATE TABLE AS` — results physically stored | Fast to query, rebuilt each `dbt run`. For final, heavily-queried models |
| **incremental** | First run: full table. Later runs: **only new rows** appended/merged | Huge event tables where full rebuilds get too slow |
| **ephemeral** | **Nothing!** The SQL gets pasted as a CTE into whichever models ref it | Shared intermediate logic that nobody queries directly |

Beginner rule: **views for staging, tables for marts**, incremental only when a rebuild actually hurts, ephemeral when a step is just shared logic.

For incremental models, the file contains a guarded filter — `{% if is_incremental() %} where event_ts > (select max(event_ts) from {{ this }}) {% endif %}` — meaning: "on repeat runs, only take rows newer than what I already have."

## 5. Jinja — the `{{ }}` stuff

dbt files aren't plain SQL; they're SQL **templates** using Jinja: `{{ … }}` inserts a value (like `ref()`), `{% … %}` is logic (ifs, loops). dbt *compiles* the template into pure SQL, then sends that to Snowflake. You can always inspect the compiled result in `target/compiled/` — when confused, look there; it's just SQL.

## 6. Project structure — where everything lives

```
dbt_training/
├── dbt_project.yml      the config: project name, folder-level settings
├── models/              your SELECTs (the heart of it)
│   ├── staging/         light cleanup, 1:1 with sources  → views
│   └── marts/           business-ready outputs           → tables
├── seeds/               small CSVs dbt can load (lookup tables)
├── snapshots/           history-keepers (next section)
├── macros/              reusable SQL snippets (Day 4)
├── tests/               data quality checks (Day 4)
└── target/              ⚙ generated — the compiled SQL dbt actually ran
```

One file lives *outside* the project: **`profiles.yml`** (in `~/.dbt/`) holds your Snowflake credentials — kept out of the repo so passwords never reach Git. `dbt debug` checks it can connect.

Naming you'll see everywhere: **staging models** (`stg_…`) = rename/clean each raw table, nothing more; **marts** (`dim_…` facts-about-things, `fct_…` records-of-events) = the tables analysts actually use.

## 7. Seeds — small CSVs as version-controlled tables

Some tables aren't "data", they're *reference facts you maintain by hand*: currency→USD rates, country codes, status mappings. dbt lets you keep them as CSVs in the repo; `dbt seed` loads them into Snowflake, and models can `ref()` them like anything else. Edits are reviewed in Git like code. (For big or fast-changing data, use real loading — seeds are for small, slow-moving lookups.)

## 8. Snapshots — remembering what the data used to say

Source tables usually keep only the *present*: when a customer moves from the US to Canada, the old value is gone. But analysis often needs the past ("revenue by where customers lived *at the time*").

A dbt **snapshot** watches a table and keeps every version of every row, adding validity timestamps:

| customer_id | country | dbt_valid_from | dbt_valid_to |
|---|---|---|---|
| 1 | US | 2024-01-01 | 2025-03-04 |
| 1 | CA | 2025-03-04 | *null* ← current |

Run `dbt snapshot` on a schedule; changed rows get their old version "closed" (valid_to filled) and a new current version added. The data-warehousing name for this pattern is **SCD Type 2** ("slowly changing dimensions, kept as history rows") — worth knowing because interviewers love it.

## Mini-glossary for Day 3

| Term | Plain meaning |
|---|---|
| Analytics engineering | Treating SQL transformations like software: versioned, tested, documented |
| Model | One .sql file with one SELECT; becomes a view/table named after the file |
| `ref()` / `source()` | "Output of that model" / "that raw table" — builds the DAG |
| DAG | The dependency flowchart dbt derives; determines run order |
| Materialization | What a model becomes: view, table, incremental, ephemeral |
| Jinja | The `{{ }}` templating; compiled SQL lands in `target/` |
| `profiles.yml` | Your credentials file, outside the repo |
| Seed | Small CSV loaded as a table (`dbt seed`) |
| Snapshot / SCD2 | History-keeping with valid_from/valid_to rows |

➡️ Now do the [Day 3 lab](README.md#hands-on-practice) — install dbt, connect it, and build this project's models.
