// Pawn Shop UI Script
(function () {
    const container = document.getElementById('shop-container');
    const titleEl = document.getElementById('shop-title');
    const itemsList = document.getElementById('items-list');
    const emptyState = document.getElementById('empty-state');
    const closeBtn = document.getElementById('close-btn');

    let currentItems = [];
    let selling = false; // debounce

    // ============================================================
    // Message listener from Lua
    // ============================================================

    window.addEventListener('message', function (event) {
        const data = event.data;

        switch (data.type) {
            case 'openShop':
                openShop(data);
                break;
            case 'closeShop':
                closeShop();
                break;
            case 'updateItems':
                currentItems = data.items || [];
                renderItems();
                break;
        }
    });

    // ============================================================
    // Open / Close
    // ============================================================

    function openShop(data) {
        currentItems = data.items || [];
        titleEl.textContent = data.shopName || 'Pawn Shop';
        container.classList.remove('hidden');
        renderItems();
    }

    function closeShop() {
        container.classList.add('hidden');
        currentItems = [];
        itemsList.innerHTML = '';
        fetch(`https://${GetParentResourceName()}/close`, {
            method: 'POST',
            body: JSON.stringify({})
        });
    }

    // Close button
    closeBtn.addEventListener('click', closeShop);

    // ESC key
    document.addEventListener('keydown', function (e) {
        if (e.key === 'Escape' || e.key === 'Backspace') {
            if (!container.classList.contains('hidden')) {
                closeShop();
            }
        }
    });

    // ============================================================
    // Render Items
    // ============================================================

    function renderItems() {
        itemsList.innerHTML = '';

        if (currentItems.length === 0) {
            emptyState.classList.remove('hidden');
            itemsList.classList.add('hidden');
            return;
        }

        emptyState.classList.add('hidden');
        itemsList.classList.remove('hidden');

        // Sort by price descending
        const sorted = [...currentItems].sort((a, b) => b.price - a.price);

        sorted.forEach(function (item) {
            const row = document.createElement('div');
            row.className = 'item-row';
            row.dataset.name = item.name;

            row.innerHTML = `
                <div class="item-info">
                    <div class="item-name">${escapeHtml(item.label)}</div>
                    <div class="item-details">
                        <span class="item-price">$${formatNumber(item.price)}</span>
                        <span class="item-qty">x${item.quantity}</span>
                    </div>
                </div>
                <button class="sell-btn" data-name="${escapeHtml(item.name)}">Sell</button>
            `;

            const sellBtn = row.querySelector('.sell-btn');
            sellBtn.addEventListener('click', function () {
                sellItem(item.name, sellBtn);
            });

            itemsList.appendChild(row);
        });
    }

    // ============================================================
    // Sell Item
    // ============================================================

    function sellItem(name, btn) {
        if (selling) return;
        selling = true;

        btn.disabled = true;
        btn.textContent = 'Selling...';

        fetch(`https://${GetParentResourceName()}/sellItem`, {
            method: 'POST',
            body: JSON.stringify({ name: name })
        }).then(function () {
            // Brief delay then re-enable (server will send updated items)
            setTimeout(function () {
                selling = false;
            }, 400);
        }).catch(function () {
            selling = false;
            btn.disabled = false;
            btn.textContent = 'Sell';
        });
    }

    // ============================================================
    // Utility
    // ============================================================

    function formatNumber(n) {
        return n.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ',');
    }

    function escapeHtml(str) {
        const div = document.createElement('div');
        div.textContent = str;
        return div.innerHTML;
    }
})();
