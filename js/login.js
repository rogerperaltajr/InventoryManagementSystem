document.getElementById('loginForm').addEventListener('submit', async e => {
    e.preventDefault();
    const result = await apiPost('../php/login_action.php', new FormData(e.target));
    if (result.success) {
        location.href = result.redirect;
        return;
    }
    document.getElementById('loginAlert').innerHTML = `<div class="alert alert-danger">${result.message}</div>`;
});

