-- Insert a new product for testing
INSERT INTO products (name, category, brand, price)
VALUES ('TestPhone Z', 'cellphone', 'TestBrand', 399.99);
-- Update that product
UPDATE products
SET price = 439.99
WHERE name = 'TestPhone X';
-- Delete that product
DELETE FROM products
WHERE name = 'TestPhone X';