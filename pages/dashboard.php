<?php
require_once __DIR__ . '/../includes/layout.php';
render_header('Dashboard', 'dashboard');
?>
<div class="dashboard-shell">
    <div class="dashboard-toolbar">
        <div>
            <h4>Store Overview</h4>
            <span>Compact POS and inventory snapshot</span>
        </div>
        <div class="dashboard-toolbar-actions">
            <a class="btn btn-primary" href="pos.php"><i class="bi bi-receipt"></i> POS</a>
            <a class="btn btn-outline-primary" href="inventory.php"><i class="bi bi-box-seam"></i> Inventory</a>
        </div>
    </div>

    <div class="dashboard-metrics" id="metrics"></div>

    <div class="dashboard-grid mt-3">
        <div class="panel dashboard-panel sales-panel">
            <div class="panel-title-row">
                <div><h5>Sales Trend</h5><span>Last 7 days</span></div>
                <span class="mini-badge">PHP</span>
            </div>
            <div class="dashboard-chart-box">
                <canvas id="salesChart"></canvas>
            </div>
        </div>
        <div class="panel dashboard-panel stock-panel">
            <div class="panel-title-row">
                <div><h5>Stock Health</h5><span>Sold vs unsold items</span></div>
            </div>
            <div class="stock-health-wrap">
                <div class="stock-chart-box"><canvas id="soldChart"></canvas></div>
                <div id="stockHealth" class="stock-health-list"></div>
            </div>
        </div>
    </div>

    <div class="dashboard-grid mt-3">
        <div class="panel dashboard-panel">
            <div class="panel-title-row">
                <div><h5>Top Sellers</h5><span>Best moving products</span></div>
                <a href="reports.php" class="panel-link">Reports</a>
            </div>
            <div id="topProducts" class="dashboard-list"></div>
        </div>
        <div class="panel dashboard-panel">
            <div class="panel-title-row">
                <div><h5>Recent Activity</h5><span>Latest system actions</span></div>
                <a href="activity_logs.php" class="panel-link">View all</a>
            </div>
            <div id="recentLogs" class="activity-feed"></div>
        </div>
    </div>
</div>
<?php render_footer(['dashboard.js']); ?>
