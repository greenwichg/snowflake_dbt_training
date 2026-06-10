# Day 5 — Pipeline Design + Capstone Kickoff

## Topics Covered

### Layered ELT architecture (medallion-style)

```
 Sources          RAW (bronze)          STAGING (silver)        MARTS (gold)
─────────        ─────────────         ─────────────────       ──────────────
 app DB   ─┐      land data            1:1 with sources,        dim_/fct_ tables,
 SaaS APIs ┼───→  exactly as     ───→  renamed, typed,    ───→  business logic,
 files     ┘      received             cleaned (views)          consumed by BI
            (COPY INTO / Snowpipe /     (dbt staging)            (dbt marts)
             Fivetran / Airbyte)
```

Principles:
- **Raw is immutable** — never transform on the way in; you can always rebuild downstream.
- **One staging model per source table**, no joins — just rename/cast/clean.
- **Business logic lives in marts only**, built from `ref()`s, never from raw.
- **Idempotency** — every layer can be re-run safely (COPY load history, incremental `unique_key`, full-refresh capability).

### Ingestion options into RAW

| Pattern | Tooling | When |
|---|---|---|
| Batch files | `COPY INTO` (Day 1), external stages | Periodic exports, vendor feeds |
| Continuous files | Snowpipe (auto-ingest from S3 events) | Streaming-ish file drops |
| CDC inside Snowflake | Streams & Tasks (Day 2) | Derived raw→raw propagation |
| Managed connectors | Fivetran / Airbyte | SaaS sources (Salesforce, Stripe…) |

### Orchestration & environments

- Scheduling dbt: dbt Cloud jobs, Airflow (`dbt build` in a DAG task), or Snowflake Tasks calling stored procs.
- Environments: dev (personal schemas) → CI (ephemeral schema per PR, `dbt build --select state:modified+`) → prod (dedicated role/warehouse/schema).
- Failure handling: tests gate promotion; alerts on `dbt build` non-zero exit; source freshness checks detect stalled ingestion.

## Hands-On: Design Exercise (morning)

In pairs, design on paper a pipeline for this scenario, then present in 10 minutes:

> *An e-commerce company receives: (1) hourly order CSVs from the order system into S3, (2) a clickstream JSON feed, (3) a daily product catalog export. The BI team needs revenue and conversion dashboards refreshed hourly; finance needs month-end-stable numbers.*

Your design must specify: stage types & file formats, COPY/Snowpipe choice, schemas & roles, dbt layer structure, materializations per layer, test strategy, schedule, and how month-end stability is achieved (hint: snapshots).

## Capstone Kickoff (afternoon)

Form teams and start the [Day 6 capstone](../day6_capstone/README.md) — finish scoping and data loading today so Day 6 is for building and presenting.

## Learning Outcomes

- Design an end-to-end layered ELT pipeline on Snowflake + dbt
- Choose appropriate ingestion, materialization, and orchestration per workload
- Plan environments, testing, and failure handling like a production team
