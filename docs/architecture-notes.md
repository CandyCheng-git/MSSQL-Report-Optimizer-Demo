# Architecture Notes

## Why this project exists

This project is designed to demonstrate database and reporting judgement, not just SQL syntax.

A lot of weak portfolio projects stop at:

- creating tables
- writing one report query
- adding one or two indexes
- claiming the report is now optimised

That is usually not enough.

This project is structured to show a more realistic path:

1. build the transactional model
2. run the baseline report
3. measure actual work done
4. attempt a first-pass optimisation
5. verify whether the work done really changed
6. if not, move to a reporting-oriented design

## Logical architecture

### 1. Transactional layer

The transactional layer stores operational data:

- `customers`
- `branches`
- `sales_reps`
- `orders`
- `order_items`

This layer is designed for write operations and business activity, not for repeated aggregate reporting.

### 2. Raw reporting layer

The baseline report joins the transactional tables directly.

This is useful for:

- getting the first version working
- validating business logic
- checking what the report should return

This is **not** always the right design for repeated high-frequency reporting.

### 3. Indexed first-pass optimisation

The next step adds indexes and slightly restructures the query.

This is the correct first thing to try because it is low-risk and often enough for moderate workloads.

However, indexing and query cleanup only help when they materially reduce the amount of work SQL Server performs.

### 4. Summary-table reporting layer

When raw-table reporting still touches too much data, the design should change.

That is why this project introduces:

- `daily_sales_summary`
- `dbo.usp_refresh_daily_sales_summary`

The summary table stores pre-aggregated values by:

- report date
- branch
- sales rep

Instead of calculating everything on every report request, the system refreshes a chosen date range and then reads from a reporting-friendly structure.

## Why summary tables matter

Summary tables are useful when:

- reports are read often
- the same aggregates are recalculated repeatedly
- near-real-time is needed, but full recalculation is too expensive
- transactional tables are not the right source for repeated aggregation

This is closer to how many real reporting systems work.

## Why incremental refresh matters

A common reporting mistake is rebuilding all history every time.

Incremental refresh avoids that by processing only:

- new data
- changed data
- a selected recent date range

That reduces unnecessary work and supports lower latency reporting.

## Trade-offs

### Transactional-table reporting
**Pros**
- simple to understand
- no extra reporting table to maintain
- always reads the latest raw data

**Cons**
- repeated aggregation cost
- slower under larger data volumes
- can put more pressure on operational tables

### Summary-table reporting
**Pros**
- faster report retrieval
- more stable performance pattern
- better fit for repeated aggregate queries

**Cons**
- extra storage
- refresh logic must be maintained
- freshness depends on refresh strategy

## Benchmarking philosophy

This project should be judged with evidence, not assumptions.

Use:

- `SET STATISTICS TIME ON`
- `SET STATISTICS IO ON`
- execution plan screenshots

Do not rely only on:
- query completion timestamp
- one-off wall-clock measurement
- gut feeling

## Current interpretation

The current benchmark shows that the first-pass rewrite improved timing only slightly and did not reduce logical reads.

That means the query still performs almost the same underlying work.

That is not a failure. It is the proof that the next architectural step is justified.

## What this project proves

At its best, this project shows:

- SQL Server schema design
- indexing awareness
- reporting query analysis
- evidence-based optimisation
- willingness to change approach when the first idea is not enough
- understanding of summary-table and incremental-refresh design
