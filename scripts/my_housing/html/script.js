// Housing System UI Script
// No jQuery - vanilla JS only

let currentHouse = null;
let currentPlayer = null;
let currentStorage = null;
let valueHistoryChart = null;
let storageVisible = false;

// Format currency
function formatCurrency(amount) {
    return '$' + amount.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
}

// Show error message
function showError(message) {
    const errorEl = document.getElementById('error-message');
    errorEl.textContent = message;
    errorEl.style.display = 'block';
    setTimeout(function() {
        errorEl.style.display = 'none';
    }, 5000);
}

// Update house data in UI
function updateHouseData(house, player) {
    currentHouse = house;
    currentPlayer = player;
    storageVisible = false;

    document.getElementById('house-name').textContent = house.name;
    document.getElementById('house-label').textContent = house.label;
    document.getElementById('house-price').textContent = formatCurrency(house.price);
    document.getElementById('house-base-price').textContent = formatCurrency(house.basePrice);

    if (house.owner) {
        document.getElementById('house-owner').textContent = house.owner;
    } else {
        document.getElementById('house-owner').textContent = 'For Sale';
    }

    const rentStatusRow = document.getElementById('rent-status-row');
    const rentPriceRow = document.getElementById('rent-price-row');

    if (house.owner) {
        rentStatusRow.style.display = 'flex';
        document.getElementById('house-rent-status').textContent = house.isRented ? 'Rented' : 'Available for Rent';
        rentPriceRow.style.display = 'flex';
        document.getElementById('house-rent-price').textContent = formatCurrency(house.rentPrice) + ' per hour';
    } else {
        rentStatusRow.style.display = 'none';
        rentPriceRow.style.display = 'none';
    }

    if (player.isOwner) {
        document.getElementById('total-earnings').textContent = formatCurrency(house.totalEarnings);
        document.getElementById('rent-toggle').checked = house.isRented;
    }

    // Hide error
    document.getElementById('error-message').style.display = 'none';

    // Update chart
    updateValueHistoryChart(house.valueHistory);

    // Show appropriate panels
    const buyPanel = document.getElementById('buy-panel');
    const ownerPanel = document.getElementById('owner-panel');
    const storageSection = document.getElementById('storage-section');
    const storageBtn = document.getElementById('storage-toggle-btn');

    buyPanel.style.display = 'none';
    ownerPanel.style.display = 'none';
    storageSection.style.display = 'none';

    if (player.isOwner) {
        ownerPanel.style.display = 'block';
        // Show/hide storage button based on rental status
        if (player.canAccessStorage) {
            storageBtn.style.display = 'block';
            storageBtn.textContent = 'House Storage';
        } else {
            storageBtn.style.display = 'none';
        }
        // Show/hide rest button: only for owned, non-rented houses
        var restBtn = document.getElementById('rest-btn');
        if (player.canAccessStorage) {
            restBtn.style.display = 'block';
        } else {
            restBtn.style.display = 'none';
        }
    } else if (player.canBuy) {
        buyPanel.style.display = 'block';
        document.getElementById('buy-price').textContent = formatCurrency(house.price);
    }
}

