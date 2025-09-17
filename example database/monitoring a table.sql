
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