
DROP EXTENSION IF EXISTS autoaudit CASCADE;
CREATE EXTENSION autoaudit;

SELECT table_schema, table_name
FROM information_schema.tables
WHERE table_schema = 'autoaudit';

select * from autoaudit.audit_log --see the autoaudit log's table

--testing the basic audit_trigger
--1.Creating the trigger
DROP TRIGGER IF EXISTS audit_customers ON customers;
CREATE TRIGGER audit_customers
AFTER INSERT OR UPDATE OR DELETE ON customers
FOR EACH ROW
EXECUTE FUNCTION autoaudit.audit_trigger();
--2.Doing some operations to test the trigger
-- Insert a new customer
INSERT INTO customers (full_name, email, phone, city)
VALUES ('Test User', 'test@example.com', '123-456-7890', 'London');
-- Update
UPDATE customers SET city = 'Paris'
WHERE full_name = 'Alice Johnson';
-- Delete
DELETE FROM order_items 
WHERE order_id IN (SELECT order_id FROM orders WHERE customer_id = 2);
DELETE FROM orders WHERE customer_id = 2;
DELETE FROM customers WHERE full_name = 'Bob Smith';
--3.Seeing the changes in the audit log
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
--Permitir a Estudiante conectarse a la base
GRANT CONNECT ON DATABASE storedb TO "Estudiante";
GRANT USAGE ON SCHEMA public TO "Estudiante";
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO "Estudiante";
--
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
             seq.sequence_schema, seq.sequence_name, 'Estudiante'
        );
    END LOOP;
END;
$$;
GRANT USAGE ON SCHEMA autoaudit TO "Estudiante";
GRANT INSERT ON autoaudit.audit_log TO "Estudiante";
GRANT USAGE, SELECT, UPDATE ON SEQUENCE autoaudit.audit_log_event_id_seq TO "Estudiante";
--See the changes "Estudiante" made
select * from autoaudit.audit_log