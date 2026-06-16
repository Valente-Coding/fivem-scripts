// Stock Market UI Script
// No jQuery - vanilla JS only

var stockData = [];
var portfolioData = [];
var sectorColors = {};
var cashMoney = 0;
var selectedCompany = null;
var priceChart = null;

// NUI Message listener
window.addEventListener('message', function(event) {
    var data = event.data;

    if (data.action === 'open') {
        stockData = data.stocks || [];
        portfolioData = data.portfolio || [];
        sectorColors = data.sectorColors || {};
        cashMoney = data.cashMoney || 0;

        document.getElementById('stock-container').style.display = 'flex';
        updateHeader();
        renderSectorList();
        renderPortfolio();
    } else if (data.action === 'updateData') {
        stockData = data.stocks || stockData;
        portfolioData = data.portfolio || portfolioData;
        if (data.cashMoney !== undefined) cashMoney = data.cashMoney;

        updateHeader();
        renderSectorList();
        renderPortfolio();

        if (selectedCompany) {
            var updatedCompany = stockData.find(function(c) { return c.id === selectedCompany.id; });
            if (updatedCompany) {
                selectedCompany = updatedCompany;
                document.getElementById('selected-price').textContent = '$' + formatMoney(updatedCompany.current_price);
                updateTotalCost();
            }
        }
    } else if (data.action === 'close') {
        closeUI();
    } else if (data.action === 'priceHistory') {
        renderPriceChart(data.history || []);
    }
});

// Close UI
function closeUI() {
    document.getElementById('stock-container').style.display = 'none';
    fetch('https://my_stocks/close', {
        method: 'POST',
        body: JSON.stringify({})
    });
}

// Update header stats
function updateHeader() {
    document.getElementById('cash-balance').textContent = '$' + formatMoney(cashMoney);

    var totalValue = 0;
    var totalInvested = 0;
    var totalDividends = 0;

    portfolioData.forEach(function(stock) {
        totalValue += stock.shares_owned * stock.current_price;
        totalInvested += stock.total_invested;
        totalDividends += stock.shares_owned * stock.dividend_per_share;
    });

    document.getElementById('portfolio-value').textContent = '$' + formatMoney(totalValue);

    var roi = totalInvested > 0 ? ((totalValue - totalInvested) / totalInvested) * 100 : 0;
    var roiElement = document.getElementById('total-roi');
    roiElement.textContent = formatPercent(roi);
    roiElement.style.color = roi >= 0 ? '#00ff88' : '#ff4757';

    document.getElementById('dividend-income').textContent = '$' + formatMoney(totalDividends);
}

// Render sector list
function renderSectorList() {
    var sectorList = document.getElementById('sector-list');
    sectorList.innerHTML = '';

    var sectors = {};
    stockData.forEach(function(company) {
        if (!sectors[company.sector]) {
            sectors[company.sector] = [];
        }
        sectors[company.sector].push(company);
    });

    Object.keys(sectors).forEach(function(sectorName) {
        var sectorColor = sectorColors[sectorName] || '#ffffff';
        var companies = sectors[sectorName];

        var sectorGroup = document.createElement('div');
        sectorGroup.className = 'sector-group';

        var sectorHeader = document.createElement('div');
        sectorHeader.className = 'sector-header';
        sectorHeader.style.background = 'linear-gradient(90deg, ' + sectorColor + '20 0%, transparent 100%)';
        sectorHeader.style.borderLeft = '3px solid ' + sectorColor;
        sectorHeader.innerHTML = '<span style="color: ' + sectorColor + '">' + sectorName + '</span><span class="sector-arrow">\u25BC</span>';

        sectorHeader.addEventListener('click', function() {
            sectorGroup.classList.toggle('collapsed');
        });

        var companyList = document.createElement('div');
        companyList.className = 'company-list';

        companies.forEach(function(company) {
            var card = createCompanyCard(company);
            companyList.appendChild(card);
        });

        sectorGroup.appendChild(sectorHeader);
        sectorGroup.appendChild(companyList);
        sectorList.appendChild(sectorGroup);
    });
}

// Create company card
function createCompanyCard(company) {
    var card = document.createElement('div');
    card.className = 'company-card';
    card.setAttribute('data-company-id', company.id);

    card.innerHTML =
        '<div class="company-card-header">' +
            '<span class="company-ticker">' + company.ticker + '</span>' +
            '<span class="company-price">$' + formatMoney(company.current_price) + '</span>' +
        '</div>' +
        '<div class="company-name">' + company.name + '</div>' +
        '<div class="company-card-footer">' +
            '<span class="dividend-badge">$' + formatMoney(company.dividend_per_share) + '/share</span>' +
        '</div>';

    card.addEventListener('click', function() {
        document.querySelectorAll('.company-card').forEach(function(c) {
            c.classList.remove('selected');
        });
        card.classList.add('selected');
        selectCompany(company);
    });

    return card;
}

