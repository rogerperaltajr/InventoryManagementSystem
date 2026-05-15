USE inventory_system;

ALTER TABLE products ADD COLUMN IF NOT EXISTS normalized_product_name VARCHAR(255) NULL AFTER product_name;
ALTER TABLE products ADD COLUMN IF NOT EXISTS brand VARCHAR(120) NULL AFTER normalized_product_name;
ALTER TABLE products ADD COLUMN IF NOT EXISTS description TEXT NULL AFTER brand;
ALTER TABLE products ADD COLUMN IF NOT EXISTS stock_quantity INT NULL AFTER quantity;
ALTER TABLE products ADD COLUMN IF NOT EXISTS product_image VARCHAR(255) NULL AFTER image_path;
ALTER TABLE products ADD COLUMN IF NOT EXISTS product_image_alt VARCHAR(255) NULL AFTER product_image;
ALTER TABLE products ADD COLUMN IF NOT EXISTS duplicate_status ENUM('None','Possible Duplicate','Exact Duplicate','Ignored','Merged','Updated','Rejected') NOT NULL DEFAULT 'None' AFTER status;
ALTER TABLE products ADD COLUMN IF NOT EXISTS duplicate_reference_id INT NULL AFTER duplicate_status;
ALTER TABLE products ADD COLUMN IF NOT EXISTS duplicate_notes TEXT NULL AFTER duplicate_reference_id;
ALTER TABLE products ADD INDEX IF NOT EXISTS idx_products_normalized_name (normalized_product_name);
ALTER TABLE products ADD INDEX IF NOT EXISTS idx_products_category (category_id);
ALTER TABLE products ADD INDEX IF NOT EXISTS idx_products_business_type (business_type_id);
ALTER TABLE products ADD INDEX IF NOT EXISTS idx_products_brand_text (brand);

CREATE TABLE IF NOT EXISTS product_duplicate_actions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    product_id INT NULL,
    duplicate_reference_id INT NULL,
    action_taken ENUM('Detected','Ignored','Merged','Updated','Rejected','Approved','Imported') NOT NULL,
    details TEXT NULL,
    user_id INT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX(product_id),
    INDEX(duplicate_reference_id)
);

