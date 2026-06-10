# Day 4 Concepts — Explained from Zero

Read this *before* the [Day 4 lab](README.md). Yesterday you built models; today you make them trustworthy, reusable, and documented.

---

## 1. Why test data at all?

Code is tested before release — but data breaks *after* release, silently: a source system starts sending duplicate orders, a status field gains a new value nobody mapped, an upstream rename turns a column to NULLs. The dashboards keep rendering; the numbers are just *wrong*. Usually a VP finds out before you do.

dbt's answer: **declare your assumptions about the data, and verify them on every run.** A dbt test is simply a query that hunts for rule-breaking rows — **zero rows found = test passed**. `dbt test` runs them all and reports failures.

## 2. Generic tests — one line of YAML each

The workhorses. Declared next to a column in a YAML file; dbt writes the checking query for you:

```yaml
columns:
  - name: order_id
    tests:
      - unique          # no duplicates
      - not_null        # no missing values
  - name: status
    tests:
      - accepted_values:
          arguments:
            values: ['completed', 'cancelled', 'refunded']   # closed list
  - name: customer_id
    tests:
      - relationships:                       # every order's customer must exist
          arguments:
            to: ref('stg_customers')
            field: customer_id
```

Those four — `unique`, `not_null`, `accepted_values`, `relationships` — catch a shocking share of real-world breakage. Minimum bar for every model: **primary key gets `unique` + `not_null`.**

## 3. Singular tests — a custom rule as a SQL file

When the rule is business-specific ("no completed order may have negative revenue"), write it yourself: drop a `.sql` file in `tests/` that **selects the violating rows**. Empty result = pass. That's the whole mechanism.

## 4. Custom generic tests — write your own reusable check

If you keep writing the same singular test for different columns, promote it: a parameterized test in `tests/generic/` —

```sql
{% test is_positive(model, column_name) %}
select {{ column_name }} from {{ model }}
where {{ column_name }} <= 0
{% endtest %}
```

— and now `- is_positive` works in YAML on any column, exactly like the built-ins. (This project applies it to `fct_orders.amount_usd`.)

## 5. Packages — installing other people's macros and tests

dbt has a package ecosystem (like pip/npm, listed in `packages.yml`, installed with `dbt deps`). The two you'll actually meet:

- **dbt_utils** — the standard library: extra tests (`accepted_range`…), helpers like `generate_surrogate_key` (you'll want that in the capstone).
- **dbt_expectations** — a big battery of assertion-style tests, e.g. "values must match this regex" (we use it to sanity-check email formats).

## 6. Macros — reusable SQL functions

A **macro** is a Jinja function that *generates SQL text* — dbt's answer to copy-paste. Define once in `macros/`:

```sql
{% macro convert_to_usd(amount_column, currency_column) %}
    round({{ amount_column }} * coalesce((select fx.usd_rate
        from {{ ref('fx_rates') }} fx
        where fx.currency = {{ currency_column }}), 1.0), 2)
{% endmacro %}
```

…use everywhere: `{{ convert_to_usd('source.amount', 'source.currency') }}`. Currency logic now has exactly one home — fix it once, every model gets the fix. Remember macros run **at compile time**: they paste SQL into your query; Snowflake never sees the macro itself. (Check `target/compiled/` to see the pasted result.)

## 7. The layer cake: staging → intermediate → marts

The convention that keeps dbt projects sane as they grow:

```
sources  →  staging (stg_)      →  intermediate (int_)     →  marts (dim_/fct_)
raw, messy   1:1 per source table,   reusable business steps,   the products: what
             rename/cast/clean,      often ephemeral            analysts query
             NO joins, NO logic
```

The rules that matter: **staging never joins** (one model per source table, cleanup only — it's the shock absorber when sources change); **business logic lives past staging, never reaches back to raw**; marts are built from `ref()`s of cleaned layers. In this project: `stg_orders` → `int_customer_orders` (ephemeral) → `dim_customers`.

Why bother? When a source renames a column, you fix **one staging model** and the whole pipeline downstream is oblivious. That's the payoff.

## 8. Docs & lineage — the self-writing documentation site

All those YAML `description:` fields aren't decoration. `dbt docs generate && dbt docs serve` builds a browsable website: every model, every column, every test — plus the **lineage graph**, a clickable drawing of the DAG from raw sources to final marts.

Two questions it answers in seconds that otherwise eat afternoons: *"Where does this revenue number actually come from?"* (walk lineage left) and *"If I change this table, what breaks?"* (walk lineage right).

## 9. Data contracts — freezing a model's shape

Tests check the *values* in data. A **contract** checks the *shape*: you list every column and its exact type in YAML with `contract: enforced: true`, and dbt **refuses to build** the model if its SELECT produces anything different. No silent drift of a schema that downstream dashboards (or another team) depend on — the model's interface becomes a promise.

A real lesson from building this very project: contract types are exact, and `number` in Snowflake means `NUMBER(38,0)` — **zero decimal places**. Our `lifetime_value_usd` was silently rounded to whole dollars until the contract was fixed to `number(12,2)`. Precision matters.

## Mini-glossary for Day 4

| Term | Plain meaning |
|---|---|
| dbt test | A query hunting for bad rows; zero rows = pass |
| Generic test | Reusable, YAML-declared (unique, not_null, …) |
| Singular test | One-off rule as a SQL file in `tests/` |
| Custom generic test | Your own parameterized test in `tests/generic/` |
| Package / `dbt deps` | Installable dbt libraries / the install command |
| Macro | Jinja function that generates SQL — DRY for queries |
| Staging / intermediate / marts | Clean 1:1 → reusable steps → final products |
| Lineage graph | Clickable map of what feeds what |
| Data contract | Enforced column names + types; build fails on drift |

➡️ Now do the [Day 4 lab](README.md#hands-on-practice) — including breaking a test on purpose to see a failure up close.
