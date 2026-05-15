let page = 1;
const userModal = new bootstrap.Modal(document.getElementById('userModal'));

async function loadUsers() {
    const data = await apiGet(`../php/user_management_action.php?action=list&page=${page}&search=${encodeURIComponent(search.value)}`);
    userStats.innerHTML = [
        ['Total Users', data.stats.total, 'bi-people', 'primary'],
        ['Admins', data.stats.admins, 'bi-shield-lock', 'primary'],
        ['Staff Users', data.stats.users, 'bi-person-badge', 'secondary'],
        ['Active Accounts', data.stats.active, 'bi-person-check', 'success'],
    ].map(s => `<div class="col-md-6 col-xl-3"><div class="summary-card"><div class="summary-icon text-${s[3]}"><i class="bi ${s[2]}"></i></div><div><strong>${s[1]}</strong><span>${s[0]}</span></div></div></div>`).join('');
    userRows.innerHTML = data.rows.map(u => `
        <tr><td>${u.full_name}</td><td>${u.username}</td><td>${u.email}</td><td><span class="badge bg-primary">${u.role}</span></td><td><span class="badge bg-${u.status === 'Active' ? 'success' : 'danger'}">${u.status}</span></td>
        <td>
            <button class="btn btn-sm btn-outline-primary action-btn" title="Edit" onclick='editUser(${JSON.stringify(u)})'><i class="bi bi-pencil"></i></button>
            <button class="btn btn-sm btn-outline-warning action-btn" title="Reset Password" onclick="resetPassword(${u.id})"><i class="bi bi-key"></i></button>
        </td></tr>`).join('') || '<tr><td colspan="6" class="text-center">No users found.</td></tr>';
    pageInfo.textContent = `Page ${data.page} of ${data.pages}`;
    prevPage.disabled = data.page <= 1;
    nextPage.disabled = data.page >= data.pages;
}

function openUserModal() {
    userForm.reset();
    userId.value = '';
    userModalTitle.textContent = 'Add User';
}

function editUser(u) {
    openUserModal();
    userModalTitle.textContent = 'Edit User';
    Object.keys(u).forEach(k => {
        const field = document.querySelector(`[name="${k}"]`);
        if (field) field.value = u[k];
    });
    userModal.show();
}

async function resetPassword(id) {
    const choice = await Swal.fire({
        title: 'Reset Password',
        html: '<div class="swal-info-card text-start mb-3">Enter a temporary password for this user. The password must be at least 6 characters.</div>',
        input: 'password',
        inputPlaceholder: 'New password',
        showCancelButton: true,
        confirmButtonText: 'Reset Password',
        cancelButtonText: 'Cancel',
        confirmButtonColor: '#2563eb',
        inputValidator: value => {
            if (!value) return 'Password is required.';
            if (value.length < 6) return 'Password must be at least 6 characters.';
            return null;
        }
    });
    if (!choice.isConfirmed) return;
    const password = choice.value;
    const result = await apiPost('../php/user_management_action.php', { action: 'reset_password', id, password });
    notify(result.message, result.success ? 'success' : 'error');
}

userForm.addEventListener('submit', async e => {
    e.preventDefault();
    const form = new FormData(e.target);
    form.append('action', userId.value ? 'update' : 'create');
    const result = await apiPost('../php/user_management_action.php', form);
    notify(result.message, result.success ? 'success' : 'error');
    if (result.success) {
        userModal.hide();
        loadUsers();
    }
});

search.oninput = () => { page = 1; loadUsers(); };
prevPage.onclick = () => { page--; loadUsers(); };
nextPage.onclick = () => { page++; loadUsers(); };
loadUsers();
