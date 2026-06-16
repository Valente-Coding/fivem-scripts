const container = document.getElementById('shop-container');
const weaponList = document.getElementById('weaponList');
const closeBtn = document.getElementById('closeBtn');

const imageMap = {
    'WEAPON_PISTOL': 'img/Pistol.png',
    'WEAPON_MICROSMG': 'img/MicroSMG.png',
    'WEAPON_CARBINERIFLE': 'img/CarbineRifle.png',
    'WEAPON_BAT': 'img/BaseballBat.png',
    'ITEM_ARMOR': 'img/Armor.png'
};

let weaponsData = [];

window.addEventListener('message', (event) => {
    const data = event.data;

    if (data.type === 'openShop') {
        weaponsData = data.weapons;
        renderWeapons();
        container.classList.remove('hidden');
    } else if (data.type === 'closeShop') {
        container.classList.add('hidden');
    } else if (data.type === 'updateWeapon') {
        const weapon = weaponsData.find(w => w.name === data.name);
        if (weapon) {
            weapon.owned = data.owned;
            renderWeapons();
        }
    }
});

function renderWeapons() {
    weaponList.innerHTML = '';

    weaponsData.forEach(weapon => {
        const card = document.createElement('div');
        card.className = 'weapon-card';

        const imgSrc = imageMap[weapon.name] || '';
        const imgHtml = imgSrc ? `<img class="weapon-image" src="${imgSrc}" alt="${weapon.label}">` : '';

        let actionsHtml = '';

        if (weapon.isArmor) {
            actionsHtml = `<button class="btn btn-buy" onclick="buyArmor()">Buy $${weapon.price.toLocaleString()}</button>`;
        } else if (weapon.owned) {
            actionsHtml = `<button class="btn btn-owned">OWNED</button>`;
            if (weapon.ammoPrice > 0) {
                actionsHtml += `<button class="btn btn-ammo" onclick="buyAmmo('${weapon.name}', '${weapon.label}')">Ammo $${weapon.ammoPrice}</button>`;
            }
        } else {
            actionsHtml = `<button class="btn btn-buy" onclick="buyWeapon('${weapon.name}', '${weapon.label}')">Buy $${weapon.price.toLocaleString()}</button>`;
        }

        const ammoPriceText = weapon.ammoPrice > 0 ? `Ammo: $${weapon.ammoPrice} (${weapon.ammoAmount} rounds)` : '';

        card.innerHTML = `
            ${imgHtml}
            <div class="weapon-info">
                <div class="weapon-name">${weapon.label}</div>
                <div class="weapon-price">$${weapon.price.toLocaleString()}</div>
                ${ammoPriceText ? `<div class="ammo-price">${ammoPriceText}</div>` : ''}
            </div>
            <div class="weapon-actions">
                ${actionsHtml}
            </div>
        `;

        weaponList.appendChild(card);
    });
}

function buyWeapon(name, label) {
    fetch(`https://${GetParentResourceName()}/buyWeapon`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ name, label })
    });
}

function buyAmmo(name, label) {
    fetch(`https://${GetParentResourceName()}/buyAmmo`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ name, label })
    });
}

function buyArmor() {
    fetch(`https://${GetParentResourceName()}/buyArmor`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    });
}

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
