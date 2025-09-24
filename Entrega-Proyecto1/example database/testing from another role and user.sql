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

--Showing this user can't modify the autoaudit log
-- Insert log into audit table
    INSERT INTO autoaudit.audit_log (
        operation_type,
        table_name,
        executed_by,
        client_ip,
        old_data,
        new_data
    )
    VALUES (
       'INSERT',    -- INSERT, UPDATE, DELETE
       'products',      -- table affected
        current_user,       -- user executing
        '127.0.0.1'::inet, -- client IP
        NULL,
        NULL
    );