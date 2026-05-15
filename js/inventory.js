let page = 1;
let options = {};
let currentView = localStorage.getItem('inventoryView') || 'grid';
let lastDuplicateMatches = [];
let currentImportBatch = null;
const modal = new bootstrap.Modal(document.getElementById('productModal'));
const viewModal = new bootstrap.Modal(document.getElementById('viewProductModal'));
const deleteModal = new bootstrap.Modal(document.getElementById('deleteProductModal'));

['productModal', 'viewProductModal', 'deleteProductModal', 'importModal'].forEach(id => {
    const el = document.getElementById(id);
    el?.addEventListener('hide.bs.modal', () => {
        if (el.contains(document.activeElement)) {
            document.activeElement.blur();
        }
    });
});

document.getElementById('productModal')?.addEventListener('shown.bs.modal', () => {
    document.getElementById('productBarcode')?.focus();
});

function productImage(p) {
    return p.image_path
        ? `<img src="../${p.image_path}" alt="${p.product_name}">`
        : `<div class="product-placeholder"><i class="bi bi-box-seam"></i></div>`;
}

function stockInfo(p) {
    const qty = Number(p.quantity || 0);
    const reorder = Number(p.reorder_level || 0);
    if (qty <= 0) return { label: 'Out of Stock', cls: 'out', percent: 0 };
    if (qty <= reorder) return { label: 'Low Stock', cls: 'low', percent: Math.max(12, Math.min(45, qty * 8)) };
    return { label: 'In Stock', cls: 'in', percent: Math.min(100, Math.max(55, qty * 2)) };
}

function productSizeText(p) {
    const value = Number(p.product_size_value || 0);
    const unit = p.product_size_unit || '';
    if (!value || !unit) return '';
    return `${Number.isInteger(value) ? value : value.toFixed(2)} ${unit}`;
}

function productPackageText(p) {
    return p.package_type || p.unit || '';
}

function productCard(p, isAdmin) {
    const stock = stockInfo(p);
    const barcode = p.barcode || '';
    return `
        <article class="product-card">
            <div class="product-image-wrap">${productImage(p)}</div>
            <div class="product-card-body">
                <div class="product-title">${p.product_name}</div>
                <div class="product-badges">
                    ${p.brand ? `<span class="soft-badge">${p.brand}</span>` : ''}
                    <span class="soft-badge">${p.category || 'Uncategorized'}</span>
                    <span class="soft-badge gray">${p.business_type || 'General'}</span>
                    ${productSizeText(p) ? `<span class="soft-badge gray">${productSizeText(p)}</span>` : ''}
                </div>
                <div class="product-price">PHP ${money(p.selling_price)}</div>
                <div class="stock-line"><span>${p.quantity} stocks available</span><span class="stock-pill ${stock.cls}">${stock.label}</span></div>
                <div class="stock-meter ${stock.cls}"><span style="width:${stock.percent}%"></span></div>
                <div class="muted small mb-3"><i class="bi bi-box"></i> ${productPackageText(p) || 'No package'} · <i class="bi bi-upc-scan"></i> ${barcode || 'No barcode'}</div>
                <div class="product-actions">
                    <button class="btn btn-outline-primary" onclick="viewProduct(${p.id})"><i class="bi bi-eye"></i> View</button>
                    <button class="btn btn-success" ${p.status !== 'Approved' || Number(p.quantity) <= 0 ? 'disabled' : ''} onclick="goToPos('${barcode}')"><i class="bi bi-cart-plus"></i> Add</button>
                    <button class="btn btn-outline-secondary" onclick="quickViewProduct(${p.id})"><i class="bi bi-lightning"></i> Quick</button>
                    <button class="btn btn-outline-primary" onclick="showBarcode('${barcode}')"><i class="bi bi-upc"></i> Barcode</button>
                    ${p.can_edit ? `<button class="btn btn-outline-primary" onclick="editProductById(${p.id})"><i class="bi bi-pencil"></i> Edit</button>` : ''}
                    ${isAdmin ? `<button class="btn btn-outline-danger" onclick="openDeleteModal(${p.id})"><i class="bi bi-trash"></i> Delete</button>` : ''}
                </div>
            </div>
        </article>
    `;
}

function setView(view) {
    currentView = view;
    localStorage.setItem('inventoryView', view);
    document.getElementById('productGrid').classList.toggle('d-none', view !== 'grid');
    document.getElementById('productTableWrap').classList.toggle('d-none', view !== 'list');
    document.getElementById('gridViewBtn').className = `btn ${view === 'grid' ? 'btn-primary' : 'btn-outline-primary'}`;
    document.getElementById('listViewBtn').className = `btn ${view === 'list' ? 'btn-primary' : 'btn-outline-primary'}`;
}

