# Day 2 — Snowflake Advanced Features

> Builds on the `TRAINING_DB` objects created on Day 1.

## Topics Covered

- Virtual warehouses in depth: sizing, scaling up vs scaling out, multi-cluster
- Caching layers: result cache, warehouse cache, metadata cache
- **Time Travel** & **Fail-safe**: querying/restoring historical data
- **Zero-copy cloning**: instant dev/test environments
- **Streams & Tasks**: change data capture and native scheduling
- Access control: roles, grants, role hierarchy (RBAC)
- Query Profile: reading execution plans, spotting spills and pruning

## Hands-On Practice

| # | Exercise | Script |
|---|---|---|
| 1 | Warehouses, scaling & caching experiments | [`sql/01_warehouses_caching.sql`](sql/01_warehouses_caching.sql) |
| 2 | Time Travel: UNDROP, AT/BEFORE, restore from "accidents" | [`sql/02_time_travel_cloning.sql`](sql/02_time_travel_cloning.sql) |
| 3 | Streams & Tasks: incremental CDC pipeline | [`sql/03_streams_tasks.sql`](sql/03_streams_tasks.sql) |
| 4 | RBAC: create roles for an analyst persona | [`sql/04_access_control.sql`](sql/04_access_control.sql) |

## Learning Outcomes

- Choose appropriate warehouse sizes and explain scale-up vs scale-out
- Recover data with Time Travel and create environments with zero-copy clones
- Build a simple CDC flow with Streams & Tasks
- Design a basic role hierarchy and grant least-privilege access
