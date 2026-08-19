-- AW SQL Server warehouse: schema for destination tables.
-- Pipeline migration code: 001_create_schema
-- Apply via Querial to the SQL Server Querial destination connection (not AdventureWorks).

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'aw')
    EXEC(N'CREATE SCHEMA aw');
