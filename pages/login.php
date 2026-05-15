<?php
require_once __DIR__ . '/../includes/auth.php';
if (current_user()) redirect_by_role();
?>
<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="csrf-token" content="<?= htmlspecialchars(csrf_token()) ?>">
    <title>Login | InventoryManagementSystem</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.css" rel="stylesheet">
    <link href="../assets/css/style.css" rel="stylesheet">
</head>
<body class="auth-body">
<div class="auth-split">
    <section class="auth-visual">
        <div class="auth-visual-content">
            <h1>InventoryManagementSystem</h1>
            <p>Modern stock control, POS, approvals, reports, and user management for retail and service businesses.</p>
            <div class="inventory-illustration" aria-hidden="true">
                <div class="shelf one"></div><div class="shelf two"></div>
                <div class="box-art a"></div><div class="box-art b"></div><div class="box-art c"></div><div class="box-art d"></div><div class="box-art e"></div>
                <div class="scanner-art"></div>
                <div class="pos-art"></div>
                <div class="cart-art"></div>
            </div>
        </div>
    </section>
    <section class="auth-panel">
        <div class="auth-card">
            <div class="mb-4">
                <span class="badge bg-primary mb-3">Secure access</span>
                <h2 class="mb-1">Welcome back</h2>
                <p class="muted mb-0">Sign in to continue to your inventory workspace.</p>
            </div>
            <div id="loginAlert"></div>
            <form id="loginForm">
                <div class="mb-3">
                    <label class="form-label">Username or Email</label>
                    <div class="input-group">
                        <span class="input-group-text bg-white"><i class="bi bi-person"></i></span>
                        <input class="form-control" name="login" required autocomplete="username">
                    </div>
                </div>
                <div class="mb-3">
                    <label class="form-label">Password</label>
                    <div class="input-group">
                        <span class="input-group-text bg-white"><i class="bi bi-lock"></i></span>
                        <input class="form-control" type="password" name="password" required autocomplete="current-password">
                    </div>
                </div>
                <div class="d-flex justify-content-between align-items-center mb-3">
                    <label class="form-check-label"><input class="form-check-input me-1" type="checkbox"> Remember me</label>
                    <a href="#" class="small text-decoration-none">Forgot password?</a>
                </div>
                <button class="btn btn-primary w-100 py-2">Login</button>
            </form>
            <p class="mt-4 mb-0 text-center">No account? <a href="register.php" class="fw-semibold text-decoration-none">Create account</a></p>
            <p class="muted mt-3 mb-0 text-center">Demo: admin/admin123 or staff/admin123</p>
        </div>
    </section>
</div>
<script src="../js/app.js"></script>
<script src="../js/login.js"></script>
</body>
</html>
