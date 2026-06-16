// ═══════════════════════════════════════════════════
//  MY_RACING  –  NUI Script
// ═══════════════════════════════════════════════════

(function () {
    const container      = document.getElementById('racing-container');
    const trackListEl    = document.getElementById('track-list');
    const lobbyListEl    = document.getElementById('lobby-list');
    const lobbyViewEl    = document.getElementById('lobby-view');
    const resultsOverlay = document.getElementById('results-overlay');
    const resultsBody    = document.getElementById('results-body');
    const createOverlay  = document.getElementById('create-overlay');
    const hostOverlay    = document.getElementById('host-overlay');

    let cachedTracks  = [];
    let cachedLobbies = [];
    let currentLobby  = null;

    // ── Helpers ──
    function post(endpoint, data) {
        return fetch('https://my_racing/' + endpoint, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(data || {})
        });
    }

    // ── Tabs ──
    document.querySelectorAll('.tab').forEach(function (tab) {
        tab.addEventListener('click', function () {
            document.querySelectorAll('.tab').forEach(t => t.classList.remove('active'));
            document.querySelectorAll('.tab-content').forEach(t => t.classList.remove('active'));
            tab.classList.add('active');
            const target = document.getElementById('tab-' + tab.dataset.tab);
            if (target) target.classList.add('active');

            // Refresh data when switching tabs
            if (tab.dataset.tab === 'tracks')  post('requestTracks');
            if (tab.dataset.tab === 'lobbies') post('requestLobbies');
        });
    });

    // ── Close ──
    document.getElementById('btn-close').addEventListener('click', function () {
        post('closeMenu');
    });

    document.addEventListener('keydown', function (e) {
        if (e.key === 'Escape') {
            // Close modals first, then menu
            if (!createOverlay.classList.contains('hidden')) {
                createOverlay.classList.add('hidden');
                return;
            }
            if (!hostOverlay.classList.contains('hidden')) {
                hostOverlay.classList.add('hidden');
                return;
            }
            if (!resultsOverlay.classList.contains('hidden')) {
                resultsOverlay.classList.add('hidden');
                return;
            }
            post('closeMenu');
        }
    });

    // ── Create Track Modal ──
    document.getElementById('btn-create-track').addEventListener('click', function () {
        document.getElementById('input-track-name').value = '';
        createOverlay.classList.remove('hidden');
    });

    document.getElementById('btn-cancel-create').addEventListener('click', function () {
        createOverlay.classList.add('hidden');
    });

    document.getElementById('btn-confirm-create').addEventListener('click', function () {
        const name = document.getElementById('input-track-name').value.trim();
        if (!name) {
            document.getElementById('input-track-name').focus();
            return;
        }
        createOverlay.classList.add('hidden');
        post('startCreation', { name: name });
    });

    // ── Host Race Modal ──
    document.getElementById('btn-cancel-host').addEventListener('click', function () {
        hostOverlay.classList.add('hidden');
    });

    document.getElementById('btn-confirm-host').addEventListener('click', function () {
        const trackId   = document.getElementById('host-track-id').value;
        const betAmount = parseInt(document.getElementById('input-bet').value) || 0;
        hostOverlay.classList.add('hidden');
        post('createLobby', { trackId: trackId, betAmount: betAmount });
    });

    // ── Results ──
    document.getElementById('btn-close-results').addEventListener('click', function () {
        resultsOverlay.classList.add('hidden');
    });

    // ════════════════════════════════════════
    //  NUI MESSAGE HANDLER
    // ════════════════════════════════════════

    window.addEventListener('message', function (event) {
        const data = event.data;

        // ── Open / Close ──
        if (data.action === 'open') {
            container.classList.remove('closing');
            container.style.display = 'block';
        }

        if (data.action === 'close') {
            container.classList.add('closing');
            setTimeout(function () {
                container.style.display = 'none';
                container.classList.remove('closing');
            }, 200);
        }

        // ── Tracks ──
        if (data.action === 'updateTracks') {
            cachedTracks = data.tracks || [];
            renderTracks();
        }

        // ── Lobbies ──
        if (data.action === 'updateLobbies') {
            cachedLobbies = data.lobbies || [];
            renderLobbies();
        }

        // ── Lobby State ──
        if (data.action === 'lobbyState') {
            currentLobby = data.lobby;
            renderLobbyView();
            // Switch to lobby tab
            switchTab('lobby');
        }

        if (data.action === 'switchToLobby') {
            switchTab('lobby');
        }

        if (data.action === 'openLobby') {
            container.classList.remove('closing');
            container.style.display = 'block';
            switchTab('lobby');
        }

        if (data.action === 'lobbyClosed') {
            currentLobby = null;
            renderLobbyView();
        }

        // ── Race Results ──
        if (data.action === 'raceResults') {
            container.classList.remove('closing');
            container.style.display = 'block';
            renderResults(data.results);
        }
    });

    // ════════════════════════════════════════
    //  RENDERERS
    // ════════════════════════════════════════

    function switchTab(name) {
        document.querySelectorAll('.tab').forEach(t => {
            t.classList.toggle('active', t.dataset.tab === name);
        });
        document.querySelectorAll('.tab-content').forEach(t => {
            t.classList.toggle('active', t.id === 'tab-' + name);
        });
    }

    function renderTracks() {
        if (cachedTracks.length === 0) {
            trackListEl.innerHTML = '<div class="empty-state">No tracks yet. Create one!</div>';
            return;
        }

        let html = '';
        cachedTracks.forEach(function (track) {
            const cpCount = (track.checkpoints ? track.checkpoints.length : 0) + 1; // +1 for start
            const loopText = track.loop ? 'Loop' : 'Point-to-Point';
            html += '<div class="track-card">'
                +   '<div class="track-info">'
                +     '<div class="track-name">' + escHtml(track.name) + '</div>'
                +     '<div class="track-meta">By ' + escHtml(track.creator_name) + ' &bull; ' + cpCount + ' checkpoints &bull; ' + loopText + '</div>'
                +   '</div>'
                +   '<div class="track-actions">'
                +     '<button class="btn-small btn-host" onclick="hostRace(\'' + track.id + '\')">Host</button>'
                +     '<button class="btn-danger" onclick="deleteTrack(\'' + track.id + '\')">✕</button>'
                +   '</div>'
                + '</div>';
        });
        trackListEl.innerHTML = html;
    }

    function renderLobbies() {
        if (cachedLobbies.length === 0) {
            lobbyListEl.innerHTML = '<div class="empty-state">No active lobbies.</div>';
            return;
        }

        let html = '';
        cachedLobbies.forEach(function (lobby) {
            html += '<div class="lobby-card">'
                +   '<div class="lobby-info">'
                +     '<div class="lobby-name">' + escHtml(lobby.trackName) + '</div>'
                +     '<div class="lobby-details">Host: ' + escHtml(lobby.hostName)
                +       ' &bull; Players: ' + lobby.players
                +       ' &bull; Bet: $' + formatNum(lobby.betAmount) + '</div>'
                +   '</div>'
                +   '<button class="btn-small btn-join" onclick="joinLobby(' + lobby.lobbyId + ')">Join</button>'
                + '</div>';
        });
        lobbyListEl.innerHTML = html;
    }

    function renderLobbyView() {
        if (!currentLobby) {
            lobbyViewEl.innerHTML = '<div class="empty-state">You are not in a lobby.</div>';
            lobbyViewEl.className = 'empty-state';
            return;
        }

        lobbyViewEl.className = 'lobby-state';

        let playersHtml = '<ul class="player-list">';
        currentLobby.players.forEach(function (p) {
            const badge = p.source === currentLobby.host
                ? '<span class="host-badge">HOST</span>' : '';
            playersHtml += '<li>' + badge + escHtml(p.name) + '</li>';
        });
        playersHtml += '</ul>';

        lobbyViewEl.innerHTML =
            '<h3>' + escHtml(currentLobby.trackName) + '</h3>'
            + '<div class="bet-info">Bet: $' + formatNum(currentLobby.betAmount) + '  &bull;  Pot: $' + formatNum(currentLobby.pot) + '</div>'
            + playersHtml
            + '<div class="lobby-actions">'
            +   '<button class="btn-secondary" onclick="leaveLobby()">Leave</button>'
            +   '<button class="btn-primary" onclick="startRace()">Start Race</button>'
            + '</div>';
    }

    function renderResults(data) {
        if (!data) return;
        resultsOverlay.classList.remove('hidden');

        let html = '<div class="result-pot">Pot: $' + formatNum(data.pot) + '</div>';
        data.results.forEach(function (r) {
            const cls = r.position === 1 ? 'result-row winner' : 'result-row';
            const status = r.dnf ? 'DNF' : (r.position === 1 ? '🏆 Winner!' : '');
            html += '<div class="' + cls + '">'
                +   '<span class="result-position">#' + r.position + '</span>'
                +   '<span class="result-name">' + escHtml(r.name) + '</span>'
                +   '<span class="result-status">' + status + '</span>'
                + '</div>';
        });

        resultsBody.innerHTML = html;
    }

    // ════════════════════════════════════════
    //  GLOBAL ACTIONS  (called from onclick)
    // ════════════════════════════════════════

    window.hostRace = function (trackId) {
        document.getElementById('host-track-id').value = trackId;
        document.getElementById('input-bet').value = '0';
        hostOverlay.classList.remove('hidden');
    };

    window.deleteTrack = function (trackId) {
        post('deleteTracks', { trackId: trackId });
    };

    window.joinLobby = function (lobbyId) {
        post('joinLobby', { lobbyId: lobbyId });
    };

    window.leaveLobby = function () {
        post('leaveLobby');
    };

    window.startRace = function () {
        post('startRace');
    };

    // ── Utilities ──
    function escHtml(s) {
        if (!s) return '';
        return String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
    }

    function formatNum(n) {
        return Number(n || 0).toLocaleString();
    }
})();
