const tables = ['product_categories', 'units', 'suppliers', 'business_types', 'brands'];

async function loadSettings() {
    const data = await apiGet('../php/settings_action.php?action=list');
    tables.forEach(t => {
        document.getElementById(`${t}Rows`).innerHTML = data[t].map(r => `
            <tr><td><input class="form-control form-control-sm" id="${t}-${r.id}" value="${r.name}"></td>
            <td class="text-end">
                <button class="btn btn-sm btn-outline-primary action-btn" title="Save" onclick="updateOption('${t}',${r.id})"><i class="bi bi-check2"></i></button>
                <button class="btn btn-sm btn-outline-danger action-btn" title="Delete" onclick="deleteOption('${t}',${r.id})"><i class="bi bi-trash"></i></button>
            </td></tr>
        `).join('');
    });
    paymentMethods.value = data.payment_methods;
}

async function deleteOption(table, id) {
    const choice = await Swal.fire({
        title: 'Delete option?',
        html: '<div class="swal-info-card text-start">This setting option will be removed from the dropdown list. Existing records using it may keep their saved value.</div>',
        icon: 'warning',
        showCancelButton: true,
        confirmButtonText: 'Delete',
        cancelButtonText: 'Cancel',
        confirmButtonColor: '#ef4444'
    });
    if (!choice.isConfirmed) return;
    const result = await apiPost('../php/settings_action.php', { action: 'delete_option', table, id });
    notify(result.message, result.success ? 'success' : 'error');
    loadSettings();
}

async function updateOption(table, id) {
    const name = document.getElementById(`${table}-${id}`).value;
    const result = await apiPost('../php/settings_action.php', { action: 'update_option', table, id, name });
    notify(result.message, result.success ? 'success' : 'error');
}

document.querySelectorAll('.add-option').forEach(btn => btn.onclick = async () => {
    const table = btn.dataset.table;
    const input = document.querySelector(`.option-input[data-table="${table}"]`);
    const result = await apiPost('../php/settings_action.php', { action: 'add_option', table, name: input.value });
    notify(result.message, result.success ? 'success' : 'error');
    input.value = '';
    loadSettings();
});

saveMethods.onclick = async () => {
    const result = await apiPost('../php/settings_action.php', { action: 'payment_methods', value: paymentMethods.value });
    notify(result.message, result.success ? 'success' : 'error');
};

loadSettings();
