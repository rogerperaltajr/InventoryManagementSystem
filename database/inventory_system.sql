CREATE DATABASE IF NOT EXISTS inventory_system CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE inventory_system;

DROP TABLE IF EXISTS sale_items;
DROP TABLE IF EXISTS sales;
DROP TABLE IF EXISTS product_approvals;
DROP TABLE IF EXISTS activity_logs;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS product_categories;
DROP TABLE IF EXISTS units;
DROP TABLE IF EXISTS suppliers;
DROP TABLE IF EXISTS business_types;
DROP TABLE IF EXISTS brands;
DROP TABLE IF EXISTS settings;

CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    full_name VARCHAR(120) NOT NULL,
    username VARCHAR(60) NOT NULL UNIQUE,
    email VARCHAR(120) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    role ENUM('Admin','User') NOT NULL DEFAULT 'User',
    status ENUM('Active','Inactive') NOT NULL DEFAULT 'Active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE product_categories (id INT AUTO_INCREMENT PRIMARY KEY, name VARCHAR(80) NOT NULL UNIQUE);
CREATE TABLE units (id INT AUTO_INCREMENT PRIMARY KEY, name VARCHAR(50) NOT NULL UNIQUE);
CREATE TABLE suppliers (id INT AUTO_INCREMENT PRIMARY KEY, name VARCHAR(120) NOT NULL UNIQUE);
CREATE TABLE business_types (id INT AUTO_INCREMENT PRIMARY KEY, name VARCHAR(120) NOT NULL UNIQUE);
CREATE TABLE brands (id INT AUTO_INCREMENT PRIMARY KEY, name VARCHAR(120) NOT NULL UNIQUE);

CREATE TABLE products (
    id INT AUTO_INCREMENT PRIMARY KEY,
    product_code VARCHAR(60) NOT NULL UNIQUE,
    barcode VARCHAR(80) UNIQUE,
    product_name VARCHAR(160) NOT NULL,
    category_id INT NULL,
    brand_id INT NULL,
    unit_id INT NULL,
    cost_price DECIMAL(12,2) NOT NULL DEFAULT 0,
    selling_price DECIMAL(12,2) NOT NULL DEFAULT 0,
    quantity INT NOT NULL DEFAULT 0,
    reorder_level INT NOT NULL DEFAULT 0,
    expiration_date DATE NULL,
    supplier_id INT NULL,
    business_type_id INT NULL,
    image_path VARCHAR(255) NULL,
    status ENUM('Pending','Approved','Rejected') NOT NULL DEFAULT 'Pending',
    remarks TEXT NULL,
    created_by INT NULL,
    approved_by INT NULL,
    approved_at DATETIME NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (category_id) REFERENCES product_categories(id) ON DELETE SET NULL,
    FOREIGN KEY (brand_id) REFERENCES brands(id) ON DELETE SET NULL,
    FOREIGN KEY (unit_id) REFERENCES units(id) ON DELETE SET NULL,
    FOREIGN KEY (supplier_id) REFERENCES suppliers(id) ON DELETE SET NULL,
    FOREIGN KEY (business_type_id) REFERENCES business_types(id) ON DELETE SET NULL,
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
    FOREIGN KEY (approved_by) REFERENCES users(id) ON DELETE SET NULL
);

CREATE TABLE product_approvals (
    id INT AUTO_INCREMENT PRIMARY KEY,
    product_id INT NOT NULL,
    admin_id INT NOT NULL,
    status ENUM('Approved','Rejected') NOT NULL,
    remarks TEXT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,
    FOREIGN KEY (admin_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE sales (
    id INT AUTO_INCREMENT PRIMARY KEY,
    invoice_no VARCHAR(40) NOT NULL UNIQUE,
    user_id INT NULL,
    subtotal DECIMAL(12,2) NOT NULL,
    discount DECIMAL(12,2) NOT NULL DEFAULT 0,
    total DECIMAL(12,2) NOT NULL,
    payment_amount DECIMAL(12,2) NOT NULL,
    change_amount DECIMAL(12,2) NOT NULL,
    payment_method VARCHAR(60) DEFAULT 'Cash',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
);

CREATE TABLE sale_items (
    id INT AUTO_INCREMENT PRIMARY KEY,
    sale_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity INT NOT NULL,
    price DECIMAL(12,2) NOT NULL,
    subtotal DECIMAL(12,2) NOT NULL,
    FOREIGN KEY (sale_id) REFERENCES sales(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE
);

CREATE TABLE activity_logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NULL,
    action VARCHAR(255) NOT NULL,
    ip_address VARCHAR(45) NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
);

CREATE TABLE settings (
    id INT AUTO_INCREMENT PRIMARY KEY,
    setting_key VARCHAR(100) NOT NULL UNIQUE,
    setting_value TEXT NULL
);

INSERT INTO users (full_name, username, email, password_hash, role, status) VALUES
('System Administrator', 'admin', 'admin@example.com', '$2y$10$.DEkToLMYzJjd53ae0Jie.mxzcl.AFT4rLNH9RNonmrkEMGyVn1ea', 'Admin', 'Active'),
('Staff User', 'staff', 'staff@example.com', '$2y$10$.DEkToLMYzJjd53ae0Jie.mxzcl.AFT4rLNH9RNonmrkEMGyVn1ea', 'User', 'Active');

INSERT INTO product_categories (name) VALUES ('Food'), ('Medicine'), ('Beverages'), ('School Supplies'), ('Hardware');
INSERT INTO units (name) VALUES ('Piece'), ('Box'), ('Pack'), ('Bottle'), ('Kg');
INSERT INTO suppliers (name) VALUES ('Default Supplier'), ('Metro Wholesale'), ('Local Distributor');
INSERT INTO brands (name) VALUES ('Generic'), ('House Brand'), ('Premium');
INSERT INTO business_types (name) VALUES
('Sari-sari Store'), ('Pharmacy'), ('Grocery'), ('Hardware'), ('Restaurant'), ('Coffee Shop'),
('Booking System'), ('Service Business'), ('School Supplies'), ('General Merchandise'), ('Others');
INSERT INTO settings (setting_key, setting_value) VALUES ('payment_methods', 'Cash,GCash,Card,Bank Transfer');

INSERT INTO products (product_code, barcode, product_name, category_id, brand_id, unit_id, cost_price, selling_price, quantity, reorder_level, supplier_id, business_type_id, status, created_by, approved_by, approved_at) VALUES
('PRD-1001', '480000000001', 'Bottled Water 500ml', 3, 1, 4, 8.00, 15.00, 80, 20, 1, 3, 'Approved', 1, 1, NOW()),
('PRD-1002', '480000000002', 'Notebook', 4, 2, 1, 18.00, 30.00, 25, 10, 2, 9, 'Approved', 1, 1, NOW()),
('PRD-1003', '480000000003', 'Pain Reliever', 2, 1, 2, 75.00, 110.00, 6, 8, 3, 2, 'Approved', 1, 1, NOW()),
('PRD-1004', '480000000004', 'Pending Coffee Beans', 3, 3, 3, 180.00, 250.00, 12, 5, 1, 6, 'Pending', 2, NULL, NULL);
