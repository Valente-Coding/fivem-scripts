const container = document.getElementById('shop-container');
const itemList   = document.getElementById('itemList');
const closeBtn   = document.getElementById('closeBtn');

let shopItems = [];

/* ── Icon map (emoji fallbacks – easy to swap for images later) ────────── */
const iconMap = {
    'cleaning_kit': '🧹',
    'repair_kit':   '🔧',
    'oil_bottle':   '🛢️',
};

function getIcon(name) {
    return iconMap[name] || '📦';
}

/* ── NUI message listener ─────────────────────────────────────────────── */
window.addEventListener('message', (event) => {
    const data = event.data;

    if (data.type === 'openShop') {
        shopItems = data.items;
        renderItems();
        container.classList.remove('hidden');
    } else if (data.type === 'closeShop') {
        container.classList.add('hidden');
    }
});

/* ── Render items ─────────────────────────────────────────────────────── */
function renderItems() {
    itemList.innerHTML = '';

    shopItems.forEach(item => {
        const card = document.createElement('div');
        card.className = 'item-card';

        card.innerHTML = `
            <div class="item-icon">${getIcon(item.name)}</div>
            <div class="item-info">
                <div class="item-name">${item.label}</div>
                <div class="item-price">$${item.price.toLocaleString()}</div>
            </div>
            <div class="item-actions">
                <button class="btn btn-buy" onclick="buyItem('${item.name}')">Buy</button>
            </div>
        `;

        itemList.appendChild(card);
    });
}

/* ── Buy action ───────────────────────────────────────────────────────── */
function buyItem(name) {
    fetch(`https://${GetParentResourceName()}/buyItem`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ name })
    });
}

/* ── Close shop ───────────────────────────────────────────────────────── */
closeBtn.addEventListener('click', () => {
    fetch(`https://${GetParentResourceName()}/closeShop`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    });
});

document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
        fetch(`https://${GetParentResourceName()}/closeShop`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({})
        });
    }
});
