<?php
require_once __DIR__ . '/../includes/auth.php';
require_once __DIR__ . '/../includes/product_helpers.php';
require_action_login();

$action = $_POST['action'] ?? $_GET['action'] ?? '';

function option_rows(PDO $pdo, string $table): array {
    return $pdo->query("SELECT id, name FROM $table ORDER BY name")->fetchAll();
}

function inventory_product_select_sql(): string
{
    return "SELECT p.*, c.name category, COALESCE(NULLIF(p.brand,''), b.name) brand, u.name unit, s.name supplier, bt.name business_type
        FROM products p
        LEFT JOIN product_categories c ON c.id=p.category_id
        LEFT JOIN brands b ON b.id=p.brand_id
        LEFT JOIN units u ON u.id=p.unit_id
        LEFT JOIN suppliers s ON s.id=p.supplier_id
        LEFT JOIN business_types bt ON bt.id=p.business_type_id";
}

function can_access_product(array $product): bool
{
    return is_admin() || $product['status'] === 'Approved' || (int)$product['created_by'] === (int)current_user()['id'];
}

function can_edit_product(array $product): bool
{
    return is_admin() || ((int)$product['created_by'] === (int)current_user()['id'] && $product['status'] === 'Pending');
}

function load_product(PDO $pdo, int $id): ?array
{
    $stmt = $pdo->prepare(inventory_product_select_sql() . ' WHERE p.id=? LIMIT 1');
    $stmt->execute([$id]);
    $product = $stmt->fetch();
    if (!$product || !can_access_product($product)) {
        return null;
    }
    $product['can_edit'] = can_edit_product($product);
    return $product;
}

if ($action === 'options') {
    json_response([
        'categories' => option_rows($pdo, 'product_categories'),
        'brands' => option_rows($pdo, 'brands'),
        'units' => option_rows($pdo, 'units'),
        'suppliers' => option_rows($pdo, 'suppliers'),
        'business_types' => option_rows($pdo, 'business_types'),
    ]);
}

if ($action === 'list') {
    $page = max(1, (int)($_GET['page'] ?? 1));
    $limit = 10;
    $offset = ($page - 1) * $limit;
    $where = ['1=1'];
    $args = [];
    if (!is_admin()) {
        $where[] = "(p.status='Approved' OR p.created_by=?)";
        $args[] = current_user()['id'];
    }
    if ($s = clean($_GET['search'] ?? '')) {
        $where[] = '(p.product_code LIKE ? OR p.barcode LIKE ? OR p.product_name LIKE ?)';
        array_push($args, "%$s%", "%$s%", "%$s%");
    }
    $categoryIds = array_values(array_filter(array_map('intval', explode(',', (string)($_GET['categories'] ?? $_GET['category'] ?? '')))));
    if ($categoryIds) {
        $where[] = 'p.category_id IN (' . implode(',', array_fill(0, count($categoryIds), '?')) . ')';
        array_push($args, ...$categoryIds);
    }
    if ($b = (int)($_GET['business_type'] ?? 0)) { $where[] = 'p.business_type_id=?'; $args[] = $b; }
    if (($_GET['stock'] ?? '') === 'low') $where[] = 'p.quantity > 0 AND p.quantity <= p.reorder_level';
    if (($_GET['stock'] ?? '') === 'out') $where[] = 'p.quantity <= 0';
    if (($_GET['stock'] ?? '') === 'available') $where[] = 'p.quantity > p.reorder_level';
    $sqlWhere = implode(' AND ', $where);
    $count = $pdo->prepare("SELECT COUNT(*) FROM products p WHERE $sqlWhere");
    $count->execute($args);
    $total = (int)$count->fetchColumn();
    $stmt = $pdo->prepare(inventory_product_select_sql() . " WHERE $sqlWhere ORDER BY p.id DESC LIMIT $limit OFFSET $offset");
    $stmt->execute($args);
    $rows = $stmt->fetchAll();
    foreach ($rows as &$row) {
        $row['can_edit'] = is_admin() || ((int)$row['created_by'] === current_user()['id'] && $row['status'] === 'Pending');
    }
    json_response(['rows' => $rows, 'page' => $page, 'pages' => max(1, (int)ceil($total / $limit)), 'is_admin' => is_admin()]);
}

