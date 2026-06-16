document.addEventListener('DOMContentLoaded', function() {
    // Variables
    let playerDirtyMoney = 0;
    let distributorCount = 0;
    let drugInventory = {};
    let currentPaymentMethod = 'dirty';
    // Config values
    let hireCost = 10000;
    let sellInterval = 10;
    let sellAmount = 5;
    let cutPercentage = 20;
    
    const container = document.getElementById('distributor-container');
    
    // Window event listener
    window.addEventListener('message', function(event) {
        let data = event.data;
        
        if (data.action === 'open') {
            container.style.display = 'flex';
            
            updateDistributorData(data.distributors, data.inventory);
            
            playerDirtyMoney = data.playerDirtyMoney || 0;
            document.getElementById('player-black-money').textContent = '$' + playerDirtyMoney.toLocaleString();
            
            hireCost = data.hireCost || 10000;
            sellInterval = data.sellInterval || 10;
            sellAmount = data.sellAmount || 5;
            cutPercentage = data.cutPercentage || 20;
            
            updateConfigValues();

        } else if (data.action === 'close') {
            container.style.display = 'none';
        } else if (data.action === 'update') {
            updateDistributorData(data.distributors, data.inventory);
            
            if (data.playerDirtyMoney !== undefined) {
                playerDirtyMoney = data.playerDirtyMoney;
                document.getElementById('player-black-money').textContent = '$' + playerDirtyMoney.toLocaleString();
            }
            
            if (data.hireCost !== undefined) hireCost = data.hireCost;
            if (data.sellInterval !== undefined) sellInterval = data.sellInterval;
            if (data.sellAmount !== undefined) sellAmount = data.sellAmount;
            if (data.cutPercentage !== undefined) cutPercentage = data.cutPercentage;
            
            updateConfigValues();
        }
    });
    
    function updateDistributorData(count, inventory) {
        distributorCount = count;
        drugInventory = inventory;
        
        document.getElementById('distributor-count').textContent = distributorCount;
        
        for (let drugType in inventory) {
            const amountEl = document.getElementById(drugType + '-amount');
            const profitEl = document.getElementById(drugType + '-profit');
            if (amountEl) amountEl.textContent = inventory[drugType].amount;
            if (profitEl) profitEl.textContent = '$' + inventory[drugType].profit.toLocaleString();
        }
        
        let totalProfit = 0;
        for (let drugType in inventory) {
            totalProfit += inventory[drugType].profit;
        }
        document.getElementById('total-profit').textContent = '$' + totalProfit.toLocaleString();
        
        const fireBtn = document.getElementById('fire-distributor');
        if (distributorCount <= 0) {
            fireBtn.disabled = true;
            fireBtn.classList.add('disabled');
        } else {
            fireBtn.disabled = false;
            fireBtn.classList.remove('disabled');
        }
        
        const withdrawBtn = document.getElementById('withdraw-profits');
        if (totalProfit <= 0) {
            withdrawBtn.disabled = true;
            withdrawBtn.classList.add('disabled');
        } else {
            withdrawBtn.disabled = false;
            withdrawBtn.classList.remove('disabled');
        }
    }
    
    function setPaymentMethod(method) {
        currentPaymentMethod = method;
        document.querySelectorAll('.payment-option').forEach(el => el.classList.remove('active'));
        const active = document.querySelector('.payment-option[data-payment="' + method + '"]');
        if (active) active.classList.add('active');
    }
    
    // Tab switching
    document.querySelectorAll('.tab').forEach(tab => {
        tab.addEventListener('click', function() {
            document.querySelectorAll('.tab').forEach(t => t.classList.remove('active'));
            this.classList.add('active');
            
            const tabId = this.getAttribute('data-tab');
            document.querySelectorAll('.tab-content').forEach(tc => tc.classList.add('hidden'));
            document.getElementById('tab-' + tabId).classList.remove('hidden');
        });
    });
    
    function postNUI(action, data) {
        fetch('https://' + GetParentResourceName() + '/' + action, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(data || {})
        });
    }
    
    function clickEffect(el) {
        el.style.transform = 'scale(0.95)';
        setTimeout(() => { el.style.transform = ''; }, 100);
    }
    
    // Hire distributor
    document.getElementById('hire-distributor').addEventListener('click', function() {
        postNUI('hireDistributor', { paymentMethod: currentPaymentMethod });
        clickEffect(this);
    });
    
    // Fire distributor
    document.getElementById('fire-distributor').addEventListener('click', function() {
        if (distributorCount > 0) {
            postNUI('fireDistributor', {});
            clickEffect(this);
        }
    });
    
    // Deposit All drugs
    document.getElementById('deposit-all-drugs').addEventListener('click', function() {
        postNUI('depositAllDrugs', {});
        clickEffect(this);
    });
    
    // Deposit drugs buttons
    document.querySelectorAll('.deposit-btn').forEach(btn => {
        btn.addEventListener('click', function() {
            const drugType = this.getAttribute('data-drug');
            const input = document.getElementById(drugType + '-deposit-amount');
            const amount = parseInt(input.value) || 1;
            
            if (amount > 0) {
                postNUI('depositDrugs', { drugType: drugType, amount: amount });
                clickEffect(this);
            }
        });
    });
    
    // Withdraw drugs buttons
    document.querySelectorAll('.withdraw-btn:not(#withdraw-profits)').forEach(btn => {
        btn.addEventListener('click', function() {
            const drugType = this.getAttribute('data-drug');
            if (!drugType) return; // skip the withdraw-profits button
            const input = document.getElementById(drugType + '-deposit-amount');
            const amount = parseInt(input.value) || 1;
            
            const inStock = parseInt(document.getElementById(drugType + '-amount').textContent) || 0;
            
            if (amount > 0) {
                if (inStock < amount) {
                    this.classList.add('error');
                    setTimeout(() => { this.classList.remove('error'); }, 500);
                    return;
                }
                
                postNUI('withdrawDrugs', { drugType: drugType, amount: amount });
                clickEffect(this);
            }
        });
    });
    
    // Withdraw profits
    document.getElementById('withdraw-profits').addEventListener('click', function() {
        let totalProfit = 0;
        for (let drugType in drugInventory) {
            totalProfit += drugInventory[drugType].profit;
        }
        
        if (totalProfit > 0) {
            postNUI('withdrawProfit', {});
            clickEffect(this);
        }
    });
    
    // Close menu
    document.getElementById('close-menu').addEventListener('click', function() {
        container.style.display = 'none';
        postNUI('close');
    });
    
    // Close on escape
    document.addEventListener('keyup', function(e) {
        if (e.key === 'Escape') {
            container.style.display = 'none';
            postNUI('close');
        }
    });
    
    function updateConfigValues() {
        const hireBtnSpan = document.querySelector('#hire-distributor span');
        if (hireBtnSpan) hireBtnSpan.textContent = 'Hire Distributor ($' + hireCost.toLocaleString() + ')';
        
        document.querySelectorAll('.config-hire-cost').forEach(el => el.textContent = '$' + hireCost.toLocaleString());
        document.querySelectorAll('.config-sell-amount').forEach(el => el.textContent = sellAmount);
        document.querySelectorAll('.config-sell-interval').forEach(el => el.textContent = Math.round(sellInterval));
        document.querySelectorAll('.config-cut-percentage').forEach(el => el.textContent = cutPercentage + '%');
    }
});
