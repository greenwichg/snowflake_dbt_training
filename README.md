# Snowflake + DBT Training Plan

**Intensive Program** | Days 1–4: Core Skills | Day 5: Pipeline Design | Days 6–7: 2-Day Capstone | Day 8: Demo

This repository contains all materials — guides, SQL scripts, sample data, and a working dbt project — for a hands-on Snowflake + dbt training program.

## Program Overview

| Day | Theme | Focus |
|-----|-------|-------|
| [Day 1](day1_snowflake_fundamentals/) | Modern Data Warehousing + Snowflake Fundamentals | Snowflake architecture, databases/schemas/tables, stages, COPY INTO, semi-structured data |
| [Day 2](day2_snowflake_advanced/) | Snowflake Performance, Security & Advanced Features | Caching & clustering, query profiling & cost, secure views & RBAC, Time Travel, Streams & Tasks, Snowpipe, Dynamic Tables, cloning & sharing, Iceberg overview |
| [Day 3](day3_dbt_fundamentals/) | Introduction to DBT — Models, Project Structure & Materializations | Core vs Cloud, project structure, all materializations, sources & refs, Jinja, seeds & snapshots |
| [Day 4](day4_dbt_advanced/) | DBT Transformations, Testing & Documentation | Macros, staging→intermediate→marts design, generic/singular/custom tests, dbt-expectations, docs & lineage, data contracts |
| [Day 5](day5_pipeline_design/) | Building the End-to-End Pipeline (Snowflake + DBT Only) | Medallion architecture (Bronze→Silver→Gold), incremental patterns, debugging, cost monitoring & query optimization |
| [Day 6](capstone/) | Capstone Day 1 of 2 — Data Ingestion + Bronze & Silver Layers | Retail Sales Analytics Platform: COPY INTO loads, sources, staging models, tests, incremental orders |
| [Day 7](capstone/) | Capstone Day 2 of 2 — Gold Layer, Documentation & Presentation | Three Gold marts, surrogate key macro, relationship tests, dbt docs & lineage |
| [Day 8](capstone/README.md#day-8--demo-to-stakeholders-and-team) | Demo to Stakeholders and Team | Architecture walkthrough, business insights, Q&A |

The hands-on exercises are numbered 1–30 across Days 1–5, matching the training plan document.

**Completely new to Snowflake and dbt?** Each day folder contains a `CONCEPTS.md` that explains every topic from zero — plain language, analogies, and a mini-glossary. Read it before that day's lab: [Day 1](day1_snowflake_fundamentals/CONCEPTS.md) · [Day 2](day2_snowflake_advanced/CONCEPTS.md) · [Day 3](day3_dbt_fundamentals/CONCEPTS.md) · [Day 4](day4_dbt_advanced/CONCEPTS.md) · [Day 5](day5_pipeline_design/CONCEPTS.md)

## Day 1 — Modern Data Warehousing + Snowflake Fundamentals

**Topics Covered**
- Traditional DW vs Cloud DW
- OLTP vs OLAP
- ETL vs ELT
- Snowflake Architecture (Storage, Compute, Cloud Services)
- Databases, Schemas, Tables, Stages
- Snowflake SQL Refresher
- COPY INTO & File Formats
- Internal vs External Stages
- Semi-structured Data (JSON/VARIANT)

**Hands-On Practice**
1. Create Snowflake trial account & explore Snowsight UI
2. Create database / schema / tables
3. Load CSV manually and via COPY INTO
4. Query JSON / VARIANT data
5. Create stages and file formats

**Learning Outcomes**
- Explain Snowflake architecture and ELT approach
- Understand compute–storage separation
- Load and query structured & semi-structured data
- Write complex analytical SQL queries

## Prerequisites

- A [Snowflake trial account](https://signup.snowflake.com/) (free, 30 days)
- Python 3.9+ (for dbt, Days 3+): `pip install dbt-snowflake`
- A SQL client — Snowsight (browser) is sufficient for Days 1–2

## Repository Layout

```
day1_snowflake_fundamentals/   Guides + SQL scripts + sample data
day2_snowflake_advanced/       Advanced Snowflake feature labs
day3_dbt_fundamentals/         dbt setup guide + first models
day4_dbt_advanced/             Tests, snapshots, incremental labs
day5_pipeline_design/          Pipeline architecture + design exercise
capstone/                      Days 6-8: Retail Sales Analytics Platform capstone (+ datasets)
dbt_training/                  Working dbt project used in Days 3–6
```
