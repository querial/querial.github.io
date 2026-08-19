-- Scenario A: SQL Server destination only.
-- Pipeline step code: load_customer
-- Step type: sql_command
-- Bind connection: SQL Server Querial destination.
-- Depends on: load_person (optional; no FK, but person rows are useful for joins later).
--
-- Replace [AdventureWorks] if your catalog name differs.

MERGE aw.customer AS t
USING
(
    SELECT
        c.CustomerID   AS customer_id,
        c.PersonID     AS person_id,
        c.StoreID      AS store_id,
        c.TerritoryID  AS territory_id,
        c.ModifiedDate AS modified_date
    FROM AdventureWorks.Sales.Customer AS c
) AS s
ON t.customer_id = s.customer_id
WHEN MATCHED AND t.modified_date <> s.modified_date THEN
    UPDATE SET
        person_id     = s.person_id,
        store_id      = s.store_id,
        territory_id  = s.territory_id,
        modified_date = s.modified_date,
        loaded_at_utc = SYSUTCDATETIME()
WHEN NOT MATCHED THEN
    INSERT (customer_id, person_id, store_id, territory_id, modified_date, loaded_at_utc)
    VALUES (s.customer_id, s.person_id, s.store_id, s.territory_id, s.modified_date, SYSUTCDATETIME());
