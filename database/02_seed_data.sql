USE SqlReportOptimizerDemo;
GO

SET NOCOUNT ON;

-- branches
INSERT INTO dbo.branches (branch_name, city)
VALUES
('Melbourne Central', 'Melbourne'),
('Box Hill', 'Melbourne'),
('Sydney CBD', 'Sydney'),
('Parramatta', 'Sydney'),
('Brisbane City', 'Brisbane');
GO

-- customers
;WITH n AS (
    SELECT TOP (1000)
        ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS num
    FROM sys.all_objects a
    CROSS JOIN sys.all_objects b
)
INSERT INTO dbo.customers (customer_name, email)
SELECT
    CONCAT('Customer ', num),
    CONCAT('customer', num, '@example.com')
FROM n;
GO

-- sales reps
INSERT INTO dbo.sales_reps (rep_name, email, branch_id)
VALUES
('Alice Wong', 'alice.wong@example.com', 1),
('Ben Chan', 'ben.chan@example.com', 1),
('Chris Lee', 'chris.lee@example.com', 2),
('Daisy Ho', 'daisy.ho@example.com', 2),
('Ethan Ng', 'ethan.ng@example.com', 3),
('Fiona Lam', 'fiona.lam@example.com', 4),
('Gary Yip', 'gary.yip@example.com', 5),
('Helen Tse', 'helen.tse@example.com', 3);
GO

-- orders
;WITH n AS (
    SELECT TOP (20000)
        ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS num
    FROM sys.all_objects a
    CROSS JOIN sys.all_objects b
)
INSERT INTO dbo.orders (customer_id, sales_rep_id, branch_id, order_date, status, total_amount)
SELECT
    ((num - 1) % 1000) + 1 AS customer_id,
    ((num - 1) % 8) + 1 AS sales_rep_id,
    ((num - 1) % 5) + 1 AS branch_id,
    DATEADD(DAY, -(num % 365), SYSDATETIME()) AS order_date,
    CASE 
        WHEN num % 10 = 0 THEN 'Cancelled'
        WHEN num % 5 = 0 THEN 'Pending'
        ELSE 'Completed'
    END AS status,
    CAST((20 + (num % 500)) * 1.25 AS DECIMAL(18,2)) AS total_amount
FROM n;
GO

-- order items: 3 items per order
INSERT INTO dbo.order_items (order_id, product_name, quantity, unit_price)
SELECT
    o.order_id,
    CONCAT('Product ', v.item_no),
    (ABS(CHECKSUM(NEWID())) % 5) + 1 AS quantity,
    CAST((ABS(CHECKSUM(NEWID())) % 200) + 10 AS DECIMAL(18,2)) AS unit_price
FROM dbo.orders o
CROSS JOIN (VALUES (1), (2), (3)) v(item_no);
GO
