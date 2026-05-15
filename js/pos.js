let cart = [];
let posProducts = new Map();
let scannerBuffer = '';
let scannerLastKeyAt = 0;
let posIsAdmin = false;
let posProductOptionsLoaded = false;
const scannerMaxGapMs = 80;
const productModalEl = document.getElementById('productModal');
const productModal = productModalEl ? new bootstrap.Modal(productModalEl) : null;

function productImage(product) {
    return product.image_path
        ? `<img src="../${product.image_path}" alt="${product.product_name}">`
        : `<div class="product-placeholder"><i class="bi bi-basket2"></i></div>`;
}

function stockInfo(product) {
    const qty = Number(product.quantity || 0);
    const reorder = Number(product.reorder_level || 0);
    if (qty <= 0) return { label: 'Out of Stock', cls: 'out', percent: 0 };
    if (qty <= reorder) return { label: 'Low Stock', cls: 'low', percent: Math.max(14, Math.min(45, qty * 8)) };
    return { label: 'In Stock', cls: 'in', percent: Math.min(100, Math.max(58, qty * 2)) };
}

function productSizeText(product) {
    const value = Number(product.product_size_value || 0);
    const unit = product.product_size_unit || '';
    if (!value || !unit) return '';
    return `${Number.isInteger(value) ? value : value.toFixed(2)} ${unit}`;
}

function posProductCard(product) {
    const stock = stockInfo(product);
    const adminMenu = posIsAdmin ? `
        <div class="dropdown pos-card-menu" onclick="event.stopPropagation();">
            <button class="pos-card-menu-btn" type="button" data-bs-toggle="dropdown" aria-expanded="false" aria-label="Product actions">
                <i class="bi bi-three-dots-vertical"></i>
            </button>
            <ul class="dropdown-menu dropdown-menu-end">
                <li><button class="dropdown-item" type="button" onclick="editPosProduct(${product.id})"><i class="bi bi-pencil-square"></i> Edit</button></li>
            </ul>
        </div>
    ` : '';
    return `
        <article class="product-card compact" onclick="addProductToCart(${product.id})">
            ${adminMenu}
            <div class="product-image-wrap">${productImage(product)}</div>
            <div class="product-card-body">
                <div class="product-title">${product.product_name}</div>
                <div class="product-badges">
                    ${product.brand ? `<span class="soft-badge">${product.brand}</span>` : ''}
                    <span class="soft-badge">${product.category || 'Product'}</span>
                    <span class="soft-badge gray">${productSizeText(product) || product.business_type || product.product_code}</span>
                </div>
                <div class="product-price">PHP ${money(product.selling_price)}</div>
                <div class="stock-line"><span>${product.quantity} stocks</span><span class="stock-pill ${stock.cls}">${stock.label}</span></div>
                <div class="stock-meter ${stock.cls}"><span style="width:${stock.percent}%"></span></div>
                <div class="muted small mb-3"><i class="bi bi-box"></i> ${product.package_type || 'Item'} · <i class="bi bi-upc-scan"></i> ${product.barcode || 'No barcode'}</div>
                <div class="product-actions">
                    <button class="btn btn-success" onclick="event.stopPropagation(); addProductToCart(${product.id})"><i class="bi bi-cart-plus"></i> Cart</button>
                </div>
            </div>
        </article>
    `;
}

function showPosSkeleton() {
    document.getElementById('posProductGrid').innerHTML = Array.from({ length: 6 }).map(() => `<div class="product-skeleton-card"><div class="skeleton mb-3" style="height:130px;border-radius:16px"></div><div class="skeleton mb-2" style="width:80%"></div><div class="skeleton" style="width:55%"></div></div>`).join('');
}

async function loadMethods() {
    const data = await apiGet('../php/pos_action.php?action=methods');
    document.getElementById('paymentMethod').innerHTML = data.methods.map(m => `<option>${m}</option>`).join('');
    document.getElementById('categoryFilter').innerHTML = data.categories.map(c => `<option value="${c.id}">${c.name}</option>`).join('');
    if (window.jQuery && jQuery.fn.select2) {
        jQuery('#categoryFilter').select2({
            placeholder: 'All Categories',
            allowClear: true,
            closeOnSelect: false,
            width: '100%'
        }).on('change', () => searchProducts(document.getElementById('productSearch').value));
    }
}

async function searchProducts(term = '') {
    showPosSkeleton();
    const categoryIds = Array.from(document.getElementById('categoryFilter').selectedOptions).map(option => option.value).filter(Boolean);
    const data = await apiGet(`../php/pos_action.php?action=search&term=${encodeURIComponent(term)}&category_ids=${encodeURIComponent(categoryIds.join(','))}`);
    posIsAdmin = Boolean(data.is_admin);
    posProducts = new Map(data.rows.map(product => [Number(product.id), product]));
    document.getElementById('posProductGrid').innerHTML = data.rows.map(posProductCard).join('') || '<div class="text-center muted py-5">No products found.</div>';
}

