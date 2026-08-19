-- Scenario B: PostgreSQL destination only.
-- Pipeline step code: load_product
-- Step type: staged-database-sql
-- Bind connection: PostgreSQL querial_test destination.
-- Depends on: extract_product (artifact_available).
-- Stage name: product  — columns must match the extract aliases.

INSERT INTO aw.product
(
    product_id,
    name,
    product_number,
    color,
    standard_cost,
    list_price,
    sell_start_date,
    modified_date,
    loaded_at_utc
)
SELECT
    s.product_id,
    s.name,
    s.product_number,
    s.color,
    s.standard_cost,
    s.list_price,
    s.sell_start_date,
    s.modified_date,
    (now() AT TIME ZONE 'utc')
FROM {{ stage.product }} AS s
ON CONFLICT (product_id) DO UPDATE SET
    name            = EXCLUDED.name,
    product_number  = EXCLUDED.product_number,
    color           = EXCLUDED.color,
    standard_cost   = EXCLUDED.standard_cost,
    list_price      = EXCLUDED.list_price,
    sell_start_date = EXCLUDED.sell_start_date,
    modified_date   = EXCLUDED.modified_date,
    loaded_at_utc   = EXCLUDED.loaded_at_utc;
