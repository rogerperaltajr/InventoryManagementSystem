<?php
require_once __DIR__ . '/../includes/layout.php';
require_admin();
render_header('Buyer Receipts', 'receipts');
?>
<div class="panel mb-3">
    <div class="row g-2 align-items-end">
        <div class="col-md-3"><label class="form-label">From</label><input id="receiptFrom" class="form-control" type="date"></div>
        <div class="col-md-3"><label class="form-label">To</label><input id="receiptTo" class="form-control" type="date"></div>
        <div class="col-md-2">
            <label class="form-label">Rows</label>
            <select id="receiptLimit" class="form-select">
                <option value="20">20</option>
                <option value="40">40</option>
                <option value="60">60</option>
                <option value="100">100</option>
                <option value="all">View All</option>
            </select>
        </div>
        <div class="col-md-2"><button id="filterReceipts" class="btn btn-primary w-100" type="button"><i class="bi bi-funnel"></i> Filter</button></div>
        <div class="col-md-2"><button id="printReceipts" class="btn btn-outline-primary w-100" type="button"><i class="bi bi-file-earmark-pdf"></i> PDF</button></div>
    </div>
</div>

<div class="panel" id="receiptReportArea">
    <div class="d-flex justify-content-between align-items-center mb-3">
        <div>
            <h5 class="mb-0">All Buyers</h5>
            <span class="muted" id="receiptSummary">Showing receipts</span>
        </div>
    </div>
    <div class="table-responsive">
        <table class="table table-hover align-middle">
            <thead><tr><th>Buyer</th><th>Invoice</th><th>Date</th><th>Cashier</th><th>Items</th><th>Total</th><th>Payment</th><th class="receipt-actions-print">Actions</th></tr></thead>
            <tbody id="receiptRows"></tbody>
        </table>
    </div>
    <div class="d-flex justify-content-between align-items-center receipt-actions-print">
        <span id="receiptPageInfo" class="muted"></span>
        <div><button id="prevReceiptPage" class="btn btn-outline-secondary btn-sm">Prev</button> <button id="nextReceiptPage" class="btn btn-outline-secondary btn-sm">Next</button></div>
    </div>
</div>

<div class="modal fade" id="receiptEditModal" tabindex="-1">
    <div class="modal-dialog">
        <form class="modal-content app-modal" id="receiptEditForm">
            <div class="modal-header app-modal-header">
                <div>
                    <span class="modal-kicker">Buyer receipt</span>
                    <h5 class="modal-title">Edit Buyer</h5>
                </div>
                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
            </div>
            <div class="modal-body app-modal-body">
                <input type="hidden" name="id" id="editReceiptId">
                <div class="mb-3"><label class="form-label">Buyer Name</label><input class="form-control" name="buyer_name" id="editBuyerName" placeholder="Buyer name"></div>
                <div><label class="form-label">Payment Method</label><input class="form-control" name="payment_method" id="editPaymentMethod" placeholder="Cash"></div>
            </div>
            <div class="modal-footer app-modal-footer">
                <button type="button" class="btn btn-outline-secondary" data-bs-dismiss="modal">Cancel</button>
                <button class="btn btn-success"><i class="bi bi-check2-circle"></i> Update</button>
            </div>
        </form>
    </div>
</div>

<?php render_footer(['receipts.js']); ?>
