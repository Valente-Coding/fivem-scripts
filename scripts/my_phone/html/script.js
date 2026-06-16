// ── Phone Script ──

(function () {
    const container    = document.getElementById('phone-container');
    const timeEl       = document.getElementById('phone-time');
    const mainScreen   = document.getElementById('main-screen');
    const skillsScreen = document.getElementById('skills-screen');
    const skillsList   = document.getElementById('skills-list');
    const skillsBack   = document.getElementById('skills-back');

    // Update clock every second
    function updateClock() {
        const now = new Date();
        const h   = String(now.getHours()).padStart(2, '0');
        const m   = String(now.getMinutes()).padStart(2, '0');
        timeEl.textContent = h + ':' + m;
    }
    updateClock();
    setInterval(updateClock, 1000);

    // ── NUI message listener ──
    window.addEventListener('message', function (event) {
        const data = event.data;

        if (data.action === 'open') {
            container.classList.remove('closing');
            container.style.display = 'block';
            mainScreen.style.display = 'flex';
            skillsScreen.style.display = 'none';
        }

        if (data.action === 'close') {
            container.classList.add('closing');
            setTimeout(function () {
                container.style.display = 'none';
                container.classList.remove('closing');
            }, 250);
        }

        if (data.action === 'showSkills') {
            renderSkills(data.skills);
            mainScreen.style.display = 'none';
            skillsScreen.style.display = 'flex';
        }
    });

    // ── Skills screen ──
    function renderSkills(skills) {
        skillsList.innerHTML = '';

        Object.keys(skills).forEach(function (key) {
            const skill = skills[key];
            const maxed = skill.level >= skill.maxLevel;
            const pct = maxed ? 100 : Math.min(100, Math.round((skill.xp / skill.xpNeeded) * 100));

            const row = document.createElement('div');
            row.className = 'skill-row';
            row.innerHTML =
                '<div class="skill-info">' +
                    '<span class="skill-label">' + skill.label + '</span>' +
                    '<span class="skill-level">Lv. ' + skill.level + ' / ' + skill.maxLevel + '</span>' +
                '</div>' +
                '<div class="skill-bar"><div class="skill-bar-fill" style="width: ' + pct + '%"></div></div>' +
                '<div class="skill-xp">' + (maxed ? 'MAX' : (skill.xp + ' / ' + skill.xpNeeded + ' XP')) + '</div>';

            skillsList.appendChild(row);
        });
    }

    skillsBack.addEventListener('click', function () {
        skillsScreen.style.display = 'none';
        mainScreen.style.display = 'flex';
    });

    // ── App button clicks ──
    document.querySelectorAll('.app-btn').forEach(function (btn) {
        btn.addEventListener('click', function () {
            const app = btn.getAttribute('data-app');
            fetch('https://my_phone/appClick', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ app: app })
            });
        });
    });

    // ── ESC key to close ──
    document.addEventListener('keydown', function (e) {
        if (e.key === 'Escape') {
            fetch('https://my_phone/closePhone', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({})
            });
        }
    });
})();
