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

<?php if (is_admin()): ?>
<div class="modal fade" id="productModal" tabindex="-1">
    <div class="modal-dialog modal-xl modal-dialog-scrollable">
        <form class="modal-content app-modal" id="productForm" enctype="multipart/form-data">
            <div class="modal-header app-modal-header">
                <div>
                    <span class="modal-kicker">Product record</span>
                    <h5 class="modal-title" id="productModalTitle">Edit Product</h5>
                </div>
                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
            </div>
            <div class="modal-body app-modal-body">
                <input type="hidden" name="id" id="productId">
                <input type="hidden" name="duplicate_decision" id="duplicateDecision">
                <input type="hidden" name="duplicate_reference_id" id="duplicateReferenceId">
                <div id="duplicateWarning" class="d-none mb-3"></div>
                <div class="modal-section">
                    <div class="modal-section-title"><i class="bi bi-upc-scan"></i><span>Product Identity</span></div>
                    <div class="row g-3">
                        <div class="col-md-4">
                            <label class="form-label">Barcode</label>
                            <div class="input-group barcode-input-group">
                                <span class="input-group-text bg-white"><i class="bi bi-upc-scan"></i></span>
                                <input class="form-control" name="barcode" id="productBarcode" inputmode="numeric" autocomplete="off" spellcheck="false" placeholder="Scan or type barcode">
                            </div>
                        </div>
                        <div class="col-md-8"><label class="form-label">Product Name</label><input class="form-control" name="product_name" required></div>
                    </div>
                </div>
                <div class="modal-section">
                    <div class="modal-section-title"><i class="bi bi-tags"></i><span>Classification</span></div>
                    <div class="row g-3">
                        <div class="col-md-3"><label class="form-label">Category</label><select class="form-select" name="category_id" id="category_id"></select></div>
                        <div class="col-md-3"><label class="form-label">Brand</label><select class="form-select" name="brand_id" id="brand_id"></select></div>
                        <div class="col-md-3"><label class="form-label">Unit</label><select class="form-select" name="unit_id" id="unit_id"></select></div>
                        <div class="col-md-3"><label class="form-label">Business Type</label><select class="form-select" name="business_type_id" id="business_type_id"></select></div>
                    </div>
                </div>
                <div class="modal-section">
                    <div class="modal-section-title"><i class="bi bi-rulers"></i><span>Size & Packaging</span></div>
                    <div class="row g-3">
                        <div class="col-md-4"><label class="form-label">Size / Weight</label><input class="form-control" type="number" step="0.01" name="product_size_value" placeholder="150"></div>
                        <div class="col-md-4"><label class="form-label">Size Unit</label><select class="form-select" name="product_size_unit"><option value="">N/A</option><option value="g">g</option><option value="kg">kg</option><option value="ml">ml</option><option value="L">L</option><option value="pcs">pcs</option><option value="tablet">tablet</option><option value="capsule">capsule</option></select></div>
                        <div class="col-md-4"><label class="form-label">Package Type</label><input class="form-control" name="package_type" placeholder="Can, bottle, pack"></div>
                    </div>
                </div>
                <div class="modal-section">
                    <div class="modal-section-title"><i class="bi bi-cash-coin"></i><span>Pricing & Stock</span></div>
                    <div class="row g-3">
                        <div class="col-md-3"><label class="form-label">Cost Price</label><input class="form-control" type="number" step="0.01" name="cost_price" required></div>
                        <div class="col-md-3"><label class="form-label">Selling Price</label><input class="form-control" type="number" step="0.01" name="selling_price" required></div>
                        <div class="col-md-3"><label class="form-label">Quantity</label><input class="form-control" type="number" name="quantity" required></div>
                        <div class="col-md-3"><label class="form-label">Reorder Level</label><input class="form-control" type="number" name="reorder_level" required></div>
                    </div>
                </div>
                <div class="modal-section">
                    <div class="modal-section-title"><i class="bi bi-image"></i><span>Supplier, Media & Notes</span></div>
                    <div class="row g-3">
                        <div class="col-md-4"><label class="form-label">Supplier</label><select class="form-select" name="supplier_id" id="supplier_id"></select></div>
                        <div class="col-md-4"><label class="form-label">Expiration Date</label><input class="form-control" type="date" name="expiration_date"></div>
                        <div class="col-md-4"><label class="form-label">Product Image</label><input class="form-control" type="file" name="image" accept="image/*"></div>
                        <div class="col-12"><label class="form-label">Description</label><textarea class="form-control" name="description" rows="3" placeholder="Optional product notes, size, variant, or supplier details"></textarea></div>
                    </div>
                </div>
            </div>
            <div class="modal-footer app-modal-footer">
                <button type="button" class="btn btn-outline-secondary" data-bs-dismiss="modal">Cancel</button>
                <button class="btn btn-success"><i class="bi bi-check2-circle"></i> Update Product</button>
            </div>
        </form>
    </div>
</div>
<?php endif; ?>
<?php render_footer(['pos.js']); ?>
