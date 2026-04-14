USE SqlReportOptimizerDemo;
GO

SET STATISTICS TIME ON;
SET STATISTICS IO ON;
GO

/*
Optimized version:
1. Pre-filter orders in a CTE
2. Reduce work before joining large tables
3. Leverage indexes added in 04_indexes.sql
*/


;WITH filtered_orders AS (
    SELECT
        order_id,
        sales_rep_id,
        branch_id,
        CAST(order_date AS DATE) AS report_date
    FROM dbo.orders
    WHERE order_date >= DATEADD(MONTH, -6, SYSDATETIME())
      AND status IN ('Completed', 'Pending')
)
SELECT
    b.branch_name,
    sr.rep_name,
    fo.report_date,
    COUNT_BIG(*) AS order_item_rows,
    COUNT(DISTINCT fo.order_id) AS total_orders,
    SUM(oi.quantity) AS total_items,
    SUM(oi.line_total) AS gross_sales
FROM filtered_orders fo
INNER JOIN dbo.order_items oi
    ON fo.order_id = oi.order_id
INNER JOIN dbo.sales_reps sr
    ON fo.sales_rep_id = sr.sales_rep_id
INNER JOIN dbo.branches b
    ON fo.branch_id = b.branch_id
GROUP BY
    b.branch_name,
    sr.rep_name,
    fo.report_date
ORDER BY
    fo.report_date DESC,
    gross_sales DESC;
GO
