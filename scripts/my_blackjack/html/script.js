/* ============================================================
   my_blackjack | script.js
   NUI logic — renders game state, handles player actions
   ============================================================ */

let currentBet = 0;
let mySeat = null;
let lastState = null;
let notificationTimeout = null;
let prevDealerCardCount = 0;
let prevPlayerCardCounts = {}; // { seat: count }

// ============================================================
// NUI MESSAGE HANDLER
// ============================================================

window.addEventListener('message', function(event) {
    const data = event.data;

    switch (data.action) {
        case 'open':
            document.getElementById('blackjack-container').style.display = 'flex';
            currentBet = 0;
            updateBetDisplay();
            break;

        case 'close':
            document.getElementById('blackjack-container').style.display = 'none';
            currentBet = 0;
            mySeat = null;
            lastState = null;
            prevDealerCardCount = 0;
            prevPlayerCardCounts = {};
            break;

        case 'updateState':
            mySeat = data.mySeat;
            lastState = data.state;
            renderState(data.state);
            break;

        case 'notify':
            showNotification(data.message);
            break;

        case 'updateBalance':
            document.getElementById('player-balance').textContent = '$' + (data.balance || 0).toLocaleString();
            break;
    }
});

// ============================================================
// RENDER GAME STATE
// ============================================================

function renderState(state) {
    // Phase label
    const phaseLabels = {
        'idle': 'WAITING FOR PLAYERS',
        'betting': 'PLACE YOUR BETS',
        'dealing': 'DEALING CARDS',
        'playing': 'PLAYERS\' TURN',
        'dealer': 'DEALER\'S TURN',
        'payout': 'ROUND RESULTS'
    };
    document.getElementById('phase-label').textContent = phaseLabels[state.phase] || state.phase.toUpperCase();

    // Timer
    updateTimer(state);

    // Dealer cards
    renderDealerCards(state);

    // Player slots
    renderPlayers(state);

    // Show/hide panels
    const bettingPanel = document.getElementById('betting-panel');
    const actionsBar = document.getElementById('actions-bar');
    const waitingMsg = document.getElementById('waiting-msg');

    // Show betting panel only during betting phase for this player
    const myPlayer = getMyPlayer(state);
    const isBetting = state.phase === 'betting' && myPlayer && (myPlayer.status === 'betting');
    bettingPanel.style.display = isBetting ? 'block' : 'none';

    // Show action buttons only during playing phase when it's my turn
    const isMyTurn = state.phase === 'playing' && state.currentSeat === mySeat && myPlayer && myPlayer.status === 'playing';
    actionsBar.style.display = isMyTurn ? 'flex' : 'none';

    // Show waiting message when nothing else is showing
    const showWaiting = !isBetting && !isMyTurn;
    if (waitingMsg) {
        waitingMsg.style.display = showWaiting ? 'block' : 'none';
        if (showWaiting && myPlayer) {
            if (state.phase === 'playing') waitingMsg.textContent = 'Waiting for other players...';
            else if (state.phase === 'dealer') waitingMsg.textContent = 'Dealer is playing...';
            else if (state.phase === 'payout') waitingMsg.textContent = 'Round complete';
            else if (state.phase === 'dealing') waitingMsg.textContent = 'Dealing cards...';
            else if (myPlayer.status === 'bet_placed') waitingMsg.textContent = 'Bet placed — waiting for others...';
            else waitingMsg.textContent = 'Waiting for next round...';
        }
    }

    // Show/hide double down (only on first 2 cards)
    if (isMyTurn && myPlayer) {
        document.getElementById('btn-double').style.display = myPlayer.hand.length === 2 ? 'inline-block' : 'none';
    }
}

function getMyPlayer(state) {
    if (!mySeat || !state.players) return null;
    for (const p of state.players) {
        if (p && p.seat === mySeat) return p;
    }
    return null;
}

// ============================================================
// TIMER
// ============================================================