// Create/update market value history chart
function updateValueHistoryChart(valueHistoryData) {
    let chartData = valueHistoryData;
    if (typeof valueHistoryData === 'string') {
        try {
            chartData = JSON.parse(valueHistoryData);
        } catch (e) {
            console.error('Failed to parse value history data:', e);
            chartData = [];
        }
    }

    if (valueHistoryChart) {
        valueHistoryChart.data.labels = Array.from({ length: chartData.length }, function(_, i) { return 'Point ' + (i + 1); });
        valueHistoryChart.data.datasets[0].data = chartData;
        valueHistoryChart.update();
        return;
    }

    const ctx = document.getElementById('valueHistoryChart').getContext('2d');

    valueHistoryChart = new Chart(ctx, {
        type: 'line',
        data: {
            labels: Array.from({ length: chartData.length }, function(_, i) { return 'Point ' + (i + 1); }),
            datasets: [{
                label: 'Market Value',
                data: chartData,
                backgroundColor: 'rgba(52, 152, 219, 0.2)',
                borderColor: 'rgba(52, 152, 219, 1)',
                borderWidth: 2,
                pointBackgroundColor: 'rgba(52, 152, 219, 1)',
                pointBorderColor: '#fff',
                pointBorderWidth: 1,
                pointRadius: 4,
                pointHoverRadius: 6,
                tension: 0.1
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            scales: {
                y: {
                    beginAtZero: false,
                    grid: {
                        color: 'rgba(255, 255, 255, 0.1)'
                    },
                    ticks: {
                        color: 'rgba(255, 255, 255, 0.7)',
                        callback: function(value) {
                            return '$' + value.toLocaleString();
                        }
                    }
                },
                x: {
                    grid: {
                        color: 'rgba(255, 255, 255, 0.1)'
                    },
                    ticks: {
                        color: 'rgba(255, 255, 255, 0.7)'
                    }
                }
            },
            plugins: {
                legend: {
                    display: false
                },
                tooltip: {
                    callbacks: {
                        label: function(context) {
                            return formatCurrency(context.parsed.y);
                        }
                    }
                }
            }
        }
    });
}

// ============================================================
// House Storage Functions
// ============================================================

// Update storage UI with data from server
function updateStorageUI(storage) {
    currentStorage = storage;

    // Update player items
    var playerItemsList = document.getElementById('player-items-list');
    playerItemsList.innerHTML = '';
    
    var playerItems = storage.playerItems || {};
    var hasPlayerItems = false;
    
    for (var itemName in playerItems) {
        if (playerItems[itemName] > 0) {
            hasPlayerItems = true;
            var itemEl = createItemRow(itemName, playerItems[itemName], 'deposit');
            playerItemsList.appendChild(itemEl);
        }
    }
    
    if (!hasPlayerItems) {
        playerItemsList.innerHTML = '<div class="storage-empty">No items in inventory</div>';
    }

    // Update house items
    var houseItemsList = document.getElementById('house-items-list');
    houseItemsList.innerHTML = '';
    
    var houseItems = storage.houseItems || {};
    var hasHouseItems = false;
    var houseItemCount = 0;
    
    for (var hItemName in houseItems) {
        if (houseItems[hItemName] > 0) {
            hasHouseItems = true;
            houseItemCount++;
            var hItemEl = createItemRow(hItemName, houseItems[hItemName], 'withdraw');
            houseItemsList.appendChild(hItemEl);
        }
    }
    
    if (!hasHouseItems) {
        houseItemsList.innerHTML = '<div class="storage-empty">No items stored</div>';
    }

    // Update storage count
    document.getElementById('storage-count').textContent = '(' + houseItemCount + '/' + (storage.maxItemStacks || 50) + ')';

    // Update money
    document.getElementById('player-cash').textContent = formatCurrency(storage.playerCash || 0);
    document.getElementById('player-dirty').textContent = formatCurrency(storage.playerDirty || 0);
    document.getElementById('house-cash').textContent = formatCurrency(storage.houseCash || 0);
    document.getElementById('house-dirty').textContent = formatCurrency(storage.houseDirty || 0);
}

// Create an item row element for storage
function createItemRow(itemName, quantity, type) {
    var row = document.createElement('div');
    row.className = 'storage-item';
    
    // Format item name for display (convert snake_case to Title Case)
    var displayName = itemName.replace(/_/g, ' ').replace(/\b\w/g, function(l) { return l.toUpperCase(); });
    
    var info = document.createElement('div');
    info.className = 'storage-item-info';
    info.innerHTML = '<span class="storage-item-name">' + displayName + '</span>' +
                     '<span class="storage-item-qty">x' + quantity + '</span>';
    
    var actions = document.createElement('div');
    actions.className = 'storage-item-actions';
    
    var input = document.createElement('input');
    input.type = 'number';
    input.min = '1';
    input.max = String(quantity);
    input.value = '1';
    input.setAttribute('data-item', itemName);
    
    var btn = document.createElement('button');
    btn.className = 'transfer-btn ' + (type === 'deposit' ? 'deposit-btn' : 'withdraw-btn');
    btn.textContent = type === 'deposit' ? 'Store →' : '← Take';
    
    btn.addEventListener('click', function() {
        var amount = parseInt(input.value) || 1;
        if (amount < 1) amount = 1;
        if (amount > quantity) amount = quantity;
        
        if (type === 'deposit') {
            depositItem(itemName, amount);
        } else {
            withdrawItem(itemName, amount);
        }
    });
    
    actions.appendChild(input);
    actions.appendChild(btn);
    
    row.appendChild(info);
    row.appendChild(actions);
    
    return row;
}

// Deposit item to house
function depositItem(itemName, amount) {
    if (!currentHouse) return;
    disableTransferButtons();
    fetch('https://' + GetParentResourceName() + '/depositItem', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ houseId: currentHouse.id, itemName: itemName, amount: amount })
    });
}

