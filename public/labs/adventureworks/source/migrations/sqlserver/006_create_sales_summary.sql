-- Destination rollup produced by DuckDB artifact-sql (Lab E only).
-- Pipeline migration code: 006_create_sales_summary

IF OBJECT_ID(N'aw.sales_order_summary', N'U') IS NULL
BEGIN
    CREATE TABLE aw.sales_order_summary
    (
        sales_order_id      INT            NOT NULL,
        customer_id         INT            NOT NULL,
        order_day           DATE           NOT NULL,
        line_count          INT            NOT NULL,
        total_qty           INT            NOT NULL,
        computed_line_total MONEY          NOT NULL,
        header_total_due    MONEY          NOT NULL,
        loaded_at_utc       DATETIMEOFFSET NOT NULL
            CONSTRAINT df_aw_sales_order_summary_loaded DEFAULT SYSUTCDATETIME(),
        CONSTRAINT pk_aw_sales_order_summary PRIMARY KEY (sales_order_id)
    );
END
