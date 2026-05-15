<?php
require_once __DIR__ . '/../includes/auth.php';
require_action_admin();

if (($_GET['action'] ?? '') !== 'list') json_response(['success' => false, 'message' => 'Invalid action.']);

$page = max(1, (int)($_GET['page'] ?? 1));
$limit = 12;
$offset = ($page - 1) * $limit;
$where = ['1=1'];
$args = [];
if ($s = clean($_GET['search'] ?? '')) {
    $where[] = '(u.full_name LIKE ? OR a.action LIKE ?)';
    array_push($args, "%$s%", "%$s%");
}
if ($from = clean($_GET['from'] ?? '')) { $where[] = 'DATE(a.created_at) >= ?'; $args[] = $from; }
if ($to = clean($_GET['to'] ?? '')) { $where[] = 'DATE(a.created_at) <= ?'; $args[] = $to; }
if ($userId = (int)($_GET['user_id'] ?? 0)) { $where[] = 'a.user_id = ?'; $args[] = $userId; }
if ($actionType = clean($_GET['action_type'] ?? '')) { $where[] = 'a.action LIKE ?'; $args[] = "%$actionType%"; }
$sqlWhere = implode(' AND ', $where);

$users = $pdo->query('SELECT id, full_name FROM users ORDER BY full_name')->fetchAll();

$count = $pdo->prepare("SELECT COUNT(*) FROM activity_logs a LEFT JOIN users u ON u.id=a.user_id WHERE $sqlWhere");
$count->execute($args);
$total = (int)$count->fetchColumn();
$stmt = $pdo->prepare("SELECT u.full_name, a.action, a.ip_address, DATE_FORMAT(a.created_at, '%Y-%m-%d %H:%i') date_time FROM activity_logs a LEFT JOIN users u ON u.id=a.user_id WHERE $sqlWhere ORDER BY a.id DESC LIMIT $limit OFFSET $offset");
$stmt->execute($args);
json_response(['rows' => $stmt->fetchAll(), 'page' => $page, 'pages' => max(1, (int)ceil($total / $limit)), 'users' => $users]);