// Withdraw item from house
function withdrawItem(itemName, amount) {
    if (!currentHouse) return;
    disableTransferButtons();
    fetch('https://' + GetParentResourceName() + '/withdrawItem', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ houseId: currentHouse.id, itemName: itemName, amount: amount })
    });
}

// Deposit money to house
function depositMoney(moneyType, amount) {
    if (!currentHouse) return;
    disableTransferButtons();
    fetch('https://' + GetParentResourceName() + '/depositMoney', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ houseId: currentHouse.id, moneyType: moneyType, amount: amount })
    });
}

// Withdraw money from house
function withdrawMoney(moneyType, amount) {
    if (!currentHouse) return;
    disableTransferButtons();
    fetch('https://' + GetParentResourceName() + '/withdrawMoney', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ houseId: currentHouse.id, moneyType: moneyType, amount: amount })
    });
}

// Disable all transfer buttons temporarily to prevent double-clicks
function disableTransferButtons() {
    var btns = document.querySelectorAll('.transfer-btn, .small-btn');
    btns.forEach(function(btn) { btn.disabled = true; });
    // Re-enable after timeout as fallback (server update will rebuild the DOM anyway)
    setTimeout(function() {
        btns.forEach(function(btn) { btn.disabled = false; });
    }, 3000);
}

// Toggle storage section visibility
function toggleStorage() {
    var storageSection = document.getElementById('storage-section');
    var storageBtn = document.getElementById('storage-toggle-btn');
    storageVisible = !storageVisible;
    
    if (storageVisible) {
        storageSection.style.display = 'block';
        storageBtn.textContent = 'Hide Storage';
    } else {
        storageSection.style.display = 'none';
        storageBtn.textContent = 'House Storage';
    }
}

// Close UI
function closeUI() {
    fetch('https://' + GetParentResourceName() + '/closeUI', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    });
}

