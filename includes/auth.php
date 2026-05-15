<?php
declare(strict_types=1);

if (session_status() === PHP_SESSION_NONE) {
    $sessionPath = __DIR__ . '/../tmp/sessions';
    if (is_dir($sessionPath) && is_writable($sessionPath)) {
        session_save_path($sessionPath);
    }
    session_start();
}

require_once __DIR__ . '/../config/db.php';

function csrf_token(): string
{
    if (empty($_SESSION['csrf_token'])) {
        $_SESSION['csrf_token'] = bin2hex(random_bytes(32));
    }
    return $_SESSION['csrf_token'];
}

function verify_csrf(): void
{
    $token = $_POST['csrf_token'] ?? $_SERVER['HTTP_X_CSRF_TOKEN'] ?? '';
    if (!hash_equals($_SESSION['csrf_token'] ?? '', $token)) {
        json_response(['success' => false, 'message' => 'Invalid security token.'], 403);
    }
}

function current_user(): ?array
{
    return $_SESSION['user'] ?? null;
}

function is_admin(): bool
{
    return (current_user()['role'] ?? '') === 'Admin';
}

function require_login(): void
{
    if (!current_user()) {
        header('Location: login.php');
        exit;
    }
}

function require_admin(): void
{
    require_login();
    if (!is_admin()) {
        http_response_code(403);
        exit('Admin access only.');
    }
}

function require_action_login(): void
{
    if (!current_user()) {
        json_response(['success' => false, 'message' => 'Please log in again.'], 401);
    }
}

function require_action_admin(): void
{
    require_action_login();
    if (!is_admin()) {
        json_response(['success' => false, 'message' => 'Admin access only.'], 403);
    }
}

function json_response(array $payload, int $status = 200): void
{
    http_response_code($status);
    header('Content-Type: application/json');
    echo json_encode($payload);
    exit;
}

function clean(string $value): string
{
    return trim(strip_tags($value));
}

function log_activity(PDO $pdo, string $action): void
{
    $user = current_user();
    $stmt = $pdo->prepare('INSERT INTO activity_logs (user_id, action, ip_address) VALUES (?, ?, ?)');
    $stmt->execute([$user['id'] ?? null, $action, $_SERVER['REMOTE_ADDR'] ?? '']);
}

function redirect_by_role(): void
{
    header('Location: dashboard.php');
    exit;
}
