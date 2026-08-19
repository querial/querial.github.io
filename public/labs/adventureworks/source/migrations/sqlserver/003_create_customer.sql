-- Destination customer dimension (subset of AdventureWorks.Sales.Customer).
-- Pipeline migration code: 003_create_customer
-- No FK to aw.person so scenario A can load independently of C.

IF OBJECT_ID(N'aw.customer', N'U') IS NULL
BEGIN
    CREATE TABLE aw.customer
    (
        customer_id    INT            NOT NULL,
        person_id      INT            NULL,
        store_id       INT            NULL,
        territory_id   INT            NULL,
        modified_date  DATETIME2(3)   NOT NULL,
        loaded_at_utc  DATETIMEOFFSET NOT NULL
            CONSTRAINT df_aw_customer_loaded DEFAULT SYSUTCDATETIME(),
        CONSTRAINT pk_aw_customer PRIMARY KEY (customer_id)
    );
END
