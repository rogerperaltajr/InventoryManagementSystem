<?php
require_once __DIR__ . '/../includes/auth.php';
require_action_admin();

if (($_GET['action'] ?? '') !== 'run') json_response(['success' => false, 'message' => 'Invalid action.']);

$type = $_GET['type'] ?? 'sales';
$from = clean($_GET['from'] ?? '') ?: date('Y-m-01');
$to = clean($_GET['to'] ?? '') ?: date('Y-m-d');
$categories = array_values(array_filter(array_map('intval', explode(',', (string)($_GET['categories'] ?? $_GET['category'] ?? '')))));
$business = (int)($_GET['business_type'] ?? 0);
$status = clean($_GET['status'] ?? '');
$args = [];

function product_filters(array $categories, int $business, string $status, array &$args): string {
    $where = [];
    if ($categories) {
        $where[] = 'p.category_id IN (' . implode(',', array_fill(0, count($categories), '?')) . ')';
        array_push($args, ...$categories);
    }
    if ($business) { $where[] = 'p.business_type_id=?'; $args[] = $business; }
    if ($status) { $where[] = 'p.status=?'; $args[] = $status; }
    return $where ? ' AND ' . implode(' AND ', $where) : '';
}

if ($type === 'sales') {
    $stmt = $pdo->prepare("SELECT s.invoice_no, DATE_FORMAT(s.created_at,'%Y-%m-%d %H:%i') date, u.full_name cashier, s.subtotal, s.discount, s.total, s.payment_method FROM sales s LEFT JOIN users u ON u.id=s.user_id WHERE DATE(s.created_at) BETWEEN ? AND ? ORDER BY s.id DESC");
    $stmt->execute([$from, $to]);
    $rows = $stmt->fetchAll();
    $columns = ['Invoice', 'Date', 'Cashier', 'Subtotal', 'Discount', 'Total', 'Payment'];
    $keys = ['invoice_no', 'date', 'cashier', 'subtotal', 'discount', 'total', 'payment_method'];
    $title = 'Sales Report';
} else {
    $filter = product_filters($categories, $business, $status, $args);
    if ($type === 'duplicates') {
        $stmt = $pdo->prepare("SELECT p.product_name, ref.product_name possible_duplicate, p.barcode, c.name category, bt.name business_type, p.duplicate_status, COALESCE(a.action_taken, 'Detected') action_taken
            FROM products p
            LEFT JOIN products ref ON ref.id=p.duplicate_reference_id
            LEFT JOIN product_categories c ON c.id=p.category_id
            LEFT JOIN business_types bt ON bt.id=p.business_type_id
            LEFT JOIN product_duplicate_actions a ON a.product_id=p.id
            WHERE p.duplicate_status <> 'None' $filter
            GROUP BY p.id
            ORDER BY p.updated_at DESC");
        $stmt->execute($args);
        $rows = $stmt->fetchAll();
        $columns = ['Product Name', 'Possible Duplicate', 'Barcode', 'Category', 'Business Type', 'Status', 'Action Taken'];
        $keys = ['product_name', 'possible_duplicate', 'barcode', 'category', 'business_type', 'duplicate_status', 'action_taken'];
        $title = 'Duplicate Product Report';
    } else {
    if ($type === 'low_stock') $filter .= ' AND p.quantity > 0 AND p.quantity <= p.reorder_level';
    if ($type === 'out_stock') $filter .= ' AND p.quantity <= 0';
    if ($type === 'unsold') $filter .= ' AND NOT EXISTS (SELECT 1 FROM sale_items si WHERE si.product_id=p.id)';
    if ($type === 'most_sold') {
        $stmt = $pdo->prepare("SELECT p.product_code, p.product_name, c.name category, bt.name business_type, SUM(si.quantity) sold_qty, SUM(si.subtotal) total_sales
            FROM sale_items si JOIN sales s ON s.id=si.sale_id JOIN products p ON p.id=si.product_id
            LEFT JOIN product_categories c ON c.id=p.category_id LEFT JOIN business_types bt ON bt.id=p.business_type_id
            WHERE DATE(s.created_at) BETWEEN ? AND ? $filter GROUP BY p.id ORDER BY sold_qty DESC");
        $stmt->execute(array_merge([$from, $to], $args));
        $rows = $stmt->fetchAll();
        $columns = ['Code', 'Product', 'Category', 'Business Type', 'Sold Qty', 'Total Sales'];
        $keys = ['product_code', 'product_name', 'category', 'business_type', 'sold_qty', 'total_sales'];
        $title = 'Most Sold Products Report';
    } else {
        $stmt = $pdo->prepare("SELECT p.product_code, p.product_name, c.name category, bt.name business_type, p.quantity, p.reorder_level, p.status, p.selling_price
            FROM products p LEFT JOIN product_categories c ON c.id=p.category_id LEFT JOIN business_types bt ON bt.id=p.business_type_id WHERE 1=1 $filter ORDER BY p.product_name");
        $stmt->execute($args);
        $rows = $stmt->fetchAll();
        $columns = ['Code', 'Product', 'Category', 'Business Type', 'Qty', 'Reorder', 'Status', 'Price'];
        $keys = ['product_code', 'product_name', 'category', 'business_type', 'quantity', 'reorder_level', 'status', 'selling_price'];
        $title = ucwords(str_replace('_', ' ', $type)) . ' Report';
    }
    }
}

json_response(['title' => $title, 'range' => "$from to $to", 'generated_by' => current_user()['full_name'], 'generated_at' => date('Y-m-d H:i'), 'columns' => $columns, 'keys' => $keys, 'rows' => $rows]);
