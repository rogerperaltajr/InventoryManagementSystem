<?php
require_once __DIR__ . '/../includes/auth.php';
require_action_login();

if (($_GET['action'] ?? '') !== 'summary') json_response(['success' => false, 'message' => 'Invalid action.']);

$today = date('Y-m-d');
$month = date('Y-m');

$totalProducts = (int)$pdo->query("SELECT COUNT(*) FROM products WHERE status='Approved'")->fetchColumn();
$salesToday = (float)$pdo->query("SELECT COALESCE(SUM(total),0) FROM sales WHERE DATE(created_at)=CURDATE()")->fetchColumn();
$salesMonth = (float)$pdo->query("SELECT COALESCE(SUM(total),0) FROM sales WHERE DATE_FORMAT(created_at,'%Y-%m')='$month'")->fetchColumn();
$lowStock = (int)$pdo->query("SELECT COUNT(*) FROM products WHERE status='Approved' AND quantity > 0 AND quantity <= reorder_level")->fetchColumn();
$outStock = (int)$pdo->query("SELECT COUNT(*) FROM products WHERE status='Approved' AND quantity <= 0")->fetchColumn();
$pending = (int)$pdo->query("SELECT COUNT(*) FROM products WHERE status='Pending'")->fetchColumn();

$daily = $pdo->query("SELECT DATE(created_at) day, COALESCE(SUM(total),0) total FROM sales WHERE created_at >= DATE_SUB(CURDATE(), INTERVAL 6 DAY) GROUP BY DATE(created_at) ORDER BY day")->fetchAll();
$top = $pdo->query("SELECT p.product_name, p.image_path, p.quantity, p.selling_price, SUM(si.quantity) qty, SUM(si.subtotal) revenue
    FROM sale_items si
    JOIN products p ON p.id=si.product_id
    GROUP BY p.id
    ORDER BY qty DESC
    LIMIT 6")->fetchAll();
$logs = $pdo->query("SELECT u.full_name, a.action, DATE_FORMAT(a.created_at, '%Y-%m-%d %H:%i') created_at FROM activity_logs a LEFT JOIN users u ON u.id=a.user_id ORDER BY a.id DESC LIMIT 10")->fetchAll();
$lowStockProducts = $pdo->query("SELECT product_name, quantity, reorder_level FROM products WHERE status='Approved' AND quantity <= reorder_level ORDER BY quantity ASC, product_name LIMIT 5")->fetchAll();

$mostSold = $pdo->query("SELECT p.product_name FROM sale_items si JOIN sales s ON s.id=si.sale_id JOIN products p ON p.id=si.product_id WHERE DATE(s.created_at)=CURDATE() GROUP BY p.id ORDER BY SUM(si.quantity) DESC LIMIT 1")->fetchColumn();
$leastSold = $pdo->query("SELECT p.product_name FROM products p LEFT JOIN sale_items si ON si.product_id=p.id WHERE p.status='Approved' GROUP BY p.id ORDER BY COALESCE(SUM(si.quantity),0) ASC LIMIT 1")->fetchColumn();
$soldCount = (int)$pdo->query("SELECT COUNT(DISTINCT product_id) FROM sale_items")->fetchColumn();
$notSoldCount = (int)$pdo->query("SELECT COUNT(*) FROM products p WHERE p.status='Approved' AND NOT EXISTS (SELECT 1 FROM sale_items si WHERE si.product_id=p.id)")->fetchColumn();

json_response([
    'total_products' => $totalProducts,
    'sales_today' => $salesToday,
    'sales_month' => $salesMonth,
    'low_stock' => $lowStock,
    'out_stock' => $outStock,
    'pending' => $pending,
    'daily_sales' => $daily,
    'top_products' => $top,
    'logs' => $logs,
    'low_stock_products' => $lowStockProducts,
    'most_sold_today' => $mostSold,
    'least_sold' => $leastSold,
    'sold_count' => $soldCount,
    'not_sold_count' => $notSoldCount,
]);
