const container = document.getElementById('inventory-container');
const itemGrid   = document.getElementById('itemGrid');
const catTabs    = document.getElementById('categoryTabs');
const emptyMsg   = document.getElementById('emptyMsg');
const confirmModal = document.getElementById('confirmModal');
const confirmMessage = document.getElementById('confirmMessage');
const confirmYes = document.getElementById('confirmYes');
const confirmNo = document.getElementById('confirmNo');

let items      = [];
let categories = [];
let activeCategory = 'all';
let pendingDeleteItem = null;

// ── NUI messages ──
window.addEventListener('message', (event) => {
    const d = event.data;
    if (d.type === 'open') {
        categories = d.categories || [];
        items      = d.items || [];
        activeCategory = 'all';
        renderTabs();
        renderItems();
        container.classList.remove('hidden');
    } else if (d.type === 'close') {
        container.classList.add('hidden');
    } else if (d.type === 'updateItems') {
        items = d.items || [];
        renderItems();
    }
});

// ── Tabs ──
function renderTabs() {
    catTabs.innerHTML = '';

    // "All" tab
    const allTab = createTab('all', 'All', '📦');
    catTabs.appendChild(allTab);

    // Only show categories that have items
    const activeCats = new Set(items.map(i => i.category));
    categories.forEach(cat => {
        if (activeCats.has(cat.id)) {
            catTabs.appendChild(createTab(cat.id, cat.label, cat.icon));
        }
    });
}

function createTab(id, label, icon) {
    const tab = document.createElement('div');
    tab.className = 'cat-tab' + (activeCategory === id ? ' active' : '');
    tab.textContent = (icon ? icon + ' ' : '') + label;
    tab.addEventListener('click', () => {
        activeCategory = id;
        renderTabs();
        renderItems();
    });
    return tab;
}

// ── Items ──
function renderItems() {
    // Remove all item rows (keep emptyMsg node)
    itemGrid.querySelectorAll('.item-row').forEach(el => el.remove());

    const filtered = activeCategory === 'all'
        ? items
        : items.filter(i => i.category === activeCategory);

    if (filtered.length === 0) {
        emptyMsg.style.display = '';
        emptyMsg.textContent = activeCategory === 'all'
            ? 'Your inventory is empty'
            : 'No items in this category';
        return;
    }

    emptyMsg.style.display = 'none';

    filtered.forEach(item => {
        const row = document.createElement('div');
        row.className = 'item-row';

        const catLabel = getCategoryLabel(item.category);

        row.innerHTML = `
            <div class="item-left">
                <div class="item-name">${item.label}</div>
                <div class="item-cat">${catLabel}</div>
            </div>
            <div class="item-right">
                <span class="item-qty">x${item.quantity}</span>
                ${item.usable
                    ? `<button class="btn-use" onclick="useItem('${item.name}')">USE</button>`
                    : `<button class="btn-use not-usable" disabled>—</button>`
                }
                <button class="btn-delete" onclick="confirmDeleteItem('${item.name}', '${item.label}', ${item.quantity})">🗑️</button>
            </div>
        `;
        itemGrid.appendChild(row);
    });
}

function getCategoryLabel(catId) {
    const cat = categories.find(c => c.id === catId);
    return cat ? cat.label : catId;
}

function useItem(name) {
    fetch(`https://${GetParentResourceName()}/useItem`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ name })
    });
}

function confirmDeleteItem(name, label, quantity) {
    pendingDeleteItem = { name, label, quantity };
    confirmMessage.textContent = `Delete ${quantity}x ${label}? This action cannot be undone.`;
    confirmModal.classList.remove('hidden');
}

function deleteItem() {
    if (!pendingDeleteItem) return;
    
    fetch(`https://${GetParentResourceName()}/deleteItem`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ name: pendingDeleteItem.name })
    });
    
    confirmModal.classList.add('hidden');
    pendingDeleteItem = null;
}

function cancelDelete() {
    confirmModal.classList.add('hidden');
    pendingDeleteItem = null;
}

// Confirmation modal buttons
confirmYes.addEventListener('click', deleteItem);
confirmNo.addEventListener('click', cancelDelete);

// ── Close ──
document.getElementById('closeBtn').addEventListener('click', () => {
    fetch(`https://${GetParentResourceName()}/close`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    });
});

document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
        fetch(`https://${GetParentResourceName()}/close`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({})
        });
    }
});