if (in_array($action, ['view', 'quick_view'], true)) {
    $product = load_product($pdo, (int)($_GET['id'] ?? 0));
    if (!$product) {
        json_response(['success' => false, 'message' => 'Product not found or not allowed.'], 404);
    }
    log_activity($pdo, $action === 'quick_view' ? 'Product quick viewed' : 'Product viewed');
    json_response(['success' => true, 'product' => $product, 'is_admin' => is_admin()]);
}

if ($action === 'barcode_lookup') {
    $barcode = clean($_GET['barcode'] ?? '');
    if ($barcode === '') {
        json_response(['success' => false, 'message' => 'Barcode is required.']);
    }
    $stmt = $pdo->prepare(inventory_product_select_sql() . ' WHERE p.barcode=? LIMIT 1');
    $stmt->execute([$barcode]);
    $product = $stmt->fetch();
    if (!$product || !can_access_product($product)) {
        json_response(['success' => false, 'message' => 'Product not registered.'], 404);
    }
    $product['can_edit'] = can_edit_product($product);
    log_activity($pdo, 'Product barcode checked');
    json_response(['success' => true, 'product' => $product]);
}

if ($action === 'duplicate_check') {
    $product = [
        'barcode' => clean($_GET['barcode'] ?? ''),
        'product_name' => clean($_GET['product_name'] ?? ''),
        'brand_id' => (int)($_GET['brand_id'] ?? 0),
        'brand' => clean($_GET['brand'] ?? ''),
        'category_id' => (int)($_GET['category_id'] ?? 0),
        'unit_id' => (int)($_GET['unit_id'] ?? 0),
        'business_type_id' => (int)($_GET['business_type_id'] ?? 0),
    ];
    $matches = find_duplicate_products($pdo, $product, (int)($_GET['id'] ?? 0));
    if ($matches) {
        log_activity($pdo, 'Duplicate detected');
    }
    json_response([
        'has_duplicates' => (bool)$matches,
        'status' => duplicate_status_from_matches($matches),
        'message' => $matches ? 'Possible duplicate product found. Please review before saving.' : 'No duplicate products found.',
        'matches' => $matches,
        'is_admin' => is_admin(),
    ]);
}

if ($action === 'import_duplicate_report') {
    require_action_admin();
    $batchId = (int)($_GET['batch_id'] ?? 0);
    $stmt = $pdo->prepare('SELECT row_number, product_name, barcode, status, duplicate_reference_id, message FROM product_import_rows WHERE batch_id=? AND status IN ("Exact Duplicate","Possible Duplicate","Invalid") ORDER BY row_number');
    $stmt->execute([$batchId]);
    header('Content-Type: text/csv');
    header('Content-Disposition: attachment; filename="duplicate-import-report.csv"');
    $out = fopen('php://output', 'w');
    fputcsv($out, ['Row', 'Product Name', 'Barcode', 'Status', 'Duplicate Reference ID', 'Message']);
    while ($row = $stmt->fetch()) {
        fputcsv($out, $row);
    }
    fclose($out);
    exit;
}

verify_csrf();

function selected_brand_name(PDO $pdo, ?int $brandId): string
{
    if (!$brandId) return '';
    $stmt = $pdo->prepare('SELECT name FROM brands WHERE id=?');
    $stmt->execute([$brandId]);
    return (string)($stmt->fetchColumn() ?: '');
}

function generate_product_code(PDO $pdo): string
{
    $maxCode = $pdo->query("SELECT MAX(CAST(SUBSTRING(product_code, 4) AS UNSIGNED)) FROM products WHERE product_code REGEXP '^PH-[0-9]+$'")->fetchColumn();
    $next = max(1, (int)$maxCode + 1);
    do {
        $code = 'PH-' . str_pad((string)$next, 6, '0', STR_PAD_LEFT);
        $stmt = $pdo->prepare('SELECT COUNT(*) FROM products WHERE product_code=?');
        $stmt->execute([$code]);
        $exists = (int)$stmt->fetchColumn() > 0;
        $next++;
    } while ($exists);
    return $code;
}

function update_existing_product(PDO $pdo, int $id, array $fields, ?string $imagePath = null): void
{
    $set = implode(', ', array_map(fn($k) => "$k=?", array_keys($fields)));
    $values = array_values($fields);
    if ($imagePath) {
        $set .= ', image_path=?, product_image=?';
        $values[] = $imagePath;
        $values[] = $imagePath;
    }
    $values[] = $id;
    $stmt = $pdo->prepare("UPDATE products SET $set WHERE id=?");
    $stmt->execute($values);
}

