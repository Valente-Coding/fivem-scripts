// Global variables
let currentTab = 'browse';
let currentVehicleData = null;
let currentOfferVehicle = null;
let currentEditVehicle = null;
let listingLimit = 0;
let browseVehicles = [];
let myListings = [];
let ownedVehicles = [];
let minOfferPercent = 70;

// Pending state for async operations
let pendingEditModel = null;
let pendingSellModel = null;
let currentOffersVehicleId = null;

// Utility function to format currency
function formatCurrency(amount) {
    return '$' + parseInt(amount).toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
}

// Get vehicle image URL from the dealership resource
function getVehicleImageUrl(model) {
    return 'https://cfx-nui-my_dealership/html/images/' + model.toLowerCase() + '.jpg';
}

// Build vehicle image HTML with fallback icon
function buildVehicleImageHtml(model) {
    var imgUrl = getVehicleImageUrl(model);
    return '<div class="vehicle-image-thumb">' +
        '<img src="' + imgUrl + '" alt="' + model + '" onerror="this.style.display=\'none\';this.nextElementSibling.style.display=\'flex\';">' +
        '<div class="vehicle-image-fallback" style="display:none;"><i class="fas fa-car"></i></div>' +
    '</div>';
}

// Utility function to show notification via client
function showNotification(message) {
    fetch('https://my_usedcars/showNotification', {
        method: 'POST',
        headers: {'Content-Type': 'application/json'},
        body: JSON.stringify({message: message})
    });
}

// Initialize event listeners
document.addEventListener('DOMContentLoaded', function() {
    // Close button
    document.getElementById('close-btn').addEventListener('click', closeMenu);

    // Tab buttons
    document.querySelectorAll('.tab-btn').forEach(function(btn) {
        btn.addEventListener('click', function() {
            switchTab(this.dataset.tab);
        });
    });

    // Search and sort
    document.getElementById('search-input').addEventListener('input', filterBrowseVehicles);
    document.getElementById('sort-select').addEventListener('change', sortBrowseVehicles);

    // Modal close buttons
    document.getElementById('modal-close').addEventListener('click', closeVehicleDetailModal);
    document.getElementById('sell-modal-close').addEventListener('click', closeSellModal);
    document.getElementById('offers-modal-close').addEventListener('click', closeOffersModal);
    document.getElementById('edit-price-modal-close').addEventListener('click', closeEditPriceModal);

    // Offer buttons
    document.getElementById('cancel-offer-btn').addEventListener('click', closeVehicleDetailModal);
    document.getElementById('submit-offer-btn').addEventListener('click', submitOffer);

    // Sell buttons
    document.getElementById('cancel-sell-btn').addEventListener('click', closeSellModal);
    document.getElementById('confirm-sell-btn').addEventListener('click', confirmSellVehicle);

    // Price suggestions
    document.querySelectorAll('.suggestion-btn').forEach(function(btn) {
        btn.addEventListener('click', function() {
            var percent = parseInt(this.dataset.percent);
            if (currentVehicleData && currentVehicleData.originalPrice) {
                var suggestedPrice = Math.floor(currentVehicleData.originalPrice * (percent / 100));
                document.getElementById('sell-price-input').value = suggestedPrice;
            }
        });
    });

    // Edit price buttons
    document.getElementById('cancel-edit-price-btn').addEventListener('click', closeEditPriceModal);
    document.getElementById('confirm-edit-price-btn').addEventListener('click', confirmEditPrice);

    // Close modals on background click
    document.querySelectorAll('.modal').forEach(function(modal) {
        modal.addEventListener('click', function(e) {
            if (e.target === this) {
                this.classList.remove('active');
            }
        });
    });
});

// ============================================================
// TAB SWITCHING
// ============================================================

function switchTab(tabName) {
    currentTab = tabName;

    document.querySelectorAll('.tab-btn').forEach(function(btn) {
        btn.classList.remove('active');
    });
    document.querySelector('[data-tab="' + tabName + '"]').classList.add('active');

    document.querySelectorAll('.tab-content').forEach(function(content) {
        content.classList.remove('active');
    });
    document.getElementById(tabName + '-tab').classList.add('active');

    if (tabName === 'browse') {
        loadBrowseVehicles();
    } else if (tabName === 'my-listings') {
        loadMyListings();
    } else if (tabName === 'sell') {
        loadOwnedVehicles();
    }
}

