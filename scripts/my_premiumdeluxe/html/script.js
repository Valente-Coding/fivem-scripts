/* ===============================================
   DEALERSHIP PURCHASE NUI - SCRIPT.JS
   Custom FiveM Framework - BareBones
   =============================================== */

// ===============================================
// STATE MANAGEMENT
// ===============================================

let isProcessing = false;
let isOwned = false;

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
        : 'my_premiumdeluxe';
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
 * Open the dealership purchase UI
 * @param {string} dealershipName - Name of the dealership
 * @param {number} price - Purchase price
 * @param {boolean} owned - Whether already owned
 */
function openUI(dealershipName, price, owned) {
    // Clear any previous feedback
    hideFeedback();

    isOwned = owned;

    // Set dealership info
    document.getElementById('dealership-name').textContent = dealershipName;
    document.getElementById('price-value').textContent = formatPrice(price);

    // Update status
    const statusValue = document.getElementById('status-value');
    const description = document.getElementById('dealership-description');
    const btn = document.getElementById('confirm-btn');

    if (owned) {
        statusValue.textContent = 'Owned';
        statusValue.classList.add('status-owned');
        description.innerHTML = 'You are the proud owner of <strong>' + dealershipName + '</strong>.';
        btn.textContent = 'ALREADY OWNED';
        btn.classList.add('owned');
        btn.disabled = true;
    } else {
        statusValue.textContent = 'Available';
        statusValue.classList.remove('status-owned');
        description.innerHTML = 'Purchase this dealership to become the proud owner of <strong>' + dealershipName + '</strong>.';
        resetConfirmButton();
    }

    // Show container with animation
    const container = document.getElementById('dealership-container');
    container.style.display = 'flex';
    container.classList.remove('closing');

    // Reset processing state
    isProcessing = false;
}

/**
 * Close the dealership purchase UI
 */
function closeUI() {
    const container = document.getElementById('dealership-container');

    // Add closing animation
    container.classList.add('closing');

    // Wait for animation to complete before hiding
    setTimeout(() => {
        container.style.display = 'none';
        container.classList.remove('closing');
    }, 200);

    // Send close callback to Lua
    post('close', {});

    // Reset state
    isProcessing = false;

    // Hide feedback
    hideFeedback();
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
            openUI(data.dealershipName || 'Dealership', data.price || 0, data.owned || false);
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
    const closeBtn = document.getElementById('close-btn');
    if (closeBtn) {
        closeBtn.addEventListener('click', closeUI);
    }

    const confirmBtn = document.getElementById('confirm-btn');
    if (confirmBtn) {
        confirmBtn.addEventListener('click', confirmPurchase);
    }
});

/**
 * ESC key handler (backup - primary handler is in client.lua)
 */
document.addEventListener('keyup', (event) => {
    if (event.key === 'Escape') {
        const container = document.getElementById('dealership-container');
        if (container && container.style.display === 'flex') {
            closeUI();
        }
    }
});

// ===============================================
// DEBUG HELPERS (for browser testing)
// ===============================================

if (!window.GetParentResourceName) {
    console.log('[PremiumDeluxe] Running in browser mode - debug enabled');

    // Auto-open UI after 1 second (for testing)
    setTimeout(() => {
        openUI('Premium Deluxe Motorsport', 500000, false);
    }, 1000);

    // Test owned state
    window.testOwned = () => {
        openUI('Premium Deluxe Motorsport', 500000, true);
    };

    // Test error
    window.testError = () => {
        showFeedback('Not enough money. You need $500,000.', false);
        resetConfirmButton();
    };
}
