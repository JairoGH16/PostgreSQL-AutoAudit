--DROP EXTENSION IF EXISTS autoaudit CASCADE;
CREATE EXTENSION autoaudit;

SELECT table_schema, table_name
FROM information_schema.tables
WHERE table_schema = 'autoaudit';

select * from autoaudit.audit_log --see the autoaudit log's table

--After adding the functions to add the trigger automatically to new tables
--and previously created tables, we're going to test it!
--1. Creating a new table and doing an operation on it
CREATE TABLE test_table (
    id serial PRIMARY KEY,
    description text
);
INSERT INTO test_table (description) VALUES ('hello world');
select * from autoaudit.audit_log --see the change on autoaudit log's table!
--2. Making changes on a previous table
-- Insert a new product for testing
INSERT INTO products (name, category, brand, price)
VALUES ('TestPhone X', 'cellphone', 'TestBrand', 499.99);
-- Update that product
UPDATE products
SET price = 459.99
WHERE name = 'TestPhone X';
-- Delete that product
DELETE FROM products
WHERE name = 'TestPhone X';
select * from autoaudit.audit_log --again, see the change on autoaudit log's table!

--To test from another user
--Grant connection and usage of public schema to Worker
GRANT CONNECT ON DATABASE storedb TO "Worker";
GRANT USAGE ON SCHEMA public TO "Worker";
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO "Worker";
DO $$
DECLARE
    seq RECORD;
BEGIN
    FOR seq IN
        SELECT sequence_schema, sequence_name
        FROM information_schema.sequences
        WHERE sequence_schema = 'public'
    LOOP
        EXECUTE format(
            'GRANT USAGE, SELECT, UPDATE ON SEQUENCE %I.%I TO "%s";',
             seq.sequence_schema, seq.sequence_name, 'Worker'
        );
    END LOOP;
END;
$$;
--See the changes "Worker" made
select * from autoaudit.audit_log