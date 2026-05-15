# Web-Based Inventory Management System

## Stack
- Frontend: HTML, CSS, JavaScript, Bootstrap
- Backend: PHP with PDO prepared statements
- Database: MySQL
- Charts: Chart.js
- Export: SheetJS Excel export and html2canvas table image export

## XAMPP Setup
1. Copy or keep this folder at `C:\xampp\htdocs\InventoryManagementSystem` or `C:\System\htdocs\InventoryManagementSystem`.
2. Start Apache and MySQL in XAMPP.
3. Open phpMyAdmin and import `database/inventory_system.sql`.
4. Import `database/ph_default_products_migration.sql` to add Philippine starter products, duplicate tracking fields, import audit tables, and product placeholder images.
5. Import `database/product_size_fields_migration.sql`, then run `php database/normalize_product_sizes.php` to separate brand names, sizes such as `150g`, and package text from product names.
6. If your MySQL username or password is different, set `DB_HOST`, `DB_NAME`, `DB_USER`, `DB_PASS`, and `DB_CHARSET` in your hosting environment or update `config/db.php` locally.
7. Browse to `http://localhost/InventoryManagementSystem/`.

## Demo Accounts
- Admin: `admin` / `admin123`
- Staff: `staff` / `admin123`

## Main Rules
- Admin can access all pages, approve/reject products, manage users, settings, reports, logs, inventory, and POS.
- User/Staff can access dashboard, inventory submissions, and POS.
- User-submitted products remain `Pending` until approved by Admin.
- Staff may edit their own pending product submissions before approval.

## Important Files
- Pages: `pages/*.php`
- Page scripts: `js/*.js`
- Action APIs: `php/*_action.php`
- Shared database connection: `config/db.php`
- Session/security helpers: `includes/auth.php`
- Shared layout/sidebar: `includes/layout.php`
- CSS: `assets/css/style.css`
- SQL schema and sample data: `database/inventory_system.sql`
- Philippine default products and duplicate-detection migration: `database/ph_default_products_migration.sql`
- Product size/package migration: `database/product_size_fields_migration.sql`
- Product name cleanup script: `database/normalize_product_sizes.php`

## Philippine Default Product Database
- Adds 500 starter products for sari-sari stores, grocery, pharmacy, hardware, school supplies, coffee shops, restaurants, service businesses, and general merchandise.
- Adds duplicate detection fields: `normalized_product_name`, `duplicate_status`, `duplicate_reference_id`, `duplicate_notes`, `brand`, `stock_quantity`, and product image aliases.
- Adds import audit tables: `product_import_batches`, `product_import_rows`, and `product_duplicate_actions`.
- Product prices are suggested PHP starter prices and should be updated by the admin based on supplier and location.

## Duplicate Detection
- Exact barcode duplicates are blocked.
- Similar product names, same name/brand/unit, and same name/category/business type show duplicate warnings.
- Admins can merge, update existing, or save possible duplicates as new.
- Staff-submitted possible duplicates remain pending for admin approval.
- Import scans show total rows, new products, exact duplicates, possible duplicates, and invalid rows before inserting.
