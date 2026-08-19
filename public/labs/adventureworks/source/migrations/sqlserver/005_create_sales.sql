-- Destination sales facts (subset of SalesOrderHeader / SalesOrderDetail).
-- Pipeline migration code: 005_create_sales
-- No FKs to person/customer/product so A/B/C can run independently.

IF OBJECT_ID(N'aw.sales_order', N'U') IS NULL
BEGIN
    CREATE TABLE aw.sales_order
    (
        sales_order_id INT            NOT NULL,
        order_date     DATETIME2(3)   NOT NULL,
        status         TINYINT        NOT NULL,
        customer_id    INT            NOT NULL,
        total_due      MONEY          NOT NULL,
        modified_date  DATETIME2(3)   NOT NULL,
        loaded_at_utc  DATETIMEOFFSET NOT NULL
            CONSTRAINT df_aw_sales_order_loaded DEFAULT SYSUTCDATETIME(),
        CONSTRAINT pk_aw_sales_order PRIMARY KEY (sales_order_id)
    );
END

IF OBJECT_ID(N'aw.sales_order_line', N'U') IS NULL
BEGIN
    CREATE TABLE aw.sales_order_line
    (
        sales_order_id        INT            NOT NULL,
        sales_order_detail_id INT            NOT NULL,
        product_id            INT            NOT NULL,
        order_qty             SMALLINT       NOT NULL,
        unit_price            MONEY          NOT NULL,
        line_total            MONEY          NOT NULL,
        loaded_at_utc         DATETIMEOFFSET NOT NULL
            CONSTRAINT df_aw_sales_line_loaded DEFAULT SYSUTCDATETIME(),
        CONSTRAINT pk_aw_sales_order_line PRIMARY KEY (sales_order_id, sales_order_detail_id)
    );
END