// Select company and show details
function selectCompany(company) {
    selectedCompany = company;

    document.getElementById('placeholder').style.display = 'none';
    document.getElementById('company-details').style.display = 'flex';

    document.getElementById('selected-company-name').textContent = company.name;
    document.getElementById('selected-ticker').textContent = company.ticker;

    var sectorTag = document.getElementById('selected-sector');
    sectorTag.textContent = company.sector;
    var sectorColor = sectorColors[company.sector] || '#ffffff';
    sectorTag.style.background = sectorColor + '20';
    sectorTag.style.borderColor = sectorColor;
    sectorTag.style.color = sectorColor;

    document.getElementById('selected-price').textContent = '$' + formatMoney(company.current_price);

    document.getElementById('dividend-value').textContent = '$' + formatMoney(company.dividend_per_share);
    var availableShares = company.max_shares - company.shares_sold;
    document.getElementById('available-shares').textContent = formatNumber(availableShares);

    var ownedStock = portfolioData.find(function(p) { return p.company_id === company.id; });
    var ownedShares = ownedStock ? ownedStock.shares_owned : 0;
    document.getElementById('owned-shares').textContent = formatNumber(ownedShares);

    var slider = document.getElementById('share-slider');
    slider.max = Math.max(1, availableShares);
    document.getElementById('share-quantity').max = availableShares;

    slider.value = 1;
    document.getElementById('share-quantity').value = 1;
    updateTotalCost();

    // Load price history
    fetch('https://my_stocks/getPriceHistory', {
        method: 'POST',
        body: JSON.stringify({ companyId: company.id })
    });
}

