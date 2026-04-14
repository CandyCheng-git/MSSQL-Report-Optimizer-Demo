# sql-report-optimizer-demo

A SQL Server reporting optimisation demo that shows the difference between:

- querying raw transactional tables
- doing light query/index tuning
- redesigning the reporting path with a summary table and incremental refresh

This project was built to demonstrate practical backend and database judgement for a business reporting scenario, not just SQL syntax.

---

## Why this project exists

A common backend problem is this:

> A business report works, but it becomes too expensive to recalculate from transactional tables every time users need it.

A weak portfolio project would stop at:
- adding a few indexes
- rewriting the query a bit
- claiming the problem is solved

This project does something more honest and more useful:

1. measure the baseline query
2. test a first-pass optimisation
3. verify whether it actually reduces SQL Server work
4. if not, move to a reporting-oriented design
5. measure the result again

That is much closer to real engineering work.

---

## Project goal

The goal is to simulate a realistic sales reporting workflow and show how reporting performance can be improved in stages.

The project demonstrates:

- transactional schema design
- seeded sample data
- baseline reporting over raw tables
- first-pass query and index tuning
- summary-table design
- incremental refresh through a stored procedure
- summary-based report retrieval with lower latency

---

## Tech stack

- **SQL Server**
- **SSMS**
- T-SQL scripts
- benchmark evidence using:
  - `SET STATISTICS TIME ON`
  - `SET STATISTICS IO ON`
  - execution logs

---

## Current project structure

```text
.
│  README.md
│
├─database
│      01_create_tables.sql
│      02_seed_data.sql
│      03_slow_report.sql
│      04_indexes.sql
│      05_optimized_report.sql
│      06_summary_table.sql
│      07_incremental_refresh.sql
│      08_summary_report.sql
│
├─docs
│      architecture-notes.md
│      before-after-results.md
│
├─logs
│      03_slow_2026-04-14T190133.pdf
│      05_opt_2026-04-14T190401.pdf
│      06_sum_2026-04-14T191040.pdf
│      06_sum_2026-04-14T191306.pdf
│      07_incremental_2026-04-14T191110.pdf
│      08_sum_2026-04-14T193353.pdf
│      sp_referesh_daily_sales_sum_2026-04-14T191820.pdf
│
└─scripts
        StoredProcedure_usp_refresh_daily_sales_summary.sql
```

---

## Data model

The transactional model includes:

- `customers`
- `branches`
- `sales_reps`
- `orders`
- `order_items`

This supports a common reporting use case:

- filter recent business activity
- join transactional tables
- group by date, branch, and sales rep
- calculate order count, item count, and gross sales

The reporting layer adds:

- `daily_sales_summary`

This table stores pre-aggregated daily metrics so the report no longer needs to recalculate from raw transaction tables on every request.

---

## What each SQL file does

### `01_create_tables.sql`
Creates the transactional schema.

### `02_seed_data.sql`
Seeds the database with sample customers, branches, sales reps, orders, and order items.

### `03_slow_report.sql`
Runs the baseline report directly against transactional tables.

### `04_indexes.sql`
Adds starter indexes to support filtering and joins.

### `05_optimized_report.sql`
Tests a first-pass optimisation using cleaner filtering and supporting indexes.

### `06_summary_table.sql`
Creates `daily_sales_summary`, a summary table for pre-aggregated reporting data.

### `07_incremental_refresh.sql`
Creates `dbo.usp_refresh_daily_sales_summary`, a stored procedure that refreshes only a chosen date range instead of rebuilding all reporting history.

### `08_summary_report.sql`
Runs the final report against the summary table.

---

## How to run the project

### 1. Create the database
```sql
CREATE DATABASE SqlReportOptimizerDemo;
GO
```

### 2. Run the scripts in order
1. `01_create_tables.sql`
2. `02_seed_data.sql`
3. `03_slow_report.sql`
4. `04_indexes.sql`
5. `05_optimized_report.sql`
6. `06_summary_table.sql`
7. `07_incremental_refresh.sql`
8. execute the refresh stored procedure
9. `08_summary_report.sql`

