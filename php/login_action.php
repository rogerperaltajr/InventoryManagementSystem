<?php
require_once __DIR__ . '/../includes/auth.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') json_response(['success' => false, 'message' => 'Invalid request.'], 405);
verify_csrf();

$login = clean($_POST['login'] ?? '');
$password = $_POST['password'] ?? '';

if ($login === '' || $password === '') {
    json_response(['success' => false, 'message' => 'Enter your username/email and password.']);
}

$stmt = $pdo->prepare('SELECT * FROM users WHERE (username = ? OR email = ?) LIMIT 1');
$stmt->execute([$login, $login]);
$user = $stmt->fetch();

if (!$user || !password_verify($password, $user['password_hash'])) {
    json_response(['success' => false, 'message' => 'Invalid login credentials.']);
}

if ($user['status'] !== 'Active') {
    json_response(['success' => false, 'message' => 'Your account is inactive.']);
}

session_regenerate_id();
$_SESSION['user'] = [
    'id' => (int)$user['id'],
    'full_name' => $user['full_name'],
    'username' => $user['username'],
    'email' => $user['email'],
    'role' => $user['role'],
];
csrf_token();
log_activity($pdo, 'Login');
json_response(['success' => true, 'redirect' => '../pages/dashboard.php']);
