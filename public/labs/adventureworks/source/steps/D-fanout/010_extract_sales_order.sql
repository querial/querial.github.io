-- Scenario D: extract sales orders from SQL Server AdventureWorks (source).
-- Pipeline step code: extract_sales_order
-- Step type: database-query-to-parquet
-- Bind connection: aw-source
-- This is the single structural root for Lab D fan-out.

SELECT
    h.SalesOrderID AS sales_order_id,
    h.OrderDate    AS order_date,
    h.Status       AS status,
    h.CustomerID   AS customer_id,
    h.TotalDue     AS total_due,
    h.ModifiedDate AS modified_date
FROM Sales.SalesOrderHeader AS h;
