<?php
declare(strict_types=1);

require_once __DIR__ . '/../config/db.php';
require_once __DIR__ . '/../includes/product_helpers.php';

$rows = $pdo->query("SELECT id, product_name, normalized_product_name, category_id, business_type_id, unit_id,
        product_size_value, product_size_unit, package_type, quantity, stock_quantity, selling_price, cost_price,
        created_at
    FROM products
    ORDER BY id")->fetchAll();

$groups = [];
foreach ($rows as $row) {
    $nameKey = normalize_product_name((string)($row['product_name'] ?? ''));
    $sizeValue = $row['product_size_value'] === null ? '' : number_format((float)$row['product_size_value'], 2, '.', '');
    $key = implode('|', [
        $nameKey,
        (string)($row['category_id'] ?? ''),
        (string)($row['business_type_id'] ?? ''),
        (string)($row['unit_id'] ?? ''),
        $sizeValue,
        strtolower((string)($row['product_size_unit'] ?? '')),
        strtolower((string)($row['package_type'] ?? '')),
    ]);
    $groups[$key][] = $row;
}

$pdo->beginTransaction();
$deleted = 0;
$mergedGroups = 0;

foreach ($groups as $items) {
    if (count($items) < 2) {
        continue;
    }

    $master = $items[0];
    $duplicates = array_slice($items, 1);
    $duplicateIds = array_map(static fn(array $item): int => (int)$item['id'], $duplicates);
    $masterId = (int)$master['id'];
    $totalQuantity = array_sum(array_map(static fn(array $item): int => (int)$item['quantity'], $items));
    $totalStock = array_sum(array_map(static fn(array $item): int => (int)($item['stock_quantity'] ?? $item['quantity']), $items));

    $pdo->prepare('UPDATE sale_items SET product_id=? WHERE product_id IN (' . implode(',', array_fill(0, count($duplicateIds), '?')) . ')')
        ->execute(array_merge([$masterId], $duplicateIds));
    $pdo->prepare('UPDATE product_approvals SET product_id=? WHERE product_id IN (' . implode(',', array_fill(0, count($duplicateIds), '?')) . ')')
        ->execute(array_merge([$masterId], $duplicateIds));
    $pdo->prepare('UPDATE product_duplicate_actions SET product_id=? WHERE product_id IN (' . implode(',', array_fill(0, count($duplicateIds), '?')) . ')')
        ->execute(array_merge([$masterId], $duplicateIds));
    $pdo->prepare('UPDATE product_duplicate_actions SET duplicate_reference_id=? WHERE duplicate_reference_id IN (' . implode(',', array_fill(0, count($duplicateIds), '?')) . ')')
        ->execute(array_merge([$masterId], $duplicateIds));

    $pdo->prepare('UPDATE products
        SET quantity=?, stock_quantity=?, duplicate_status="None", duplicate_reference_id=NULL, duplicate_notes=NULL
        WHERE id=?')->execute([$totalQuantity, $totalStock, $masterId]);

    $pdo->prepare('DELETE FROM products WHERE id IN (' . implode(',', array_fill(0, count($duplicateIds), '?')) . ')')
        ->execute($duplicateIds);

    $deleted += count($duplicateIds);
    $mergedGroups++;
}

$pdo->commit();

echo "Duplicate cleanup completed.\n";
echo "Groups merged: {$mergedGroups}\n";
echo "Duplicate rows removed: {$deleted}\n";
