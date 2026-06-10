# Days 5–6 — Capstone Project

Build a complete, working ELT pipeline on Snowflake + dbt and present it. This is the proof of everything from Days 1–5.

## The Brief

You run analytics for **"NorthWind Outfitters"**, an online retailer. Leadership wants a trustworthy revenue & customer-behavior data platform. You have:

- `customers.csv` and `orders.csv` (Day 1 data — or generate/extend your own, more rows encouraged)
- `web_events.json` clickstream (Day 1 data — extend it with more events)
- An FX-rates lookup (seed)

## Required Deliverables

### 1. Snowflake foundation (Day 1–2 skills)
- [ ] Dedicated database with `RAW` schema; file formats and named stages
- [ ] All three datasets loaded via `COPY INTO` (no UI wizard!)
- [ ] JSON landed in a `VARIANT` column, not pre-flattened
- [ ] RBAC: a `TRANSFORMER` role for dbt and a read-only `ANALYST` role
- [ ] One Stream + Task that propagates newly inserted raw orders (Day 2 lab pattern), **or** a documented Snowpipe design

### 2. dbt project (Day 3–4 skills)
- [ ] Sources declared with at least one freshness rule
- [ ] Staging layer: one view model per raw table
- [ ] Marts: at least `dim_customers`, `fct_orders`, and one model of your own design (e.g. `fct_sessions`, `fct_monthly_revenue`)
- [ ] At least one **incremental** model with a justified `unique_key`
- [ ] One **snapshot** capturing customer changes (SCD2)
- [ ] One custom **macro** used by ≥1 model
- [ ] Tests: every primary key `unique`+`not_null`, at least one `relationships`, one `accepted_values`, and one singular test
- [ ] Descriptions on every model; `dbt docs generate` works
- [ ] `dbt build` completes green from a clean schema

### 3. Analytics layer
Answer with SQL over your marts (present the results):
- [ ] Monthly revenue trend with month-over-month growth %
- [ ] Top 5 customers by lifetime value, with their order counts
- [ ] Conversion rate from `page_view` to `purchase` by device
- [ ] One business question your team invents

### 4. Presentation (15 min/team)
- [ ] Architecture diagram: source → stage → RAW → staging → marts → consumers
- [ ] Live demo: insert a new raw order + a new web event, run the pipeline, show them appear in the marts
- [ ] Walk through the dbt lineage graph and one test failure you fixed
- [ ] Trade-offs: what you'd change for 100× the data volume

## Evaluation Rubric

| Criterion | Weight |
|---|---|
| Pipeline works end-to-end (live demo) | 30% |
| dbt project quality: layering, tests, docs | 25% |
| Correct use of Snowflake features (stages, VARIANT, streams/tasks, RBAC) | 20% |
| SQL quality of analytics queries | 15% |
| Presentation clarity & design trade-off discussion | 10% |

## Tips

- Start from a **clean database** (e.g. `CAPSTONE_DB`) — don't reuse `TRAINING_DB` objects; rebuilding from scratch is the test of whether you understood Days 1–4.
- Commit your work: SQL setup scripts + the dbt project in a Git repo, with a README explaining how to run it from zero.
- Budget: load and foundation by end of Day 5; models/tests Day 6 morning; polish and rehearse Day 6 afternoon.
