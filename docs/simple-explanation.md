# Simple Explanation

## What is this project?

This project is about making a business report faster.

In many systems, reports are built from **transactional tables** such as:

- `orders`
- `order_items`
- `sales_reps`
- `branches`

At first, this seems fine.  
But as the data grows, the report may become slower because SQL Server has to read and calculate too much data every time the report is opened.

So the project asks:

> How should we improve the report properly?

---

## The three approaches in this project

### 1. Baseline report  
**English term:** `baseline query` / `raw transactional reporting`  
**繁中:** 基準查詢 / 直接查原始交易表

This is the most direct version.

The report reads from the raw transactional tables and calculates everything at query time.

That means every time the report runs, SQL Server has to:
- join tables
- filter rows
- group data
- calculate totals again

### Easy way to think about it
It is like counting all receipts from scratch every time the manager asks for a daily sales summary.

---

### 2. First-pass optimisation  
**English term:** `index tuning` / `query restructuring`  
**繁中:** 索引優化 / 查詢重組

The next idea is to improve the SQL query a bit:

- add indexes
- rewrite the query in a cleaner way
- filter earlier

This is a reasonable first step.

But the benchmark showed something important:

- the timing improved only a little
- the **logical reads** did not decrease

**English term:** `logical reads`  
**繁中:** 邏輯讀取

That means SQL Server still had to touch almost the same amount of data.

### Important lesson
Cleaner SQL is not always cheaper SQL.

---

### 3. Summary-table reporting  
**English term:** `summary table` / `pre-aggregation`  
**繁中:** 彙總表 / 預先彙總

This is where the stronger improvement came from.

Instead of recalculating the full report from raw tables every time, the project creates a table called:

- `daily_sales_summary`

This table stores report-ready results such as:

- report date
- branch
- sales rep
- total orders
- total items
- gross sales

Now the report can read from this smaller reporting table instead of rebuilding everything from the original transactional data each time.

### Easy way to think about it
Instead of counting all receipts every time, you prepare a daily summary sheet in advance and read that sheet when someone asks for the report.

---

## What is incremental refresh?

**English term:** `incremental refresh`  
**繁中:** 增量更新

Incremental refresh means:

- update only the required date range
- do not rebuild the full history every time

For example:

If today is April 14, you may only need to refresh recent days or a chosen date range, instead of recalculating the whole reporting history again.

This reduces unnecessary work and helps lower latency.

---

## What did the benchmark show?

### Baseline report
- CPU time: **219 ms**
- elapsed time: **287 ms**

### First-pass optimized report
- CPU time: **203 ms**
- elapsed time: **277 ms**

The improvement was small.

### Summary-table report
- CPU time: **15 ms**
- elapsed time: **103 ms**

This is the first result that shows a meaningful improvement.

---

## Why did the summary-table design work better?

Because it changed the kind of work SQL Server had to do.

The raw report asked SQL Server to:
- read larger transactional tables
- perform aggregation during the report query

The summary-table report asked SQL Server to:
- read a much smaller pre-aggregated table
- avoid repeating the same heavy calculations at runtime

That is why the improvement was more meaningful.

---

## Simple example

Imagine a store manager wants to know:

- how many orders were made today
- how many items were sold
- how much revenue each sales rep generated

### Method 1: raw transactional reporting
Every time the manager asks, you reopen every receipt and count everything again.

This works, but it becomes slow.

### Method 2: summary-table reporting
At the end of the day, you prepare one summary sheet with the totals.

When the manager asks, you read the summary sheet instead of recounting every receipt.

This is faster and more practical.

### Method 3: incremental refresh
The next day, you do not rewrite all past summary sheets.  
You only update today’s numbers or the date range that changed.

That is the same idea as incremental refresh in this project.

---

## What this project teaches

This project teaches an important backend lesson:

- first measure the query
- do not assume a rewrite is enough
- check whether SQL Server is actually doing less work
- if logical reads do not improve, the real solution may be architectural
- summary tables and incremental refresh are often more realistic for frequently used business reports

---

## Key terms to remember

- **transactional tables** = 原始交易表
- **baseline query** = 基準查詢
- **index tuning** = 索引優化
- **query restructuring** = 查詢重組
- **logical reads** = 邏輯讀取
- **summary table** = 彙總表
- **pre-aggregation** = 預先彙總
- **incremental refresh** = 增量更新
- **elapsed time** = 經過時間
- **CPU time** = CPU 時間

---

## Final simple summary

If a report is slow, do not assume that rewriting the SQL is enough.

Measure the query first.

If SQL Server still reads almost the same amount of data, then the real bottleneck may be the reporting design.

In that case, a **summary table** and **incremental refresh** can be a better solution than repeatedly recalculating the report from raw transactional tables.
