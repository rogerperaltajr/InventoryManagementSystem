const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content || '';

document.getElementById('sidebarToggle')?.addEventListener('click', () => {
    document.querySelector('.sidebar')?.classList.toggle('open');
});

document.getElementById('sidebarSizeToggle')?.addEventListener('click', () => {
    const root = document.documentElement;
    const collapsed = root.classList.toggle('sidebar-collapsed');
    localStorage.setItem('sidebarCollapsed', collapsed ? '1' : '0');
});

async function apiPost(url, data = {}) {
    const form = data instanceof FormData ? data : new FormData();
    if (!(data instanceof FormData)) {
        Object.entries(data).forEach(([key, value]) => form.append(key, value));
    }
    form.append('csrf_token', csrfToken);
    const res = await fetch(url, { method: 'POST', body: form, headers: { 'X-CSRF-Token': csrfToken } });
    return res.json();
}

async function apiGet(url) {
    const res = await fetch(url, { headers: { 'X-CSRF-Token': csrfToken } });
    return res.json();
}

function notify(message, type = 'success') {
    if (window.Swal) {
        Swal.fire({ icon: type, text: message, timer: 1800, showConfirmButton: false });
    } else {
        alert(message);
    }
}

function money(value) {
    return Number(value || 0).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 });
}

function escapeHtml(value) {
    return String(value ?? '').replace(/[&<>"']/g, char => ({
        '&': '&amp;',
        '<': '&lt;',
        '>': '&gt;',
        '"': '&quot;',
        "'": '&#039;'
    }[char]));
}

function receiptEndpoint(action, params = {}) {
    const query = new URLSearchParams({ action, ...params });
    return `../php/notifications_action.php?${query}`;
}

function receiptItemsHtml(items = []) {
    return `
        <div class="table-responsive">
            <table class="table table-sm align-middle mb-0">
                <thead><tr><th>Item</th><th class="text-center">Qty</th><th class="text-end">Price</th><th class="text-end">Subtotal</th></tr></thead>
                <tbody>
                    ${items.map(item => `
                        <tr>
                            <td>${escapeHtml(item.product_name || 'Deleted product')}</td>
                            <td class="text-center">${escapeHtml(item.quantity)}</td>
                            <td class="text-end">PHP ${money(item.price)}</td>
                            <td class="text-end">PHP ${money(item.subtotal)}</td>
                        </tr>
                    `).join('') || '<tr><td colspan="4" class="text-center muted">No items found.</td></tr>'}
                </tbody>
            </table>
        </div>
    `;
}

async function showReceiptDetail(id, buyerLabel = 'Buyer') {
    const data = await apiGet(receiptEndpoint('receipt', { id }));
    if (!data.success) return notify(data.message || 'Receipt not found.', 'error');

    const receipt = data.receipt;
    document.getElementById('receiptDetailTitle').textContent = `${buyerLabel} - ${receipt.invoice_no}`;
    document.getElementById('receiptDetailBody').innerHTML = `
        <div class="receipt-detail-summary">
            <div><span>Invoice</span><strong>${escapeHtml(receipt.invoice_no)}</strong></div>
            <div><span>Date</span><strong>${escapeHtml(receipt.created_at)}</strong></div>
            <div><span>Cashier</span><strong>${escapeHtml(receipt.cashier || 'N/A')}</strong></div>
            <div><span>Payment</span><strong>${escapeHtml(receipt.payment_method)}</strong></div>
        </div>
        ${receiptItemsHtml(data.items)}
        <div class="receipt-total-box">
            <div><span>Subtotal</span><strong>PHP ${money(receipt.subtotal)}</strong></div>
            <div><span>Discount</span><strong>PHP ${money(receipt.discount)}</strong></div>
            <div><span>Total</span><strong>PHP ${money(receipt.total)}</strong></div>
            <div><span>Payment</span><strong>PHP ${money(receipt.payment_amount)}</strong></div>
            <div><span>Change</span><strong>PHP ${money(receipt.change_amount)}</strong></div>
        </div>
    `;
    bootstrap.Modal.getOrCreateInstance(document.getElementById('receiptDetailModal')).show();
}

async function loadReceiptNotifications() {
    const list = document.getElementById('receiptNotificationList');
    const dot = document.getElementById('receiptNotificationDot');
    if (!list) return;

    const data = await apiGet(receiptEndpoint('receipts'));
    const rows = data.rows || [];
    dot?.classList.toggle('d-none', !rows.length);
    list.innerHTML = rows.map(row => `
        <button class="receipt-notification-item" type="button" onclick="showReceiptDetail(${Number(row.id)}, '${escapeHtml(row.buyer_label)}')">
            <span>
                <strong>${escapeHtml(row.buyer_label)}</strong>
                <small>${escapeHtml(row.invoice_no)} · ${escapeHtml(row.created_at)}</small>
            </span>
            <b>PHP ${money(row.total)}</b>
        </button>
    `).join('') || '<div class="receipt-notification-empty">No receipts yet.</div>';
}

document.getElementById('refreshReceiptsBtn')?.addEventListener('click', event => {
    event.stopPropagation();
    loadReceiptNotifications();
});

window.refreshReceiptNotifications = loadReceiptNotifications;
window.showReceiptDetail = showReceiptDetail;
loadReceiptNotifications();

function tableToExcel(tableId, filename) {
    const table = document.getElementById(tableId);
    const wb = XLSX.utils.table_to_book(table, { sheet: 'Report' });
    XLSX.writeFile(wb, `${filename}.xlsx`);
}

function tableToImage(containerId, filename) {
    html2canvas(document.getElementById(containerId)).then(canvas => {
        const link = document.createElement('a');
        link.download = `${filename}.png`;
        link.href = canvas.toDataURL('image/png');
        link.click();
    });
}
