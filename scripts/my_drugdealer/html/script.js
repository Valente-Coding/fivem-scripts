const container = document.getElementById('dealer-container');
const itemGrid = document.getElementById('dealer-items');
const levelEl = document.getElementById('player-level');
const expBar = document.getElementById('exp-bar');
const expText = document.getElementById('exp-text');
const dirtyEl = document.getElementById('dirty-money');
const bulkPanel = document.getElementById('bulk-buy-panel');
const bulkQuantityInput = document.getElementById('bulk-quantity');
const bulkTotalCost = document.getElementById('bulk-total-cost');

let currentItems = [];
let currentFilter = 'all';
let playerLevel = 1;
let maxLevel = 5;
let largeDrugPrices = { weed: 0, cocaine: 0, meth: 0 };

window.addEventListener('message', (event) => {
    const d = event.data;

    if (d.action === 'open') {
        currentItems = d.items || [];
        playerLevel = d.playerLevel || 1;
        maxLevel = d.maxLevel || 5;
        
        // Extract large drug prices
        const largeWeed = currentItems.find(i => i.name === 'large_weed');
        const largeCocaine = currentItems.find(i => i.name === 'large_cocaine');
        const largeMeth = currentItems.find(i => i.name === 'large_meth');
        
        if (largeWeed) largeDrugPrices.weed = largeWeed.price;
        if (largeCocaine) largeDrugPrices.cocaine = largeCocaine.price;
        if (largeMeth) largeDrugPrices.meth = largeMeth.price;
        
        updateReputation(d.playerLevel, d.playerExp, d.maxExp);
        dirtyEl.textContent = (d.dirtyMoney || 0).toLocaleString();
        renderItems();
        updateBulkPanel();
        container.style.display = 'flex';

    } else if (d.action === 'updateData') {
        updateReputation(d.playerLevel, d.playerExp, d.maxExp);
        if (d.dirtyMoney !== undefined) {
            dirtyEl.textContent = d.dirtyMoney.toLocaleString();
        }
        playerLevel = d.playerLevel || playerLevel;
        updateBulkPanel();

    } else if (d.action === 'levelUp') {
        const badge = document.querySelector('.level-badge');
        badge.classList.add('level-up');
        setTimeout(() => badge.classList.remove('level-up'), 1000);
        renderItems();
        updateBulkPanel();

    } else if (d.action === 'close') {
        container.style.display = 'none';
        bulkPanel.style.display = 'none';
    }
});

function updateBulkPanel() {
    if (playerLevel >= 5) {
        bulkPanel.style.display = 'flex';
        updateBulkTotal();
    } else {
        bulkPanel.style.display = 'none';
    }
}

function updateBulkTotal() {
    const qty = parseInt(bulkQuantityInput.value) || 1;
    document.getElementById('bulk-weed-qty').textContent = qty;
    document.getElementById('bulk-cocaine-qty').textContent = qty;
    document.getElementById('bulk-meth-qty').textContent = qty;
    
    const total = (largeDrugPrices.weed + largeDrugPrices.cocaine + largeDrugPrices.meth) * qty;
    bulkTotalCost.textContent = '$' + total.toLocaleString();
}

function updateReputation(level, exp, maxExp) {
    levelEl.textContent = level;
    if (level >= maxLevel) {
        expBar.style.width = '100%';
        expText.textContent = 'MAX LEVEL';
    } else {
        const pct = maxExp > 0 ? Math.min((exp / maxExp) * 100, 100) : 0;
        expBar.style.width = pct + '%';
        expText.textContent = exp + ' / ' + maxExp;
    }
}

function getIcon(name) {
    if (name.includes('weed')) return 'fas fa-cannabis';
    if (name.includes('cocaine')) return 'fas fa-pills';
    if (name.includes('meth')) return 'fas fa-vial';
    return 'fas fa-box';
}

function getDrugClass(name) {
    if (name.includes('weed')) return 'weed';
    if (name.includes('cocaine')) return 'cocaine';
    if (name.includes('meth')) return 'meth';
    return '';
}