function updateTimer(state) {
    const fill = document.getElementById('timer-fill');
    let maxTime = 1;
    if (state.phase === 'betting') maxTime = 15; // Config.BettingTime
    else if (state.phase === 'playing') maxTime = 30; // Config.TurnTime

    const pct = maxTime > 0 ? (state.phaseTimer / maxTime) * 100 : 0;
    fill.style.width = pct + '%';

    // Color change
    if (pct > 50) {
        fill.style.background = 'linear-gradient(90deg, #00e676, #76ff03)';
    } else if (pct > 25) {
        fill.style.background = 'linear-gradient(90deg, #ff9100, #ffd740)';
    } else {
        fill.style.background = 'linear-gradient(90deg, #ff1744, #ff5252)';
    }
}

// ============================================================
// DEALER CARDS
// ============================================================

function renderDealerCards(state) {
    const container = document.getElementById('dealer-cards');
    const valueSpan = document.getElementById('dealer-value');

    if (!state.dealer || !state.dealer.hand) {
        container.innerHTML = '';
        valueSpan.textContent = '';
        prevDealerCardCount = 0;
        return;
    }

    const hand = state.dealer.hand;
    const currentCount = hand.length;
    const needsRebuild = currentCount < prevDealerCardCount || container.children.length !== prevDealerCardCount;

    if (needsRebuild) {
        // Full rebuild (new round or mismatch)
        container.innerHTML = '';
        hand.forEach((card, i) => {
            container.appendChild(createCardElement(card, true));
        });
    } else {
        // Update existing cards in-place (e.g. hole card reveal)
        for (let i = 0; i < Math.min(prevDealerCardCount, hand.length); i++) {
            const existing = container.children[i];
            const card = hand[i];
            if (card.rank === 'hidden') {
                if (!existing.classList.contains('card-back')) {
                    container.replaceChild(createCardElement(card, false), existing);
                }
            } else {
                const expectedSrc = 'img/' + card.image;
                if (existing.tagName === 'DIV' || (existing.tagName === 'IMG' && existing.src !== expectedSrc && !existing.src.endsWith(card.image))) {
                    container.replaceChild(createCardElement(card, true), existing);
                }
            }
        }
        // Append new cards only
        for (let i = prevDealerCardCount; i < currentCount; i++) {
            container.appendChild(createCardElement(hand[i], true));
        }
    }

    prevDealerCardCount = currentCount;

    if (state.dealer.handValue > 0) {
        valueSpan.textContent = '(' + state.dealer.handValue + ')';
    } else {
        valueSpan.textContent = '';
    }
}

function createCardElement(card, animate) {
    if (card.rank === 'hidden') {
        const div = document.createElement('div');
        div.className = 'card-back' + (animate ? ' card-deal-animate' : '');
        return div;
    } else {
        const img = document.createElement('img');
        img.className = 'card' + (animate ? ' card-deal-animate' : '');
        img.src = 'img/' + card.image;
        img.alt = card.rank + ' of ' + card.suit;
        return img;
    }
}

// ============================================================
// PLAYER SLOTS
// ============================================================

