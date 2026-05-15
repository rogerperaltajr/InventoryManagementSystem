let receiptPage = 1;
let receiptRows = [];
const receiptEditModal = new bootstrap.Modal(document.getElementById('receiptEditModal'));

function receiptParams() {
    return new URLSearchParams({
        action: 'list',
        page: receiptPage,
        limit: document.getElementById('receiptLimit').value,
        from: document.getElementById('receiptFrom').value,
        to: document.getElementById('receiptTo').value,
    });
}

async function loadReceipts() {
    const data = await apiGet(`../php/receipts_action.php?${receiptParams()}`);
    receiptRows = data.rows || [];
    document.getElementById('receiptRows').innerHTML = receiptRows.map(row => `
        <tr>
            <td><strong>${escapeHtml(row.buyer_label)}</strong></td>
            <td>${escapeHtml(row.invoice_no)}</td>
            <td>${escapeHtml(row.created_at)}</td>
            <td>${escapeHtml(row.cashier || 'N/A')}</td>
            <td>${Number(row.item_count || 0)}</td>
            <td><strong>PHP ${money(row.total)}</strong></td>
            <td>${escapeHtml(row.payment_method || 'Cash')}</td>
            <td class="receipt-actions-print">
                <button class="btn btn-sm btn-outline-primary action-btn" title="View" onclick="showReceiptDetail(${row.id}, decodeURIComponent('${encodeURIComponent(row.buyer_label)}'))"><i class="bi bi-eye"></i></button>
                <button class="btn btn-sm btn-outline-secondary action-btn" title="Edit" onclick="openReceiptEdit(${row.id})"><i class="bi bi-pencil"></i></button>
                <button class="btn btn-sm btn-outline-danger action-btn" title="Delete" onclick="deleteReceipt(${row.id})"><i class="bi bi-trash"></i></button>
            </td>
        </tr>
    `).join('') || '<tr><td colspan="8" class="text-center">No receipts found.</td></tr>';
    document.getElementById('receiptSummary').textContent = `${data.total || 0} receipt(s) found`;
    document.getElementById('receiptPageInfo').textContent = `Page ${data.page} of ${data.pages}`;
    document.getElementById('prevReceiptPage').disabled = data.page <= 1 || data.limit === 'all';
    document.getElementById('nextReceiptPage').disabled = data.page >= data.pages || data.limit === 'all';
}

function openReceiptEdit(id) {
    const row = receiptRows.find(item => Number(item.id) === Number(id));
    if (!row) return;
    document.getElementById('editReceiptId').value = row.id;
    document.getElementById('editBuyerName').value = row.buyer_name || row.buyer_label;
    document.getElementById('editPaymentMethod').value = row.payment_method || 'Cash';
    receiptEditModal.show();
}

async function deleteReceipt(id) {
    const confirm = await Swal.fire({
        icon: 'warning',
        title: 'Delete receipt?',
        text: 'This will remove the receipt and its sold item records.',
        showCancelButton: true,
        confirmButtonText: 'Delete',
        confirmButtonColor: '#ef4444'
    });
    if (!confirm.isConfirmed) return;
    const result = await apiPost('../php/receipts_action.php', { action: 'delete', id });
    notify(result.message, result.success ? 'success' : 'error');
    if (result.success) {
        loadReceipts();
        window.refreshReceiptNotifications?.();
    }
}

document.getElementById('receiptEditForm').addEventListener('submit', async e => {
    e.preventDefault();
    const form = new FormData(e.target);
    form.append('action', 'update');
    const result = await apiPost('../php/receipts_action.php', form);
    notify(result.message, result.success ? 'success' : 'error');
    if (result.success) {
        receiptEditModal.hide();
        loadReceipts();
        window.refreshReceiptNotifications?.();
    }
});

document.getElementById('filterReceipts').onclick = () => { receiptPage = 1; loadReceipts(); };
document.getElementById('receiptLimit').onchange = () => { receiptPage = 1; loadReceipts(); };
document.getElementById('prevReceiptPage').onclick = () => { receiptPage--; loadReceipts(); };
document.getElementById('nextReceiptPage').onclick = () => { receiptPage++; loadReceipts(); };
document.getElementById('printReceipts').onclick = () => window.print();

loadReceipts();
