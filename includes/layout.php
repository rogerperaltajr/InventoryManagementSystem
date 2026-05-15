<?php
require_once __DIR__ . '/auth.php';

function render_header(string $title, string $active = ''): void
{
    require_login();
    $user = current_user();
    $base = '..';
    $items = [
        ['dashboard', 'Dashboard', 'dashboard.php', 'bi-grid-1x2-fill', true],
        ['inventory', 'Inventory', 'inventory.php', 'bi-box-seam-fill', true],
        ['approval', 'Product Approval', 'product_approval.php', 'bi-patch-check-fill', is_admin()],
        ['pos', 'POS System', 'pos.php', 'bi-receipt-cutoff', true],
        ['reports', 'Reports', 'reports.php', 'bi-bar-chart-fill', is_admin()],
        ['users', 'User Management', 'user_management.php', 'bi-people-fill', is_admin()],
        ['settings', 'Settings', 'settings.php', 'bi-gear-fill', is_admin()],
        ['logs', 'Activity Logs', 'activity_logs.php', 'bi-clock-history', is_admin()],
    ];
    ?>
<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="csrf-token" content="<?= htmlspecialchars(csrf_token()) ?>">
    <title><?= htmlspecialchars($title) ?> | InventoryManagementSystem</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.css" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/select2@4.1.0-rc.0/dist/css/select2.min.css" rel="stylesheet">
    <link href="<?= $base ?>/assets/css/style.css" rel="stylesheet">
    <script>
        if (localStorage.getItem('sidebarCollapsed') === '1') {
            document.documentElement.classList.add('sidebar-collapsed');
        }
    </script>
</head>
<body>
<div class="app-shell">
    <aside class="sidebar">
        <div class="brand">
            <div class="brand-mark">IMS</div>
            <div><span>IMS</span><small>Inventory Management System</small></div>
        </div>
        <nav>
            <?php foreach ($items as $item): if (!$item[4]) continue; ?>
                <a class="<?= $active === $item[0] ? 'active' : '' ?>" href="<?= htmlspecialchars($item[2]) ?>">
                    <i class="bi <?= htmlspecialchars($item[3]) ?>"></i>
                    <span><?= htmlspecialchars($item[1]) ?></span>
                </a>
            <?php endforeach; ?>
            <form method="post" action="../php/logout_action.php" class="sidebar-logout">
                <input type="hidden" name="csrf_token" value="<?= htmlspecialchars(csrf_token()) ?>">
                <button type="submit"><i class="bi bi-box-arrow-left"></i><span>Logout</span></button>
            </form>
        </nav>
    </aside>
    <main class="main">
        <header class="topbar">
            <button class="icon-btn d-lg-none" id="sidebarToggle" type="button" aria-label="Open menu"><i class="bi bi-list"></i></button>
            <button class="icon-btn d-none d-lg-inline-grid" id="sidebarSizeToggle" type="button" aria-label="Toggle navigation size" title="Toggle navigation size"><i class="bi bi-layout-sidebar-inset"></i></button>
            <div class="page-heading">
                <h1><?= htmlspecialchars($title) ?></h1>
                <span>Inventory operations, sales, and reports</span>
            </div>
            <div class="topbar-actions ms-auto">
                <div class="dropdown receipt-notification-wrap">
                    <button class="icon-btn" id="receiptNotificationBtn" type="button" data-bs-toggle="dropdown" aria-expanded="false" aria-label="Receipt notifications">
                        <i class="bi bi-bell"></i><span class="notification-dot d-none" id="receiptNotificationDot"></span>
                    </button>
                    <div class="dropdown-menu dropdown-menu-end receipt-notification-menu">
                        <div class="receipt-notification-head">
                            <strong>Receipts</strong>
                            <button class="btn btn-sm btn-link" type="button" id="refreshReceiptsBtn">Refresh</button>
                        </div>
                        <div id="receiptNotificationList" class="receipt-notification-list">
                            <div class="receipt-notification-empty">No receipts yet.</div>
                        </div>
                    </div>
                </div>
                <div class="dropdown">
                    <button class="profile-chip dropdown-toggle" type="button" data-bs-toggle="dropdown">
                        <span class="avatar-wrap"><span class="avatar"><?= htmlspecialchars(strtoupper(substr($user['full_name'], 0, 1))) ?></span><span class="online-dot"></span></span>
                        <span class="profile-meta"><strong><?= htmlspecialchars($user['full_name']) ?></strong><small><?= htmlspecialchars($user['role']) ?></small></span>
                    </button>
                    <ul class="dropdown-menu dropdown-menu-end">
                        <li><span class="dropdown-item-text"><?= htmlspecialchars($user['email']) ?></span></li>
                        <li><hr class="dropdown-divider"></li>
                        <li>
                            <form method="post" action="../php/logout_action.php">
                                <input type="hidden" name="csrf_token" value="<?= htmlspecialchars(csrf_token()) ?>">
                                <button class="dropdown-item text-danger" type="submit">Logout</button>
                            </form>
                        </li>
                    </ul>
                </div>
            </div>
        </header>
        <section class="content">
    <?php
}

function render_footer(array $scripts = []): void
{
    ?>
        </section>
    </main>
</div>
<div class="modal fade" id="receiptDetailModal" tabindex="-1">
    <div class="modal-dialog modal-lg modal-dialog-scrollable">
        <div class="modal-content app-modal">
            <div class="modal-header app-modal-header">
                <div>
                    <span class="modal-kicker">Receipt details</span>
                    <h5 class="modal-title" id="receiptDetailTitle">Receipt</h5>
                </div>
                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
            </div>
            <div class="modal-body app-modal-body" id="receiptDetailBody"></div>
            <div class="modal-footer app-modal-footer">
                <button type="button" class="btn btn-outline-secondary" data-bs-dismiss="modal">Close</button>
            </div>
        </div>
    </div>
</div>
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/jquery@3.7.1/dist/jquery.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/select2@4.1.0-rc.0/dist/js/select2.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.1/dist/chart.umd.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>
<script src="https://cdn.jsdelivr.net/npm/xlsx@0.18.5/dist/xlsx.full.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/html2canvas@1.4.1/dist/html2canvas.min.js"></script>
<script src="../js/app.js?v=<?= filemtime(__DIR__ . '/../js/app.js') ?>"></script>
<?php foreach ($scripts as $script): ?>
<script src="../js/<?= htmlspecialchars($script) ?>?v=<?= filemtime(__DIR__ . '/../js/' . $script) ?>"></script>
<?php endforeach; ?>
</body>
</html>
    <?php
}