function fillPosProductSelect(id, rows) {
    const el = document.getElementById(id);
    if (!el) return;
    el.innerHTML = '<option value="">Select</option>' + rows.map(row => `<option value="${row.id}">${row.name}</option>`).join('');
}

async function loadPosProductOptions() {
    if (!productModalEl || posProductOptionsLoaded) return;
    const options = await apiGet('../php/inventory_action.php?action=options');
    fillPosProductSelect('category_id', options.categories);
    fillPosProductSelect('brand_id', options.brands);
    fillPosProductSelect('unit_id', options.units);
    fillPosProductSelect('supplier_id', options.suppliers);
    fillPosProductSelect('business_type_id', options.business_types);
    posProductOptionsLoaded = true;
}

function resetPosDuplicateWarning() {
    const box = document.getElementById('duplicateWarning');
    if (!box) return;
    box.classList.add('d-none');
    box.innerHTML = '';
}

function fillPosProductForm(product) {
    const form = document.getElementById('productForm');
    form.reset();
    resetPosDuplicateWarning();
    document.getElementById('productModalTitle').textContent = 'Edit Product';
    Object.keys(product).forEach(key => {
        const field = form.querySelector(`[name="${key}"]`);
        if (field && field.type !== 'file') field.value = product[key] ?? '';
    });
    document.getElementById('productId').value = product.id || '';
    document.getElementById('duplicateDecision').value = '';
    document.getElementById('duplicateReferenceId').value = '';
}

async function editPosProduct(id) {
    if (!productModal) return;
    await loadPosProductOptions();
    const result = await apiGet(`../php/inventory_action.php?action=view&id=${id}`);
    if (!result.success) return notify(result.message, 'error');
    if (!result.product.can_edit) return notify('You cannot edit this product.', 'error');
    fillPosProductForm(result.product);
    productModal.show();
}

function syncCartProduct(product) {
    const item = cart.find(row => Number(row.id) === Number(product.id));
    if (!item) return;
    item.name = product.product_name;
    item.price = Number(product.selling_price);
    item.stock = Number(product.quantity);
    if (item.qty > item.stock) item.qty = Math.max(1, item.stock);
    renderCart();
}

async function scanBarcode(code) {
    const data = await apiGet(`../php/pos_action.php?action=barcode&code=${encodeURIComponent(code)}`);
    if (!data.success) {
        notify('Product not registered', 'error');
        return;
    }
    addToCart(data.product);
}

function addProductToCart(productId) {
    const product = posProducts.get(Number(productId));
    if (!product) {
        notify('Product is no longer available in this view.', 'error');
        return;
    }
    addToCart(product);
}

function addToCart(product) {
    if (Number(product.quantity) <= 0) {
        notify('Insufficient stock.', 'error');
        return;
    }
    const item = cart.find(i => i.id == product.id);
    if (item) {
        if (item.qty + 1 > Number(product.quantity)) return notify('Insufficient stock.', 'error');
        item.qty++;
    } else {
        cart.push({ id: product.id, name: product.product_name, price: Number(product.selling_price), stock: Number(product.quantity), qty: 1 });
    }
    renderCart();
}

function renderCart() {
    document.getElementById('cartRows').innerHTML = cart.map((i, idx) => `
        <tr>
            <td>${i.name}<div class="muted">PHP ${money(i.price)}</div></td>
            <td>
                <div class="pos-qty-stepper" aria-label="Quantity controls for ${i.name}">
                    <button type="button" onclick="adjustQty(${idx}, -1)" aria-label="Decrease quantity">-</button>
                    <input type="number" min="1" max="${i.stock}" value="${i.qty}" onchange="setQty(${idx}, this.value)" aria-label="Quantity">
                    <button type="button" onclick="adjustQty(${idx}, 1)" aria-label="Increase quantity">+</button>
                </div>
            </td>
            <td>PHP ${money(i.price * i.qty)}</td>
        </tr>`).join('') || '<tr><td colspan="3" class="text-center">Cart is empty.</td></tr>';
    recalc();
}

function adjustQty(idx, delta) {
    if (!cart[idx]) return;
    setQty(idx, cart[idx].qty + delta);
}

function removeCartItem(idx) {
    cart.splice(idx, 1);
    renderCart();
}

function setQty(idx, value) {
    const qty = Math.max(0, Number(value));
    if (qty <= 0) {
        removeCartItem(idx);
        return;
    }
    if (qty > cart[idx].stock) {
        notify('Insufficient stock.', 'error');
        cart[idx].qty = cart[idx].stock;
    } else {
        cart[idx].qty = qty;
    }
    renderCart();
}

