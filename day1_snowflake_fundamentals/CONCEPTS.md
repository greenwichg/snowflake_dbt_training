# Day 1 Concepts — Explained from Zero

Read this *before* the [Day 1 lab](README.md). No prior data-warehouse knowledge assumed.

---

## 1. What is a data warehouse, and why does it exist?

Your company's applications (the online shop, the payment system, the CRM) each keep their own database. Those databases are built for **running the business**: save this order, update that address — thousands of tiny operations per second.

But the questions the business *asks* look totally different: *"What was revenue per country last quarter?"*, *"Which customers are about to churn?"*. Answering them means scanning **millions of rows across many systems at once**. Doing that on the live shop database would slow real customers down — and the data you need is scattered across five different systems anyway.

A **data warehouse** is a separate database, built for exactly one job: collect data from all those systems in one place, and make big analytical questions fast and safe to ask. Snowflake is a data warehouse.

## 2. OLTP vs OLAP — the two database personalities

These two acronyms just name the two jobs from above:

| | OLTP — *transaction* processing | OLAP — *analytical* processing |
|---|---|---|
| Job | Run the business | Understand the business |
| Typical operation | "Save order #1042" | "Average order value by month" |
| Touches | One row at a time | Millions of rows at once |
| Example system | PostgreSQL behind your shop | Snowflake |

**Analogy:** OLTP is a cashier — fast at handling one customer's purchase. OLAP is an accountant — slow at selling you a coffee, brilliant at analyzing a year of receipts.

A technical consequence worth knowing: OLTP databases store data **row by row** (grab one whole order quickly), warehouses store it **column by column** (scan just the `amount` column of 100M orders without reading anything else). Same data, different physical layout, each optimized for its job.

## 3. ETL vs ELT — when does the cleanup happen?

Data arriving from source systems is messy: inconsistent formats, duplicates, weird codes. It must be **transformed** before analysts can trust it. The acronyms describe *where* that happens:

- **ETL (old way):** Extract from sources → **Transform on a separate processing server** → Load the cleaned result into the warehouse. You needed this when warehouse compute was scarce and expensive.
- **ELT (modern way):** Extract → **Load the raw, messy data straight into the warehouse** → Transform it *inside* the warehouse using SQL.

ELT won because cloud storage became dirt cheap and cloud warehouses became elastic — so why maintain a separate transformation server? Keeping the raw data also means you can always re-derive everything when requirements change.

**Remember this:** the tool you'll learn from Day 3, **dbt, is the "T" in ELT**. Snowflake stores and computes; dbt organizes the SQL transformations.

## 4. Snowflake's architecture — three layers, separated on purpose

Snowflake splits the classic "database server" into three independent layers:

```
┌────────────────────────────┐
│ Cloud Services  (the brain)│  Receives your SQL, plans it, checks permissions,
│                            │  tracks metadata. Always on; you barely pay for it.
├────────────────────────────┤
│ Compute         (the hands)│  "Virtual warehouses" — clusters of machines that
│                            │  actually execute queries. You switch them on/off.
├────────────────────────────┤
│ Storage         (the shelf)│  Your data, compressed into columnar files in
│                            │  cloud storage (S3/Azure/GCS). Always available.
└────────────────────────────┘
```

⚠️ **Naming trap:** in Snowflake, a **"warehouse" means a compute cluster** — an engine that runs queries — *not* the place data lives. Data lives in the storage layer. Yes, everyone finds this confusing on day one.

**Why the separation matters (this is THE Snowflake idea):**
- Storage and compute **scale independently**. Keep petabytes stored cheaply while running zero compute at 3am.
- Many compute warehouses can read **the same data simultaneously** without fighting: the loading team, the dashboard users, and the data scientists each get their own engine.
- Compute is billed **per second while running**. Suspend a warehouse → cost stops, data stays.

**Analogy:** a library (storage) where every reading group brings its own table and lamps (compute). Groups don't disturb each other, tables fold away when unused, and the books stay put.

## 5. How Snowflake organizes things: database → schema → table

Just folders within folders:

```
Account                      your whole Snowflake tenancy
└── Database  (TRAINING_DB)  big top-level container
    └── Schema  (RAW)        a named folder inside it
        ├── Tables           the actual data (rows & columns)
        ├── Views            saved SELECT queries that act like tables
        ├── Stages           file in-boxes (next section)
        └── File formats     descriptions of how to parse files
```

A full object name is `database.schema.table`, e.g. `TRAINING_DB.RAW.CUSTOMERS`. In the lab we create two schemas that mirror ELT: `RAW` (data exactly as it arrived) and `ANALYTICS` (cleaned-up, ready to query).

Table flavors you'll meet: **permanent** (default, fully protected), **transient** (cheaper, skips some recovery protection — fine for reloadable raw data), **temporary** (vanishes when your session ends).

## 6. Getting data in: stages, file formats, COPY INTO

Three pieces that work together, used in every real loading pipeline:

1. **Stage** = a file in-box. A place to put files (CSV, JSON…) *before* loading them into tables. An **internal** stage lives inside Snowflake (you upload to it); an **external** stage just points at your company's cloud bucket (S3/Azure/GCS) where files already land.
2. **File format** = parsing instructions, saved once and reused: "comma-separated, first row is headers, quotes around text, dates look like YYYY-MM-DD".
3. **`COPY INTO table FROM @stage`** = the bulk-load command: read files from the in-box, parse them per the file format, append the rows to a table.

A lovely safety feature: Snowflake remembers which files each table already loaded (for 64 days). Run the same `COPY INTO` twice and the second run loads **nothing** — no accidental duplicates. The fancy word for "safe to re-run" is **idempotent**; you'll hear it a lot.

## 7. Semi-structured data: JSON and VARIANT

Not all data comes as neat rows and columns. Web/app events usually arrive as **JSON** — nested, flexible blobs:

```json
{"event_type": "purchase", "user": {"customer_id": 5, "device": "mobile"},
 "items": [{"sku": "WIDGET-A", "qty": 2}]}
```

Old-school warehouses forced you to flatten this into columns *before* loading — and every time the app team added a field, your pipeline broke. Snowflake instead has a column type called **`VARIANT`**: it stores the whole JSON object as-is, and you query inside it with a path syntax:

```sql
SELECT event:user.customer_id::integer,   -- reach into the nest, cast to a type
       event:user.device::string
FROM raw_events;
```

For lists inside the JSON (like `items`), **`LATERAL FLATTEN`** unpacks one row per list element. This is ELT in miniature: load the raw JSON now, decide how to flatten it later — and change your mind freely, because the original is still there.

## 8. Mini-glossary for Day 1

| Term | Plain meaning |
|---|---|
| Warehouse (Snowflake) | A compute engine you switch on to run queries. Not storage! |
| Micro-partition | The small compressed file chunks Snowflake stores tables as (becomes important Day 2) |
| Stage | File in-box for loading |
| File format | Saved parsing instructions for files |
| `COPY INTO` | Bulk "load files into table" command |
| VARIANT | Column type that holds whole JSON objects |
| Idempotent | Safe to run twice — second run changes nothing |
| Snowsight | Snowflake's browser UI |
| Credit | Snowflake's billing unit; an XS warehouse burns 1 credit/hour *while running* |

➡️ Now do the [Day 1 hands-on lab](README.md#hands-on-practice) — every concept above appears there in runnable form.
