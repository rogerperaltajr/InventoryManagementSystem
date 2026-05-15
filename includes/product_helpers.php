<?php
declare(strict_types=1);

function normalize_product_name(string $name): string
{
    $name = strtolower(trim($name));
    $replacements = [
        '/\bpcs\b/' => ' pieces ',
        '/\bpc\b/' => ' piece ',
        '/\bml\b/' => ' milliliter ',
        '/\bl\b/' => ' liter ',
        '/\bkg\b/' => ' kilogram ',
        '/\bg\b/' => ' gram ',
        '/\bchili[\s-]*mansi\b/' => ' chilimansi ',
        '/\bkalamansi\b/' => ' calamansi ',
    ];
    foreach ($replacements as $pattern => $replacement) {
        $name = preg_replace($pattern, $replacement, $name);
    }
    $name = preg_replace('/[^a-z0-9]+/', ' ', $name);
    $name = preg_replace('/\s+/', ' ', $name);
    return trim($name ?? '');
}

function extract_product_size_parts(string $name): array
{
    $cleanName = trim($name);
    $sizeValue = null;
    $sizeUnit = null;
    if (preg_match('/\b(\d+(?:\.\d+)?)\s*(kg|g|ml|l)\b/i', $cleanName, $match)) {
        $sizeValue = (float)$match[1];
        $unit = strtolower($match[2]);
        $sizeUnit = $unit === 'l' ? 'L' : $unit;
        $cleanName = preg_replace('/\b\d+(?:\.\d+)?\s*(kg|g|ml|l)\b/i', '', $cleanName, 1);
    }
    $cleanName = preg_replace('/\b(Small|Regular|Family|Promo|Bundle)\s+Pack\s+\d+\b/i', '', $cleanName);
    $cleanName = trim(preg_replace('/\s+/', ' ', $cleanName ?? ''));
    return [
        'name' => $cleanName ?: trim($name),
        'size_value' => $sizeValue,
        'size_unit' => $sizeUnit,
    ];
}

function clean_product_display_name(string $name): string
{
    $name = trim($name);
    $name = preg_replace('/\s+product image$/i', '', $name);
    $parts = extract_product_size_parts((string)$name);
    $cleanName = preg_replace('/\b(Small|Regular|Family|Promo|Bundle)\s+Pack\b/i', '', $parts['name']);
    $cleanName = preg_replace('/\s+\d+\b$/', '', (string)$cleanName);
    $cleanName = trim(preg_replace('/\s+/', ' ', (string)$cleanName));
    return $cleanName !== '' ? $cleanName : trim($name);
}

function strip_brand_from_product_name(string $name, ?string $brand): string
{
    $name = trim($name);
    $brand = trim((string)$brand);
    if ($name === '' || $brand === '') {
        return $name;
    }
    $pattern = '/^' . preg_quote($brand, '/') . '\b[\s\-:]*/i';
    $clean = trim(preg_replace($pattern, '', $name, 1) ?? $name);
    return $clean !== '' ? $clean : $name;
}

function ensure_brand_in_product_display_name(string $name, ?string $brand): string
{
    $name = trim($name);
    $brand = trim((string)$brand);
    if ($name === '' || $brand === '') {
        return $name;
    }

    $normalizedName = normalize_product_name($name);
    $normalizedBrand = normalize_product_name($brand);
    if ($normalizedBrand !== '' && (str_starts_with($normalizedName, $normalizedBrand) || str_contains($normalizedName, $normalizedBrand))) {
        return $name;
    }

    return trim($brand . ' ' . $name);
}

