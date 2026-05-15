<?php
require_once __DIR__ . '/../includes/layout.php';
require_admin();
render_header('User Management', 'users');
?>
<div class="row g-3 mb-3" id="userStats"></div>
<div class="panel mb-3">
    <div class="row g-2 align-items-end">
        <div class="col-md-5"><label class="form-label">Search</label><input id="search" class="form-control" placeholder="Name, username, email"></div>
        <div class="col-md-7 text-md-end"><button class="btn btn-primary" data-bs-toggle="modal" data-bs-target="#userModal" onclick="openUserModal()"><i class="bi bi-person-plus"></i> Add User</button></div>
    </div>
</div>
<div class="panel">
    <div class="table-responsive table-shell"><table class="table table-hover align-middle"><thead><tr><th>Name</th><th>Username</th><th>Email</th><th>Role</th><th>Status</th><th>Actions</th></tr></thead><tbody id="userRows"></tbody></table></div>
    <div class="d-flex justify-content-between"><span id="pageInfo" class="muted"></span><div><button id="prevPage" class="btn btn-outline-secondary btn-sm">Prev</button> <button id="nextPage" class="btn btn-outline-secondary btn-sm">Next</button></div></div>
</div>
<div class="modal fade" id="userModal" tabindex="-1">
    <div class="modal-dialog modal-lg">
        <form class="modal-content app-modal" id="userForm">
            <div class="modal-header app-modal-header">
                <div>
                    <span class="modal-kicker">Account access</span>
                    <h5 id="userModalTitle" class="modal-title">Add User</h5>
                </div>
                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
            </div>
            <div class="modal-body app-modal-body">
                <input type="hidden" name="id" id="userId">
                <div class="modal-section">
                    <div class="modal-section-title"><i class="bi bi-person-vcard"></i><span>Profile Information</span></div>
                    <div class="row g-3">
                        <div class="col-md-6"><label class="form-label">Full Name</label><input class="form-control" name="full_name" required></div>
                        <div class="col-md-6"><label class="form-label">Username</label><input class="form-control" name="username" required></div>
                        <div class="col-12"><label class="form-label">Email</label><input class="form-control" type="email" name="email" required></div>
                    </div>
                </div>
                <div class="modal-section">
                    <div class="modal-section-title"><i class="bi bi-shield-lock"></i><span>Permissions & Security</span></div>
                    <div class="row g-3">
                        <div class="col-md-4"><label class="form-label">Role</label><select class="form-select" name="role"><option>User</option><option>Admin</option></select></div>
                        <div class="col-md-4"><label class="form-label">Status</label><select class="form-select" name="status"><option>Active</option><option>Inactive</option></select></div>
                        <div class="col-md-4"><label class="form-label">Password</label><input class="form-control" type="password" name="password" placeholder="Blank keeps current"></div>
                    </div>
                    <p class="modal-help mb-0 mt-2">Password is required for new users. For existing users, leave it blank to keep the current password.</p>
                </div>
            </div>
            <div class="modal-footer app-modal-footer"><button type="button" class="btn btn-outline-secondary" data-bs-dismiss="modal">Cancel</button><button class="btn btn-success"><i class="bi bi-check2-circle"></i> Save User</button></div>
        </form>
    </div>
</div>
<?php render_footer(['user_management.js']); ?>
