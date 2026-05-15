async function loadPending() {
    const data = await apiGet('../php/product_approval_action.php?action=list');
    document.getElementById('approvalStats').innerHTML = [
        ['Pending', data.stats.pending, 'bi-hourglass-split', 'warning'],
        ['Approved', data.stats.approved, 'bi-check2-circle', 'success'],
        ['Rejected', data.stats.rejected, 'bi-x-circle', 'danger'],
    ].map(s => `<div class="col-md-4"><div class="summary-card"><div class="summary-icon text-${s[3]}"><i class="bi ${s[2]}"></i></div><div><strong>${s[1]}</strong><span>${s[0]} products</span></div></div></div>`).join('');
    document.getElementById('approvalRows').innerHTML = data.rows.map(p => `
        <tr>
            <td>${p.product_code}</td>
            <td>${p.product_name}
                ${p.duplicate_status && p.duplicate_status !== 'None' ? `<div><span class="badge bg-warning mt-1"><i class="bi bi-exclamation-triangle"></i> ${p.duplicate_status}</span></div>` : ''}
            </td>
            <td>${p.barcode || ''}</td><td>${p.quantity}</td><td>${p.full_name || ''}</td>
            <td><input class="form-control form-control-sm" id="remarks-${p.id}" placeholder="Remarks"></td>
            <td>
                <button class="btn btn-sm btn-outline-secondary action-btn" title="Preview" onclick='previewProduct(${JSON.stringify(p)})'><i class="bi bi-eye"></i></button>
                ${p.duplicate_reference_id ? `<button class="btn btn-sm btn-outline-warning action-btn" title="Compare duplicate" onclick='compareDuplicate(${JSON.stringify(p)})'><i class="bi bi-intersect"></i></button>` : ''}
                <button class="btn btn-sm btn-success action-btn" title="Approve" onclick="decide(${p.id}, 'Approved')"><i class="bi bi-check2"></i></button>
                <button class="btn btn-sm btn-danger action-btn" title="Reject" onclick="decide(${p.id}, 'Rejected')"><i class="bi bi-x-lg"></i></button>
            </td>
        </tr>`).join('') || '<tr><td colspan="7" class="text-center">No pending products.</td></tr>';
}

function previewProduct(p) {
    Swal.fire({
        title: p.product_name,
        html: `
            <div class="swal-modal-grid">
                <div class="swal-info-card">
                    <div class="fw-bold mb-2">Product Information</div>
                    <div class="row g-2">
                        <div class="col-6"><span class="muted">Code</span><br><strong>${p.product_code}</strong></div>
                        <div class="col-6"><span class="muted">Barcode</span><br><strong>${p.barcode || 'N/A'}</strong></div>
                        <div class="col-6"><span class="muted">Quantity</span><br><strong>${p.quantity}</strong></div>
                        <div class="col-6"><span class="muted">Submitted by</span><br><strong>${p.full_name || 'N/A'}</strong></div>
                    </div>
                </div>
            </div>
        `,
        confirmButtonColor: '#2563eb'
    });
}

function compareDuplicate(p) {
    Swal.fire({
        title: 'Duplicate Comparison',
        width: 820,
        html: `
            <div class="row g-3 text-start">
                <div class="col-md-6">
                    <div class="swal-info-card h-100">
                        <div class="fw-bold mb-2">Submitted Product</div>
                        <p class="mb-2"><b>${p.product_name}</b></p>
                        <div class="small lh-lg">Barcode: ${p.barcode || 'N/A'}<br>Brand: ${p.brand_name || 'N/A'}<br>Category: ${p.category || 'N/A'}<br>Unit: ${p.unit || 'N/A'}<br>Price: PHP ${money(p.selling_price)}<br>Stock: ${p.quantity}</div>
                    </div>
                </div>
                <div class="col-md-6">
                    <div class="swal-info-card h-100">
                        <div class="fw-bold mb-2">Matched Existing Product</div>
                        <p class="mb-2"><b>${p.duplicate_product_name || 'N/A'}</b></p>
                        <div class="small lh-lg">Barcode: ${p.duplicate_barcode || 'N/A'}<br>Current Price: PHP ${money(p.duplicate_price)}<br>Current Stock: ${p.duplicate_stock || 0}</div>
                    </div>
                </div>
            </div>
        `,
        showCancelButton: true,
        showDenyButton: true,
        confirmButtonText: 'Merge',
        denyButtonText: 'Reject',
        cancelButtonText: 'Close',
        confirmButtonColor: '#22c55e',
        denyButtonColor: '#ef4444'
    }).then(async result => {
        if (result.isConfirmed) {
            const response = await apiPost('../php/inventory_action.php', { action: 'merge_duplicate', source_id: p.id, target_id: p.duplicate_reference_id });
            notify(response.message, response.success ? 'success' : 'error');
            loadPending();
        } else if (result.isDenied) {
            decide(p.id, 'Rejected');
        }
    });
}

async function decide(id, status) {
    const remarks = document.getElementById(`remarks-${id}`).value;
    const result = await apiPost('../php/product_approval_action.php', { action: 'decide', id, status, remarks });
    notify(result.message, result.success ? 'success' : 'error');
    loadPending();
}

loadPending();
