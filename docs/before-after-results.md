# Before vs After Results

## Scope of comparison

This document compares three reporting approaches in the project:

1. `03_slow_report.sql` - baseline report over raw transactional tables
2. `05_optimized_report.sql` - first-pass optimisation using indexes and light query restructuring
3. `08_summary_report.sql` - summary-table report over pre-aggregated data

It also records the reasoning behind moving from query-level tuning to a reporting-oriented design.

---

## 1. Baseline query

**File:** `database/03_slow_report.sql`

### Measured result
- CPU time: **219 ms**
- Elapsed time: **287 ms**

### Logical reads
- `order_items`: **389**
- `orders`: **189**
- `sales_reps`: **2**
- `branches`: **2**

### Rows returned
- **1308**

### Interpretation
The baseline query is already reasonably fast on the current sample dataset, but it still calculates the report directly from raw transactional tables on every execution.

That means the aggregation cost remains in the runtime path.

---

## 2. First-pass optimized query

**File:** `database/05_optimized_report.sql`

### Measured result
- CPU time: **203 ms**
- Elapsed time: **277 ms**

### Logical reads
- `order_items`: **389**
- `orders`: **189**
- `sales_reps`: **2**
- `branches`: **2**

### Rows returned
- **1308**

### Interpretation
The first-pass rewrite made the query structure cleaner and improved timing slightly, but it did **not** reduce logical reads.

That means SQL Server still touched almost the same amount of data and performed almost the same underlying work.

---

## 3. First comparison summary

### Timing change
- CPU improved by **16 ms**
- Elapsed time improved by **10 ms**

### I/O change
- No reduction in logical reads

### Engineering conclusion
This was **not** a strong optimisation result.

It was still useful, because it proved that light query restructuring and starter indexes alone did not materially reduce the amount of work performed by the report.

That result justified moving to a stronger design pattern instead of pretending that a small runtime change was enough.

---

## 4. Summary-table layer

### Setup status
- `06_summary_table.sql` executed successfully
- `07_incremental_refresh.sql` executed successfully
- `daily_sales_summary` row count after refresh: **1408**

### Why this layer was added
The first-pass optimisation did not materially reduce I/O, so the next step was to change the reporting design:

- pre-aggregate report data into `daily_sales_summary`
- refresh only the required date range
- read from the summary layer instead of recalculating from raw transaction tables every time

This is closer to how real business reporting systems reduce latency.

---

## 5. Summary-table report

**File:** `database/08_summary_report.sql`

### Measured result
- CPU time: **15 ms**
- Elapsed time: **103 ms**

### Logical reads
- `daily_sales_summary`: **11**
- `branches`: **2**
- `sales_reps`: **2**

### Rows returned
- **1316**

### Interpretation
The summary-table report reads pre-aggregated data rather than recalculating the report from raw transactional tables at query time.

This produced a meaningful reduction in both elapsed time and logical reads.

---

## 6. Raw report vs summary-table report

### Baseline raw report
- CPU: **219 ms**
- Elapsed: **287 ms**
- Main reads:
  - `order_items`: **389**
  - `orders`: **189**

### Summary-table report
- CPU: **15 ms**
- Elapsed: **103 ms**
- Main reads:
  - `daily_sales_summary`: **11**

### Improvement
Compared with the baseline raw report:

- CPU time reduced by **204 ms**
- Elapsed time reduced by **184 ms**
- Raw-table reads on `orders` and `order_items` were replaced by a much smaller read footprint on `daily_sales_summary`

### What this proves
This is the first result in the project that shows a **material reporting improvement**.

The stronger gain came **not** from cosmetic query cleanup, but from changing the reporting design.

---

## 7. Engineering takeaway

The most important lesson from this project is:

- measure first
- do not assume a rewritten query is cheaper just because it looks cleaner
- when logical reads do not improve, move up a level and redesign the reporting path
- summary tables and incremental refresh are often a more realistic optimisation strategy for frequently accessed business reports

This is stronger engineering judgement than forcing a fake “query optimization success” story.

---

## 8. Trade-off discussion

### Benefits of the summary-table approach
- faster report retrieval
- lower runtime aggregation cost
- smaller read footprint
- better fit for repeated business reporting queries

### Costs of the summary-table approach
- extra storage
- refresh procedure must be maintained
- freshness depends on refresh cadence
- more moving parts than querying transactional tables directly

---

## 9. Honest project status

This project now shows a credible optimisation path:

1. baseline measurement
2. first-pass query/index tuning
3. evidence that the improvement was limited
4. introduction of summary-table and incremental-refresh design
5. measurable reporting improvement using the summary layer

That is a more believable portfolio story than claiming that a minor SQL rewrite solved a reporting performance problem.

---

## 10. Suggested next extension

To make the project even stronger later, add:

- larger seed volumes
- benchmark notes for cold cache vs warm cache
- a scheduled refresh job
- an ASP.NET Core API endpoint for report retrieval
- a short architecture diagram in the README or docs
