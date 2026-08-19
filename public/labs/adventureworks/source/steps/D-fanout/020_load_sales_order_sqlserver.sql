-- Scenario D: SQL Server destination via same-instance 3-part names.
-- Pipeline step code: load_sales_order_sqlserver
-- Step type: sql_command
-- Bind connection: aw-sql-dest
-- Depends on: extract_sales_order (succeeded) — ordering only; this path re-queries source.
-- Replace [AdventureWorks] if your catalog name differs.

MERGE aw.sales_order AS t
USING
(
    SELECT
        h.SalesOrderID AS sales_order_id,
        h.OrderDate    AS order_date,
        h.Status       AS status,
        h.CustomerID   AS customer_id,
        h.TotalDue     AS total_due,
        h.ModifiedDate AS modified_date
    FROM AdventureWorks.Sales.SalesOrderHeader AS h
) AS s
ON t.sales_order_id = s.sales_order_id
WHEN MATCHED AND t.modified_date <> s.modified_date THEN
    UPDATE SET
        order_date    = s.order_date,
        status        = s.status,
        customer_id   = s.customer_id,
        total_due     = s.total_due,
        modified_date = s.modified_date,
        loaded_at_utc = SYSUTCDATETIME()
WHEN NOT MATCHED THEN
    INSERT (sales_order_id, order_date, status, customer_id, total_due, modified_date, loaded_at_utc)
    VALUES (s.sales_order_id, s.order_date, s.status, s.customer_id, s.total_due, s.modified_date, SYSUTCDATETIME());
