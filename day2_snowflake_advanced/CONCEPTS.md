# Day 2 Concepts — Explained from Zero

Read this *before* the [Day 2 lab](README.md). Builds on [Day 1 concepts](../day1_snowflake_fundamentals/CONCEPTS.md).

---

## 1. Warehouse sizing: scale UP vs scale OUT

Warehouses come in T-shirt sizes (XS, S, M, L…). Each size up **doubles** the horsepower — and doubles the credits per hour. There are two different ways to add power, for two different problems:

- **Scale UP (bigger size):** one *huge* query is too slow → give it a bigger engine. An XL finishes a giant join much faster than an XS.
- **Scale OUT (more clusters, "multi-cluster"):** *many people* run small queries at once and they queue behind each other → add copies of the same engine so everyone gets served. Bigger wouldn't help here; *more* does.

**Analogy:** scale up = swap the van for a truck (one big delivery). Scale out = hire more vans (many small deliveries at once).

## 2. The three caches — why repeated queries are free

1. **Result cache** (brain layer): run the *exact same query text* again and Snowflake returns the saved answer instantly — no compute engine even starts, so it costs nothing. Lives 24h, shared across all users.
2. **Warehouse cache** (hands layer): a running warehouse keeps recently-read data on its local disks. Similar (not identical) queries skip re-downloading from storage. Dies when the warehouse suspends.
3. **Metadata cache** (brain layer): Snowflake permanently knows per-table stats like row counts and min/max values, so `COUNT(*)` answers instantly without any warehouse at all.

## 3. Micro-partitions & clustering — how tables are physically stored

Every Snowflake table is secretly stored as thousands of **micro-partitions**: compressed, columnar chunks of ~16MB, each covering some contiguous slice of rows. For every chunk, Snowflake records the **min and max value of every column** in it.

That bookkeeping enables **pruning**: ask for `WHERE order_date = '2024-07-15'` and Snowflake skips every chunk whose date range can't contain that day — reading maybe 3 chunks instead of 3,000. Pruning is *the* reason warehouse queries on huge tables come back in seconds.

Pruning works best when similar values sit physically together (data loaded in date order → date chunks are tight). If a giant table is queried by a column the data *isn't* sorted by, a **clustering key** tells Snowflake to keep it physically reorganized by that column — for a background-maintenance fee. Rule of thumb: clustering is a multi-terabyte-table tool; for normal tables, natural load order is fine.

## 4. Reading a Query Profile & controlling cost

The **Query Profile** (in Snowsight's query history) is the x-ray of how a query actually ran. The three things worth checking as a beginner:

- **Partitions scanned vs total** — is pruning working, or did you scan the whole table?
- **Spilling** — the warehouse ran out of memory and used disk; the query needs a bigger warehouse (scale up).
- **The fattest operator** — which step (join? sort?) consumed the time.

Cost in Snowflake ≈ **warehouse runtime**. The big levers: low `AUTO_SUSPEND` so idle engines switch off, start XS and grow only on evidence, give each team its own warehouse so you can see who spends what, and set a **resource monitor** — a credit budget that warns or force-suspends when exceeded.

## 5. RBAC and secure views — who may see what

Snowflake permissions follow **RBAC** (role-based access control): you never grant rights to people directly. Rights go to **roles** ("can read the ANALYTICS schema"), and people get roles. New analyst joins? One grant — done.

Day-2 lab roles: `TRANSFORMER` (what dbt will log in as — reads raw, builds cleaned data) and `ANALYST` (read-only on the cleaned data, can't even *see* raw). One subtlety: a grant on "all tables" covers only tables existing *now* — you also grant on **future** tables so tomorrow's tables are covered automatically.

A **secure view** is for showing someone *part* of a table — masked emails, only active customers — with guarantees: viewers can't read the view's definition, and Snowflake disables optimizer shortcuts that could leak the hidden rows. Required if you ever share data outside your account.

## 6. Time Travel & cloning — the "undo" superpowers

Because micro-partitions are never edited in place (changes write *new* chunks; old ones are kept a while), Snowflake gets two near-magic features almost for free:

- **Time Travel:** query a table *as it was* — `SELECT … FROM orders AT(OFFSET => -3600)` is "orders, one hour ago". Deleted rows by accident? Read the past and restore. Dropped a whole table? `UNDROP TABLE`. Default window 1 day, extendable to 90. (After that, **Fail-safe** gives Snowflake support 7 more days to rescue you — an emergency exit, not a tool.)
- **Zero-copy cloning:** `CREATE DATABASE dev CLONE prod` duplicates a database **instantly and for free**, because the clone just *points at the same chunks*. Only when one side changes does the changed part take new storage. Instant dev/test environments with real data.

## 7. Streams & Tasks — Snowflake's built-in automation (CDC)

**CDC** (change data capture) = "tell me what changed since I last looked, so I process only that, not the whole table."

- A **stream** sits on a table and acts like a tray of unread changes: query it and you see only rows inserted/updated/deleted since the stream was last consumed. Use it in an `INSERT…SELECT` and the tray empties.
- A **task** is a saved SQL statement on a schedule (cron, inside Snowflake). The classic pair: a task that runs every minute, *but only if the stream has data* (checking is free), and pipes the new rows onward.

Together: an always-on mini-pipeline with no external tools.

## 8. Snowpipe — files that load themselves

`COPY INTO` is something *you* run. **Snowpipe** is a saved COPY that runs *itself* whenever a new file lands in the stage — your cloud bucket notifies Snowflake, and within a minute the file is in the table. No schedule, no warehouse to manage (Snowflake bills small "serverless" per-file fees). It inherits COPY's no-duplicates memory. This is the standard "files drip in all day" ingestion pattern.

## 9. Dynamic Tables vs Materialized Views — self-refreshing results

Both are "a query whose results are kept stored and up to date automatically":

- **Materialized view:** auto-maintained copy of a *single-table* query (no joins allowed). Always exactly in sync. Good for pre-aggregating one huge table.
- **Dynamic table:** auto-maintained result of **any** query (joins, unions, window functions). You declare a freshness target — `TARGET_LAG = '1 minute'` means "never be more than a minute stale" — and Snowflake schedules incremental refreshes. Chain dynamic tables and you've declared a whole pipeline without writing any orchestration. Fresher lag = more compute = more cost; you choose the trade-off.

## 10. Data Sharing & Iceberg — two ways to be open (overview only)

- **Secure Data Sharing:** grant another Snowflake account live, read-only access to your (secure-view-wrapped) data. Nothing is copied; they query your storage with *their* compute. No more emailing CSVs.
- **Iceberg tables:** store a table's files in *your own* cloud bucket using Apache Iceberg, an open format that Spark/Trino/etc. can also read. You trade a little Snowflake performance/convenience for "no lock-in, many engines, one copy of the data".

## Mini-glossary for Day 2

| Term | Plain meaning |
|---|---|
| Multi-cluster | Warehouse that spawns copies of itself under concurrent load |
| Pruning | Skipping data chunks that can't match your filter |
| Clustering key | Asking Snowflake to keep a big table physically sorted |
| Spilling | Query ran out of memory → used disk → needs a bigger warehouse |
| Resource monitor | Credit budget with automatic warnings/cutoffs |
| RBAC | Permissions via roles, never directly to users |
| CDC | Processing only what changed since last time |
| Stream / Task | Unread-changes tray / scheduled SQL job |
| Snowpipe | Auto-loading of files as they arrive |
| `TARGET_LAG` | How stale a dynamic table is allowed to get |

➡️ Now run the [Day 2 labs](README.md#hands-on-practice).