// ============================================================
// BROWSE TAB
// ============================================================

function loadBrowseVehicles() {
    fetch('https://my_usedcars/getUsedCarsForSale', {
        method: 'POST',
        headers: {'Content-Type': 'application/json'},
        body: JSON.stringify({})
    });
    // Data arrives via NUI message 'browseVehiclesData'
}

function renderBrowseVehicles() {
    var grid = document.getElementById('browse-vehicles-grid');
    var noVehicles = document.getElementById('browse-no-vehicles');

    grid.innerHTML = '';

    if (browseVehicles.length === 0) {
        grid.style.display = 'none';
        noVehicles.style.display = 'block';
        return;
    }

    grid.style.display = 'grid';
    noVehicles.style.display = 'none';

    browseVehicles.forEach(function(vehicle) {
        var card = createBrowseVehicleCard(vehicle);
        grid.appendChild(card);
    });
}

function createBrowseVehicleCard(vehicle) {
    var card = document.createElement('div');
    card.className = 'vehicle-card';

    var discount = vehicle.originalPrice ? Math.round((1 - vehicle.price / vehicle.originalPrice) * 100) : 0;
    var discountHtml = discount > 0 ? '<div class="discount-badge">' + discount + '% OFF</div>' : '';
    var label = vehicle.label || vehicle.model;

    card.innerHTML =
        buildVehicleImageHtml(vehicle.model) +
        '<div class="vehicle-info">' +
            '<h3>' + label + '</h3>' +
            '<div class="vehicle-details">' +
                '<div class="detail-item">' +
                    '<span><i class="fas fa-id-card"></i> Plate</span>' +
                    '<span>' + vehicle.plate + '</span>' +
                '</div>' +
                (vehicle.originalPrice ?
                '<div class="detail-item">' +
                    '<span><i class="fas fa-chart-line"></i> Market</span>' +
                    '<span>' + formatCurrency(vehicle.originalPrice) + '</span>' +
                '</div>' : '') +
            '</div>' +
            '<div class="vehicle-price">' + formatCurrency(vehicle.price) + ' ' + discountHtml + '</div>' +
            '<div class="vehicle-actions">' +
                '<button class="action-btn primary" data-vehicle-id="' + vehicle.id + '">' +
                    '<i class="fas fa-info-circle"></i> Details' +
                '</button>' +
            '</div>' +
        '</div>';

    card.querySelector('.action-btn.primary').addEventListener('click', function() {
        openVehicleDetail(vehicle.id);
    });

    return card;
}

function openVehicleDetail(vehicleId) {
    var vehicle = browseVehicles.find(function(v) { return v.id === vehicleId; });
    if (!vehicle) return;

    currentVehicleData = vehicle;

    document.getElementById('modal-vehicle-name').textContent = vehicle.label || vehicle.model;
    
    // Set modal vehicle image
    var modalImg = document.getElementById('modal-vehicle-image');
    if (modalImg) {
        modalImg.src = getVehicleImageUrl(vehicle.model);
        modalImg.style.display = 'block';
        modalImg.onerror = function() {
            this.style.display = 'none';
            document.getElementById('modal-image-fallback').style.display = 'flex';
        };
        document.getElementById('modal-image-fallback').style.display = 'none';
    }
    
    document.getElementById('detail-model').textContent = vehicle.model;
    document.getElementById('detail-plate').textContent = vehicle.plate;
    document.getElementById('detail-price').textContent = formatCurrency(vehicle.price);

    if (vehicle.originalPrice) {
        document.getElementById('detail-market-price').textContent = formatCurrency(vehicle.originalPrice);
        var discount = Math.round((1 - vehicle.price / vehicle.originalPrice) * 100);
        if (discount > 0) {
            document.getElementById('detail-discount').textContent = discount + '% OFF';
            document.getElementById('detail-discount-row').style.display = 'flex';
        } else {
            document.getElementById('detail-discount-row').style.display = 'none';
        }
    } else {
        document.getElementById('detail-market-price').textContent = 'N/A';
        document.getElementById('detail-discount-row').style.display = 'none';
    }

    document.getElementById('offer-amount').value = '';
    document.getElementById('vehicle-detail-modal').classList.add('active');
}

function closeVehicleDetailModal() {
    document.getElementById('vehicle-detail-modal').classList.remove('active');
    currentVehicleData = null;
}

