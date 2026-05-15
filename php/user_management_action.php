<?php
require_once __DIR__ . '/../includes/auth.php';
require_action_admin();

$action = $_POST['action'] ?? $_GET['action'] ?? '';

if ($action === 'list') {
    $page = max(1, (int)($_GET['page'] ?? 1));
    $limit = 10;
    $offset = ($page - 1) * $limit;
    $search = '%' . clean($_GET['search'] ?? '') . '%';
    $count = $pdo->prepare('SELECT COUNT(*) FROM users WHERE full_name LIKE ? OR username LIKE ? OR email LIKE ?');
    $count->execute([$search, $search, $search]);
    $total = (int)$count->fetchColumn();
    $stmt = $pdo->prepare("SELECT id, full_name, username, email, role, status FROM users WHERE full_name LIKE ? OR username LIKE ? OR email LIKE ? ORDER BY id DESC LIMIT $limit OFFSET $offset");
    $stmt->execute([$search, $search, $search]);
    $stats = [
        'total' => (int)$pdo->query('SELECT COUNT(*) FROM users')->fetchColumn(),
        'admins' => (int)$pdo->query("SELECT COUNT(*) FROM users WHERE role='Admin'")->fetchColumn(),
        'users' => (int)$pdo->query("SELECT COUNT(*) FROM users WHERE role='User'")->fetchColumn(),
        'active' => (int)$pdo->query("SELECT COUNT(*) FROM users WHERE status='Active'")->fetchColumn(),
    ];
    json_response(['rows' => $stmt->fetchAll(), 'page' => $page, 'pages' => max(1, (int)ceil($total / $limit)), 'stats' => $stats]);
}

verify_csrf();

if ($action === 'create' || $action === 'update') {
    $full = clean($_POST['full_name'] ?? '');
    $username = clean($_POST['username'] ?? '');
    $email = filter_var($_POST['email'] ?? '', FILTER_VALIDATE_EMAIL);
    $role = $_POST['role'] === 'Admin' ? 'Admin' : 'User';
    $status = $_POST['status'] === 'Inactive' ? 'Inactive' : 'Active';
    $password = $_POST['password'] ?? '';
    if (!$full || !$username || !$email) json_response(['success' => false, 'message' => 'Complete all required fields.']);
    try {
        if ($action === 'create') {
            if (strlen($password) < 6) json_response(['success' => false, 'message' => 'Password must be at least 6 characters.']);
            $stmt = $pdo->prepare('INSERT INTO users (full_name, username, email, password_hash, role, status) VALUES (?, ?, ?, ?, ?, ?)');
            $stmt->execute([$full, $username, $email, password_hash($password, PASSWORD_DEFAULT), $role, $status]);
            log_activity($pdo, 'User added');
            json_response(['success' => true, 'message' => 'User added.']);
        }
        $id = (int)$_POST['id'];
        $stmt = $pdo->prepare('UPDATE users SET full_name=?, username=?, email=?, role=?, status=? WHERE id=?');
        $stmt->execute([$full, $username, $email, $role, $status, $id]);
        if ($password !== '') {
            if (strlen($password) < 6) json_response(['success' => false, 'message' => 'Password must be at least 6 characters.']);
            $pdo->prepare('UPDATE users SET password_hash=? WHERE id=?')->execute([password_hash($password, PASSWORD_DEFAULT), $id]);
        }
        log_activity($pdo, 'User updated');
        json_response(['success' => true, 'message' => 'User updated.']);
    } catch (PDOException $e) {
        json_response(['success' => false, 'message' => 'Username or email already exists.']);
    }
}

if ($action === 'reset_password') {
    $password = $_POST['password'] ?? '';
    if (strlen($password) < 6) json_response(['success' => false, 'message' => 'Password must be at least 6 characters.']);
    $pdo->prepare('UPDATE users SET password_hash=? WHERE id=?')->execute([password_hash($password, PASSWORD_DEFAULT), (int)$_POST['id']]);
    log_activity($pdo, 'User password reset');
    json_response(['success' => true, 'message' => 'Password reset.']);
}

json_response(['success' => false, 'message' => 'Invalid action.']);
