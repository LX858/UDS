(() => {
  const box = document.createElement('aside');
  box.id = 'interaction-hint';
  box.hidden = true;
  box.setAttribute('role', 'status');
  box.innerHTML =
    '<span class="hint-ring" aria-hidden="true"></span>' +
    '<kbd></kbd>' +
    '<div class="hint-copy"><small></small><span></span></div>' +
    '<i class="hint-orb" aria-hidden="true"></i>';
  document.body.appendChild(box);

  const key = box.querySelector('kbd');
  const title = box.querySelector('small');
  const label = box.querySelector('.hint-copy span');

  const stack = document.createElement('div');
  stack.id = 'toast-stack';
  document.body.appendChild(stack);

  const hex = (v) => /^#[0-9a-f]{6}$/i.test(v || '');

  function showHint(visible) {
    if (visible) {
      box.hidden = false;
      box.classList.add('is-on');
    } else {
      box.classList.remove('is-on');
      box.hidden = true;
    }
  }

  addEventListener('message', ({ data: d }) => {
    if (!d || typeof d !== 'object') return;

    if (d.action === 'toast') {
      const t = document.createElement('div');
      t.className = 'toast ' + (['success', 'error', 'inform'].includes(d.type) ? d.type : 'inform');
      t.textContent = String(d.description || '');
      if (hex(d.accent)) t.style.setProperty('--hint-accent', d.accent);
      stack.appendChild(t);
      requestAnimationFrame(() => t.classList.add('show'));
      setTimeout(() => {
        t.classList.remove('show');
        setTimeout(() => t.remove(), 320);
      }, 4200);
      while (stack.childElementCount > 4) stack.firstElementChild.remove();
      return;
    }

    if (d.action !== 'interactionHint') return;

    const textRaw = d.text;
    if (textRaw === false || textRaw === null || textRaw === undefined || textRaw === '') {
      showHint(false);
      return;
    }

    let text = String(textRaw);
    let k = d.key ? String(d.key) : '';
    const match = !k && text.match(/^\[([^\]]+)\]\s*/);
    if (match) {
      k = match[1];
      text = text.slice(match[0].length);
    }

    key.hidden = !k;
    key.textContent = k || '';
    label.textContent = text;
    title.textContent = String(d.title || 'RENTAL');
    box.style.setProperty('--hint-scale', String(Math.max(0.75, Math.min(1.5, Number(d.scale) || 1))));
    if (hex(d.accent)) box.style.setProperty('--hint-accent', d.accent);
    showHint(true);
  });

  try {
    fetch('https://' + GetParentResourceName() + '/interactionHintReady', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: '{}',
    }).catch(() => {});
  } catch (_) {}
})();
