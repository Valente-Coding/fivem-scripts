(function() {
    let currentBusiness = null;
    let isOverviewMenu = false;

    // ========================================
    // UTILITIES
    // ========================================

    function formatMoney(amount) {
        return amount.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ',');
    }

    function closeAllScreens() {
        document.getElementById('purchase-screen').style.display = 'none';
        document.getElementById('management-screen').style.display = 'none';
        document.getElementById('business-overview').style.display = 'none';
        document.getElementById('warehouse-screen').style.display = 'none';
        hideError('purchase-error');
        hideError('dirty-money-error');
        hideError('warehouse-error');
        // Reset warehouse button states
        const confirmBtn = document.getElementById('confirm-distribution-btn');
        if (confirmBtn) {
            confirmBtn.disabled = false;
            confirmBtn.textContent = 'Confirm Distribution';
        }
        const withdrawBtn = document.getElementById('withdraw-all-dirty-money-btn');
        if (withdrawBtn) {
            withdrawBtn.disabled = false;
            withdrawBtn.textContent = 'Withdraw All Dirty Money';
        }
    }

    function showError(elementId, message) {
        const el = document.getElementById(elementId);
        if (el) {
            el.textContent = message;
            el.style.display = 'block';
        }
    }

    function hideError(elementId) {
        const el = document.getElementById(elementId);
        if (el) {
            el.style.display = 'none';
        }
    }

    function closeUI() {
        fetch('https://my_business/close', {
            method: 'POST',
            body: JSON.stringify({})
        });
    }

    function roundToFive(n) {
        return Math.round(n / 5) * 5;
    }

    function calculateIncome(price, instance) {
        const baseIncomeMultiplier = 0.01;
        const staffBonus = (instance.staff_level || 0) * 0.002;
        const sizeBonus = (instance.size_level || 0) * 0.003;
        const logisticsBonus = (instance.logistics_level || 0) * 0.002;
        const securityBonus = (instance.security_level || 0) * 0.001;
        const totalMultiplier = baseIncomeMultiplier + staffBonus + sizeBonus + logisticsBonus + securityBonus;
        return roundToFive(Math.floor(price * totalMultiplier));
    }

    // ========================================
    // SCREEN DISPLAYS
    // ========================================

    function displayPurchaseScreen(business) {
        currentBusiness = business;
        closeAllScreens();

        document.getElementById('purchase-business-name').textContent = business.label;
        document.getElementById('purchase-business-description').textContent = business.description;
        document.getElementById('purchase-business-price').textContent = formatMoney(business.price);
        document.getElementById('purchase-business-type').textContent =
            business.type.charAt(0).toUpperCase() + business.type.slice(1);

        const incomeRow = document.querySelector('.business-income');
        if (business.type === 'warehouse') {
            if (incomeRow) incomeRow.style.display = 'none';
        } else {
            if (incomeRow) incomeRow.style.display = 'block';
            const baseIncome = Math.floor(business.price * 0.01);
            document.getElementById('purchase-business-income').textContent = formatMoney(baseIncome);
        }

        document.getElementById('purchase-screen').style.display = 'block';
    }

    function displayManagementScreen(business, income, upgradeInfo, boostedIncome, nextPayoutInfo, normalIncome) {
        currentBusiness = business;
        closeAllScreens();

        document.getElementById('management-business-name').textContent = business.label;
        document.getElementById('management-business-description').textContent = business.description;
        document.getElementById('management-business-type').textContent =
            business.type.charAt(0).toUpperCase() + business.type.slice(1);
        document.getElementById('management-business-price').textContent = formatMoney(business.price);
        document.getElementById('management-business-income').textContent = formatMoney(income);

        // Dirty money info
        document.getElementById('dirty-money-amount').textContent = formatMoney(business.dirty_money || 0);
        document.getElementById('normal-income').textContent = formatMoney(normalIncome);

        const boostInfoElement = document.getElementById('dirty-money-boost-info');
        if (business.dirty_money > 0) {
            boostInfoElement.textContent = nextPayoutInfo || 'Income boosted by dirty money';
            boostInfoElement.style.color = '#76d872';
        } else {
            boostInfoElement.textContent = 'No active boost';
            boostInfoElement.style.color = '#aaa';
        }

        // Upgrade info
        document.getElementById('staff-level').textContent = business.staff_level;
        document.getElementById('staff-max-level').textContent = upgradeInfo.staff.maxLevel;
        document.getElementById('staff-bonus').textContent = upgradeInfo.staff.bonus;
        document.getElementById('staff-cost').textContent = formatMoney(upgradeInfo.staff.cost);

        document.getElementById('size-level').textContent = business.size_level;
        document.getElementById('size-max-level').textContent = upgradeInfo.size.maxLevel;
        document.getElementById('size-bonus').textContent = upgradeInfo.size.bonus;
        document.getElementById('size-cost').textContent = formatMoney(upgradeInfo.size.cost);

        document.getElementById('logistics-level').textContent = business.logistics_level;
        document.getElementById('logistics-max-level').textContent = upgradeInfo.logistics.maxLevel;
        document.getElementById('logistics-bonus').textContent = upgradeInfo.logistics.bonus;
        document.getElementById('logistics-cost').textContent = formatMoney(upgradeInfo.logistics.cost);

        document.getElementById('security-level').textContent = business.security_level;
        document.getElementById('security-max-level').textContent = upgradeInfo.security.maxLevel;
        document.getElementById('security-bonus').textContent = upgradeInfo.security.bonus;
        document.getElementById('security-cost').textContent = formatMoney(upgradeInfo.security.cost);

        // Sell price
        const sellPrice = Math.floor(business.price * 0.9) + (business.money || 0);
        document.getElementById('sell-price').textContent = formatMoney(sellPrice);

        // Disable maxed upgrade buttons
        document.querySelectorAll('.upgrade-btn').forEach(function(button) {
            const type = button.getAttribute('data-type');
            if (business[type + '_level'] >= upgradeInfo[type].maxLevel) {
                button.disabled = true;
            } else {
                button.disabled = false;
            }
        });

        document.getElementById('management-screen').style.display = 'block';
    }

    function displayWarehouseScreen(business) {
        currentBusiness = business;
        closeAllScreens();

        document.getElementById('warehouse-business-name').textContent = business.label;
        document.getElementById('warehouse-business-description').textContent = business.description;

        document.getElementById('distribution-cycles').value = '';
        document.getElementById('warehouse-preview').style.display = 'none';
        document.getElementById('warehouse-error').textContent = '';
        document.getElementById('warehouse-loading').style.display = 'none';

        // Reset button states
        const confirmBtn = document.getElementById('confirm-distribution-btn');
        if (confirmBtn) {
            confirmBtn.disabled = false;
            confirmBtn.textContent = 'Confirm Distribution';
        }
        const withdrawBtn = document.getElementById('withdraw-all-dirty-money-btn');
        if (withdrawBtn) {
            withdrawBtn.disabled = false;
            withdrawBtn.textContent = 'Withdraw All Dirty Money';
        }

        document.getElementById('warehouse-screen').style.display = 'block';
    }

    function displayBusinessOverview(businesses, totalIncome) {
        closeAllScreens();

        document.getElementById('total-income').textContent = formatMoney(totalIncome);

        const businessesList = document.getElementById('businesses-list');
        businessesList.innerHTML = '';

        if (!businesses || Object.keys(businesses).length === 0) {
            const noBusiness = document.createElement('div');
            noBusiness.className = 'no-businesses-message';
            noBusiness.textContent = "You don't own any businesses yet. Go explore the city to find businesses to purchase!";
            businessesList.appendChild(noBusiness);
        } else {
            Object.entries(businesses).forEach(function([businessName, businessData]) {
                const baseData = businessData.business;
                const instanceData = businessData.instance;
                if (!baseData || !instanceData) return;

                const normalIncome = calculateIncome(baseData.price, instanceData);
                const dirtyMoney = instanceData.dirty_money || 0;

                // Calculate actual boosted income (matches what the server pays out)
                let displayIncome = normalIncome;
                if (dirtyMoney > 0) {
                    const maxAdditionalIncome = roundToFive(Math.floor(normalIncome * 0.5));
                    const additionalIncome = Math.min(dirtyMoney, maxAdditionalIncome);
                    displayIncome = normalIncome + additionalIncome;
                }

                let boostInfo = '';
                if (dirtyMoney > 0) {
                    const amountPerCycle = roundToFive(Math.floor(normalIncome * 0.5));
                    const boostPayouts = Math.floor(dirtyMoney / amountPerCycle);
                    const remainderAmount = dirtyMoney % amountPerCycle;

                    if (remainderAmount > 0) {
                        boostInfo = '<div class="business-detail dirty-money-active">' +
                            '<span class="label">Dirty Money:</span>' +
                            '<span class="value">$' + formatMoney(dirtyMoney) + ' (' + boostPayouts + ' full + 1 partial)</span>' +
                            '</div>';
                    } else {
                        boostInfo = '<div class="business-detail dirty-money-active">' +
                            '<span class="label">Dirty Money:</span>' +
                            '<span class="value">$' + formatMoney(dirtyMoney) + ' (' + boostPayouts + ' boosted payments)</span>' +
                            '</div>';
                    }
                } else {
                    boostInfo = '<div class="business-detail">' +
                        '<span class="label">Dirty Money:</span>' +
                        '<span class="value" style="color: #888;">$0 (no boost)</span>' +
                        '</div>';
                }

                const card = document.createElement('div');
                card.className = 'business-card';
                card.innerHTML =
                    '<h3>' + baseData.label + '</h3>' +
                    '<div class="business-detail">' +
                        '<span class="label">Income:</span>' +
                        '<span class="value income">$' + formatMoney(displayIncome) + '/5min</span>' +
                    '</div>' +
                    '<div class="business-detail">' +
                        '<span class="label">Payment:</span>' +
                        '<span class="value">Paid to cash</span>' +
                    '</div>' +
                    boostInfo +
                    '<div class="business-detail">' +
                        '<span class="label">Upgrades:</span>' +
                        '<span class="value">Staff: ' + (instanceData.staff_level || 0) + '/5, Size: ' + (instanceData.size_level || 0) + '/5</span>' +
                    '</div>' +
                    '<div class="business-detail">' +
                        '<span class="label"></span>' +
                        '<span class="value">Logistics: ' + (instanceData.logistics_level || 0) + '/5, Security: ' + (instanceData.security_level || 0) + '/5</span>' +
                    '</div>';

                // Teleport on click (only if NOT overview)
                if (!isOverviewMenu) {
                    card.addEventListener('click', function() {
                        fetch('https://my_business/teleportToBusiness', {
                            method: 'POST',
                            body: JSON.stringify({ name: businessName })
                        });
                    });
                }

                businessesList.appendChild(card);
            });
        }

        document.getElementById('business-overview').style.display = 'block';
    }

    // ========================================
    // DISTRIBUTION PREVIEW
    // ========================================

    function updateDistributionPreview(data) {
        const tbody = document.getElementById('preview-table-body');
        tbody.innerHTML = '';

        if (data.businesses && data.businesses.length > 0) {
            data.businesses.forEach(function(business) {
                const row = document.createElement('tr');
                row.innerHTML =
                    '<td>' + business.label + '</td>' +
                    '<td>$' + formatMoney(business.income) + '</td>' +
                    '<td>$' + formatMoney(business.amountPerCycle) + '</td>' +
                    '<td>$' + formatMoney(business.totalAmount) + '</td>';
                tbody.appendChild(row);
            });
        }

        document.getElementById('total-required').textContent = formatMoney(data.totalRequired);
    }

    // ========================================
    // MESSAGE HANDLER
    // ========================================

    window.addEventListener('message', function(event) {
        const data = event.data;

        if (data.type === 'openPurchase') {
            isOverviewMenu = false;
            displayPurchaseScreen(data.business);
        } else if (data.type === 'openManage') {
            isOverviewMenu = false;
            displayManagementScreen(data.business, data.income, data.upgradeInfo,
                data.boostedIncome, data.nextPayoutInfo, data.normalIncome);
        } else if (data.type === 'openWarehouse') {
            isOverviewMenu = false;
            displayWarehouseScreen(data.business);
        } else if (data.type === 'openOverview') {
            isOverviewMenu = data.isOverview === true;
            displayBusinessOverview(data.businesses, data.totalIncome);
        } else if (data.type === 'close') {
            isOverviewMenu = false;
            closeAllScreens();
        }
        // Error messages from client
        else if (data.type === 'purchaseError') {
            showError('purchase-error', data.message);
        } else if (data.type === 'dirtyMoneyError') {
            showError('dirty-money-error', data.message);
        } else if (data.type === 'warehouseError') {
            showError('warehouse-error', data.message);
        } else if (data.type === 'withdrawAllError') {
            showError('warehouse-error', data.message);
            const btn = document.getElementById('withdraw-all-dirty-money-btn');
            if (btn) {
                btn.disabled = false;
                btn.textContent = 'Withdraw All Dirty Money';
            }
        } else if (data.type === 'distributionPreview') {
            document.getElementById('warehouse-loading').style.display = 'none';
            if (data.data.error) {
                showError('warehouse-error', data.data.error);
                document.getElementById('warehouse-preview').style.display = 'none';
            } else {
                hideError('warehouse-error');
                updateDistributionPreview(data.data);
                document.getElementById('warehouse-preview').style.display = 'block';
            }
        } else if (data.type === 'distributionError') {
            showError('warehouse-error', data.message);
            const btn = document.getElementById('confirm-distribution-btn');
            if (btn) {
                btn.disabled = false;
                btn.textContent = 'Confirm Distribution';
            }
        } else if (data.type === 'distributionSuccess') {
            const btn = document.getElementById('confirm-distribution-btn');
            if (btn) {
                btn.disabled = false;
                btn.textContent = 'Confirm Distribution';
            }
        }
    });

    // ========================================
    // EVENT LISTENERS
    // ========================================

    // Close buttons
    document.addEventListener('click', function(e) {
        if (e.target.classList.contains('close-btn')) {
            e.preventDefault();
            e.stopPropagation();
            closeUI();
        }
    });

    // Purchase with cash
    document.getElementById('purchase-cash').addEventListener('click', function() {
        if (!currentBusiness) return;
        hideError('purchase-error');
        fetch('https://my_business/purchase', {
            method: 'POST',
            body: JSON.stringify({ name: currentBusiness.name })
        });
    });

    // Sell business
    document.getElementById('sell-business-btn').addEventListener('click', function() {
        if (!currentBusiness) return;
        fetch('https://my_business/sell', {
            method: 'POST',
            body: JSON.stringify({ name: currentBusiness.name })
        });
    });

    // Upgrade buttons
    document.querySelectorAll('.upgrade-btn').forEach(function(button) {
        button.addEventListener('click', function() {
            if (!currentBusiness) return;
            const upgradeType = this.getAttribute('data-type');
            fetch('https://my_business/upgrade', {
                method: 'POST',
                body: JSON.stringify({
                    name: currentBusiness.name,
                    upgradeType: upgradeType
                })
            });
        });
    });

    // Deposit dirty money
    document.getElementById('deposit-dirty-money-btn').addEventListener('click', function() {
        const amount = parseInt(document.getElementById('dirty-money-deposit-amount').value);
        if (!amount || amount <= 0 || isNaN(amount)) {
            showError('dirty-money-error', 'Please enter a valid amount');
            return;
        }
        hideError('dirty-money-error');
        fetch('https://my_business/depositDirtyMoney', {
            method: 'POST',
            body: JSON.stringify({
                business: currentBusiness.name,
                amount: amount
            })
        });
    });

    // Withdraw dirty money
    document.getElementById('withdraw-dirty-money-btn').addEventListener('click', function() {
        const amount = parseInt(document.getElementById('dirty-money-deposit-amount').value);
        if (!amount || amount <= 0 || isNaN(amount)) {
            showError('dirty-money-error', 'Please enter a valid amount');
            return;
        }
        hideError('dirty-money-error');
        fetch('https://my_business/withdrawDirtyMoney', {
            method: 'POST',
            body: JSON.stringify({
                business: currentBusiness.name,
                amount: amount
            })
        });
    });

    // Withdraw all dirty money (warehouse)
    document.getElementById('withdraw-all-dirty-money-btn').addEventListener('click', function() {
        this.disabled = true;
        this.textContent = 'Processing...';
        hideError('warehouse-error');
        fetch('https://my_business/withdrawAllDirtyMoney', {
            method: 'POST',
            body: JSON.stringify({})
        });
    });

    // Distribution cycles input - debounced calculation
    let calculationTimeout = null;
    document.getElementById('distribution-cycles').addEventListener('input', function() {
        clearTimeout(calculationTimeout);
        calculationTimeout = setTimeout(function() {
            const cycles = parseInt(document.getElementById('distribution-cycles').value);
            if (isNaN(cycles) || cycles < 1) {
                showError('warehouse-error', 'Please enter a valid number of cycles');
                document.getElementById('warehouse-preview').style.display = 'none';
                return;
            }
            document.getElementById('warehouse-loading').style.display = 'block';
            hideError('warehouse-error');
            document.getElementById('warehouse-preview').style.display = 'none';

            fetch('https://my_business/calculateDistribution', {
                method: 'POST',
                body: JSON.stringify({ cycles: cycles })
            });
        }, 300);
    });

    // Confirm distribution
    document.getElementById('confirm-distribution-btn').addEventListener('click', function() {
        const cycles = parseInt(document.getElementById('distribution-cycles').value);
        if (isNaN(cycles) || cycles < 1) {
            showError('warehouse-error', 'Invalid cycle count');
            return;
        }

        this.disabled = true;
        this.textContent = 'Processing...';
        hideError('warehouse-error');

        fetch('https://my_business/distributeWarehouse', {
            method: 'POST',
            body: JSON.stringify({ cycles: cycles })
        });
    });

    // Keyboard events
    document.addEventListener('keyup', function(event) {
        if (event.key === 'Escape') {
            closeUI();
        }
        if (isOverviewMenu) {
            event.preventDefault();
            event.stopPropagation();
        }
    });

    document.addEventListener('keydown', function(event) {
        if (isOverviewMenu) {
            event.preventDefault();
            event.stopPropagation();
        }
    });
})();
