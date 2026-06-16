/* ===============================================
   VEHICLE DEALERSHIP NUI - SCRIPT.JS
   Custom FiveM Framework - BareBones
   =============================================== */

// ===============================================
// STATE MANAGEMENT
// ===============================================

let currentVehicles = [];
let selectedVehicle = null;
let isPurchasing = false;

// Category state
let activeCategory = 'All';
let categoryData = [];
let filteredVehicles = [];

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
        : 'my_dealership';
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
 * @returns {string} Formatted price (e.g., $50,000)
 */
function formatPrice(price) {
    if (typeof price !== 'number') {
        price = 0;
    }
    return '$' + price.toLocaleString('en-US');
}

/**
 * Build category data from vehicles array
 * @param {Array} vehicles - Array of vehicle objects
 * @returns {Array} Array of {name, count} objects
 */
function buildCategoryData(vehicles) {
    if (!Array.isArray(vehicles) || vehicles.length === 0) {
        return [{ name: 'All', count: 0 }];
    }
    
    // Extract unique categories
    const uniqueCategories = [...new Set(vehicles.map(v => v.category || 'Unknown'))];
    
    // Build category objects with counts
    const categories = uniqueCategories.sort().map(cat => ({
        name: cat,
        count: vehicles.filter(v => (v.category || 'Unknown') === cat).length
    }));
    
    // Add "All" category at start
    categories.unshift({
        name: 'All',
        count: vehicles.length
    });
    
    return categories;
}

/**
 * Render category tabs
 * @param {Array} categories - Array of category objects
 */
function renderCategoryTabs(categories) {
    const tabsContainer = document.getElementById('category-tabs');
    if (!tabsContainer) return;
    
    tabsContainer.innerHTML = '';
    
    categories.forEach(cat => {
        const tab = document.createElement('button');
        tab.className = 'category-tab';
        tab.dataset.category = cat.name;
        tab.textContent = `${cat.name} (${cat.count})`;
        
        // Set active state
        if (cat.name === activeCategory) {
            tab.classList.add('active');
        }
        
        // Disable if empty (optional)
        if (cat.count === 0) {
            tab.classList.add('disabled');
            tab.disabled = true;
        }
        
        // Click handler
        tab.addEventListener('click', () => {
            if (cat.count > 0) {
                selectCategory(cat.name);
            }
        });
        
        tabsContainer.appendChild(tab);
    });
}

/**
 * Select a category and filter vehicles
 * @param {string} categoryName - Category to select
 */
function selectCategory(categoryName) {
    activeCategory = categoryName;
    
    // Filter vehicles
    if (categoryName === 'All') {
        filteredVehicles = [...currentVehicles];
    } else {
        filteredVehicles = currentVehicles.filter(v => 
            (v.category || 'Unknown') === categoryName
        );
    }
    
    // Update UI
    renderCategoryTabs(categoryData);
    renderVehicleList(filteredVehicles);
    updatePanelLabel(filteredVehicles.length);
    
    // Auto-select first vehicle
    if (filteredVehicles.length > 0) {
        selectVehicle(filteredVehicles[0]);
    } else {
        showNoSelection();
    }
}

/**
 * Update panel label with vehicle count
 * @param {number} count - Number of vehicles
 */
function updatePanelLabel(count) {
    const label = document.querySelector('.vehicle-list-panel .panel-label');
    if (label) {
        label.textContent = `AVAILABLE VEHICLES (${count})`;
    }
}

// ===============================================
// UI FUNCTIONS
// ===============================================

/**
 * Open the dealership UI
 * @param {Array} vehicles - Array of vehicle objects
 */
function openUI(vehicles) {
    // Validate input
    if (!Array.isArray(vehicles)) {
        console.error('[Dealership] Invalid vehicles data');
        vehicles = [];
    }
    
    // Store vehicles
    currentVehicles = vehicles;
    
    // Build and render categories
    categoryData = buildCategoryData(vehicles);
    renderCategoryTabs(categoryData);
    
    // Default to "All" category
    activeCategory = 'All';
    filteredVehicles = [...vehicles];
    
    // Clear any previous feedback
    hideFeedback();
    
    // Render vehicle list (filtered)
    renderVehicleList(filteredVehicles);
    updatePanelLabel(filteredVehicles.length);
    
    // Auto-select first vehicle
    if (filteredVehicles.length > 0) {
        selectVehicle(filteredVehicles[0]);
    } else {
        // Show empty state in details panel
        showNoSelection();
    }
    
    // Show container with animation
    const container = document.getElementById('dealership-container');
    container.style.display = 'flex';
    container.classList.remove('closing');
    
    // Reset purchase state
    isPurchasing = false;
}

