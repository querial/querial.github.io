-- Scenario A: SQL Server destination only.
-- Pipeline step code: load_person
-- Step type: sql_command
-- Bind connection: SQL Server Querial destination (same instance as AdventureWorks).
--
-- Replace [AdventureWorks] if your catalog is AdventureWorks2019 / AdventureWorks2022.
-- Full AdventureWorks OLTP is required (not AdventureWorksLT).

MERGE aw.person AS t
USING
(
    SELECT
        p.BusinessEntityID AS business_entity_id,
        p.PersonType       AS person_type,
        p.FirstName        AS first_name,
        p.LastName         AS last_name,
        p.ModifiedDate     AS modified_date
    FROM AdventureWorks.Person.Person AS p
) AS s
ON t.business_entity_id = s.business_entity_id
WHEN MATCHED AND t.modified_date <> s.modified_date THEN
    UPDATE SET
        person_type   = s.person_type,
        first_name    = s.first_name,
        last_name     = s.last_name,
        modified_date = s.modified_date,
        loaded_at_utc = SYSUTCDATETIME()
WHEN NOT MATCHED THEN
    INSERT (business_entity_id, person_type, first_name, last_name, modified_date, loaded_at_utc)
    VALUES (s.business_entity_id, s.person_type, s.first_name, s.last_name, s.modified_date, SYSUTCDATETIME());
