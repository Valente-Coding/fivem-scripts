// Get parent resource name
const resourceName = window.GetParentResourceName ? window.GetParentResourceName() : 'my_money';

// Format number with commas
function formatMoney(amount) {
    return '$' + amount.toLocaleString('en-US');
}

// Update HUD display
function updateHUD(cash, dirty) {
    // Validate inputs
    if (typeof cash !== 'number') cash = 0;
    if (typeof dirty !== 'number') dirty = 0;

    const cashElement = document.getElementById('hud-cash');
    const dirtyElement = document.getElementById('hud-dirty');
    
    if (cashElement) {
        cashElement.textContent = formatMoney(cash);
    }
    
    if (dirtyElement) {
        dirtyElement.textContent = formatMoney(dirty);
    }
}

// Flash money item
function flashMoney(type) {
    const element = document.querySelector(`.money-item.${type}`);
    if (element) {
        element.classList.add('flash');
        setTimeout(() => {
            element.classList.remove('flash');
        }, 600); // Match CSS animation duration
    }
}

// Listen for messages from Lua
window.addEventListener('message', (event) => {
    const data = event.data;
    
    if (!data || !data.action) return;
    
    switch (data.action) {
        case 'updateMoney':
            updateHUD(data.cash, data.dirty);
            break;
            
        case 'flashMoney':
            if (data.type) {
                flashMoney(data.type);
            }
            break;
    }
});

