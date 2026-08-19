-- Destination product dimension (subset of AdventureWorks.Production.Product).
-- Pipeline migration code: 004_create_product

CREATE TABLE IF NOT EXISTS aw.product
(
    product_id      INTEGER         NOT NULL,
    name            VARCHAR(50)     NOT NULL,
    product_number  VARCHAR(25)     NOT NULL,
    color           VARCHAR(15)     NULL,
    standard_cost   NUMERIC(19, 4)  NOT NULL,
    list_price      NUMERIC(19, 4)  NOT NULL,
    sell_start_date TIMESTAMP       NOT NULL,
    modified_date   TIMESTAMP       NOT NULL,
    loaded_at_utc   TIMESTAMPTZ     NOT NULL DEFAULT (now() AT TIME ZONE 'utc'),
    CONSTRAINT pk_aw_product PRIMARY KEY (product_id)
);