function recalc() {
    const subtotal = cart.reduce((sum, i) => sum + i.price * i.qty, 0);
    const discount = Number(document.getElementById('discount').value || 0);
    const total = Math.max(0, subtotal - discount);
    const paid = Number(document.getElementById('paymentAmount').value || 0);
    document.getElementById('cartTotal').textContent = `PHP ${money(total)}`;
    document.getElementById('changeAmount').textContent = `PHP ${money(Math.max(0, paid - total))}`;
}

document.getElementById('barcodeInput').addEventListener('keydown', e => {
    if (e.key === 'Enter') {
        e.preventDefault();
        scanBarcode(e.target.value.trim());
        e.target.value = '';
    }
});

function isTypingField(el) {
    if (!el) return false;
    return ['INPUT', 'TEXTAREA', 'SELECT'].includes(el.tagName) || el.isContentEditable;
}

document.addEventListener('keydown', e => {
    if (e.ctrlKey || e.altKey || e.metaKey) return;
    if (document.querySelector('.modal.show')) return;
    if (document.activeElement?.id === 'barcodeInput') return;

    const activeIsTypingField = isTypingField(document.activeElement);
    const now = Date.now();
    const fastScan = scannerBuffer && (now - scannerLastKeyAt) <= scannerMaxGapMs;

    if (e.key === 'Enter') {
        const code = scannerBuffer.trim();
        scannerBuffer = '';
        if (code.length >= 4) {
            e.preventDefault();
            scanBarcode(code);
            document.activeElement?.blur?.();
            document.getElementById('barcodeInput').value = '';
        }
        return;
    }

    if (e.key.length !== 1) return;
    if (activeIsTypingField && !fastScan) {
        scannerBuffer = '';
        scannerLastKeyAt = now;
        return;
    }

    if (!fastScan) scannerBuffer = '';
    scannerBuffer += e.key;
    scannerLastKeyAt = now;

    if (activeIsTypingField && scannerBuffer.length >= 3) {
        e.preventDefault();
    }
}, true);
document.getElementById('searchBtn').onclick = () => searchProducts(document.getElementById('productSearch').value);
document.getElementById('categoryFilter').onchange = () => searchProducts(document.getElementById('productSearch').value);
document.getElementById('clearCategoryFilter').onclick = () => {
    if (window.jQuery && jQuery.fn.select2) {
        jQuery('#categoryFilter').val(null).trigger('change');
    } else {
        Array.from(document.getElementById('categoryFilter').options).forEach(option => option.selected = false);
        searchProducts(document.getElementById('productSearch').value);
    }
};
document.getElementById('productSearch').addEventListener('keydown', e => {
    if (e.key === 'Enter') {
        e.preventDefault();
        searchProducts(e.target.value);
    }
});
document.getElementById('discount').oninput = recalc;
document.getElementById('paymentAmount').oninput = recalc;
document.querySelectorAll('.payment-shortcut').forEach(btn => btn.addEventListener('click', () => {
    document.getElementById('paymentMethod').value = btn.dataset.method;
}));

document.getElementById('productForm')?.addEventListener('submit', async e => {
    e.preventDefault();
    const form = new FormData(e.target);
    form.append('action', 'update');
    const result = await apiPost('../php/inventory_action.php', form);
    notify(result.message, result.success ? 'success' : 'error');
    if (!result.success) return;

    const productId = form.get('id');
    const updated = await apiGet(`../php/inventory_action.php?action=view&id=${productId}`);
    if (updated.success) syncCartProduct(updated.product);

    productModal?.hide();
    await searchProducts(document.getElementById('productSearch').value);
});

document.getElementById('saveSale').onclick = async () => {
    const payload = {
        action: 'save',
        cart: JSON.stringify(cart),
        discount: document.getElementById('discount').value || 0,
        payment_amount: document.getElementById('paymentAmount').value || 0,
        payment_method: document.getElementById('paymentMethod').value,
    };
    const result = await apiPost('../php/pos_action.php', payload);
    notify(result.message, result.success ? 'success' : 'error');
    if (result.success) {
        const receipt = document.getElementById('receipt');
        receipt.classList.add('d-none');
        receipt.innerHTML = result.receipt_html;
        cart = [];
        renderCart();
        searchProducts();
        window.refreshReceiptNotifications?.();
    }
};

async function initPos() {
    await loadMethods();
    const initialBarcode = new URLSearchParams(location.search).get('barcode');
    if (initialBarcode) scanBarcode(initialBarcode);
    searchProducts();
    renderCart();
}

initPos();
