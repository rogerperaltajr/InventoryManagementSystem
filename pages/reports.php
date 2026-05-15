<?php
require_once __DIR__ . '/../includes/layout.php';
require_admin();
render_header('Reports', 'reports');
?>
<div class="panel mb-3">
    <div class="row g-2 align-items-end">
        <div class="col-md-2"><label class="form-label">Report</label><select id="reportType" class="form-select"><option value="sales">Sales</option><option value="inventory">Inventory</option><option value="low_stock">Low Stock</option><option value="out_stock">Out of Stock</option><option value="most_sold">Most Sold</option><option value="unsold">Unsold</option><option value="duplicates">Duplicate Products</option></select></div>
        <div class="col-md-2"><label class="form-label">Date From</label><input id="dateFrom" type="date" class="form-control"></div>
        <div class="col-md-2"><label class="form-label">Date To</label><input id="dateTo" type="date" class="form-control"></div>
        <div class="col-md-2"><label class="form-label">Category</label><select id="category" class="form-select category-select2" multiple></select></div>
        <div class="col-md-2"><label class="form-label">Business</label><select id="businessType" class="form-select"><option value="">All</option></select></div>
        <div class="col-md-2"><label class="form-label">Status</label><select id="status" class="form-select"><option value="">All</option><option>Pending</option><option>Approved</option><option>Rejected</option></select></div>
        <div class="col-12 text-end">
            <button class="btn btn-primary" id="runReport"><i class="bi bi-funnel"></i> Run</button>
            <button class="btn btn-outline-primary" onclick="tableToExcel('reportTable','inventory-report')"><i class="bi bi-file-earmark-excel"></i> Export Excel</button>
            <button class="btn btn-outline-secondary" onclick="tableToImage('reportBox','inventory-report')"><i class="bi bi-image"></i> Save Image</button>
            <button class="btn btn-outline-dark" onclick="print()"><i class="bi bi-printer"></i> Print</button>
        </div>
    </div>
</div>
<div class="row g-3 mb-3">
    <div class="col-md-4"><div class="summary-card"><div class="summary-icon"><i class="bi bi-file-earmark-bar-graph"></i></div><div><strong>Reports</strong><span>Sales, inventory, low stock, and product movement</span></div></div></div>
    <div class="col-md-4"><div class="summary-card"><div class="summary-icon text-success"><i class="bi bi-download"></i></div><div><strong>Exports</strong><span>Excel, image, and print-ready output</span></div></div></div>
    <div class="col-md-4"><div class="summary-card"><div class="summary-icon text-warning"><i class="bi bi-calendar-range"></i></div><div><strong>Date Range</strong><span>Filter by business period and category</span></div></div></div>
</div>
<div class="panel" id="reportBox">
    <h5 id="reportTitle">Report</h5>
    <p class="muted" id="reportMeta"></p>
    <div class="table-responsive table-shell"><table class="table table-bordered" id="reportTable"><thead id="reportHead"></thead><tbody id="reportBody"></tbody></table></div>
</div>
<?php render_footer(['reports.js']); ?>
