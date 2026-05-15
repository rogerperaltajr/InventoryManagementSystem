<?php
require_once __DIR__ . '/../includes/layout.php';
require_admin();
render_header('Activity Logs', 'logs');
?>
<div class="panel mb-3">
    <div class="row g-2 align-items-end">
        <div class="col-md-3"><label class="form-label">Search</label><input id="search" class="form-control" placeholder="User or action"></div>
        <div class="col-md-2"><label class="form-label">Date From</label><input id="dateFrom" type="date" class="form-control"></div>
        <div class="col-md-2"><label class="form-label">Date To</label><input id="dateTo" type="date" class="form-control"></div>
        <div class="col-md-2"><label class="form-label">User</label><select id="userFilter" class="form-select"><option value="">All users</option></select></div>
        <div class="col-md-2"><label class="form-label">Action Type</label><select id="actionFilter" class="form-select"><option value="">All actions</option><option>Login</option><option>Logout</option><option>Product</option><option>Sales</option><option>User</option><option>Setting</option></select></div>
        <div class="col-md-1"><button id="filterBtn" class="btn btn-primary w-100"><i class="bi bi-search"></i></button></div>
    </div>
</div>
<div class="panel">
    <div class="table-responsive table-shell"><table class="table table-hover"><thead><tr><th>User</th><th>Action</th><th>Description</th><th>Date & Time</th><th>IP Address</th></tr></thead><tbody id="logRows"></tbody></table></div>
    <div class="d-flex justify-content-between"><span id="pageInfo" class="muted"></span><div><button id="prevPage" class="btn btn-outline-secondary btn-sm">Prev</button> <button id="nextPage" class="btn btn-outline-secondary btn-sm">Next</button></div></div>
</div>
<?php render_footer(['activity_logs.js']); ?>
