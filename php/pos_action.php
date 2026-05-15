<?php
require_once __DIR__ . '/../includes/auth.php';
require_once __DIR__ . '/../includes/pos_printer.php';
require_action_login();

$action = $_POST['action'] ?? $_GET['action'] ?? '';

function receipt_money($amount) {
    return number_format((float)$amount, 2);
}

function build_receipt_text($invoice, $items, $subtotal, $discount, $total, $payment, $change, $cashier) {
    $width = 42;
    $text = "Receipt\n";
    $text .= "Invoice: $invoice\n";
    $text .= "Date: " . date('Y-m-d H:i') . "\n";
    $text .= "Cashier: $cashier\n";
    $text .= str_repeat('-', $width) . "\n";
    foreach ($items as $item) {
        $name = substr($item['name'], 0, 24);
        $qty = (string)$item['qty'];
        $amount = receipt_money($item['subtotal']);
        $text .= str_pad($name, 26) . str_pad($qty, 4, ' ', STR_PAD_LEFT) . str_pad($amount, 12, ' ', STR_PAD_LEFT) . "\n";
    }
    $text .= str_repeat('-', $width) . "\n";
    $text .= str_pad('Subtotal:', 26) . str_pad(receipt_money($subtotal), 16, ' ', STR_PAD_LEFT) . "\n";
    $text .= str_pad('Discount:', 26) . str_pad(receipt_money($discount), 16, ' ', STR_PAD_LEFT) . "\n";
    $text .= str_pad('Total:', 26) . str_pad(receipt_money($total), 16, ' ', STR_PAD_LEFT) . "\n";
    $text .= str_pad('Payment:', 26) . str_pad(receipt_money($payment), 16, ' ', STR_PAD_LEFT) . "\n";
    $text .= str_pad('Change:', 26) . str_pad(receipt_money($change), 16, ' ', STR_PAD_LEFT) . "\n";
    $text .= "\nThank you!\n\n";
    return $text;
}

function windows_cmd_quote($value) {
    return '"' . str_replace('"', '\"', $value) . '"';
}

function direct_print_receipt($receiptText) {
    if (!POS_DIRECT_PRINT_ENABLED) {
        return ['success' => false, 'message' => 'Direct printing is not enabled.'];
    }
    if (!POS_PRINTER_SHARE) {
        return ['success' => false, 'message' => 'Receipt printer share path is not configured.'];
    }
    if (stripos(PHP_OS_FAMILY, 'Windows') === false) {
        return ['success' => false, 'message' => 'Direct print helper is configured for Windows/XAMPP only.'];
    }
    if (!function_exists('shell_exec')) {
        return ['success' => false, 'message' => 'PHP shell_exec is disabled, so direct printing cannot run.'];
    }

    $payload = "\x1B\x40";
    if (POS_OPEN_CASH_DRAWER) {
        $payload .= "\x1B\x70\x00\x19\xFA";
    }
    $payload .= $receiptText;
    if (POS_CUT_RECEIPT) {
        $payload .= "\n\n\x1D\x56\x00";
    }

    $file = tempnam(sys_get_temp_dir(), 'ims_receipt_');
    if (!$file || file_put_contents($file, $payload) === false) {
        return ['success' => false, 'message' => 'Unable to create receipt print file.'];
    }

    $command = 'cmd /C copy /B ' . windows_cmd_quote($file) . ' ' . windows_cmd_quote(POS_PRINTER_SHARE) . ' 2>&1';
    $output = shell_exec($command);
    @unlink($file);

    $printed = is_string($output) && stripos($output, '1 file(s) copied') !== false;
    return [
        'success' => $printed,
        'message' => $printed ? 'Receipt sent to printer and cash drawer pulse sent.' : 'Receipt saved, but direct print failed: ' . trim((string)$output),
    ];
}

if ($action === 'methods') {
    $value = $pdo->query("SELECT setting_value FROM settings WHERE setting_key='payment_methods'")->fetchColumn() ?: 'Cash';
    $categories = $pdo->query("SELECT id, name FROM product_categories ORDER BY name")->fetchAll();
    json_response(['methods' => array_map('trim', explode(',', $value)), 'categories' => $categories]);
}

