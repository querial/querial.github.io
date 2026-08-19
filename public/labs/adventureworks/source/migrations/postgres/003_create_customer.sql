-- Destination customer dimension (subset of AdventureWorks.Sales.Customer).
-- Pipeline migration code: 003_create_customer
-- No FK to aw.person so scenario A can load independently of C.

CREATE TABLE IF NOT EXISTS aw.customer
(
    customer_id    INTEGER        NOT NULL,
    person_id      INTEGER        NULL,
    store_id       INTEGER        NULL,
    territory_id   INTEGER        NULL,
    modified_date  TIMESTAMP      NOT NULL,
    loaded_at_utc  TIMESTAMPTZ    NOT NULL DEFAULT (now() AT TIME ZONE 'utc'),
    CONSTRAINT pk_aw_customer PRIMARY KEY (customer_id)
);