### 3. Refresh the summary table
Example:
```sql
EXEC dbo.usp_refresh_daily_sales_summary
    @start_date = '2025-10-01',
    @end_date   = '2026-04-14';
GO
```

### 4. Benchmark properly
Use:
```sql
SET STATISTICS TIME ON;
SET STATISTICS IO ON;
GO
```

Do not rely only on the completion timestamp. Compare:
- CPU time
- elapsed time
- logical reads
- whether the query still touches raw transactional tables

---

## Benchmark results

## Baseline report
**File:** `03_slow_report.sql`

- CPU time: **219 ms**
- elapsed time: **287 ms**
- logical reads:
  - `order_items`: **389**
  - `orders`: **189**
  - `sales_reps`: **2**
  - `branches`: **2**
- rows returned: **1308**

## First-pass optimized report
**File:** `05_optimized_report.sql`

- CPU time: **203 ms**
- elapsed time: **277 ms**
- logical reads:
  - `order_items`: **389**
  - `orders`: **189**
  - `sales_reps`: **2**
  - `branches`: **2**
- rows returned: **1308**

### Interpretation
This first optimisation attempt only improved timing slightly and did **not** reduce logical reads.

That means SQL Server still performed almost the same underlying work.

This is important, because it shows that:
- query cleanup is not automatically real optimisation
- starter indexes do not always solve the reporting cost
- evidence should decide the next move

## Summary-table report
**File:** `08_summary_report.sql`

After building and refreshing `daily_sales_summary`:

- summary row count: **1408**
- CPU time: **15 ms**
- elapsed time: **103 ms**
- logical reads:
  - `daily_sales_summary`: **11**
  - `branches`: **2**
  - `sales_reps`: **2**
- rows returned: **1316**

### Interpretation
This is the first result in the project that shows a **material reporting improvement**.

The stronger improvement came from changing the reporting design, not from cosmetic query rewrite alone.

---

## What this project proves

This project proves more than “I can write SQL.”

It shows that I can:

- measure baseline behaviour before making claims
- evaluate whether a first optimisation attempt actually reduces work
- recognise when a query still touches too much data
- move from raw-table reporting to summary-table reporting
- use incremental refresh to avoid full recalculation on every request
- explain performance trade-offs honestly

---

## Engineering takeaway

The main lesson is simple:

- measure first
- do not confuse cleaner SQL with cheaper SQL
- if logical reads do not improve, the real bottleneck may be architectural
- for frequently accessed business reports, **summary tables + incremental refresh** are often a more realistic optimisation strategy than repeatedly aggregating raw transactional tables

This is the part that makes the project credible.

---

## Trade-offs

### Raw transactional report
**Pros**
- simpler
- always reads from the latest source tables
- useful for first validation

**Cons**
- repeated aggregation work
- larger read footprint
- weaker fit for frequent reporting access

### Summary-table report
**Pros**
- lower latency
- smaller read footprint
- better fit for repeated report retrieval

**Cons**
- extra table to maintain
- refresh procedure required
- report freshness depends on refresh cadence

---

## Evidence files

Supporting evidence is stored in:

- `logs/`
- `docs/before-after-results.md`
- `docs/architecture-notes.md`

These logs capture SQL Server timing and I/O results for:
- baseline query
- first-pass rewrite
- summary-table setup
- incremental refresh
- summary-table report

---

## Future improvements

The next logical extensions would be:

- larger seed volumes
- scheduled refresh automation
- ASP.NET Core API endpoints for report retrieval
- cold cache vs warm cache benchmarks
- a lightweight architecture diagram
- a small dashboard only after the database story is fully solid

---

## Why this matters for backend work

A lot of backend work is not about inventing clever code.  
It is about recognising when the system is doing the wrong kind of work at runtime and changing the design so the workload becomes cheaper.

That is what this project demonstrates.