// Render price chart
function renderPriceChart(history) {
    var ctx = document.getElementById('price-chart').getContext('2d');

    if (priceChart) {
        priceChart.destroy();
    }

    var labels = [];
    var prices = [];

    if (history && history.length > 0) {
        history.forEach(function(record) {
            var date = new Date(record.timestamp * 1000);
            labels.push(date.toLocaleTimeString([], {hour: '2-digit', minute: '2-digit'}));
            prices.push(parseFloat(record.price));
        });
    } else {
        labels = ['Now'];
        prices = [selectedCompany ? selectedCompany.current_price : 0];
    }

    var gradient = ctx.createLinearGradient(0, 0, 0, 300);
    gradient.addColorStop(0, 'rgba(0, 212, 255, 0.3)');
    gradient.addColorStop(1, 'rgba(0, 212, 255, 0)');

    priceChart = new Chart(ctx, {
        type: 'line',
        data: {
            labels: labels,
            datasets: [{
                label: 'Price',
                data: prices,
                borderColor: '#00d4ff',
                backgroundColor: gradient,
                borderWidth: 2,
                fill: true,
                tension: 0.4,
                pointRadius: 3,
                pointBackgroundColor: '#00d4ff',
                pointBorderColor: '#ffffff',
                pointBorderWidth: 2
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: {
                legend: { display: false },
                tooltip: {
                    mode: 'index',
                    intersect: false,
                    backgroundColor: 'rgba(15, 15, 30, 0.9)',
                    titleColor: '#00d4ff',
                    bodyColor: '#ffffff',
                    borderColor: '#00d4ff',
                    borderWidth: 1,
                    padding: 12,
                    displayColors: false,
                    callbacks: {
                        label: function(context) {
                            return '$' + formatMoney(context.parsed.y);
                        }
                    }
                }
            },
            scales: {
                y: {
                    grid: { color: 'rgba(255, 255, 255, 0.1)', drawBorder: false },
                    ticks: {
                        color: 'rgba(255, 255, 255, 0.6)',
                        callback: function(value) { return '$' + formatMoney(value); }
                    }
                },
                x: {
                    grid: { display: false },
                    ticks: { color: 'rgba(255, 255, 255, 0.6)', maxRotation: 45, minRotation: 45 }
                }
            },
            interaction: { mode: 'nearest', axis: 'x', intersect: false }
        }
    });
}

// Render portfolio table
function renderPortfolio() {
    var tbody = document.getElementById('portfolio-tbody');
    tbody.innerHTML = '';

    if (portfolioData.length === 0) {
        tbody.innerHTML = '<tr class="empty-portfolio"><td colspan="5">No investments yet</td></tr>';
        document.getElementById('best-performer').textContent = '---';
        document.getElementById('worst-performer').textContent = '---';
        return;
    }

    var bestPerformer = null;
    var worstPerformer = null;
    var bestROI = -Infinity;
    var worstROI = Infinity;

    portfolioData.forEach(function(stock) {
        var currentValue = stock.shares_owned * stock.current_price;
        var avgCost = stock.total_invested / stock.shares_owned;
        var profitLoss = ((currentValue - stock.total_invested) / stock.total_invested) * 100;

        var plClass = profitLoss >= 0 ? 'positive' : 'negative';
        var plSymbol = profitLoss >= 0 ? '\u25B2' : '\u25BC';

        var row = document.createElement('tr');
        row.innerHTML =
            '<td><strong>' + stock.ticker + '</strong></td>' +
            '<td>' + formatNumber(stock.shares_owned) + '</td>' +
            '<td>$' + formatMoney(avgCost) + '</td>' +
            '<td>$' + formatMoney(currentValue) + '</td>' +
            '<td class="price-change ' + plClass + '">' + plSymbol + ' ' + Math.abs(profitLoss).toFixed(2) + '%</td>';

        tbody.appendChild(row);

        if (profitLoss > bestROI) {
            bestROI = profitLoss;
            bestPerformer = stock.ticker + ' ' + plSymbol + ' ' + profitLoss.toFixed(2) + '%';
        }
        if (profitLoss < worstROI) {
            worstROI = profitLoss;
            var wsymbol = profitLoss >= 0 ? '\u25B2' : '\u25BC';
            worstPerformer = stock.ticker + ' ' + wsymbol + ' ' + Math.abs(profitLoss).toFixed(2) + '%';
        }
    });

    var bestEl = document.getElementById('best-performer');
    bestEl.textContent = bestPerformer || '---';
    bestEl.style.color = bestROI >= 0 ? '#00ff88' : '#ff4757';

    var worstEl = document.getElementById('worst-performer');
    worstEl.textContent = worstPerformer || '---';
    worstEl.style.color = worstROI >= 0 ? '#00ff88' : '#ff4757';
}

// Update total cost
function updateTotalCost() {
    if (!selectedCompany) return;
    var quantity = parseInt(document.getElementById('share-quantity').value) || 0;
    var total = quantity * selectedCompany.current_price;
    document.getElementById('total-cost').textContent = '$' + formatMoney(total);
}

// Event listeners
document.addEventListener('DOMContentLoaded', function() {
    document.getElementById('close-btn').addEventListener('click', closeUI);

    document.getElementById('refresh-btn').addEventListener('click', function() {
        fetch('https://my_stocks/refreshData', {
            method: 'POST',
            body: JSON.stringify({})
        });
    });

    document.getElementById('share-slider').addEventListener('input', function() {
        document.getElementById('share-quantity').value = this.value;
        updateTotalCost();
    });

    document.getElementById('share-quantity').addEventListener('input', function() {
        var max = parseInt(this.max) || 100;
        var val = Math.max(1, Math.min(parseInt(this.value) || 1, max));
        this.value = val;
        document.getElementById('share-slider').value = val;
        updateTotalCost();
    });

    document.getElementById('buy-btn').addEventListener('click', function() {
        if (!selectedCompany) return;
        var shares = parseInt(document.getElementById('share-quantity').value);
        fetch('https://my_stocks/buyShares', {
            method: 'POST',
            body: JSON.stringify({
                companyId: selectedCompany.id,
                shares: shares
            })
        });
    });

    document.getElementById('sell-btn').addEventListener('click', function() {
        if (!selectedCompany) return;
        var shares = parseInt(document.getElementById('share-quantity').value);
        fetch('https://my_stocks/sellShares', {
            method: 'POST',
            body: JSON.stringify({
                companyId: selectedCompany.id,
                shares: shares
            })
        });
    });

    document.addEventListener('keyup', function(e) {
        if (e.key === 'Escape') {
            closeUI();
        }
    });
});

// Utility functions
function formatMoney(value) {
    return parseFloat(value).toLocaleString('en-US', {
        minimumFractionDigits: 2,
        maximumFractionDigits: 2
    });
}

function formatNumber(value) {
    return parseInt(value).toLocaleString('en-US');
}

function formatPercent(value) {
    var sign = value >= 0 ? '+' : '';
    return sign + value.toFixed(2) + '%';
}

// Auto-refresh prices every 10 seconds
setInterval(function() {
    var container = document.getElementById('stock-container');
    if (container && container.style.display !== 'none') {
        fetch('https://my_stocks/refreshData', {
            method: 'POST',
            body: JSON.stringify({})
        });
    }
}, 10000);
