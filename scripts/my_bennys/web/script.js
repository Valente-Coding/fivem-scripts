// =============================================
// Sound
// =============================================

let audioPlayer;
try {
    audioPlayer = new Howl({ src: ["sound.mp3"] });
} catch (e) {}

function playSound() {
    if (audioPlayer) {
        try { audioPlayer.play(); } catch (e) {}
    }
}

// =============================================
// Menu Rendering
// =============================================

let currentOptions = [];
let selectedIndex = 1;

function showMenu(data) {
    const container = document.getElementById('menu-container');
    const title = document.getElementById('menu-title');
    const body = document.getElementById('menu-body');

    title.textContent = data.title || "BENNY'S";
    currentOptions = data.options || [];
    selectedIndex = data.selectedIndex || 1;

    body.innerHTML = '';
    currentOptions.forEach((opt, i) => {
        const idx = i + 1;
        const div = document.createElement('div');
        div.className = 'menu-option' + (idx === selectedIndex ? ' selected' : '');
        div.id = 'menu-opt-' + idx;

        let valueHTML = '';
        if (opt.hasValues && opt.currentValue) {
            valueHTML = `
                <div class="menu-option-value">
                    <span class="menu-option-arrow">◀</span>
                    <span class="menu-option-value-text">${escapeHtml(opt.currentValue)}</span>
                    <span class="menu-option-arrow">▶</span>
                </div>`;
        }

        let descHTML = '';
        if (opt.description) {
            descHTML = `<div class="menu-option-description">${escapeHtml(opt.description)}</div>`;
        }

        div.innerHTML = `
            <div class="menu-option-row">
                <span class="menu-option-label">${escapeHtml(opt.label)}</span>
                ${valueHTML}
            </div>
            ${descHTML}`;

        body.appendChild(div);
    });

    container.style.display = 'block';
}

function hideMenu() {
    document.getElementById('menu-container').style.display = 'none';
}

function updateSelected(newIndex) {
    const prev = document.querySelector('.menu-option.selected');
    if (prev) prev.classList.remove('selected');

    const next = document.getElementById('menu-opt-' + newIndex);
    if (next) {
        next.classList.add('selected');
        next.scrollIntoView({ block: 'nearest', behavior: 'smooth' });
    }
    selectedIndex = newIndex;
}

function updateScroll(optionIndex, scrollIndex, value) {
    const opt = document.getElementById('menu-opt-' + optionIndex);
    if (!opt) return;
    const valueText = opt.querySelector('.menu-option-value-text');
    if (valueText && value !== undefined) {
        valueText.textContent = value;
    }
}

function escapeHtml(text) {
    if (!text) return '';
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

// =============================================
// NUI Message Handler
// =============================================

window.addEventListener('message', (event) => {
    const data = event.data;

    switch (data.action) {
        case 'showMenu':
            showMenu(data);
            break;
        case 'hideMenu':
            hideMenu();
            break;
        case 'updateSelected':
            updateSelected(data.selectedIndex);
            break;
        case 'updateScroll':
            updateScroll(data.optionIndex, data.scrollIndex, data.value);
            break;
    }

    // Sound effect (mod installed)
    if (data.sound) {
        playSound();
    }
});