function submitOffer() {
    var offerAmount = parseInt(document.getElementById('offer-amount').value);

    if (!offerAmount || offerAmount <= 0) {
        showNotification('Please enter a valid offer amount');
        return;
    }

    if (!currentVehicleData) return;

    if (currentVehicleData.price) {
        var minimumOffer = Math.floor(currentVehicleData.price * (minOfferPercent / 100));
        if (offerAmount < minimumOffer) {
            showNotification('Offer too low! Minimum offer is ' + formatCurrency(minimumOffer));
            return;
        }
    }

    fetch('https://my_usedcars/makeOffer', {
        method: 'POST',
        headers: {'Content-Type': 'application/json'},
        body: JSON.stringify({
            vehicleId: currentVehicleData.id,
            offerPrice: offerAmount
        })
    });
    // Result arrives via NUI message 'makeOfferResult'
}

function filterBrowseVehicles() {
    var searchTerm = document.getElementById('search-input').value.toLowerCase();
    var filtered = browseVehicles.filter(function(v) {
        var label = (v.label || v.model || '').toLowerCase();
        return label.includes(searchTerm) ||
            v.model.toLowerCase().includes(searchTerm) ||
            v.plate.toLowerCase().includes(searchTerm);
    });

    var grid = document.getElementById('browse-vehicles-grid');
    var noVehicles = document.getElementById('browse-no-vehicles');
    grid.innerHTML = '';

    if (filtered.length === 0) {
        grid.style.display = 'none';
        noVehicles.style.display = 'block';
        return;
    }

    grid.style.display = 'grid';
    noVehicles.style.display = 'none';

    filtered.forEach(function(vehicle) {
        var card = createBrowseVehicleCard(vehicle);
        grid.appendChild(card);
    });
}

function sortBrowseVehicles() {
    var sortBy = document.getElementById('sort-select').value;

    if (sortBy === 'price-asc') {
        browseVehicles.sort(function(a, b) { return a.price - b.price; });
    } else if (sortBy === 'price-desc') {
        browseVehicles.sort(function(a, b) { return b.price - a.price; });
    } else if (sortBy === 'newest') {
        browseVehicles.sort(function(a, b) { return b.id - a.id; });
    }

    renderBrowseVehicles();
}

// ============================================================
// MY LISTINGS TAB
// ============================================================

function loadMyListings() {
    fetch('https://my_usedcars/getPlayerVehicles', {
        method: 'POST',
        headers: {'Content-Type': 'application/json'},
        body: JSON.stringify({})
    });
    // Data arrives via NUI message 'myListingsData'
}

function renderMyListings() {
    var grid = document.getElementById('my-vehicles-grid');
    var noVehicles = document.getElementById('my-no-vehicles');

    document.getElementById('listing-count').textContent = myListings.length;
    document.getElementById('listing-limit').textContent = listingLimit;

    grid.innerHTML = '';

    if (myListings.length === 0) {
        grid.style.display = 'none';
        noVehicles.style.display = 'block';
        return;
    }

    grid.style.display = 'grid';
    noVehicles.style.display = 'none';

    myListings.forEach(function(vehicle) {
        var card = createMyListingCard(vehicle);
        grid.appendChild(card);
    });
}

function createMyListingCard(vehicle) {
    var card = document.createElement('div');
    card.className = 'vehicle-card';
    var label = vehicle.label || vehicle.model;

    card.innerHTML =
        buildVehicleImageHtml(vehicle.model) +
        '<div class="vehicle-info">' +
            '<h3>' + label + '</h3>' +
            '<div class="vehicle-details">' +
                '<div class="detail-item">' +
                    '<span><i class="fas fa-id-card"></i> Plate</span>' +
                    '<span>' + vehicle.plate + '</span>' +
                '</div>' +
            '</div>' +
            '<div class="vehicle-price">' + formatCurrency(vehicle.price) + '</div>' +
            '<div class="vehicle-actions">' +
                '<button class="action-btn primary btn-offers"><i class="fas fa-handshake"></i> Offers</button>' +
                '<button class="action-btn secondary btn-edit"><i class="fas fa-edit"></i> Edit</button>' +
                '<button class="action-btn danger btn-remove"><i class="fas fa-trash"></i> Remove</button>' +
            '</div>' +
        '</div>';

    card.querySelector('.btn-offers').addEventListener('click', function() {
        viewOffers(vehicle.id, label);
    });
    card.querySelector('.btn-edit').addEventListener('click', function() {
        openEditPrice(vehicle.id, vehicle.model, vehicle.price);
    });
    card.querySelector('.btn-remove').addEventListener('click', function() {
        removeVehicle(vehicle.id);
    });

    return card;
}

