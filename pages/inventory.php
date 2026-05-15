<?php
require_once __DIR__ . '/../includes/layout.php';
render_header('Inventory / Products', 'inventory');
?>
<div class="panel mb-3">
    <div class="row g-2 align-items-end">
        <div class="col-md-3">
            <label class="form-label">Search Products</label>
            <div class="input-group"><span class="input-group-text bg-white"><i class="bi bi-search"></i></span><input id="search" class="form-control" placeholder="Code, barcode, name"></div>
        </div>
        <div class="col-md-2"><label class="form-label">Barcode</label><input id="barcodeFilter" class="form-control" placeholder="Scan barcode"></div>
        <div class="col-md-2"><label class="form-label">Category</label><select id="categoryFilter" class="form-select category-select2" multiple></select></div>
        <div class="col-md-2"><label class="form-label">Business Type</label><select id="businessFilter" class="form-select"><option value="">All</option></select></div>
        <div class="col-md-1"><label class="form-label">Stock</label><select id="stockFilter" class="form-select"><option value="">All</option><option value="low">Low</option><option value="out">Out</option><option value="available">In Stock</option></select></div>
        <div class="col-md-2 text-md-end">
            <div class="btn-group view-toggle mb-2" role="group">
                <button class="btn btn-primary" id="gridViewBtn" type="button" title="Grid view"><i class="bi bi-grid-3x3-gap"></i></button>
                <button class="btn btn-outline-primary" id="listViewBtn" type="button" title="List view"><i class="bi bi-list-ul"></i></button>
            </div>
            <?php if (is_admin()): ?>
            <button class="btn btn-outline-primary w-100 mb-2" data-bs-toggle="modal" data-bs-target="#importModal" type="button"><i class="bi bi-upload"></i> Import</button>
            <?php endif; ?>
            <button class="btn btn-primary w-100" data-bs-toggle="modal" data-bs-target="#productModal" onclick="openProductModal()"><i class="bi bi-plus-lg"></i> Add Product</button>
        </div>
    </div>
</div>
<div class="panel">
    <div id="productGrid" class="product-grid"></div>
    <div id="productTableWrap" class="table-responsive table-shell d-none mt-3">
        <table class="table table-hover align-middle">
            <thead><tr><th>Barcode</th><th>Image</th><th>Product Name</th><th>Category</th><th>Business Type</th><th>Price</th><th>Stock</th><th>Status</th><th>Actions</th></tr></thead>
            <tbody id="productRows"></tbody>
        </table>
    </div>
    <div class="d-flex justify-content-between align-items-center"><span id="pageInfo" class="muted"></span><div><button id="prevPage" class="btn btn-outline-secondary btn-sm">Prev</button> <button id="nextPage" class="btn btn-outline-secondary btn-sm">Next</button></div></div>
</div>

<div class="modal fade" id="viewProductModal" tabindex="-1">
    <div class="modal-dialog modal-lg modal-dialog-scrollable">
        <div class="modal-content app-modal">
            <div class="modal-header app-modal-header">
                <div>
                    <span class="modal-kicker">Inventory item</span>
                    <h5 class="modal-title" id="viewProductTitle">Product Details</h5>
                </div>
                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
            </div>
            <div class="modal-body app-modal-body" id="viewProductBody"></div>
            <div class="modal-footer app-modal-footer">
                <button type="button" class="btn btn-outline-secondary" data-bs-dismiss="modal">Close</button>
                <button type="button" class="btn btn-primary d-none" id="viewEditBtn"><i class="bi bi-pencil"></i> Edit Product</button>
            </div>
        </div>
    </div>
</div>

<div class="modal fade" id="deleteProductModal" tabindex="-1">
    <div class="modal-dialog">
        <div class="modal-content app-modal">
            <div class="modal-header app-modal-header danger">
                <div>
                    <span class="modal-kicker">Permanent action</span>
                    <h5 class="modal-title">Delete Product</h5>
                </div>
                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
            </div>
            <div class="modal-body app-modal-body">
                <input type="hidden" id="deleteProductId">
                <div class="alert alert-danger border-0 rounded-4 mb-3">
                    <strong>Are you sure you want to delete this product?</strong>
                    <div class="mt-2" id="deleteProductName"></div>
                </div>
                <p class="muted mb-0">This action removes the product from inventory. Sales records already made will remain in the system.</p>
            </div>
            <div class="modal-footer app-modal-footer">
                <button type="button" class="btn btn-outline-secondary" data-bs-dismiss="modal">Cancel</button>
                <button type="button" class="btn btn-danger" id="confirmDeleteBtn"><i class="bi bi-trash"></i> Delete Product</button>
            </div>
        </div>
    </div>
</div>

<div class="modal fade" id="productModal" tabindex="-1">
    <div class="modal-dialog modal-xl modal-dialog-scrollable">
        <form class="modal-content app-modal" id="productForm" enctype="multipart/form-data">
            <div class="modal-header app-modal-header">
                <div>
                    <span class="modal-kicker">Product record</span>
                    <h5 class="modal-title" id="productModalTitle">Add Product</h5>
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
                            <div class="modal-help">Scan here first. Press Enter after scanning to check duplicates.</div>
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
                        <div class="col-md-3">
                            <label class="form-label">Reorder Level</label>
                            <input class="form-control" type="number" name="reorder_level" required>
                            <div class="modal-help">Low stock alert starts at this quantity.</div>
                        </div>
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
            <div class="modal-footer app-modal-footer"><button type="button" class="btn btn-outline-secondary" data-bs-dismiss="modal">Cancel</button><button class="btn btn-success"><i class="bi bi-check2-circle"></i> Save Product</button></div>
        </form>
    </div>
</div>

<?php if (is_admin()): ?>
<div class="modal fade" id="importModal" tabindex="-1">
    <div class="modal-dialog modal-lg">
        <div class="modal-content app-modal">
            <div class="modal-header app-modal-header">
                <div>
                    <span class="modal-kicker">Bulk upload</span>
                    <h5 class="modal-title">Import Products</h5>
                </div>
                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
            </div>
            <div class="modal-body app-modal-body">
                <div class="modal-section">
                    <div class="modal-section-title"><i class="bi bi-shield-check"></i><span>Duplicate Detection</span></div>
                    <p class="muted mb-3">Upload CSV or Excel. The system scans products first and imports only valid new rows after admin confirmation.</p>
                    <input id="importFile" class="form-control" type="file" accept=".csv,.xlsx,.xls">
                </div>
                <div id="importSummary" class="row g-3"></div>
            </div>
            <div class="modal-footer app-modal-footer">
                <a id="duplicateReportLink" class="btn btn-outline-warning d-none" href="#" target="_blank"><i class="bi bi-download"></i> Duplicate Report</a>
                <button class="btn btn-outline-secondary" data-bs-dismiss="modal" type="button">Close</button>
                <button id="scanImportBtn" class="btn btn-primary" type="button">Scan File</button>
                <button id="commitImportBtn" class="btn btn-success d-none" type="button">Import Valid New Products</button>
            </div>
        </div>
    </div>
</div>
<?php endif; ?>
<?php render_footer(['inventory.js']); ?>