// Event listeners
document.addEventListener('DOMContentLoaded', function() {
    // Close button
    document.getElementById('close-btn').addEventListener('click', closeUI);

    // Buy with cash
    document.getElementById('buy-cash-btn').addEventListener('click', function() {
        if (!currentHouse) return;
        fetch('https://' + GetParentResourceName() + '/buyHouse', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ houseId: currentHouse.id })
        });
    });

    // Sell house
    document.getElementById('sell-btn').addEventListener('click', function() {
        if (!currentHouse) return;
        fetch('https://' + GetParentResourceName() + '/sellHouse', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ houseId: currentHouse.id })
        });
    });

    // Rent toggle
    document.getElementById('rent-toggle').addEventListener('change', function() {
        if (!currentHouse) return;
        var rentStatus = this.checked;
        fetch('https://' + GetParentResourceName() + '/toggleRent', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ houseId: currentHouse.id, rentStatus: rentStatus })
        });
    });

    // Rent house button
    document.getElementById('rent-btn').addEventListener('click', function() {
        if (!currentHouse) return;
        fetch('https://' + GetParentResourceName() + '/rentHouse', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ houseId: currentHouse.id })
        });
    });

    // Storage toggle button
    document.getElementById('storage-toggle-btn').addEventListener('click', function() {
        toggleStorage();
    });

    // Rest at house button
    document.getElementById('rest-btn').addEventListener('click', function() {
        if (!currentHouse) return;
        fetch('https://' + GetParentResourceName() + '/restAtHouse', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ houseId: currentHouse.id })
        });
    });

    // Storage tab switching
    var storageTabs = document.querySelectorAll('.storage-tab');
    storageTabs.forEach(function(tab) {
        tab.addEventListener('click', function() {
            storageTabs.forEach(function(t) { t.classList.remove('active'); });
            tab.classList.add('active');
            
            var tabName = tab.getAttribute('data-tab');
            document.getElementById('storage-items-tab').style.display = tabName === 'items' ? 'block' : 'none';
            document.getElementById('storage-money-tab').style.display = tabName === 'money' ? 'block' : 'none';
        });
    });

    // Money deposit/withdraw buttons
    document.getElementById('deposit-cash-btn').addEventListener('click', function() {
        var amount = parseInt(document.getElementById('deposit-cash-amount').value) || 0;
        if (amount > 0) {
            depositMoney('cash', amount);
            document.getElementById('deposit-cash-amount').value = '';
        }
    });

    document.getElementById('deposit-dirty-btn').addEventListener('click', function() {
        var amount = parseInt(document.getElementById('deposit-dirty-amount').value) || 0;
        if (amount > 0) {
            depositMoney('dirty', amount);
            document.getElementById('deposit-dirty-amount').value = '';
        }
    });

    document.getElementById('withdraw-cash-btn').addEventListener('click', function() {
        var amount = parseInt(document.getElementById('withdraw-cash-amount').value) || 0;
        if (amount > 0) {
            withdrawMoney('cash', amount);
            document.getElementById('withdraw-cash-amount').value = '';
        }
    });

    document.getElementById('withdraw-dirty-btn').addEventListener('click', function() {
        var amount = parseInt(document.getElementById('withdraw-dirty-amount').value) || 0;
        if (amount > 0) {
            withdrawMoney('dirty', amount);
            document.getElementById('withdraw-dirty-amount').value = '';
        }
    });
});

// NUI Message listener
window.addEventListener('message', function(event) {
    var data = event.data;

    if (data.type === 'open') {
        document.getElementById('housing-container').style.display = 'flex';
        document.getElementById('storage-section').style.display = 'none';
        storageVisible = false;
        currentStorage = null;
        updateHouseData(data.house, data.player);
    } else if (data.type === 'close') {
        document.getElementById('housing-container').style.display = 'none';
        document.getElementById('storage-section').style.display = 'none';
        storageVisible = false;
        currentStorage = null;
    } else if (data.type === 'error') {
        showError(data.message);
    } else if (data.type === 'toggleRentError') {
        showError(data.message);
        // Revert toggle
        var toggle = document.getElementById('rent-toggle');
        toggle.checked = !toggle.checked;
    } else if (data.type === 'updateStorage') {
        updateStorageUI(data.storage);
        // Always show storage section when storage data arrives (user has it open)
        if (storageVisible) {
            document.getElementById('storage-section').style.display = 'block';
            // Flash the storage section for visual feedback
            var section = document.getElementById('storage-section');
            section.classList.add('storage-flash');
            setTimeout(function() { section.classList.remove('storage-flash'); }, 400);
        }
    } else if (data.type === 'storageError') {
        showError(data.message);
    }
});
