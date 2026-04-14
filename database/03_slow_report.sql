USE SqlReportOptimizerDemo;
GO

SET STATISTICS TIME ON;
SET STATISTICS IO ON;
GO
/*
Purpose:
A deliberately basic reporting query before index tuning.
This simulates the first pass of a sales summary report.
*/

SELECT
    b.branch_name,
    sr.rep_name,
    CAST(o.order_date AS DATE) AS report_date,
    COUNT(DISTINCT o.order_id) AS total_orders,
    SUM(oi.quantity) AS total_items,
    SUM(oi.line_total) AS gross_sales
FROM dbo.orders o
INNER JOIN dbo.order_items oi
    ON o.order_id = oi.order_id
INNER JOIN dbo.sales_reps sr
    ON o.sales_rep_id = sr.sales_rep_id
INNER JOIN dbo.branches b
    ON o.branch_id = b.branch_id
WHERE o.order_date >= DATEADD(MONTH, -6, SYSDATETIME())
  AND o.status IN ('Completed', 'Pending')
GROUP BY
    b.branch_name,
    sr.rep_name,
    CAST(o.order_date AS DATE)
ORDER BY
    report_date DESC,
    gross_sales DESC;
GO
