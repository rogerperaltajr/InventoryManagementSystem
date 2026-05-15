<?php
require_once __DIR__ . '/../includes/auth.php';
require_action_admin();

$allowed = ['product_categories', 'units', 'suppliers', 'business_types', 'brands'];
$action = $_POST['action'] ?? $_GET['action'] ?? '';

if ($action === 'list') {
    $data = [];
    foreach ($allowed as $table) {
        $data[$table] = $pdo->query("SELECT id, name FROM $table ORDER BY name")->fetchAll();
    }
    $data['payment_methods'] = $pdo->query("SELECT setting_value FROM settings WHERE setting_key='payment_methods'")->fetchColumn() ?: '';
    json_response($data);
}

verify_csrf();

$table = $_POST['table'] ?? '';
if (in_array($action, ['add_option', 'update_option', 'delete_option'], true) && !in_array($table, $allowed, true)) {
    json_response(['success' => false, 'message' => 'Invalid option type.']);
}

if ($action === 'add_option') {
    $name = clean($_POST['name'] ?? '');
    if ($name === '') json_response(['success' => false, 'message' => 'Name is required.']);
    try {
        $stmt = $pdo->prepare("INSERT INTO $table (name) VALUES (?)");
        $stmt->execute([$name]);
        log_activity($pdo, 'Setting option added');
        json_response(['success' => true, 'message' => 'Option added.']);
    } catch (PDOException $e) {
        json_response(['success' => false, 'message' => 'Option already exists.']);
    }
}

if ($action === 'update_option') {
    $name = clean($_POST['name'] ?? '');
    $stmt = $pdo->prepare("UPDATE $table SET name=? WHERE id=?");
    $stmt->execute([$name, (int)$_POST['id']]);
    log_activity($pdo, 'Setting option updated');
    json_response(['success' => true, 'message' => 'Option updated.']);
}

if ($action === 'delete_option') {
    try {
        $stmt = $pdo->prepare("DELETE FROM $table WHERE id=?");
        $stmt->execute([(int)$_POST['id']]);
        log_activity($pdo, 'Setting option deleted');
        json_response(['success' => true, 'message' => 'Option deleted.']);
    } catch (PDOException $e) {
        json_response(['success' => false, 'message' => 'This option is in use and cannot be deleted.']);
    }
}

if ($action === 'payment_methods') {
    $value = clean($_POST['value'] ?? 'Cash');
    $stmt = $pdo->prepare("INSERT INTO settings (setting_key, setting_value) VALUES ('payment_methods', ?) ON DUPLICATE KEY UPDATE setting_value=VALUES(setting_value)");
    $stmt->execute([$value]);
    log_activity($pdo, 'Payment methods updated');
    json_response(['success' => true, 'message' => 'Payment methods saved.']);
}

json_response(['success' => false, 'message' => 'Invalid action.']);
