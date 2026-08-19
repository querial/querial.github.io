-- Destination person dimension (subset of AdventureWorks.Person.Person).
-- Pipeline migration code: 002_create_person

IF OBJECT_ID(N'aw.person', N'U') IS NULL
BEGIN
    CREATE TABLE aw.person
    (
        business_entity_id INT            NOT NULL,
        person_type        NCHAR(2)       NOT NULL,
        first_name         NVARCHAR(50)   NOT NULL,
        last_name          NVARCHAR(50)   NOT NULL,
        modified_date      DATETIME2(3)   NOT NULL,
        loaded_at_utc      DATETIMEOFFSET NOT NULL
            CONSTRAINT df_aw_person_loaded DEFAULT SYSUTCDATETIME(),
        CONSTRAINT pk_aw_person PRIMARY KEY (business_entity_id)
    );
END
