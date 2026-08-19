-- Destination product dimension (subset of AdventureWorks.Production.Product).
-- Pipeline migration code: 004_create_product

IF OBJECT_ID(N'aw.product', N'U') IS NULL
BEGIN
    CREATE TABLE aw.product
    (
        product_id      INT             NOT NULL,
        name            NVARCHAR(50)    NOT NULL,
        product_number  NVARCHAR(25)    NOT NULL,
        color           NVARCHAR(15)    NULL,
        standard_cost   MONEY           NOT NULL,
        list_price      MONEY           NOT NULL,
        sell_start_date DATETIME2(3)    NOT NULL,
        modified_date   DATETIME2(3)    NOT NULL,
        loaded_at_utc   DATETIMEOFFSET  NOT NULL
            CONSTRAINT df_aw_product_loaded DEFAULT SYSUTCDATETIME(),
        CONSTRAINT pk_aw_product PRIMARY KEY (product_id)
    );
END