function showSkeleton() {
    document.getElementById('productGrid').innerHTML = `<div class="product-skeleton-grid">${Array.from({ length: 8 }).map(() => `<div class="product-skeleton-card"><div class="skeleton mb-3" style="height:160px;border-radius:16px"></div><div class="skeleton mb-2" style="width:80%"></div><div class="skeleton mb-2" style="width:55%"></div><div class="skeleton" style="width:70%"></div></div>`).join('')}</div>`;
}

async function loadOptions() {
    options = await apiGet('../php/inventory_action.php?action=options');
    fillSelect('category_id', options.categories);
    fillSelect('brand_id', options.brands);
    fillSelect('unit_id', options.units);
    fillSelect('supplier_id', options.suppliers);
    fillSelect('business_type_id', options.business_types);
    fillSelect('categoryFilter', options.categories, true);
    fillSelect('businessFilter', options.business_types, true);
    initInventoryCategorySelect2();
}

function fillSelect(id, rows, keepFirst = false) {
    const el = document.getElementById(id);
    const first = keepFirst ? (el.multiple ? '' : el.querySelector('option')?.outerHTML || '<option value="">All</option>') : '<option value="">Select</option>';
    el.innerHTML = first + rows.map(r => `<option value="${r.id}">${r.name}</option>`).join('');
}

function initInventoryCategorySelect2() {
    if (!window.jQuery || !jQuery.fn.select2) return;
    jQuery('#categoryFilter').select2({
        placeholder: 'All Categories',
        allowClear: true,
        closeOnSelect: false,
        width: '100%'
    }).on('change', () => {
        page = 1;
        loadProducts();
    });
}

async function loadProducts() {
    showSkeleton();
    const params = new URLSearchParams({
        action: 'list',
        page,
        search: `${document.getElementById('search').value} ${document.getElementById('barcodeFilter').value}`.trim(),
        categories: Array.from(document.getElementById('categoryFilter').selectedOptions).map(option => option.value).filter(Boolean).join(','),
        business_type: document.getElementById('businessFilter').value,
        stock: document.getElementById('stockFilter').value,
    });
    const data = await apiGet(`../php/inventory_action.php?${params}`);
    document.getElementById('productGrid').innerHTML = data.rows.map(p => productCard(p, data.is_admin)).join('') || '<div class="text-center muted py-5">No products found.</div>';
    document.getElementById('productRows').innerHTML = data.rows.map(p => `
        <tr>
            <td><strong>${p.barcode || 'N/A'}</strong><div class="muted">${p.product_code}</div></td>
            <td>${p.image_path ? `<img class="product-thumb" src="../${p.image_path}">` : '<span class="avatar"><i class="bi bi-box"></i></span>'}</td>
            <td>${p.product_name}<div class="muted">${p.brand || ''}${productSizeText(p) ? ` · ${productSizeText(p)}` : ''}${productPackageText(p) ? ` · ${productPackageText(p)}` : ''}</div></td>
            <td>${p.category || ''}</td><td>${p.business_type || ''}</td><td>PHP ${money(p.selling_price)}</td><td>${p.quantity}</td>
            <td><span class="badge status-badge bg-${p.status === 'Approved' ? 'success' : p.status === 'Rejected' ? 'danger' : 'warning'}">${p.status}</span></td>
            <td>
                <button class="btn btn-sm btn-outline-secondary action-btn" title="View" onclick="viewProduct(${p.id})"><i class="bi bi-eye"></i></button>
                ${p.can_edit ? `<button class="btn btn-sm btn-outline-primary action-btn" title="Edit" onclick="editProductById(${p.id})"><i class="bi bi-pencil"></i></button>` : ''}
                ${data.is_admin ? `<button class="btn btn-sm btn-outline-danger action-btn" title="Delete" onclick="openDeleteModal(${p.id})"><i class="bi bi-trash"></i></button>` : ''}
            </td>
        </tr>`).join('') || '<tr><td colspan="9" class="text-center">No products found.</td></tr>';
    document.getElementById('pageInfo').textContent = `Page ${data.page} of ${data.pages}`;
    document.getElementById('prevPage').disabled = data.page <= 1;
    document.getElementById('nextPage').disabled = data.page >= data.pages;
    setView(currentView);
}

function openProductModal() {
    document.getElementById('productForm').reset();
    document.getElementById('category_id').value = '';
    document.getElementById('productId').value = '';
    document.getElementById('duplicateDecision').value = '';
    document.getElementById('duplicateReferenceId').value = '';
    renderDuplicateWarning([]);
    document.getElementById('productModalTitle').textContent = 'Add Product';
    setTimeout(() => document.getElementById('productBarcode')?.focus(), 250);
}

