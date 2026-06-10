# Day 4 — dbt Advanced

> All exercises happen in [`dbt_training/`](../dbt_training/); the advanced features are already wired into the project so you can study working examples, then extend them.

## Topics Covered

- **Tests**: generic (`unique`, `not_null`, `accepted_values`, `relationships`), singular tests, packages (`dbt_utils`)
- **Documentation**: descriptions in YAML, `dbt docs generate/serve`, lineage graph
- **Seeds**: version-controlled lookup tables (`dbt seed`)
- **Macros & Jinja**: DRY SQL with reusable macros
- **Snapshots**: SCD Type 2 change history
- **Incremental models**: `is_incremental()`, `unique_key`, when (not) to use them
- `dbt build` and node selection syntax (`-s`, `+model+`, `tag:`, `state:modified`)

## Hands-On Practice

1. **Tests** — run `dbt test`. Then break one on purpose: insert a duplicate order into `RAW.ORDERS`, run `dbt test -s stg_orders`, read the failure, find the failing rows with the compiled test SQL in `target/`, delete the duplicate row, and re-run. Study the singular test in [`tests/assert_no_negative_completed_revenue.sql`](../dbt_training/tests/assert_no_negative_completed_revenue.sql); write your own: *no order may predate its customer's signup date*.
2. **Seeds + macros** — `dbt seed`, then read [`macros/convert_to_usd.sql`](../dbt_training/macros/convert_to_usd.sql) and see it used in `stg_orders`. Extend `fx_rates.csv` with a new currency and rebuild.
3. **Snapshots** — `dbt snapshot`, then change a customer's `COUNTRY` in `RAW.CUSTOMERS` (SQL in Snowsight), `dbt snapshot` again, and inspect `dbt_valid_from`/`dbt_valid_to` in the snapshot table.
4. **Incremental** — `dbt run -s fct_web_events` twice; compare the queries in Snowflake Query History (first = full build, second = insert of 0 new rows). Insert a new JSON event into `RAW.WEB_EVENTS_RAW` and run again. Try `dbt run -s fct_web_events --full-refresh`.
5. **Docs** — `dbt docs generate && dbt docs serve`; explore the lineage graph from source to mart.
6. **One command** — `dbt build` and observe the DAG-ordered seed → run → test sequence.

## Learning Outcomes

- Add meaningful tests and documentation to every model
- Capture slowly changing dimensions with snapshots
- Build correct incremental models and know when a simple table is better
- Use macros/seeds to keep transformation logic DRY and reviewable