function viewOffers(vehicleId, vehicleLabel) {
    currentOffersVehicleId = vehicleId;
    document.getElementById('offers-vehicle-name').textContent = vehicleLabel;

    fetch('https://my_usedcars/getVehicleOffers', {
        method: 'POST',
        headers: {'Content-Type': 'application/json'},
        body: JSON.stringify({vehicleId: vehicleId})
    });
    // Data arrives via NUI message 'vehicleOffersData'
    // Modal will be opened when data arrives
}

function renderOffers(offers) {
    var list = document.getElementById('offers-list');
    var noOffers = document.getElementById('no-offers');

    list.innerHTML = '';

    if (offers.length === 0) {
        list.style.display = 'none';
        noOffers.style.display = 'block';
        return;
    }

    list.style.display = 'flex';
    noOffers.style.display = 'none';

    offers.forEach(function(offer) {
        var card = createOfferCard(offer);
        list.appendChild(card);
    });
}

function createOfferCard(offer) {
    var card = document.createElement('div');
    card.className = 'offer-card';

    var genderIcon = offer.gender === 'male' ? 'fa-male' : 'fa-female';

    card.innerHTML =
        '<div class="offer-header">' +
            '<div class="buyer-name"><i class="fas ' + genderIcon + '"></i> ' + offer.buyer_name + '</div>' +
            '<div class="offer-price">' + formatCurrency(offer.offer_price) + '</div>' +
        '</div>' +
        '<div class="offer-actions">' +
            '<button class="action-btn success btn-accept"><i class="fas fa-check"></i> Accept</button>' +
            '<button class="action-btn danger btn-reject"><i class="fas fa-times"></i> Reject</button>' +
        '</div>';

    card.querySelector('.btn-accept').addEventListener('click', function() {
        acceptOffer(offer.vehicleId, offer.id);
    });
    card.querySelector('.btn-reject').addEventListener('click', function() {
        rejectOffer(offer.vehicleId, offer.id);
    });

    return card;
}

function acceptOffer(vehicleId, offerId) {
    var vehicle = myListings.find(function(v) { return v.id === vehicleId; });
    if (!vehicle) return;

    // Need to get the offer details - we already have them rendered
    // Re-fetch offers to get the full data
    fetch('https://my_usedcars/getVehicleOffers', {
        method: 'POST',
        headers: {'Content-Type': 'application/json'},
        body: JSON.stringify({vehicleId: vehicleId})
    });

    // Store pending accept data
    window._pendingAccept = { vehicleId: vehicleId, offerId: offerId, vehicle: vehicle };
}

function rejectOffer(vehicleId, offerId) {
    fetch('https://my_usedcars/rejectOffer', {
        method: 'POST',
        headers: {'Content-Type': 'application/json'},
        body: JSON.stringify({
            vehicleId: vehicleId,
            offerId: offerId
        })
    });
    // Result arrives via NUI message 'rejectOfferResult'
}

function closeOffersModal() {
    document.getElementById('offers-modal').classList.remove('active');
    currentOfferVehicle = null;
    currentOffersVehicleId = null;
}

// ============================================================
// EDIT PRICE
// ============================================================

function openEditPrice(vehicleId, vehicleModel, currentPrice) {
    currentEditVehicle = vehicleId;
    pendingEditModel = vehicleModel;

    document.getElementById('edit-current-price').textContent = formatCurrency(currentPrice);
    document.getElementById('edit-price-input').value = currentPrice;

    // Request original price from server
    fetch('https://my_usedcars/getVehicleOriginalPrice', {
        method: 'POST',
        headers: {'Content-Type': 'application/json'},
        body: JSON.stringify({model: vehicleModel})
    });

    // Show modal immediately, price will be updated via message
    document.getElementById('edit-original-price').textContent = 'Loading...';
    document.getElementById('edit-price-modal').classList.add('active');
}

function closeEditPriceModal() {
    document.getElementById('edit-price-modal').classList.remove('active');
    currentEditVehicle = null;
    pendingEditModel = null;
}