/**
 * Close the dealership UI
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
    selectedVehicle = null;
    currentVehicles = [];
    isPurchasing = false;
    
    // Hide feedback
    hideFeedback();
}

/**
 * Render the vehicle list in the left panel
 * @param {Array} vehicles - Array of vehicle objects
 */
function renderVehicleList(vehicles) {
    const vehicleList = document.getElementById('vehicle-list');
    
    // Clear existing content
    vehicleList.innerHTML = '';
    
    // Check if vehicles array is empty
    if (!vehicles || vehicles.length === 0) {
        const emptyState = document.createElement('div');
        emptyState.className = 'empty-state';
        emptyState.textContent = 'No vehicles available';
        vehicleList.appendChild(emptyState);
        return;
    }
    
    // Create vehicle items
    vehicles.forEach((vehicle, index) => {
        const item = createVehicleItem(vehicle, index);
        vehicleList.appendChild(item);
    });
}

/**
 * Create a vehicle item element
 * @param {object} vehicle - Vehicle data
 * @param {number} index - Vehicle index
 * @returns {HTMLElement} Vehicle item element
 */
function createVehicleItem(vehicle, index) {
    const item = document.createElement('div');
    item.className = 'vehicle-item';
    item.dataset.model = vehicle.model;
    item.dataset.price = vehicle.price;
    item.dataset.category = vehicle.category;
    item.dataset.index = index;
    
    // Vehicle header (name + price)
    const header = document.createElement('div');
    header.className = 'vehicle-header';
    
    const name = document.createElement('span');
    name.className = 'vehicle-name';
    name.textContent = vehicle.name || vehicle.model;
    
    const price = document.createElement('span');
    price.className = 'vehicle-price';
    price.textContent = formatPrice(vehicle.price);
    
    header.appendChild(name);
    header.appendChild(price);
    
    // Vehicle category
    const category = document.createElement('div');
    category.className = 'vehicle-category';
    category.textContent = vehicle.category || 'Unknown';
    
    // Assemble item
    item.appendChild(header);
    item.appendChild(category);
    
    // Add click event
    item.addEventListener('click', () => {
        selectVehicle(vehicle);
    });
    
    return item;
}

/**
 * Select a vehicle and update the details panel
 * @param {object} vehicle - Vehicle data
 */
function selectVehicle(vehicle) {
    // Store selected vehicle
    selectedVehicle = vehicle;
    
    // Update UI - remove selected class from all items
    const allItems = document.querySelectorAll('.vehicle-item');
    allItems.forEach(item => item.classList.remove('selected'));
    
    // Add selected class to clicked item
    const selectedItem = document.querySelector(`.vehicle-item[data-model="${vehicle.model}"]`);
    if (selectedItem) {
        selectedItem.classList.add('selected');
    }
    
    // Update details panel
    renderDetailsPanel(vehicle);
}

/**
 * Render the vehicle details panel (right side)
 * @param {object} vehicle - Vehicle data
 */
function renderDetailsPanel(vehicle) {
    const detailsContent = document.getElementById('details-content');
    
    const imagePath = `images/${vehicle.model}.jpg`;
    
    // Build details HTML
    detailsContent.innerHTML = `
        <div class="vehicle-image-container">
            <img class="vehicle-image" id="vehicle-image" 
                 src="${imagePath}" 
                 alt="${vehicle.name || vehicle.model}" />
        </div>
        
        <h2 class="vehicle-name-large">${(vehicle.name || vehicle.model).toUpperCase()}</h2>
        <div class="price-large">${formatPrice(vehicle.price)}</div>
        
        <button class="purchase-btn" id="purchase-btn">PURCHASE VEHICLE</button>
    `;
    
    // Add image event listeners
    const img = document.getElementById('vehicle-image');
    if (img) {
        img.addEventListener('load', function() {
            this.classList.add('loaded');
        });
        
        img.addEventListener('error', function() {
            handleImageError(this, vehicle.name || vehicle.model);
        });
    }
    
    // Add event listener to purchase button
    const purchaseBtn = document.getElementById('purchase-btn');
    if (purchaseBtn) {
        purchaseBtn.addEventListener('click', purchaseVehicle);
    }
}

