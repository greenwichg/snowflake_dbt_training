# Snowflake + DBT Training Plan

**6-Day Intensive Program** | Days 1–4: Core Skills | Day 5: Pipeline Design | Days 5–6: Capstone Project

This repository contains all materials — guides, SQL scripts, sample data, and a working dbt project — for a hands-on Snowflake + dbt training program.

## Program Overview

| Day | Theme | Focus |
|-----|-------|-------|
| [Day 1](day1_snowflake_fundamentals/) | Modern Data Warehousing + Snowflake Fundamentals | Snowflake architecture, databases/schemas/tables, stages, COPY INTO, semi-structured data |
| [Day 2](day2_snowflake_advanced/) | Snowflake Advanced Features | Warehouses & scaling, Time Travel, zero-copy cloning, Streams & Tasks, access control |
| [Day 3](day3_dbt_fundamentals/) | dbt Fundamentals | dbt project setup, models, sources, `ref()`, materializations, Jinja basics |
| [Day 4](day4_dbt_advanced/) | dbt Advanced | Tests, documentation, snapshots, incremental models, macros, packages |
| [Day 5](day5_pipeline_design/) | Pipeline Design + Capstone Kickoff | End-to-end ELT pipeline design, layered architecture, orchestration, capstone start |
| [Day 6](day6_capstone/) | Capstone Project | Build and present a complete Snowflake + dbt pipeline |

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
day6_capstone/                 Capstone project specification
dbt_training/                  Working dbt project used in Days 3–6
```
