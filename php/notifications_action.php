<?php
require_once __DIR__ . '/../includes/auth.php';
require_action_login();

$action = $_GET['action'] ?? '';

if ($action === 'receipts') {
    $stmt = $pdo->query("SELECT s.id, s.invoice_no, s.total, s.payment_method, DATE_FORMAT(s.created_at, '%Y-%m-%d %H:%i') created_at, u.full_name cashier
        FROM sales s
        LEFT JOIN users u ON u.id=s.user_id
        ORDER BY s.id DESC
        LIMIT 10");
    $rows = $stmt->fetchAll();
    foreach ($rows as $idx => &$row) {
        $row['buyer_label'] = 'Buyer ' . ($idx + 1);
    }
    json_response(['success' => true, 'rows' => $rows]);
}

if ($action === 'receipt') {
    $id = (int)($_GET['id'] ?? 0);
    $stmt = $pdo->prepare("SELECT s.id, s.invoice_no, s.subtotal, s.discount, s.total, s.payment_amount, s.change_amount, s.payment_method, DATE_FORMAT(s.created_at, '%Y-%m-%d %H:%i') created_at, u.full_name cashier
        FROM sales s
        LEFT JOIN users u ON u.id=s.user_id
        WHERE s.id=?
        LIMIT 1");
    $stmt->execute([$id]);
    $receipt = $stmt->fetch();
    if (!$receipt) {
        json_response(['success' => false, 'message' => 'Receipt not found.'], 404);
    }

    $items = $pdo->prepare("SELECT si.quantity, si.price, si.subtotal, p.product_name
        FROM sale_items si
        LEFT JOIN products p ON p.id=si.product_id
        WHERE si.sale_id=?
        ORDER BY si.id");
    $items->execute([$id]);
    json_response(['success' => true, 'receipt' => $receipt, 'items' => $items->fetchAll()]);
}

json_response(['success' => false, 'message' => 'Invalid action.']);
