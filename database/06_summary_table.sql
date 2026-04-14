USE SqlReportOptimizerDemo;
SET STATISTICS TIME ON;
SET STATISTICS IO ON;
GO

/*
Purpose:
Create a daily summary table so reports can read pre-aggregated data
instead of scanning raw transactional tables every time.
*/

IF OBJECT_ID('dbo.daily_sales_summary', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.daily_sales_summary (
        summary_id BIGINT IDENTITY(1,1) PRIMARY KEY,
        report_date DATE NOT NULL,
        branch_id INT NOT NULL,
        sales_rep_id INT NOT NULL,
        total_orders INT NOT NULL,
        total_items INT NOT NULL,
        gross_sales DECIMAL(18,2) NOT NULL,
        refreshed_at DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
        CONSTRAINT FK_daily_sales_summary_branch
            FOREIGN KEY (branch_id) REFERENCES dbo.branches(branch_id),
        CONSTRAINT FK_daily_sales_summary_sales_rep
            FOREIGN KEY (sales_rep_id) REFERENCES dbo.sales_reps(sales_rep_id),
        CONSTRAINT UQ_daily_sales_summary
            UNIQUE (report_date, branch_id, sales_rep_id)
    );
END
GO

/*
Helpful index for date-range report retrieval.
*/
IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IX_daily_sales_summary_report_date'
      AND object_id = OBJECT_ID('dbo.daily_sales_summary')
)
BEGIN
    CREATE INDEX IX_daily_sales_summary_report_date
        ON dbo.daily_sales_summary (report_date, branch_id, sales_rep_id)
        INCLUDE (total_orders, total_items, gross_sales, refreshed_at);
END
GO