function find_duplicate_products(PDO $pdo, array $product, int $excludeId = 0): array
{
    $barcode = trim((string)($product['barcode'] ?? ''));
    $name = trim((string)($product['product_name'] ?? ''));
    $normalized = normalize_product_name($name);
    $brand = trim((string)($product['brand'] ?? ''));
    $brandId = (int)($product['brand_id'] ?? 0);
    $categoryId = (int)($product['category_id'] ?? 0);
    $unitId = (int)($product['unit_id'] ?? 0);
    $businessTypeId = (int)($product['business_type_id'] ?? 0);

    $matches = [];
    $seen = [];
    $baseSelect = "SELECT p.*, c.name category, COALESCE(NULLIF(p.brand,''), br.name) brand_name, u.name unit, bt.name business_type
        FROM products p
        LEFT JOIN product_categories c ON c.id=p.category_id
        LEFT JOIN brands br ON br.id=p.brand_id
        LEFT JOIN units u ON u.id=p.unit_id
        LEFT JOIN business_types bt ON bt.id=p.business_type_id
        WHERE p.id <> ?";

    $addMatch = function (array $row, string $type, string $reason, int $score) use (&$matches, &$seen): void {
        $id = (int)$row['id'];
        if (isset($seen[$id])) {
            if ($score > $matches[$seen[$id]]['score']) {
                $matches[$seen[$id]]['type'] = $type;
                $matches[$seen[$id]]['reason'] = $reason;
                $matches[$seen[$id]]['score'] = $score;
            }
            return;
        }
        $seen[$id] = count($matches);
        $matches[] = [
            'id' => $id,
            'product_name' => $row['product_name'],
            'barcode' => $row['barcode'],
            'brand' => $row['brand_name'] ?? '',
            'category' => $row['category'] ?? '',
            'unit' => $row['unit'] ?? '',
            'business_type' => $row['business_type'] ?? '',
            'selling_price' => $row['selling_price'],
            'quantity' => $row['quantity'],
            'type' => $type,
            'reason' => $reason,
            'score' => $score,
        ];
    };

    if ($barcode !== '') {
        $stmt = $pdo->prepare("$baseSelect AND p.barcode = ? LIMIT 1");
        $stmt->execute([$excludeId, $barcode]);
        if ($row = $stmt->fetch()) {
            $addMatch($row, 'Exact Duplicate', 'Barcode already exists.', 100);
        }
    }

    if ($normalized !== '') {
        $stmt = $pdo->prepare("$baseSelect AND p.normalized_product_name = ? LIMIT 5");
        $stmt->execute([$excludeId, $normalized]);
        while ($row = $stmt->fetch()) {
            $addMatch($row, 'Possible Duplicate', 'Product name is very similar.', 92);
        }

        if ($brandId || $brand !== '' || $unitId) {
            $stmt = $pdo->prepare("$baseSelect AND p.unit_id <=> ? AND (p.brand_id <=> ? OR LOWER(COALESCE(p.brand,'')) = LOWER(?)) AND p.normalized_product_name = ? LIMIT 5");
            $stmt->execute([$excludeId, $unitId ?: null, $brandId ?: null, $brand, $normalized]);
            while ($row = $stmt->fetch()) {
                $addMatch($row, 'Possible Duplicate', 'Product name, brand, and unit already exist.', 95);
            }
        }

        if ($categoryId && $businessTypeId) {
            $stmt = $pdo->prepare("$baseSelect AND p.category_id = ? AND p.business_type_id = ? AND p.normalized_product_name = ? LIMIT 5");
            $stmt->execute([$excludeId, $categoryId, $businessTypeId, $normalized]);
            while ($row = $stmt->fetch()) {
                $addMatch($row, 'Possible Duplicate', 'Product name, category, and business type already exist.', 90);
            }
        }

        $needle = '%' . substr($normalized, 0, min(18, strlen($normalized))) . '%';
        $stmt = $pdo->prepare("$baseSelect AND p.normalized_product_name LIKE ? LIMIT 20");
        $stmt->execute([$excludeId, $needle]);
        while ($row = $stmt->fetch()) {
            $existing = (string)($row['normalized_product_name'] ?? normalize_product_name($row['product_name']));
            similar_text($normalized, $existing, $percent);
            if ($percent >= 82 || str_contains($existing, $normalized) || str_contains($normalized, $existing)) {
                $addMatch($row, 'Possible Duplicate', 'Product name is very similar to an existing product.', (int)$percent);
            }
        }
    }

    usort($matches, fn($a, $b) => $b['score'] <=> $a['score']);
    return array_slice($matches, 0, 8);
}

function duplicate_status_from_matches(array $matches): string
{
    foreach ($matches as $match) {
        if ($match['type'] === 'Exact Duplicate') {
            return 'Exact Duplicate';
        }
    }
    return $matches ? 'Possible Duplicate' : 'None';
}

function log_duplicate_action(PDO $pdo, ?int $productId, ?int $referenceId, string $action, string $details = ''): void
{
    $stmt = $pdo->prepare('INSERT INTO product_duplicate_actions (product_id, duplicate_reference_id, action_taken, details, user_id) VALUES (?, ?, ?, ?, ?)');
    $stmt->execute([$productId, $referenceId, $action, $details, current_user()['id'] ?? null]);
}
