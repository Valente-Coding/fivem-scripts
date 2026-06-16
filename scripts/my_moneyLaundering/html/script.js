/* ===============================================
   MONEY LAUNDERING NUI - SCRIPT.JS
   Custom FiveM Framework - BareBones
   =============================================== */

// ===============================================
// UTILITY
// ===============================================

function getResourceName() {
    return window.GetParentResourceName
        ? window.GetParentResourceName()
        : 'my_moneylaundering';
}

function post(endpoint, data) {
    fetch(`https://${getResourceName()}/${endpoint}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data || {})
    });
}

function formatMoney(amount) {
    if (typeof amount !== 'number') amount = 0;
    return '$' + amount.toLocaleString('en-US');
}

// ===============================================
// DOM REFERENCES
// ===============================================

const container     = document.getElementById('launder-container');
const closeBtn      = document.getElementById('close-btn');
const btnLaunder    = document.getElementById('btn-launder');
const btnCancel     = document.getElementById('btn-cancel');
const dirtyEl       = document.getElementById('dirty-amount');
const cleanEl       = document.getElementById('clean-amount');
const bossCutEl     = document.getElementById('boss-cut');
const yourRateEl    = document.getElementById('your-rate');
const warningEl     = document.getElementById('launder-warning');
const feedbackEl    = document.getElementById('feedback-message');

// ===============================================
// OPEN / CLOSE
// ===============================================

function openUI(data) {
    dirtyEl.textContent  = formatMoney(data.dirtyMoney);
    cleanEl.textContent  = formatMoney(data.cleanAmount);
    bossCutEl.textContent = (100 - data.launderRate) + '%';
    yourRateEl.textContent = data.launderRate + '%';

    // Check if player has enough
    if (data.dirtyMoney < data.minRequired) {
        warningEl.style.display = 'block';
        btnLaunder.disabled = true;
    } else {
        warningEl.style.display = 'none';
        btnLaunder.disabled = false;
    }

    container.style.display = 'flex';
    container.classList.remove('closing');
}

function closeUI() {
    container.classList.add('closing');
    setTimeout(() => {
        container.style.display = 'none';
        container.classList.remove('closing');
    }, 200);
    post('close');
}

// ===============================================
// FEEDBACK BANNER
// ===============================================

let feedbackTimer = null;

function showFeedback(success, message) {
    if (feedbackTimer) clearTimeout(feedbackTimer);

    feedbackEl.textContent = message;
    feedbackEl.className = 'feedback-message ' + (success ? 'success' : 'error');
    feedbackEl.style.display = 'block';

    feedbackTimer = setTimeout(() => {
        feedbackEl.classList.add('closing');
        setTimeout(() => {
            feedbackEl.style.display = 'none';
            feedbackEl.classList.remove('closing');
        }, 300);
    }, 4000);
}

// ===============================================
// NUI MESSAGE LISTENER
// ===============================================

window.addEventListener('message', (event) => {
    const data = event.data;

    switch (data.action) {
        case 'open':
            openUI(data);
            break;

        case 'close':
            container.classList.add('closing');
            setTimeout(() => {
                container.style.display = 'none';
                container.classList.remove('closing');
            }, 200);
            break;

        case 'feedback':
            showFeedback(data.success, data.message);
            break;
    }
});

// ===============================================
// BUTTON HANDLERS
// ===============================================

closeBtn.addEventListener('click', closeUI);
btnCancel.addEventListener('click', closeUI);

btnLaunder.addEventListener('click', () => {
    if (btnLaunder.disabled) return;
    btnLaunder.disabled = true;
    btnLaunder.textContent = 'PROCESSING...';

    // Close UI and trigger server event
    container.classList.add('closing');
    setTimeout(() => {
        container.style.display = 'none';
        container.classList.remove('closing');
        btnLaunder.textContent = 'LAUNDER MONEY';
    }, 200);

    post('launder');
});

// ===============================================
// KEYBOARD: Escape to close
// ===============================================

document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape' && container.style.display === 'flex') {
        closeUI();
    }
});
