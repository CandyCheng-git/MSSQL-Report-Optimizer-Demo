USE SqlReportOptimizerDemo;
GO

/*
Add indexes after observing the baseline query plan.
These are starter indexes for the demo.
*/

CREATE INDEX IX_orders_order_date_status_branch_rep
    ON dbo.orders (order_date, status, branch_id, sales_rep_id)
    INCLUDE (total_amount, customer_id);
GO

CREATE INDEX IX_order_items_order_id
    ON dbo.order_items (order_id)
    INCLUDE (quantity, unit_price, line_total);
GO

CREATE INDEX IX_sales_reps_branch_id
    ON dbo.sales_reps (branch_id);
GO
