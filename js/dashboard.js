let salesChart;
let soldChart;

async function loadDashboard() {
    const data = await apiGet('../php/dashboard_action.php?action=summary');
    const metrics = [
        ['Products', data.total_products, 'bi-box-seam', 'blue'],
        ['Sales Today', `PHP ${money(data.sales_today)}`, 'bi-cash-stack', 'green'],
        ['This Month', `PHP ${money(data.sales_month)}`, 'bi-graph-up-arrow', 'blue'],
        ['Low Stock', data.low_stock, 'bi-exclamation-triangle', 'orange'],
        ['Out of Stock', data.out_stock, 'bi-x-octagon', 'red'],
        ['Pending', data.pending, 'bi-hourglass-split', 'gray'],
    ];

    document.getElementById('metrics').innerHTML = metrics.map(metric => `
        <div class="dashboard-metric ${metric[3]}">
            <span class="dashboard-metric-icon"><i class="bi ${metric[2]}"></i></span>
            <div>
                <small>${metric[0]}</small>
                <strong>${metric[1]}</strong>
            </div>
        </div>
    `).join('');

    salesChart?.destroy();
    salesChart = new Chart(document.getElementById('salesChart'), {
        type: 'line',
        data: {
            labels: data.daily_sales.map(row => row.day.slice(5)),
            datasets: [{
                data: data.daily_sales.map(row => row.total),
                borderColor: '#2563eb',
                backgroundColor: 'rgba(37, 99, 235, .12)',
                fill: true,
                tension: .35,
                pointRadius: 3,
                pointBackgroundColor: '#2563eb',
            }],
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            animation: false,
            resizeDelay: 0,
            plugins: { legend: { display: false } },
            scales: {
                x: { grid: { display: false }, ticks: { color: '#64748b', font: { size: 11 } } },
                y: { grid: { color: '#eef2f7' }, ticks: { color: '#64748b', font: { size: 11 } } },
            },
        },
    });

    soldChart?.destroy();
    soldChart = new Chart(document.getElementById('soldChart'), {
        type: 'doughnut',
        data: {
            labels: ['Sold', 'Not Sold'],
            datasets: [{
                data: [data.sold_count, data.not_sold_count],
                backgroundColor: ['#2563eb', '#f59e0b'],
                borderWidth: 0,
                cutout: '68%',
            }],
        },
        options: {
            maintainAspectRatio: false,
            plugins: { legend: { display: false } },
        },
    });

    document.getElementById('stockHealth').innerHTML = `
        <div class="stock-health-item"><span>Sold products</span><strong>${data.sold_count}</strong></div>
        <div class="stock-health-item"><span>Not sold</span><strong>${data.not_sold_count}</strong></div>
        <div class="stock-health-item warning"><span>Watch item</span><strong>${data.least_sold || 'None'}</strong></div>
    `;

    document.getElementById('topProducts').innerHTML = data.top_products.map(product => `
        <article class="dashboard-list-item">
            <div class="list-thumb">
                ${product.image_path ? `<img src="../${product.image_path}" alt="${product.product_name}">` : '<i class="bi bi-bag-check"></i>'}
            </div>
            <div>
                <strong>${product.product_name}</strong>
                <span>${product.qty} sold · ${product.quantity} left</span>
            </div>
            <b>PHP ${money(product.revenue)}</b>
        </article>
    `).join('') || '<div class="empty-state">No sales yet.</div>';

    document.getElementById('recentLogs').innerHTML = data.logs.map(log => `
        <article class="activity-item">
            <span class="activity-dot"></span>
            <div><strong>${log.action}</strong><span>${log.full_name || 'System'} · ${log.created_at}</span></div>
        </article>
    `).join('') || '<div class="empty-state">No recent activity.</div>';
}

loadDashboard();
