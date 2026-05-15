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
    <title>Create Account | InventoryManagementSystem</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.css" rel="stylesheet">
    <link href="../assets/css/style.css" rel="stylesheet">
</head>
<body class="auth-body">
<div class="auth-split">
    <section class="auth-visual">
        <div class="auth-visual-content">
            <h1>Create your workspace access</h1>
            <p>Staff accounts can use POS and submit product records, while admins can approve, report, and manage the full system.</p>
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
            <span class="badge bg-primary mb-3">User / Staff</span>
            <h2 class="mb-1">Create Account</h2>
            <p class="muted mb-4">New accounts are created as User/Staff.</p>
            <div id="registerAlert"></div>
            <form id="registerForm">
                <div class="mb-2"><label class="form-label">Full Name</label><input class="form-control" name="full_name" required></div>
                <div class="mb-2"><label class="form-label">Username</label><input class="form-control" name="username" required></div>
                <div class="mb-2"><label class="form-label">Email</label><input class="form-control" type="email" name="email" required></div>
                <div class="mb-2"><label class="form-label">Password</label><input class="form-control" type="password" name="password" minlength="6" required></div>
                <div class="mb-3"><label class="form-label">Confirm Password</label><input class="form-control" type="password" name="confirm_password" minlength="6" required></div>
                <button class="btn btn-primary w-100 py-2">Create Account</button>
            </form>
            <p class="mt-3 mb-0 text-center"><a href="login.php" class="fw-semibold text-decoration-none">Back to login</a></p>
        </div>
    </section>
</div>
<script src="../js/app.js"></script>
<script src="../js/register.js"></script>
</body>
</html>
