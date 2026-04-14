USE SqlReportOptimizerDemo;
GO

SET STATISTICS TIME ON;
SET STATISTICS IO ON;
GO

SELECT
    b.branch_name,
    sr.rep_name,
    dss.report_date,
    dss.total_orders,
    dss.total_items,
    dss.gross_sales,
    dss.refreshed_at
FROM dbo.daily_sales_summary dss
INNER JOIN dbo.branches b
    ON dss.branch_id = b.branch_id
INNER JOIN dbo.sales_reps sr
    ON dss.sales_rep_id = sr.sales_rep_id
WHERE dss.report_date >= DATEADD(MONTH, -6, CAST(SYSDATETIME() AS DATE))
ORDER BY dss.report_date DESC, dss.gross_sales DESC;
GO