function renderItems() {
    itemGrid.innerHTML = '';

    currentItems.forEach(item => {
        if (currentFilter !== 'all' && !item.name.includes(currentFilter)) return;

        const locked = playerLevel < item.requiredLevel;
        const card = document.createElement('div');
        card.className = 'item ' + getDrugClass(item.name) + (locked ? ' locked' : '');

        card.innerHTML = `
            <div class="item-icon"><i class="${getIcon(item.name)}"></i></div>
            <div class="item-info">
                <h3 class="item-name">${item.label}</h3>
                <p class="item-description">${item.description || ''}</p>
                <div class="item-level">
                    <i class="fas fa-star"></i>
                    <span>Level ${item.requiredLevel}${locked ? ' (Locked)' : ''}</span>
                </div>
            </div>
            <div class="item-price">$${item.price.toLocaleString()}</div>
            <div class="item-buy">
                <div class="item-quantity">
                    <button class="quantity-btn minus-btn"><i class="fas fa-minus"></i></button>
                    <input type="number" class="quantity-input" value="1" min="1" max="100" ${locked ? 'disabled' : ''}>
                    <button class="quantity-btn plus-btn"><i class="fas fa-plus"></i></button>
                </div>
                <button class="buy-btn" ${locked ? 'disabled' : ''}>BUY</button>
            </div>
        `;

        const qtyInput = card.querySelector('.quantity-input');
        const priceEl = card.querySelector('.item-price');

        card.querySelector('.minus-btn').addEventListener('click', () => {
            let v = parseInt(qtyInput.value);
            if (v > 1) { qtyInput.value = v - 1; priceEl.textContent = '$' + (item.price * (v - 1)).toLocaleString(); }
        });

        card.querySelector('.plus-btn').addEventListener('click', () => {
            let v = parseInt(qtyInput.value);
            if (v < 100) { qtyInput.value = v + 1; priceEl.textContent = '$' + (item.price * (v + 1)).toLocaleString(); }
        });

        qtyInput.addEventListener('change', () => {
            let v = parseInt(qtyInput.value);
            if (isNaN(v) || v < 1) v = 1;
            if (v > 100) v = 100;
            qtyInput.value = v;
            priceEl.textContent = '$' + (item.price * v).toLocaleString();
        });

        card.querySelector('.buy-btn').addEventListener('click', () => {
            if (locked) return;
            let qty = parseInt(qtyInput.value) || 1;
            if (qty < 1) qty = 1;
            if (qty > 100) qty = 100;
            fetch(`https://${GetParentResourceName()}/buyItem`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ name: item.name, quantity: qty })
            });
        });

        itemGrid.appendChild(card);
    });
}

// Tab switching
document.querySelectorAll('.tab').forEach(tab => {
    tab.addEventListener('click', () => {
        document.querySelectorAll('.tab').forEach(t => t.classList.remove('active'));
        tab.classList.add('active');
        currentFilter = tab.dataset.tab;
        renderItems();
    });
});

// Close button
document.getElementById('close-menu').addEventListener('click', () => {
    container.style.display = 'none';
    bulkPanel.style.display = 'none';
    fetch(`https://${GetParentResourceName()}/close`, {
        method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({})
    });
});

// Escape key
document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
        container.style.display = 'none';
        bulkPanel.style.display = 'none';
        fetch(`https://${GetParentResourceName()}/close`, {
            method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({})
        });
    }
});

// Bulk buy panel controls
document.getElementById('bulk-qty-minus').addEventListener('click', () => {
    let val = parseInt(bulkQuantityInput.value) || 1;
    if (val > 1) {
        bulkQuantityInput.value = val - 1;
        updateBulkTotal();
    }
});

document.getElementById('bulk-qty-plus').addEventListener('click', () => {
    let val = parseInt(bulkQuantityInput.value) || 1;
    if (val < 100) {
        bulkQuantityInput.value = val + 1;
        updateBulkTotal();
    }
});

bulkQuantityInput.addEventListener('input', () => {
    let val = parseInt(bulkQuantityInput.value);
    if (isNaN(val) || val < 1) bulkQuantityInput.value = 1;
    if (val > 100) bulkQuantityInput.value = 100;
    updateBulkTotal();
});

document.getElementById('bulk-buy-confirm').addEventListener('click', () => {
    const qty = parseInt(bulkQuantityInput.value) || 1;
    fetch(`https://${GetParentResourceName()}/buyBulk`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ quantity: qty })
    });
});