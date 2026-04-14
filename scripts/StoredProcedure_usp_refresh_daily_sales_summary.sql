USE SqlReportOptimizerDemo;
GO

SET STATISTICS TIME ON;
SET STATISTICS IO ON;
GO

EXEC dbo.usp_refresh_daily_sales_summary
    @start_date = '2025-10-01',
    @end_date   = '2026-04-14';