function confirmEditPrice() {
    var newPrice = parseInt(document.getElementById('edit-price-input').value);

    if (!newPrice || newPrice <= 0) {
        showNotification('Please enter a valid price');
        return;
    }

    fetch('https://my_usedcars/updateVehiclePrice', {
        method: 'POST',
        headers: {'Content-Type': 'application/json'},
        body: JSON.stringify({
            vehicleId: currentEditVehicle,
            newPrice: newPrice
        })
    });
    // Result arrives via NUI message 'updatePriceResult'
}

// ============================================================
// REMOVE VEHICLE
// ============================================================

function removeVehicle(vehicleId) {
    fetch('https://my_usedcars/removeVehicle', {
        method: 'POST',
        headers: {'Content-Type': 'application/json'},
        body: JSON.stringify({vehicleId: vehicleId})
    });
    // Result arrives via NUI message 'removeListingResult'
}

// ============================================================
// SELL TAB (Owned Vehicles)
// ============================================================

function loadOwnedVehicles() {
    fetch('https://my_usedcars/getPlayerOwnedVehicles', {
        method: 'POST',
        headers: {'Content-Type': 'application/json'},
        body: JSON.stringify({})
    });
    // Data arrives via NUI message 'ownedVehiclesData'
}

function renderOwnedVehicles() {
    var grid = document.getElementById('owned-vehicles-grid');
    var noVehicles = document.getElementById('owned-no-vehicles');

    grid.innerHTML = '';

    if (ownedVehicles.length === 0) {
        grid.style.display = 'none';
        noVehicles.style.display = 'block';
        return;
    }

    grid.style.display = 'grid';
    noVehicles.style.display = 'none';

    ownedVehicles.forEach(function(vehicle) {
        var card = createOwnedVehicleCard(vehicle);
        grid.appendChild(card);
    });
}

function createOwnedVehicleCard(vehicle) {
    var card = document.createElement('div');
    card.className = 'vehicle-card';
    var label = vehicle.label || vehicle.model;

    card.innerHTML =
        buildVehicleImageHtml(vehicle.model) +
        '<div class="vehicle-info">' +
            '<h3>' + label + '</h3>' +
            '<div class="vehicle-details">' +
                '<div class="detail-item">' +
                    '<span><i class="fas fa-id-card"></i> Plate</span>' +
                    '<span>' + vehicle.plate + '</span>' +
                '</div>' +
            '</div>' +
            '<div class="vehicle-actions">' +
                '<button class="action-btn success btn-sell"><i class="fas fa-dollar-sign"></i> Sell Vehicle</button>' +
            '</div>' +
        '</div>';

    card.querySelector('.btn-sell').addEventListener('click', function() {
        openSellModal(vehicle.model, vehicle.plate);
    });

    return card;
}

function openSellModal(model, plate) {
    var vehicle = ownedVehicles.find(function(v) { return v.plate === plate; });
    if (!vehicle) return;

    currentVehicleData = vehicle;
    pendingSellModel = model;

    document.getElementById('sell-modal-vehicle-name').textContent = 'List your vehicle for Sale';
    document.getElementById('sell-detail-model').textContent = vehicle.label || vehicle.model;
    document.getElementById('sell-detail-plate').textContent = plate;
    document.getElementById('sell-price-input').value = '';

    // Request original price
    document.getElementById('sell-detail-market-price').textContent = 'Loading...';
    fetch('https://my_usedcars/getVehicleOriginalPrice', {
        method: 'POST',
        headers: {'Content-Type': 'application/json'},
        body: JSON.stringify({model: model})
    });

    document.getElementById('sell-vehicle-modal').classList.add('active');
}

function closeSellModal() {
    document.getElementById('sell-vehicle-modal').classList.remove('active');
    currentVehicleData = null;
    pendingSellModel = null;
}

function confirmSellVehicle() {
    var price = parseInt(document.getElementById('sell-price-input').value);

    if (!price || price <= 0) {
        showNotification('Please enter a valid price');
        return;
    }

    if (!currentVehicleData) return;

    fetch('https://my_usedcars/addVehicleToSaleList', {
        method: 'POST',
        headers: {'Content-Type': 'application/json'},
        body: JSON.stringify({
            vehicle: currentVehicleData,
            price: price
        })
    });
    // Result arrives via NUI message 'addListingResult'
}

// ============================================================
// CLOSE MENU
// ============================================================

function closeMenu() {
    document.getElementById('usedcars-container').style.display = 'none';
    fetch('https://my_usedcars/closeMenu', {
        method: 'POST',
        headers: {'Content-Type': 'application/json'},
        body: JSON.stringify({})
    });
}