if ($action === 'search') {
    $term = '%' . clean($_GET['term'] ?? '') . '%';
    $categoryIds = array_values(array_filter(array_map('intval', explode(',', (string)($_GET['category_ids'] ?? $_GET['category_id'] ?? '')))));
    $where = "p.status='Approved' AND p.quantity > 0 AND (p.product_code LIKE ? OR p.barcode LIKE ? OR p.product_name LIKE ?)";
    $args = [$term, $term, $term];
    if ($categoryIds) {
        $where .= ' AND p.category_id IN (' . implode(',', array_fill(0, count($categoryIds), '?')) . ')';
        array_push($args, ...$categoryIds);
    }
    $stmt = $pdo->prepare("SELECT p.id, p.product_code, p.barcode, p.product_name, COALESCE(NULLIF(p.brand,''), br.name) brand, p.product_size_value, p.product_size_unit, p.package_type, p.selling_price, p.quantity, p.reorder_level, p.image_path, c.name category, bt.name business_type
        FROM products p
        LEFT JOIN product_categories c ON c.id=p.category_id
        LEFT JOIN brands br ON br.id=p.brand_id
        LEFT JOIN business_types bt ON bt.id=p.business_type_id
        WHERE $where
        ORDER BY p.product_name LIMIT 30");
    $stmt->execute($args);
    json_response(['rows' => $stmt->fetchAll(), 'is_admin' => is_admin()]);
}

if ($action === 'barcode') {
    $code = clean($_GET['code'] ?? '');
    $stmt = $pdo->prepare("SELECT p.id, p.product_code, p.barcode, p.product_name, COALESCE(NULLIF(p.brand,''), br.name) brand, p.product_size_value, p.product_size_unit, p.package_type, p.selling_price, p.quantity, p.reorder_level, p.image_path, c.name category, bt.name business_type
        FROM products p
        LEFT JOIN product_categories c ON c.id=p.category_id
        LEFT JOIN brands br ON br.id=p.brand_id
        LEFT JOIN business_types bt ON bt.id=p.business_type_id
        WHERE p.status='Approved' AND p.barcode=? LIMIT 1");
    $stmt->execute([$code]);
    $product = $stmt->fetch();
    if (!$product) json_response(['success' => false, 'message' => 'Product not registered']);
    json_response(['success' => true, 'product' => $product]);
}

verify_csrf();

if ($action === 'save') {
    $cart = json_decode($_POST['cart'] ?? '[]', true);
    if (!$cart) json_response(['success' => false, 'message' => 'Cart is empty.']);
    $discount = max(0, (float)($_POST['discount'] ?? 0));
    $payment = max(0, (float)($_POST['payment_amount'] ?? 0));
    $method = clean($_POST['payment_method'] ?? 'Cash');

    $pdo->beginTransaction();
    $items = [];
    $subtotal = 0;
    foreach ($cart as $row) {
        $stmt = $pdo->prepare('SELECT id, product_name, selling_price, quantity FROM products WHERE id=? AND status="Approved" FOR UPDATE');
        $stmt->execute([(int)$row['id']]);
        $product = $stmt->fetch();
        $qty = max(1, (int)$row['qty']);
        if (!$product || $product['quantity'] < $qty) {
            $pdo->rollBack();
            json_response(['success' => false, 'message' => 'Insufficient stock for ' . ($product['product_name'] ?? 'product')]);
        }
        $line = $qty * (float)$product['selling_price'];
        $subtotal += $line;
        $items[] = ['id' => $product['id'], 'name' => $product['product_name'], 'qty' => $qty, 'price' => (float)$product['selling_price'], 'subtotal' => $line];
    }
    $total = max(0, $subtotal - $discount);
    if ($payment < $total) {
        $pdo->rollBack();
        json_response(['success' => false, 'message' => 'Payment is less than total.']);
    }
    $invoice = 'INV-' . date('YmdHis') . random_int(10, 99);
    $stmt = $pdo->prepare('INSERT INTO sales (invoice_no, user_id, subtotal, discount, total, payment_amount, change_amount, payment_method) VALUES (?, ?, ?, ?, ?, ?, ?, ?)');
    $stmt->execute([$invoice, current_user()['id'], $subtotal, $discount, $total, $payment, $payment - $total, $method]);
    $saleId = (int)$pdo->lastInsertId();
    foreach ($items as $item) {
        $pdo->prepare('INSERT INTO sale_items (sale_id, product_id, quantity, price, subtotal) VALUES (?, ?, ?, ?, ?)')->execute([$saleId, $item['id'], $item['qty'], $item['price'], $item['subtotal']]);
        $pdo->prepare('UPDATE products SET quantity = quantity - ? WHERE id=?')->execute([$item['qty'], $item['id']]);
    }
    log_activity($pdo, "Sales transaction $invoice");
    $pdo->commit();

    $lines = '';
    foreach ($items as $item) $lines .= '<tr><td>' . htmlspecialchars($item['name']) . '</td><td>' . $item['qty'] . '</td><td>' . number_format($item['subtotal'], 2) . '</td></tr>';
    $receipt = "<div style='font-family:Arial;width:300px'><h3>Receipt</h3><p>Invoice: $invoice<br>Date: " . date('Y-m-d H:i') . "<br>Cashier: " . htmlspecialchars(current_user()['full_name']) . "</p><table width='100%'>$lines</table><hr><p>Subtotal: " . number_format($subtotal, 2) . "<br>Discount: " . number_format($discount, 2) . "<br><b>Total: " . number_format($total, 2) . "</b><br>Payment: " . number_format($payment, 2) . "<br>Change: " . number_format($payment - $total, 2) . "</p></div>";
    $receiptText = build_receipt_text($invoice, $items, $subtotal, $discount, $total, $payment, $payment - $total, current_user()['full_name']);
    $printResult = direct_print_receipt($receiptText);
    $message = 'Transaction saved.';
    if (POS_DIRECT_PRINT_ENABLED) {
        $message .= ' ' . $printResult['message'];
    }
    json_response(['success' => true, 'message' => $message, 'receipt_html' => $receipt, 'print_result' => $printResult]);
}

json_response(['success' => false, 'message' => 'Invalid action.']);