CREATE TABLE IF NOT EXISTS product_import_batches (
    id INT AUTO_INCREMENT PRIMARY KEY,
    file_name VARCHAR(255) NOT NULL,
    total_rows INT NOT NULL DEFAULT 0,
    new_products INT NOT NULL DEFAULT 0,
    exact_duplicates INT NOT NULL DEFAULT 0,
    possible_duplicates INT NOT NULL DEFAULT 0,
    invalid_rows INT NOT NULL DEFAULT 0,
    imported_by INT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS product_import_rows (
    id INT AUTO_INCREMENT PRIMARY KEY,
    batch_id INT NOT NULL,
    row_number INT NOT NULL,
    product_name VARCHAR(255) NULL,
    barcode VARCHAR(80) NULL,
    status ENUM('New','Exact Duplicate','Possible Duplicate','Invalid','Imported') NOT NULL,
    duplicate_reference_id INT NULL,
    message TEXT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (batch_id) REFERENCES product_import_batches(id) ON DELETE CASCADE
);

UPDATE products SET normalized_product_name = LOWER(TRIM(REGEXP_REPLACE(product_name, '[^a-zA-Z0-9]+', ' '))) WHERE normalized_product_name IS NULL OR normalized_product_name = '';
UPDATE products SET stock_quantity = quantity WHERE stock_quantity IS NULL;
UPDATE products SET product_image = image_path WHERE product_image IS NULL AND image_path IS NOT NULL;

INSERT IGNORE INTO suppliers (name) VALUES ('Default Philippine Supplier');
INSERT IGNORE INTO brands (name) VALUES ('Lucky Me'),('Nissin'),('Payless'),('Argentina'),('Century Tuna'),('555'),('CDO'),('Milo'),('Nescafe'),('Kopiko'),('Bear Brand'),('Surf'),('Tide'),('Safeguard'),('Palmolive'),('Biogesic'),('Enervon'),('Mongol'),('HBW'),('Generic');
USE inventory_system;

INSERT IGNORE INTO product_categories (name) VALUES ('Rice');
INSERT IGNORE INTO product_categories (name) VALUES ('Noodles');
INSERT IGNORE INTO product_categories (name) VALUES ('Canned Goods');
INSERT IGNORE INTO product_categories (name) VALUES ('Beverages');
INSERT IGNORE INTO product_categories (name) VALUES ('Coffee');
INSERT IGNORE INTO product_categories (name) VALUES ('Snacks');
INSERT IGNORE INTO product_categories (name) VALUES ('Biscuits');
INSERT IGNORE INTO product_categories (name) VALUES ('Bread');
INSERT IGNORE INTO product_categories (name) VALUES ('Condiments');
INSERT IGNORE INTO product_categories (name) VALUES ('Cooking Oil');
INSERT IGNORE INTO product_categories (name) VALUES ('Sugar');
INSERT IGNORE INTO product_categories (name) VALUES ('Milk');
INSERT IGNORE INTO product_categories (name) VALUES ('Soap');
INSERT IGNORE INTO product_categories (name) VALUES ('Shampoo');
INSERT IGNORE INTO product_categories (name) VALUES ('Detergent');
INSERT IGNORE INTO product_categories (name) VALUES ('Medicine');
INSERT IGNORE INTO product_categories (name) VALUES ('Vitamins');
INSERT IGNORE INTO product_categories (name) VALUES ('School Supplies');
INSERT IGNORE INTO product_categories (name) VALUES ('Hardware');
INSERT IGNORE INTO product_categories (name) VALUES ('Cleaning Supplies');
INSERT IGNORE INTO product_categories (name) VALUES ('Service Items');
INSERT IGNORE INTO product_categories (name) VALUES ('Others');
INSERT IGNORE INTO business_types (name) VALUES ('Sari-sari Store');
INSERT IGNORE INTO business_types (name) VALUES ('Grocery');
INSERT IGNORE INTO business_types (name) VALUES ('Pharmacy');
INSERT IGNORE INTO business_types (name) VALUES ('Hardware');
INSERT IGNORE INTO business_types (name) VALUES ('School Supplies');
INSERT IGNORE INTO business_types (name) VALUES ('General Merchandise');
INSERT IGNORE INTO business_types (name) VALUES ('Coffee Shop');
INSERT IGNORE INTO business_types (name) VALUES ('Restaurant');
INSERT IGNORE INTO business_types (name) VALUES ('Booking System');
INSERT IGNORE INTO business_types (name) VALUES ('Service Business');
INSERT IGNORE INTO units (name) VALUES ('piece');
INSERT IGNORE INTO units (name) VALUES ('pack');
INSERT IGNORE INTO units (name) VALUES ('sachet');
INSERT IGNORE INTO units (name) VALUES ('bottle');
INSERT IGNORE INTO units (name) VALUES ('can');
INSERT IGNORE INTO units (name) VALUES ('box');
INSERT IGNORE INTO units (name) VALUES ('kg');
INSERT IGNORE INTO units (name) VALUES ('liter');
INSERT IGNORE INTO units (name) VALUES ('roll');
INSERT IGNORE INTO units (name) VALUES ('tablet');
INSERT IGNORE INTO units (name) VALUES ('capsule');
INSERT IGNORE INTO units (name) VALUES ('set');

-- 500 starter Philippine products with category placeholder images

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000001', 6)), '4800000000001', 'Lucky Me Pancit Canton Chilimansi 60g', 'lucky me pancit canton chilimansi 60g', 'Lucky Me',
       (SELECT id FROM product_categories WHERE name='Noodles'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='pack'),
       13.12, 16.00, 55, 55, 5, 'assets/images/products/placeholders/noodles.png', 'assets/images/products/placeholders/noodles.png', 'Lucky Me Pancit Canton Chilimansi 60g product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000001');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000002', 6)), '4800000000002', 'Lucky Me Pancit Canton Kalamansi 60g', 'lucky me pancit canton kalamansi 60g', 'Lucky Me',
       (SELECT id FROM product_categories WHERE name='Noodles'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='pack'),
       13.12, 16.00, 111, 111, 5, 'assets/images/products/placeholders/noodles.png', 'assets/images/products/placeholders/noodles.png', 'Lucky Me Pancit Canton Kalamansi 60g product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000002');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000003', 6)), '4800000000003', 'Lucky Me Beef Noodles 55g', 'lucky me beef noodles 55g', 'Lucky Me',
       (SELECT id FROM product_categories WHERE name='Noodles'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='pack'),
       11.48, 14.00, 36, 36, 10, 'assets/images/products/placeholders/noodles.png', 'assets/images/products/placeholders/noodles.png', 'Lucky Me Beef Noodles 55g product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000003');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000004', 6)), '4800000000004', 'Nissin Cup Noodles Beef', 'nissin cup noodles beef', 'Nissin',
       (SELECT id FROM product_categories WHERE name='Noodles'),
       (SELECT id FROM business_types WHERE name='Grocery'),
       (SELECT id FROM units WHERE name='piece'),
       31.16, 38.00, 20, 20, 15, 'assets/images/products/placeholders/noodles.png', 'assets/images/products/placeholders/noodles.png', 'Nissin Cup Noodles Beef product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000004');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000005', 6)), '4800000000005', 'Payless Xtra Big Pancit Canton', 'payless xtra big pancit canton', 'Payless',
       (SELECT id FROM product_categories WHERE name='Noodles'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='pack'),
       13.94, 17.00, 20, 20, 20, 'assets/images/products/placeholders/noodles.png', 'assets/images/products/placeholders/noodles.png', 'Payless Xtra Big Pancit Canton product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000005');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000006', 6)), '4800000000006', 'Argentina Corned Beef 150g', 'argentina corned beef 150g', 'Argentina',
       (SELECT id FROM product_categories WHERE name='Canned Goods'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='can'),
       31.98, 39.00, 40, 40, 15, 'assets/images/products/placeholders/canned_goods.png', 'assets/images/products/placeholders/canned_goods.png', 'Argentina Corned Beef 150g product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000006');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000007', 6)), '4800000000007', 'Century Tuna Flakes in Oil 155g', 'century tuna flakes in oil 155g', 'Century',
       (SELECT id FROM product_categories WHERE name='Canned Goods'),
       (SELECT id FROM business_types WHERE name='Grocery'),
       (SELECT id FROM units WHERE name='can'),
       36.9, 45.00, 84, 84, 15, 'assets/images/products/placeholders/canned_goods.png', 'assets/images/products/placeholders/canned_goods.png', 'Century Tuna Flakes in Oil 155g product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000007');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000008', 6)), '4800000000008', 'Mega Sardines Tomato Sauce 155g', 'mega sardines tomato sauce 155g', 'Mega',
       (SELECT id FROM product_categories WHERE name='Canned Goods'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='can'),
       19.68, 24.00, 84, 84, 10, 'assets/images/products/placeholders/canned_goods.png', 'assets/images/products/placeholders/canned_goods.png', 'Mega Sardines Tomato Sauce 155g product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000008');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000009', 6)), '4800000000009', '555 Sardines Tomato Sauce 155g', '555 sardines tomato sauce 155g', '555',
       (SELECT id FROM product_categories WHERE name='Canned Goods'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='can'),
       18.86, 23.00, 27, 27, 5, 'assets/images/products/placeholders/canned_goods.png', 'assets/images/products/placeholders/canned_goods.png', '555 Sardines Tomato Sauce 155g product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000009');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000010', 6)), '4800000000010', 'Young''s Town Sardines 155g', 'young s town sardines 155g', 'Young''s Town',
       (SELECT id FROM product_categories WHERE name='Canned Goods'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='can'),
       18.86, 23.00, 98, 98, 20, 'assets/images/products/placeholders/canned_goods.png', 'assets/images/products/placeholders/canned_goods.png', 'Young''s Town Sardines 155g product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000010');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000011', 6)), '4800000000011', 'Coca-Cola 1.5L', 'coca cola 1 5l', 'Coca-Cola',
       (SELECT id FROM product_categories WHERE name='Beverages'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='bottle'),
       61.5, 75.00, 88, 88, 20, 'assets/images/products/placeholders/beverages.png', 'assets/images/products/placeholders/beverages.png', 'Coca-Cola 1.5L product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000011');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000012', 6)), '4800000000012', 'Sprite 1.5L', 'sprite 1 5l', 'Sprite',
       (SELECT id FROM product_categories WHERE name='Beverages'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='bottle'),
       61.5, 75.00, 88, 88, 5, 'assets/images/products/placeholders/beverages.png', 'assets/images/products/placeholders/beverages.png', 'Sprite 1.5L product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000012');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000013', 6)), '4800000000013', 'Royal Tru Orange 1.5L', 'royal tru orange 1 5l', 'Royal',
       (SELECT id FROM product_categories WHERE name='Beverages'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='bottle'),
       61.5, 75.00, 23, 23, 15, 'assets/images/products/placeholders/beverages.png', 'assets/images/products/placeholders/beverages.png', 'Royal Tru Orange 1.5L product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000013');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000014', 6)), '4800000000014', 'Cobra Energy Drink 350ml', 'cobra energy drink 350ml', 'Cobra',
       (SELECT id FROM product_categories WHERE name='Beverages'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='bottle'),
       20.5, 25.00, 71, 71, 5, 'assets/images/products/placeholders/beverages.png', 'assets/images/products/placeholders/beverages.png', 'Cobra Energy Drink 350ml product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000014');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000015', 6)), '4800000000015', 'C2 Green Tea 500ml', 'c2 green tea 500ml', 'C2',
       (SELECT id FROM product_categories WHERE name='Beverages'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='bottle'),
       28.7, 35.00, 50, 50, 5, 'assets/images/products/placeholders/beverages.png', 'assets/images/products/placeholders/beverages.png', 'C2 Green Tea 500ml product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000015');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000016', 6)), '4800000000016', 'Bear Brand Powdered Milk 33g', 'bear brand powdered milk 33g', 'Bear Brand',
       (SELECT id FROM product_categories WHERE name='Milk'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='sachet'),
       11.48, 14.00, 46, 46, 20, 'assets/images/products/placeholders/milk.png', 'assets/images/products/placeholders/milk.png', 'Bear Brand Powdered Milk 33g product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000016');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000017', 6)), '4800000000017', 'Milo Sachet 24g', 'milo sachet 24g', 'Milo',
       (SELECT id FROM product_categories WHERE name='Milk'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='sachet'),
       9.84, 12.00, 37, 37, 5, 'assets/images/products/placeholders/milk.png', 'assets/images/products/placeholders/milk.png', 'Milo Sachet 24g product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000017');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000018', 6)), '4800000000018', 'Alaska Evaporada 370ml', 'alaska evaporada 370ml', 'Alaska',
       (SELECT id FROM product_categories WHERE name='Milk'),
       (SELECT id FROM business_types WHERE name='Grocery'),
       (SELECT id FROM units WHERE name='can'),
       31.98, 39.00, 111, 111, 15, 'assets/images/products/placeholders/milk.png', 'assets/images/products/placeholders/milk.png', 'Alaska Evaporada 370ml product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000018');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000019', 6)), '4800000000019', 'Nescafe Classic Sachet 2g', 'nescafe classic sachet 2g', 'Nescafe',
       (SELECT id FROM product_categories WHERE name='Coffee'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='sachet'),
       2.46, 3.00, 107, 107, 10, 'assets/images/products/placeholders/coffee.png', 'assets/images/products/placeholders/coffee.png', 'Nescafe Classic Sachet 2g product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000019');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000020', 6)), '4800000000020', 'Kopiko Brown Coffee Twin Pack', 'kopiko brown coffee twin pack', 'Kopiko',
       (SELECT id FROM product_categories WHERE name='Coffee'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='pack'),
       12.3, 15.00, 16, 16, 20, 'assets/images/products/placeholders/coffee.png', 'assets/images/products/placeholders/coffee.png', 'Kopiko Brown Coffee Twin Pack product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000020');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000021', 6)), '4800000000021', 'Great Taste White 30g', 'great taste white 30g', 'Great Taste',
       (SELECT id FROM product_categories WHERE name='Coffee'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='sachet'),
       9.84, 12.00, 38, 38, 10, 'assets/images/products/placeholders/coffee.png', 'assets/images/products/placeholders/coffee.png', 'Great Taste White 30g product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000021');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000022', 6)), '4800000000022', 'SkyFlakes Crackers', 'skyflakes crackers', 'SkyFlakes',
       (SELECT id FROM product_categories WHERE name='Biscuits'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='pack'),
       8.2, 10.00, 38, 38, 15, 'assets/images/products/placeholders/biscuits.png', 'assets/images/products/placeholders/biscuits.png', 'SkyFlakes Crackers product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000022');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000023', 6)), '4800000000023', 'Fita Crackers', 'fita crackers', 'Fita',
       (SELECT id FROM product_categories WHERE name='Biscuits'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='pack'),
       7.38, 9.00, 55, 55, 20, 'assets/images/products/placeholders/biscuits.png', 'assets/images/products/placeholders/biscuits.png', 'Fita Crackers product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000023');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000024', 6)), '4800000000024', 'Rebisco Crackers', 'rebisco crackers', 'Rebisco',
       (SELECT id FROM product_categories WHERE name='Biscuits'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='pack'),
       6.56, 8.00, 76, 76, 15, 'assets/images/products/placeholders/biscuits.png', 'assets/images/products/placeholders/biscuits.png', 'Rebisco Crackers product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000024');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000025', 6)), '4800000000025', 'Piattos Cheese 40g', 'piattos cheese 40g', 'Piattos',
       (SELECT id FROM product_categories WHERE name='Snacks'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='pack'),
       16.4, 20.00, 107, 107, 10, 'assets/images/products/placeholders/snacks.png', 'assets/images/products/placeholders/snacks.png', 'Piattos Cheese 40g product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000025');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000026', 6)), '4800000000026', 'Nova Multigrain Snacks 40g', 'nova multigrain snacks 40g', 'Nova',
       (SELECT id FROM product_categories WHERE name='Snacks'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='pack'),
       16.4, 20.00, 20, 20, 10, 'assets/images/products/placeholders/snacks.png', 'assets/images/products/placeholders/snacks.png', 'Nova Multigrain Snacks 40g product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000026');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000027', 6)), '4800000000027', 'Chippy BBQ 110g', 'chippy bbq 110g', 'Chippy',
       (SELECT id FROM product_categories WHERE name='Snacks'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='pack'),
       26.24, 32.00, 98, 98, 15, 'assets/images/products/placeholders/snacks.png', 'assets/images/products/placeholders/snacks.png', 'Chippy BBQ 110g product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000027');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000028', 6)), '4800000000028', 'Safeguard Soap 60g', 'safeguard soap 60g', 'Safeguard',
       (SELECT id FROM product_categories WHERE name='Soap'),
       (SELECT id FROM business_types WHERE name='Grocery'),
       (SELECT id FROM units WHERE name='piece'),
       20.5, 25.00, 72, 72, 20, 'assets/images/products/placeholders/soap.png', 'assets/images/products/placeholders/soap.png', 'Safeguard Soap 60g product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000028');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000029', 6)), '4800000000029', 'Palmolive Shampoo Sachet', 'palmolive shampoo sachet', 'Palmolive',
       (SELECT id FROM product_categories WHERE name='Shampoo'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='sachet'),
       6.56, 8.00, 25, 25, 15, 'assets/images/products/placeholders/shampoo.png', 'assets/images/products/placeholders/shampoo.png', 'Palmolive Shampoo Sachet product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000029');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000030', 6)), '4800000000030', 'Head & Shoulders Sachet', 'head shoulders sachet', 'Head & Shoulders',
       (SELECT id FROM product_categories WHERE name='Shampoo'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='sachet'),
       7.38, 9.00, 80, 80, 15, 'assets/images/products/placeholders/shampoo.png', 'assets/images/products/placeholders/shampoo.png', 'Head & Shoulders Sachet product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000030');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000031', 6)), '4800000000031', 'Sunsilk Shampoo Sachet', 'sunsilk shampoo sachet', 'Sunsilk',
       (SELECT id FROM product_categories WHERE name='Shampoo'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='sachet'),
       6.56, 8.00, 99, 99, 20, 'assets/images/products/placeholders/shampoo.png', 'assets/images/products/placeholders/shampoo.png', 'Sunsilk Shampoo Sachet product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000031');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000032', 6)), '4800000000032', 'Surf Powder Detergent 70g', 'surf powder detergent 70g', 'Surf',
       (SELECT id FROM product_categories WHERE name='Detergent'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='sachet'),
       6.56, 8.00, 16, 16, 15, 'assets/images/products/placeholders/detergent.png', 'assets/images/products/placeholders/detergent.png', 'Surf Powder Detergent 70g product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000032');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000033', 6)), '4800000000033', 'Ariel Powder Detergent 70g', 'ariel powder detergent 70g', 'Ariel',
       (SELECT id FROM product_categories WHERE name='Detergent'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='sachet'),
       7.38, 9.00, 100, 100, 20, 'assets/images/products/placeholders/detergent.png', 'assets/images/products/placeholders/detergent.png', 'Ariel Powder Detergent 70g product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000033');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000034', 6)), '4800000000034', 'Tide Detergent Bar', 'tide detergent bar', 'Tide',
       (SELECT id FROM product_categories WHERE name='Detergent'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='piece'),
       12.3, 15.00, 97, 97, 5, 'assets/images/products/placeholders/detergent.png', 'assets/images/products/placeholders/detergent.png', 'Tide Detergent Bar product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000034');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000035', 6)), '4800000000035', 'Joy Dishwashing Liquid 20ml', 'joy dishwashing liquid 20ml', 'Joy',
       (SELECT id FROM product_categories WHERE name='Cleaning Supplies'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='sachet'),
       5.74, 7.00, 67, 67, 20, 'assets/images/products/placeholders/cleaning_supplies.png', 'assets/images/products/placeholders/cleaning_supplies.png', 'Joy Dishwashing Liquid 20ml product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000035');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000036', 6)), '4800000000036', 'Biogesic 500mg', 'biogesic 500mg', 'Biogesic',
       (SELECT id FROM product_categories WHERE name='Medicine'),
       (SELECT id FROM business_types WHERE name='Pharmacy'),
       (SELECT id FROM units WHERE name='tablet'),
       5.74, 7.00, 88, 88, 20, 'assets/images/products/placeholders/medicine.png', 'assets/images/products/placeholders/medicine.png', 'Biogesic 500mg product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000036');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000037', 6)), '4800000000037', 'Neozep Forte', 'neozep forte', 'Neozep',
       (SELECT id FROM product_categories WHERE name='Medicine'),
       (SELECT id FROM business_types WHERE name='Pharmacy'),
       (SELECT id FROM units WHERE name='tablet'),
       6.56, 8.00, 54, 54, 20, 'assets/images/products/placeholders/medicine.png', 'assets/images/products/placeholders/medicine.png', 'Neozep Forte product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000037');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000038', 6)), '4800000000038', 'Bioflu Tablet', 'bioflu tablet', 'Bioflu',
       (SELECT id FROM product_categories WHERE name='Medicine'),
       (SELECT id FROM business_types WHERE name='Pharmacy'),
       (SELECT id FROM units WHERE name='tablet'),
       7.38, 9.00, 23, 23, 5, 'assets/images/products/placeholders/medicine.png', 'assets/images/products/placeholders/medicine.png', 'Bioflu Tablet product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000038');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000039', 6)), '4800000000039', 'Alaxan FR Capsule', 'alaxan fr capsule', 'Alaxan',
       (SELECT id FROM product_categories WHERE name='Medicine'),
       (SELECT id FROM business_types WHERE name='Pharmacy'),
       (SELECT id FROM units WHERE name='capsule'),
       8.2, 10.00, 83, 83, 20, 'assets/images/products/placeholders/medicine.png', 'assets/images/products/placeholders/medicine.png', 'Alaxan FR Capsule product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000039');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000040', 6)), '4800000000040', 'Diatabs Capsule', 'diatabs capsule', 'Diatabs',
       (SELECT id FROM product_categories WHERE name='Medicine'),
       (SELECT id FROM business_types WHERE name='Pharmacy'),
       (SELECT id FROM units WHERE name='capsule'),
       9.02, 11.00, 107, 107, 20, 'assets/images/products/placeholders/medicine.png', 'assets/images/products/placeholders/medicine.png', 'Diatabs Capsule product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000040');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000041', 6)), '4800000000041', 'Vitamin C 500mg', 'vitamin c 500mg', 'Generic',
       (SELECT id FROM product_categories WHERE name='Vitamins'),
       (SELECT id FROM business_types WHERE name='Pharmacy'),
       (SELECT id FROM units WHERE name='tablet'),
       4.1, 5.00, 62, 62, 20, 'assets/images/products/placeholders/vitamins.png', 'assets/images/products/placeholders/vitamins.png', 'Vitamin C 500mg product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000041');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000042', 6)), '4800000000042', 'Bond Paper Short 10pcs', 'bond paper short 10pcs', 'Generic',
       (SELECT id FROM product_categories WHERE name='School Supplies'),
       (SELECT id FROM business_types WHERE name='School Supplies'),
       (SELECT id FROM units WHERE name='pack'),
       9.84, 12.00, 113, 113, 20, 'assets/images/products/placeholders/school_supplies.png', 'assets/images/products/placeholders/school_supplies.png', 'Bond Paper Short 10pcs product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000042');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000043', 6)), '4800000000043', 'Bond Paper Long 10pcs', 'bond paper long 10pcs', 'Generic',
       (SELECT id FROM product_categories WHERE name='School Supplies'),
       (SELECT id FROM business_types WHERE name='School Supplies'),
       (SELECT id FROM units WHERE name='pack'),
       12.3, 15.00, 18, 18, 5, 'assets/images/products/placeholders/school_supplies.png', 'assets/images/products/placeholders/school_supplies.png', 'Bond Paper Long 10pcs product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000043');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000044', 6)), '4800000000044', 'Ballpen Black', 'ballpen black', 'Generic',
       (SELECT id FROM product_categories WHERE name='School Supplies'),
       (SELECT id FROM business_types WHERE name='School Supplies'),
       (SELECT id FROM units WHERE name='piece'),
       8.2, 10.00, 81, 81, 10, 'assets/images/products/placeholders/school_supplies.png', 'assets/images/products/placeholders/school_supplies.png', 'Ballpen Black product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000044');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000045', 6)), '4800000000045', 'Pencil No.2', 'pencil no 2', 'Generic',
       (SELECT id FROM product_categories WHERE name='School Supplies'),
       (SELECT id FROM business_types WHERE name='School Supplies'),
       (SELECT id FROM units WHERE name='piece'),
       6.56, 8.00, 101, 101, 15, 'assets/images/products/placeholders/school_supplies.png', 'assets/images/products/placeholders/school_supplies.png', 'Pencil No.2 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000045');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000046', 6)), '4800000000046', 'Notebook 80 Leaves', 'notebook 80 leaves', 'Generic',
       (SELECT id FROM product_categories WHERE name='School Supplies'),
       (SELECT id FROM business_types WHERE name='School Supplies'),
       (SELECT id FROM units WHERE name='piece'),
       20.5, 25.00, 56, 56, 5, 'assets/images/products/placeholders/school_supplies.png', 'assets/images/products/placeholders/school_supplies.png', 'Notebook 80 Leaves product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000046');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000047', 6)), '4800000000047', 'Hammer Small', 'hammer small', 'Generic',
       (SELECT id FROM product_categories WHERE name='Hardware'),
       (SELECT id FROM business_types WHERE name='Hardware'),
       (SELECT id FROM units WHERE name='piece'),
       147.6, 180.00, 40, 40, 20, 'assets/images/products/placeholders/hardware.png', 'assets/images/products/placeholders/hardware.png', 'Hammer Small product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000047');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000048', 6)), '4800000000048', 'Screwdriver Flat', 'screwdriver flat', 'Generic',
       (SELECT id FROM product_categories WHERE name='Hardware'),
       (SELECT id FROM business_types WHERE name='Hardware'),
       (SELECT id FROM units WHERE name='piece'),
       53.3, 65.00, 91, 91, 5, 'assets/images/products/placeholders/hardware.png', 'assets/images/products/placeholders/hardware.png', 'Screwdriver Flat product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000048');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000049', 6)), '4800000000049', 'Common Nails 1kg', 'common nails 1kg', 'Generic',
       (SELECT id FROM product_categories WHERE name='Hardware'),
       (SELECT id FROM business_types WHERE name='Hardware'),
       (SELECT id FROM units WHERE name='kg'),
       77.9, 95.00, 53, 53, 15, 'assets/images/products/placeholders/hardware.png', 'assets/images/products/placeholders/hardware.png', 'Common Nails 1kg product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000049');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000050', 6)), '4800000000050', 'Electrical Tape', 'electrical tape', 'Generic',
       (SELECT id FROM product_categories WHERE name='Hardware'),
       (SELECT id FROM business_types WHERE name='Hardware'),
       (SELECT id FROM units WHERE name='roll'),
       20.5, 25.00, 52, 52, 15, 'assets/images/products/placeholders/hardware.png', 'assets/images/products/placeholders/hardware.png', 'Electrical Tape product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000050');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000051', 6)), '4800000000051', 'Rice Regular per kilo', 'rice regular per kilo', 'Generic',
       (SELECT id FROM product_categories WHERE name='Rice'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='kg'),
       45.1, 55.00, 94, 94, 5, 'assets/images/products/placeholders/rice.png', 'assets/images/products/placeholders/rice.png', 'Rice Regular per kilo product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000051');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000052', 6)), '4800000000052', 'Cooking Oil 1L', 'cooking oil 1l', 'Generic',
       (SELECT id FROM product_categories WHERE name='Cooking Oil'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='liter'),
       77.9, 95.00, 70, 70, 5, 'assets/images/products/placeholders/cooking_oil.png', 'assets/images/products/placeholders/cooking_oil.png', 'Cooking Oil 1L product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000052');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000053', 6)), '4800000000053', 'Sugar White per kilo', 'sugar white per kilo', 'Generic',
       (SELECT id FROM product_categories WHERE name='Sugar'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='kg'),
       69.7, 85.00, 113, 113, 10, 'assets/images/products/placeholders/sugar.png', 'assets/images/products/placeholders/sugar.png', 'Sugar White per kilo product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000053');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000054', 6)), '4800000000054', 'Silver Swan Soy Sauce 1L', 'silver swan soy sauce 1l', 'Silver Swan',
       (SELECT id FROM product_categories WHERE name='Condiments'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='bottle'),
       50.84, 62.00, 21, 21, 15, 'assets/images/products/placeholders/condiments.png', 'assets/images/products/placeholders/condiments.png', 'Silver Swan Soy Sauce 1L product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000054');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000055', 6)), '4800000000055', 'Datu Puti Vinegar 1L', 'datu puti vinegar 1l', 'Datu Puti',
       (SELECT id FROM product_categories WHERE name='Condiments'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='bottle'),
       47.56, 58.00, 116, 116, 10, 'assets/images/products/placeholders/condiments.png', 'assets/images/products/placeholders/condiments.png', 'Datu Puti Vinegar 1L product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000055');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000056', 6)), '4800000000056', 'C2 Green Tea 500ml Regular Pack 56', 'c2 green tea 500ml regular pack 56', 'C2',
       (SELECT id FROM product_categories WHERE name='Beverages'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='bottle'),
       24.6, 30.00, 44, 44, 10, 'assets/images/products/placeholders/beverages.png', 'assets/images/products/placeholders/beverages.png', 'C2 Green Tea 500ml Regular Pack 56 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000056');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000057', 6)), '4800000000057', 'Great Taste White 30g Bundle Pack 57', 'great taste white 30g bundle pack 57', 'Great Taste',
       (SELECT id FROM product_categories WHERE name='Coffee'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='sachet'),
       12.3, 15.00, 113, 113, 5, 'assets/images/products/placeholders/coffee.png', 'assets/images/products/placeholders/coffee.png', 'Great Taste White 30g Bundle Pack 57 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000057');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000058', 6)), '4800000000058', 'Argentina Corned Beef 150g Family Pack 58', 'argentina corned beef 150g family pack 58', 'Argentina',
       (SELECT id FROM product_categories WHERE name='Canned Goods'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='can'),
       29.52, 36.00, 89, 89, 20, 'assets/images/products/placeholders/canned_goods.png', 'assets/images/products/placeholders/canned_goods.png', 'Argentina Corned Beef 150g Family Pack 58 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000058');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000059', 6)), '4800000000059', 'Alaxan FR Capsule Family Pack 59', 'alaxan fr capsule family pack 59', 'Alaxan',
       (SELECT id FROM product_categories WHERE name='Medicine'),
       (SELECT id FROM business_types WHERE name='Pharmacy'),
       (SELECT id FROM units WHERE name='capsule'),
       9.02, 11.00, 24, 24, 10, 'assets/images/products/placeholders/medicine.png', 'assets/images/products/placeholders/medicine.png', 'Alaxan FR Capsule Family Pack 59 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000059');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000060', 6)), '4800000000060', 'Kopiko Brown Coffee Twin Pack Family Pack 60', 'kopiko brown coffee twin pack family pack 60', 'Kopiko',
       (SELECT id FROM product_categories WHERE name='Coffee'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='pack'),
       13.94, 17.00, 67, 67, 5, 'assets/images/products/placeholders/coffee.png', 'assets/images/products/placeholders/coffee.png', 'Kopiko Brown Coffee Twin Pack Family Pack 60 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000060');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000061', 6)), '4800000000061', 'Chippy BBQ 110g Regular Pack 61', 'chippy bbq 110g regular pack 61', 'Chippy',
       (SELECT id FROM product_categories WHERE name='Snacks'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='pack'),
       27.06, 33.00, 103, 103, 10, 'assets/images/products/placeholders/snacks.png', 'assets/images/products/placeholders/snacks.png', 'Chippy BBQ 110g Regular Pack 61 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000061');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000062', 6)), '4800000000062', 'Surf Powder Detergent 70g Bundle Pack 62', 'surf powder detergent 70g bundle pack 62', 'Surf',
       (SELECT id FROM product_categories WHERE name='Detergent'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='sachet'),
       5.74, 7.00, 28, 28, 5, 'assets/images/products/placeholders/detergent.png', 'assets/images/products/placeholders/detergent.png', 'Surf Powder Detergent 70g Bundle Pack 62 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000062');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000063', 6)), '4800000000063', 'Common Nails 1kg Promo Pack 63', 'common nails 1kg promo pack 63', 'Generic',
       (SELECT id FROM product_categories WHERE name='Hardware'),
       (SELECT id FROM business_types WHERE name='Hardware'),
       (SELECT id FROM units WHERE name='kg'),
       100.86, 123.00, 30, 30, 15, 'assets/images/products/placeholders/hardware.png', 'assets/images/products/placeholders/hardware.png', 'Common Nails 1kg Promo Pack 63 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000063');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000064', 6)), '4800000000064', 'Royal Tru Orange 1.5L Family Pack 64', 'royal tru orange 1 5l family pack 64', 'Royal',
       (SELECT id FROM product_categories WHERE name='Beverages'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='bottle'),
       73.8, 90.00, 43, 43, 5, 'assets/images/products/placeholders/beverages.png', 'assets/images/products/placeholders/beverages.png', 'Royal Tru Orange 1.5L Family Pack 64 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000064');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000065', 6)), '4800000000065', 'Argentina Corned Beef 150g Regular Pack 65', 'argentina corned beef 150g regular pack 65', 'Argentina',
       (SELECT id FROM product_categories WHERE name='Canned Goods'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='can'),
       29.52, 36.00, 52, 52, 20, 'assets/images/products/placeholders/canned_goods.png', 'assets/images/products/placeholders/canned_goods.png', 'Argentina Corned Beef 150g Regular Pack 65 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000065');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000066', 6)), '4800000000066', 'Common Nails 1kg Family Pack 66', 'common nails 1kg family pack 66', 'Generic',
       (SELECT id FROM product_categories WHERE name='Hardware'),
       (SELECT id FROM business_types WHERE name='Hardware'),
       (SELECT id FROM units WHERE name='kg'),
       66.42, 81.00, 34, 34, 10, 'assets/images/products/placeholders/hardware.png', 'assets/images/products/placeholders/hardware.png', 'Common Nails 1kg Family Pack 66 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000066');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000067', 6)), '4800000000067', 'Datu Puti Vinegar 1L Regular Pack 67', 'datu puti vinegar 1l regular pack 67', 'Datu Puti',
       (SELECT id FROM product_categories WHERE name='Condiments'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='bottle'),
       51.66, 63.00, 107, 107, 15, 'assets/images/products/placeholders/condiments.png', 'assets/images/products/placeholders/condiments.png', 'Datu Puti Vinegar 1L Regular Pack 67 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000067');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000068', 6)), '4800000000068', '555 Sardines Tomato Sauce 155g Bundle Pack 68', '555 sardines tomato sauce 155g bundle pack 68', '555',
       (SELECT id FROM product_categories WHERE name='Canned Goods'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='can'),
       22.14, 27.00, 68, 68, 10, 'assets/images/products/placeholders/canned_goods.png', 'assets/images/products/placeholders/canned_goods.png', '555 Sardines Tomato Sauce 155g Bundle Pack 68 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000068');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000069', 6)), '4800000000069', 'Sunsilk Shampoo Sachet Bundle Pack 69', 'sunsilk shampoo sachet bundle pack 69', 'Sunsilk',
       (SELECT id FROM product_categories WHERE name='Shampoo'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='sachet'),
       5.74, 7.00, 81, 81, 15, 'assets/images/products/placeholders/shampoo.png', 'assets/images/products/placeholders/shampoo.png', 'Sunsilk Shampoo Sachet Bundle Pack 69 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000069');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000070', 6)), '4800000000070', 'Electrical Tape Bundle Pack 70', 'electrical tape bundle pack 70', 'Generic',
       (SELECT id FROM product_categories WHERE name='Hardware'),
       (SELECT id FROM business_types WHERE name='Hardware'),
       (SELECT id FROM units WHERE name='roll'),
       23.78, 29.00, 93, 93, 5, 'assets/images/products/placeholders/hardware.png', 'assets/images/products/placeholders/hardware.png', 'Electrical Tape Bundle Pack 70 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000070');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000071', 6)), '4800000000071', 'Bear Brand Powdered Milk 33g Small Pack 71', 'bear brand powdered milk 33g small pack 71', 'Bear Brand',
       (SELECT id FROM product_categories WHERE name='Milk'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='sachet'),
       12.3, 15.00, 117, 117, 5, 'assets/images/products/placeholders/milk.png', 'assets/images/products/placeholders/milk.png', 'Bear Brand Powdered Milk 33g Small Pack 71 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000071');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000072', 6)), '4800000000072', 'Alaska Evaporada 370ml Regular Pack 72', 'alaska evaporada 370ml regular pack 72', 'Alaska',
       (SELECT id FROM product_categories WHERE name='Milk'),
       (SELECT id FROM business_types WHERE name='Grocery'),
       (SELECT id FROM units WHERE name='can'),
       34.44, 42.00, 43, 43, 10, 'assets/images/products/placeholders/milk.png', 'assets/images/products/placeholders/milk.png', 'Alaska Evaporada 370ml Regular Pack 72 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000072');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000073', 6)), '4800000000073', 'Bond Paper Long 10pcs Small Pack 73', 'bond paper long 10pcs small pack 73', 'Generic',
       (SELECT id FROM product_categories WHERE name='School Supplies'),
       (SELECT id FROM business_types WHERE name='School Supplies'),
       (SELECT id FROM units WHERE name='pack'),
       16.4, 20.00, 73, 73, 10, 'assets/images/products/placeholders/school_supplies.png', 'assets/images/products/placeholders/school_supplies.png', 'Bond Paper Long 10pcs Small Pack 73 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000073');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000074', 6)), '4800000000074', 'Payless Xtra Big Pancit Canton Regular Pack 74', 'payless xtra big pancit canton regular pack 74', 'Payless',
       (SELECT id FROM product_categories WHERE name='Noodles'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='pack'),
       15.58, 19.00, 88, 88, 5, 'assets/images/products/placeholders/noodles.png', 'assets/images/products/placeholders/noodles.png', 'Payless Xtra Big Pancit Canton Regular Pack 74 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000074');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000075', 6)), '4800000000075', 'Datu Puti Vinegar 1L Promo Pack 75', 'datu puti vinegar 1l promo pack 75', 'Datu Puti',
       (SELECT id FROM product_categories WHERE name='Condiments'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='bottle'),
       63.96, 78.00, 74, 74, 10, 'assets/images/products/placeholders/condiments.png', 'assets/images/products/placeholders/condiments.png', 'Datu Puti Vinegar 1L Promo Pack 75 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000075');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000076', 6)), '4800000000076', 'Payless Xtra Big Pancit Canton Bundle Pack 76', 'payless xtra big pancit canton bundle pack 76', 'Payless',
       (SELECT id FROM product_categories WHERE name='Noodles'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='pack'),
       13.94, 17.00, 86, 86, 15, 'assets/images/products/placeholders/noodles.png', 'assets/images/products/placeholders/noodles.png', 'Payless Xtra Big Pancit Canton Bundle Pack 76 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000076');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000077', 6)), '4800000000077', 'Datu Puti Vinegar 1L Small Pack 77', 'datu puti vinegar 1l small pack 77', 'Datu Puti',
       (SELECT id FROM product_categories WHERE name='Condiments'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='bottle'),
       48.38, 59.00, 87, 87, 20, 'assets/images/products/placeholders/condiments.png', 'assets/images/products/placeholders/condiments.png', 'Datu Puti Vinegar 1L Small Pack 77 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000077');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000078', 6)), '4800000000078', 'Common Nails 1kg Regular Pack 78', 'common nails 1kg regular pack 78', 'Generic',
       (SELECT id FROM product_categories WHERE name='Hardware'),
       (SELECT id FROM business_types WHERE name='Hardware'),
       (SELECT id FROM units WHERE name='kg'),
       68.88, 84.00, 100, 100, 5, 'assets/images/products/placeholders/hardware.png', 'assets/images/products/placeholders/hardware.png', 'Common Nails 1kg Regular Pack 78 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000078');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000079', 6)), '4800000000079', 'Sunsilk Shampoo Sachet Promo Pack 79', 'sunsilk shampoo sachet promo pack 79', 'Sunsilk',
       (SELECT id FROM product_categories WHERE name='Shampoo'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='sachet'),
       7.38, 9.00, 77, 77, 20, 'assets/images/products/placeholders/shampoo.png', 'assets/images/products/placeholders/shampoo.png', 'Sunsilk Shampoo Sachet Promo Pack 79 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000079');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000080', 6)), '4800000000080', 'Cooking Oil 1L Promo Pack 80', 'cooking oil 1l promo pack 80', 'Generic',
       (SELECT id FROM product_categories WHERE name='Cooking Oil'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='liter'),
       77.08, 94.00, 108, 108, 10, 'assets/images/products/placeholders/cooking_oil.png', 'assets/images/products/placeholders/cooking_oil.png', 'Cooking Oil 1L Promo Pack 80 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000080');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000081', 6)), '4800000000081', 'Bond Paper Short 10pcs Bundle Pack 81', 'bond paper short 10pcs bundle pack 81', 'Generic',
       (SELECT id FROM product_categories WHERE name='School Supplies'),
       (SELECT id FROM business_types WHERE name='School Supplies'),
       (SELECT id FROM units WHERE name='pack'),
       12.3, 15.00, 23, 23, 5, 'assets/images/products/placeholders/school_supplies.png', 'assets/images/products/placeholders/school_supplies.png', 'Bond Paper Short 10pcs Bundle Pack 81 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000081');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000082', 6)), '4800000000082', 'Hammer Small Bundle Pack 82', 'hammer small bundle pack 82', 'Generic',
       (SELECT id FROM product_categories WHERE name='Hardware'),
       (SELECT id FROM business_types WHERE name='Hardware'),
       (SELECT id FROM units WHERE name='piece'),
       149.24, 182.00, 48, 48, 20, 'assets/images/products/placeholders/hardware.png', 'assets/images/products/placeholders/hardware.png', 'Hammer Small Bundle Pack 82 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000082');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000083', 6)), '4800000000083', 'Safeguard Soap 60g Family Pack 83', 'safeguard soap 60g family pack 83', 'Safeguard',
       (SELECT id FROM product_categories WHERE name='Soap'),
       (SELECT id FROM business_types WHERE name='Grocery'),
       (SELECT id FROM units WHERE name='piece'),
       24.6, 30.00, 55, 55, 5, 'assets/images/products/placeholders/soap.png', 'assets/images/products/placeholders/soap.png', 'Safeguard Soap 60g Family Pack 83 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000083');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000084', 6)), '4800000000084', 'Sunsilk Shampoo Sachet Small Pack 84', 'sunsilk shampoo sachet small pack 84', 'Sunsilk',
       (SELECT id FROM product_categories WHERE name='Shampoo'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='sachet'),
       9.02, 11.00, 46, 46, 15, 'assets/images/products/placeholders/shampoo.png', 'assets/images/products/placeholders/shampoo.png', 'Sunsilk Shampoo Sachet Small Pack 84 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000084');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000085', 6)), '4800000000085', 'Nissin Cup Noodles Beef Promo Pack 85', 'nissin cup noodles beef promo pack 85', 'Nissin',
       (SELECT id FROM product_categories WHERE name='Noodles'),
       (SELECT id FROM business_types WHERE name='Grocery'),
       (SELECT id FROM units WHERE name='piece'),
       38.54, 47.00, 67, 67, 5, 'assets/images/products/placeholders/noodles.png', 'assets/images/products/placeholders/noodles.png', 'Nissin Cup Noodles Beef Promo Pack 85 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000085');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000086', 6)), '4800000000086', 'Silver Swan Soy Sauce 1L Promo Pack 86', 'silver swan soy sauce 1l promo pack 86', 'Silver Swan',
       (SELECT id FROM product_categories WHERE name='Condiments'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='bottle'),
       59.04, 72.00, 33, 33, 20, 'assets/images/products/placeholders/condiments.png', 'assets/images/products/placeholders/condiments.png', 'Silver Swan Soy Sauce 1L Promo Pack 86 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000086');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000087', 6)), '4800000000087', 'Rebisco Crackers Regular Pack 87', 'rebisco crackers regular pack 87', 'Rebisco',
       (SELECT id FROM product_categories WHERE name='Biscuits'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='pack'),
       5.74, 7.00, 38, 38, 10, 'assets/images/products/placeholders/biscuits.png', 'assets/images/products/placeholders/biscuits.png', 'Rebisco Crackers Regular Pack 87 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000087');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000088', 6)), '4800000000088', 'Neozep Forte Small Pack 88', 'neozep forte small pack 88', 'Neozep',
       (SELECT id FROM product_categories WHERE name='Medicine'),
       (SELECT id FROM business_types WHERE name='Pharmacy'),
       (SELECT id FROM units WHERE name='tablet'),
       6.56, 8.00, 87, 87, 15, 'assets/images/products/placeholders/medicine.png', 'assets/images/products/placeholders/medicine.png', 'Neozep Forte Small Pack 88 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000088');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000089', 6)), '4800000000089', 'Sunsilk Shampoo Sachet Regular Pack 89', 'sunsilk shampoo sachet regular pack 89', 'Sunsilk',
       (SELECT id FROM product_categories WHERE name='Shampoo'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='sachet'),
       6.56, 8.00, 67, 67, 10, 'assets/images/products/placeholders/shampoo.png', 'assets/images/products/placeholders/shampoo.png', 'Sunsilk Shampoo Sachet Regular Pack 89 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000089');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000090', 6)), '4800000000090', 'Common Nails 1kg Family Pack 90', 'common nails 1kg family pack 90', 'Generic',
       (SELECT id FROM product_categories WHERE name='Hardware'),
       (SELECT id FROM business_types WHERE name='Hardware'),
       (SELECT id FROM units WHERE name='kg'),
       96.76, 118.00, 86, 86, 10, 'assets/images/products/placeholders/hardware.png', 'assets/images/products/placeholders/hardware.png', 'Common Nails 1kg Family Pack 90 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000090');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000091', 6)), '4800000000091', 'Cobra Energy Drink 350ml Bundle Pack 91', 'cobra energy drink 350ml bundle pack 91', 'Cobra',
       (SELECT id FROM product_categories WHERE name='Beverages'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='bottle'),
       22.14, 27.00, 105, 105, 15, 'assets/images/products/placeholders/beverages.png', 'assets/images/products/placeholders/beverages.png', 'Cobra Energy Drink 350ml Bundle Pack 91 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000091');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000092', 6)), '4800000000092', 'Tide Detergent Bar Family Pack 92', 'tide detergent bar family pack 92', 'Tide',
       (SELECT id FROM product_categories WHERE name='Detergent'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='piece'),
       15.58, 19.00, 93, 93, 20, 'assets/images/products/placeholders/detergent.png', 'assets/images/products/placeholders/detergent.png', 'Tide Detergent Bar Family Pack 92 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000092');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000093', 6)), '4800000000093', 'Hammer Small Promo Pack 93', 'hammer small promo pack 93', 'Generic',
       (SELECT id FROM product_categories WHERE name='Hardware'),
       (SELECT id FROM business_types WHERE name='Hardware'),
       (SELECT id FROM units WHERE name='piece'),
       177.12, 216.00, 40, 40, 20, 'assets/images/products/placeholders/hardware.png', 'assets/images/products/placeholders/hardware.png', 'Hammer Small Promo Pack 93 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000093');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000094', 6)), '4800000000094', 'Vitamin C 500mg Family Pack 94', 'vitamin c 500mg family pack 94', 'Generic',
       (SELECT id FROM product_categories WHERE name='Vitamins'),
       (SELECT id FROM business_types WHERE name='Pharmacy'),
       (SELECT id FROM units WHERE name='tablet'),
       5.74, 7.00, 16, 16, 10, 'assets/images/products/placeholders/vitamins.png', 'assets/images/products/placeholders/vitamins.png', 'Vitamin C 500mg Family Pack 94 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000094');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000095', 6)), '4800000000095', 'Bioflu Tablet Small Pack 95', 'bioflu tablet small pack 95', 'Bioflu',
       (SELECT id FROM product_categories WHERE name='Medicine'),
       (SELECT id FROM business_types WHERE name='Pharmacy'),
       (SELECT id FROM units WHERE name='tablet'),
       9.02, 11.00, 36, 36, 10, 'assets/images/products/placeholders/medicine.png', 'assets/images/products/placeholders/medicine.png', 'Bioflu Tablet Small Pack 95 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000095');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000096', 6)), '4800000000096', 'Payless Xtra Big Pancit Canton Promo Pack 96', 'payless xtra big pancit canton promo pack 96', 'Payless',
       (SELECT id FROM product_categories WHERE name='Noodles'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='pack'),
       18.86, 23.00, 15, 15, 10, 'assets/images/products/placeholders/noodles.png', 'assets/images/products/placeholders/noodles.png', 'Payless Xtra Big Pancit Canton Promo Pack 96 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000096');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000097', 6)), '4800000000097', 'Vitamin C 500mg Small Pack 97', 'vitamin c 500mg small pack 97', 'Generic',
       (SELECT id FROM product_categories WHERE name='Vitamins'),
       (SELECT id FROM business_types WHERE name='Pharmacy'),
       (SELECT id FROM units WHERE name='tablet'),
       3.28, 4.00, 106, 106, 5, 'assets/images/products/placeholders/vitamins.png', 'assets/images/products/placeholders/vitamins.png', 'Vitamin C 500mg Small Pack 97 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000097');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000098', 6)), '4800000000098', 'Piattos Cheese 40g Family Pack 98', 'piattos cheese 40g family pack 98', 'Piattos',
       (SELECT id FROM product_categories WHERE name='Snacks'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='pack'),
       19.68, 24.00, 54, 54, 20, 'assets/images/products/placeholders/snacks.png', 'assets/images/products/placeholders/snacks.png', 'Piattos Cheese 40g Family Pack 98 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000098');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000099', 6)), '4800000000099', 'Young''s Town Sardines 155g Small Pack 99', 'young s town sardines 155g small pack 99', 'Young''s Town',
       (SELECT id FROM product_categories WHERE name='Canned Goods'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='can'),
       23.78, 29.00, 39, 39, 10, 'assets/images/products/placeholders/canned_goods.png', 'assets/images/products/placeholders/canned_goods.png', 'Young''s Town Sardines 155g Small Pack 99 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000099');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000100', 6)), '4800000000100', 'Sprite 1.5L Small Pack 100', 'sprite 1 5l small pack 100', 'Sprite',
       (SELECT id FROM product_categories WHERE name='Beverages'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='bottle'),
       55.76, 68.00, 105, 105, 20, 'assets/images/products/placeholders/beverages.png', 'assets/images/products/placeholders/beverages.png', 'Sprite 1.5L Small Pack 100 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000100');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000101', 6)), '4800000000101', 'Silver Swan Soy Sauce 1L Small Pack 101', 'silver swan soy sauce 1l small pack 101', 'Silver Swan',
       (SELECT id FROM product_categories WHERE name='Condiments'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='bottle'),
       49.2, 60.00, 64, 64, 15, 'assets/images/products/placeholders/condiments.png', 'assets/images/products/placeholders/condiments.png', 'Silver Swan Soy Sauce 1L Small Pack 101 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000101');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000102', 6)), '4800000000102', 'SkyFlakes Crackers Family Pack 102', 'skyflakes crackers family pack 102', 'SkyFlakes',
       (SELECT id FROM product_categories WHERE name='Biscuits'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='pack'),
       9.84, 12.00, 18, 18, 10, 'assets/images/products/placeholders/biscuits.png', 'assets/images/products/placeholders/biscuits.png', 'SkyFlakes Crackers Family Pack 102 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000102');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000103', 6)), '4800000000103', 'Joy Dishwashing Liquid 20ml Regular Pack 103', 'joy dishwashing liquid 20ml regular pack 103', 'Joy',
       (SELECT id FROM product_categories WHERE name='Cleaning Supplies'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='sachet'),
       5.74, 7.00, 89, 89, 10, 'assets/images/products/placeholders/cleaning_supplies.png', 'assets/images/products/placeholders/cleaning_supplies.png', 'Joy Dishwashing Liquid 20ml Regular Pack 103 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000103');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000104', 6)), '4800000000104', 'Bond Paper Short 10pcs Bundle Pack 104', 'bond paper short 10pcs bundle pack 104', 'Generic',
       (SELECT id FROM product_categories WHERE name='School Supplies'),
       (SELECT id FROM business_types WHERE name='School Supplies'),
       (SELECT id FROM units WHERE name='pack'),
       12.3, 15.00, 20, 20, 5, 'assets/images/products/placeholders/school_supplies.png', 'assets/images/products/placeholders/school_supplies.png', 'Bond Paper Short 10pcs Bundle Pack 104 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000104');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000105', 6)), '4800000000105', 'Cobra Energy Drink 350ml Bundle Pack 105', 'cobra energy drink 350ml bundle pack 105', 'Cobra',
       (SELECT id FROM product_categories WHERE name='Beverages'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='bottle'),
       18.86, 23.00, 110, 110, 10, 'assets/images/products/placeholders/beverages.png', 'assets/images/products/placeholders/beverages.png', 'Cobra Energy Drink 350ml Bundle Pack 105 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000105');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000106', 6)), '4800000000106', 'Nissin Cup Noodles Beef Family Pack 106', 'nissin cup noodles beef family pack 106', 'Nissin',
       (SELECT id FROM product_categories WHERE name='Noodles'),
       (SELECT id FROM business_types WHERE name='Grocery'),
       (SELECT id FROM units WHERE name='piece'),
       37.72, 46.00, 17, 17, 5, 'assets/images/products/placeholders/noodles.png', 'assets/images/products/placeholders/noodles.png', 'Nissin Cup Noodles Beef Family Pack 106 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000106');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000107', 6)), '4800000000107', 'Coca-Cola 1.5L Family Pack 107', 'coca cola 1 5l family pack 107', 'Coca-Cola',
       (SELECT id FROM product_categories WHERE name='Beverages'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='bottle'),
       68.06, 83.00, 63, 63, 10, 'assets/images/products/placeholders/beverages.png', 'assets/images/products/placeholders/beverages.png', 'Coca-Cola 1.5L Family Pack 107 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000107');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000108', 6)), '4800000000108', 'Cooking Oil 1L Small Pack 108', 'cooking oil 1l small pack 108', 'Generic',
       (SELECT id FROM product_categories WHERE name='Cooking Oil'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='liter'),
       98.4, 120.00, 42, 42, 20, 'assets/images/products/placeholders/cooking_oil.png', 'assets/images/products/placeholders/cooking_oil.png', 'Cooking Oil 1L Small Pack 108 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000108');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000109', 6)), '4800000000109', 'Screwdriver Flat Small Pack 109', 'screwdriver flat small pack 109', 'Generic',
       (SELECT id FROM product_categories WHERE name='Hardware'),
       (SELECT id FROM business_types WHERE name='Hardware'),
       (SELECT id FROM units WHERE name='piece'),
       65.6, 80.00, 84, 84, 10, 'assets/images/products/placeholders/hardware.png', 'assets/images/products/placeholders/hardware.png', 'Screwdriver Flat Small Pack 109 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000109');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000110', 6)), '4800000000110', 'Biogesic 500mg Regular Pack 110', 'biogesic 500mg regular pack 110', 'Biogesic',
       (SELECT id FROM product_categories WHERE name='Medicine'),
       (SELECT id FROM business_types WHERE name='Pharmacy'),
       (SELECT id FROM units WHERE name='tablet'),
       5.74, 7.00, 84, 84, 10, 'assets/images/products/placeholders/medicine.png', 'assets/images/products/placeholders/medicine.png', 'Biogesic 500mg Regular Pack 110 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000110');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000111', 6)), '4800000000111', 'Cooking Oil 1L Small Pack 111', 'cooking oil 1l small pack 111', 'Generic',
       (SELECT id FROM product_categories WHERE name='Cooking Oil'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='liter'),
       104.96, 128.00, 41, 41, 5, 'assets/images/products/placeholders/cooking_oil.png', 'assets/images/products/placeholders/cooking_oil.png', 'Cooking Oil 1L Small Pack 111 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000111');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000112', 6)), '4800000000112', 'Hammer Small Promo Pack 112', 'hammer small promo pack 112', 'Generic',
       (SELECT id FROM product_categories WHERE name='Hardware'),
       (SELECT id FROM business_types WHERE name='Hardware'),
       (SELECT id FROM units WHERE name='piece'),
       132.02, 161.00, 47, 47, 20, 'assets/images/products/placeholders/hardware.png', 'assets/images/products/placeholders/hardware.png', 'Hammer Small Promo Pack 112 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000112');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000113', 6)), '4800000000113', 'Mega Sardines Tomato Sauce 155g Bundle Pack 113', 'mega sardines tomato sauce 155g bundle pack 113', 'Mega',
       (SELECT id FROM product_categories WHERE name='Canned Goods'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='can'),
       19.68, 24.00, 44, 44, 5, 'assets/images/products/placeholders/canned_goods.png', 'assets/images/products/placeholders/canned_goods.png', 'Mega Sardines Tomato Sauce 155g Bundle Pack 113 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000113');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000114', 6)), '4800000000114', 'Diatabs Capsule Family Pack 114', 'diatabs capsule family pack 114', 'Diatabs',
       (SELECT id FROM product_categories WHERE name='Medicine'),
       (SELECT id FROM business_types WHERE name='Pharmacy'),
       (SELECT id FROM units WHERE name='capsule'),
       9.02, 11.00, 52, 52, 10, 'assets/images/products/placeholders/medicine.png', 'assets/images/products/placeholders/medicine.png', 'Diatabs Capsule Family Pack 114 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000114');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000115', 6)), '4800000000115', 'Argentina Corned Beef 150g Family Pack 115', 'argentina corned beef 150g family pack 115', 'Argentina',
       (SELECT id FROM product_categories WHERE name='Canned Goods'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='can'),
       39.36, 48.00, 107, 107, 5, 'assets/images/products/placeholders/canned_goods.png', 'assets/images/products/placeholders/canned_goods.png', 'Argentina Corned Beef 150g Family Pack 115 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000115');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000116', 6)), '4800000000116', 'Century Tuna Flakes in Oil 155g Regular Pack 116', 'century tuna flakes in oil 155g regular pack 116', 'Century',
       (SELECT id FROM product_categories WHERE name='Canned Goods'),
       (SELECT id FROM business_types WHERE name='Grocery'),
       (SELECT id FROM units WHERE name='can'),
       37.72, 46.00, 48, 48, 5, 'assets/images/products/placeholders/canned_goods.png', 'assets/images/products/placeholders/canned_goods.png', 'Century Tuna Flakes in Oil 155g Regular Pack 116 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000116');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000117', 6)), '4800000000117', 'Joy Dishwashing Liquid 20ml Promo Pack 117', 'joy dishwashing liquid 20ml promo pack 117', 'Joy',
       (SELECT id FROM product_categories WHERE name='Cleaning Supplies'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='sachet'),
       4.92, 6.00, 36, 36, 5, 'assets/images/products/placeholders/cleaning_supplies.png', 'assets/images/products/placeholders/cleaning_supplies.png', 'Joy Dishwashing Liquid 20ml Promo Pack 117 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000117');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000118', 6)), '4800000000118', 'Argentina Corned Beef 150g Promo Pack 118', 'argentina corned beef 150g promo pack 118', 'Argentina',
       (SELECT id FROM product_categories WHERE name='Canned Goods'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='can'),
       40.18, 49.00, 100, 100, 10, 'assets/images/products/placeholders/canned_goods.png', 'assets/images/products/placeholders/canned_goods.png', 'Argentina Corned Beef 150g Promo Pack 118 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000118');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000119', 6)), '4800000000119', 'Argentina Corned Beef 150g Bundle Pack 119', 'argentina corned beef 150g bundle pack 119', 'Argentina',
       (SELECT id FROM product_categories WHERE name='Canned Goods'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='can'),
       32.8, 40.00, 89, 89, 10, 'assets/images/products/placeholders/canned_goods.png', 'assets/images/products/placeholders/canned_goods.png', 'Argentina Corned Beef 150g Bundle Pack 119 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000119');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000120', 6)), '4800000000120', 'Great Taste White 30g Bundle Pack 120', 'great taste white 30g bundle pack 120', 'Great Taste',
       (SELECT id FROM product_categories WHERE name='Coffee'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='sachet'),
       9.02, 11.00, 106, 106, 20, 'assets/images/products/placeholders/coffee.png', 'assets/images/products/placeholders/coffee.png', 'Great Taste White 30g Bundle Pack 120 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000120');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000121', 6)), '4800000000121', 'Datu Puti Vinegar 1L Small Pack 121', 'datu puti vinegar 1l small pack 121', 'Datu Puti',
       (SELECT id FROM product_categories WHERE name='Condiments'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='bottle'),
       46.74, 57.00, 81, 81, 10, 'assets/images/products/placeholders/condiments.png', 'assets/images/products/placeholders/condiments.png', 'Datu Puti Vinegar 1L Small Pack 121 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000121');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000122', 6)), '4800000000122', 'Nescafe Classic Sachet 2g Bundle Pack 122', 'nescafe classic sachet 2g bundle pack 122', 'Nescafe',
       (SELECT id FROM product_categories WHERE name='Coffee'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='sachet'),
       2.46, 3.00, 63, 63, 15, 'assets/images/products/placeholders/coffee.png', 'assets/images/products/placeholders/coffee.png', 'Nescafe Classic Sachet 2g Bundle Pack 122 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000122');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000123', 6)), '4800000000123', 'Young''s Town Sardines 155g Promo Pack 123', 'young s town sardines 155g promo pack 123', 'Young''s Town',
       (SELECT id FROM product_categories WHERE name='Canned Goods'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='can'),
       21.32, 26.00, 55, 55, 20, 'assets/images/products/placeholders/canned_goods.png', 'assets/images/products/placeholders/canned_goods.png', 'Young''s Town Sardines 155g Promo Pack 123 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000123');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000124', 6)), '4800000000124', 'Bond Paper Long 10pcs Family Pack 124', 'bond paper long 10pcs family pack 124', 'Generic',
       (SELECT id FROM product_categories WHERE name='School Supplies'),
       (SELECT id FROM business_types WHERE name='School Supplies'),
       (SELECT id FROM units WHERE name='pack'),
       11.48, 14.00, 40, 40, 20, 'assets/images/products/placeholders/school_supplies.png', 'assets/images/products/placeholders/school_supplies.png', 'Bond Paper Long 10pcs Family Pack 124 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000124');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000125', 6)), '4800000000125', 'Nova Multigrain Snacks 40g Family Pack 125', 'nova multigrain snacks 40g family pack 125', 'Nova',
       (SELECT id FROM product_categories WHERE name='Snacks'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='pack'),
       21.32, 26.00, 44, 44, 15, 'assets/images/products/placeholders/snacks.png', 'assets/images/products/placeholders/snacks.png', 'Nova Multigrain Snacks 40g Family Pack 125 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000125');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000126', 6)), '4800000000126', 'Cobra Energy Drink 350ml Family Pack 126', 'cobra energy drink 350ml family pack 126', 'Cobra',
       (SELECT id FROM product_categories WHERE name='Beverages'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='bottle'),
       26.24, 32.00, 115, 115, 10, 'assets/images/products/placeholders/beverages.png', 'assets/images/products/placeholders/beverages.png', 'Cobra Energy Drink 350ml Family Pack 126 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000126');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000127', 6)), '4800000000127', 'Rebisco Crackers Regular Pack 127', 'rebisco crackers regular pack 127', 'Rebisco',
       (SELECT id FROM product_categories WHERE name='Biscuits'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='pack'),
       7.38, 9.00, 94, 94, 5, 'assets/images/products/placeholders/biscuits.png', 'assets/images/products/placeholders/biscuits.png', 'Rebisco Crackers Regular Pack 127 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000127');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000128', 6)), '4800000000128', 'Payless Xtra Big Pancit Canton Regular Pack 128', 'payless xtra big pancit canton regular pack 128', 'Payless',
       (SELECT id FROM product_categories WHERE name='Noodles'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='pack'),
       13.12, 16.00, 62, 62, 15, 'assets/images/products/placeholders/noodles.png', 'assets/images/products/placeholders/noodles.png', 'Payless Xtra Big Pancit Canton Regular Pack 128 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000128');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000129', 6)), '4800000000129', 'Ballpen Black Bundle Pack 129', 'ballpen black bundle pack 129', 'Generic',
       (SELECT id FROM product_categories WHERE name='School Supplies'),
       (SELECT id FROM business_types WHERE name='School Supplies'),
       (SELECT id FROM units WHERE name='piece'),
       9.84, 12.00, 70, 70, 15, 'assets/images/products/placeholders/school_supplies.png', 'assets/images/products/placeholders/school_supplies.png', 'Ballpen Black Bundle Pack 129 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000129');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000130', 6)), '4800000000130', 'Century Tuna Flakes in Oil 155g Bundle Pack 130', 'century tuna flakes in oil 155g bundle pack 130', 'Century',
       (SELECT id FROM product_categories WHERE name='Canned Goods'),
       (SELECT id FROM business_types WHERE name='Grocery'),
       (SELECT id FROM units WHERE name='can'),
       39.36, 48.00, 33, 33, 20, 'assets/images/products/placeholders/canned_goods.png', 'assets/images/products/placeholders/canned_goods.png', 'Century Tuna Flakes in Oil 155g Bundle Pack 130 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000130');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000131', 6)), '4800000000131', 'Rice Regular per kilo Promo Pack 131', 'rice regular per kilo promo pack 131', 'Generic',
       (SELECT id FROM product_categories WHERE name='Rice'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='kg'),
       58.22, 71.00, 59, 59, 20, 'assets/images/products/placeholders/rice.png', 'assets/images/products/placeholders/rice.png', 'Rice Regular per kilo Promo Pack 131 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000131');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000132', 6)), '4800000000132', 'Silver Swan Soy Sauce 1L Regular Pack 132', 'silver swan soy sauce 1l regular pack 132', 'Silver Swan',
       (SELECT id FROM product_categories WHERE name='Condiments'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='bottle'),
       54.94, 67.00, 43, 43, 20, 'assets/images/products/placeholders/condiments.png', 'assets/images/products/placeholders/condiments.png', 'Silver Swan Soy Sauce 1L Regular Pack 132 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000132');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000133', 6)), '4800000000133', 'C2 Green Tea 500ml Small Pack 133', 'c2 green tea 500ml small pack 133', 'C2',
       (SELECT id FROM product_categories WHERE name='Beverages'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='bottle'),
       31.16, 38.00, 94, 94, 15, 'assets/images/products/placeholders/beverages.png', 'assets/images/products/placeholders/beverages.png', 'C2 Green Tea 500ml Small Pack 133 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000133');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000134', 6)), '4800000000134', 'Ballpen Black Bundle Pack 134', 'ballpen black bundle pack 134', 'Generic',
       (SELECT id FROM product_categories WHERE name='School Supplies'),
       (SELECT id FROM business_types WHERE name='School Supplies'),
       (SELECT id FROM units WHERE name='piece'),
       9.84, 12.00, 27, 27, 15, 'assets/images/products/placeholders/school_supplies.png', 'assets/images/products/placeholders/school_supplies.png', 'Ballpen Black Bundle Pack 134 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000134');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000135', 6)), '4800000000135', 'Sugar White per kilo Promo Pack 135', 'sugar white per kilo promo pack 135', 'Generic',
       (SELECT id FROM product_categories WHERE name='Sugar'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='kg'),
       84.46, 103.00, 97, 97, 20, 'assets/images/products/placeholders/sugar.png', 'assets/images/products/placeholders/sugar.png', 'Sugar White per kilo Promo Pack 135 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000135');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000136', 6)), '4800000000136', 'Sprite 1.5L Family Pack 136', 'sprite 1 5l family pack 136', 'Sprite',
       (SELECT id FROM product_categories WHERE name='Beverages'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='bottle'),
       72.16, 88.00, 39, 39, 15, 'assets/images/products/placeholders/beverages.png', 'assets/images/products/placeholders/beverages.png', 'Sprite 1.5L Family Pack 136 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000136');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000137', 6)), '4800000000137', 'Argentina Corned Beef 150g Bundle Pack 137', 'argentina corned beef 150g bundle pack 137', 'Argentina',
       (SELECT id FROM product_categories WHERE name='Canned Goods'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='can'),
       35.26, 43.00, 109, 109, 5, 'assets/images/products/placeholders/canned_goods.png', 'assets/images/products/placeholders/canned_goods.png', 'Argentina Corned Beef 150g Bundle Pack 137 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000137');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000138', 6)), '4800000000138', 'Neozep Forte Regular Pack 138', 'neozep forte regular pack 138', 'Neozep',
       (SELECT id FROM product_categories WHERE name='Medicine'),
       (SELECT id FROM business_types WHERE name='Pharmacy'),
       (SELECT id FROM units WHERE name='tablet'),
       6.56, 8.00, 78, 78, 20, 'assets/images/products/placeholders/medicine.png', 'assets/images/products/placeholders/medicine.png', 'Neozep Forte Regular Pack 138 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000138');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000139', 6)), '4800000000139', 'Ariel Powder Detergent 70g Bundle Pack 139', 'ariel powder detergent 70g bundle pack 139', 'Ariel',
       (SELECT id FROM product_categories WHERE name='Detergent'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='sachet'),
       9.02, 11.00, 26, 26, 10, 'assets/images/products/placeholders/detergent.png', 'assets/images/products/placeholders/detergent.png', 'Ariel Powder Detergent 70g Bundle Pack 139 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000139');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000140', 6)), '4800000000140', 'Nova Multigrain Snacks 40g Promo Pack 140', 'nova multigrain snacks 40g promo pack 140', 'Nova',
       (SELECT id FROM product_categories WHERE name='Snacks'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='pack'),
       13.94, 17.00, 45, 45, 20, 'assets/images/products/placeholders/snacks.png', 'assets/images/products/placeholders/snacks.png', 'Nova Multigrain Snacks 40g Promo Pack 140 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000140');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000141', 6)), '4800000000141', 'Cooking Oil 1L Promo Pack 141', 'cooking oil 1l promo pack 141', 'Generic',
       (SELECT id FROM product_categories WHERE name='Cooking Oil'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='liter'),
       72.98, 89.00, 94, 94, 5, 'assets/images/products/placeholders/cooking_oil.png', 'assets/images/products/placeholders/cooking_oil.png', 'Cooking Oil 1L Promo Pack 141 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000141');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000142', 6)), '4800000000142', 'Lucky Me Beef Noodles 55g Bundle Pack 142', 'lucky me beef noodles 55g bundle pack 142', 'Lucky Me',
       (SELECT id FROM product_categories WHERE name='Noodles'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='pack'),
       14.76, 18.00, 117, 117, 20, 'assets/images/products/placeholders/noodles.png', 'assets/images/products/placeholders/noodles.png', 'Lucky Me Beef Noodles 55g Bundle Pack 142 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000142');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000143', 6)), '4800000000143', 'Nescafe Classic Sachet 2g Bundle Pack 143', 'nescafe classic sachet 2g bundle pack 143', 'Nescafe',
       (SELECT id FROM product_categories WHERE name='Coffee'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='sachet'),
       2.46, 3.00, 61, 61, 10, 'assets/images/products/placeholders/coffee.png', 'assets/images/products/placeholders/coffee.png', 'Nescafe Classic Sachet 2g Bundle Pack 143 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000143');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000144', 6)), '4800000000144', 'Sprite 1.5L Family Pack 144', 'sprite 1 5l family pack 144', 'Sprite',
       (SELECT id FROM product_categories WHERE name='Beverages'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='bottle'),
       59.86, 73.00, 74, 74, 10, 'assets/images/products/placeholders/beverages.png', 'assets/images/products/placeholders/beverages.png', 'Sprite 1.5L Family Pack 144 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000144');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000145', 6)), '4800000000145', 'Young''s Town Sardines 155g Promo Pack 145', 'young s town sardines 155g promo pack 145', 'Young''s Town',
       (SELECT id FROM product_categories WHERE name='Canned Goods'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='can'),
       22.96, 28.00, 89, 89, 15, 'assets/images/products/placeholders/canned_goods.png', 'assets/images/products/placeholders/canned_goods.png', 'Young''s Town Sardines 155g Promo Pack 145 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000145');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000146', 6)), '4800000000146', 'Common Nails 1kg Small Pack 146', 'common nails 1kg small pack 146', 'Generic',
       (SELECT id FROM product_categories WHERE name='Hardware'),
       (SELECT id FROM business_types WHERE name='Hardware'),
       (SELECT id FROM units WHERE name='kg'),
       100.04, 122.00, 18, 18, 15, 'assets/images/products/placeholders/hardware.png', 'assets/images/products/placeholders/hardware.png', 'Common Nails 1kg Small Pack 146 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000146');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000147', 6)), '4800000000147', 'Piattos Cheese 40g Family Pack 147', 'piattos cheese 40g family pack 147', 'Piattos',
       (SELECT id FROM product_categories WHERE name='Snacks'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='pack'),
       14.76, 18.00, 116, 116, 15, 'assets/images/products/placeholders/snacks.png', 'assets/images/products/placeholders/snacks.png', 'Piattos Cheese 40g Family Pack 147 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000147');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000148', 6)), '4800000000148', 'Century Tuna Flakes in Oil 155g Promo Pack 148', 'century tuna flakes in oil 155g promo pack 148', 'Century',
       (SELECT id FROM product_categories WHERE name='Canned Goods'),
       (SELECT id FROM business_types WHERE name='Grocery'),
       (SELECT id FROM units WHERE name='can'),
       36.08, 44.00, 80, 80, 15, 'assets/images/products/placeholders/canned_goods.png', 'assets/images/products/placeholders/canned_goods.png', 'Century Tuna Flakes in Oil 155g Promo Pack 148 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000148');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000149', 6)), '4800000000149', 'Bear Brand Powdered Milk 33g Family Pack 149', 'bear brand powdered milk 33g family pack 149', 'Bear Brand',
       (SELECT id FROM product_categories WHERE name='Milk'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='sachet'),
       14.76, 18.00, 65, 65, 5, 'assets/images/products/placeholders/milk.png', 'assets/images/products/placeholders/milk.png', 'Bear Brand Powdered Milk 33g Family Pack 149 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000149');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000150', 6)), '4800000000150', 'Fita Crackers Small Pack 150', 'fita crackers small pack 150', 'Fita',
       (SELECT id FROM product_categories WHERE name='Biscuits'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='pack'),
       7.38, 9.00, 28, 28, 20, 'assets/images/products/placeholders/biscuits.png', 'assets/images/products/placeholders/biscuits.png', 'Fita Crackers Small Pack 150 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000150');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000151', 6)), '4800000000151', 'Neozep Forte Bundle Pack 151', 'neozep forte bundle pack 151', 'Neozep',
       (SELECT id FROM product_categories WHERE name='Medicine'),
       (SELECT id FROM business_types WHERE name='Pharmacy'),
       (SELECT id FROM units WHERE name='tablet'),
       7.38, 9.00, 32, 32, 5, 'assets/images/products/placeholders/medicine.png', 'assets/images/products/placeholders/medicine.png', 'Neozep Forte Bundle Pack 151 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000151');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000152', 6)), '4800000000152', 'Nova Multigrain Snacks 40g Promo Pack 152', 'nova multigrain snacks 40g promo pack 152', 'Nova',
       (SELECT id FROM product_categories WHERE name='Snacks'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='pack'),
       20.5, 25.00, 17, 17, 20, 'assets/images/products/placeholders/snacks.png', 'assets/images/products/placeholders/snacks.png', 'Nova Multigrain Snacks 40g Promo Pack 152 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000152');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000153', 6)), '4800000000153', 'Lucky Me Pancit Canton Kalamansi 60g Regular Pack 153', 'lucky me pancit canton kalamansi 60g regular pack 153', 'Lucky Me',
       (SELECT id FROM product_categories WHERE name='Noodles'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='pack'),
       15.58, 19.00, 32, 32, 5, 'assets/images/products/placeholders/noodles.png', 'assets/images/products/placeholders/noodles.png', 'Lucky Me Pancit Canton Kalamansi 60g Regular Pack 153 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000153');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000154', 6)), '4800000000154', 'Century Tuna Flakes in Oil 155g Small Pack 154', 'century tuna flakes in oil 155g small pack 154', 'Century',
       (SELECT id FROM product_categories WHERE name='Canned Goods'),
       (SELECT id FROM business_types WHERE name='Grocery'),
       (SELECT id FROM units WHERE name='can'),
       45.92, 56.00, 44, 44, 10, 'assets/images/products/placeholders/canned_goods.png', 'assets/images/products/placeholders/canned_goods.png', 'Century Tuna Flakes in Oil 155g Small Pack 154 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000154');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000155', 6)), '4800000000155', 'Tide Detergent Bar Small Pack 155', 'tide detergent bar small pack 155', 'Tide',
       (SELECT id FROM product_categories WHERE name='Detergent'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='piece'),
       16.4, 20.00, 41, 41, 15, 'assets/images/products/placeholders/detergent.png', 'assets/images/products/placeholders/detergent.png', 'Tide Detergent Bar Small Pack 155 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000155');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000156', 6)), '4800000000156', 'Tide Detergent Bar Family Pack 156', 'tide detergent bar family pack 156', 'Tide',
       (SELECT id FROM product_categories WHERE name='Detergent'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='piece'),
       13.94, 17.00, 35, 35, 5, 'assets/images/products/placeholders/detergent.png', 'assets/images/products/placeholders/detergent.png', 'Tide Detergent Bar Family Pack 156 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000156');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000157', 6)), '4800000000157', 'Payless Xtra Big Pancit Canton Regular Pack 157', 'payless xtra big pancit canton regular pack 157', 'Payless',
       (SELECT id FROM product_categories WHERE name='Noodles'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='pack'),
       16.4, 20.00, 30, 30, 20, 'assets/images/products/placeholders/noodles.png', 'assets/images/products/placeholders/noodles.png', 'Payless Xtra Big Pancit Canton Regular Pack 157 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000157');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000158', 6)), '4800000000158', 'Nescafe Classic Sachet 2g Family Pack 158', 'nescafe classic sachet 2g family pack 158', 'Nescafe',
       (SELECT id FROM product_categories WHERE name='Coffee'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='sachet'),
       3.28, 4.00, 58, 58, 15, 'assets/images/products/placeholders/coffee.png', 'assets/images/products/placeholders/coffee.png', 'Nescafe Classic Sachet 2g Family Pack 158 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000158');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000159', 6)), '4800000000159', 'Nescafe Classic Sachet 2g Family Pack 159', 'nescafe classic sachet 2g family pack 159', 'Nescafe',
       (SELECT id FROM product_categories WHERE name='Coffee'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='sachet'),
       3.28, 4.00, 100, 100, 5, 'assets/images/products/placeholders/coffee.png', 'assets/images/products/placeholders/coffee.png', 'Nescafe Classic Sachet 2g Family Pack 159 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000159');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000160', 6)), '4800000000160', 'Palmolive Shampoo Sachet Family Pack 160', 'palmolive shampoo sachet family pack 160', 'Palmolive',
       (SELECT id FROM product_categories WHERE name='Shampoo'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='sachet'),
       8.2, 10.00, 64, 64, 10, 'assets/images/products/placeholders/shampoo.png', 'assets/images/products/placeholders/shampoo.png', 'Palmolive Shampoo Sachet Family Pack 160 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000160');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000161', 6)), '4800000000161', 'Head & Shoulders Sachet Bundle Pack 161', 'head shoulders sachet bundle pack 161', 'Head & Shoulders',
       (SELECT id FROM product_categories WHERE name='Shampoo'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='sachet'),
       9.84, 12.00, 109, 109, 15, 'assets/images/products/placeholders/shampoo.png', 'assets/images/products/placeholders/shampoo.png', 'Head & Shoulders Sachet Bundle Pack 161 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000161');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000162', 6)), '4800000000162', 'Great Taste White 30g Promo Pack 162', 'great taste white 30g promo pack 162', 'Great Taste',
       (SELECT id FROM product_categories WHERE name='Coffee'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='sachet'),
       10.66, 13.00, 86, 86, 5, 'assets/images/products/placeholders/coffee.png', 'assets/images/products/placeholders/coffee.png', 'Great Taste White 30g Promo Pack 162 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000162');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000163', 6)), '4800000000163', 'Biogesic 500mg Family Pack 163', 'biogesic 500mg family pack 163', 'Biogesic',
       (SELECT id FROM product_categories WHERE name='Medicine'),
       (SELECT id FROM business_types WHERE name='Pharmacy'),
       (SELECT id FROM units WHERE name='tablet'),
       6.56, 8.00, 99, 99, 5, 'assets/images/products/placeholders/medicine.png', 'assets/images/products/placeholders/medicine.png', 'Biogesic 500mg Family Pack 163 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000163');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000164', 6)), '4800000000164', 'Nescafe Classic Sachet 2g Promo Pack 164', 'nescafe classic sachet 2g promo pack 164', 'Nescafe',
       (SELECT id FROM product_categories WHERE name='Coffee'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='sachet'),
       3.28, 4.00, 34, 34, 15, 'assets/images/products/placeholders/coffee.png', 'assets/images/products/placeholders/coffee.png', 'Nescafe Classic Sachet 2g Promo Pack 164 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000164');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000165', 6)), '4800000000165', 'Coca-Cola 1.5L Regular Pack 165', 'coca cola 1 5l regular pack 165', 'Coca-Cola',
       (SELECT id FROM product_categories WHERE name='Beverages'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='bottle'),
       62.32, 76.00, 54, 54, 20, 'assets/images/products/placeholders/beverages.png', 'assets/images/products/placeholders/beverages.png', 'Coca-Cola 1.5L Regular Pack 165 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000165');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000166', 6)), '4800000000166', 'Kopiko Brown Coffee Twin Pack Small Pack 166', 'kopiko brown coffee twin pack small pack 166', 'Kopiko',
       (SELECT id FROM product_categories WHERE name='Coffee'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='pack'),
       11.48, 14.00, 22, 22, 10, 'assets/images/products/placeholders/coffee.png', 'assets/images/products/placeholders/coffee.png', 'Kopiko Brown Coffee Twin Pack Small Pack 166 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000166');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000167', 6)), '4800000000167', 'Ariel Powder Detergent 70g Promo Pack 167', 'ariel powder detergent 70g promo pack 167', 'Ariel',
       (SELECT id FROM product_categories WHERE name='Detergent'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='sachet'),
       7.38, 9.00, 90, 90, 5, 'assets/images/products/placeholders/detergent.png', 'assets/images/products/placeholders/detergent.png', 'Ariel Powder Detergent 70g Promo Pack 167 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000167');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000168', 6)), '4800000000168', 'Sugar White per kilo Regular Pack 168', 'sugar white per kilo regular pack 168', 'Generic',
       (SELECT id FROM product_categories WHERE name='Sugar'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='kg'),
       88.56, 108.00, 43, 43, 10, 'assets/images/products/placeholders/sugar.png', 'assets/images/products/placeholders/sugar.png', 'Sugar White per kilo Regular Pack 168 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000168');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000169', 6)), '4800000000169', 'Notebook 80 Leaves Promo Pack 169', 'notebook 80 leaves promo pack 169', 'Generic',
       (SELECT id FROM product_categories WHERE name='School Supplies'),
       (SELECT id FROM business_types WHERE name='School Supplies'),
       (SELECT id FROM units WHERE name='piece'),
       19.68, 24.00, 67, 67, 10, 'assets/images/products/placeholders/school_supplies.png', 'assets/images/products/placeholders/school_supplies.png', 'Notebook 80 Leaves Promo Pack 169 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000169');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000170', 6)), '4800000000170', 'Nissin Cup Noodles Beef Promo Pack 170', 'nissin cup noodles beef promo pack 170', 'Nissin',
       (SELECT id FROM product_categories WHERE name='Noodles'),
       (SELECT id FROM business_types WHERE name='Grocery'),
       (SELECT id FROM units WHERE name='piece'),
       27.06, 33.00, 119, 119, 15, 'assets/images/products/placeholders/noodles.png', 'assets/images/products/placeholders/noodles.png', 'Nissin Cup Noodles Beef Promo Pack 170 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000170');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000171', 6)), '4800000000171', 'Lucky Me Beef Noodles 55g Small Pack 171', 'lucky me beef noodles 55g small pack 171', 'Lucky Me',
       (SELECT id FROM product_categories WHERE name='Noodles'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='pack'),
       12.3, 15.00, 41, 41, 5, 'assets/images/products/placeholders/noodles.png', 'assets/images/products/placeholders/noodles.png', 'Lucky Me Beef Noodles 55g Small Pack 171 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000171');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000172', 6)), '4800000000172', 'Ballpen Black Regular Pack 172', 'ballpen black regular pack 172', 'Generic',
       (SELECT id FROM product_categories WHERE name='School Supplies'),
       (SELECT id FROM business_types WHERE name='School Supplies'),
       (SELECT id FROM units WHERE name='piece'),
       7.38, 9.00, 78, 78, 20, 'assets/images/products/placeholders/school_supplies.png', 'assets/images/products/placeholders/school_supplies.png', 'Ballpen Black Regular Pack 172 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000172');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000173', 6)), '4800000000173', 'Kopiko Brown Coffee Twin Pack Small Pack 173', 'kopiko brown coffee twin pack small pack 173', 'Kopiko',
       (SELECT id FROM product_categories WHERE name='Coffee'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='pack'),
       15.58, 19.00, 19, 19, 15, 'assets/images/products/placeholders/coffee.png', 'assets/images/products/placeholders/coffee.png', 'Kopiko Brown Coffee Twin Pack Small Pack 173 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000173');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000174', 6)), '4800000000174', 'Safeguard Soap 60g Family Pack 174', 'safeguard soap 60g family pack 174', 'Safeguard',
       (SELECT id FROM product_categories WHERE name='Soap'),
       (SELECT id FROM business_types WHERE name='Grocery'),
       (SELECT id FROM units WHERE name='piece'),
       20.5, 25.00, 24, 24, 20, 'assets/images/products/placeholders/soap.png', 'assets/images/products/placeholders/soap.png', 'Safeguard Soap 60g Family Pack 174 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000174');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000175', 6)), '4800000000175', 'Alaska Evaporada 370ml Small Pack 175', 'alaska evaporada 370ml small pack 175', 'Alaska',
       (SELECT id FROM product_categories WHERE name='Milk'),
       (SELECT id FROM business_types WHERE name='Grocery'),
       (SELECT id FROM units WHERE name='can'),
       28.7, 35.00, 46, 46, 10, 'assets/images/products/placeholders/milk.png', 'assets/images/products/placeholders/milk.png', 'Alaska Evaporada 370ml Small Pack 175 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000175');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000176', 6)), '4800000000176', 'Silver Swan Soy Sauce 1L Bundle Pack 176', 'silver swan soy sauce 1l bundle pack 176', 'Silver Swan',
       (SELECT id FROM product_categories WHERE name='Condiments'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='bottle'),
       59.04, 72.00, 70, 70, 15, 'assets/images/products/placeholders/condiments.png', 'assets/images/products/placeholders/condiments.png', 'Silver Swan Soy Sauce 1L Bundle Pack 176 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000176');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000177', 6)), '4800000000177', 'Silver Swan Soy Sauce 1L Promo Pack 177', 'silver swan soy sauce 1l promo pack 177', 'Silver Swan',
       (SELECT id FROM product_categories WHERE name='Condiments'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='bottle'),
       45.92, 56.00, 97, 97, 20, 'assets/images/products/placeholders/condiments.png', 'assets/images/products/placeholders/condiments.png', 'Silver Swan Soy Sauce 1L Promo Pack 177 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000177');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000178', 6)), '4800000000178', 'Joy Dishwashing Liquid 20ml Bundle Pack 178', 'joy dishwashing liquid 20ml bundle pack 178', 'Joy',
       (SELECT id FROM product_categories WHERE name='Cleaning Supplies'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='sachet'),
       6.56, 8.00, 28, 28, 20, 'assets/images/products/placeholders/cleaning_supplies.png', 'assets/images/products/placeholders/cleaning_supplies.png', 'Joy Dishwashing Liquid 20ml Bundle Pack 178 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000178');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000179', 6)), '4800000000179', 'Piattos Cheese 40g Small Pack 179', 'piattos cheese 40g small pack 179', 'Piattos',
       (SELECT id FROM product_categories WHERE name='Snacks'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='pack'),
       17.22, 21.00, 58, 58, 10, 'assets/images/products/placeholders/snacks.png', 'assets/images/products/placeholders/snacks.png', 'Piattos Cheese 40g Small Pack 179 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000179');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000180', 6)), '4800000000180', 'Lucky Me Beef Noodles 55g Regular Pack 180', 'lucky me beef noodles 55g regular pack 180', 'Lucky Me',
       (SELECT id FROM product_categories WHERE name='Noodles'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='pack'),
       13.12, 16.00, 90, 90, 20, 'assets/images/products/placeholders/noodles.png', 'assets/images/products/placeholders/noodles.png', 'Lucky Me Beef Noodles 55g Regular Pack 180 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000180');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000181', 6)), '4800000000181', 'Notebook 80 Leaves Regular Pack 181', 'notebook 80 leaves regular pack 181', 'Generic',
       (SELECT id FROM product_categories WHERE name='School Supplies'),
       (SELECT id FROM business_types WHERE name='School Supplies'),
       (SELECT id FROM units WHERE name='piece'),
       19.68, 24.00, 32, 32, 10, 'assets/images/products/placeholders/school_supplies.png', 'assets/images/products/placeholders/school_supplies.png', 'Notebook 80 Leaves Regular Pack 181 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000181');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000182', 6)), '4800000000182', 'Young''s Town Sardines 155g Promo Pack 182', 'young s town sardines 155g promo pack 182', 'Young''s Town',
       (SELECT id FROM product_categories WHERE name='Canned Goods'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='can'),
       22.14, 27.00, 58, 58, 15, 'assets/images/products/placeholders/canned_goods.png', 'assets/images/products/placeholders/canned_goods.png', 'Young''s Town Sardines 155g Promo Pack 182 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000182');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000183', 6)), '4800000000183', 'Nissin Cup Noodles Beef Regular Pack 183', 'nissin cup noodles beef regular pack 183', 'Nissin',
       (SELECT id FROM product_categories WHERE name='Noodles'),
       (SELECT id FROM business_types WHERE name='Grocery'),
       (SELECT id FROM units WHERE name='piece'),
       27.88, 34.00, 34, 34, 5, 'assets/images/products/placeholders/noodles.png', 'assets/images/products/placeholders/noodles.png', 'Nissin Cup Noodles Beef Regular Pack 183 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000183');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000184', 6)), '4800000000184', 'Rice Regular per kilo Bundle Pack 184', 'rice regular per kilo bundle pack 184', 'Generic',
       (SELECT id FROM product_categories WHERE name='Rice'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='kg'),
       60.68, 74.00, 76, 76, 10, 'assets/images/products/placeholders/rice.png', 'assets/images/products/placeholders/rice.png', 'Rice Regular per kilo Bundle Pack 184 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000184');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000185', 6)), '4800000000185', 'Great Taste White 30g Small Pack 185', 'great taste white 30g small pack 185', 'Great Taste',
       (SELECT id FROM product_categories WHERE name='Coffee'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='sachet'),
       10.66, 13.00, 24, 24, 10, 'assets/images/products/placeholders/coffee.png', 'assets/images/products/placeholders/coffee.png', 'Great Taste White 30g Small Pack 185 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000185');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000186', 6)), '4800000000186', 'Kopiko Brown Coffee Twin Pack Family Pack 186', 'kopiko brown coffee twin pack family pack 186', 'Kopiko',
       (SELECT id FROM product_categories WHERE name='Coffee'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='pack'),
       16.4, 20.00, 35, 35, 10, 'assets/images/products/placeholders/coffee.png', 'assets/images/products/placeholders/coffee.png', 'Kopiko Brown Coffee Twin Pack Family Pack 186 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000186');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000187', 6)), '4800000000187', 'Great Taste White 30g Regular Pack 187', 'great taste white 30g regular pack 187', 'Great Taste',
       (SELECT id FROM product_categories WHERE name='Coffee'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='sachet'),
       11.48, 14.00, 84, 84, 10, 'assets/images/products/placeholders/coffee.png', 'assets/images/products/placeholders/coffee.png', 'Great Taste White 30g Regular Pack 187 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000187');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000188', 6)), '4800000000188', 'Biogesic 500mg Small Pack 188', 'biogesic 500mg small pack 188', 'Biogesic',
       (SELECT id FROM product_categories WHERE name='Medicine'),
       (SELECT id FROM business_types WHERE name='Pharmacy'),
       (SELECT id FROM units WHERE name='tablet'),
       4.92, 6.00, 51, 51, 20, 'assets/images/products/placeholders/medicine.png', 'assets/images/products/placeholders/medicine.png', 'Biogesic 500mg Small Pack 188 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000188');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000189', 6)), '4800000000189', 'Milo Sachet 24g Regular Pack 189', 'milo sachet 24g regular pack 189', 'Milo',
       (SELECT id FROM product_categories WHERE name='Milk'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='sachet'),
       12.3, 15.00, 116, 116, 10, 'assets/images/products/placeholders/milk.png', 'assets/images/products/placeholders/milk.png', 'Milo Sachet 24g Regular Pack 189 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000189');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000190', 6)), '4800000000190', 'Biogesic 500mg Regular Pack 190', 'biogesic 500mg regular pack 190', 'Biogesic',
       (SELECT id FROM product_categories WHERE name='Medicine'),
       (SELECT id FROM business_types WHERE name='Pharmacy'),
       (SELECT id FROM units WHERE name='tablet'),
       7.38, 9.00, 99, 99, 20, 'assets/images/products/placeholders/medicine.png', 'assets/images/products/placeholders/medicine.png', 'Biogesic 500mg Regular Pack 190 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000190');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000191', 6)), '4800000000191', 'SkyFlakes Crackers Promo Pack 191', 'skyflakes crackers promo pack 191', 'SkyFlakes',
       (SELECT id FROM product_categories WHERE name='Biscuits'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='pack'),
       8.2, 10.00, 53, 53, 10, 'assets/images/products/placeholders/biscuits.png', 'assets/images/products/placeholders/biscuits.png', 'SkyFlakes Crackers Promo Pack 191 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000191');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000192', 6)), '4800000000192', 'Piattos Cheese 40g Small Pack 192', 'piattos cheese 40g small pack 192', 'Piattos',
       (SELECT id FROM product_categories WHERE name='Snacks'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='pack'),
       18.04, 22.00, 78, 78, 15, 'assets/images/products/placeholders/snacks.png', 'assets/images/products/placeholders/snacks.png', 'Piattos Cheese 40g Small Pack 192 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000192');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000193', 6)), '4800000000193', 'Mega Sardines Tomato Sauce 155g Family Pack 193', 'mega sardines tomato sauce 155g family pack 193', 'Mega',
       (SELECT id FROM product_categories WHERE name='Canned Goods'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='can'),
       19.68, 24.00, 29, 29, 10, 'assets/images/products/placeholders/canned_goods.png', 'assets/images/products/placeholders/canned_goods.png', 'Mega Sardines Tomato Sauce 155g Family Pack 193 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000193');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000194', 6)), '4800000000194', 'Electrical Tape Family Pack 194', 'electrical tape family pack 194', 'Generic',
       (SELECT id FROM product_categories WHERE name='Hardware'),
       (SELECT id FROM business_types WHERE name='Hardware'),
       (SELECT id FROM units WHERE name='roll'),
       19.68, 24.00, 98, 98, 20, 'assets/images/products/placeholders/hardware.png', 'assets/images/products/placeholders/hardware.png', 'Electrical Tape Family Pack 194 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000194');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000195', 6)), '4800000000195', 'Electrical Tape Family Pack 195', 'electrical tape family pack 195', 'Generic',
       (SELECT id FROM product_categories WHERE name='Hardware'),
       (SELECT id FROM business_types WHERE name='Hardware'),
       (SELECT id FROM units WHERE name='roll'),
       24.6, 30.00, 47, 47, 15, 'assets/images/products/placeholders/hardware.png', 'assets/images/products/placeholders/hardware.png', 'Electrical Tape Family Pack 195 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000195');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000196', 6)), '4800000000196', 'Diatabs Capsule Promo Pack 196', 'diatabs capsule promo pack 196', 'Diatabs',
       (SELECT id FROM product_categories WHERE name='Medicine'),
       (SELECT id FROM business_types WHERE name='Pharmacy'),
       (SELECT id FROM units WHERE name='capsule'),
       8.2, 10.00, 23, 23, 5, 'assets/images/products/placeholders/medicine.png', 'assets/images/products/placeholders/medicine.png', 'Diatabs Capsule Promo Pack 196 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000196');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000197', 6)), '4800000000197', 'Sugar White per kilo Bundle Pack 197', 'sugar white per kilo bundle pack 197', 'Generic',
       (SELECT id FROM product_categories WHERE name='Sugar'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='kg'),
       72.16, 88.00, 56, 56, 10, 'assets/images/products/placeholders/sugar.png', 'assets/images/products/placeholders/sugar.png', 'Sugar White per kilo Bundle Pack 197 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000197');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000198', 6)), '4800000000198', 'Royal Tru Orange 1.5L Family Pack 198', 'royal tru orange 1 5l family pack 198', 'Royal',
       (SELECT id FROM product_categories WHERE name='Beverages'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='bottle'),
       54.12, 66.00, 90, 90, 20, 'assets/images/products/placeholders/beverages.png', 'assets/images/products/placeholders/beverages.png', 'Royal Tru Orange 1.5L Family Pack 198 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000198');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000199', 6)), '4800000000199', 'Notebook 80 Leaves Regular Pack 199', 'notebook 80 leaves regular pack 199', 'Generic',
       (SELECT id FROM product_categories WHERE name='School Supplies'),
       (SELECT id FROM business_types WHERE name='School Supplies'),
       (SELECT id FROM units WHERE name='piece'),
       27.06, 33.00, 74, 74, 15, 'assets/images/products/placeholders/school_supplies.png', 'assets/images/products/placeholders/school_supplies.png', 'Notebook 80 Leaves Regular Pack 199 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000199');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000200', 6)), '4800000000200', 'Bear Brand Powdered Milk 33g Regular Pack 200', 'bear brand powdered milk 33g regular pack 200', 'Bear Brand',
       (SELECT id FROM product_categories WHERE name='Milk'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='sachet'),
       13.94, 17.00, 31, 31, 15, 'assets/images/products/placeholders/milk.png', 'assets/images/products/placeholders/milk.png', 'Bear Brand Powdered Milk 33g Regular Pack 200 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000200');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000201', 6)), '4800000000201', 'Young''s Town Sardines 155g Small Pack 201', 'young s town sardines 155g small pack 201', 'Young''s Town',
       (SELECT id FROM product_categories WHERE name='Canned Goods'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='can'),
       22.96, 28.00, 36, 36, 20, 'assets/images/products/placeholders/canned_goods.png', 'assets/images/products/placeholders/canned_goods.png', 'Young''s Town Sardines 155g Small Pack 201 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000201');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000202', 6)), '4800000000202', 'Common Nails 1kg Promo Pack 202', 'common nails 1kg promo pack 202', 'Generic',
       (SELECT id FROM product_categories WHERE name='Hardware'),
       (SELECT id FROM business_types WHERE name='Hardware'),
       (SELECT id FROM units WHERE name='kg'),
       72.98, 89.00, 35, 35, 5, 'assets/images/products/placeholders/hardware.png', 'assets/images/products/placeholders/hardware.png', 'Common Nails 1kg Promo Pack 202 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000202');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000203', 6)), '4800000000203', 'Tide Detergent Bar Small Pack 203', 'tide detergent bar small pack 203', 'Tide',
       (SELECT id FROM product_categories WHERE name='Detergent'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='piece'),
       11.48, 14.00, 104, 104, 10, 'assets/images/products/placeholders/detergent.png', 'assets/images/products/placeholders/detergent.png', 'Tide Detergent Bar Small Pack 203 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000203');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000204', 6)), '4800000000204', 'Chippy BBQ 110g Promo Pack 204', 'chippy bbq 110g promo pack 204', 'Chippy',
       (SELECT id FROM product_categories WHERE name='Snacks'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='pack'),
       29.52, 36.00, 102, 102, 15, 'assets/images/products/placeholders/snacks.png', 'assets/images/products/placeholders/snacks.png', 'Chippy BBQ 110g Promo Pack 204 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000204');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000205', 6)), '4800000000205', 'Lucky Me Beef Noodles 55g Regular Pack 205', 'lucky me beef noodles 55g regular pack 205', 'Lucky Me',
       (SELECT id FROM product_categories WHERE name='Noodles'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='pack'),
       12.3, 15.00, 19, 19, 10, 'assets/images/products/placeholders/noodles.png', 'assets/images/products/placeholders/noodles.png', 'Lucky Me Beef Noodles 55g Regular Pack 205 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000205');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000206', 6)), '4800000000206', 'Cobra Energy Drink 350ml Promo Pack 206', 'cobra energy drink 350ml promo pack 206', 'Cobra',
       (SELECT id FROM product_categories WHERE name='Beverages'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='bottle'),
       17.22, 21.00, 33, 33, 15, 'assets/images/products/placeholders/beverages.png', 'assets/images/products/placeholders/beverages.png', 'Cobra Energy Drink 350ml Promo Pack 206 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000206');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000207', 6)), '4800000000207', 'Safeguard Soap 60g Bundle Pack 207', 'safeguard soap 60g bundle pack 207', 'Safeguard',
       (SELECT id FROM product_categories WHERE name='Soap'),
       (SELECT id FROM business_types WHERE name='Grocery'),
       (SELECT id FROM units WHERE name='piece'),
       25.42, 31.00, 100, 100, 10, 'assets/images/products/placeholders/soap.png', 'assets/images/products/placeholders/soap.png', 'Safeguard Soap 60g Bundle Pack 207 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000207');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000208', 6)), '4800000000208', 'Notebook 80 Leaves Bundle Pack 208', 'notebook 80 leaves bundle pack 208', 'Generic',
       (SELECT id FROM product_categories WHERE name='School Supplies'),
       (SELECT id FROM business_types WHERE name='School Supplies'),
       (SELECT id FROM units WHERE name='piece'),
       18.04, 22.00, 96, 96, 15, 'assets/images/products/placeholders/school_supplies.png', 'assets/images/products/placeholders/school_supplies.png', 'Notebook 80 Leaves Bundle Pack 208 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000208');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000209', 6)), '4800000000209', 'Datu Puti Vinegar 1L Small Pack 209', 'datu puti vinegar 1l small pack 209', 'Datu Puti',
       (SELECT id FROM product_categories WHERE name='Condiments'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='bottle'),
       46.74, 57.00, 38, 38, 15, 'assets/images/products/placeholders/condiments.png', 'assets/images/products/placeholders/condiments.png', 'Datu Puti Vinegar 1L Small Pack 209 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000209');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000210', 6)), '4800000000210', 'Ballpen Black Promo Pack 210', 'ballpen black promo pack 210', 'Generic',
       (SELECT id FROM product_categories WHERE name='School Supplies'),
       (SELECT id FROM business_types WHERE name='School Supplies'),
       (SELECT id FROM units WHERE name='piece'),
       9.84, 12.00, 67, 67, 10, 'assets/images/products/placeholders/school_supplies.png', 'assets/images/products/placeholders/school_supplies.png', 'Ballpen Black Promo Pack 210 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000210');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000211', 6)), '4800000000211', 'Century Tuna Flakes in Oil 155g Bundle Pack 211', 'century tuna flakes in oil 155g bundle pack 211', 'Century',
       (SELECT id FROM product_categories WHERE name='Canned Goods'),
       (SELECT id FROM business_types WHERE name='Grocery'),
       (SELECT id FROM units WHERE name='can'),
       46.74, 57.00, 28, 28, 15, 'assets/images/products/placeholders/canned_goods.png', 'assets/images/products/placeholders/canned_goods.png', 'Century Tuna Flakes in Oil 155g Bundle Pack 211 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000211');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000212', 6)), '4800000000212', 'Tide Detergent Bar Bundle Pack 212', 'tide detergent bar bundle pack 212', 'Tide',
       (SELECT id FROM product_categories WHERE name='Detergent'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='piece'),
       15.58, 19.00, 36, 36, 15, 'assets/images/products/placeholders/detergent.png', 'assets/images/products/placeholders/detergent.png', 'Tide Detergent Bar Bundle Pack 212 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000212');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000213', 6)), '4800000000213', 'Coca-Cola 1.5L Small Pack 213', 'coca cola 1 5l small pack 213', 'Coca-Cola',
       (SELECT id FROM product_categories WHERE name='Beverages'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='bottle'),
       61.5, 75.00, 27, 27, 10, 'assets/images/products/placeholders/beverages.png', 'assets/images/products/placeholders/beverages.png', 'Coca-Cola 1.5L Small Pack 213 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000213');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000214', 6)), '4800000000214', 'Bear Brand Powdered Milk 33g Promo Pack 214', 'bear brand powdered milk 33g promo pack 214', 'Bear Brand',
       (SELECT id FROM product_categories WHERE name='Milk'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='sachet'),
       12.3, 15.00, 51, 51, 20, 'assets/images/products/placeholders/milk.png', 'assets/images/products/placeholders/milk.png', 'Bear Brand Powdered Milk 33g Promo Pack 214 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000214');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000215', 6)), '4800000000215', 'Sunsilk Shampoo Sachet Small Pack 215', 'sunsilk shampoo sachet small pack 215', 'Sunsilk',
       (SELECT id FROM product_categories WHERE name='Shampoo'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='sachet'),
       8.2, 10.00, 48, 48, 15, 'assets/images/products/placeholders/shampoo.png', 'assets/images/products/placeholders/shampoo.png', 'Sunsilk Shampoo Sachet Small Pack 215 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000215');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000216', 6)), '4800000000216', 'Piattos Cheese 40g Small Pack 216', 'piattos cheese 40g small pack 216', 'Piattos',
       (SELECT id FROM product_categories WHERE name='Snacks'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='pack'),
       17.22, 21.00, 99, 99, 10, 'assets/images/products/placeholders/snacks.png', 'assets/images/products/placeholders/snacks.png', 'Piattos Cheese 40g Small Pack 216 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000216');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000217', 6)), '4800000000217', 'Young''s Town Sardines 155g Small Pack 217', 'young s town sardines 155g small pack 217', 'Young''s Town',
       (SELECT id FROM product_categories WHERE name='Canned Goods'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='can'),
       22.96, 28.00, 76, 76, 20, 'assets/images/products/placeholders/canned_goods.png', 'assets/images/products/placeholders/canned_goods.png', 'Young''s Town Sardines 155g Small Pack 217 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000217');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000218', 6)), '4800000000218', 'Mega Sardines Tomato Sauce 155g Bundle Pack 218', 'mega sardines tomato sauce 155g bundle pack 218', 'Mega',
       (SELECT id FROM product_categories WHERE name='Canned Goods'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='can'),
       18.86, 23.00, 35, 35, 15, 'assets/images/products/placeholders/canned_goods.png', 'assets/images/products/placeholders/canned_goods.png', 'Mega Sardines Tomato Sauce 155g Bundle Pack 218 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000218');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000219', 6)), '4800000000219', 'Kopiko Brown Coffee Twin Pack Family Pack 219', 'kopiko brown coffee twin pack family pack 219', 'Kopiko',
       (SELECT id FROM product_categories WHERE name='Coffee'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='pack'),
       11.48, 14.00, 61, 61, 5, 'assets/images/products/placeholders/coffee.png', 'assets/images/products/placeholders/coffee.png', 'Kopiko Brown Coffee Twin Pack Family Pack 219 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000219');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000220', 6)), '4800000000220', 'Payless Xtra Big Pancit Canton Promo Pack 220', 'payless xtra big pancit canton promo pack 220', 'Payless',
       (SELECT id FROM product_categories WHERE name='Noodles'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='pack'),
       16.4, 20.00, 74, 74, 20, 'assets/images/products/placeholders/noodles.png', 'assets/images/products/placeholders/noodles.png', 'Payless Xtra Big Pancit Canton Promo Pack 220 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000220');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000221', 6)), '4800000000221', 'Lucky Me Pancit Canton Chilimansi 60g Bundle Pack 221', 'lucky me pancit canton chilimansi 60g bundle pack 221', 'Lucky Me',
       (SELECT id FROM product_categories WHERE name='Noodles'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='pack'),
       17.22, 21.00, 30, 30, 15, 'assets/images/products/placeholders/noodles.png', 'assets/images/products/placeholders/noodles.png', 'Lucky Me Pancit Canton Chilimansi 60g Bundle Pack 221 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000221');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000222', 6)), '4800000000222', 'Rice Regular per kilo Regular Pack 222', 'rice regular per kilo regular pack 222', 'Generic',
       (SELECT id FROM product_categories WHERE name='Rice'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='kg'),
       54.94, 67.00, 25, 25, 20, 'assets/images/products/placeholders/rice.png', 'assets/images/products/placeholders/rice.png', 'Rice Regular per kilo Regular Pack 222 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000222');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000223', 6)), '4800000000223', 'Rice Regular per kilo Regular Pack 223', 'rice regular per kilo regular pack 223', 'Generic',
       (SELECT id FROM product_categories WHERE name='Rice'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='kg'),
       47.56, 58.00, 93, 93, 15, 'assets/images/products/placeholders/rice.png', 'assets/images/products/placeholders/rice.png', 'Rice Regular per kilo Regular Pack 223 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000223');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000224', 6)), '4800000000224', 'Nova Multigrain Snacks 40g Bundle Pack 224', 'nova multigrain snacks 40g bundle pack 224', 'Nova',
       (SELECT id FROM product_categories WHERE name='Snacks'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='pack'),
       21.32, 26.00, 17, 17, 5, 'assets/images/products/placeholders/snacks.png', 'assets/images/products/placeholders/snacks.png', 'Nova Multigrain Snacks 40g Bundle Pack 224 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000224');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000225', 6)), '4800000000225', '555 Sardines Tomato Sauce 155g Small Pack 225', '555 sardines tomato sauce 155g small pack 225', '555',
       (SELECT id FROM product_categories WHERE name='Canned Goods'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='can'),
       18.04, 22.00, 34, 34, 5, 'assets/images/products/placeholders/canned_goods.png', 'assets/images/products/placeholders/canned_goods.png', '555 Sardines Tomato Sauce 155g Small Pack 225 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000225');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000226', 6)), '4800000000226', 'Great Taste White 30g Bundle Pack 226', 'great taste white 30g bundle pack 226', 'Great Taste',
       (SELECT id FROM product_categories WHERE name='Coffee'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='sachet'),
       11.48, 14.00, 116, 116, 20, 'assets/images/products/placeholders/coffee.png', 'assets/images/products/placeholders/coffee.png', 'Great Taste White 30g Bundle Pack 226 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000226');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000227', 6)), '4800000000227', 'Screwdriver Flat Family Pack 227', 'screwdriver flat family pack 227', 'Generic',
       (SELECT id FROM product_categories WHERE name='Hardware'),
       (SELECT id FROM business_types WHERE name='Hardware'),
       (SELECT id FROM units WHERE name='piece'),
       48.38, 59.00, 105, 105, 5, 'assets/images/products/placeholders/hardware.png', 'assets/images/products/placeholders/hardware.png', 'Screwdriver Flat Family Pack 227 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000227');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000228', 6)), '4800000000228', 'Century Tuna Flakes in Oil 155g Small Pack 228', 'century tuna flakes in oil 155g small pack 228', 'Century',
       (SELECT id FROM product_categories WHERE name='Canned Goods'),
       (SELECT id FROM business_types WHERE name='Grocery'),
       (SELECT id FROM units WHERE name='can'),
       47.56, 58.00, 53, 53, 10, 'assets/images/products/placeholders/canned_goods.png', 'assets/images/products/placeholders/canned_goods.png', 'Century Tuna Flakes in Oil 155g Small Pack 228 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000228');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000229', 6)), '4800000000229', 'Sugar White per kilo Bundle Pack 229', 'sugar white per kilo bundle pack 229', 'Generic',
       (SELECT id FROM product_categories WHERE name='Sugar'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='kg'),
       73.8, 90.00, 43, 43, 10, 'assets/images/products/placeholders/sugar.png', 'assets/images/products/placeholders/sugar.png', 'Sugar White per kilo Bundle Pack 229 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000229');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000230', 6)), '4800000000230', 'Head & Shoulders Sachet Bundle Pack 230', 'head shoulders sachet bundle pack 230', 'Head & Shoulders',
       (SELECT id FROM product_categories WHERE name='Shampoo'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='sachet'),
       9.02, 11.00, 82, 82, 5, 'assets/images/products/placeholders/shampoo.png', 'assets/images/products/placeholders/shampoo.png', 'Head & Shoulders Sachet Bundle Pack 230 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000230');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000231', 6)), '4800000000231', 'Sprite 1.5L Family Pack 231', 'sprite 1 5l family pack 231', 'Sprite',
       (SELECT id FROM product_categories WHERE name='Beverages'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='bottle'),
       78.72, 96.00, 33, 33, 5, 'assets/images/products/placeholders/beverages.png', 'assets/images/products/placeholders/beverages.png', 'Sprite 1.5L Family Pack 231 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000231');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000232', 6)), '4800000000232', 'SkyFlakes Crackers Family Pack 232', 'skyflakes crackers family pack 232', 'SkyFlakes',
       (SELECT id FROM product_categories WHERE name='Biscuits'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='pack'),
       8.2, 10.00, 96, 96, 10, 'assets/images/products/placeholders/biscuits.png', 'assets/images/products/placeholders/biscuits.png', 'SkyFlakes Crackers Family Pack 232 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000232');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000233', 6)), '4800000000233', 'Silver Swan Soy Sauce 1L Bundle Pack 233', 'silver swan soy sauce 1l bundle pack 233', 'Silver Swan',
       (SELECT id FROM product_categories WHERE name='Condiments'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='bottle'),
       63.14, 77.00, 32, 32, 10, 'assets/images/products/placeholders/condiments.png', 'assets/images/products/placeholders/condiments.png', 'Silver Swan Soy Sauce 1L Bundle Pack 233 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000233');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000234', 6)), '4800000000234', 'Common Nails 1kg Family Pack 234', 'common nails 1kg family pack 234', 'Generic',
       (SELECT id FROM product_categories WHERE name='Hardware'),
       (SELECT id FROM business_types WHERE name='Hardware'),
       (SELECT id FROM units WHERE name='kg'),
       93.48, 114.00, 23, 23, 5, 'assets/images/products/placeholders/hardware.png', 'assets/images/products/placeholders/hardware.png', 'Common Nails 1kg Family Pack 234 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000234');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000235', 6)), '4800000000235', 'Bond Paper Long 10pcs Small Pack 235', 'bond paper long 10pcs small pack 235', 'Generic',
       (SELECT id FROM product_categories WHERE name='School Supplies'),
       (SELECT id FROM business_types WHERE name='School Supplies'),
       (SELECT id FROM units WHERE name='pack'),
       12.3, 15.00, 42, 42, 20, 'assets/images/products/placeholders/school_supplies.png', 'assets/images/products/placeholders/school_supplies.png', 'Bond Paper Long 10pcs Small Pack 235 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000235');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000236', 6)), '4800000000236', 'Young''s Town Sardines 155g Family Pack 236', 'young s town sardines 155g family pack 236', 'Young''s Town',
       (SELECT id FROM product_categories WHERE name='Canned Goods'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='can'),
       21.32, 26.00, 58, 58, 10, 'assets/images/products/placeholders/canned_goods.png', 'assets/images/products/placeholders/canned_goods.png', 'Young''s Town Sardines 155g Family Pack 236 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000236');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000237', 6)), '4800000000237', 'Joy Dishwashing Liquid 20ml Promo Pack 237', 'joy dishwashing liquid 20ml promo pack 237', 'Joy',
       (SELECT id FROM product_categories WHERE name='Cleaning Supplies'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='sachet'),
       6.56, 8.00, 120, 120, 20, 'assets/images/products/placeholders/cleaning_supplies.png', 'assets/images/products/placeholders/cleaning_supplies.png', 'Joy Dishwashing Liquid 20ml Promo Pack 237 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000237');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000238', 6)), '4800000000238', 'Alaxan FR Capsule Bundle Pack 238', 'alaxan fr capsule bundle pack 238', 'Alaxan',
       (SELECT id FROM product_categories WHERE name='Medicine'),
       (SELECT id FROM business_types WHERE name='Pharmacy'),
       (SELECT id FROM units WHERE name='capsule'),
       10.66, 13.00, 77, 77, 20, 'assets/images/products/placeholders/medicine.png', 'assets/images/products/placeholders/medicine.png', 'Alaxan FR Capsule Bundle Pack 238 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000238');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000239', 6)), '4800000000239', 'Sunsilk Shampoo Sachet Promo Pack 239', 'sunsilk shampoo sachet promo pack 239', 'Sunsilk',
       (SELECT id FROM product_categories WHERE name='Shampoo'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='sachet'),
       9.02, 11.00, 86, 86, 15, 'assets/images/products/placeholders/shampoo.png', 'assets/images/products/placeholders/shampoo.png', 'Sunsilk Shampoo Sachet Promo Pack 239 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000239');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000240', 6)), '4800000000240', 'Lucky Me Beef Noodles 55g Regular Pack 240', 'lucky me beef noodles 55g regular pack 240', 'Lucky Me',
       (SELECT id FROM product_categories WHERE name='Noodles'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='pack'),
       11.48, 14.00, 56, 56, 10, 'assets/images/products/placeholders/noodles.png', 'assets/images/products/placeholders/noodles.png', 'Lucky Me Beef Noodles 55g Regular Pack 240 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000240');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000241', 6)), '4800000000241', '555 Sardines Tomato Sauce 155g Regular Pack 241', '555 sardines tomato sauce 155g regular pack 241', '555',
       (SELECT id FROM product_categories WHERE name='Canned Goods'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='can'),
       19.68, 24.00, 117, 117, 20, 'assets/images/products/placeholders/canned_goods.png', 'assets/images/products/placeholders/canned_goods.png', '555 Sardines Tomato Sauce 155g Regular Pack 241 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000241');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000242', 6)), '4800000000242', 'Screwdriver Flat Family Pack 242', 'screwdriver flat family pack 242', 'Generic',
       (SELECT id FROM product_categories WHERE name='Hardware'),
       (SELECT id FROM business_types WHERE name='Hardware'),
       (SELECT id FROM units WHERE name='piece'),
       53.3, 65.00, 20, 20, 10, 'assets/images/products/placeholders/hardware.png', 'assets/images/products/placeholders/hardware.png', 'Screwdriver Flat Family Pack 242 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000242');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000243', 6)), '4800000000243', 'Common Nails 1kg Promo Pack 243', 'common nails 1kg promo pack 243', 'Generic',
       (SELECT id FROM product_categories WHERE name='Hardware'),
       (SELECT id FROM business_types WHERE name='Hardware'),
       (SELECT id FROM units WHERE name='kg'),
       101.68, 124.00, 77, 77, 20, 'assets/images/products/placeholders/hardware.png', 'assets/images/products/placeholders/hardware.png', 'Common Nails 1kg Promo Pack 243 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000243');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000244', 6)), '4800000000244', 'Fita Crackers Regular Pack 244', 'fita crackers regular pack 244', 'Fita',
       (SELECT id FROM product_categories WHERE name='Biscuits'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='pack'),
       6.56, 8.00, 40, 40, 20, 'assets/images/products/placeholders/biscuits.png', 'assets/images/products/placeholders/biscuits.png', 'Fita Crackers Regular Pack 244 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000244');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000245', 6)), '4800000000245', 'Diatabs Capsule Bundle Pack 245', 'diatabs capsule bundle pack 245', 'Diatabs',
       (SELECT id FROM product_categories WHERE name='Medicine'),
       (SELECT id FROM business_types WHERE name='Pharmacy'),
       (SELECT id FROM units WHERE name='capsule'),
       11.48, 14.00, 70, 70, 20, 'assets/images/products/placeholders/medicine.png', 'assets/images/products/placeholders/medicine.png', 'Diatabs Capsule Bundle Pack 245 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000245');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000246', 6)), '4800000000246', 'Argentina Corned Beef 150g Bundle Pack 246', 'argentina corned beef 150g bundle pack 246', 'Argentina',
       (SELECT id FROM product_categories WHERE name='Canned Goods'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='can'),
       39.36, 48.00, 16, 16, 15, 'assets/images/products/placeholders/canned_goods.png', 'assets/images/products/placeholders/canned_goods.png', 'Argentina Corned Beef 150g Bundle Pack 246 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000246');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000247', 6)), '4800000000247', 'Ballpen Black Promo Pack 247', 'ballpen black promo pack 247', 'Generic',
       (SELECT id FROM product_categories WHERE name='School Supplies'),
       (SELECT id FROM business_types WHERE name='School Supplies'),
       (SELECT id FROM units WHERE name='piece'),
       10.66, 13.00, 37, 37, 15, 'assets/images/products/placeholders/school_supplies.png', 'assets/images/products/placeholders/school_supplies.png', 'Ballpen Black Promo Pack 247 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000247');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000248', 6)), '4800000000248', 'C2 Green Tea 500ml Regular Pack 248', 'c2 green tea 500ml regular pack 248', 'C2',
       (SELECT id FROM product_categories WHERE name='Beverages'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='bottle'),
       32.8, 40.00, 119, 119, 20, 'assets/images/products/placeholders/beverages.png', 'assets/images/products/placeholders/beverages.png', 'C2 Green Tea 500ml Regular Pack 248 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000248');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000249', 6)), '4800000000249', 'Common Nails 1kg Bundle Pack 249', 'common nails 1kg bundle pack 249', 'Generic',
       (SELECT id FROM product_categories WHERE name='Hardware'),
       (SELECT id FROM business_types WHERE name='Hardware'),
       (SELECT id FROM units WHERE name='kg'),
       66.42, 81.00, 94, 94, 20, 'assets/images/products/placeholders/hardware.png', 'assets/images/products/placeholders/hardware.png', 'Common Nails 1kg Bundle Pack 249 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000249');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000250', 6)), '4800000000250', 'Pencil No.2 Bundle Pack 250', 'pencil no 2 bundle pack 250', 'Generic',
       (SELECT id FROM product_categories WHERE name='School Supplies'),
       (SELECT id FROM business_types WHERE name='School Supplies'),
       (SELECT id FROM units WHERE name='piece'),
       9.02, 11.00, 61, 61, 5, 'assets/images/products/placeholders/school_supplies.png', 'assets/images/products/placeholders/school_supplies.png', 'Pencil No.2 Bundle Pack 250 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000250');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000251', 6)), '4800000000251', 'Bond Paper Short 10pcs Promo Pack 251', 'bond paper short 10pcs promo pack 251', 'Generic',
       (SELECT id FROM product_categories WHERE name='School Supplies'),
       (SELECT id FROM business_types WHERE name='School Supplies'),
       (SELECT id FROM units WHERE name='pack'),
       10.66, 13.00, 26, 26, 15, 'assets/images/products/placeholders/school_supplies.png', 'assets/images/products/placeholders/school_supplies.png', 'Bond Paper Short 10pcs Promo Pack 251 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000251');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000252', 6)), '4800000000252', 'Biogesic 500mg Bundle Pack 252', 'biogesic 500mg bundle pack 252', 'Biogesic',
       (SELECT id FROM product_categories WHERE name='Medicine'),
       (SELECT id FROM business_types WHERE name='Pharmacy'),
       (SELECT id FROM units WHERE name='tablet'),
       7.38, 9.00, 48, 48, 15, 'assets/images/products/placeholders/medicine.png', 'assets/images/products/placeholders/medicine.png', 'Biogesic 500mg Bundle Pack 252 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000252');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000253', 6)), '4800000000253', 'Lucky Me Pancit Canton Kalamansi 60g Small Pack 253', 'lucky me pancit canton kalamansi 60g small pack 253', 'Lucky Me',
       (SELECT id FROM product_categories WHERE name='Noodles'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='pack'),
       11.48, 14.00, 35, 35, 15, 'assets/images/products/placeholders/noodles.png', 'assets/images/products/placeholders/noodles.png', 'Lucky Me Pancit Canton Kalamansi 60g Small Pack 253 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000253');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000254', 6)), '4800000000254', '555 Sardines Tomato Sauce 155g Bundle Pack 254', '555 sardines tomato sauce 155g bundle pack 254', '555',
       (SELECT id FROM product_categories WHERE name='Canned Goods'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='can'),
       18.86, 23.00, 40, 40, 5, 'assets/images/products/placeholders/canned_goods.png', 'assets/images/products/placeholders/canned_goods.png', '555 Sardines Tomato Sauce 155g Bundle Pack 254 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000254');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000255', 6)), '4800000000255', 'Lucky Me Beef Noodles 55g Family Pack 255', 'lucky me beef noodles 55g family pack 255', 'Lucky Me',
       (SELECT id FROM product_categories WHERE name='Noodles'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='pack'),
       15.58, 19.00, 119, 119, 10, 'assets/images/products/placeholders/noodles.png', 'assets/images/products/placeholders/noodles.png', 'Lucky Me Beef Noodles 55g Family Pack 255 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000255');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000256', 6)), '4800000000256', 'Century Tuna Flakes in Oil 155g Regular Pack 256', 'century tuna flakes in oil 155g regular pack 256', 'Century',
       (SELECT id FROM product_categories WHERE name='Canned Goods'),
       (SELECT id FROM business_types WHERE name='Grocery'),
       (SELECT id FROM units WHERE name='can'),
       32.8, 40.00, 56, 56, 20, 'assets/images/products/placeholders/canned_goods.png', 'assets/images/products/placeholders/canned_goods.png', 'Century Tuna Flakes in Oil 155g Regular Pack 256 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000256');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000257', 6)), '4800000000257', 'Alaska Evaporada 370ml Small Pack 257', 'alaska evaporada 370ml small pack 257', 'Alaska',
       (SELECT id FROM product_categories WHERE name='Milk'),
       (SELECT id FROM business_types WHERE name='Grocery'),
       (SELECT id FROM units WHERE name='can'),
       31.98, 39.00, 16, 16, 10, 'assets/images/products/placeholders/milk.png', 'assets/images/products/placeholders/milk.png', 'Alaska Evaporada 370ml Small Pack 257 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000257');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000258', 6)), '4800000000258', 'Alaxan FR Capsule Bundle Pack 258', 'alaxan fr capsule bundle pack 258', 'Alaxan',
       (SELECT id FROM product_categories WHERE name='Medicine'),
       (SELECT id FROM business_types WHERE name='Pharmacy'),
       (SELECT id FROM units WHERE name='capsule'),
       10.66, 13.00, 63, 63, 10, 'assets/images/products/placeholders/medicine.png', 'assets/images/products/placeholders/medicine.png', 'Alaxan FR Capsule Bundle Pack 258 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000258');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000259', 6)), '4800000000259', 'Great Taste White 30g Bundle Pack 259', 'great taste white 30g bundle pack 259', 'Great Taste',
       (SELECT id FROM product_categories WHERE name='Coffee'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='sachet'),
       9.02, 11.00, 105, 105, 20, 'assets/images/products/placeholders/coffee.png', 'assets/images/products/placeholders/coffee.png', 'Great Taste White 30g Bundle Pack 259 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000259');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000260', 6)), '4800000000260', 'Pencil No.2 Family Pack 260', 'pencil no 2 family pack 260', 'Generic',
       (SELECT id FROM product_categories WHERE name='School Supplies'),
       (SELECT id FROM business_types WHERE name='School Supplies'),
       (SELECT id FROM units WHERE name='piece'),
       8.2, 10.00, 115, 115, 5, 'assets/images/products/placeholders/school_supplies.png', 'assets/images/products/placeholders/school_supplies.png', 'Pencil No.2 Family Pack 260 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000260');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000261', 6)), '4800000000261', 'Milo Sachet 24g Promo Pack 261', 'milo sachet 24g promo pack 261', 'Milo',
       (SELECT id FROM product_categories WHERE name='Milk'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='sachet'),
       9.84, 12.00, 52, 52, 5, 'assets/images/products/placeholders/milk.png', 'assets/images/products/placeholders/milk.png', 'Milo Sachet 24g Promo Pack 261 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000261');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000262', 6)), '4800000000262', 'Silver Swan Soy Sauce 1L Regular Pack 262', 'silver swan soy sauce 1l regular pack 262', 'Silver Swan',
       (SELECT id FROM product_categories WHERE name='Condiments'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='bottle'),
       51.66, 63.00, 109, 109, 5, 'assets/images/products/placeholders/condiments.png', 'assets/images/products/placeholders/condiments.png', 'Silver Swan Soy Sauce 1L Regular Pack 262 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000262');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000263', 6)), '4800000000263', '555 Sardines Tomato Sauce 155g Family Pack 263', '555 sardines tomato sauce 155g family pack 263', '555',
       (SELECT id FROM product_categories WHERE name='Canned Goods'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='can'),
       19.68, 24.00, 35, 35, 5, 'assets/images/products/placeholders/canned_goods.png', 'assets/images/products/placeholders/canned_goods.png', '555 Sardines Tomato Sauce 155g Family Pack 263 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000263');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000264', 6)), '4800000000264', 'Coca-Cola 1.5L Regular Pack 264', 'coca cola 1 5l regular pack 264', 'Coca-Cola',
       (SELECT id FROM product_categories WHERE name='Beverages'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='bottle'),
       58.22, 71.00, 73, 73, 5, 'assets/images/products/placeholders/beverages.png', 'assets/images/products/placeholders/beverages.png', 'Coca-Cola 1.5L Regular Pack 264 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000264');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000265', 6)), '4800000000265', 'Screwdriver Flat Regular Pack 265', 'screwdriver flat regular pack 265', 'Generic',
       (SELECT id FROM product_categories WHERE name='Hardware'),
       (SELECT id FROM business_types WHERE name='Hardware'),
       (SELECT id FROM units WHERE name='piece'),
       61.5, 75.00, 52, 52, 5, 'assets/images/products/placeholders/hardware.png', 'assets/images/products/placeholders/hardware.png', 'Screwdriver Flat Regular Pack 265 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000265');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000266', 6)), '4800000000266', '555 Sardines Tomato Sauce 155g Small Pack 266', '555 sardines tomato sauce 155g small pack 266', '555',
       (SELECT id FROM product_categories WHERE name='Canned Goods'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='can'),
       22.96, 28.00, 115, 115, 15, 'assets/images/products/placeholders/canned_goods.png', 'assets/images/products/placeholders/canned_goods.png', '555 Sardines Tomato Sauce 155g Small Pack 266 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000266');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000267', 6)), '4800000000267', 'SkyFlakes Crackers Family Pack 267', 'skyflakes crackers family pack 267', 'SkyFlakes',
       (SELECT id FROM product_categories WHERE name='Biscuits'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='pack'),
       7.38, 9.00, 87, 87, 15, 'assets/images/products/placeholders/biscuits.png', 'assets/images/products/placeholders/biscuits.png', 'SkyFlakes Crackers Family Pack 267 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000267');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000268', 6)), '4800000000268', 'Nissin Cup Noodles Beef Regular Pack 268', 'nissin cup noodles beef regular pack 268', 'Nissin',
       (SELECT id FROM product_categories WHERE name='Noodles'),
       (SELECT id FROM business_types WHERE name='Grocery'),
       (SELECT id FROM units WHERE name='piece'),
       30.34, 37.00, 41, 41, 20, 'assets/images/products/placeholders/noodles.png', 'assets/images/products/placeholders/noodles.png', 'Nissin Cup Noodles Beef Regular Pack 268 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000268');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000269', 6)), '4800000000269', 'Tide Detergent Bar Regular Pack 269', 'tide detergent bar regular pack 269', 'Tide',
       (SELECT id FROM product_categories WHERE name='Detergent'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='piece'),
       14.76, 18.00, 62, 62, 5, 'assets/images/products/placeholders/detergent.png', 'assets/images/products/placeholders/detergent.png', 'Tide Detergent Bar Regular Pack 269 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000269');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000270', 6)), '4800000000270', 'Piattos Cheese 40g Bundle Pack 270', 'piattos cheese 40g bundle pack 270', 'Piattos',
       (SELECT id FROM product_categories WHERE name='Snacks'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='pack'),
       15.58, 19.00, 111, 111, 10, 'assets/images/products/placeholders/snacks.png', 'assets/images/products/placeholders/snacks.png', 'Piattos Cheese 40g Bundle Pack 270 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000270');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000271', 6)), '4800000000271', 'Payless Xtra Big Pancit Canton Regular Pack 271', 'payless xtra big pancit canton regular pack 271', 'Payless',
       (SELECT id FROM product_categories WHERE name='Noodles'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='pack'),
       12.3, 15.00, 84, 84, 15, 'assets/images/products/placeholders/noodles.png', 'assets/images/products/placeholders/noodles.png', 'Payless Xtra Big Pancit Canton Regular Pack 271 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000271');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000272', 6)), '4800000000272', 'Century Tuna Flakes in Oil 155g Regular Pack 272', 'century tuna flakes in oil 155g regular pack 272', 'Century',
       (SELECT id FROM product_categories WHERE name='Canned Goods'),
       (SELECT id FROM business_types WHERE name='Grocery'),
       (SELECT id FROM units WHERE name='can'),
       43.46, 53.00, 44, 44, 20, 'assets/images/products/placeholders/canned_goods.png', 'assets/images/products/placeholders/canned_goods.png', 'Century Tuna Flakes in Oil 155g Regular Pack 272 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000272');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000273', 6)), '4800000000273', 'Payless Xtra Big Pancit Canton Promo Pack 273', 'payless xtra big pancit canton promo pack 273', 'Payless',
       (SELECT id FROM product_categories WHERE name='Noodles'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='pack'),
       16.4, 20.00, 56, 56, 20, 'assets/images/products/placeholders/noodles.png', 'assets/images/products/placeholders/noodles.png', 'Payless Xtra Big Pancit Canton Promo Pack 273 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000273');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000274', 6)), '4800000000274', 'Chippy BBQ 110g Promo Pack 274', 'chippy bbq 110g promo pack 274', 'Chippy',
       (SELECT id FROM product_categories WHERE name='Snacks'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='pack'),
       27.06, 33.00, 78, 78, 20, 'assets/images/products/placeholders/snacks.png', 'assets/images/products/placeholders/snacks.png', 'Chippy BBQ 110g Promo Pack 274 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000274');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000275', 6)), '4800000000275', 'Argentina Corned Beef 150g Family Pack 275', 'argentina corned beef 150g family pack 275', 'Argentina',
       (SELECT id FROM product_categories WHERE name='Canned Goods'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='can'),
       41.0, 50.00, 107, 107, 15, 'assets/images/products/placeholders/canned_goods.png', 'assets/images/products/placeholders/canned_goods.png', 'Argentina Corned Beef 150g Family Pack 275 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000275');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000276', 6)), '4800000000276', 'Cobra Energy Drink 350ml Small Pack 276', 'cobra energy drink 350ml small pack 276', 'Cobra',
       (SELECT id FROM product_categories WHERE name='Beverages'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='bottle'),
       21.32, 26.00, 37, 37, 15, 'assets/images/products/placeholders/beverages.png', 'assets/images/products/placeholders/beverages.png', 'Cobra Energy Drink 350ml Small Pack 276 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000276');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000277', 6)), '4800000000277', 'Great Taste White 30g Family Pack 277', 'great taste white 30g family pack 277', 'Great Taste',
       (SELECT id FROM product_categories WHERE name='Coffee'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='sachet'),
       10.66, 13.00, 29, 29, 15, 'assets/images/products/placeholders/coffee.png', 'assets/images/products/placeholders/coffee.png', 'Great Taste White 30g Family Pack 277 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000277');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000278', 6)), '4800000000278', 'Ballpen Black Bundle Pack 278', 'ballpen black bundle pack 278', 'Generic',
       (SELECT id FROM product_categories WHERE name='School Supplies'),
       (SELECT id FROM business_types WHERE name='School Supplies'),
       (SELECT id FROM units WHERE name='piece'),
       10.66, 13.00, 36, 36, 15, 'assets/images/products/placeholders/school_supplies.png', 'assets/images/products/placeholders/school_supplies.png', 'Ballpen Black Bundle Pack 278 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000278');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000279', 6)), '4800000000279', 'Argentina Corned Beef 150g Small Pack 279', 'argentina corned beef 150g small pack 279', 'Argentina',
       (SELECT id FROM product_categories WHERE name='Canned Goods'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='can'),
       31.16, 38.00, 52, 52, 10, 'assets/images/products/placeholders/canned_goods.png', 'assets/images/products/placeholders/canned_goods.png', 'Argentina Corned Beef 150g Small Pack 279 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000279');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000280', 6)), '4800000000280', 'Screwdriver Flat Small Pack 280', 'screwdriver flat small pack 280', 'Generic',
       (SELECT id FROM product_categories WHERE name='Hardware'),
       (SELECT id FROM business_types WHERE name='Hardware'),
       (SELECT id FROM units WHERE name='piece'),
       59.86, 73.00, 97, 97, 5, 'assets/images/products/placeholders/hardware.png', 'assets/images/products/placeholders/hardware.png', 'Screwdriver Flat Small Pack 280 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000280');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000281', 6)), '4800000000281', 'Cooking Oil 1L Bundle Pack 281', 'cooking oil 1l bundle pack 281', 'Generic',
       (SELECT id FROM product_categories WHERE name='Cooking Oil'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='liter'),
       82.0, 100.00, 97, 97, 20, 'assets/images/products/placeholders/cooking_oil.png', 'assets/images/products/placeholders/cooking_oil.png', 'Cooking Oil 1L Bundle Pack 281 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000281');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000282', 6)), '4800000000282', 'Sprite 1.5L Bundle Pack 282', 'sprite 1 5l bundle pack 282', 'Sprite',
       (SELECT id FROM product_categories WHERE name='Beverages'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='bottle'),
       52.48, 64.00, 99, 99, 10, 'assets/images/products/placeholders/beverages.png', 'assets/images/products/placeholders/beverages.png', 'Sprite 1.5L Bundle Pack 282 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000282');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000283', 6)), '4800000000283', 'Alaxan FR Capsule Family Pack 283', 'alaxan fr capsule family pack 283', 'Alaxan',
       (SELECT id FROM product_categories WHERE name='Medicine'),
       (SELECT id FROM business_types WHERE name='Pharmacy'),
       (SELECT id FROM units WHERE name='capsule'),
       7.38, 9.00, 53, 53, 15, 'assets/images/products/placeholders/medicine.png', 'assets/images/products/placeholders/medicine.png', 'Alaxan FR Capsule Family Pack 283 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000283');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000284', 6)), '4800000000284', 'Bond Paper Long 10pcs Small Pack 284', 'bond paper long 10pcs small pack 284', 'Generic',
       (SELECT id FROM product_categories WHERE name='School Supplies'),
       (SELECT id FROM business_types WHERE name='School Supplies'),
       (SELECT id FROM units WHERE name='pack'),
       11.48, 14.00, 100, 100, 5, 'assets/images/products/placeholders/school_supplies.png', 'assets/images/products/placeholders/school_supplies.png', 'Bond Paper Long 10pcs Small Pack 284 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000284');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000285', 6)), '4800000000285', 'Sugar White per kilo Family Pack 285', 'sugar white per kilo family pack 285', 'Generic',
       (SELECT id FROM product_categories WHERE name='Sugar'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='kg'),
       71.34, 87.00, 78, 78, 15, 'assets/images/products/placeholders/sugar.png', 'assets/images/products/placeholders/sugar.png', 'Sugar White per kilo Family Pack 285 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000285');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000286', 6)), '4800000000286', 'Lucky Me Pancit Canton Kalamansi 60g Bundle Pack 286', 'lucky me pancit canton kalamansi 60g bundle pack 286', 'Lucky Me',
       (SELECT id FROM product_categories WHERE name='Noodles'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='pack'),
       11.48, 14.00, 28, 28, 10, 'assets/images/products/placeholders/noodles.png', 'assets/images/products/placeholders/noodles.png', 'Lucky Me Pancit Canton Kalamansi 60g Bundle Pack 286 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000286');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000287', 6)), '4800000000287', 'Screwdriver Flat Small Pack 287', 'screwdriver flat small pack 287', 'Generic',
       (SELECT id FROM product_categories WHERE name='Hardware'),
       (SELECT id FROM business_types WHERE name='Hardware'),
       (SELECT id FROM units WHERE name='piece'),
       52.48, 64.00, 108, 108, 20, 'assets/images/products/placeholders/hardware.png', 'assets/images/products/placeholders/hardware.png', 'Screwdriver Flat Small Pack 287 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000287');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000288', 6)), '4800000000288', 'Datu Puti Vinegar 1L Promo Pack 288', 'datu puti vinegar 1l promo pack 288', 'Datu Puti',
       (SELECT id FROM product_categories WHERE name='Condiments'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='bottle'),
       58.22, 71.00, 29, 29, 15, 'assets/images/products/placeholders/condiments.png', 'assets/images/products/placeholders/condiments.png', 'Datu Puti Vinegar 1L Promo Pack 288 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000288');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000289', 6)), '4800000000289', 'Sprite 1.5L Regular Pack 289', 'sprite 1 5l regular pack 289', 'Sprite',
       (SELECT id FROM product_categories WHERE name='Beverages'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='bottle'),
       71.34, 87.00, 111, 111, 5, 'assets/images/products/placeholders/beverages.png', 'assets/images/products/placeholders/beverages.png', 'Sprite 1.5L Regular Pack 289 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000289');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000290', 6)), '4800000000290', 'Milo Sachet 24g Regular Pack 290', 'milo sachet 24g regular pack 290', 'Milo',
       (SELECT id FROM product_categories WHERE name='Milk'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='sachet'),
       12.3, 15.00, 90, 90, 10, 'assets/images/products/placeholders/milk.png', 'assets/images/products/placeholders/milk.png', 'Milo Sachet 24g Regular Pack 290 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000290');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000291', 6)), '4800000000291', 'Vitamin C 500mg Small Pack 291', 'vitamin c 500mg small pack 291', 'Generic',
       (SELECT id FROM product_categories WHERE name='Vitamins'),
       (SELECT id FROM business_types WHERE name='Pharmacy'),
       (SELECT id FROM units WHERE name='tablet'),
       4.1, 5.00, 29, 29, 5, 'assets/images/products/placeholders/vitamins.png', 'assets/images/products/placeholders/vitamins.png', 'Vitamin C 500mg Small Pack 291 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000291');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000292', 6)), '4800000000292', 'Datu Puti Vinegar 1L Promo Pack 292', 'datu puti vinegar 1l promo pack 292', 'Datu Puti',
       (SELECT id FROM product_categories WHERE name='Condiments'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='bottle'),
       63.14, 77.00, 114, 114, 5, 'assets/images/products/placeholders/condiments.png', 'assets/images/products/placeholders/condiments.png', 'Datu Puti Vinegar 1L Promo Pack 292 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000292');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000293', 6)), '4800000000293', 'Rebisco Crackers Small Pack 293', 'rebisco crackers small pack 293', 'Rebisco',
       (SELECT id FROM product_categories WHERE name='Biscuits'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='pack'),
       6.56, 8.00, 55, 55, 20, 'assets/images/products/placeholders/biscuits.png', 'assets/images/products/placeholders/biscuits.png', 'Rebisco Crackers Small Pack 293 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000293');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000294', 6)), '4800000000294', 'Lucky Me Pancit Canton Chilimansi 60g Promo Pack 294', 'lucky me pancit canton chilimansi 60g promo pack 294', 'Lucky Me',
       (SELECT id FROM product_categories WHERE name='Noodles'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='pack'),
       12.3, 15.00, 33, 33, 15, 'assets/images/products/placeholders/noodles.png', 'assets/images/products/placeholders/noodles.png', 'Lucky Me Pancit Canton Chilimansi 60g Promo Pack 294 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000294');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000295', 6)), '4800000000295', 'Chippy BBQ 110g Promo Pack 295', 'chippy bbq 110g promo pack 295', 'Chippy',
       (SELECT id FROM product_categories WHERE name='Snacks'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='pack'),
       31.98, 39.00, 66, 66, 10, 'assets/images/products/placeholders/snacks.png', 'assets/images/products/placeholders/snacks.png', 'Chippy BBQ 110g Promo Pack 295 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000295');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000296', 6)), '4800000000296', 'Cooking Oil 1L Bundle Pack 296', 'cooking oil 1l bundle pack 296', 'Generic',
       (SELECT id FROM product_categories WHERE name='Cooking Oil'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='liter'),
       80.36, 98.00, 76, 76, 15, 'assets/images/products/placeholders/cooking_oil.png', 'assets/images/products/placeholders/cooking_oil.png', 'Cooking Oil 1L Bundle Pack 296 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000296');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000297', 6)), '4800000000297', 'Fita Crackers Regular Pack 297', 'fita crackers regular pack 297', 'Fita',
       (SELECT id FROM product_categories WHERE name='Biscuits'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='pack'),
       8.2, 10.00, 107, 107, 15, 'assets/images/products/placeholders/biscuits.png', 'assets/images/products/placeholders/biscuits.png', 'Fita Crackers Regular Pack 297 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000297');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000298', 6)), '4800000000298', 'Tide Detergent Bar Family Pack 298', 'tide detergent bar family pack 298', 'Tide',
       (SELECT id FROM product_categories WHERE name='Detergent'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='piece'),
       13.12, 16.00, 85, 85, 15, 'assets/images/products/placeholders/detergent.png', 'assets/images/products/placeholders/detergent.png', 'Tide Detergent Bar Family Pack 298 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000298');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000299', 6)), '4800000000299', 'Great Taste White 30g Regular Pack 299', 'great taste white 30g regular pack 299', 'Great Taste',
       (SELECT id FROM product_categories WHERE name='Coffee'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='sachet'),
       12.3, 15.00, 56, 56, 5, 'assets/images/products/placeholders/coffee.png', 'assets/images/products/placeholders/coffee.png', 'Great Taste White 30g Regular Pack 299 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000299');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000300', 6)), '4800000000300', 'Vitamin C 500mg Promo Pack 300', 'vitamin c 500mg promo pack 300', 'Generic',
       (SELECT id FROM product_categories WHERE name='Vitamins'),
       (SELECT id FROM business_types WHERE name='Pharmacy'),
       (SELECT id FROM units WHERE name='tablet'),
       4.1, 5.00, 57, 57, 5, 'assets/images/products/placeholders/vitamins.png', 'assets/images/products/placeholders/vitamins.png', 'Vitamin C 500mg Promo Pack 300 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000300');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000301', 6)), '4800000000301', 'Tide Detergent Bar Promo Pack 301', 'tide detergent bar promo pack 301', 'Tide',
       (SELECT id FROM product_categories WHERE name='Detergent'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='piece'),
       13.12, 16.00, 61, 61, 10, 'assets/images/products/placeholders/detergent.png', 'assets/images/products/placeholders/detergent.png', 'Tide Detergent Bar Promo Pack 301 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000301');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000302', 6)), '4800000000302', 'Hammer Small Regular Pack 302', 'hammer small regular pack 302', 'Generic',
       (SELECT id FROM product_categories WHERE name='Hardware'),
       (SELECT id FROM business_types WHERE name='Hardware'),
       (SELECT id FROM units WHERE name='piece'),
       168.92, 206.00, 113, 113, 10, 'assets/images/products/placeholders/hardware.png', 'assets/images/products/placeholders/hardware.png', 'Hammer Small Regular Pack 302 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000302');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000303', 6)), '4800000000303', 'Great Taste White 30g Regular Pack 303', 'great taste white 30g regular pack 303', 'Great Taste',
       (SELECT id FROM product_categories WHERE name='Coffee'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='sachet'),
       11.48, 14.00, 95, 95, 15, 'assets/images/products/placeholders/coffee.png', 'assets/images/products/placeholders/coffee.png', 'Great Taste White 30g Regular Pack 303 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000303');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000304', 6)), '4800000000304', 'Sunsilk Shampoo Sachet Bundle Pack 304', 'sunsilk shampoo sachet bundle pack 304', 'Sunsilk',
       (SELECT id FROM product_categories WHERE name='Shampoo'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='sachet'),
       7.38, 9.00, 93, 93, 15, 'assets/images/products/placeholders/shampoo.png', 'assets/images/products/placeholders/shampoo.png', 'Sunsilk Shampoo Sachet Bundle Pack 304 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000304');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000305', 6)), '4800000000305', 'Common Nails 1kg Regular Pack 305', 'common nails 1kg regular pack 305', 'Generic',
       (SELECT id FROM product_categories WHERE name='Hardware'),
       (SELECT id FROM business_types WHERE name='Hardware'),
       (SELECT id FROM units WHERE name='kg'),
       79.54, 97.00, 72, 72, 20, 'assets/images/products/placeholders/hardware.png', 'assets/images/products/placeholders/hardware.png', 'Common Nails 1kg Regular Pack 305 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000305');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000306', 6)), '4800000000306', 'Coca-Cola 1.5L Bundle Pack 306', 'coca cola 1 5l bundle pack 306', 'Coca-Cola',
       (SELECT id FROM product_categories WHERE name='Beverages'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='bottle'),
       78.72, 96.00, 44, 44, 20, 'assets/images/products/placeholders/beverages.png', 'assets/images/products/placeholders/beverages.png', 'Coca-Cola 1.5L Bundle Pack 306 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000306');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000307', 6)), '4800000000307', 'Joy Dishwashing Liquid 20ml Family Pack 307', 'joy dishwashing liquid 20ml family pack 307', 'Joy',
       (SELECT id FROM product_categories WHERE name='Cleaning Supplies'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='sachet'),
       5.74, 7.00, 75, 75, 15, 'assets/images/products/placeholders/cleaning_supplies.png', 'assets/images/products/placeholders/cleaning_supplies.png', 'Joy Dishwashing Liquid 20ml Family Pack 307 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000307');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000308', 6)), '4800000000308', 'Sunsilk Shampoo Sachet Family Pack 308', 'sunsilk shampoo sachet family pack 308', 'Sunsilk',
       (SELECT id FROM product_categories WHERE name='Shampoo'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='sachet'),
       6.56, 8.00, 38, 38, 20, 'assets/images/products/placeholders/shampoo.png', 'assets/images/products/placeholders/shampoo.png', 'Sunsilk Shampoo Sachet Family Pack 308 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000308');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000309', 6)), '4800000000309', 'Lucky Me Pancit Canton Chilimansi 60g Bundle Pack 309', 'lucky me pancit canton chilimansi 60g bundle pack 309', 'Lucky Me',
       (SELECT id FROM product_categories WHERE name='Noodles'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='pack'),
       13.12, 16.00, 87, 87, 20, 'assets/images/products/placeholders/noodles.png', 'assets/images/products/placeholders/noodles.png', 'Lucky Me Pancit Canton Chilimansi 60g Bundle Pack 309 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000309');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000310', 6)), '4800000000310', 'Head & Shoulders Sachet Bundle Pack 310', 'head shoulders sachet bundle pack 310', 'Head & Shoulders',
       (SELECT id FROM product_categories WHERE name='Shampoo'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='sachet'),
       6.56, 8.00, 46, 46, 10, 'assets/images/products/placeholders/shampoo.png', 'assets/images/products/placeholders/shampoo.png', 'Head & Shoulders Sachet Bundle Pack 310 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000310');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000311', 6)), '4800000000311', 'Ballpen Black Small Pack 311', 'ballpen black small pack 311', 'Generic',
       (SELECT id FROM product_categories WHERE name='School Supplies'),
       (SELECT id FROM business_types WHERE name='School Supplies'),
       (SELECT id FROM units WHERE name='piece'),
       9.84, 12.00, 94, 94, 5, 'assets/images/products/placeholders/school_supplies.png', 'assets/images/products/placeholders/school_supplies.png', 'Ballpen Black Small Pack 311 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000311');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000312', 6)), '4800000000312', 'Nescafe Classic Sachet 2g Bundle Pack 312', 'nescafe classic sachet 2g bundle pack 312', 'Nescafe',
       (SELECT id FROM product_categories WHERE name='Coffee'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='sachet'),
       2.46, 3.00, 78, 78, 10, 'assets/images/products/placeholders/coffee.png', 'assets/images/products/placeholders/coffee.png', 'Nescafe Classic Sachet 2g Bundle Pack 312 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000312');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000313', 6)), '4800000000313', 'Sugar White per kilo Family Pack 313', 'sugar white per kilo family pack 313', 'Generic',
       (SELECT id FROM product_categories WHERE name='Sugar'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='kg'),
       62.32, 76.00, 63, 63, 5, 'assets/images/products/placeholders/sugar.png', 'assets/images/products/placeholders/sugar.png', 'Sugar White per kilo Family Pack 313 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000313');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000314', 6)), '4800000000314', 'Alaxan FR Capsule Family Pack 314', 'alaxan fr capsule family pack 314', 'Alaxan',
       (SELECT id FROM product_categories WHERE name='Medicine'),
       (SELECT id FROM business_types WHERE name='Pharmacy'),
       (SELECT id FROM units WHERE name='capsule'),
       10.66, 13.00, 15, 15, 5, 'assets/images/products/placeholders/medicine.png', 'assets/images/products/placeholders/medicine.png', 'Alaxan FR Capsule Family Pack 314 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000314');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000315', 6)), '4800000000315', 'Nova Multigrain Snacks 40g Regular Pack 315', 'nova multigrain snacks 40g regular pack 315', 'Nova',
       (SELECT id FROM product_categories WHERE name='Snacks'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='pack'),
       17.22, 21.00, 25, 25, 10, 'assets/images/products/placeholders/snacks.png', 'assets/images/products/placeholders/snacks.png', 'Nova Multigrain Snacks 40g Regular Pack 315 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000315');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000316', 6)), '4800000000316', 'Bond Paper Short 10pcs Family Pack 316', 'bond paper short 10pcs family pack 316', 'Generic',
       (SELECT id FROM product_categories WHERE name='School Supplies'),
       (SELECT id FROM business_types WHERE name='School Supplies'),
       (SELECT id FROM units WHERE name='pack'),
       9.02, 11.00, 102, 102, 5, 'assets/images/products/placeholders/school_supplies.png', 'assets/images/products/placeholders/school_supplies.png', 'Bond Paper Short 10pcs Family Pack 316 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000316');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000317', 6)), '4800000000317', 'Lucky Me Pancit Canton Kalamansi 60g Bundle Pack 317', 'lucky me pancit canton kalamansi 60g bundle pack 317', 'Lucky Me',
       (SELECT id FROM product_categories WHERE name='Noodles'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='pack'),
       12.3, 15.00, 78, 78, 15, 'assets/images/products/placeholders/noodles.png', 'assets/images/products/placeholders/noodles.png', 'Lucky Me Pancit Canton Kalamansi 60g Bundle Pack 317 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000317');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000318', 6)), '4800000000318', 'Century Tuna Flakes in Oil 155g Promo Pack 318', 'century tuna flakes in oil 155g promo pack 318', 'Century',
       (SELECT id FROM product_categories WHERE name='Canned Goods'),
       (SELECT id FROM business_types WHERE name='Grocery'),
       (SELECT id FROM units WHERE name='can'),
       31.98, 39.00, 79, 79, 15, 'assets/images/products/placeholders/canned_goods.png', 'assets/images/products/placeholders/canned_goods.png', 'Century Tuna Flakes in Oil 155g Promo Pack 318 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000318');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000319', 6)), '4800000000319', 'Pencil No.2 Small Pack 319', 'pencil no 2 small pack 319', 'Generic',
       (SELECT id FROM product_categories WHERE name='School Supplies'),
       (SELECT id FROM business_types WHERE name='School Supplies'),
       (SELECT id FROM units WHERE name='piece'),
       7.38, 9.00, 106, 106, 15, 'assets/images/products/placeholders/school_supplies.png', 'assets/images/products/placeholders/school_supplies.png', 'Pencil No.2 Small Pack 319 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000319');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000320', 6)), '4800000000320', 'Nissin Cup Noodles Beef Family Pack 320', 'nissin cup noodles beef family pack 320', 'Nissin',
       (SELECT id FROM product_categories WHERE name='Noodles'),
       (SELECT id FROM business_types WHERE name='Grocery'),
       (SELECT id FROM units WHERE name='piece'),
       34.44, 42.00, 98, 98, 10, 'assets/images/products/placeholders/noodles.png', 'assets/images/products/placeholders/noodles.png', 'Nissin Cup Noodles Beef Family Pack 320 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000320');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000321', 6)), '4800000000321', 'Datu Puti Vinegar 1L Regular Pack 321', 'datu puti vinegar 1l regular pack 321', 'Datu Puti',
       (SELECT id FROM product_categories WHERE name='Condiments'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='bottle'),
       54.12, 66.00, 67, 67, 20, 'assets/images/products/placeholders/condiments.png', 'assets/images/products/placeholders/condiments.png', 'Datu Puti Vinegar 1L Regular Pack 321 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000321');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000322', 6)), '4800000000322', 'Sprite 1.5L Promo Pack 322', 'sprite 1 5l promo pack 322', 'Sprite',
       (SELECT id FROM product_categories WHERE name='Beverages'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='bottle'),
       53.3, 65.00, 26, 26, 15, 'assets/images/products/placeholders/beverages.png', 'assets/images/products/placeholders/beverages.png', 'Sprite 1.5L Promo Pack 322 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000322');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000323', 6)), '4800000000323', 'Payless Xtra Big Pancit Canton Regular Pack 323', 'payless xtra big pancit canton regular pack 323', 'Payless',
       (SELECT id FROM product_categories WHERE name='Noodles'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='pack'),
       18.04, 22.00, 78, 78, 15, 'assets/images/products/placeholders/noodles.png', 'assets/images/products/placeholders/noodles.png', 'Payless Xtra Big Pancit Canton Regular Pack 323 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000323');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000324', 6)), '4800000000324', 'Datu Puti Vinegar 1L Small Pack 324', 'datu puti vinegar 1l small pack 324', 'Datu Puti',
       (SELECT id FROM product_categories WHERE name='Condiments'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='bottle'),
       58.22, 71.00, 81, 81, 10, 'assets/images/products/placeholders/condiments.png', 'assets/images/products/placeholders/condiments.png', 'Datu Puti Vinegar 1L Small Pack 324 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000324');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000325', 6)), '4800000000325', 'Sunsilk Shampoo Sachet Small Pack 325', 'sunsilk shampoo sachet small pack 325', 'Sunsilk',
       (SELECT id FROM product_categories WHERE name='Shampoo'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='sachet'),
       6.56, 8.00, 35, 35, 5, 'assets/images/products/placeholders/shampoo.png', 'assets/images/products/placeholders/shampoo.png', 'Sunsilk Shampoo Sachet Small Pack 325 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000325');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000326', 6)), '4800000000326', 'Sprite 1.5L Regular Pack 326', 'sprite 1 5l regular pack 326', 'Sprite',
       (SELECT id FROM product_categories WHERE name='Beverages'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='bottle'),
       52.48, 64.00, 108, 108, 10, 'assets/images/products/placeholders/beverages.png', 'assets/images/products/placeholders/beverages.png', 'Sprite 1.5L Regular Pack 326 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000326');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000327', 6)), '4800000000327', 'Surf Powder Detergent 70g Regular Pack 327', 'surf powder detergent 70g regular pack 327', 'Surf',
       (SELECT id FROM product_categories WHERE name='Detergent'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='sachet'),
       7.38, 9.00, 28, 28, 5, 'assets/images/products/placeholders/detergent.png', 'assets/images/products/placeholders/detergent.png', 'Surf Powder Detergent 70g Regular Pack 327 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000327');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000328', 6)), '4800000000328', 'Alaska Evaporada 370ml Small Pack 328', 'alaska evaporada 370ml small pack 328', 'Alaska',
       (SELECT id FROM product_categories WHERE name='Milk'),
       (SELECT id FROM business_types WHERE name='Grocery'),
       (SELECT id FROM units WHERE name='can'),
       31.98, 39.00, 36, 36, 15, 'assets/images/products/placeholders/milk.png', 'assets/images/products/placeholders/milk.png', 'Alaska Evaporada 370ml Small Pack 328 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000328');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000329', 6)), '4800000000329', 'Nova Multigrain Snacks 40g Family Pack 329', 'nova multigrain snacks 40g family pack 329', 'Nova',
       (SELECT id FROM product_categories WHERE name='Snacks'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='pack'),
       14.76, 18.00, 71, 71, 10, 'assets/images/products/placeholders/snacks.png', 'assets/images/products/placeholders/snacks.png', 'Nova Multigrain Snacks 40g Family Pack 329 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000329');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000330', 6)), '4800000000330', 'Cobra Energy Drink 350ml Regular Pack 330', 'cobra energy drink 350ml regular pack 330', 'Cobra',
       (SELECT id FROM product_categories WHERE name='Beverages'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='bottle'),
       23.78, 29.00, 56, 56, 5, 'assets/images/products/placeholders/beverages.png', 'assets/images/products/placeholders/beverages.png', 'Cobra Energy Drink 350ml Regular Pack 330 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000330');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000331', 6)), '4800000000331', 'Palmolive Shampoo Sachet Promo Pack 331', 'palmolive shampoo sachet promo pack 331', 'Palmolive',
       (SELECT id FROM product_categories WHERE name='Shampoo'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='sachet'),
       7.38, 9.00, 118, 118, 10, 'assets/images/products/placeholders/shampoo.png', 'assets/images/products/placeholders/shampoo.png', 'Palmolive Shampoo Sachet Promo Pack 331 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000331');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000332', 6)), '4800000000332', 'Royal Tru Orange 1.5L Bundle Pack 332', 'royal tru orange 1 5l bundle pack 332', 'Royal',
       (SELECT id FROM product_categories WHERE name='Beverages'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='bottle'),
       52.48, 64.00, 111, 111, 20, 'assets/images/products/placeholders/beverages.png', 'assets/images/products/placeholders/beverages.png', 'Royal Tru Orange 1.5L Bundle Pack 332 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000332');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000333', 6)), '4800000000333', 'Bond Paper Long 10pcs Bundle Pack 333', 'bond paper long 10pcs bundle pack 333', 'Generic',
       (SELECT id FROM product_categories WHERE name='School Supplies'),
       (SELECT id FROM business_types WHERE name='School Supplies'),
       (SELECT id FROM units WHERE name='pack'),
       11.48, 14.00, 63, 63, 20, 'assets/images/products/placeholders/school_supplies.png', 'assets/images/products/placeholders/school_supplies.png', 'Bond Paper Long 10pcs Bundle Pack 333 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000333');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000334', 6)), '4800000000334', 'Argentina Corned Beef 150g Bundle Pack 334', 'argentina corned beef 150g bundle pack 334', 'Argentina',
       (SELECT id FROM product_categories WHERE name='Canned Goods'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='can'),
       32.8, 40.00, 47, 47, 5, 'assets/images/products/placeholders/canned_goods.png', 'assets/images/products/placeholders/canned_goods.png', 'Argentina Corned Beef 150g Bundle Pack 334 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000334');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000335', 6)), '4800000000335', 'Ariel Powder Detergent 70g Promo Pack 335', 'ariel powder detergent 70g promo pack 335', 'Ariel',
       (SELECT id FROM product_categories WHERE name='Detergent'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='sachet'),
       9.02, 11.00, 50, 50, 15, 'assets/images/products/placeholders/detergent.png', 'assets/images/products/placeholders/detergent.png', 'Ariel Powder Detergent 70g Promo Pack 335 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000335');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000336', 6)), '4800000000336', 'Nescafe Classic Sachet 2g Family Pack 336', 'nescafe classic sachet 2g family pack 336', 'Nescafe',
       (SELECT id FROM product_categories WHERE name='Coffee'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='sachet'),
       2.46, 3.00, 91, 91, 15, 'assets/images/products/placeholders/coffee.png', 'assets/images/products/placeholders/coffee.png', 'Nescafe Classic Sachet 2g Family Pack 336 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000336');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000337', 6)), '4800000000337', 'Diatabs Capsule Regular Pack 337', 'diatabs capsule regular pack 337', 'Diatabs',
       (SELECT id FROM product_categories WHERE name='Medicine'),
       (SELECT id FROM business_types WHERE name='Pharmacy'),
       (SELECT id FROM units WHERE name='capsule'),
       10.66, 13.00, 68, 68, 20, 'assets/images/products/placeholders/medicine.png', 'assets/images/products/placeholders/medicine.png', 'Diatabs Capsule Regular Pack 337 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000337');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000338', 6)), '4800000000338', 'Argentina Corned Beef 150g Regular Pack 338', 'argentina corned beef 150g regular pack 338', 'Argentina',
       (SELECT id FROM product_categories WHERE name='Canned Goods'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='can'),
       33.62, 41.00, 116, 116, 20, 'assets/images/products/placeholders/canned_goods.png', 'assets/images/products/placeholders/canned_goods.png', 'Argentina Corned Beef 150g Regular Pack 338 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000338');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000339', 6)), '4800000000339', 'Tide Detergent Bar Family Pack 339', 'tide detergent bar family pack 339', 'Tide',
       (SELECT id FROM product_categories WHERE name='Detergent'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='piece'),
       11.48, 14.00, 105, 105, 5, 'assets/images/products/placeholders/detergent.png', 'assets/images/products/placeholders/detergent.png', 'Tide Detergent Bar Family Pack 339 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000339');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000340', 6)), '4800000000340', 'Bond Paper Short 10pcs Small Pack 340', 'bond paper short 10pcs small pack 340', 'Generic',
       (SELECT id FROM product_categories WHERE name='School Supplies'),
       (SELECT id FROM business_types WHERE name='School Supplies'),
       (SELECT id FROM units WHERE name='pack'),
       9.02, 11.00, 51, 51, 5, 'assets/images/products/placeholders/school_supplies.png', 'assets/images/products/placeholders/school_supplies.png', 'Bond Paper Short 10pcs Small Pack 340 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000340');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000341', 6)), '4800000000341', 'Vitamin C 500mg Bundle Pack 341', 'vitamin c 500mg bundle pack 341', 'Generic',
       (SELECT id FROM product_categories WHERE name='Vitamins'),
       (SELECT id FROM business_types WHERE name='Pharmacy'),
       (SELECT id FROM units WHERE name='tablet'),
       3.28, 4.00, 117, 117, 5, 'assets/images/products/placeholders/vitamins.png', 'assets/images/products/placeholders/vitamins.png', 'Vitamin C 500mg Bundle Pack 341 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000341');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000342', 6)), '4800000000342', 'Surf Powder Detergent 70g Small Pack 342', 'surf powder detergent 70g small pack 342', 'Surf',
       (SELECT id FROM product_categories WHERE name='Detergent'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='sachet'),
       6.56, 8.00, 45, 45, 10, 'assets/images/products/placeholders/detergent.png', 'assets/images/products/placeholders/detergent.png', 'Surf Powder Detergent 70g Small Pack 342 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000342');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000343', 6)), '4800000000343', 'Surf Powder Detergent 70g Bundle Pack 343', 'surf powder detergent 70g bundle pack 343', 'Surf',
       (SELECT id FROM product_categories WHERE name='Detergent'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='sachet'),
       6.56, 8.00, 53, 53, 10, 'assets/images/products/placeholders/detergent.png', 'assets/images/products/placeholders/detergent.png', 'Surf Powder Detergent 70g Bundle Pack 343 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000343');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000344', 6)), '4800000000344', 'Nova Multigrain Snacks 40g Bundle Pack 344', 'nova multigrain snacks 40g bundle pack 344', 'Nova',
       (SELECT id FROM product_categories WHERE name='Snacks'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='pack'),
       14.76, 18.00, 84, 84, 10, 'assets/images/products/placeholders/snacks.png', 'assets/images/products/placeholders/snacks.png', 'Nova Multigrain Snacks 40g Bundle Pack 344 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000344');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000345', 6)), '4800000000345', 'Lucky Me Beef Noodles 55g Bundle Pack 345', 'lucky me beef noodles 55g bundle pack 345', 'Lucky Me',
       (SELECT id FROM product_categories WHERE name='Noodles'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='pack'),
       11.48, 14.00, 96, 96, 10, 'assets/images/products/placeholders/noodles.png', 'assets/images/products/placeholders/noodles.png', 'Lucky Me Beef Noodles 55g Bundle Pack 345 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000345');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000346', 6)), '4800000000346', 'Tide Detergent Bar Bundle Pack 346', 'tide detergent bar bundle pack 346', 'Tide',
       (SELECT id FROM product_categories WHERE name='Detergent'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='piece'),
       12.3, 15.00, 71, 71, 5, 'assets/images/products/placeholders/detergent.png', 'assets/images/products/placeholders/detergent.png', 'Tide Detergent Bar Bundle Pack 346 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000346');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000347', 6)), '4800000000347', 'Milo Sachet 24g Small Pack 347', 'milo sachet 24g small pack 347', 'Milo',
       (SELECT id FROM product_categories WHERE name='Milk'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='sachet'),
       10.66, 13.00, 35, 35, 10, 'assets/images/products/placeholders/milk.png', 'assets/images/products/placeholders/milk.png', 'Milo Sachet 24g Small Pack 347 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000347');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000348', 6)), '4800000000348', 'Bear Brand Powdered Milk 33g Small Pack 348', 'bear brand powdered milk 33g small pack 348', 'Bear Brand',
       (SELECT id FROM product_categories WHERE name='Milk'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='sachet'),
       13.12, 16.00, 119, 119, 10, 'assets/images/products/placeholders/milk.png', 'assets/images/products/placeholders/milk.png', 'Bear Brand Powdered Milk 33g Small Pack 348 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000348');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000349', 6)), '4800000000349', 'Fita Crackers Bundle Pack 349', 'fita crackers bundle pack 349', 'Fita',
       (SELECT id FROM product_categories WHERE name='Biscuits'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='pack'),
       8.2, 10.00, 20, 20, 20, 'assets/images/products/placeholders/biscuits.png', 'assets/images/products/placeholders/biscuits.png', 'Fita Crackers Bundle Pack 349 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000349');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000350', 6)), '4800000000350', 'Coca-Cola 1.5L Promo Pack 350', 'coca cola 1 5l promo pack 350', 'Coca-Cola',
       (SELECT id FROM product_categories WHERE name='Beverages'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='bottle'),
       74.62, 91.00, 118, 118, 10, 'assets/images/products/placeholders/beverages.png', 'assets/images/products/placeholders/beverages.png', 'Coca-Cola 1.5L Promo Pack 350 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000350');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000351', 6)), '4800000000351', 'Biogesic 500mg Small Pack 351', 'biogesic 500mg small pack 351', 'Biogesic',
       (SELECT id FROM product_categories WHERE name='Medicine'),
       (SELECT id FROM business_types WHERE name='Pharmacy'),
       (SELECT id FROM units WHERE name='tablet'),
       6.56, 8.00, 96, 96, 5, 'assets/images/products/placeholders/medicine.png', 'assets/images/products/placeholders/medicine.png', 'Biogesic 500mg Small Pack 351 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000351');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000352', 6)), '4800000000352', 'Nescafe Classic Sachet 2g Family Pack 352', 'nescafe classic sachet 2g family pack 352', 'Nescafe',
       (SELECT id FROM product_categories WHERE name='Coffee'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='sachet'),
       3.28, 4.00, 21, 21, 5, 'assets/images/products/placeholders/coffee.png', 'assets/images/products/placeholders/coffee.png', 'Nescafe Classic Sachet 2g Family Pack 352 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000352');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000353', 6)), '4800000000353', 'Screwdriver Flat Regular Pack 353', 'screwdriver flat regular pack 353', 'Generic',
       (SELECT id FROM product_categories WHERE name='Hardware'),
       (SELECT id FROM business_types WHERE name='Hardware'),
       (SELECT id FROM units WHERE name='piece'),
       46.74, 57.00, 54, 54, 20, 'assets/images/products/placeholders/hardware.png', 'assets/images/products/placeholders/hardware.png', 'Screwdriver Flat Regular Pack 353 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000353');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000354', 6)), '4800000000354', 'Milo Sachet 24g Regular Pack 354', 'milo sachet 24g regular pack 354', 'Milo',
       (SELECT id FROM product_categories WHERE name='Milk'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='sachet'),
       9.84, 12.00, 16, 16, 20, 'assets/images/products/placeholders/milk.png', 'assets/images/products/placeholders/milk.png', 'Milo Sachet 24g Regular Pack 354 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000354');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000355', 6)), '4800000000355', 'Mega Sardines Tomato Sauce 155g Promo Pack 355', 'mega sardines tomato sauce 155g promo pack 355', 'Mega',
       (SELECT id FROM product_categories WHERE name='Canned Goods'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='can'),
       23.78, 29.00, 115, 115, 5, 'assets/images/products/placeholders/canned_goods.png', 'assets/images/products/placeholders/canned_goods.png', 'Mega Sardines Tomato Sauce 155g Promo Pack 355 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000355');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000356', 6)), '4800000000356', 'Palmolive Shampoo Sachet Promo Pack 356', 'palmolive shampoo sachet promo pack 356', 'Palmolive',
       (SELECT id FROM product_categories WHERE name='Shampoo'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='sachet'),
       8.2, 10.00, 56, 56, 20, 'assets/images/products/placeholders/shampoo.png', 'assets/images/products/placeholders/shampoo.png', 'Palmolive Shampoo Sachet Promo Pack 356 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000356');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000357', 6)), '4800000000357', 'Nescafe Classic Sachet 2g Bundle Pack 357', 'nescafe classic sachet 2g bundle pack 357', 'Nescafe',
       (SELECT id FROM product_categories WHERE name='Coffee'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='sachet'),
       2.46, 3.00, 67, 67, 15, 'assets/images/products/placeholders/coffee.png', 'assets/images/products/placeholders/coffee.png', 'Nescafe Classic Sachet 2g Bundle Pack 357 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000357');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000358', 6)), '4800000000358', 'Screwdriver Flat Promo Pack 358', 'screwdriver flat promo pack 358', 'Generic',
       (SELECT id FROM product_categories WHERE name='Hardware'),
       (SELECT id FROM business_types WHERE name='Hardware'),
       (SELECT id FROM units WHERE name='piece'),
       59.04, 72.00, 85, 85, 15, 'assets/images/products/placeholders/hardware.png', 'assets/images/products/placeholders/hardware.png', 'Screwdriver Flat Promo Pack 358 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000358');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000359', 6)), '4800000000359', 'Bond Paper Short 10pcs Family Pack 359', 'bond paper short 10pcs family pack 359', 'Generic',
       (SELECT id FROM product_categories WHERE name='School Supplies'),
       (SELECT id FROM business_types WHERE name='School Supplies'),
       (SELECT id FROM units WHERE name='pack'),
       9.02, 11.00, 49, 49, 15, 'assets/images/products/placeholders/school_supplies.png', 'assets/images/products/placeholders/school_supplies.png', 'Bond Paper Short 10pcs Family Pack 359 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000359');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000360', 6)), '4800000000360', 'Chippy BBQ 110g Small Pack 360', 'chippy bbq 110g small pack 360', 'Chippy',
       (SELECT id FROM product_categories WHERE name='Snacks'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='pack'),
       25.42, 31.00, 47, 47, 20, 'assets/images/products/placeholders/snacks.png', 'assets/images/products/placeholders/snacks.png', 'Chippy BBQ 110g Small Pack 360 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000360');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000361', 6)), '4800000000361', 'Fita Crackers Regular Pack 361', 'fita crackers regular pack 361', 'Fita',
       (SELECT id FROM product_categories WHERE name='Biscuits'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='pack'),
       8.2, 10.00, 102, 102, 15, 'assets/images/products/placeholders/biscuits.png', 'assets/images/products/placeholders/biscuits.png', 'Fita Crackers Regular Pack 361 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000361');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000362', 6)), '4800000000362', 'Payless Xtra Big Pancit Canton Family Pack 362', 'payless xtra big pancit canton family pack 362', 'Payless',
       (SELECT id FROM product_categories WHERE name='Noodles'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='pack'),
       12.3, 15.00, 58, 58, 20, 'assets/images/products/placeholders/noodles.png', 'assets/images/products/placeholders/noodles.png', 'Payless Xtra Big Pancit Canton Family Pack 362 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000362');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000363', 6)), '4800000000363', 'Cobra Energy Drink 350ml Regular Pack 363', 'cobra energy drink 350ml regular pack 363', 'Cobra',
       (SELECT id FROM product_categories WHERE name='Beverages'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='bottle'),
       27.06, 33.00, 79, 79, 10, 'assets/images/products/placeholders/beverages.png', 'assets/images/products/placeholders/beverages.png', 'Cobra Energy Drink 350ml Regular Pack 363 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000363');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000364', 6)), '4800000000364', 'Bear Brand Powdered Milk 33g Promo Pack 364', 'bear brand powdered milk 33g promo pack 364', 'Bear Brand',
       (SELECT id FROM product_categories WHERE name='Milk'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='sachet'),
       13.94, 17.00, 103, 103, 20, 'assets/images/products/placeholders/milk.png', 'assets/images/products/placeholders/milk.png', 'Bear Brand Powdered Milk 33g Promo Pack 364 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000364');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000365', 6)), '4800000000365', 'Surf Powder Detergent 70g Promo Pack 365', 'surf powder detergent 70g promo pack 365', 'Surf',
       (SELECT id FROM product_categories WHERE name='Detergent'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='sachet'),
       7.38, 9.00, 49, 49, 5, 'assets/images/products/placeholders/detergent.png', 'assets/images/products/placeholders/detergent.png', 'Surf Powder Detergent 70g Promo Pack 365 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000365');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000366', 6)), '4800000000366', 'Tide Detergent Bar Bundle Pack 366', 'tide detergent bar bundle pack 366', 'Tide',
       (SELECT id FROM product_categories WHERE name='Detergent'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='piece'),
       15.58, 19.00, 25, 25, 5, 'assets/images/products/placeholders/detergent.png', 'assets/images/products/placeholders/detergent.png', 'Tide Detergent Bar Bundle Pack 366 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000366');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000367', 6)), '4800000000367', 'Alaska Evaporada 370ml Bundle Pack 367', 'alaska evaporada 370ml bundle pack 367', 'Alaska',
       (SELECT id FROM product_categories WHERE name='Milk'),
       (SELECT id FROM business_types WHERE name='Grocery'),
       (SELECT id FROM units WHERE name='can'),
       38.54, 47.00, 63, 63, 10, 'assets/images/products/placeholders/milk.png', 'assets/images/products/placeholders/milk.png', 'Alaska Evaporada 370ml Bundle Pack 367 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000367');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000368', 6)), '4800000000368', 'Bond Paper Short 10pcs Family Pack 368', 'bond paper short 10pcs family pack 368', 'Generic',
       (SELECT id FROM product_categories WHERE name='School Supplies'),
       (SELECT id FROM business_types WHERE name='School Supplies'),
       (SELECT id FROM units WHERE name='pack'),
       9.02, 11.00, 60, 60, 5, 'assets/images/products/placeholders/school_supplies.png', 'assets/images/products/placeholders/school_supplies.png', 'Bond Paper Short 10pcs Family Pack 368 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000368');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000369', 6)), '4800000000369', 'Tide Detergent Bar Promo Pack 369', 'tide detergent bar promo pack 369', 'Tide',
       (SELECT id FROM product_categories WHERE name='Detergent'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='piece'),
       12.3, 15.00, 81, 81, 15, 'assets/images/products/placeholders/detergent.png', 'assets/images/products/placeholders/detergent.png', 'Tide Detergent Bar Promo Pack 369 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000369');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000370', 6)), '4800000000370', 'Bond Paper Long 10pcs Small Pack 370', 'bond paper long 10pcs small pack 370', 'Generic',
       (SELECT id FROM product_categories WHERE name='School Supplies'),
       (SELECT id FROM business_types WHERE name='School Supplies'),
       (SELECT id FROM units WHERE name='pack'),
       11.48, 14.00, 81, 81, 5, 'assets/images/products/placeholders/school_supplies.png', 'assets/images/products/placeholders/school_supplies.png', 'Bond Paper Long 10pcs Small Pack 370 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000370');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000371', 6)), '4800000000371', 'Nescafe Classic Sachet 2g Promo Pack 371', 'nescafe classic sachet 2g promo pack 371', 'Nescafe',
       (SELECT id FROM product_categories WHERE name='Coffee'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='sachet'),
       3.28, 4.00, 45, 45, 15, 'assets/images/products/placeholders/coffee.png', 'assets/images/products/placeholders/coffee.png', 'Nescafe Classic Sachet 2g Promo Pack 371 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000371');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000372', 6)), '4800000000372', 'Palmolive Shampoo Sachet Small Pack 372', 'palmolive shampoo sachet small pack 372', 'Palmolive',
       (SELECT id FROM product_categories WHERE name='Shampoo'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='sachet'),
       7.38, 9.00, 80, 80, 5, 'assets/images/products/placeholders/shampoo.png', 'assets/images/products/placeholders/shampoo.png', 'Palmolive Shampoo Sachet Small Pack 372 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000372');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000373', 6)), '4800000000373', 'Nescafe Classic Sachet 2g Family Pack 373', 'nescafe classic sachet 2g family pack 373', 'Nescafe',
       (SELECT id FROM product_categories WHERE name='Coffee'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='sachet'),
       2.46, 3.00, 59, 59, 20, 'assets/images/products/placeholders/coffee.png', 'assets/images/products/placeholders/coffee.png', 'Nescafe Classic Sachet 2g Family Pack 373 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000373');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000374', 6)), '4800000000374', 'Screwdriver Flat Regular Pack 374', 'screwdriver flat regular pack 374', 'Generic',
       (SELECT id FROM product_categories WHERE name='Hardware'),
       (SELECT id FROM business_types WHERE name='Hardware'),
       (SELECT id FROM units WHERE name='piece'),
       64.78, 79.00, 81, 81, 20, 'assets/images/products/placeholders/hardware.png', 'assets/images/products/placeholders/hardware.png', 'Screwdriver Flat Regular Pack 374 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000374');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000375', 6)), '4800000000375', 'Chippy BBQ 110g Family Pack 375', 'chippy bbq 110g family pack 375', 'Chippy',
       (SELECT id FROM product_categories WHERE name='Snacks'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='pack'),
       28.7, 35.00, 85, 85, 5, 'assets/images/products/placeholders/snacks.png', 'assets/images/products/placeholders/snacks.png', 'Chippy BBQ 110g Family Pack 375 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000375');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000376', 6)), '4800000000376', 'Surf Powder Detergent 70g Family Pack 376', 'surf powder detergent 70g family pack 376', 'Surf',
       (SELECT id FROM product_categories WHERE name='Detergent'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='sachet'),
       5.74, 7.00, 99, 99, 20, 'assets/images/products/placeholders/detergent.png', 'assets/images/products/placeholders/detergent.png', 'Surf Powder Detergent 70g Family Pack 376 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000376');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000377', 6)), '4800000000377', 'Royal Tru Orange 1.5L Bundle Pack 377', 'royal tru orange 1 5l bundle pack 377', 'Royal',
       (SELECT id FROM product_categories WHERE name='Beverages'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='bottle'),
       53.3, 65.00, 38, 38, 15, 'assets/images/products/placeholders/beverages.png', 'assets/images/products/placeholders/beverages.png', 'Royal Tru Orange 1.5L Bundle Pack 377 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000377');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000378', 6)), '4800000000378', 'Nescafe Classic Sachet 2g Regular Pack 378', 'nescafe classic sachet 2g regular pack 378', 'Nescafe',
       (SELECT id FROM product_categories WHERE name='Coffee'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='sachet'),
       2.46, 3.00, 51, 51, 5, 'assets/images/products/placeholders/coffee.png', 'assets/images/products/placeholders/coffee.png', 'Nescafe Classic Sachet 2g Regular Pack 378 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000378');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000379', 6)), '4800000000379', 'Nescafe Classic Sachet 2g Regular Pack 379', 'nescafe classic sachet 2g regular pack 379', 'Nescafe',
       (SELECT id FROM product_categories WHERE name='Coffee'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='sachet'),
       3.28, 4.00, 73, 73, 5, 'assets/images/products/placeholders/coffee.png', 'assets/images/products/placeholders/coffee.png', 'Nescafe Classic Sachet 2g Regular Pack 379 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000379');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000380', 6)), '4800000000380', 'Hammer Small Family Pack 380', 'hammer small family pack 380', 'Generic',
       (SELECT id FROM product_categories WHERE name='Hardware'),
       (SELECT id FROM business_types WHERE name='Hardware'),
       (SELECT id FROM units WHERE name='piece'),
       145.14, 177.00, 44, 44, 5, 'assets/images/products/placeholders/hardware.png', 'assets/images/products/placeholders/hardware.png', 'Hammer Small Family Pack 380 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000380');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000381', 6)), '4800000000381', 'Notebook 80 Leaves Family Pack 381', 'notebook 80 leaves family pack 381', 'Generic',
       (SELECT id FROM product_categories WHERE name='School Supplies'),
       (SELECT id FROM business_types WHERE name='School Supplies'),
       (SELECT id FROM units WHERE name='piece'),
       24.6, 30.00, 83, 83, 5, 'assets/images/products/placeholders/school_supplies.png', 'assets/images/products/placeholders/school_supplies.png', 'Notebook 80 Leaves Family Pack 381 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000381');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000382', 6)), '4800000000382', 'Silver Swan Soy Sauce 1L Family Pack 382', 'silver swan soy sauce 1l family pack 382', 'Silver Swan',
       (SELECT id FROM product_categories WHERE name='Condiments'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='bottle'),
       53.3, 65.00, 43, 43, 20, 'assets/images/products/placeholders/condiments.png', 'assets/images/products/placeholders/condiments.png', 'Silver Swan Soy Sauce 1L Family Pack 382 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000382');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000383', 6)), '4800000000383', 'Datu Puti Vinegar 1L Family Pack 383', 'datu puti vinegar 1l family pack 383', 'Datu Puti',
       (SELECT id FROM product_categories WHERE name='Condiments'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='bottle'),
       63.96, 78.00, 33, 33, 5, 'assets/images/products/placeholders/condiments.png', 'assets/images/products/placeholders/condiments.png', 'Datu Puti Vinegar 1L Family Pack 383 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000383');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000384', 6)), '4800000000384', 'Coca-Cola 1.5L Promo Pack 384', 'coca cola 1 5l promo pack 384', 'Coca-Cola',
       (SELECT id FROM product_categories WHERE name='Beverages'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='bottle'),
       63.96, 78.00, 117, 117, 20, 'assets/images/products/placeholders/beverages.png', 'assets/images/products/placeholders/beverages.png', 'Coca-Cola 1.5L Promo Pack 384 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000384');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000385', 6)), '4800000000385', 'Alaska Evaporada 370ml Regular Pack 385', 'alaska evaporada 370ml regular pack 385', 'Alaska',
       (SELECT id FROM product_categories WHERE name='Milk'),
       (SELECT id FROM business_types WHERE name='Grocery'),
       (SELECT id FROM units WHERE name='can'),
       32.8, 40.00, 118, 118, 15, 'assets/images/products/placeholders/milk.png', 'assets/images/products/placeholders/milk.png', 'Alaska Evaporada 370ml Regular Pack 385 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000385');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000386', 6)), '4800000000386', 'Nescafe Classic Sachet 2g Bundle Pack 386', 'nescafe classic sachet 2g bundle pack 386', 'Nescafe',
       (SELECT id FROM product_categories WHERE name='Coffee'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='sachet'),
       2.46, 3.00, 105, 105, 10, 'assets/images/products/placeholders/coffee.png', 'assets/images/products/placeholders/coffee.png', 'Nescafe Classic Sachet 2g Bundle Pack 386 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000386');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000387', 6)), '4800000000387', 'Electrical Tape Small Pack 387', 'electrical tape small pack 387', 'Generic',
       (SELECT id FROM product_categories WHERE name='Hardware'),
       (SELECT id FROM business_types WHERE name='Hardware'),
       (SELECT id FROM units WHERE name='roll'),
       27.06, 33.00, 38, 38, 5, 'assets/images/products/placeholders/hardware.png', 'assets/images/products/placeholders/hardware.png', 'Electrical Tape Small Pack 387 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000387');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000388', 6)), '4800000000388', 'Rebisco Crackers Promo Pack 388', 'rebisco crackers promo pack 388', 'Rebisco',
       (SELECT id FROM product_categories WHERE name='Biscuits'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='pack'),
       6.56, 8.00, 114, 114, 5, 'assets/images/products/placeholders/biscuits.png', 'assets/images/products/placeholders/biscuits.png', 'Rebisco Crackers Promo Pack 388 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000388');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000389', 6)), '4800000000389', 'Sprite 1.5L Small Pack 389', 'sprite 1 5l small pack 389', 'Sprite',
       (SELECT id FROM product_categories WHERE name='Beverages'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='bottle'),
       81.18, 99.00, 109, 109, 20, 'assets/images/products/placeholders/beverages.png', 'assets/images/products/placeholders/beverages.png', 'Sprite 1.5L Small Pack 389 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000389');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000390', 6)), '4800000000390', 'Alaxan FR Capsule Family Pack 390', 'alaxan fr capsule family pack 390', 'Alaxan',
       (SELECT id FROM product_categories WHERE name='Medicine'),
       (SELECT id FROM business_types WHERE name='Pharmacy'),
       (SELECT id FROM units WHERE name='capsule'),
       10.66, 13.00, 56, 56, 5, 'assets/images/products/placeholders/medicine.png', 'assets/images/products/placeholders/medicine.png', 'Alaxan FR Capsule Family Pack 390 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000390');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000391', 6)), '4800000000391', 'Nissin Cup Noodles Beef Bundle Pack 391', 'nissin cup noodles beef bundle pack 391', 'Nissin',
       (SELECT id FROM product_categories WHERE name='Noodles'),
       (SELECT id FROM business_types WHERE name='Grocery'),
       (SELECT id FROM units WHERE name='piece'),
       38.54, 47.00, 19, 19, 10, 'assets/images/products/placeholders/noodles.png', 'assets/images/products/placeholders/noodles.png', 'Nissin Cup Noodles Beef Bundle Pack 391 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000391');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000392', 6)), '4800000000392', 'Ballpen Black Promo Pack 392', 'ballpen black promo pack 392', 'Generic',
       (SELECT id FROM product_categories WHERE name='School Supplies'),
       (SELECT id FROM business_types WHERE name='School Supplies'),
       (SELECT id FROM units WHERE name='piece'),
       8.2, 10.00, 78, 78, 5, 'assets/images/products/placeholders/school_supplies.png', 'assets/images/products/placeholders/school_supplies.png', 'Ballpen Black Promo Pack 392 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000392');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000393', 6)), '4800000000393', 'Kopiko Brown Coffee Twin Pack Promo Pack 393', 'kopiko brown coffee twin pack promo pack 393', 'Kopiko',
       (SELECT id FROM product_categories WHERE name='Coffee'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='pack'),
       14.76, 18.00, 86, 86, 15, 'assets/images/products/placeholders/coffee.png', 'assets/images/products/placeholders/coffee.png', 'Kopiko Brown Coffee Twin Pack Promo Pack 393 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000393');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000394', 6)), '4800000000394', 'Screwdriver Flat Bundle Pack 394', 'screwdriver flat bundle pack 394', 'Generic',
       (SELECT id FROM product_categories WHERE name='Hardware'),
       (SELECT id FROM business_types WHERE name='Hardware'),
       (SELECT id FROM units WHERE name='piece'),
       51.66, 63.00, 75, 75, 5, 'assets/images/products/placeholders/hardware.png', 'assets/images/products/placeholders/hardware.png', 'Screwdriver Flat Bundle Pack 394 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000394');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000395', 6)), '4800000000395', 'Neozep Forte Bundle Pack 395', 'neozep forte bundle pack 395', 'Neozep',
       (SELECT id FROM product_categories WHERE name='Medicine'),
       (SELECT id FROM business_types WHERE name='Pharmacy'),
       (SELECT id FROM units WHERE name='tablet'),
       6.56, 8.00, 28, 28, 20, 'assets/images/products/placeholders/medicine.png', 'assets/images/products/placeholders/medicine.png', 'Neozep Forte Bundle Pack 395 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000395');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000396', 6)), '4800000000396', 'Diatabs Capsule Regular Pack 396', 'diatabs capsule regular pack 396', 'Diatabs',
       (SELECT id FROM product_categories WHERE name='Medicine'),
       (SELECT id FROM business_types WHERE name='Pharmacy'),
       (SELECT id FROM units WHERE name='capsule'),
       8.2, 10.00, 31, 31, 15, 'assets/images/products/placeholders/medicine.png', 'assets/images/products/placeholders/medicine.png', 'Diatabs Capsule Regular Pack 396 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000396');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000397', 6)), '4800000000397', 'Piattos Cheese 40g Regular Pack 397', 'piattos cheese 40g regular pack 397', 'Piattos',
       (SELECT id FROM product_categories WHERE name='Snacks'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='pack'),
       21.32, 26.00, 21, 21, 5, 'assets/images/products/placeholders/snacks.png', 'assets/images/products/placeholders/snacks.png', 'Piattos Cheese 40g Regular Pack 397 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000397');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000398', 6)), '4800000000398', 'Lucky Me Pancit Canton Kalamansi 60g Regular Pack 398', 'lucky me pancit canton kalamansi 60g regular pack 398', 'Lucky Me',
       (SELECT id FROM product_categories WHERE name='Noodles'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='pack'),
       13.94, 17.00, 95, 95, 5, 'assets/images/products/placeholders/noodles.png', 'assets/images/products/placeholders/noodles.png', 'Lucky Me Pancit Canton Kalamansi 60g Regular Pack 398 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000398');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000399', 6)), '4800000000399', 'Cobra Energy Drink 350ml Promo Pack 399', 'cobra energy drink 350ml promo pack 399', 'Cobra',
       (SELECT id FROM product_categories WHERE name='Beverages'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='bottle'),
       23.78, 29.00, 65, 65, 20, 'assets/images/products/placeholders/beverages.png', 'assets/images/products/placeholders/beverages.png', 'Cobra Energy Drink 350ml Promo Pack 399 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000399');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000400', 6)), '4800000000400', 'SkyFlakes Crackers Family Pack 400', 'skyflakes crackers family pack 400', 'SkyFlakes',
       (SELECT id FROM product_categories WHERE name='Biscuits'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='pack'),
       7.38, 9.00, 117, 117, 10, 'assets/images/products/placeholders/biscuits.png', 'assets/images/products/placeholders/biscuits.png', 'SkyFlakes Crackers Family Pack 400 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000400');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000401', 6)), '4800000000401', 'Mega Sardines Tomato Sauce 155g Regular Pack 401', 'mega sardines tomato sauce 155g regular pack 401', 'Mega',
       (SELECT id FROM product_categories WHERE name='Canned Goods'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='can'),
       17.22, 21.00, 40, 40, 10, 'assets/images/products/placeholders/canned_goods.png', 'assets/images/products/placeholders/canned_goods.png', 'Mega Sardines Tomato Sauce 155g Regular Pack 401 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000401');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000402', 6)), '4800000000402', 'Alaska Evaporada 370ml Bundle Pack 402', 'alaska evaporada 370ml bundle pack 402', 'Alaska',
       (SELECT id FROM product_categories WHERE name='Milk'),
       (SELECT id FROM business_types WHERE name='Grocery'),
       (SELECT id FROM units WHERE name='can'),
       36.9, 45.00, 61, 61, 5, 'assets/images/products/placeholders/milk.png', 'assets/images/products/placeholders/milk.png', 'Alaska Evaporada 370ml Bundle Pack 402 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000402');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000403', 6)), '4800000000403', 'Bond Paper Long 10pcs Promo Pack 403', 'bond paper long 10pcs promo pack 403', 'Generic',
       (SELECT id FROM product_categories WHERE name='School Supplies'),
       (SELECT id FROM business_types WHERE name='School Supplies'),
       (SELECT id FROM units WHERE name='pack'),
       14.76, 18.00, 73, 73, 15, 'assets/images/products/placeholders/school_supplies.png', 'assets/images/products/placeholders/school_supplies.png', 'Bond Paper Long 10pcs Promo Pack 403 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000403');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000404', 6)), '4800000000404', 'Nissin Cup Noodles Beef Family Pack 404', 'nissin cup noodles beef family pack 404', 'Nissin',
       (SELECT id FROM product_categories WHERE name='Noodles'),
       (SELECT id FROM business_types WHERE name='Grocery'),
       (SELECT id FROM units WHERE name='piece'),
       30.34, 37.00, 60, 60, 20, 'assets/images/products/placeholders/noodles.png', 'assets/images/products/placeholders/noodles.png', 'Nissin Cup Noodles Beef Family Pack 404 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000404');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000405', 6)), '4800000000405', 'Kopiko Brown Coffee Twin Pack Small Pack 405', 'kopiko brown coffee twin pack small pack 405', 'Kopiko',
       (SELECT id FROM product_categories WHERE name='Coffee'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='pack'),
       16.4, 20.00, 34, 34, 20, 'assets/images/products/placeholders/coffee.png', 'assets/images/products/placeholders/coffee.png', 'Kopiko Brown Coffee Twin Pack Small Pack 405 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000405');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000406', 6)), '4800000000406', 'Biogesic 500mg Promo Pack 406', 'biogesic 500mg promo pack 406', 'Biogesic',
       (SELECT id FROM product_categories WHERE name='Medicine'),
       (SELECT id FROM business_types WHERE name='Pharmacy'),
       (SELECT id FROM units WHERE name='tablet'),
       7.38, 9.00, 64, 64, 20, 'assets/images/products/placeholders/medicine.png', 'assets/images/products/placeholders/medicine.png', 'Biogesic 500mg Promo Pack 406 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000406');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000407', 6)), '4800000000407', 'Common Nails 1kg Small Pack 407', 'common nails 1kg small pack 407', 'Generic',
       (SELECT id FROM product_categories WHERE name='Hardware'),
       (SELECT id FROM business_types WHERE name='Hardware'),
       (SELECT id FROM units WHERE name='kg'),
       67.24, 82.00, 94, 94, 10, 'assets/images/products/placeholders/hardware.png', 'assets/images/products/placeholders/hardware.png', 'Common Nails 1kg Small Pack 407 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000407');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000408', 6)), '4800000000408', 'Hammer Small Small Pack 408', 'hammer small small pack 408', 'Generic',
       (SELECT id FROM product_categories WHERE name='Hardware'),
       (SELECT id FROM business_types WHERE name='Hardware'),
       (SELECT id FROM units WHERE name='piece'),
       154.16, 188.00, 104, 104, 5, 'assets/images/products/placeholders/hardware.png', 'assets/images/products/placeholders/hardware.png', 'Hammer Small Small Pack 408 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000408');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000409', 6)), '4800000000409', 'Coca-Cola 1.5L Family Pack 409', 'coca cola 1 5l family pack 409', 'Coca-Cola',
       (SELECT id FROM product_categories WHERE name='Beverages'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='bottle'),
       68.88, 84.00, 67, 67, 10, 'assets/images/products/placeholders/beverages.png', 'assets/images/products/placeholders/beverages.png', 'Coca-Cola 1.5L Family Pack 409 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000409');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000410', 6)), '4800000000410', 'Piattos Cheese 40g Regular Pack 410', 'piattos cheese 40g regular pack 410', 'Piattos',
       (SELECT id FROM product_categories WHERE name='Snacks'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='pack'),
       20.5, 25.00, 74, 74, 10, 'assets/images/products/placeholders/snacks.png', 'assets/images/products/placeholders/snacks.png', 'Piattos Cheese 40g Regular Pack 410 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000410');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000411', 6)), '4800000000411', 'Diatabs Capsule Family Pack 411', 'diatabs capsule family pack 411', 'Diatabs',
       (SELECT id FROM product_categories WHERE name='Medicine'),
       (SELECT id FROM business_types WHERE name='Pharmacy'),
       (SELECT id FROM units WHERE name='capsule'),
       9.84, 12.00, 99, 99, 15, 'assets/images/products/placeholders/medicine.png', 'assets/images/products/placeholders/medicine.png', 'Diatabs Capsule Family Pack 411 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000411');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000412', 6)), '4800000000412', 'Neozep Forte Family Pack 412', 'neozep forte family pack 412', 'Neozep',
       (SELECT id FROM product_categories WHERE name='Medicine'),
       (SELECT id FROM business_types WHERE name='Pharmacy'),
       (SELECT id FROM units WHERE name='tablet'),
       6.56, 8.00, 105, 105, 15, 'assets/images/products/placeholders/medicine.png', 'assets/images/products/placeholders/medicine.png', 'Neozep Forte Family Pack 412 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000412');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000413', 6)), '4800000000413', 'Datu Puti Vinegar 1L Regular Pack 413', 'datu puti vinegar 1l regular pack 413', 'Datu Puti',
       (SELECT id FROM product_categories WHERE name='Condiments'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='bottle'),
       51.66, 63.00, 70, 70, 20, 'assets/images/products/placeholders/condiments.png', 'assets/images/products/placeholders/condiments.png', 'Datu Puti Vinegar 1L Regular Pack 413 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000413');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000414', 6)), '4800000000414', 'Kopiko Brown Coffee Twin Pack Bundle Pack 414', 'kopiko brown coffee twin pack bundle pack 414', 'Kopiko',
       (SELECT id FROM product_categories WHERE name='Coffee'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='pack'),
       11.48, 14.00, 97, 97, 5, 'assets/images/products/placeholders/coffee.png', 'assets/images/products/placeholders/coffee.png', 'Kopiko Brown Coffee Twin Pack Bundle Pack 414 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000414');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000415', 6)), '4800000000415', 'Diatabs Capsule Family Pack 415', 'diatabs capsule family pack 415', 'Diatabs',
       (SELECT id FROM product_categories WHERE name='Medicine'),
       (SELECT id FROM business_types WHERE name='Pharmacy'),
       (SELECT id FROM units WHERE name='capsule'),
       9.84, 12.00, 76, 76, 15, 'assets/images/products/placeholders/medicine.png', 'assets/images/products/placeholders/medicine.png', 'Diatabs Capsule Family Pack 415 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000415');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000416', 6)), '4800000000416', 'Pencil No.2 Small Pack 416', 'pencil no 2 small pack 416', 'Generic',
       (SELECT id FROM product_categories WHERE name='School Supplies'),
       (SELECT id FROM business_types WHERE name='School Supplies'),
       (SELECT id FROM units WHERE name='piece'),
       6.56, 8.00, 29, 29, 20, 'assets/images/products/placeholders/school_supplies.png', 'assets/images/products/placeholders/school_supplies.png', 'Pencil No.2 Small Pack 416 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000416');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000417', 6)), '4800000000417', 'Tide Detergent Bar Family Pack 417', 'tide detergent bar family pack 417', 'Tide',
       (SELECT id FROM product_categories WHERE name='Detergent'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='piece'),
       11.48, 14.00, 79, 79, 5, 'assets/images/products/placeholders/detergent.png', 'assets/images/products/placeholders/detergent.png', 'Tide Detergent Bar Family Pack 417 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000417');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000418', 6)), '4800000000418', 'Fita Crackers Promo Pack 418', 'fita crackers promo pack 418', 'Fita',
       (SELECT id FROM product_categories WHERE name='Biscuits'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='pack'),
       8.2, 10.00, 58, 58, 20, 'assets/images/products/placeholders/biscuits.png', 'assets/images/products/placeholders/biscuits.png', 'Fita Crackers Promo Pack 418 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000418');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000419', 6)), '4800000000419', 'Mega Sardines Tomato Sauce 155g Small Pack 419', 'mega sardines tomato sauce 155g small pack 419', 'Mega',
       (SELECT id FROM product_categories WHERE name='Canned Goods'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='can'),
       21.32, 26.00, 87, 87, 15, 'assets/images/products/placeholders/canned_goods.png', 'assets/images/products/placeholders/canned_goods.png', 'Mega Sardines Tomato Sauce 155g Small Pack 419 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000419');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000420', 6)), '4800000000420', 'Cooking Oil 1L Promo Pack 420', 'cooking oil 1l promo pack 420', 'Generic',
       (SELECT id FROM product_categories WHERE name='Cooking Oil'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='liter'),
       82.82, 101.00, 47, 47, 20, 'assets/images/products/placeholders/cooking_oil.png', 'assets/images/products/placeholders/cooking_oil.png', 'Cooking Oil 1L Promo Pack 420 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000420');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000421', 6)), '4800000000421', 'Rebisco Crackers Bundle Pack 421', 'rebisco crackers bundle pack 421', 'Rebisco',
       (SELECT id FROM product_categories WHERE name='Biscuits'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='pack'),
       6.56, 8.00, 76, 76, 20, 'assets/images/products/placeholders/biscuits.png', 'assets/images/products/placeholders/biscuits.png', 'Rebisco Crackers Bundle Pack 421 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000421');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000422', 6)), '4800000000422', 'Lucky Me Pancit Canton Kalamansi 60g Small Pack 422', 'lucky me pancit canton kalamansi 60g small pack 422', 'Lucky Me',
       (SELECT id FROM product_categories WHERE name='Noodles'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='pack'),
       14.76, 18.00, 85, 85, 5, 'assets/images/products/placeholders/noodles.png', 'assets/images/products/placeholders/noodles.png', 'Lucky Me Pancit Canton Kalamansi 60g Small Pack 422 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000422');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000423', 6)), '4800000000423', 'Sprite 1.5L Regular Pack 423', 'sprite 1 5l regular pack 423', 'Sprite',
       (SELECT id FROM product_categories WHERE name='Beverages'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='bottle'),
       63.14, 77.00, 60, 60, 10, 'assets/images/products/placeholders/beverages.png', 'assets/images/products/placeholders/beverages.png', 'Sprite 1.5L Regular Pack 423 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000423');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000424', 6)), '4800000000424', 'Silver Swan Soy Sauce 1L Bundle Pack 424', 'silver swan soy sauce 1l bundle pack 424', 'Silver Swan',
       (SELECT id FROM product_categories WHERE name='Condiments'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='bottle'),
       46.74, 57.00, 118, 118, 5, 'assets/images/products/placeholders/condiments.png', 'assets/images/products/placeholders/condiments.png', 'Silver Swan Soy Sauce 1L Bundle Pack 424 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000424');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000425', 6)), '4800000000425', 'Neozep Forte Small Pack 425', 'neozep forte small pack 425', 'Neozep',
       (SELECT id FROM product_categories WHERE name='Medicine'),
       (SELECT id FROM business_types WHERE name='Pharmacy'),
       (SELECT id FROM units WHERE name='tablet'),
       8.2, 10.00, 119, 119, 5, 'assets/images/products/placeholders/medicine.png', 'assets/images/products/placeholders/medicine.png', 'Neozep Forte Small Pack 425 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000425');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000426', 6)), '4800000000426', 'Sprite 1.5L Regular Pack 426', 'sprite 1 5l regular pack 426', 'Sprite',
       (SELECT id FROM product_categories WHERE name='Beverages'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='bottle'),
       59.86, 73.00, 56, 56, 10, 'assets/images/products/placeholders/beverages.png', 'assets/images/products/placeholders/beverages.png', 'Sprite 1.5L Regular Pack 426 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000426');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000427', 6)), '4800000000427', 'Sprite 1.5L Bundle Pack 427', 'sprite 1 5l bundle pack 427', 'Sprite',
       (SELECT id FROM product_categories WHERE name='Beverages'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='bottle'),
       60.68, 74.00, 94, 94, 15, 'assets/images/products/placeholders/beverages.png', 'assets/images/products/placeholders/beverages.png', 'Sprite 1.5L Bundle Pack 427 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000427');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000428', 6)), '4800000000428', 'Piattos Cheese 40g Family Pack 428', 'piattos cheese 40g family pack 428', 'Piattos',
       (SELECT id FROM product_categories WHERE name='Snacks'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='pack'),
       16.4, 20.00, 47, 47, 10, 'assets/images/products/placeholders/snacks.png', 'assets/images/products/placeholders/snacks.png', 'Piattos Cheese 40g Family Pack 428 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000428');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000429', 6)), '4800000000429', 'Joy Dishwashing Liquid 20ml Promo Pack 429', 'joy dishwashing liquid 20ml promo pack 429', 'Joy',
       (SELECT id FROM product_categories WHERE name='Cleaning Supplies'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='sachet'),
       6.56, 8.00, 38, 38, 10, 'assets/images/products/placeholders/cleaning_supplies.png', 'assets/images/products/placeholders/cleaning_supplies.png', 'Joy Dishwashing Liquid 20ml Promo Pack 429 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000429');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000430', 6)), '4800000000430', 'Silver Swan Soy Sauce 1L Promo Pack 430', 'silver swan soy sauce 1l promo pack 430', 'Silver Swan',
       (SELECT id FROM product_categories WHERE name='Condiments'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='bottle'),
       62.32, 76.00, 63, 63, 15, 'assets/images/products/placeholders/condiments.png', 'assets/images/products/placeholders/condiments.png', 'Silver Swan Soy Sauce 1L Promo Pack 430 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000430');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000431', 6)), '4800000000431', 'Cooking Oil 1L Family Pack 431', 'cooking oil 1l family pack 431', 'Generic',
       (SELECT id FROM product_categories WHERE name='Cooking Oil'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='liter'),
       103.32, 126.00, 44, 44, 20, 'assets/images/products/placeholders/cooking_oil.png', 'assets/images/products/placeholders/cooking_oil.png', 'Cooking Oil 1L Family Pack 431 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000431');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000432', 6)), '4800000000432', 'Mega Sardines Tomato Sauce 155g Promo Pack 432', 'mega sardines tomato sauce 155g promo pack 432', 'Mega',
       (SELECT id FROM product_categories WHERE name='Canned Goods'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='can'),
       18.04, 22.00, 66, 66, 10, 'assets/images/products/placeholders/canned_goods.png', 'assets/images/products/placeholders/canned_goods.png', 'Mega Sardines Tomato Sauce 155g Promo Pack 432 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000432');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000433', 6)), '4800000000433', 'Chippy BBQ 110g Bundle Pack 433', 'chippy bbq 110g bundle pack 433', 'Chippy',
       (SELECT id FROM product_categories WHERE name='Snacks'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='pack'),
       29.52, 36.00, 49, 49, 5, 'assets/images/products/placeholders/snacks.png', 'assets/images/products/placeholders/snacks.png', 'Chippy BBQ 110g Bundle Pack 433 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000433');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000434', 6)), '4800000000434', 'Ariel Powder Detergent 70g Small Pack 434', 'ariel powder detergent 70g small pack 434', 'Ariel',
       (SELECT id FROM product_categories WHERE name='Detergent'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='sachet'),
       9.02, 11.00, 61, 61, 15, 'assets/images/products/placeholders/detergent.png', 'assets/images/products/placeholders/detergent.png', 'Ariel Powder Detergent 70g Small Pack 434 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000434');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000435', 6)), '4800000000435', 'Royal Tru Orange 1.5L Regular Pack 435', 'royal tru orange 1 5l regular pack 435', 'Royal',
       (SELECT id FROM product_categories WHERE name='Beverages'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='bottle'),
       55.76, 68.00, 90, 90, 15, 'assets/images/products/placeholders/beverages.png', 'assets/images/products/placeholders/beverages.png', 'Royal Tru Orange 1.5L Regular Pack 435 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000435');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000436', 6)), '4800000000436', 'Argentina Corned Beef 150g Family Pack 436', 'argentina corned beef 150g family pack 436', 'Argentina',
       (SELECT id FROM product_categories WHERE name='Canned Goods'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='can'),
       31.98, 39.00, 77, 77, 15, 'assets/images/products/placeholders/canned_goods.png', 'assets/images/products/placeholders/canned_goods.png', 'Argentina Corned Beef 150g Family Pack 436 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000436');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000437', 6)), '4800000000437', 'Nescafe Classic Sachet 2g Family Pack 437', 'nescafe classic sachet 2g family pack 437', 'Nescafe',
       (SELECT id FROM product_categories WHERE name='Coffee'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='sachet'),
       3.28, 4.00, 40, 40, 20, 'assets/images/products/placeholders/coffee.png', 'assets/images/products/placeholders/coffee.png', 'Nescafe Classic Sachet 2g Family Pack 437 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000437');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000438', 6)), '4800000000438', 'Chippy BBQ 110g Small Pack 438', 'chippy bbq 110g small pack 438', 'Chippy',
       (SELECT id FROM product_categories WHERE name='Snacks'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='pack'),
       34.44, 42.00, 28, 28, 20, 'assets/images/products/placeholders/snacks.png', 'assets/images/products/placeholders/snacks.png', 'Chippy BBQ 110g Small Pack 438 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000438');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000439', 6)), '4800000000439', 'Payless Xtra Big Pancit Canton Small Pack 439', 'payless xtra big pancit canton small pack 439', 'Payless',
       (SELECT id FROM product_categories WHERE name='Noodles'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='pack'),
       13.94, 17.00, 15, 15, 20, 'assets/images/products/placeholders/noodles.png', 'assets/images/products/placeholders/noodles.png', 'Payless Xtra Big Pancit Canton Small Pack 439 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000439');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000440', 6)), '4800000000440', 'Bear Brand Powdered Milk 33g Regular Pack 440', 'bear brand powdered milk 33g regular pack 440', 'Bear Brand',
       (SELECT id FROM product_categories WHERE name='Milk'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='sachet'),
       13.94, 17.00, 53, 53, 5, 'assets/images/products/placeholders/milk.png', 'assets/images/products/placeholders/milk.png', 'Bear Brand Powdered Milk 33g Regular Pack 440 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000440');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000441', 6)), '4800000000441', 'Chippy BBQ 110g Regular Pack 441', 'chippy bbq 110g regular pack 441', 'Chippy',
       (SELECT id FROM product_categories WHERE name='Snacks'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='pack'),
       23.78, 29.00, 92, 92, 10, 'assets/images/products/placeholders/snacks.png', 'assets/images/products/placeholders/snacks.png', 'Chippy BBQ 110g Regular Pack 441 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000441');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000442', 6)), '4800000000442', 'Diatabs Capsule Promo Pack 442', 'diatabs capsule promo pack 442', 'Diatabs',
       (SELECT id FROM product_categories WHERE name='Medicine'),
       (SELECT id FROM business_types WHERE name='Pharmacy'),
       (SELECT id FROM units WHERE name='capsule'),
       11.48, 14.00, 23, 23, 10, 'assets/images/products/placeholders/medicine.png', 'assets/images/products/placeholders/medicine.png', 'Diatabs Capsule Promo Pack 442 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000442');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000443', 6)), '4800000000443', 'Century Tuna Flakes in Oil 155g Small Pack 443', 'century tuna flakes in oil 155g small pack 443', 'Century',
       (SELECT id FROM product_categories WHERE name='Canned Goods'),
       (SELECT id FROM business_types WHERE name='Grocery'),
       (SELECT id FROM units WHERE name='can'),
       31.98, 39.00, 78, 78, 5, 'assets/images/products/placeholders/canned_goods.png', 'assets/images/products/placeholders/canned_goods.png', 'Century Tuna Flakes in Oil 155g Small Pack 443 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000443');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000444', 6)), '4800000000444', 'Sunsilk Shampoo Sachet Family Pack 444', 'sunsilk shampoo sachet family pack 444', 'Sunsilk',
       (SELECT id FROM product_categories WHERE name='Shampoo'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='sachet'),
       8.2, 10.00, 87, 87, 5, 'assets/images/products/placeholders/shampoo.png', 'assets/images/products/placeholders/shampoo.png', 'Sunsilk Shampoo Sachet Family Pack 444 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000444');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000445', 6)), '4800000000445', 'Cobra Energy Drink 350ml Bundle Pack 445', 'cobra energy drink 350ml bundle pack 445', 'Cobra',
       (SELECT id FROM product_categories WHERE name='Beverages'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='bottle'),
       22.14, 27.00, 17, 17, 15, 'assets/images/products/placeholders/beverages.png', 'assets/images/products/placeholders/beverages.png', 'Cobra Energy Drink 350ml Bundle Pack 445 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000445');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000446', 6)), '4800000000446', 'Lucky Me Pancit Canton Kalamansi 60g Bundle Pack 446', 'lucky me pancit canton kalamansi 60g bundle pack 446', 'Lucky Me',
       (SELECT id FROM product_categories WHERE name='Noodles'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='pack'),
       17.22, 21.00, 79, 79, 20, 'assets/images/products/placeholders/noodles.png', 'assets/images/products/placeholders/noodles.png', 'Lucky Me Pancit Canton Kalamansi 60g Bundle Pack 446 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000446');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000447', 6)), '4800000000447', 'SkyFlakes Crackers Bundle Pack 447', 'skyflakes crackers bundle pack 447', 'SkyFlakes',
       (SELECT id FROM product_categories WHERE name='Biscuits'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='pack'),
       10.66, 13.00, 92, 92, 10, 'assets/images/products/placeholders/biscuits.png', 'assets/images/products/placeholders/biscuits.png', 'SkyFlakes Crackers Bundle Pack 447 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000447');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000448', 6)), '4800000000448', 'Fita Crackers Small Pack 448', 'fita crackers small pack 448', 'Fita',
       (SELECT id FROM product_categories WHERE name='Biscuits'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='pack'),
       8.2, 10.00, 70, 70, 10, 'assets/images/products/placeholders/biscuits.png', 'assets/images/products/placeholders/biscuits.png', 'Fita Crackers Small Pack 448 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000448');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000449', 6)), '4800000000449', 'Lucky Me Beef Noodles 55g Promo Pack 449', 'lucky me beef noodles 55g promo pack 449', 'Lucky Me',
       (SELECT id FROM product_categories WHERE name='Noodles'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='pack'),
       11.48, 14.00, 33, 33, 10, 'assets/images/products/placeholders/noodles.png', 'assets/images/products/placeholders/noodles.png', 'Lucky Me Beef Noodles 55g Promo Pack 449 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000449');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000450', 6)), '4800000000450', 'Palmolive Shampoo Sachet Regular Pack 450', 'palmolive shampoo sachet regular pack 450', 'Palmolive',
       (SELECT id FROM product_categories WHERE name='Shampoo'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='sachet'),
       6.56, 8.00, 46, 46, 10, 'assets/images/products/placeholders/shampoo.png', 'assets/images/products/placeholders/shampoo.png', 'Palmolive Shampoo Sachet Regular Pack 450 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000450');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000451', 6)), '4800000000451', 'Rebisco Crackers Family Pack 451', 'rebisco crackers family pack 451', 'Rebisco',
       (SELECT id FROM product_categories WHERE name='Biscuits'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='pack'),
       6.56, 8.00, 103, 103, 5, 'assets/images/products/placeholders/biscuits.png', 'assets/images/products/placeholders/biscuits.png', 'Rebisco Crackers Family Pack 451 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000451');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000452', 6)), '4800000000452', 'Mega Sardines Tomato Sauce 155g Promo Pack 452', 'mega sardines tomato sauce 155g promo pack 452', 'Mega',
       (SELECT id FROM product_categories WHERE name='Canned Goods'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='can'),
       26.24, 32.00, 21, 21, 10, 'assets/images/products/placeholders/canned_goods.png', 'assets/images/products/placeholders/canned_goods.png', 'Mega Sardines Tomato Sauce 155g Promo Pack 452 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000452');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000453', 6)), '4800000000453', 'Alaska Evaporada 370ml Small Pack 453', 'alaska evaporada 370ml small pack 453', 'Alaska',
       (SELECT id FROM product_categories WHERE name='Milk'),
       (SELECT id FROM business_types WHERE name='Grocery'),
       (SELECT id FROM units WHERE name='can'),
       40.18, 49.00, 69, 69, 20, 'assets/images/products/placeholders/milk.png', 'assets/images/products/placeholders/milk.png', 'Alaska Evaporada 370ml Small Pack 453 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000453');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000454', 6)), '4800000000454', 'Rebisco Crackers Regular Pack 454', 'rebisco crackers regular pack 454', 'Rebisco',
       (SELECT id FROM product_categories WHERE name='Biscuits'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='pack'),
       5.74, 7.00, 58, 58, 20, 'assets/images/products/placeholders/biscuits.png', 'assets/images/products/placeholders/biscuits.png', 'Rebisco Crackers Regular Pack 454 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000454');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000455', 6)), '4800000000455', 'Vitamin C 500mg Regular Pack 455', 'vitamin c 500mg regular pack 455', 'Generic',
       (SELECT id FROM product_categories WHERE name='Vitamins'),
       (SELECT id FROM business_types WHERE name='Pharmacy'),
       (SELECT id FROM units WHERE name='tablet'),
       4.1, 5.00, 22, 22, 10, 'assets/images/products/placeholders/vitamins.png', 'assets/images/products/placeholders/vitamins.png', 'Vitamin C 500mg Regular Pack 455 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000455');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000456', 6)), '4800000000456', 'Screwdriver Flat Regular Pack 456', 'screwdriver flat regular pack 456', 'Generic',
       (SELECT id FROM product_categories WHERE name='Hardware'),
       (SELECT id FROM business_types WHERE name='Hardware'),
       (SELECT id FROM units WHERE name='piece'),
       51.66, 63.00, 47, 47, 15, 'assets/images/products/placeholders/hardware.png', 'assets/images/products/placeholders/hardware.png', 'Screwdriver Flat Regular Pack 456 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000456');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000457', 6)), '4800000000457', 'Sprite 1.5L Promo Pack 457', 'sprite 1 5l promo pack 457', 'Sprite',
       (SELECT id FROM product_categories WHERE name='Beverages'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='bottle'),
       70.52, 86.00, 116, 116, 15, 'assets/images/products/placeholders/beverages.png', 'assets/images/products/placeholders/beverages.png', 'Sprite 1.5L Promo Pack 457 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000457');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000458', 6)), '4800000000458', 'Hammer Small Promo Pack 458', 'hammer small promo pack 458', 'Generic',
       (SELECT id FROM product_categories WHERE name='Hardware'),
       (SELECT id FROM business_types WHERE name='Hardware'),
       (SELECT id FROM units WHERE name='piece'),
       145.96, 178.00, 116, 116, 20, 'assets/images/products/placeholders/hardware.png', 'assets/images/products/placeholders/hardware.png', 'Hammer Small Promo Pack 458 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000458');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000459', 6)), '4800000000459', 'Alaxan FR Capsule Small Pack 459', 'alaxan fr capsule small pack 459', 'Alaxan',
       (SELECT id FROM product_categories WHERE name='Medicine'),
       (SELECT id FROM business_types WHERE name='Pharmacy'),
       (SELECT id FROM units WHERE name='capsule'),
       10.66, 13.00, 93, 93, 15, 'assets/images/products/placeholders/medicine.png', 'assets/images/products/placeholders/medicine.png', 'Alaxan FR Capsule Small Pack 459 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000459');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000460', 6)), '4800000000460', 'Bond Paper Long 10pcs Small Pack 460', 'bond paper long 10pcs small pack 460', 'Generic',
       (SELECT id FROM product_categories WHERE name='School Supplies'),
       (SELECT id FROM business_types WHERE name='School Supplies'),
       (SELECT id FROM units WHERE name='pack'),
       10.66, 13.00, 86, 86, 5, 'assets/images/products/placeholders/school_supplies.png', 'assets/images/products/placeholders/school_supplies.png', 'Bond Paper Long 10pcs Small Pack 460 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000460');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000461', 6)), '4800000000461', 'Head & Shoulders Sachet Promo Pack 461', 'head shoulders sachet promo pack 461', 'Head & Shoulders',
       (SELECT id FROM product_categories WHERE name='Shampoo'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='sachet'),
       6.56, 8.00, 75, 75, 5, 'assets/images/products/placeholders/shampoo.png', 'assets/images/products/placeholders/shampoo.png', 'Head & Shoulders Sachet Promo Pack 461 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000461');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000462', 6)), '4800000000462', 'Cobra Energy Drink 350ml Regular Pack 462', 'cobra energy drink 350ml regular pack 462', 'Cobra',
       (SELECT id FROM product_categories WHERE name='Beverages'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='bottle'),
       24.6, 30.00, 108, 108, 5, 'assets/images/products/placeholders/beverages.png', 'assets/images/products/placeholders/beverages.png', 'Cobra Energy Drink 350ml Regular Pack 462 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000462');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000463', 6)), '4800000000463', 'Rice Regular per kilo Small Pack 463', 'rice regular per kilo small pack 463', 'Generic',
       (SELECT id FROM product_categories WHERE name='Rice'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='kg'),
       43.46, 53.00, 90, 90, 15, 'assets/images/products/placeholders/rice.png', 'assets/images/products/placeholders/rice.png', 'Rice Regular per kilo Small Pack 463 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000463');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000464', 6)), '4800000000464', 'Electrical Tape Family Pack 464', 'electrical tape family pack 464', 'Generic',
       (SELECT id FROM product_categories WHERE name='Hardware'),
       (SELECT id FROM business_types WHERE name='Hardware'),
       (SELECT id FROM units WHERE name='roll'),
       21.32, 26.00, 101, 101, 20, 'assets/images/products/placeholders/hardware.png', 'assets/images/products/placeholders/hardware.png', 'Electrical Tape Family Pack 464 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000464');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000465', 6)), '4800000000465', 'Lucky Me Beef Noodles 55g Bundle Pack 465', 'lucky me beef noodles 55g bundle pack 465', 'Lucky Me',
       (SELECT id FROM product_categories WHERE name='Noodles'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='pack'),
       15.58, 19.00, 34, 34, 15, 'assets/images/products/placeholders/noodles.png', 'assets/images/products/placeholders/noodles.png', 'Lucky Me Beef Noodles 55g Bundle Pack 465 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000465');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000466', 6)), '4800000000466', 'Electrical Tape Small Pack 466', 'electrical tape small pack 466', 'Generic',
       (SELECT id FROM product_categories WHERE name='Hardware'),
       (SELECT id FROM business_types WHERE name='Hardware'),
       (SELECT id FROM units WHERE name='roll'),
       18.04, 22.00, 79, 79, 15, 'assets/images/products/placeholders/hardware.png', 'assets/images/products/placeholders/hardware.png', 'Electrical Tape Small Pack 466 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000466');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000467', 6)), '4800000000467', 'Rice Regular per kilo Family Pack 467', 'rice regular per kilo family pack 467', 'Generic',
       (SELECT id FROM product_categories WHERE name='Rice'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='kg'),
       57.4, 70.00, 112, 112, 20, 'assets/images/products/placeholders/rice.png', 'assets/images/products/placeholders/rice.png', 'Rice Regular per kilo Family Pack 467 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000467');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000468', 6)), '4800000000468', '555 Sardines Tomato Sauce 155g Promo Pack 468', '555 sardines tomato sauce 155g promo pack 468', '555',
       (SELECT id FROM product_categories WHERE name='Canned Goods'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='can'),
       25.42, 31.00, 108, 108, 5, 'assets/images/products/placeholders/canned_goods.png', 'assets/images/products/placeholders/canned_goods.png', '555 Sardines Tomato Sauce 155g Promo Pack 468 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000468');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000469', 6)), '4800000000469', 'Joy Dishwashing Liquid 20ml Promo Pack 469', 'joy dishwashing liquid 20ml promo pack 469', 'Joy',
       (SELECT id FROM product_categories WHERE name='Cleaning Supplies'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='sachet'),
       4.92, 6.00, 88, 88, 15, 'assets/images/products/placeholders/cleaning_supplies.png', 'assets/images/products/placeholders/cleaning_supplies.png', 'Joy Dishwashing Liquid 20ml Promo Pack 469 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000469');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000470', 6)), '4800000000470', 'Pencil No.2 Family Pack 470', 'pencil no 2 family pack 470', 'Generic',
       (SELECT id FROM product_categories WHERE name='School Supplies'),
       (SELECT id FROM business_types WHERE name='School Supplies'),
       (SELECT id FROM units WHERE name='piece'),
       6.56, 8.00, 29, 29, 15, 'assets/images/products/placeholders/school_supplies.png', 'assets/images/products/placeholders/school_supplies.png', 'Pencil No.2 Family Pack 470 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000470');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000471', 6)), '4800000000471', 'Ariel Powder Detergent 70g Small Pack 471', 'ariel powder detergent 70g small pack 471', 'Ariel',
       (SELECT id FROM product_categories WHERE name='Detergent'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='sachet'),
       6.56, 8.00, 52, 52, 20, 'assets/images/products/placeholders/detergent.png', 'assets/images/products/placeholders/detergent.png', 'Ariel Powder Detergent 70g Small Pack 471 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000471');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000472', 6)), '4800000000472', 'Biogesic 500mg Family Pack 472', 'biogesic 500mg family pack 472', 'Biogesic',
       (SELECT id FROM product_categories WHERE name='Medicine'),
       (SELECT id FROM business_types WHERE name='Pharmacy'),
       (SELECT id FROM units WHERE name='tablet'),
       7.38, 9.00, 101, 101, 15, 'assets/images/products/placeholders/medicine.png', 'assets/images/products/placeholders/medicine.png', 'Biogesic 500mg Family Pack 472 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000472');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000473', 6)), '4800000000473', 'Silver Swan Soy Sauce 1L Promo Pack 473', 'silver swan soy sauce 1l promo pack 473', 'Silver Swan',
       (SELECT id FROM product_categories WHERE name='Condiments'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='bottle'),
       68.06, 83.00, 55, 55, 10, 'assets/images/products/placeholders/condiments.png', 'assets/images/products/placeholders/condiments.png', 'Silver Swan Soy Sauce 1L Promo Pack 473 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000473');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000474', 6)), '4800000000474', 'Joy Dishwashing Liquid 20ml Regular Pack 474', 'joy dishwashing liquid 20ml regular pack 474', 'Joy',
       (SELECT id FROM product_categories WHERE name='Cleaning Supplies'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='sachet'),
       5.74, 7.00, 79, 79, 5, 'assets/images/products/placeholders/cleaning_supplies.png', 'assets/images/products/placeholders/cleaning_supplies.png', 'Joy Dishwashing Liquid 20ml Regular Pack 474 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000474');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000475', 6)), '4800000000475', 'Electrical Tape Regular Pack 475', 'electrical tape regular pack 475', 'Generic',
       (SELECT id FROM product_categories WHERE name='Hardware'),
       (SELECT id FROM business_types WHERE name='Hardware'),
       (SELECT id FROM units WHERE name='roll'),
       22.14, 27.00, 92, 92, 20, 'assets/images/products/placeholders/hardware.png', 'assets/images/products/placeholders/hardware.png', 'Electrical Tape Regular Pack 475 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000475');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000476', 6)), '4800000000476', 'Nova Multigrain Snacks 40g Regular Pack 476', 'nova multigrain snacks 40g regular pack 476', 'Nova',
       (SELECT id FROM product_categories WHERE name='Snacks'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='pack'),
       20.5, 25.00, 39, 39, 20, 'assets/images/products/placeholders/snacks.png', 'assets/images/products/placeholders/snacks.png', 'Nova Multigrain Snacks 40g Regular Pack 476 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000476');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000477', 6)), '4800000000477', 'Piattos Cheese 40g Small Pack 477', 'piattos cheese 40g small pack 477', 'Piattos',
       (SELECT id FROM product_categories WHERE name='Snacks'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='pack'),
       20.5, 25.00, 25, 25, 20, 'assets/images/products/placeholders/snacks.png', 'assets/images/products/placeholders/snacks.png', 'Piattos Cheese 40g Small Pack 477 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000477');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000478', 6)), '4800000000478', 'Argentina Corned Beef 150g Promo Pack 478', 'argentina corned beef 150g promo pack 478', 'Argentina',
       (SELECT id FROM product_categories WHERE name='Canned Goods'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='can'),
       35.26, 43.00, 40, 40, 10, 'assets/images/products/placeholders/canned_goods.png', 'assets/images/products/placeholders/canned_goods.png', 'Argentina Corned Beef 150g Promo Pack 478 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000478');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000479', 6)), '4800000000479', 'Ballpen Black Promo Pack 479', 'ballpen black promo pack 479', 'Generic',
       (SELECT id FROM product_categories WHERE name='School Supplies'),
       (SELECT id FROM business_types WHERE name='School Supplies'),
       (SELECT id FROM units WHERE name='piece'),
       9.02, 11.00, 27, 27, 10, 'assets/images/products/placeholders/school_supplies.png', 'assets/images/products/placeholders/school_supplies.png', 'Ballpen Black Promo Pack 479 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000479');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000480', 6)), '4800000000480', 'Nescafe Classic Sachet 2g Regular Pack 480', 'nescafe classic sachet 2g regular pack 480', 'Nescafe',
       (SELECT id FROM product_categories WHERE name='Coffee'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='sachet'),
       3.28, 4.00, 22, 22, 5, 'assets/images/products/placeholders/coffee.png', 'assets/images/products/placeholders/coffee.png', 'Nescafe Classic Sachet 2g Regular Pack 480 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000480');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000481', 6)), '4800000000481', 'Ariel Powder Detergent 70g Regular Pack 481', 'ariel powder detergent 70g regular pack 481', 'Ariel',
       (SELECT id FROM product_categories WHERE name='Detergent'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='sachet'),
       6.56, 8.00, 35, 35, 5, 'assets/images/products/placeholders/detergent.png', 'assets/images/products/placeholders/detergent.png', 'Ariel Powder Detergent 70g Regular Pack 481 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000481');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000482', 6)), '4800000000482', 'Diatabs Capsule Regular Pack 482', 'diatabs capsule regular pack 482', 'Diatabs',
       (SELECT id FROM product_categories WHERE name='Medicine'),
       (SELECT id FROM business_types WHERE name='Pharmacy'),
       (SELECT id FROM units WHERE name='capsule'),
       9.84, 12.00, 117, 117, 20, 'assets/images/products/placeholders/medicine.png', 'assets/images/products/placeholders/medicine.png', 'Diatabs Capsule Regular Pack 482 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000482');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000483', 6)), '4800000000483', 'Nescafe Classic Sachet 2g Regular Pack 483', 'nescafe classic sachet 2g regular pack 483', 'Nescafe',
       (SELECT id FROM product_categories WHERE name='Coffee'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='sachet'),
       2.46, 3.00, 46, 46, 15, 'assets/images/products/placeholders/coffee.png', 'assets/images/products/placeholders/coffee.png', 'Nescafe Classic Sachet 2g Regular Pack 483 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000483');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000484', 6)), '4800000000484', 'Great Taste White 30g Bundle Pack 484', 'great taste white 30g bundle pack 484', 'Great Taste',
       (SELECT id FROM product_categories WHERE name='Coffee'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='sachet'),
       8.2, 10.00, 119, 119, 10, 'assets/images/products/placeholders/coffee.png', 'assets/images/products/placeholders/coffee.png', 'Great Taste White 30g Bundle Pack 484 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000484');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000485', 6)), '4800000000485', 'Piattos Cheese 40g Bundle Pack 485', 'piattos cheese 40g bundle pack 485', 'Piattos',
       (SELECT id FROM product_categories WHERE name='Snacks'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='pack'),
       17.22, 21.00, 22, 22, 10, 'assets/images/products/placeholders/snacks.png', 'assets/images/products/placeholders/snacks.png', 'Piattos Cheese 40g Bundle Pack 485 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000485');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000486', 6)), '4800000000486', 'Electrical Tape Small Pack 486', 'electrical tape small pack 486', 'Generic',
       (SELECT id FROM product_categories WHERE name='Hardware'),
       (SELECT id FROM business_types WHERE name='Hardware'),
       (SELECT id FROM units WHERE name='roll'),
       27.06, 33.00, 87, 87, 15, 'assets/images/products/placeholders/hardware.png', 'assets/images/products/placeholders/hardware.png', 'Electrical Tape Small Pack 486 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000486');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000487', 6)), '4800000000487', 'Bond Paper Short 10pcs Regular Pack 487', 'bond paper short 10pcs regular pack 487', 'Generic',
       (SELECT id FROM product_categories WHERE name='School Supplies'),
       (SELECT id FROM business_types WHERE name='School Supplies'),
       (SELECT id FROM units WHERE name='pack'),
       12.3, 15.00, 15, 15, 5, 'assets/images/products/placeholders/school_supplies.png', 'assets/images/products/placeholders/school_supplies.png', 'Bond Paper Short 10pcs Regular Pack 487 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000487');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000488', 6)), '4800000000488', 'Kopiko Brown Coffee Twin Pack Regular Pack 488', 'kopiko brown coffee twin pack regular pack 488', 'Kopiko',
       (SELECT id FROM product_categories WHERE name='Coffee'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='pack'),
       10.66, 13.00, 95, 95, 10, 'assets/images/products/placeholders/coffee.png', 'assets/images/products/placeholders/coffee.png', 'Kopiko Brown Coffee Twin Pack Regular Pack 488 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000488');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000489', 6)), '4800000000489', 'Silver Swan Soy Sauce 1L Regular Pack 489', 'silver swan soy sauce 1l regular pack 489', 'Silver Swan',
       (SELECT id FROM product_categories WHERE name='Condiments'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='bottle'),
       67.24, 82.00, 21, 21, 10, 'assets/images/products/placeholders/condiments.png', 'assets/images/products/placeholders/condiments.png', 'Silver Swan Soy Sauce 1L Regular Pack 489 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000489');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000490', 6)), '4800000000490', 'Great Taste White 30g Regular Pack 490', 'great taste white 30g regular pack 490', 'Great Taste',
       (SELECT id FROM product_categories WHERE name='Coffee'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='sachet'),
       10.66, 13.00, 106, 106, 5, 'assets/images/products/placeholders/coffee.png', 'assets/images/products/placeholders/coffee.png', 'Great Taste White 30g Regular Pack 490 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000490');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000491', 6)), '4800000000491', 'C2 Green Tea 500ml Regular Pack 491', 'c2 green tea 500ml regular pack 491', 'C2',
       (SELECT id FROM product_categories WHERE name='Beverages'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='bottle'),
       28.7, 35.00, 56, 56, 10, 'assets/images/products/placeholders/beverages.png', 'assets/images/products/placeholders/beverages.png', 'C2 Green Tea 500ml Regular Pack 491 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000491');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000492', 6)), '4800000000492', 'Royal Tru Orange 1.5L Regular Pack 492', 'royal tru orange 1 5l regular pack 492', 'Royal',
       (SELECT id FROM product_categories WHERE name='Beverages'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='bottle'),
       82.82, 101.00, 107, 107, 20, 'assets/images/products/placeholders/beverages.png', 'assets/images/products/placeholders/beverages.png', 'Royal Tru Orange 1.5L Regular Pack 492 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000492');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000493', 6)), '4800000000493', 'Payless Xtra Big Pancit Canton Family Pack 493', 'payless xtra big pancit canton family pack 493', 'Payless',
       (SELECT id FROM product_categories WHERE name='Noodles'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='pack'),
       17.22, 21.00, 97, 97, 5, 'assets/images/products/placeholders/noodles.png', 'assets/images/products/placeholders/noodles.png', 'Payless Xtra Big Pancit Canton Family Pack 493 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000493');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000494', 6)), '4800000000494', 'Vitamin C 500mg Promo Pack 494', 'vitamin c 500mg promo pack 494', 'Generic',
       (SELECT id FROM product_categories WHERE name='Vitamins'),
       (SELECT id FROM business_types WHERE name='Pharmacy'),
       (SELECT id FROM units WHERE name='tablet'),
       4.92, 6.00, 26, 26, 5, 'assets/images/products/placeholders/vitamins.png', 'assets/images/products/placeholders/vitamins.png', 'Vitamin C 500mg Promo Pack 494 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000494');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000495', 6)), '4800000000495', 'Head & Shoulders Sachet Regular Pack 495', 'head shoulders sachet regular pack 495', 'Head & Shoulders',
       (SELECT id FROM product_categories WHERE name='Shampoo'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='sachet'),
       9.84, 12.00, 60, 60, 5, 'assets/images/products/placeholders/shampoo.png', 'assets/images/products/placeholders/shampoo.png', 'Head & Shoulders Sachet Regular Pack 495 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000495');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000496', 6)), '4800000000496', 'Safeguard Soap 60g Regular Pack 496', 'safeguard soap 60g regular pack 496', 'Safeguard',
       (SELECT id FROM product_categories WHERE name='Soap'),
       (SELECT id FROM business_types WHERE name='Grocery'),
       (SELECT id FROM units WHERE name='piece'),
       22.14, 27.00, 116, 116, 15, 'assets/images/products/placeholders/soap.png', 'assets/images/products/placeholders/soap.png', 'Safeguard Soap 60g Regular Pack 496 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000496');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000497', 6)), '4800000000497', 'Sugar White per kilo Bundle Pack 497', 'sugar white per kilo bundle pack 497', 'Generic',
       (SELECT id FROM product_categories WHERE name='Sugar'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='kg'),
       79.54, 97.00, 35, 35, 15, 'assets/images/products/placeholders/sugar.png', 'assets/images/products/placeholders/sugar.png', 'Sugar White per kilo Bundle Pack 497 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000497');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000498', 6)), '4800000000498', 'Argentina Corned Beef 150g Small Pack 498', 'argentina corned beef 150g small pack 498', 'Argentina',
       (SELECT id FROM product_categories WHERE name='Canned Goods'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='can'),
       32.8, 40.00, 23, 23, 15, 'assets/images/products/placeholders/canned_goods.png', 'assets/images/products/placeholders/canned_goods.png', 'Argentina Corned Beef 150g Small Pack 498 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000498');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000499', 6)), '4800000000499', 'Sunsilk Shampoo Sachet Family Pack 499', 'sunsilk shampoo sachet family pack 499', 'Sunsilk',
       (SELECT id FROM product_categories WHERE name='Shampoo'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='sachet'),
       7.38, 9.00, 77, 77, 15, 'assets/images/products/placeholders/shampoo.png', 'assets/images/products/placeholders/shampoo.png', 'Sunsilk Shampoo Sachet Family Pack 499 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000499');

INSERT INTO products
(product_code, barcode, product_name, normalized_product_name, brand, category_id, business_type_id, unit_id, cost_price, selling_price, quantity, stock_quantity, reorder_level, image_path, product_image, product_image_alt, status, duplicate_status)
SELECT CONCAT('PH-', RIGHT('4800000000500', 6)), '4800000000500', 'Young''s Town Sardines 155g Regular Pack 500', 'young s town sardines 155g regular pack 500', 'Young''s Town',
       (SELECT id FROM product_categories WHERE name='Canned Goods'),
       (SELECT id FROM business_types WHERE name='Sari-sari Store'),
       (SELECT id FROM units WHERE name='can'),
       16.4, 20.00, 41, 41, 10, 'assets/images/products/placeholders/canned_goods.png', 'assets/images/products/placeholders/canned_goods.png', 'Young''s Town Sardines 155g Regular Pack 500 product image', 'Approved', 'None'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE barcode='4800000000500');




