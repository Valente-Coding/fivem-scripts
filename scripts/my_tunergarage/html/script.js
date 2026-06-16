/* ===============================================
   GARAGE PURCHASE & MANAGEMENT NUI - SCRIPT.JS
   Custom FiveM Framework - BareBones
   =============================================== */

// ===============================================
// STATE MANAGEMENT
// ===============================================

let isProcessing = false;
let isOwned = false;
let hasWorker = false;
let currentView = null; // 'purchase' or 'management'

// ===============================================
// UTILITY FUNCTIONS
// ===============================================

/**
 * Get the resource name (FiveM helper)
 * @returns {string} Resource name
 */
function getResourceName() {
    return window.GetParentResourceName
        ? window.GetParentResourceName()
        : 'my_tunergarage';
}

/**
 * Post data to NUI callback
 * @param {string} endpoint - Callback endpoint
 * @param {object} data - Data to send
 */
function post(endpoint, data) {
    fetch(`https://${getResourceName()}/${endpoint}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data)
    });
}

/**
 * Format price with dollar sign and comma separators
 * @param {number} price - Price to format
 * @returns {string} Formatted price (e.g., $500,000)
 */
function formatPrice(price) {
    if (typeof price !== 'number') {
        price = 0;
    }
    return '$' + price.toLocaleString('en-US');
}

// ===============================================
// UI FUNCTIONS
// ===============================================

/**
 * Open the garage purchase UI
 * @param {string} garageName - Name of the garage
 * @param {number} price - Purchase price
 * @param {boolean} owned - Whether already owned
 */
function openUI(garageName, price, owned) {
    // Clear any previous feedback
    hideFeedback();

    isOwned = owned;

    // Set garage info
    document.getElementById('garage-name').textContent = garageName;
    document.getElementById('price-value').textContent = formatPrice(price);

    // Update status
    const statusValue = document.getElementById('status-value');
    const description = document.getElementById('garage-description');
    const btn = document.getElementById('confirm-btn');

    if (owned) {
        statusValue.textContent = 'Owned';
        statusValue.classList.add('status-owned');
        description.innerHTML = 'You are the proud owner of <strong>' + garageName + '</strong>.';
        btn.textContent = 'ALREADY OWNED';
        btn.classList.add('owned');
        btn.disabled = true;
    } else {
        statusValue.textContent = 'Available';
        statusValue.classList.remove('status-owned');
        description.innerHTML = 'Purchase this garage to become the proud owner of <strong>' + garageName + '</strong>.';
        resetConfirmButton();
    }

    // Show container with animation
    const container = document.getElementById('garage-container');
    container.style.display = 'flex';
    container.classList.remove('closing');

    // Reset processing state
    isProcessing = false;
}

/**
 * Close the garage purchase UI
 */
function closeUI() {
    const containers = ['garage-container', 'management-container'];
    containers.forEach(id => {
        const el = document.getElementById(id);
        if (el && el.style.display === 'flex') {
            el.classList.add('closing');
            setTimeout(() => {
                el.style.display = 'none';
                el.classList.remove('closing');
            }, 200);
        }
    });

    // Send close callback to Lua
    post('close', {});

    // Reset state
    isProcessing = false;
    currentView = null;

    // Hide feedback
    hideFeedback();
}

// ===============================================
// MANAGEMENT UI FUNCTIONS
// ===============================================

/**
 * Open the garage management UI
 */
function openManagement(garageName, workerHired, pendingProfit, hireCost) {
    hideFeedback();
    hasWorker = workerHired;

    // Hide purchase view, show management view
    document.getElementById('garage-container').style.display = 'none';
    const container = document.getElementById('management-container');

    // Set garage name
    document.getElementById('mgmt-garage-name').textContent = garageName;

    // Worker status
    const workerStatus = document.getElementById('mgmt-worker-status');
    const hireBtn = document.getElementById('hire-btn');
    const collectBtn = document.getElementById('collect-btn');
    const description = document.getElementById('mgmt-description');

    if (workerHired) {
        workerStatus.textContent = 'Hired';
        workerStatus.classList.add('status-hired');
        hireBtn.style.display = 'none';
        collectBtn.style.display = 'block';
        description.innerHTML = 'Your mechanic is working on cars. Collect your earnings below.';
    } else {
        workerStatus.textContent = 'Not Hired';
        workerStatus.classList.remove('status-hired');
        hireBtn.style.display = 'block';
        hireBtn.textContent = 'HIRE MECHANIC \u2014 ' + formatPrice(hireCost);
        hireBtn.disabled = false;
        hireBtn.classList.remove('loading');
        collectBtn.style.display = 'none';
        description.innerHTML = 'Hire a mechanic to work on cars and earn passive income.';
    }

    // Update profit display
    updateProfitDisplay(pendingProfit || 0);

    // Show container
    container.style.display = 'flex';
    container.classList.remove('closing');
    currentView = 'management';
    isProcessing = false;
}

/**
 * Update the profit display value
 */
function updateProfitDisplay(amount) {
    const profitEl = document.getElementById('mgmt-profit-value');
    if (profitEl) {
        profitEl.textContent = formatPrice(amount);
        if (amount > 0) {
            profitEl.classList.add('profit-positive');
        } else {
            profitEl.classList.remove('profit-positive');
        }
    }

    // Enable/disable collect button
    const collectBtn = document.getElementById('collect-btn');
    if (collectBtn && hasWorker) {
        collectBtn.disabled = (amount <= 0);
    }
}

/**
 * Handle hire mechanic button click
 */
function hireWorker() {
    if (isProcessing || hasWorker) return;
    isProcessing = true;

    const btn = document.getElementById('hire-btn');
    if (btn) {
        btn.classList.add('loading');
        btn.textContent = 'PROCESSING...';
        btn.disabled = true;
    }

    post('hireWorker', {});
}

/**
 * Handle collect profit button click
 */
function collectProfit() {
    if (isProcessing) return;
    isProcessing = true;

    const btn = document.getElementById('collect-btn');
    if (btn) {
        btn.classList.add('loading');
        btn.textContent = 'COLLECTING...';
        btn.disabled = true;
    }

    post('collectProfit', {});
}

/**
 * Handle confirm purchase
 */
function confirmPurchase() {
    // Prevent double-click or if already owned
    if (isProcessing || isOwned) return;

    // Set processing state
    isProcessing = true;

    // Update button state
    const btn = document.getElementById('confirm-btn');
    if (btn) {
        btn.classList.add('loading');
        btn.textContent = 'PROCESSING...';
        btn.disabled = true;
    }

    // Send confirmation to Lua
    post('confirmPurchase', {});
}

/**
 * Reset the confirm button to normal state
 */
function resetConfirmButton() {
    isProcessing = false;

    const btn = document.getElementById('confirm-btn');
    if (btn) {
        btn.classList.remove('loading');
        btn.classList.remove('owned');
        btn.textContent = 'PURCHASE';
        btn.disabled = false;
    }
}

/**
 * Show feedback message banner
 * @param {string} message - Message to display
 * @param {boolean} isSuccess - True for success, false for error
 */
function showFeedback(message, isSuccess) {
    const feedback = document.getElementById('feedback-message');

    // Set message content
    feedback.textContent = message;

    // Set style based on success/error
    feedback.className = 'feedback-message ' + (isSuccess ? 'success' : 'error');

    // Show feedback
    feedback.style.display = 'block';

    // Auto-hide after timeout
    const timeout = isSuccess ? 3000 : 5000;
    setTimeout(() => {
        hideFeedback();
    }, timeout);
}

/**
 * Hide feedback message banner
 */
function hideFeedback() {
    const feedback = document.getElementById('feedback-message');

    // Add closing animation
    feedback.classList.add('closing');

    // Wait for animation then hide
    setTimeout(() => {
        feedback.style.display = 'none';
        feedback.classList.remove('closing');
    }, 300);
}

// ===============================================
// EVENT LISTENERS
// ===============================================

/**
 * Message event listener - receives data from Lua
 */
window.addEventListener('message', (event) => {
    const data = event.data;

    switch (data.action) {
        case 'open':
            currentView = 'purchase';
            openUI(data.garageName || 'Garage', data.price || 0, data.owned || false);
            break;

        case 'openManagement':
            openManagement(
                data.garageName || 'Garage',
                data.hasWorker || false,
                data.pendingProfit || 0,
                data.hireCost || 10000
            );
            break;

        case 'close':
            closeUI();
            break;

        case 'error':
            showFeedback(data.message || 'Purchase failed', false);
            resetConfirmButton();
            break;
    }
});

/**
 * Close button click handler
 */
document.addEventListener('DOMContentLoaded', () => {
    // Purchase view buttons
    const closeBtn = document.getElementById('close-btn');
    if (closeBtn) {
        closeBtn.addEventListener('click', closeUI);
    }

    const confirmBtn = document.getElementById('confirm-btn');
    if (confirmBtn) {
        confirmBtn.addEventListener('click', confirmPurchase);
    }

    // Management view buttons
    const mgmtCloseBtn = document.getElementById('mgmt-close-btn');
    if (mgmtCloseBtn) {
        mgmtCloseBtn.addEventListener('click', closeUI);
    }

    const hireBtn = document.getElementById('hire-btn');
    if (hireBtn) {
        hireBtn.addEventListener('click', hireWorker);
    }

    const collectBtn = document.getElementById('collect-btn');
    if (collectBtn) {
        collectBtn.addEventListener('click', collectProfit);
    }
});

/**
 * ESC key handler (backup - primary handler is in client.lua)
 */
document.addEventListener('keyup', (event) => {
    if (event.key === 'Escape') {
        const purchase = document.getElementById('garage-container');
        const management = document.getElementById('management-container');
        if ((purchase && purchase.style.display === 'flex') ||
            (management && management.style.display === 'flex')) {
            closeUI();
        }
    }
});

// ===============================================
// DEBUG HELPERS (for browser testing)
// ===============================================

if (!window.GetParentResourceName) {
    console.log('[TunerGarage] Running in browser mode - debug enabled');

    // Auto-open UI after 1 second (for testing)
    setTimeout(() => {
        openUI('Little Seoul Tuner Garage', 500000, false);
    }, 1000);

    // Test owned state
    window.testOwned = () => {
        openUI('Little Seoul Tuner Garage', 500000, true);
    };

    // Test management view (no worker)
    window.testManagement = () => {
        openManagement('Little Seoul Tuner Garage', false, 0, 10000);
    };

    // Test management view (worker hired, with profit)
    window.testManagementHired = () => {
        openManagement('Little Seoul Tuner Garage', true, 1350, 10000);
    };

    // Test error
    window.testError = () => {
        showFeedback('Not enough money. You need $500,000.', false);
        resetConfirmButton();
    };
}
