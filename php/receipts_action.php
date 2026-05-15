<?php
require_once __DIR__ . '/../includes/auth.php';
require_once __DIR__ . '/../includes/sales_helpers.php';
require_action_admin();
ensure_sales_buyer_column($pdo);

$action = $_POST['action'] ?? $_GET['action'] ?? '';

if ($action === 'list') {
    $from = clean($_GET['from'] ?? '');
    $to = clean($_GET['to'] ?? '');
    $limitParam = $_GET['limit'] ?? '20';
    $page = max(1, (int)($_GET['page'] ?? 1));
    $allowedLimits = ['20', '40', '60', '100', 'all'];
    if (!in_array($limitParam, $allowedLimits, true)) $limitParam = '20';

    $where = ['1=1'];
    $args = [];
    if ($from !== '') {
        $where[] = 'DATE(s.created_at) >= ?';
        $args[] = $from;
    }
    if ($to !== '') {
        $where[] = 'DATE(s.created_at) <= ?';
        $args[] = $to;
    }
    $sqlWhere = implode(' AND ', $where);

    $count = $pdo->prepare("SELECT COUNT(*) FROM sales s WHERE $sqlWhere");
    $count->execute($args);
    $totalRows = (int)$count->fetchColumn();

    $limitSql = '';
    if ($limitParam !== 'all') {
        $limit = (int)$limitParam;
        $offset = ($page - 1) * $limit;
        $limitSql = " LIMIT $limit OFFSET $offset";
    } else {
        $limit = max(1, $totalRows);
        $page = 1;
    }

    $stmt = $pdo->prepare("SELECT s.id, s.invoice_no, s.buyer_name, DATE_FORMAT(s.created_at, '%Y-%m-%d %H:%i') created_at, u.full_name cashier, s.subtotal, s.discount, s.total, s.payment_amount, s.change_amount, s.payment_method,
            COALESCE(SUM(si.quantity), 0) item_count
        FROM sales s
        LEFT JOIN users u ON u.id=s.user_id
        LEFT JOIN sale_items si ON si.sale_id=s.id
        WHERE $sqlWhere
        GROUP BY s.id
        ORDER BY s.id DESC$limitSql");
    $stmt->execute($args);
    $rows = $stmt->fetchAll();
    foreach ($rows as &$row) {
        $row['buyer_label'] = sale_buyer_label($row);
    }

    json_response([
        'success' => true,
        'rows' => $rows,
        'page' => $page,
        'pages' => $limitParam === 'all' ? 1 : max(1, (int)ceil($totalRows / max(1, $limit))),
        'total' => $totalRows,
        'limit' => $limitParam,
    ]);
}

if ($action === 'view') {
    $id = (int)($_GET['id'] ?? 0);
    $stmt = $pdo->prepare("SELECT s.id, s.invoice_no, s.buyer_name, s.subtotal, s.discount, s.total, s.payment_amount, s.change_amount, s.payment_method, DATE_FORMAT(s.created_at, '%Y-%m-%d %H:%i') created_at, u.full_name cashier
        FROM sales s
        LEFT JOIN users u ON u.id=s.user_id
        WHERE s.id=?
        LIMIT 1");
    $stmt->execute([$id]);
    $receipt = $stmt->fetch();
    if (!$receipt) json_response(['success' => false, 'message' => 'Receipt not found.'], 404);
    $receipt['buyer_label'] = sale_buyer_label($receipt);

    $items = $pdo->prepare("SELECT si.quantity, si.price, si.subtotal, p.product_name
        FROM sale_items si
        LEFT JOIN products p ON p.id=si.product_id
        WHERE si.sale_id=?
        ORDER BY si.id");
    $items->execute([$id]);
    json_response(['success' => true, 'receipt' => $receipt, 'items' => $items->fetchAll()]);
}

verify_csrf();

if ($action === 'update') {
    $id = (int)($_POST['id'] ?? 0);
    $buyerName = clean($_POST['buyer_name'] ?? '');
    $paymentMethod = clean($_POST['payment_method'] ?? 'Cash');
    $stmt = $pdo->prepare('UPDATE sales SET buyer_name=?, payment_method=? WHERE id=?');
    $stmt->execute([$buyerName ?: null, $paymentMethod, $id]);
    log_activity($pdo, 'Receipt buyer updated');
    json_response(['success' => true, 'message' => 'Buyer receipt updated.']);
}

if ($action === 'delete') {
    $id = (int)($_POST['id'] ?? 0);
    $items = $pdo->prepare('SELECT product_id, quantity FROM sale_items WHERE sale_id=?');
    $items->execute([$id]);
    $rows = $items->fetchAll();
    $pdo->beginTransaction();
    foreach ($rows as $row) {
        $pdo->prepare('UPDATE products SET quantity = quantity + ? WHERE id=?')->execute([(int)$row['quantity'], (int)$row['product_id']]);
    }
    $stmt = $pdo->prepare('DELETE FROM sales WHERE id=?');
    $stmt->execute([$id]);
    log_activity($pdo, 'Receipt deleted');
    $pdo->commit();
    json_response(['success' => true, 'message' => 'Receipt deleted.']);
}

json_response(['success' => false, 'message' => 'Invalid action.']);
