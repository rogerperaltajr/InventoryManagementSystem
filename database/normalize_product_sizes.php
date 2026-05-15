<?php
declare(strict_types=1);

require_once __DIR__ . '/../config/db.php';
require_once __DIR__ . '/../includes/product_helpers.php';

$rows = $pdo->query("SELECT p.id, p.product_name, p.product_image_alt, p.product_size_value, p.product_size_unit,
        COALESCE(NULLIF(p.brand,''), b.name) brand_name, u.name unit_name, c.name category_name
    FROM products p
    LEFT JOIN brands b ON b.id=p.brand_id
    LEFT JOIN units u ON u.id=p.unit_id
    LEFT JOIN product_categories c ON c.id=p.category_id")->fetchAll();

$update = $pdo->prepare('UPDATE products
    SET product_name=?, normalized_product_name=?, product_size_value=?, product_size_unit=?, package_type=?
    WHERE id=?');

foreach ($rows as $row) {
    $sourceName = !empty($row['product_image_alt'])
        ? preg_replace('/\s+product image$/i', '', (string)$row['product_image_alt'])
        : (string)$row['product_name'];
    $parts = extract_product_size_parts($sourceName);
    $sizeValue = $parts['size_value'] ?? ($row['product_size_value'] !== null ? (float)$row['product_size_value'] : null);
    $sizeUnit = $parts['size_unit'] ?? ($row['product_size_unit'] ?: null);
    $cleanName = ensure_brand_in_product_display_name(clean_product_display_name($sourceName), (string)($row['brand_name'] ?? ''));
    $packageType = trim((string)($row['unit_name'] ?? ''));
    if (strtolower((string)$row['category_name']) === 'canned goods' || strtolower($packageType) === 'can') {
        $packageType = 'Can';
    } elseif ($packageType !== '') {
        $packageType = ucwords($packageType);
    }
    $update->execute([
        $cleanName,
        normalize_product_name($cleanName),
        $sizeValue,
        $sizeUnit,
        $packageType ?: null,
        (int)$row['id'],
    ]);
}

echo "Product names normalized and sizes separated.\n";
