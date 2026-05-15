<?php
require_once __DIR__ . '/../includes/layout.php';
render_header('Point of Sale', 'pos');
?>
<div class="row g-3">
    <div class="col-xl-9 col-lg-8">
        <div class="panel">
            <div class="d-flex justify-content-between align-items-center mb-3">
                <div><h5 class="mb-0">Product Selection</h5><span class="muted">Touch a product card to add it to cart quickly.</span></div>
                <button class="btn btn-outline-primary pos-filter-toggle" type="button" data-bs-toggle="collapse" data-bs-target="#posFilterPanel" aria-expanded="false" aria-controls="posFilterPanel">
                    <i class="bi bi-funnel"></i><span>Filters</span>
                </button>
            </div>
            <div class="collapse pos-filter-panel mb-3" id="posFilterPanel">
                <div class="pos-filter-card">
                    <div class="pos-filter-title"><i class="bi bi-tags"></i><span>Find products</span></div>
                    <div class="row g-2 align-items-end">
                        <div class="col-md-5">
                            <label class="form-label">Search product manually</label>
                            <div class="input-group">
                                <input id="productSearch" class="form-control" placeholder="Search product manually">
                                <button id="searchBtn" class="btn btn-success" type="button"><i class="bi bi-search"></i> Search</button>
                            </div>
                        </div>
                        <div class="col-md-5">
                            <label class="form-label">Filter by category</label>
                            <select id="categoryFilter" class="form-select pos-category-select" multiple></select>
                        </div>
                        <div class="col-md-2"><button id="clearCategoryFilter" class="btn btn-outline-secondary w-100" type="button"><i class="bi bi-x-circle"></i> Clear</button></div>
                    </div>
                </div>
            </div>
            <div id="posProductGrid" class="pos-product-grid"></div>
        </div>
    </div>
    <div class="col-xl-3 col-lg-4">
        <div class="panel">
            <h5>Cart</h5>
            <div class="pos-cart-scroll"><table class="table table-sm pos-cart-table"><thead><tr><th>Item</th><th>Qty</th><th>Total</th></tr></thead><tbody id="cartRows"></tbody></table></div>
            <div class="mb-2"><label class="form-label">Discount</label><input id="discount" type="number" step="0.01" class="form-control" value="0"></div>
            <div class="mb-2">
                <label class="form-label">Payment Method</label>
                <div class="d-flex gap-2 mb-2">
                    <button type="button" class="btn btn-outline-primary flex-fill payment-shortcut" data-method="Cash"><i class="bi bi-cash"></i> Cash</button>
                    <button type="button" class="btn btn-outline-primary flex-fill payment-shortcut" data-method="Card"><i class="bi bi-credit-card"></i> Card</button>
                </div>
                <select id="paymentMethod" class="form-select"></select>
            </div>
            <div class="mb-2"><label class="form-label">Payment Amount</label><input id="paymentAmount" type="number" step="0.01" class="form-control" value="0"></div>
            <h5 class="d-flex justify-content-between"><span>Total</span><strong id="cartTotal">PHP 0.00</strong></h5>
            <h6 class="d-flex justify-content-between"><span>Change</span><strong id="changeAmount">PHP 0.00</strong></h6>
            <button id="saveSale" class="btn btn-primary w-100 mt-2 py-2"><i class="bi bi-check2-circle"></i> Complete Sale</button>
            <div id="receipt" class="d-none mt-3"></div>
        </div>
        <div class="panel mt-3">
            <label class="form-label">Barcode Scanner</label>
            <div class="input-group">
                <span class="input-group-text bg-white"><i class="bi bi-upc-scan"></i></span>
                <input id="barcodeInput" class="form-control" placeholder="Scan barcode and press Enter" autofocus>
            </div>
        </div>
    </div>
</div>
<?php render_footer(['pos.js']); ?>