function renderPlayers(state) {
    const container = document.getElementById('players-area');

    if (!state.players || !state.players.length) {
        container.innerHTML = '';
        prevPlayerCardCounts = {};
        return;
    }

    // Build a map of current seat -> DOM element
    const existingSlots = {};
    for (const child of Array.from(container.children)) {
        const seat = parseInt(child.dataset.seat);
        if (seat) existingSlots[seat] = child;
    }

    // Track which seats are active this render
    const activeSeats = new Set();

    for (const p of state.players) {
        if (!p) continue;
        const seat = p.seat;
        activeSeats.add(seat);

        const isMe = seat === mySeat;
        const isActive = state.phase === 'playing' && state.currentSeat === seat;
        const prevCount = prevPlayerCardCounts[seat] || 0;
        const curCount = (p.hand && p.hand.length) || 0;

        let slot = existingSlots[seat];
        if (!slot) {
            // Create new slot
            slot = document.createElement('div');
            slot.dataset.seat = seat;
            container.appendChild(slot);
        }

        // Update classes
        slot.className = 'player-slot';
        if (isActive) slot.classList.add('active-turn');
        if (isMe) slot.classList.add('is-me');

        // Rebuild inner content (lightweight — no card animation re-trigger)
        let html = '';
        html += '<div class="player-name' + (isMe ? ' is-me' : '') + '">' + (isMe ? '★ ' : '') + escapeHtml(p.name) + '</div>';
        html += '<div class="player-bet">' + (p.bet > 0 ? 'BET: $' + p.bet.toLocaleString() : '') + '</div>';

        // Cards — only set via DOM to control animation
        html += '<div class="player-cards" data-seat-cards="' + seat + '"></div>';

        // Value
        if (p.hand && p.hand.length > 0) {
            let valClass = 'player-value';
            if (p.handValue > 21) valClass += ' bust';
            if (p.handValue === 21 && p.hand.length === 2) valClass += ' blackjack';
            html += '<div class="' + valClass + '">' + p.handValue + '</div>';
        }

        // Status
        const statusText = getStatusText(p.status, state.phase);
        html += '<div class="player-status' + (statusText.cls ? ' ' + statusText.cls : '') + '">' + escapeHtml(statusText.text) + '</div>';

        slot.innerHTML = html;

        // Now handle the cards container with diffing
        const cardsDiv = slot.querySelector('[data-seat-cards="' + seat + '"]');
        if (p.hand && p.hand.length > 0) {
            if (curCount < prevCount) {
                // New round — rebuild all with animation
                p.hand.forEach(card => {
                    cardsDiv.appendChild(createCardElement(card, true));
                });
            } else {
                // Add existing cards without animation
                for (let i = 0; i < Math.min(prevCount, curCount); i++) {
                    cardsDiv.appendChild(createCardElement(p.hand[i], false));
                }
                // Animate only new cards
                for (let i = prevCount; i < curCount; i++) {
                    cardsDiv.appendChild(createCardElement(p.hand[i], true));
                }
            }
        }

        prevPlayerCardCounts[seat] = curCount;
    }

    // Remove slots for players who left
    for (const [seat, el] of Object.entries(existingSlots)) {
        if (!activeSeats.has(parseInt(seat))) {
            el.remove();
            delete prevPlayerCardCounts[seat];
        }
    }
}

function escapeHtml(str) {
    if (!str) return '';
    return str.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
}

function getStatusText(status, phase) {
    if (phase === 'payout' && typeof status === 'string' && status.length > 15) {
        // This is the result message
        const isWin = status.toLowerCase().includes('win') || status.toLowerCase().includes('blackjack');
        const isLose = status.toLowerCase().includes('lose') || status.toLowerCase().includes('bust');
        const isPush = status.toLowerCase().includes('push');
        let cls = '';
        if (isWin) cls = 'winner';
        else if (isLose) cls = 'loser';
        return { text: status, cls };
    }

    switch (status) {
        case 'waiting': return { text: 'WAITING', cls: '' };
        case 'betting': return { text: 'BETTING...', cls: '' };
        case 'bet_placed': return { text: 'BET PLACED ✓', cls: '' };
        case 'playing': return { text: 'PLAYING', cls: '' };
        case 'stand': return { text: 'STAND', cls: '' };
        case 'bust': return { text: 'BUST', cls: 'loser' };
        case 'blackjack': return { text: 'BLACKJACK!', cls: 'winner' };
        default: return { text: status || '', cls: '' };
    }
}

// ============================================================
// BETTING
// ============================================================

function addBet(amount) {
    currentBet += amount;
    updateBetDisplay();
}

function clearBet() {
    currentBet = 0;
    updateBetDisplay();
}

function updateBetDisplay() {
    document.getElementById('current-bet').textContent = '$' + currentBet.toLocaleString();
}

function confirmBet() {
    if (currentBet <= 0) {
        showNotification('Enter a bet amount first.');
        return;
    }
    fetch('https://my_blackjack/placeBet', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ amount: currentBet })
    });
    currentBet = 0;
    updateBetDisplay();
}

// ============================================================
// ACTIONS
// ============================================================

function doAction(action) {
    fetch('https://my_blackjack/' + action, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    });
}

// ============================================================
// NOTIFICATIONS
// ============================================================

function showNotification(msg) {
    const el = document.getElementById('notification');
    el.textContent = msg;
    el.classList.add('show');

    if (notificationTimeout) clearTimeout(notificationTimeout);
    notificationTimeout = setTimeout(() => {
        el.classList.remove('show');
    }, 4000);
}

// ============================================================
// ESC KEY
// ============================================================

document.addEventListener('keydown', function(e) {
    if (e.key === 'Escape') {
        doAction('closeUI');
    }
});
