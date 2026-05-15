<?php

function ensure_sales_buyer_column(PDO $pdo): void
{
    static $checked = false;
    if ($checked) return;

    $column = $pdo->query("SHOW COLUMNS FROM sales LIKE 'buyer_name'")->fetch();
    if (!$column) {
        $pdo->exec("ALTER TABLE sales ADD COLUMN buyer_name VARCHAR(120) NULL AFTER invoice_no");
    }
    $checked = true;
}

function sale_buyer_label(array $sale): string
{
    $buyerName = trim((string)($sale['buyer_name'] ?? ''));
    return $buyerName !== '' ? $buyerName : 'Buyer ' . (int)$sale['id'];
}
