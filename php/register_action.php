<?php
require_once __DIR__ . '/../includes/auth.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') json_response(['success' => false, 'message' => 'Invalid request.'], 405);
verify_csrf();

$fullName = clean($_POST['full_name'] ?? '');
$username = clean($_POST['username'] ?? '');
$email = filter_var($_POST['email'] ?? '', FILTER_VALIDATE_EMAIL);
$password = $_POST['password'] ?? '';
$confirm = $_POST['confirm_password'] ?? '';

if (!$fullName || !$username || !$email || strlen($password) < 6) {
    json_response(['success' => false, 'message' => 'Complete all fields. Password must be at least 6 characters.']);
}
if ($password !== $confirm) {
    json_response(['success' => false, 'message' => 'Passwords do not match.']);
}

try {
    $stmt = $pdo->prepare('INSERT INTO users (full_name, username, email, password_hash, role, status) VALUES (?, ?, ?, ?, "User", "Active")');
    $stmt->execute([$fullName, $username, $email, password_hash($password, PASSWORD_DEFAULT)]);
    json_response(['success' => true, 'message' => 'Account created. You may now log in.']);
} catch (PDOException $e) {
    json_response(['success' => false, 'message' => 'Username or email is already used.']);
}