function lookup_id(PDO $pdo, string $table, string $name): ?int
{
    $name = trim($name);
    if ($name === '') return null;
    $stmt = $pdo->prepare("SELECT id FROM $table WHERE LOWER(name)=LOWER(?) LIMIT 1");
    $stmt->execute([$name]);
    $id = $stmt->fetchColumn();
    if ($id) return (int)$id;
    if (!is_admin()) return null;
    $stmt = $pdo->prepare("INSERT INTO $table (name) VALUES (?)");
    $stmt->execute([$name]);
    return (int)$pdo->lastInsertId();
}

function import_row_to_product(PDO $pdo, array $row): ?array
{
    $name = clean((string)($row['product_name'] ?? $row['Product Name'] ?? $row['name'] ?? ''));
    if ($name === '') return null;
    $categoryId = lookup_id($pdo, 'product_categories', (string)($row['category'] ?? $row['Category'] ?? 'Others'));
    $businessId = lookup_id($pdo, 'business_types', (string)($row['business_type'] ?? $row['Business Type'] ?? 'General Merchandise'));
    $unitId = lookup_id($pdo, 'units', (string)($row['unit'] ?? $row['Unit'] ?? 'piece'));
    $brand = clean((string)($row['brand'] ?? $row['Brand'] ?? ''));
    $brandId = $brand ? lookup_id($pdo, 'brands', $brand) : null;
    $barcode = clean((string)($row['barcode'] ?? $row['Barcode'] ?? '')) ?: null;
    $parts = extract_product_size_parts($name);
    $cleanProductName = ensure_brand_in_product_display_name(clean_product_display_name($name), $brand);
    return [
        'product_code' => clean((string)($row['product_code'] ?? $row['Product Code'] ?? 'IMP-' . date('YmdHis') . random_int(1000, 9999))),
        'barcode' => $barcode,
        'product_name' => $cleanProductName,
        'product_size_value' => (float)($row['product_size_value'] ?? $row['Size Value'] ?? 0) ?: $parts['size_value'],
        'product_size_unit' => clean((string)($row['product_size_unit'] ?? $row['Size Unit'] ?? '')) ?: $parts['size_unit'],
        'package_type' => clean((string)($row['package_type'] ?? $row['Package Type'] ?? '')),
        'normalized_product_name' => normalize_product_name($cleanProductName),
        'brand' => $brand,
        'brand_id' => $brandId,
        'category_id' => $categoryId,
        'business_type_id' => $businessId,
        'unit_id' => $unitId,
        'cost_price' => (float)($row['cost_price'] ?? $row['Cost Price'] ?? 0),
        'selling_price' => (float)($row['selling_price'] ?? $row['Suggested Selling Price'] ?? $row['Selling Price'] ?? 0),
        'quantity' => (int)($row['stock_quantity'] ?? $row['quantity'] ?? $row['Stock Quantity'] ?? 0),
        'stock_quantity' => (int)($row['stock_quantity'] ?? $row['quantity'] ?? $row['Stock Quantity'] ?? 0),
        'reorder_level' => (int)($row['reorder_level'] ?? $row['Reorder Level'] ?? 10),
        'expiration_date' => clean((string)($row['expiration_date'] ?? $row['Expiration Date'] ?? '')) ?: null,
        'image_path' => clean((string)($row['product_image'] ?? $row['Product Image'] ?? 'assets/images/products/placeholders/default_product.png')),
        'product_image' => clean((string)($row['product_image'] ?? $row['Product Image'] ?? 'assets/images/products/placeholders/default_product.png')),
        'status' => 'Approved',
        'created_by' => current_user()['id'],
        'approved_by' => current_user()['id'],
        'approved_at' => date('Y-m-d H:i:s'),
    ];
}

