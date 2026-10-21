const app = document.getElementById('app');
const rowsEl = document.getElementById('rows');
const claimBtn = document.getElementById('claimBtn');
const meNote = document.getElementById('meNote');

const fmt = (n) => Number(n).toLocaleString('vi-VN');
const esc = (s) => String(s).replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
const rankIcon = (r) => (r === 1 ? '👑' : r === 2 ? '🥈' : r === 3 ? '🥉' : r);

function post(name, body) {
    return fetch(`https://${GetParentResourceName()}/${name}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(body || {}),
    });
}

function setImg(el, src) {
    el.style.display = src ? '' : 'none';
    el.onerror = () => { el.style.display = 'none'; };
    if (src) el.src = src;
}

function setClaimed() {
    claimBtn.disabled = true;
    claimBtn.textContent = '✔ ĐÃ NHẬN QUÀ';
}

function close() {
    app.classList.add('hidden');
    post('close');
}

function open(data) {
    const { item, rows } = data;
    const me = data.me;

    document.getElementById('bossName').textContent = data.boss;
    document.getElementById('itemLabel').textContent = item.label;
    setImg(document.getElementById('itemImg'), item.image);

    const topDamage = rows.length ? rows[0].damage : 1;
    rowsEl.innerHTML = rows.map((r, i) => {
        const width = Math.max(4, Math.round((r.damage / topDamage) * 100));
        const mine = me && r.rank === me.rank;
        const cls = `row${r.rank <= 3 ? ' r' + r.rank : ''}${mine ? ' mine' : ''}`;
        return `
            <li class="${cls}" style="animation-delay:${i * 60}ms">
                <div class="bar" style="--w:${width}%"></div>
                <div class="rank">${rankIcon(r.rank)}</div>
                <div class="info">
                    <div class="name">${esc(r.name)}${mine ? ' (Bạn)' : ''}</div>
                    <div class="dmg"><b>${fmt(r.damage)}</b> sát thương · ${r.percent}%</div>
                </div>
                <div class="reward"><img src="${esc(item.image)}" onerror="this.style.display='none'" alt="">x${r.reward}</div>
            </li>`;
    }).join('');

    if (me) {
        document.getElementById('meRank').textContent = `#${me.rank}/${me.total}`;
        document.getElementById('meDamage').textContent = fmt(me.damage);
        setImg(document.getElementById('meImg'), item.image);
        document.getElementById('meReward').textContent = `x${me.reward} ${item.label}`;
        meNote.textContent = '';
        claimBtn.classList.remove('hidden');
        if (me.claimed) {
            setClaimed();
        } else {
            claimBtn.disabled = false;
            claimBtn.textContent = '🎁 NHẬN QUÀ';
        }
    } else {
        document.getElementById('meRank').textContent = '-';
        document.getElementById('meDamage').textContent = '-';
        setImg(document.getElementById('meImg'), '');
        document.getElementById('meReward').textContent = '-';
        meNote.textContent = 'Bạn không tham gia đánh boss lượt này nên không có quà.';
        claimBtn.classList.add('hidden');
    }

    app.classList.remove('hidden');
}

claimBtn.addEventListener('click', async () => {
    if (claimBtn.disabled) return;
    claimBtn.disabled = true;
    claimBtn.textContent = 'Đang nhận...';
    try {
        const res = await (await post('claim')).json();
        if (res.ok) {
            setClaimed();
            meNote.textContent = '';
        } else {
            claimBtn.disabled = false;
            claimBtn.textContent = '🎁 NHẬN QUÀ';
            meNote.textContent = res.msg || '';
        }
    } catch (e) {
        claimBtn.disabled = false;
        claimBtn.textContent = '🎁 NHẬN QUÀ';
    }
});

window.addEventListener('message', (e) => {
    if (e.data && e.data.action === 'open') open(e.data.data);
    if (e.data && e.data.action === 'close') close();
});

document.getElementById('closeBtn').addEventListener('click', close);
document.addEventListener('keyup', (e) => { if (e.key === 'Escape') close(); });
