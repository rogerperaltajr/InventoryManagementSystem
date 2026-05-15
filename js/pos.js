let cart = [];
let posProducts = new Map();
let scannerBuffer = '';
let scannerLastKeyAt = 0;
const scannerMaxGapMs = 80;

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
    return `
        <article class="product-card compact" onclick="addProductToCart(${product.id})">
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
    posProducts = new Map(data.rows.map(product => [Number(product.id), product]));
    document.getElementById('posProductGrid').innerHTML = data.rows.map(posProductCard).join('') || '<div class="text-center muted py-5">No products found.</div>';
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
            <td><button class="btn btn-sm btn-outline-danger pos-remove-btn" onclick="removeCartItem(${idx})"><i class="bi bi-trash"></i></button></td>
        </tr>`).join('') || '<tr><td colspan="4" class="text-center">Cart is empty.</td></tr>';
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
