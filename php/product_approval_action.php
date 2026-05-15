<?php
require_once __DIR__ . '/../includes/auth.php';
require_once __DIR__ . '/../includes/product_helpers.php';
require_action_admin();

$action = $_POST['action'] ?? $_GET['action'] ?? '';

if ($action === 'list') {
    $rows = $pdo->query("SELECT p.*, u.full_name, c.name category, COALESCE(NULLIF(p.brand,''), br.name) brand_name, un.name unit, bt.name business_type,
            ref.product_name duplicate_product_name, ref.barcode duplicate_barcode, ref.selling_price duplicate_price, ref.quantity duplicate_stock
        FROM products p
        LEFT JOIN users u ON u.id=p.created_by
        LEFT JOIN product_categories c ON c.id=p.category_id
        LEFT JOIN brands br ON br.id=p.brand_id
        LEFT JOIN units un ON un.id=p.unit_id
        LEFT JOIN business_types bt ON bt.id=p.business_type_id
        LEFT JOIN products ref ON ref.id=p.duplicate_reference_id
        WHERE p.status='Pending' ORDER BY p.id DESC")->fetchAll();
    $stats = [
        'pending' => (int)$pdo->query("SELECT COUNT(*) FROM products WHERE status='Pending'")->fetchColumn(),
        'approved' => (int)$pdo->query("SELECT COUNT(*) FROM products WHERE status='Approved'")->fetchColumn(),
        'rejected' => (int)$pdo->query("SELECT COUNT(*) FROM products WHERE status='Rejected'")->fetchColumn(),
    ];
    json_response(['rows' => $rows, 'stats' => $stats]);
}

verify_csrf();

if ($action === 'decide') {
    $id = (int)$_POST['id'];
    $status = $_POST['status'] === 'Approved' ? 'Approved' : 'Rejected';
    $remarks = clean($_POST['remarks'] ?? '');
    $pdo->beginTransaction();
    $stmt = $pdo->prepare('UPDATE products SET status=?, remarks=?, approved_by=?, approved_at=NOW() WHERE id=? AND status="Pending"');
    $stmt->execute([$status, $remarks, current_user()['id'], $id]);
    if ($stmt->rowCount() === 0) {
        $pdo->rollBack();
        json_response(['success' => false, 'message' => 'Product is no longer pending.']);
    }
    $stmt = $pdo->prepare('INSERT INTO product_approvals (product_id, admin_id, status, remarks) VALUES (?, ?, ?, ?)');
    $stmt->execute([$id, current_user()['id'], $status, $remarks]);
    log_duplicate_action($pdo, $id, null, $status === 'Approved' ? 'Approved' : 'Rejected', 'Product approval decision: ' . $status);
    log_activity($pdo, 'Product ' . strtolower($status));
    $pdo->commit();
    json_response(['success' => true, 'message' => "Product $status."]);
}

json_response(['success' => false, 'message' => 'Invalid action.']);
