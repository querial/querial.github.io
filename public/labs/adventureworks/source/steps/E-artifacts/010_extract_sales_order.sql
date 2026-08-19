-- Scenario E: extract sales orders from SQL Server AdventureWorks (source).
-- Pipeline step code: extract_sales_order
-- Step type: database-query-to-parquet
-- Bind connection: aw-source
-- Single structural root for Lab E (line extract depends on this for ordering).

SELECT
    h.SalesOrderID AS sales_order_id,
    h.OrderDate    AS order_date,
    h.Status       AS status,
    h.CustomerID   AS customer_id,
    h.TotalDue     AS total_due,
    h.ModifiedDate AS modified_date
FROM Sales.SalesOrderHeader AS h;
