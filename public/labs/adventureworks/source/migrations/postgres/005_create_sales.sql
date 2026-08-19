-- Destination sales facts (subset of SalesOrderHeader / SalesOrderDetail).
-- Pipeline migration code: 005_create_sales
-- No FKs to person/customer/product so A/B/C can run independently.

CREATE TABLE IF NOT EXISTS aw.sales_order
(
    sales_order_id INTEGER        NOT NULL,
    order_date     TIMESTAMP      NOT NULL,
    status         SMALLINT       NOT NULL,
    customer_id    INTEGER        NOT NULL,
    total_due      NUMERIC(19, 4) NOT NULL,
    modified_date  TIMESTAMP      NOT NULL,
    loaded_at_utc  TIMESTAMPTZ    NOT NULL DEFAULT (now() AT TIME ZONE 'utc'),
    CONSTRAINT pk_aw_sales_order PRIMARY KEY (sales_order_id)
);

CREATE TABLE IF NOT EXISTS aw.sales_order_line
(
    sales_order_id        INTEGER        NOT NULL,
    sales_order_detail_id INTEGER        NOT NULL,
    product_id            INTEGER        NOT NULL,
    order_qty             SMALLINT       NOT NULL,
    unit_price            NUMERIC(19, 4) NOT NULL,
    line_total            NUMERIC(19, 4) NOT NULL,
    loaded_at_utc         TIMESTAMPTZ    NOT NULL DEFAULT (now() AT TIME ZONE 'utc'),
    CONSTRAINT pk_aw_sales_order_line PRIMARY KEY (sales_order_id, sales_order_detail_id)
);
