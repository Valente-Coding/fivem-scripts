let currentTiers = [];
let activeContract = null;
let lockpickData = null;
let currentStageNum = 1;
let deliveryData = null;
let selectedTier = null;
let playerCash = 0;
let playerDirtyMoney = 0;
let cooldownInfo = null;

function formatMoney(amount) {
    return '$' + amount.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
}

function sendData(action, data = {}) {
    fetch(`https://${GetParentResourceName()}/${action}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data)
    });
}

document.addEventListener('keydown', function(e) {
    if (e.key === 'Escape') {
        const lockpickUI = document.getElementById('lockpickUI');
        if (lockpickUI.style.display !== 'none' && lockpickUI.style.display !== '') {
            // Cancel lockpick — car stays locked, no police, must restart
            closeLockpickUI();
            sendData('lockpickCancelled');
            return;
        }
        closeAllUIs();
    }
});

function closeAllUIs() {
    document.getElementById('contractUI').style.display = 'none';
    document.getElementById('paymentUI').style.display = 'none';
    document.getElementById('lockpickUI').style.display = 'none';
    document.getElementById('deliveryUI').style.display = 'none';
    stopLockpick();
    sendData('closeUI');
}

// ==================== MESSAGE HANDLER ====================

window.addEventListener('message', function(event) {
    const data = event.data;
    if (data.action === 'openContractUI') {
        openContractUI(data.tiers, data.activeContract, data.playerCash, data.playerDirtyMoney, data.cooldown);
    } else if (data.action === 'updateTimer') {
        updateTimer(data.timeRemaining);
    } else if (data.action === 'openLockpickUI') {
        openLockpickUI(data.lockpickSettings);
    } else if (data.action === 'openDeliveryUI') {
        openDeliveryUI(data.deliveryData);
    } else if (data.action === 'closeUI') {
        closeAllUIs();
    }
});

// ==================== CONTRACT UI ====================

function openContractUI(tiers, contract, cash, dirty, cooldown) {
    currentTiers = tiers;
    activeContract = contract;
    playerCash = cash || 0;
    playerDirtyMoney = dirty || 0;
    cooldownInfo = cooldown || null;
    
    const tiersGrid = document.getElementById('tiersGrid');
    tiersGrid.innerHTML = '';
    
    if (cooldownInfo && cooldownInfo.active) {
        const minutes = Math.ceil(cooldownInfo.remainingSeconds / 60);
        const cooldownTier = tiers.find(t => t.id === cooldownInfo.tierId);
        const tierName = cooldownTier ? cooldownTier.name : 'Unknown';
        
        const cooldownDiv = document.createElement('div');
        cooldownDiv.style.cssText = 'grid-column: 1 / -1; background: rgba(220, 50, 50, 0.2); border: 2px solid rgba(220, 50, 50, 0.5); border-radius: 10px; padding: 20px; text-align: center; margin-bottom: 20px;';
        cooldownDiv.innerHTML = `
            <div style="font-size: 24px; font-weight: bold; color: #dc3232; margin-bottom: 10px;">COOLDOWN ACTIVE</div>
            <div style="font-size: 16px; color: #ffffff;">You recently completed a ${tierName} contract.</div>
            <div style="font-size: 18px; color: #ffcc00; margin-top: 10px;">Wait ${minutes} minute${minutes > 1 ? 's' : ''} before accepting another contract.</div>
        `;
        tiersGrid.appendChild(cooldownDiv);
    }
    
    tiers.forEach(tier => {
        const priceText = tier.contractPrice === 0 ? 'FREE' : formatMoney(tier.contractPrice);
        const priceClass = tier.contractPrice === 0 ? 'free' : '';
        
        const tierCard = document.createElement('div');
        tierCard.className = 'tier-card tier-' + tier.id;
        tierCard.setAttribute('data-tier-id', tier.id);
        tierCard.innerHTML = `
            <div class="tier-name">${tier.name}</div>
            <div class="tier-price ${priceClass}">${priceText}</div>
            <div class="tier-description">${tier.description}</div>
            <div class="tier-details">
                <div>Vehicle Range: ${formatMoney(tier.minPrice)} - ${formatMoney(tier.maxPrice)}</div>
                <div>Reward: ${Math.floor(tier.rewardMultiplier * 100)}% of value</div>
                <div>Difficulty: ${tier.lockpick.stages} stages</div>
            </div>
        `;
        
        if (!activeContract && (!cooldownInfo || !cooldownInfo.active)) {
            tierCard.addEventListener('click', function() {
                selectedTier = tier;
                openPaymentUI(tier);
            });
        } else {
            tierCard.style.opacity = '0.5';
            tierCard.style.cursor = 'not-allowed';
        }
        
        tiersGrid.appendChild(tierCard);
    });
    
    if (contract) {
        const tier = tiers.find(t => t.id === contract.tierId);
        const refundAmount = Math.floor(tier.contractPrice * 0.5);
        document.getElementById('activeContractDetails').textContent = tier.name + ' - ' + contract.vehicleLabel;
        document.getElementById('refundAmount').textContent = formatMoney(refundAmount);
        document.getElementById('activeContractSection').style.display = '';
        document.querySelectorAll('.tier-card').forEach(tc => {
            tc.style.opacity = '0.5';
            tc.style.cursor = 'not-allowed';
            tc.replaceWith(tc.cloneNode(true)); // remove click listeners
        });
    } else {
        document.getElementById('activeContractSection').style.display = 'none';
    }
    
    document.getElementById('contractUI').style.display = '';
}

function updateTimer(seconds) {
    const minutes = Math.floor(seconds / 60);
    const secs = seconds % 60;
    document.getElementById('activeContractTimer').textContent = 'Time Remaining: ' + minutes + ':' + secs.toString().padStart(2, '0');
}

document.getElementById('cancelContractBtn').addEventListener('click', function() {
    sendData('cancelContract');
    closeAllUIs();
});

document.getElementById('closeContractUI').addEventListener('click', function() { closeAllUIs(); });

// ==================== PAYMENT UI ====================

function openPaymentUI(tier) {
    document.getElementById('selectedTierName').textContent = tier.name;
    document.getElementById('contractFee').textContent = formatMoney(tier.contractPrice);
    document.getElementById('cashBalance').textContent = formatMoney(playerCash);
    document.getElementById('dirtyMoneyBalance').textContent = formatMoney(playerDirtyMoney);
    
    const canPayCash = playerCash >= tier.contractPrice;
    const canPayDirty = playerDirtyMoney >= tier.contractPrice;
    
    const cashEl = document.getElementById('paymentCash');
    const dirtyEl = document.getElementById('paymentDirty');
    
    cashEl.classList.remove('insufficient', 'available');
    cashEl.classList.add(canPayCash ? 'available' : 'insufficient');
    dirtyEl.classList.remove('insufficient', 'available');
    dirtyEl.classList.add(canPayDirty ? 'available' : 'insufficient');
    
    document.getElementById('contractUI').style.display = 'none';
    document.getElementById('paymentUI').style.display = '';
}

document.getElementById('paymentCash').addEventListener('click', function() {
    if (!selectedTier) return;
    if (playerCash >= selectedTier.contractPrice) {
        sendData('requestContract', { tierId: selectedTier.id, paymentType: 'cash' });
        closeAllUIs();
    }
});

document.getElementById('paymentDirty').addEventListener('click', function() {
    if (!selectedTier) return;
    if (playerDirtyMoney >= selectedTier.contractPrice) {
        sendData('requestContract', { tierId: selectedTier.id, paymentType: 'dirty' });
        closeAllUIs();
    }
});

document.getElementById('closePaymentUI').addEventListener('click', function() {
    document.getElementById('paymentUI').style.display = 'none';
    document.getElementById('contractUI').style.display = '';
});

// ==================== LOCKPICKING UI ====================

let lockpickFrozen = false;
let feedbackTimer = null;

currentStageNum = 1;
function openLockpickUI(settings) {
    lockpickData = settings;
    lockpickFrozen = false;
    document.getElementById('currentStage').textContent = currentStageNum;
    document.getElementById('totalStages').textContent = settings.stages;
    document.getElementById('lockpickUI').style.display = '';
    clearLockpickFeedback();
    
    const successZone = document.getElementById('successZone');
    successZone.style.width = settings.successZoneSize + 'px';
    
    const lockpickBar = document.getElementById('lockpickBar');
    const barWidth = lockpickBar.offsetWidth;
    const maxLeft = barWidth - settings.successZoneSize;
    const randomLeft = Math.random() * maxLeft;
    successZone.style.left = randomLeft + 'px';
    
    const indicator = document.getElementById('indicator');
    indicator.style.animationDuration = settings.indicatorSpeed + 's';
    
    // Remove old listener and add new one
    lockpickBar.removeEventListener('mousedown', handleLockpickClick);
    lockpickBar.addEventListener('mousedown', handleLockpickClick);
}

function showLockpickFeedback(type, message) {
    const feedback = document.getElementById('lockpickFeedback');
    const feedbackText = document.getElementById('feedbackText');
    const lockpickBar = document.getElementById('lockpickBar');
    
    // Clear previous feedback
    feedback.classList.remove('show', 'feedback-success', 'feedback-fail');
    lockpickBar.classList.remove('bar-flash-success', 'bar-flash-fail');
    
    // Apply new feedback
    feedbackText.textContent = message;
    feedback.classList.add('show', type === 'success' ? 'feedback-success' : 'feedback-fail');
    lockpickBar.classList.add(type === 'success' ? 'bar-flash-success' : 'bar-flash-fail');
    
    // Auto-clear bar flash after a short time (for success stages)
    if (feedbackTimer) clearTimeout(feedbackTimer);
    if (type === 'success') {
        feedbackTimer = setTimeout(() => {
            lockpickBar.classList.remove('bar-flash-success');
            feedback.classList.remove('show');
        }, 800);
    }
}

function clearLockpickFeedback() {
    const feedback = document.getElementById('lockpickFeedback');
    const lockpickBar = document.getElementById('lockpickBar');
    if (feedback) feedback.classList.remove('show', 'feedback-success', 'feedback-fail');
    if (lockpickBar) lockpickBar.classList.remove('bar-flash-success', 'bar-flash-fail');
    if (feedbackTimer) { clearTimeout(feedbackTimer); feedbackTimer = null; }
}

function handleLockpickClick(e) {
    if (!lockpickData || lockpickFrozen) return;
    
    const indicator = document.getElementById('indicator');
    const successZone = document.getElementById('successZone');
    
    const indicatorX = indicator.offsetLeft;
    const successLeft = successZone.offsetLeft;
    const successRight = successLeft + lockpickData.successZoneSize;
    
    if (indicatorX >= successLeft && indicatorX <= successRight) {
        // SUCCESS — advance stage
        currentStageNum++;
        if (currentStageNum <= lockpickData.stages) {
            showLockpickFeedback('success', 'Stage Complete!');
            document.getElementById('currentStage').textContent = currentStageNum;
            const lockpickBar = document.getElementById('lockpickBar');
            const barWidth = lockpickBar.offsetWidth;
            const maxLeft = barWidth - lockpickData.successZoneSize;
            const randomLeft = Math.random() * maxLeft;
            successZone.style.left = randomLeft + 'px';
        } else {
            // All stages done
            sendData('lockpickSuccess');
            closeLockpickUI();
        }
    } else {
        // FAIL — show feedback, notify police called, then close
        showLockpickFeedback('fail', 'Failed! Police have been called!');
        lockpickFrozen = true;
        setTimeout(() => {
            sendData('lockpickFailed');
            closeLockpickUI();
        }, 2000);
    }
}

function closeLockpickUI() {
    stopLockpick();
    document.getElementById('lockpickUI').style.display = 'none';
}

function stopLockpick() {
    lockpickData = null;
    lockpickFrozen = false;
    currentStageNum = 1;
    clearLockpickFeedback();
    document.getElementById('lockpickBar').removeEventListener('mousedown', handleLockpickClick);
}

// ==================== DELIVERY UI ====================

function openDeliveryUI(data) {
    deliveryData = data;
    
    document.getElementById('vehicleName').textContent = data.vehicleLabel;
    document.getElementById('baseValue').textContent = formatMoney(data.vehiclePrice);
    
    const condition = Math.floor(data.conditionPercent);
    const conditionElem = document.getElementById('vehicleCondition');
    conditionElem.textContent = condition + '%';
    
    conditionElem.classList.remove('condition-good', 'condition-fair', 'condition-poor');
    if (condition >= 80) {
        conditionElem.classList.add('condition-good');
    } else if (condition >= 50) {
        conditionElem.classList.add('condition-fair');
    } else {
        conditionElem.classList.add('condition-poor');
    }
    
    const tier = currentTiers.find(t => t.id === data.tierId);
    const keepFee = Math.floor(data.vehiclePrice * tier.keepVehicleFeeMultiplier);
    const sellPayout = Math.floor(data.vehiclePrice * tier.rewardMultiplier * (data.conditionPercent / 100));
    
    document.getElementById('keepFee').textContent = formatMoney(keepFee);
    document.getElementById('sellPayout').textContent = formatMoney(sellPayout);
    
    if (condition < 100) {
        document.getElementById('conditionNote').textContent = '(' + (100 - condition) + '% penalty for damage)';
    } else {
        document.getElementById('conditionNote').textContent = '(Perfect condition bonus!)';
    }
    
    document.getElementById('deliveryUI').style.display = '';
}

document.getElementById('keepVehicleBtn').addEventListener('click', function() {
    sendData('deliverKeep');
    closeAllUIs();
});

document.getElementById('sellVehicleBtn').addEventListener('click', function() {
    sendData('deliverSell');
    closeAllUIs();
});

document.getElementById('closeDeliveryUI').addEventListener('click', function() { closeAllUIs(); });