if ($action === 'import_scan') {
    require_action_admin();
    $rows = json_decode($_POST['rows'] ?? '[]', true);
    if (!is_array($rows) || !$rows) {
        json_response(['success' => false, 'message' => 'No import rows found.']);
    }
    $summary = ['total_rows' => count($rows), 'new_products' => 0, 'exact_duplicates' => 0, 'possible_duplicates' => 0, 'invalid_rows' => 0];
    $pdo->beginTransaction();
    $stmt = $pdo->prepare('INSERT INTO product_import_batches (file_name, total_rows, imported_by) VALUES (?, ?, ?)');
    $stmt->execute([clean($_POST['file_name'] ?? 'product-import'), count($rows), current_user()['id']]);
    $batchId = (int)$pdo->lastInsertId();
    $_SESSION['import_valid_rows'][$batchId] = [];
    foreach ($rows as $i => $row) {
        $product = import_row_to_product($pdo, is_array($row) ? $row : []);
        if (!$product || !$product['selling_price']) {
            $summary['invalid_rows']++;
            $pdo->prepare('INSERT INTO product_import_rows (batch_id, row_number, product_name, barcode, status, message) VALUES (?, ?, ?, ?, "Invalid", ?)')
                ->execute([$batchId, $i + 2, $product['product_name'] ?? '', $product['barcode'] ?? '', 'Missing product name or selling price.']);
            continue;
        }
        $matches = find_duplicate_products($pdo, $product);
        $status = 'New';
        $message = 'Ready to import.';
        $ref = null;
        if ($matches) {
            $ref = $matches[0]['id'];
            if (duplicate_status_from_matches($matches) === 'Exact Duplicate') {
                $summary['exact_duplicates']++;
                $status = 'Exact Duplicate';
                $message = 'Exact duplicate barcode found.';
            } else {
                $summary['possible_duplicates']++;
                $status = 'Possible Duplicate';
                $message = 'Possible duplicate product found. Please review before saving.';
            }
        } else {
            $summary['new_products']++;
            $_SESSION['import_valid_rows'][$batchId][] = $product;
        }
        $pdo->prepare('INSERT INTO product_import_rows (batch_id, row_number, product_name, barcode, status, duplicate_reference_id, message) VALUES (?, ?, ?, ?, ?, ?, ?)')
            ->execute([$batchId, $i + 2, $product['product_name'], $product['barcode'], $status, $ref, $message]);
    }
    $pdo->prepare('UPDATE product_import_batches SET new_products=?, exact_duplicates=?, possible_duplicates=?, invalid_rows=? WHERE id=?')
        ->execute([$summary['new_products'], $summary['exact_duplicates'], $summary['possible_duplicates'], $summary['invalid_rows'], $batchId]);
    log_activity($pdo, 'Product imported scan completed');
    $pdo->commit();
    json_response(['success' => true, 'batch_id' => $batchId, 'summary' => $summary, 'message' => 'Import scan completed.']);
}

if ($action === 'import_commit') {
    require_action_admin();
    $batchId = (int)($_POST['batch_id'] ?? 0);
    $rows = $_SESSION['import_valid_rows'][$batchId] ?? [];
    if (!$rows) json_response(['success' => false, 'message' => 'No valid new products to import.']);
    $pdo->beginTransaction();
    foreach ($rows as $product) {
        $product['duplicate_status'] = 'None';
        $columns = array_keys($product);
        $stmt = $pdo->prepare('INSERT INTO products (' . implode(',', $columns) . ') VALUES (' . implode(',', array_fill(0, count($columns), '?')) . ')');
        $stmt->execute(array_values($product));
    }
    $pdo->prepare('UPDATE product_import_rows SET status="Imported" WHERE batch_id=? AND status="New"')->execute([$batchId]);
    log_duplicate_action($pdo, null, null, 'Imported', count($rows) . ' products imported from clean rows.');
    log_activity($pdo, 'Product imported');
    $pdo->commit();
    unset($_SESSION['import_valid_rows'][$batchId]);
    json_response(['success' => true, 'message' => count($rows) . ' products imported.']);
}

if ($action === 'delete') {
    require_action_admin();
    $stmt = $pdo->prepare('DELETE FROM products WHERE id=?');
    $stmt->execute([(int)$_POST['id']]);
    log_activity($pdo, 'Product deleted');
    json_response(['success' => true, 'message' => 'Product deleted.']);
}

if ($action === 'merge_duplicate') {
    require_action_admin();
    $sourceId = (int)($_POST['source_id'] ?? 0);
    $targetId = (int)($_POST['target_id'] ?? 0);
    if (!$sourceId || !$targetId || $sourceId === $targetId) {
        json_response(['success' => false, 'message' => 'Invalid merge request.']);
    }
    $source = $pdo->prepare('SELECT * FROM products WHERE id=?');
    $source->execute([$sourceId]);
    $sourceRow = $source->fetch();
    if (!$sourceRow) json_response(['success' => false, 'message' => 'Source product not found.']);
    $pdo->beginTransaction();
    $pdo->prepare('UPDATE products SET quantity = quantity + ?, stock_quantity = COALESCE(stock_quantity, quantity) + ?, selling_price=?, cost_price=? WHERE id=?')
        ->execute([(int)$sourceRow['quantity'], (int)$sourceRow['quantity'], $sourceRow['selling_price'], $sourceRow['cost_price'], $targetId]);
    $pdo->prepare('UPDATE products SET status="Rejected", duplicate_status="Merged", duplicate_reference_id=?, remarks="Merged with existing product" WHERE id=?')
        ->execute([$targetId, $sourceId]);
    log_duplicate_action($pdo, $sourceId, $targetId, 'Merged', 'Product merged with existing product.');
    log_activity($pdo, 'Product merged');
    $pdo->commit();
    json_response(['success' => true, 'message' => 'Product merged with existing product.']);
}

