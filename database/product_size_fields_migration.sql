USE inventory_system;

ALTER TABLE products ADD COLUMN IF NOT EXISTS product_size_value DECIMAL(10,2) NULL AFTER product_name;
ALTER TABLE products ADD COLUMN IF NOT EXISTS product_size_unit VARCHAR(30) NULL AFTER product_size_value;
ALTER TABLE products ADD COLUMN IF NOT EXISTS package_type VARCHAR(60) NULL AFTER product_size_unit;
ALTER TABLE products ADD INDEX IF NOT EXISTS idx_products_size (product_size_value, product_size_unit);

