const container = document.getElementById('shop-container');
const closeBtn  = document.getElementById('closeBtn');
const buyBtn    = document.getElementById('buyBtn');
const backBtn   = document.getElementById('backBtn');
const shopView  = document.getElementById('shopView');
const houseView = document.getElementById('houseView');
const houseList = document.getElementById('houseList');
const itemName  = document.getElementById('itemName');
const itemPrice = document.getElementById('itemPrice');

/* ── NUI message listener ─────────────────────────────────────────────── */
window.addEventListener('message', (event) => {
    const data = event.data;

    if (data.action === 'open') {
        itemName.textContent = data.item.label;
        itemPrice.textContent = '$' + data.item.price.toLocaleString();
        showShopView();
        container.classList.remove('hidden');
    } else if (data.action === 'selectHouse') {
        renderHouses(data.houses);
        showHouseView();
    } else if (data.action === 'close') {
        container.classList.add('hidden');
    }
});

/* ── View switching ───────────────────────────────────────────────────── */
function showShopView() {
    shopView.classList.remove('hidden');
    houseView.classList.add('hidden');
}

function showHouseView() {
    shopView.classList.add('hidden');
    houseView.classList.remove('hidden');
}

/* ── Render house list ────────────────────────────────────────────────── */
function renderHouses(houses) {
    houseList.innerHTML = '';

    houses.forEach(house => {
        const card = document.createElement('div');
        card.className = 'house-card';
        card.innerHTML = `
            <div class="house-label">${house.label}</div>
            <button class="btn btn-buy" onclick="selectHouse(${house.id})">Deliver Here</button>
        `;
        houseList.appendChild(card);
    });
}

/* ── Actions ───────────────────────────────────────────────────────────── */
function selectHouse(houseId) {
    fetch(`https://${GetParentResourceName()}/selectHouse`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ houseId })
    });
}

buyBtn.addEventListener('click', () => {
    fetch(`https://${GetParentResourceName()}/buyTools`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    });
});

backBtn.addEventListener('click', () => {
    showShopView();
});

function closeShop() {
    container.classList.add('hidden');
    fetch(`https://${GetParentResourceName()}/close`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    });
}

closeBtn.addEventListener('click', closeShop);

document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
        closeShop();
    }
});
