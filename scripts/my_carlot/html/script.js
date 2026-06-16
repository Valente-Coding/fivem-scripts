/* ===============================================
   CAR LOT NUI - SCRIPT.JS
   Custom FiveM Framework - BareBones
   =============================================== */

let isProcessing = false;
let currentMode = null;

// ===============================================
// UTILITY
// ===============================================

function getResourceName() {
    return window.GetParentResourceName
        ? window.GetParentResourceName()
        : 'my_carlot';
}

function post(endpoint, data) {
    fetch(`https://${getResourceName()}/${endpoint}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data || {})
    });
}

function formatPrice(price) {
    if (typeof price !== 'number') price = 0;
    return '$' + price.toLocaleString('en-US');
}

function formatDate(timestamp) {
    if (!timestamp) return '—';
    const d = new Date(timestamp * 1000);
    return d.toLocaleDateString('en-US', { month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' });
}

function timeSince(timestamp) {
    if (!timestamp) return '';
    const seconds = Math.floor(Date.now() / 1000) - timestamp;
    if (seconds < 60) return 'Just now';
    if (seconds < 3600) return Math.floor(seconds / 60) + 'm ago';
    if (seconds < 86400) return Math.floor(seconds / 3600) + 'h ago';
    return Math.floor(seconds / 86400) + 'd ago';
}

// ===============================================
// SHOW / HIDE PANELS
// ===============================================

function hideAllPanels() {
    document.getElementById('purchase-container').style.display = 'none';
    document.getElementById('confirm-container').style.display = 'none';
    document.getElementById('manage-container').style.display = 'none';
}

function showPanel(id) {
    hideAllPanels();
    const el = document.getElementById(id);
    el.style.display = 'flex';
    el.classList.remove('closing');
}

function closeAll() {
    const containers = document.querySelectorAll('.panel-container');
    containers.forEach(c => c.classList.add('closing'));
    setTimeout(() => {
        hideAllPanels();
        containers.forEach(c => c.classList.remove('closing'));
    }, 200);
    post('close', {});
    isProcessing = false;
    currentMode = null;
}

// ===============================================
// PURCHASE MODE
// ===============================================

function openPurchaseUI(data) {
    currentMode = 'purchase';
    document.getElementById('dealership-name').textContent = data.dealershipName || 'Car Lot';
    document.getElementById('purchase-price').textContent = formatPrice(data.price || 0);

    const statusEl = document.getElementById('purchase-status');
    const btn = document.getElementById('purchase-btn');
    const desc = document.getElementById('purchase-description');

    if (data.owned) {
        statusEl.textContent = 'Owned';
        statusEl.classList.add('status-owned');
        btn.textContent = 'ALREADY OWNED';
        btn.classList.add('owned');
        btn.disabled = true;
        desc.innerHTML = 'You are the proud owner of <strong>' + (data.dealershipName || 'this car lot') + '</strong>.';
    } else {
        statusEl.textContent = 'Available';
        statusEl.classList.remove('status-owned');
        btn.textContent = 'PURCHASE';
        btn.classList.remove('owned', 'loading');
        btn.disabled = false;
        desc.innerHTML = 'Purchase this car lot to sell your vehicles at <strong>90% market value</strong>.';
    }

    isProcessing = false;
    showPanel('purchase-container');
}

function handlePurchase() {
    if (isProcessing) return;
    isProcessing = true;
    const btn = document.getElementById('purchase-btn');
    btn.classList.add('loading');
    btn.textContent = 'PROCESSING...';
    btn.disabled = true;
    post('confirmPurchase', {});
}

// ===============================================
// CONFIRM LISTING MODE
// ===============================================

function openConfirmUI(data) {
    currentMode = 'confirm';
    document.getElementById('confirm-vehicle-name').textContent = data.vehicleName || 'Vehicle';
    document.getElementById('confirm-price').textContent = formatPrice(data.salePrice || 0);
    isProcessing = false;

    // Reset confirm button state from any previous use
    const btn = document.getElementById('confirm-yes-btn');
    btn.classList.remove('loading');
    btn.textContent = 'CONFIRM';
    btn.disabled = false;

    showPanel('confirm-container');
}

function handleConfirmListing() {
    if (isProcessing) return;
    isProcessing = true;
    const btn = document.getElementById('confirm-yes-btn');
    btn.classList.add('loading');
    btn.textContent = 'LISTING...';
    btn.disabled = true;
    post('confirmListing', {});
}

function handleCancelListing() {
    post('cancelListing', {});
    closeAll();
}

// ===============================================
// MANAGEMENT MODE
// ===============================================

function openManageUI(data) {
    currentMode = 'manage';
    renderListings(data.listings || []);
    renderSalesLog(data.salesLog || []);
    updateSummary(data.listings || [], data.salesLog || []);

    // Reset to first tab
    setActiveTab('listings');
    showPanel('manage-container');
}

function renderListings(listings) {
    const container = document.getElementById('listings-list');

    if (!listings.length) {
        container.innerHTML = '<div class="empty-state">No vehicles listed for sale.</div>';
        return;
    }

    let html = '';
    for (const item of listings) {
        html += `
            <div class="list-item">
                <div class="list-item-info">
                    <span class="list-item-name">${escapeHtml(item.label || item.model)}</span>
                    <span class="list-item-detail">${escapeHtml(item.plate)} &bull; ${timeSince(item.listed_at)}</span>
                </div>
                <div class="list-item-right">
                    <span class="list-item-price">${formatPrice(item.price)}</span>
                    <button class="remove-btn" data-id="${item.id}">REMOVE</button>
                </div>
            </div>
        `;
    }
    container.innerHTML = html;

    // Attach remove handlers
    container.querySelectorAll('.remove-btn').forEach(btn => {
        btn.addEventListener('click', () => {
            const id = parseInt(btn.dataset.id);
            if (id) {
                btn.textContent = '...';
                btn.disabled = true;
                post('removeListing', { id: id });
            }
        });
    });
}

function renderSalesLog(sales) {
    const container = document.getElementById('sales-list');

    if (!sales.length) {
        container.innerHTML = '<div class="empty-state">No sales yet.</div>';
        return;
    }

    // Show most recent first
    const sorted = [...sales].sort((a, b) => (b.sold_at || 0) - (a.sold_at || 0));

    let html = '';
    for (const sale of sorted) {
        html += `
            <div class="list-item sale-item">
                <div class="list-item-info">
                    <span class="list-item-name">${escapeHtml(sale.label || sale.model)}</span>
                    <span class="list-item-detail">Sold to ${escapeHtml(sale.buyerName)} &bull; ${formatDate(sale.sold_at)}</span>
                </div>
                <div class="list-item-right">
                    <span class="list-item-price sale-price">${formatPrice(sale.price)}</span>
                </div>
            </div>
        `;
    }
    container.innerHTML = html;
}

function updateSummary(listings, sales) {
    document.getElementById('summary-listed').textContent = listings.length;
    const totalEarned = sales.reduce((sum, s) => sum + (s.price || 0), 0);
    document.getElementById('summary-earned').textContent = formatPrice(totalEarned);
}

function escapeHtml(str) {
    if (!str) return '';
    const div = document.createElement('div');
    div.textContent = str;
    return div.innerHTML;
}

// ===============================================
// TABS
// ===============================================

function setActiveTab(tabName) {
    document.querySelectorAll('.tab-btn').forEach(btn => {
        btn.classList.toggle('active', btn.dataset.tab === tabName);
    });
    document.querySelectorAll('.tab-panel').forEach(panel => {
        panel.classList.toggle('active', panel.id === 'tab-' + tabName);
    });
}

// ===============================================
// FEEDBACK
// ===============================================

function showFeedback(message, isSuccess) {
    const el = document.getElementById('feedback-message');
    el.textContent = message;
    el.className = 'feedback-message ' + (isSuccess ? 'success' : 'error');
    el.style.display = 'block';
    setTimeout(() => {
        el.classList.add('closing');
        setTimeout(() => {
            el.style.display = 'none';
            el.classList.remove('closing');
        }, 300);
    }, isSuccess ? 3000 : 5000);
}

// ===============================================
// EVENT LISTENERS
// ===============================================

window.addEventListener('message', (event) => {
    const data = event.data;

    switch (data.action) {
        case 'open':
            hideFeedback();
            if (data.mode === 'purchase') openPurchaseUI(data);
            else if (data.mode === 'confirm') openConfirmUI(data);
            else if (data.mode === 'manage') openManageUI(data);
            break;

        case 'close':
            closeAll();
            break;

        case 'error':
            showFeedback(data.message || 'An error occurred', false);
            isProcessing = false;
            break;
    }
});

function hideFeedback() {
    const el = document.getElementById('feedback-message');
    el.style.display = 'none';
    el.classList.remove('closing');
}

document.addEventListener('DOMContentLoaded', () => {
    // Close buttons
    document.getElementById('purchase-close-btn').addEventListener('click', closeAll);
    document.getElementById('confirm-close-btn').addEventListener('click', closeAll);
    document.getElementById('manage-close-btn').addEventListener('click', closeAll);

    // Purchase
    document.getElementById('purchase-btn').addEventListener('click', handlePurchase);

    // Confirm listing
    document.getElementById('confirm-yes-btn').addEventListener('click', handleConfirmListing);
    document.getElementById('confirm-cancel-btn').addEventListener('click', handleCancelListing);

    // Tabs
    document.querySelectorAll('.tab-btn').forEach(btn => {
        btn.addEventListener('click', () => setActiveTab(btn.dataset.tab));
    });
});

document.addEventListener('keyup', (event) => {
    if (event.key === 'Escape') {
        closeAll();
    }
});

// ===============================================
// DEBUG
// ===============================================

if (!window.GetParentResourceName) {
    console.log('[CarLot] Browser debug mode');
    setTimeout(() => {
        openManageUI({
            listings: [
                { id: 1, label: 'Karin Sultan', model: 'sultan', plate: 'ABC123', price: 22500, listed_at: Math.floor(Date.now()/1000) - 3600 },
                { id: 2, label: 'Declasse Vigero', model: 'vigero', plate: 'XYZ789', price: 18000, listed_at: Math.floor(Date.now()/1000) - 86400 }
            ],
            salesLog: [
                { label: 'Vapid Dominator', model: 'dominator', price: 31500, buyerName: 'John Smith', sold_at: Math.floor(Date.now()/1000) - 7200 }
            ]
        });
    }, 500);
}
