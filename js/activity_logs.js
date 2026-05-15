let page = 1;

async function loadLogs() {
    const params = new URLSearchParams({ action: 'list', page, search: search.value, from: dateFrom.value, to: dateTo.value, user_id: userFilter.value, action_type: actionFilter.value });
    const data = await apiGet(`../php/activity_logs_action.php?${params}`);
    if (userFilter.options.length <= 1) {
        userFilter.innerHTML += data.users.map(u => `<option value="${u.id}">${u.full_name}</option>`).join('');
    }
    logRows.innerHTML = data.rows.map(r => {
        const type = r.action.includes('Login') ? 'success' : r.action.includes('Logout') ? 'secondary' : r.action.includes('Rejected') ? 'danger' : r.action.includes('Product') ? 'primary' : r.action.includes('Sales') ? 'warning' : 'primary';
        return `<tr><td>${r.full_name || 'System'}</td><td><span class="badge bg-${type}">${r.action.split(' ')[0]}</span></td><td>${r.action}</td><td>${r.date_time}</td><td>${r.ip_address || ''}</td></tr>`;
    }).join('') || '<tr><td colspan="5" class="text-center">No logs found.</td></tr>';
    pageInfo.textContent = `Page ${data.page} of ${data.pages}`;
    prevPage.disabled = data.page <= 1;
    nextPage.disabled = data.page >= data.pages;
}

filterBtn.onclick = () => { page = 1; loadLogs(); };
search.oninput = () => { page = 1; loadLogs(); };
userFilter.onchange = () => { page = 1; loadLogs(); };
actionFilter.onchange = () => { page = 1; loadLogs(); };
prevPage.onclick = () => { page--; loadLogs(); };
nextPage.onclick = () => { page++; loadLogs(); };
loadLogs();