function editProduct(p) {
    openProductModal();
    document.getElementById('productModalTitle').textContent = 'Edit Product';
    Object.keys(p).forEach(k => {
        const field = document.querySelector(`[name="${k}"]`);
        if (field && field.type !== 'file') field.value = p[k] ?? '';
    });
    document.getElementById('category_id').value = p.category_id || '';
    modal.show();
    checkDuplicateNow();
}

async function editProductById(id) {
    const result = await apiGet(`../php/inventory_action.php?action=view&id=${id}`);
    if (!result.success) return notify(result.message, 'error');
    if (!result.product.can_edit) return notify('You cannot edit this product.', 'error');
    editProduct(result.product);
}

function productDetailsHtml(p, compact = false) {
    const stock = stockInfo(p);
    return `
        <div class="row g-3">
            <div class="${compact ? 'col-12' : 'col-md-5'}">
                <div class="product-image-wrap rounded-4">${productImage(p)}</div>
                <div class="stock-meter ${stock.cls} mt-3"><span style="width:${stock.percent}%"></span></div>
                <span class="stock-pill ${stock.cls}">${stock.label}</span>
            </div>
            <div class="${compact ? 'col-12' : 'col-md-7'}">
                <div class="product-badges mb-2">
                    <span class="soft-badge">${p.category || 'Uncategorized'}</span>
                    <span class="soft-badge gray">${p.business_type || 'General'}</span>
                    <span class="badge bg-${p.status === 'Approved' ? 'success' : p.status === 'Rejected' ? 'danger' : 'warning'}">${p.status}</span>
                </div>
                <h4 class="fw-bold">${p.product_name}</h4>
                <div class="product-price mb-3">PHP ${money(p.selling_price)}</div>
                <div class="row g-2">
                    <div class="col-6"><strong>Product Code</strong><br>${p.product_code}</div>
                    <div class="col-6"><strong>Barcode</strong><br>${p.barcode || 'N/A'}</div>
                    <div class="col-6"><strong>Brand</strong><br>${p.brand || 'N/A'}</div>
                    <div class="col-6"><strong>Unit</strong><br>${p.unit || 'N/A'}</div>
                    <div class="col-6"><strong>Size / Weight</strong><br>${productSizeText(p) || 'N/A'}</div>
                    <div class="col-6"><strong>Package Type</strong><br>${p.package_type || 'N/A'}</div>
                    <div class="col-6"><strong>Cost Price</strong><br>PHP ${money(p.cost_price)}</div>
                    <div class="col-6"><strong>Stock</strong><br>${p.quantity}</div>
                    <div class="col-6"><strong>Reorder Level</strong><br>${p.reorder_level}</div>
                    <div class="col-6"><strong>Supplier</strong><br>${p.supplier || 'N/A'}</div>
                    <div class="col-12"><strong>Description</strong><br>${p.description || 'N/A'}</div>
                </div>
            </div>
        </div>
    `;
}

async function viewProduct(id) {
    const result = await apiGet(`../php/inventory_action.php?action=view&id=${id}`);
    if (!result.success) return notify(result.message, 'error');
    const p = result.product;
    document.getElementById('viewProductTitle').textContent = p.product_name;
    document.getElementById('viewProductBody').innerHTML = productDetailsHtml(p);
    const editBtn = document.getElementById('viewEditBtn');
    editBtn.classList.toggle('d-none', !p.can_edit);
    editBtn.onclick = () => {
        viewModal.hide();
        editProductById(p.id);
    };
    viewModal.show();
}

async function quickViewProduct(id) {
    const result = await apiGet(`../php/inventory_action.php?action=quick_view&id=${id}`);
    if (!result.success) return notify(result.message, 'error');
    const p = result.product;
    Swal.fire({
        title: 'Quick View',
        width: 640,
        html: productDetailsHtml(p, true),
        showCancelButton: true,
        confirmButtonText: 'Open Full View',
        cancelButtonText: 'Close',
        confirmButtonColor: '#2563eb'
    }).then(res => {
        if (res.isConfirmed) viewProduct(id);
    });
}

