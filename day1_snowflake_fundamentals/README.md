# Day 1 — Modern Data Warehousing + Snowflake Fundamentals

## Topics Covered

### 1. Traditional DW vs Cloud DW

| | Traditional DW (Teradata, on-prem Oracle) | Cloud DW (Snowflake, BigQuery, Redshift) |
|---|---|---|
| Provisioning | Buy hardware up front, capacity planning | On-demand, scale in seconds |
| Scaling | Coupled compute + storage, expensive | Independent compute & storage scaling |
| Maintenance | DBA-heavy: indexes, vacuuming, tuning | Mostly managed by the platform |
| Cost model | Large CapEx | Pay-per-use OpEx |
| Concurrency | Workloads compete for one cluster | Isolated virtual warehouses per workload |

### 2. OLTP vs OLAP

- **OLTP** (Online Transaction Processing): many small reads/writes, row-oriented storage, normalized schemas, e.g. an orders service backed by PostgreSQL.
- **OLAP** (Online Analytical Processing): few large scans/aggregations, column-oriented storage, denormalized/star schemas, e.g. revenue-by-region dashboards.
- Snowflake is an **OLAP** system — it stores data in compressed columnar *micro-partitions* and is not intended to back transactional applications.

### 3. ETL vs ELT

- **ETL**: Extract → Transform (on a separate engine, e.g. Informatica) → Load. Transformation happens *before* the warehouse.
- **ELT**: Extract → Load (raw data lands in the warehouse) → Transform (inside the warehouse with SQL). Cheap cloud storage + elastic compute made this the modern default.
- **dbt** (Days 3–6) is the "T" in ELT: it transforms raw loaded data into analytics-ready models using SQL inside Snowflake.

### 4. Snowflake Architecture — Three Layers

```
┌─────────────────────────────────────────────┐
│ Cloud Services                              │  Auth, metadata, query parsing/
│ (the "brain")                               │  optimization, transactions, security
├─────────────────────────────────────────────┤
│ Compute — Virtual Warehouses                │  Independent MPP clusters (XS–6XL).
│ (the "muscle")                              │  Each workload gets its own; pay only
│                                             │  while running; auto-suspend/resume.
├─────────────────────────────────────────────┤
│ Storage                                     │  Columnar micro-partitions in cloud
│ (the "memory")                              │  object storage (S3/Blob/GCS).
│                                             │  All warehouses see the same data.
└─────────────────────────────────────────────┘
```

Key consequence — **compute–storage separation**: you can run a loading warehouse, a BI warehouse, and a data-science warehouse against the *same* data simultaneously with zero contention, and resize or suspend each independently.

### 5. Object Hierarchy

```
Account
└── Database            (logical grouping, e.g. TRAINING_DB)
    └── Schema          (namespace, e.g. RAW, ANALYTICS)
        ├── Tables      (permanent | transient | temporary)
        ├── Views
        ├── Stages      (file landing areas)
        └── File Formats
```

### 6. Stages — Internal vs External

| Stage type | Lives in | Reference | Use case |
|---|---|---|---|
| **User stage** | Snowflake | `@~` | Personal scratch files |
| **Table stage** | Snowflake | `@%my_table` | Files for one specific table |
| **Named internal stage** | Snowflake | `@my_stage` | Shared loading area (most common internal) |
| **External stage** | Your S3 / Azure Blob / GCS | `@my_ext_stage` | Production pipelines, data lake integration |

### 7. COPY INTO & File Formats

`COPY INTO <table> FROM @stage` is Snowflake's bulk-loading command. A **file format** object tells it how to parse files (CSV delimiters, JSON, Parquet, compression). Load metadata is kept for 64 days, so re-running a COPY does **not** duplicate already-loaded files.

### 8. Semi-structured Data (JSON / VARIANT)

The `VARIANT` type stores JSON, Avro, Parquet, etc. natively. Query it with path notation — `col:path.to.field::string` — and explode arrays with `LATERAL FLATTEN`.

---

## Hands-On Practice

Work through the scripts in order. Each is self-contained and commented.

| # | Exercise | Script |
|---|---|---|
| 1 | Create Snowflake trial account & explore Snowsight UI | [`01_account_setup_snowsight.md`](01_account_setup_snowsight.md) |
| 2 | Create database / schema / tables | [`sql/02_create_database_schema_tables.sql`](sql/02_create_database_schema_tables.sql) |
| 3 | Load CSV manually and via COPY INTO | [`sql/03_load_csv_copy_into.sql`](sql/03_load_csv_copy_into.sql) |
| 4 | Query JSON / VARIANT data | [`sql/04_query_json_variant.sql`](sql/04_query_json_variant.sql) |
| 5 | Create stages and file formats | [`sql/05_stages_file_formats.sql`](sql/05_stages_file_formats.sql) |
| 6 | SQL refresher — complex analytical queries | [`sql/06_sql_refresher_analytics.sql`](sql/06_sql_refresher_analytics.sql) |

Sample data lives in [`data/`](data/): `customers.csv`, `orders.csv`, `web_events.json`.

---

## Learning Outcomes

By the end of Day 1 you should be able to:

- ✅ Explain Snowflake architecture and the ELT approach
- ✅ Understand compute–storage separation
- ✅ Load and query structured & semi-structured data
- ✅ Write complex analytical SQL queries
