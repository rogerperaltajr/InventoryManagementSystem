document.getElementById('registerForm').addEventListener('submit', async e => {
    e.preventDefault();
    const result = await apiPost('../php/register_action.php', new FormData(e.target));
    const box = document.getElementById('registerAlert');
    if (result.success) {
        box.innerHTML = `<div class="alert alert-success">${result.message}</div>`;
        setTimeout(() => location.href = 'login.php', 900);
    } else {
        box.innerHTML = `<div class="alert alert-danger">${result.message}</div>`;
    }
});

