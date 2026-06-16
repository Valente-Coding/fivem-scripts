/* ===============================================
   MOTEL CHECK-IN NUI - SCRIPT.JS
   Custom FiveM Framework - BareBones
   =============================================== */

// ===============================================
// STATE MANAGEMENT
// ===============================================

let isProcessing = false;

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
        : 'my_motels';
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
 * @returns {string} Formatted price (e.g., $100)
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
 * Open the motel check-in UI
 * @param {string} motelName - Name of the motel
 * @param {number} price - Price per night
 */
function openUI(motelName, price) {
    // Clear any previous feedback
    hideFeedback();

    // Set motel info
    document.getElementById('motel-name').textContent = motelName;
    document.getElementById('price-value').textContent = formatPrice(price);

    // Reset button state
    resetConfirmButton();

    // Show container with animation
    const container = document.getElementById('motel-container');
    container.style.display = 'flex';
    container.classList.remove('closing');

    // Reset processing state
    isProcessing = false;
}

/**
 * Close the motel check-in UI
 */
function closeUI() {
    const container = document.getElementById('motel-container');

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
 * Handle confirm check-in
 */
function confirmCheckIn() {
    // Prevent double-click
    if (isProcessing) return;

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
    post('confirmCheckIn', {});
}

/**
 * Reset the confirm button to normal state
 */
function resetConfirmButton() {
    isProcessing = false;

    const btn = document.getElementById('confirm-btn');
    if (btn) {
        btn.classList.remove('loading');
        btn.textContent = 'CHECK IN';
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
            openUI(data.motelName || 'Motel', data.price || 0);
            break;

        case 'close':
            closeUI();
            break;

        case 'error':
            showFeedback(data.message || 'Check-in failed', false);
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
        confirmBtn.addEventListener('click', confirmCheckIn);
    }
});

/**
 * ESC key handler (backup - primary handler is in client.lua)
 */
document.addEventListener('keyup', (event) => {
    if (event.key === 'Escape') {
        const container = document.getElementById('motel-container');
        if (container && container.style.display === 'flex') {
            closeUI();
        }
    }
});

// ===============================================
// DEBUG HELPERS (for browser testing)
// ===============================================

if (!window.GetParentResourceName) {
    console.log('[Motels] Running in browser mode - debug enabled');

    // Auto-open UI after 1 second (for testing)
    setTimeout(() => {
        openUI('The Pink Cage', 100);
    }, 1000);

    // Test error
    window.testError = () => {
        showFeedback('Not enough money. You need $100.', false);
        resetConfirmButton();
    };
}
