USE SqlReportOptimizerDemo;
GO

IF OBJECT_ID('dbo.order_items', 'U') IS NOT NULL DROP TABLE dbo.order_items;
IF OBJECT_ID('dbo.orders', 'U') IS NOT NULL DROP TABLE dbo.orders;
IF OBJECT_ID('dbo.sales_reps', 'U') IS NOT NULL DROP TABLE dbo.sales_reps;
IF OBJECT_ID('dbo.branches', 'U') IS NOT NULL DROP TABLE dbo.branches;
IF OBJECT_ID('dbo.customers', 'U') IS NOT NULL DROP TABLE dbo.customers;
GO

CREATE TABLE dbo.customers (
    customer_id INT IDENTITY(1,1) PRIMARY KEY,
    customer_name NVARCHAR(100) NOT NULL,
    email NVARCHAR(255) NULL,
    created_at DATETIME2 NOT NULL DEFAULT SYSDATETIME()
);
GO

CREATE TABLE dbo.branches (
    branch_id INT IDENTITY(1,1) PRIMARY KEY,
    branch_name NVARCHAR(100) NOT NULL,
    city NVARCHAR(100) NULL,
    created_at DATETIME2 NOT NULL DEFAULT SYSDATETIME()
);
GO

CREATE TABLE dbo.sales_reps (
    sales_rep_id INT IDENTITY(1,1) PRIMARY KEY,
    rep_name NVARCHAR(100) NOT NULL,
    email NVARCHAR(255) NULL,
    branch_id INT NOT NULL,
    created_at DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT FK_sales_reps_branch
        FOREIGN KEY (branch_id) REFERENCES dbo.branches(branch_id)
);
GO

CREATE TABLE dbo.orders (
    order_id BIGINT IDENTITY(1,1) PRIMARY KEY,
    customer_id INT NOT NULL,
    sales_rep_id INT NOT NULL,
    branch_id INT NOT NULL,
    order_date DATETIME2 NOT NULL,
    status NVARCHAR(30) NOT NULL,
    total_amount DECIMAL(18,2) NOT NULL,
    created_at DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT FK_orders_customer
        FOREIGN KEY (customer_id) REFERENCES dbo.customers(customer_id),
    CONSTRAINT FK_orders_sales_rep
        FOREIGN KEY (sales_rep_id) REFERENCES dbo.sales_reps(sales_rep_id),
    CONSTRAINT FK_orders_branch
        FOREIGN KEY (branch_id) REFERENCES dbo.branches(branch_id)
);
GO

CREATE TABLE dbo.order_items (
    order_item_id BIGINT IDENTITY(1,1) PRIMARY KEY,
    order_id BIGINT NOT NULL,
    product_name NVARCHAR(200) NOT NULL,
    quantity INT NOT NULL,
    unit_price DECIMAL(18,2) NOT NULL,
    line_total AS (quantity * unit_price) PERSISTED,
    created_at DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT FK_order_items_order
        FOREIGN KEY (order_id) REFERENCES dbo.orders(order_id)
);
GO
