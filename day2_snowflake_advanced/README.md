# Day 2 — Snowflake Performance, Security & Advanced Features

> 🧠 **New to these topics?** Read [CONCEPTS.md](CONCEPTS.md) first — every concept below explained from zero, with analogies.

> Builds on the `TRAINING_DB` objects created on Day 1.

## Topics Covered

- **Virtual Warehouses & Caching** — sizing, scale-up vs scale-out, multi-cluster; result / warehouse / metadata caches
- **Micro-partitions & Clustering** — how Snowflake stores data, partition pruning, clustering keys, when (not) to cluster
- **Query Profiling & Cost Optimization** — reading the Query Profile, spotting spills & full scans, credit monitoring, resource monitors
- **Secure Views & RBAC** — roles, grants, users, role hierarchy; why secure views for data sharing
- **Time Travel & Fail-safe** — querying/restoring historical data, retention windows
- **Streams & Tasks (CDC concepts)** — change tracking, task scheduling and graphs
- **Snowpipe** — continuous, serverless file ingestion with auto-ingest
- **Dynamic Tables** — declarative incremental pipelines; vs Materialized Views
- **Zero-copy Clones & Data Sharing** — instant environments; secure shares to other accounts
- **Iceberg Tables Overview** — open table format on your own object storage, when to use vs native tables

## Hands-On Practice

| # | Exercise | Script |
|---|---|---|
| 6 | Analyze query profiles; create multi-size warehouses | [`sql/01_warehouses_profiling_cost.sql`](sql/01_warehouses_profiling_cost.sql) |
| 7 | Create secure views, roles and grant access | [`sql/04_access_control_secure_views.sql`](sql/04_access_control_secure_views.sql) |
| 8 | Use Time Travel to recover data | [`sql/02_time_travel_cloning.sql`](sql/02_time_travel_cloning.sql) |
| 9 | Create a Stream on a table and automate a Task | [`sql/03_streams_tasks.sql`](sql/03_streams_tasks.sql) |
| 10 | Configure a Snowpipe flow | [`sql/05_snowpipe.sql`](sql/05_snowpipe.sql) |
| 11 | Create a Dynamic Table vs Materialized View | [`sql/06_dynamic_tables_vs_mv.sql`](sql/06_dynamic_tables_vs_mv.sql) |
| 12 | Zero-copy clone a table/schema | [`sql/02_time_travel_cloning.sql`](sql/02_time_travel_cloning.sql) (part 3) |

## Learning Outcomes

- ✅ Explain Snowflake optimization techniques
- ✅ Understand secure data sharing & RBAC
- ✅ Explain CDC, automation, and Snowpipe ingestion
- ✅ Distinguish Dynamic Tables vs Materialized Views
- ✅ Use Time Travel and Zero-copy Clones confidently
