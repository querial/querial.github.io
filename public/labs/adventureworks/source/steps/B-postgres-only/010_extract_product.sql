-- Scenario B: extract product from SQL Server AdventureWorks (source connection).
-- Pipeline step code: extract_product
-- Step type: database-query-to-parquet (when the designer exposes it)
--            or run in SQL Editor against the AdventureWorks connection to verify.
-- Bind connection: SQL Server AdventureWorks (source).
-- Default database = AdventureWorks, so two-part names are enough.

SELECT
    p.ProductID      AS product_id,
    p.Name           AS name,
    p.ProductNumber  AS product_number,
    p.Color          AS color,
    p.StandardCost   AS standard_cost,
    p.ListPrice      AS list_price,
    p.SellStartDate  AS sell_start_date,
    p.ModifiedDate   AS modified_date
FROM Production.Product AS p;