function renderDuplicateWarning(matches = []) {
    lastDuplicateMatches = matches;
    const box = document.getElementById('duplicateWarning');
    if (!matches.length) {
        box.classList.add('d-none');
        box.innerHTML = '';
        return;
    }
    box.classList.remove('d-none');
    box.innerHTML = `
        <div class="alert alert-warning border-0 shadow-sm rounded-4 mb-0">
            <div class="d-flex gap-2 align-items-start">
                <i class="bi bi-exclamation-triangle-fill fs-4"></i>
                <div class="w-100">
                    <strong>Possible duplicate product found. Please review before saving.</strong>
                    <div class="row g-2 mt-2">
                        ${matches.map(m => `
                            <div class="col-md-6">
                                <div class="bg-white rounded-3 p-2 border">
                                    <div class="fw-bold">${m.product_name}</div>
                                    <div class="small text-muted">Barcode: ${m.barcode || 'N/A'} · Brand: ${m.brand || 'N/A'}</div>
                                    <div class="small text-muted">Category: ${m.category || 'N/A'} · Unit: ${m.unit || 'N/A'}</div>
                                    <div class="small">Price: PHP ${money(m.selling_price)} · Stock: ${m.quantity}</div>
                                    <span class="badge bg-${m.type === 'Exact Duplicate' ? 'danger' : 'warning'} mt-1">${m.reason}</span>
                                </div>
                            </div>
                        `).join('')}
                    </div>
                </div>
            </div>
        </div>
    `;
}

async function checkDuplicateNow() {
    const form = document.getElementById('productForm');
    const params = new URLSearchParams({
        action: 'duplicate_check',
        id: document.getElementById('productId').value || '',
        barcode: form.barcode.value || '',
        product_name: form.product_name.value || '',
        brand_id: form.brand_id.value || '',
        category_id: form.category_id.value || '',
        unit_id: form.unit_id.value || '',
        business_type_id: form.business_type_id.value || '',
    });
    if (!params.get('barcode') && !params.get('product_name')) return renderDuplicateWarning([]);
    const data = await apiGet(`../php/inventory_action.php?${params}`);
    renderDuplicateWarning(data.matches || []);
}

async function reviewDuplicateDecision(result, originalForm) {
    const exact = (result.matches || []).some(m => m.type === 'Exact Duplicate');
    const first = result.matches?.[0];
    const choice = await Swal.fire({
        title: 'Duplicate Review',
        html: `
            <p class="text-start">${result.message}</p>
            <div class="text-start bg-light rounded-3 p-3">
                <strong>${first?.product_name || ''}</strong><br>
                Barcode: ${first?.barcode || 'N/A'}<br>
                Price: PHP ${money(first?.selling_price)} · Stock: ${first?.quantity || 0}
            </div>
        `,
        icon: 'warning',
        showDenyButton: !exact,
        showCancelButton: true,
        confirmButtonText: exact ? 'Update Existing' : 'Merge',
        denyButtonText: 'Save as New',
        cancelButtonText: 'Cancel',
        confirmButtonColor: '#2563eb',
        denyButtonColor: '#22c55e'
    });
    if (choice.isConfirmed) {
        originalForm.set('duplicate_decision', exact ? 'update_existing' : 'merge');
        originalForm.set('duplicate_reference_id', first.id);
    } else if (choice.isDenied) {
        originalForm.set('duplicate_decision', 'save_new');
        originalForm.set('duplicate_reference_id', first.id);
    } else {
        return;
    }
    const retry = await apiPost('../php/inventory_action.php', originalForm);
    notify(retry.message, retry.success ? 'success' : 'error');
    if (retry.success) {
        modal.hide();
        loadProducts();
    }
}

async function openDeleteModal(id) {
    const result = await apiGet(`../php/inventory_action.php?action=view&id=${id}`);
    if (!result.success) return notify(result.message, 'error');
    document.getElementById('deleteProductId').value = id;
    document.getElementById('deleteProductName').innerHTML = `<b>${result.product.product_name}</b><br><span class="small">Barcode: ${result.product.barcode || 'N/A'} · Stock: ${result.product.quantity}</span>`;
    deleteModal.show();
}

async function deleteProduct(id) {
    const result = await apiPost('../php/inventory_action.php', { action: 'delete', id });
    notify(result.message, result.success ? 'success' : 'error');
    if (result.success) {
        deleteModal.hide();
        loadProducts();
    }
}

async function showBarcode(barcode) {
    if (!barcode) return notify('This product has no barcode.', 'error');
    const result = await apiGet(`../php/inventory_action.php?action=barcode_lookup&barcode=${encodeURIComponent(barcode)}`);
    if (!result.success) return notify(result.message, 'error');
    navigator.clipboard?.writeText(barcode);
    Swal.fire({
        title: 'Barcode',
        html: `<div class="text-center"><div class="display-6 fw-bold">${barcode}</div><p class="muted mb-0">${result.product.product_name}</p><p class="small text-muted">Barcode copied to clipboard.</p></div>`,
        confirmButtonColor: '#2563eb'
    });
}

