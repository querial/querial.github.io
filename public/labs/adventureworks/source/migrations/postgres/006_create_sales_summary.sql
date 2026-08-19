-- Destination rollup produced by DuckDB artifact-sql (Lab E only).
-- Pipeline migration code: 006_create_sales_summary

CREATE TABLE IF NOT EXISTS aw.sales_order_summary
(
    sales_order_id      INTEGER        NOT NULL,
    customer_id         INTEGER        NOT NULL,
    order_day           DATE           NOT NULL,
    line_count          INTEGER        NOT NULL,
    total_qty           INTEGER        NOT NULL,
    computed_line_total NUMERIC(19, 4) NOT NULL,
    header_total_due    NUMERIC(19, 4) NOT NULL,
    loaded_at_utc       TIMESTAMPTZ    NOT NULL DEFAULT (now() AT TIME ZONE 'utc'),
    CONSTRAINT pk_aw_sales_order_summary PRIMARY KEY (sales_order_id)
);