if ($action === 'create' || $action === 'update') {
    $id = (int)($_POST['id'] ?? 0);
    if ($action === 'update') {
        $own = $pdo->prepare('SELECT created_by, status FROM products WHERE id=?');
        $own->execute([$id]);
        $existing = $own->fetch();
        if (!$existing || (!is_admin() && ((int)$existing['created_by'] !== current_user()['id'] || $existing['status'] !== 'Pending'))) {
            json_response(['success' => false, 'message' => 'You cannot edit this product.'], 403);
        }
    }

    $brandId = (int)($_POST['brand_id'] ?? 0) ?: null;
    $quantity = (int)($_POST['quantity'] ?? 0);
    $nameParts = extract_product_size_parts(clean($_POST['product_name'] ?? ''));
    $brandName = selected_brand_name($pdo, $brandId);
    $productName = ensure_brand_in_product_display_name(clean_product_display_name(clean($_POST['product_name'] ?? '')), $brandName);
    $sizeValue = ($_POST['product_size_value'] ?? '') === '' ? $nameParts['size_value'] : (float)$_POST['product_size_value'];
    $sizeUnit = clean($_POST['product_size_unit'] ?? '') ?: $nameParts['size_unit'];
    $normalizedName = normalize_product_name($productName);
    $fields = [
        'barcode' => clean($_POST['barcode'] ?? '') ?: null,
        'product_name' => $productName,
        'product_size_value' => $sizeValue,
        'product_size_unit' => $sizeUnit,
        'package_type' => clean($_POST['package_type'] ?? '') ?: null,
        'normalized_product_name' => $normalizedName,
        'brand' => $brandName,
        'description' => clean($_POST['description'] ?? ''),
        'category_id' => (int)($_POST['category_id'] ?? 0) ?: null,
        'brand_id' => $brandId,
        'unit_id' => (int)($_POST['unit_id'] ?? 0) ?: null,
        'cost_price' => (float)($_POST['cost_price'] ?? 0),
        'selling_price' => (float)($_POST['selling_price'] ?? 0),
        'quantity' => $quantity,
        'stock_quantity' => $quantity,
        'reorder_level' => (int)($_POST['reorder_level'] ?? 0),
        'expiration_date' => clean($_POST['expiration_date'] ?? '') ?: null,
        'supplier_id' => (int)($_POST['supplier_id'] ?? 0) ?: null,
        'business_type_id' => (int)($_POST['business_type_id'] ?? 0) ?: null,
    ];
    if ($fields['product_name'] === '') {
        json_response(['success' => false, 'message' => 'Product name is required.']);
    }

    $imagePath = null;
    if (!empty($_FILES['image']['name']) && is_uploaded_file($_FILES['image']['tmp_name'])) {
        $ext = strtolower(pathinfo($_FILES['image']['name'], PATHINFO_EXTENSION));
        if (!in_array($ext, ['jpg', 'jpeg', 'png', 'gif', 'webp'], true)) json_response(['success' => false, 'message' => 'Invalid image type.']);
        $imagePath = 'uploads/product_' . time() . '_' . random_int(1000, 9999) . '.' . $ext;
        move_uploaded_file($_FILES['image']['tmp_name'], __DIR__ . '/../' . $imagePath);
    }

    try {
        $matches = find_duplicate_products($pdo, $fields, $id);
        $duplicateStatus = duplicate_status_from_matches($matches);
        $duplicateRef = $matches[0]['id'] ?? null;
        $hasExactBarcode = false;
        foreach ($matches as $match) {
            if ($match['type'] === 'Exact Duplicate') {
                $hasExactBarcode = true;
                $duplicateRef = $match['id'];
                break;
            }
        }
        $decision = $_POST['duplicate_decision'] ?? '';
        $decisionTarget = (int)($_POST['duplicate_reference_id'] ?? $duplicateRef);

        if ($matches && is_admin() && $decision === '') {
            log_duplicate_action($pdo, $id ?: null, $duplicateRef ? (int)$duplicateRef : null, 'Detected', 'Admin product entry has possible duplicates.');
            json_response([
                'success' => false,
                'duplicate_warning' => true,
                'message' => 'Possible duplicate product found. Please review before saving.',
                'status' => $duplicateStatus,
                'matches' => $matches,
            ]);
        }

        if ($hasExactBarcode && !is_admin()) {
            log_duplicate_action($pdo, null, $duplicateRef ? (int)$duplicateRef : null, 'Detected', 'Staff attempted to submit exact duplicate barcode.');
            json_response(['success' => false, 'duplicate_warning' => true, 'message' => 'Barcode already exists. Exact duplicate barcode is not allowed.', 'matches' => $matches]);
        }

        if (is_admin() && in_array($decision, ['merge', 'update_existing'], true) && $decisionTarget) {
            if ($decision === 'merge') {
                $pdo->prepare('UPDATE products SET quantity = quantity + ?, stock_quantity = COALESCE(stock_quantity, quantity) + ? WHERE id=?')
                    ->execute([$fields['quantity'], $fields['quantity'], $decisionTarget]);
                log_duplicate_action($pdo, null, $decisionTarget, 'Merged', 'Admin merged new product entry into existing product.');
                log_activity($pdo, 'Product merged');
                json_response(['success' => true, 'message' => 'Product quantity merged with existing product.']);
            }
            update_existing_product($pdo, $decisionTarget, $fields, $imagePath);
            log_duplicate_action($pdo, null, $decisionTarget, 'Updated', 'Admin updated existing product from duplicate review.');
            log_activity($pdo, 'Product updated from duplicate review');
            json_response(['success' => true, 'message' => 'Existing product updated.']);
        }

        if ($hasExactBarcode) {
            json_response(['success' => false, 'duplicate_warning' => true, 'message' => 'Barcode already exists. Exact duplicate barcode is not allowed.', 'matches' => $matches]);
        }

        if ($action === 'create') {
            $status = is_admin() ? 'Approved' : 'Pending';
            if (!is_admin() && $matches) {
                $status = 'Pending';
            }
            $insert = $fields;
            $insert['product_code'] = generate_product_code($pdo);
            $insert['image_path'] = $imagePath;
            $insert['product_image'] = $imagePath;
            $insert['status'] = $status;
            $insert['duplicate_status'] = $matches ? $duplicateStatus : 'None';
            $insert['duplicate_reference_id'] = $duplicateRef;
            $insert['created_by'] = current_user()['id'];
            $insert['approved_by'] = is_admin() ? current_user()['id'] : null;
            $insert['approved_at'] = is_admin() ? date('Y-m-d H:i:s') : null;
            $columns = array_keys($insert);
            $placeholders = implode(',', array_fill(0, count($columns), '?'));
            $stmt = $pdo->prepare('INSERT INTO products (' . implode(',', $columns) . ") VALUES ($placeholders)");
            $stmt->execute(array_values($insert));
            $newId = (int)$pdo->lastInsertId();
            if ($matches) {
                log_duplicate_action($pdo, $newId, $duplicateRef ? (int)$duplicateRef : null, 'Detected', 'Duplicate detected during product creation.');
                log_activity($pdo, 'Duplicate detected');
            }
            log_activity($pdo, is_admin() ? 'Product added and approved' : 'Product submitted for approval');
            json_response(['success' => true, 'message' => $matches && !is_admin() ? 'Possible duplicate submitted for admin approval.' : (is_admin() ? 'Product added.' : 'Product submitted for approval.')]);
        }
        $fields['duplicate_status'] = $matches ? $duplicateStatus : 'None';
        $fields['duplicate_reference_id'] = $duplicateRef;
        update_existing_product($pdo, $id, $fields, $imagePath);
        if ($matches) {
            log_duplicate_action($pdo, $id, $duplicateRef ? (int)$duplicateRef : null, 'Detected', 'Duplicate detected during product update.');
        }
        log_activity($pdo, 'Product edited');
        json_response(['success' => true, 'message' => 'Product updated.']);
    } catch (PDOException $e) {
        json_response(['success' => false, 'message' => 'Product code or barcode already exists.']);
    }
}

json_response(['success' => false, 'message' => 'Invalid action.']);