function goToPos(barcode) {
    location.href = `pos.php${barcode ? `?barcode=${encodeURIComponent(barcode)}` : ''}`;
}

document.getElementById('productForm').addEventListener('submit', async e => {
    e.preventDefault();
    const form = new FormData(e.target);
    form.append('action', form.get('id') ? 'update' : 'create');
    const result = await apiPost('../php/inventory_action.php', form);
    if (result.duplicate_warning) {
        renderDuplicateWarning(result.matches || []);
        await reviewDuplicateDecision(result, form);
        return;
    }
    notify(result.message, result.success ? 'success' : 'error');
    if (result.success) {
        modal.hide();
        loadProducts();
    }
});

['search', 'barcodeFilter', 'businessFilter', 'stockFilter'].forEach(id => document.getElementById(id).addEventListener('input', () => { page = 1; loadProducts(); }));
document.getElementById('categoryFilter').addEventListener('change', () => { page = 1; loadProducts(); });
['barcode', 'product_name', 'brand_id', 'category_id', 'unit_id', 'business_type_id'].forEach(name => {
    const field = document.querySelector(`[name="${name}"]`);
    const eventName = field?.tagName === 'SELECT' ? 'change' : 'input';
    field?.addEventListener(eventName, () => {
        clearTimeout(window.duplicateTimer);
        window.duplicateTimer = setTimeout(checkDuplicateNow, 350);
    });
});

document.getElementById('productBarcode')?.addEventListener('keydown', e => {
    if (e.key !== 'Enter') return;
    e.preventDefault();
    clearTimeout(window.duplicateTimer);
    checkDuplicateNow();
    document.querySelector('[name="product_name"]')?.focus();
});
document.getElementById('prevPage').onclick = () => { page--; loadProducts(); };
document.getElementById('nextPage').onclick = () => { page++; loadProducts(); };
document.getElementById('gridViewBtn').onclick = () => setView('grid');
document.getElementById('listViewBtn').onclick = () => setView('list');
document.getElementById('confirmDeleteBtn').onclick = () => deleteProduct(document.getElementById('deleteProductId').value);

function readImportRows(file) {
    return new Promise((resolve, reject) => {
        const reader = new FileReader();
        reader.onload = e => {
            try {
                const data = new Uint8Array(e.target.result);
                const workbook = XLSX.read(data, { type: 'array' });
                const sheet = workbook.Sheets[workbook.SheetNames[0]];
                resolve(XLSX.utils.sheet_to_json(sheet, { defval: '' }));
            } catch (err) {
                reject(err);
            }
        };
        reader.onerror = reject;
        reader.readAsArrayBuffer(file);
    });
}

document.getElementById('scanImportBtn')?.addEventListener('click', async () => {
    const file = document.getElementById('importFile').files[0];
    if (!file) return notify('Choose a CSV or Excel file first.', 'error');
    const rows = await readImportRows(file);
    const result = await apiPost('../php/inventory_action.php', { action: 'import_scan', file_name: file.name, rows: JSON.stringify(rows) });
    notify(result.message, result.success ? 'success' : 'error');
    if (!result.success) return;
    currentImportBatch = result.batch_id;
    const s = result.summary;
    document.getElementById('importSummary').innerHTML = [
        ['Total rows scanned', s.total_rows, 'primary'],
        ['New products', s.new_products, 'success'],
        ['Exact duplicates', s.exact_duplicates, 'danger'],
        ['Possible duplicates', s.possible_duplicates, 'warning'],
        ['Invalid products', s.invalid_rows, 'secondary'],
    ].map(item => `<div class="col-md-4"><div class="summary-card"><div><strong>${item[1]}</strong><span>${item[0]}</span></div></div></div>`).join('');
    document.getElementById('duplicateReportLink').href = `../php/inventory_action.php?action=import_duplicate_report&batch_id=${currentImportBatch}`;
    document.getElementById('duplicateReportLink').classList.toggle('d-none', !(s.exact_duplicates || s.possible_duplicates || s.invalid_rows));
    document.getElementById('commitImportBtn').classList.toggle('d-none', !s.new_products);
});

document.getElementById('commitImportBtn')?.addEventListener('click', async () => {
    if (!currentImportBatch) return;
    const result = await apiPost('../php/inventory_action.php', { action: 'import_commit', batch_id: currentImportBatch });
    notify(result.message, result.success ? 'success' : 'error');
    if (result.success) {
        loadProducts();
        document.getElementById('commitImportBtn').classList.add('d-none');
    }
});

loadOptions().then(loadProducts);
