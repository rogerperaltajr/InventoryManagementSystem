<?php
require_once __DIR__ . '/../includes/layout.php';
require_admin();
render_header('Settings', 'settings');
$tabs = [
    'product_categories' => ['Product Categories', 'bi-tags'],
    'units' => ['Units', 'bi-rulers'],
    'suppliers' => ['Suppliers', 'bi-truck'],
    'business_types' => ['Business Types', 'bi-buildings'],
    'brands' => ['Brands', 'bi-award'],
];
?>
<div class="panel">
    <ul class="nav nav-tabs mb-3" id="settingsTabs" role="tablist">
        <?php $first = true; foreach ($tabs as $key => $meta): ?>
            <li class="nav-item" role="presentation">
                <button class="nav-link <?= $first ? 'active' : '' ?>" data-bs-toggle="tab" data-bs-target="#tab-<?= $key ?>" type="button">
                    <i class="bi <?= $meta[1] ?>"></i> <?= $meta[0] ?>
                </button>
            </li>
        <?php $first = false; endforeach; ?>
        <li class="nav-item" role="presentation">
            <button class="nav-link" data-bs-toggle="tab" data-bs-target="#tab-payment" type="button">
                <i class="bi bi-credit-card"></i> Payment Methods
            </button>
        </li>
    </ul>
    <div class="tab-content">
        <?php $first = true; foreach ($tabs as $key => $meta): ?>
            <div class="tab-pane fade <?= $first ? 'show active' : '' ?>" id="tab-<?= $key ?>">
                <div class="row g-3 align-items-end mb-3">
                    <div class="col-md-8">
                        <label class="form-label">Add <?= $meta[0] ?></label>
                        <input class="form-control option-input" data-table="<?= $key ?>" placeholder="Enter option name">
                    </div>
                    <div class="col-md-4">
                        <button class="btn btn-primary w-100 add-option" data-table="<?= $key ?>">Add Option</button>
                    </div>
                </div>
                <div class="table-responsive"><table class="table table-hover"><tbody id="<?= $key ?>Rows"></tbody></table></div>
            </div>
        <?php $first = false; endforeach; ?>
        <div class="tab-pane fade" id="tab-payment">
            <label class="form-label">Payment Methods</label>
            <textarea id="paymentMethods" class="form-control mb-3" rows="5" placeholder="Cash,GCash,Card,Bank Transfer"></textarea>
            <button id="saveMethods" class="btn btn-primary">Save Payment Methods</button>
        </div>
    </div>
</div>
<?php render_footer(['settings.js']); ?>

