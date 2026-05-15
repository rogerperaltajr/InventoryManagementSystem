const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content || '';

document.getElementById('sidebarToggle')?.addEventListener('click', () => {
    document.querySelector('.sidebar')?.classList.toggle('open');
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