// ============================================================
// NUI MESSAGE HANDLER (async responses from server via client)
// ============================================================

window.addEventListener('message', function(event) {
    var data = event.data;

    if (data.action === 'openMenu') {
        if (data.minOfferPercent) {
            minOfferPercent = data.minOfferPercent;
        }
        document.getElementById('usedcars-container').style.display = 'flex';
        switchTab('browse');

    } else if (data.action === 'closeMenu') {
        document.getElementById('usedcars-container').style.display = 'none';

    } else if (data.action === 'browseVehiclesData') {
        browseVehicles = data.vehicles || [];
        sortBrowseVehicles();

    } else if (data.action === 'myListingsData') {
        myListings = data.vehicles || [];
        listingLimit = data.postLimit || 0;
        renderMyListings();

    } else if (data.action === 'ownedVehiclesData') {
        ownedVehicles = data.vehicles || [];
        renderOwnedVehicles();

    } else if (data.action === 'vehicleOffersData') {
        var offers = data.offers || [];

        // Check if we have a pending accept
        if (window._pendingAccept && window._pendingAccept.vehicleId === currentOffersVehicleId) {
            var pa = window._pendingAccept;
            var offer = offers.find(function(o) { return o.id === pa.offerId; });
            if (offer) {
                // Schedule meeting with this offer
                fetch('https://my_usedcars/scheduleMeeting', {
                    method: 'POST',
                    headers: {'Content-Type': 'application/json'},
                    body: JSON.stringify({
                        vehicle: pa.vehicle,
                        offer: offer
                    })
                });
                closeOffersModal();
                closeMenu();
                window._pendingAccept = null;
                return;
            }
            window._pendingAccept = null;
        }

        // Normal offer display
        renderOffers(offers);
        document.getElementById('offers-modal').classList.add('active');

    } else if (data.action === 'addListingResult') {
        if (data.success) {
            showNotification('Vehicle listed for sale successfully!');
            closeSellModal();
            loadOwnedVehicles();
        } else {
            if (data.errorCode === 'limit_reached') {
                showNotification('You have reached your listing limit. Get a license for more slots!');
            } else {
                showNotification('Failed to list vehicle for sale');
            }
        }

    } else if (data.action === 'updatePriceResult') {
        if (data.success) {
            showNotification('Price updated successfully');
            closeEditPriceModal();
            loadMyListings();
        } else {
            showNotification('Failed to update price');
        }

    } else if (data.action === 'removeListingResult') {
        if (data.success) {
            showNotification('Vehicle removed from listings');
            loadMyListings();
        } else {
            showNotification('Failed to remove vehicle');
        }

    } else if (data.action === 'makeOfferResult') {
        if (data.success) {
            showNotification('Your offer has been submitted!');
            closeVehicleDetailModal();
        } else {
            if (data.error === 'insufficient_funds') {
                showNotification('You do not have enough money for this offer');
            } else {
                showNotification('Failed to submit offer');
            }
        }

    } else if (data.action === 'rejectOfferResult') {
        if (data.success) {
            showNotification('Offer rejected');
            // Reload offers for the current vehicle
            if (currentOffersVehicleId) {
                fetch('https://my_usedcars/getVehicleOffers', {
                    method: 'POST',
                    headers: {'Content-Type': 'application/json'},
                    body: JSON.stringify({vehicleId: currentOffersVehicleId})
                });
            }
        }

    } else if (data.action === 'vehiclePriceData') {
        // Update any open modal that requested price data
        if (document.getElementById('edit-price-modal').classList.contains('active')) {
            if (data.originalPrice) {
                document.getElementById('edit-original-price').textContent = formatCurrency(data.originalPrice);
            } else {
                document.getElementById('edit-original-price').textContent = 'N/A';
            }
        }

        if (document.getElementById('sell-vehicle-modal').classList.contains('active')) {
            if (data.originalPrice) {
                if (currentVehicleData) {
                    currentVehicleData.originalPrice = data.originalPrice;
                }
                document.getElementById('sell-detail-market-price').textContent = formatCurrency(data.originalPrice);
            } else {
                document.getElementById('sell-detail-market-price').textContent = 'N/A';
            }
        }
    }
});

// ESC key to close
document.addEventListener('keydown', function(event) {
    if (event.key === 'Escape') {
        closeMenu();
    }
});
