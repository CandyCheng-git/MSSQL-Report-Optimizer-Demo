USE SqlReportOptimizerDemo;
GO

SET STATISTICS TIME ON;
SET STATISTICS IO ON;
GO

/*
Purpose:
Incrementally refresh the summary table for a selected date range.
This avoids rebuilding the entire reporting history every time.
*/

CREATE OR ALTER PROCEDURE dbo.usp_refresh_daily_sales_summary
    @start_date DATE,
    @end_date   DATE
AS
BEGIN
    SET NOCOUNT ON;

    IF @start_date IS NULL OR @end_date IS NULL
    BEGIN
        THROW 50001, 'start_date and end_date are required.', 1;
    END;

    IF @start_date > @end_date
    BEGIN
        THROW 50002, 'start_date cannot be later than end_date.', 1;
    END;

    ;WITH source_data AS (
        SELECT
            CAST(o.order_date AS DATE) AS report_date,
            o.branch_id,
            o.sales_rep_id,
            COUNT(DISTINCT o.order_id) AS total_orders,
            SUM(oi.quantity) AS total_items,
            SUM(oi.line_total) AS gross_sales
        FROM dbo.orders o
        INNER JOIN dbo.order_items oi
            ON o.order_id = oi.order_id
        WHERE CAST(o.order_date AS DATE) BETWEEN @start_date AND @end_date
          AND o.status IN ('Completed', 'Pending')
        GROUP BY
            CAST(o.order_date AS DATE),
            o.branch_id,
            o.sales_rep_id
    )
    MERGE dbo.daily_sales_summary AS target
    USING source_data AS source
       ON target.report_date = source.report_date
      AND target.branch_id = source.branch_id
      AND target.sales_rep_id = source.sales_rep_id
    WHEN MATCHED THEN
        UPDATE SET
            total_orders = source.total_orders,
            total_items = source.total_items,
            gross_sales = source.gross_sales,
            refreshed_at = SYSDATETIME()
    WHEN NOT MATCHED BY TARGET THEN
        INSERT (
            report_date,
            branch_id,
            sales_rep_id,
            total_orders,
            total_items,
            gross_sales,
            refreshed_at
        )
        VALUES (
            source.report_date,
            source.branch_id,
            source.sales_rep_id,
            source.total_orders,
            source.total_items,
            source.gross_sales,
            SYSDATETIME()
        )
    WHEN NOT MATCHED BY SOURCE
         AND target.report_date BETWEEN @start_date AND @end_date
    THEN DELETE;
END;
GO

/*
Example usage:
EXEC dbo.usp_refresh_daily_sales_summary
    @start_date = '2025-10-01',
    @end_date   = '2026-04-14';
GO

Summary-table report query example:
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
*/
