<?php
require_once __DIR__ . '/../includes/auth.php';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    verify_csrf();
    if (current_user()) {
        log_activity($pdo, 'Logout');
    }
}

$_SESSION = [];
session_destroy();
header('Location: ../pages/login.php');
exit;

