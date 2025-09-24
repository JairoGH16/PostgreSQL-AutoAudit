-- =====================================
-- Create database and connect
-- =====================================
--DROP DATABASE IF EXISTS storedb;
CREATE DATABASE storedb;

-- =====================================
-- Create tables
-- =====================================

-- Customers table
CREATE TABLE customers (
    customer_id BIGSERIAL PRIMARY KEY,
    full_name   TEXT NOT NULL,
    email       TEXT UNIQUE NOT NULL,
    phone       TEXT,
    city        TEXT
);

-- Products table
CREATE TABLE products (
    product_id  BIGSERIAL PRIMARY KEY,
    name        TEXT NOT NULL,
    category    TEXT NOT NULL,   -- laptop, console, cellphone
    brand       TEXT NOT NULL,
    price       NUMERIC(10,2) NOT NULL
);

-- Orders table
CREATE TABLE orders (
    order_id    BIGSERIAL PRIMARY KEY,
    customer_id BIGINT REFERENCES customers(customer_id),
    order_date  TIMESTAMPTZ DEFAULT now(),
    status      TEXT DEFAULT 'PENDING'
);

-- Order items table
CREATE TABLE order_items (
    item_id     BIGSERIAL PRIMARY KEY,
    order_id    BIGINT REFERENCES orders(order_id),
    product_id  BIGINT REFERENCES products(product_id),
    quantity    INT NOT NULL,
    unit_price  NUMERIC(10,2) NOT NULL
);

-- =====================================
-- Insert 10 customers
-- =====================================
INSERT INTO customers (full_name, email, phone, city) VALUES
('Alice Johnson', 'alice@example.com', '888-111-2222', 'New York'),
('Bob Smith', 'bob@example.com', '888-222-3333', 'Los Angeles'),
('Charlie Davis', 'charlie@example.com', '888-333-4444', 'Chicago'),
('Diana Evans', 'diana@example.com', '888-444-5555', 'Houston'),
('Ethan Brown', 'ethan@example.com', '888-555-6666', 'Phoenix'),
('Fiona Wilson', 'fiona@example.com', '888-666-7777', 'San Diego'),
('George Miller', 'george@example.com', '888-777-8888', 'San Jose'),
('Hannah Martin', 'hannah@example.com', '888-888-9999', 'Miami'),
('Ian Thomas', 'ian@example.com', '888-999-1111', 'Boston'),
('Julia White', 'julia@example.com', '888-000-1111', 'Seattle');

-- =====================================
-- Insert 10 products (laptops, consoles, cellphones)
-- =====================================
INSERT INTO products (name, category, brand, price) VALUES
('MacBook Pro 14"', 'laptop', 'Apple', 1999.99),
('Dell XPS 13', 'laptop', 'Dell', 1399.00),
('Lenovo ThinkPad X1 Carbon', 'laptop', 'Lenovo', 1599.50),
('PlayStation 5', 'console', 'Sony', 499.99),
('Xbox Series X', 'console', 'Microsoft', 479.99),
('Nintendo Switch OLED', 'console', 'Nintendo', 349.99),
('iPhone 15 Pro', 'cellphone', 'Apple', 1199.00),
('Samsung Galaxy S23 Ultra', 'cellphone', 'Samsung', 1299.99),
('Google Pixel 8 Pro', 'cellphone', 'Google', 1099.00),
('Asus ROG Zephyrus G14', 'laptop', 'Asus', 1799.00);

-- =====================================
-- Insert 10 orders
-- =====================================
INSERT INTO orders (customer_id, order_date, status) VALUES
(1, '2025-09-01 10:15:00', 'COMPLETED'),
(2, '2025-09-02 14:30:00', 'PENDING'),
(3, '2025-09-03 11:45:00', 'COMPLETED'),
(4, '2025-09-04 16:20:00', 'CANCELLED'),
(5, '2025-09-05 09:10:00', 'PENDING'),
(6, '2025-09-06 12:50:00', 'COMPLETED'),
(7, '2025-09-07 18:40:00', 'PENDING'),
(8, '2025-09-08 20:00:00', 'COMPLETED'),
(9, '2025-09-09 13:35:00', 'COMPLETED'),
(10, '2025-09-10 11:15:00', 'PENDING');

-- =====================================
-- Insert 10 order items
-- =====================================
INSERT INTO order_items (order_id, product_id, quantity, unit_price) VALUES
(1, 1, 1, 1999.99),
(1, 4, 2, 499.99),
(2, 7, 1, 1199.00),
(2, 6, 1, 349.99),
(3, 2, 1, 1399.00),
(3, 8, 1, 1299.99),
(4, 5, 2, 479.99),
(5, 3, 1, 1599.50),
(6, 10, 1, 1799.00),
(7, 9, 1, 1099.00);

-- Ver clientes
SELECT * FROM customers;

-- Ver productos
SELECT * FROM products;

-- Ver órdenes
SELECT * FROM orders;

-- Ver detalles de órdenes
SELECT * FROM order_items;