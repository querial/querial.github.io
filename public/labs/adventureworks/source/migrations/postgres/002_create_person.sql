-- Destination person dimension (subset of AdventureWorks.Person.Person).
-- Pipeline migration code: 002_create_person

CREATE TABLE IF NOT EXISTS aw.person
(
    business_entity_id INTEGER        NOT NULL,
    person_type        CHAR(2)        NOT NULL,
    first_name         VARCHAR(50)    NOT NULL,
    last_name          VARCHAR(50)    NOT NULL,
    modified_date      TIMESTAMP      NOT NULL,
    loaded_at_utc      TIMESTAMPTZ    NOT NULL DEFAULT (now() AT TIME ZONE 'utc'),
    CONSTRAINT pk_aw_person PRIMARY KEY (business_entity_id)
);
