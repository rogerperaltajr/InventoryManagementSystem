<?php
require_once __DIR__ . '/../includes/layout.php';
require_admin();
render_header('Product Approval', 'approval');
?>
<div class="row g-3 mb-3" id="approvalStats"></div>
<div class="panel">
    <div class="d-flex justify-content-between align-items-center mb-3">
        <div><h5 class="mb-0">Pending Product Submissions</h5><span class="muted">Review product details, approve or reject with remarks.</span></div>
    </div>
    <div class="table-responsive table-shell">
        <table class="table table-hover align-middle">
            <thead><tr><th>Code</th><th>Name</th><th>Barcode</th><th>Qty</th><th>Submitted By</th><th>Remarks</th><th>Actions</th></tr></thead>
            <tbody id="approvalRows"></tbody>
        </table>
    </div>
</div>
<?php render_footer(['product_approval.js']); ?>