/**
 * Show "no selection" state in details panel
 */
function showNoSelection() {
    const detailsContent = document.getElementById('details-content');
    detailsContent.innerHTML = `
        <div class="no-selection">
            <p>Select a vehicle to view details</p>
        </div>
    `;
}

/**
 * Purchase the selected vehicle
 */
function purchaseVehicle() {
    // Validate selection
    if (!selectedVehicle) {
        return;
    }
    
    // Prevent double-click
    if (isPurchasing) {
        return;
    }
    
    // Set purchasing state
    isPurchasing = true;
    
    // Update button state
    const btn = document.getElementById('purchase-btn');
    if (btn) {
        btn.classList.add('loading');
        btn.textContent = 'PROCESSING...';
        btn.disabled = true;
    }
    
    // Send purchase request to server
    post('purchaseVehicle', { 
        model: selectedVehicle.model 
    });
    
    // Note: Response will come via message event (purchaseSuccess or purchaseFailure)
}

/**
 * Reset the purchase button to normal state
 */
function resetPurchaseButton() {
    isPurchasing = false;
    
    const btn = document.getElementById('purchase-btn');
    if (btn) {
        btn.classList.remove('loading');
        btn.textContent = 'PURCHASE VEHICLE';
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

/**
 * Handle image load errors
 * @param {HTMLImageElement} imgElement - The image element that failed to load
 * @param {string} vehicleName - Name of the vehicle
 */
function handleImageError(imgElement, vehicleName) {
    imgElement.classList.add('error');
    const container = imgElement.parentElement;
    
    // Create placeholder
    const placeholder = document.createElement('div');
    placeholder.className = 'vehicle-image-placeholder';
    placeholder.textContent = 'No Image Available';
    
    container.appendChild(placeholder);
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
            openUI(data.vehicles || []);
            break;
            
        case 'close':
            closeUI();
            break;
            
        case 'purchaseSuccess':
            showFeedback(data.message || '✓ Purchase Successful!', true);
            // Close UI after showing success message
            setTimeout(() => {
                closeUI();
            }, 1000);
            break;
            
        case 'purchaseFailure':
            showFeedback(data.message || '✗ Purchase Failed', false);
            // Reset purchase button
            resetPurchaseButton();
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

// Mock data for testing in browser (outside FiveM)
if (!window.GetParentResourceName) {
    
    // Test data with multiple categories
    const testVehicles = [
        { model: 'rhapsody', name: 'Declasse Rhapsody', price: 3500, category: 'Compacts' },
        { model: 'prairie', name: 'Bollokan Prairie', price: 4200, category: 'Compacts' },
        { model: 'brioso2', name: 'Grotti Brioso 300', price: 5000, category: 'Compacts' },
        { model: 'panto', name: 'Benefactor Panto', price: 2800, category: 'Compacts' },
        { model: 'weevil', name: 'BF Weevil', price: 3200, category: 'Compacts' },
        { model: 'blista', name: 'Dinka Blista', price: 4000, category: 'Compacts' },
        { model: 'adder', name: 'Truffade Adder', price: 50000, category: 'Super' },
        { model: 't20', name: 'Progen T20', price: 45000, category: 'Super' },
        { model: 'zentorno', name: 'Pegassi Zentorno', price: 40000, category: 'Super' },
        { model: 'turismor', name: 'Grotti Turismo R', price: 38000, category: 'Super' },
        { model: 'elegy', name: 'Annis Elegy RH8', price: 15000, category: 'Sports' },
        { model: 'jester', name: 'Dinka Jester', price: 18000, category: 'Sports' },
        { model: 'schwartzer', name: 'Benefactor Schwartzer', price: 12500, category: 'Sports' }
    ];
    
    // Auto-open UI after 1 second (for testing)
    setTimeout(() => {
        openUI(testVehicles);
    }, 1000);
    
    // Test purchase success
    window.testPurchaseSuccess = () => {
        showFeedback('✓ Vehicle purchased successfully!', true);
        setTimeout(() => closeUI(), 2000);
    };
    
    // Test purchase failure
    window.testPurchaseFailure = () => {
        showFeedback('✗ Insufficient funds', false);
        resetPurchaseButton();
    };
}
