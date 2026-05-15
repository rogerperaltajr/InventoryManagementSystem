<?php
require_once __DIR__ . '/../includes/auth.php';
require_once __DIR__ . '/../includes/sales_helpers.php';
require_action_login();
ensure_sales_buyer_column($pdo);

$action = $_GET['action'] ?? '';

if ($action === 'receipts') {
    $stmt = $pdo->query("SELECT s.id, s.invoice_no, s.buyer_name, s.total, s.payment_method, DATE_FORMAT(s.created_at, '%Y-%m-%d %H:%i') created_at, u.full_name cashier
        FROM sales s
        LEFT JOIN users u ON u.id=s.user_id
        ORDER BY s.id DESC
        LIMIT 3");
    $rows = $stmt->fetchAll();
    foreach ($rows as &$row) {
        $row['buyer_label'] = sale_buyer_label($row);
    }
    json_response(['success' => true, 'rows' => $rows]);
}

if ($action === 'receipt') {
    $id = (int)($_GET['id'] ?? 0);
    $stmt = $pdo->prepare("SELECT s.id, s.invoice_no, s.buyer_name, s.subtotal, s.discount, s.total, s.payment_amount, s.change_amount, s.payment_method, DATE_FORMAT(s.created_at, '%Y-%m-%d %H:%i') created_at, u.full_name cashier
        FROM sales s
        LEFT JOIN users u ON u.id=s.user_id
        WHERE s.id=?
        LIMIT 1");
    $stmt->execute([$id]);
    $receipt = $stmt->fetch();
    if (!$receipt) {
        json_response(['success' => false, 'message' => 'Receipt not found.'], 404);
    }
    $receipt['buyer_label'] = sale_buyer_label($receipt);

    $items = $pdo->prepare("SELECT si.quantity, si.price, si.subtotal, p.product_name
        FROM sale_items si
        LEFT JOIN products p ON p.id=si.product_id
        WHERE si.sale_id=?
        ORDER BY si.id");
    $items->execute([$id]);
    json_response(['success' => true, 'receipt' => $receipt, 'items' => $items->fetchAll()]);
}

json_response(['success' => false, 'message' => 'Invalid action.']);
