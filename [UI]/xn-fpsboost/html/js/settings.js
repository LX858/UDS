/* ==========================================================================
   oxlyn-fpsboost · settings.js
   --------------------------------------------------------------------------
   Render do menu de definicoes a partir do schema enviado pelo Lua.

   Nada aqui conhece nomes de definicoes. Tudo o que aparece no menu vem de
   Config.Settings. Adicionar uma opcao nova ao config.lua faz com que ela
   apareca aqui automaticamente, com o controlo certo para o seu tipo.
   ========================================================================== */

const ICONS = {
  monitor:  '<rect x="3" y="4" width="18" height="13" rx="2"/><path d="M8 21h8M12 17v4"/>',
  bulb:     '<path d="M9 18h6M10 21h4M12 3a6 6 0 0 0-3.5 10.9V16h7v-2.1A6 6 0 0 0 12 3Z"/>',
  users:    '<circle cx="9" cy="8" r="3"/><path d="M3 20a6 6 0 0 1 12 0M16 6.5a3 3 0 0 1 0 5.8M18 20a5.5 5.5 0 0 0-3-4.6"/>',
  sparkles: '<path d="M12 3 13.5 8 18 9.5 13.5 11 12 16 10.5 11 6 9.5 10.5 8Z"/><path d="M18 15l.8 2.2L21 18l-2.2.8L18 21l-.8-2.2L15 18l2.2-.8Z"/>',
  broom:    '<path d="M15 4 9 10M4 20l4-8 8 4-8 4Z"/><path d="m13 9 5-5"/>',
  gauge:    '<path d="M12 4a8 8 0 0 0-8 8h3a5 5 0 1 1 10 0h3a8 8 0 0 0-8-8Z"/><path d="m12 12 4-3"/>',
  palette:  '<path d="M12 3a9 9 0 1 0 0 18c1 0 1.5-.7 1.5-1.5 0-1.4 1-2 2-2H17a4 4 0 0 0 4-4c0-5-4-10.5-9-10.5Z"/><circle cx="8" cy="10" r="1"/><circle cx="12" cy="7.5" r="1"/><circle cx="16" cy="10" r="1"/>',
  robot:    '<rect x="4" y="8" width="16" height="12" rx="3"/><circle cx="9" cy="14" r="1.3"/><circle cx="15" cy="14" r="1.3"/><path d="M12 4v4M9 4h6"/>',
  power:    '<path d="M12 4v8M7.5 6.5a7 7 0 1 0 9 0"/>',
  feather:  '<path d="M19 5c0 8-6 11-11 11H5l1-3c0-6 5-9 9-9Z"/><path d="M5 19 12 12"/>',
  scale:    '<path d="M12 4v16M6 8h12"/><path d="m6 8-3 6h6ZM18 8l-3 6h6Z"/>',
  zap:      '<path d="M13 3 5 14h6l-1 7 8-11h-6Z"/>',
  flame:    '<path d="M12 3s5 4 5 9a5 5 0 0 1-10 0c0-2 1-3 2-4 0 1.5 1 2 1 2s-.5-4 2-7Z"/>',
  sliders:  '<path d="M4 8h10M18 8h2M4 16h4M12 16h8"/><circle cx="16" cy="8" r="2"/><circle cx="10" cy="16" r="2"/>',
  trash:    '<path d="M4 7h16M10 4h4M6 7l1 13h10l1-13"/><path d="M10 11v6M14 11v6"/>',
  // Batata: um contorno irregular com dois olhos. O preset mais agressivo
  // merece um simbolo que se reconheca de relance no meio dos outros.
  potato:   '<path d="M8.5 4.6c3-1.4 6.4-.6 8.2 1.7 2 2.6 1.6 6.4-.6 9.2-2.1 2.7-5.6 4.2-8.4 3.2-2.6-.9-4.2-3.7-4-6.8.2-3.2 2-6 4.8-7.3Z"/><path d="M10 10.5h.01M14.2 13.4h.01M11.6 15.8h.01"/>',
};

function svgIcon(name, cls = '') {
  return `<svg class="${cls}" viewBox="0 0 24 24">${ICONS[name] || ICONS.sliders}</svg>`;
}

/* ==========================================================================
   DROPDOWN
   --------------------------------------------------------------------------
   Substitui o <select> nativo em toda a interface.

   Nao e preferencia estetica: a lista aberta de um <select> e desenhada pelo
   SISTEMA OPERATIVO, fora do documento. Nenhuma regra de CSS lhe chega — nem
   cor, nem tipo de letra, nem cantos. Por muito bem que o botao fechado
   ficasse, ao abrir aparecia sempre a caixa azul do Windows por cima do
   painel. A unica forma de a lista seguir o design e desenha-la nos.

   O menu vive em <body> e usa `position: fixed`. Duas razoes:
     · a lista de definicoes tem overflow, e um menu la dentro seria cortado;
     · .app__grid tem um transform (a flutuacao), e um ancestral com transform
       passa a ser o bloco de referencia de qualquer `position: fixed` que
       esteja DENTRO dele — o menu deixaria de se posicionar pelo ecra.
   ========================================================================== */
const Dropdown = {
  menu: null,
  owner: null,

  _ensure() {
    if (this.menu) return this.menu;
    this.menu = el('div', { class: 'selmenu', hidden: true });
    document.body.append(this.menu);

    // Captura na fase de captura para fechar antes de qualquer outro handler.
    document.addEventListener('mousedown', (e) => {
      if (!this.menu || this.menu.hidden) return;
      if (this.menu.contains(e.target)) return;
      if (this.owner && this.owner.contains(e.target)) return;
      this.close();
    }, true);

    window.addEventListener('resize', () => this.close());

    // Rolar a lista POR BAIXO de um menu aberto deixaria o menu orfao: a
    // posicao dele foi calculada a partir do rectangulo do botao, e o botao
    // move-se com o scroll enquanto o menu (position: fixed) fica parado.
    //
    // Mas rolar DENTRO do menu e legitimo — com doze idiomas a lista nao cabe
    // toda, e o scroll e a unica forma de ver o resto. Fechar nesse caso
    // tornava as ultimas opcoes inalcancaveis.
    document.addEventListener('scroll', (e) => {
      if (!this.menu || this.menu.hidden) return;
      const t = e.target;
      if (t === this.menu) return;
      if (t instanceof Node && this.menu.contains(t)) return;
      this.close();
    }, true);
    return this.menu;
  },

  isOpen() { return !!(this.menu && !this.menu.hidden); },

  close() {
    if (this.menu) { this.menu.hidden = true; this.menu.replaceChildren(); }
    if (this.owner) this.owner.classList.remove('is-open');
    this.owner = null;
  },

  open(trigger, options, currentValue, onPick) {
    const wasOwner = this.owner === trigger;
    this.close();
    if (wasOwner) return;            // segundo clique no mesmo botao fecha

    const menu = this._ensure();
    this.owner = trigger;
    trigger.classList.add('is-open');

    menu.replaceChildren(...options.map(o => el('button', {
      class: 'selmenu__opt' + (o.value === currentValue ? ' is-active' : ''),
      type: 'button',
      onclick: () => { this.close(); onPick(o); },
    }, o.label)));

    /*  POSICIONAR DENTRO DE UM ZOOM, SEM ADIVINHAR A CONVENCAO
        ---------------------------------------------------------
        Este menu vive em <body> e e colocado por coordenadas, mas tanto ele
        como o botao que o abre estao dentro da escala da interface. Isso
        levanta uma pergunta a que os motores respondem de maneira
        DIFERENTE: em que espaco e que getBoundingClientRect() devolve os
        numeros dentro de um `zoom`?

          · Chromium recente (e o Edge onde isto se testa fora do jogo)
            devolve pixeis reais do ecra, ja multiplicados pela escala.
          · O CEF que o FiveM embute divide o rectangulo pela escala do
            elemento e devolve-o no espaco de layout dele.

        Escolher um dos dois e escolher em qual deles o menu aparece ao
        lado do botao em vez de debaixo dele. Foi o que aconteceu: alinhado
        no browser, deslocado uns duzentos pixeis para a esquerda no jogo.

        Por isso nao se assume nada — mede-se. Escrevemos ao menu duas
        posicoes conhecidas e vemos onde ele aterra:

          k = quanto anda o rectangulo por cada unidade que escrevemos
          s = quanto vale um pixel de ecra no mesmo espaco do rectangulo

        Com estes dois numeros, todas as contas passam a ser feitas no espaco
        do rectangulo — seja ele qual for — e so a escrita final e convertida
        de volta. Custa duas medicoes por abertura de menu, o que nao e nada
        para algo que acontece a um clique.                                 */
    const zoom = (typeof UiScale !== 'undefined' && UiScale.value) ? UiScale.value : 1;

    // Tem de estar visivel para se poder medir seja o que for.
    menu.hidden = false;

    menu.style.left = '0px';
    menu.style.top  = '0px';
    const at0 = menu.getBoundingClientRect();
    menu.style.left = '100px';
    menu.style.top  = '100px';
    const at100 = menu.getBoundingClientRect();

    const kx = (at100.left - at0.left) / 100 || 1;
    const ky = (at100.top  - at0.top)  / 100 || 1;
    const s  = kx / zoom;      // pixeis de ecra -> espaco do rectangulo

    // A largura do botao vem no espaco do rectangulo; minWidth escreve-se em
    // unidades locais, logo divide-se por k.
    const r = trigger.getBoundingClientRect();
    menu.style.minWidth = `${Math.round(r.width / kx)}px`;

    // Medir DEPOIS do minWidth: e ele que decide a largura final.
    const m  = menu.getBoundingClientRect();
    const mw = m.width;
    const mh = m.height;
    const vw = window.innerWidth  * s;
    const vh = window.innerHeight * s;

    // Abre para baixo; se nao houver espaco em baixo mas houver em cima, inverte.
    const fitsBelow = (vh - r.bottom) > mh + 12 * s;
    const top  = (!fitsBelow && r.top > mh + 12 * s)
      ? (r.top - mh - 6 * s)
      : (r.bottom + 6 * s);
    const left = Math.min(Math.max(8 * s, r.left), vw - mw - 8 * s);

    // De volta a unidades locais, ancorando na medicao dos 100.
    menu.style.top  = `${Math.round(100 + (top  - at100.top)  / ky)}px`;
    menu.style.left = `${Math.round(100 + (left - at100.left) / kx)}px`;
  },
};

/** Constroi um selector com o aspecto da restante UI.
    `options`: [{ value, label }] · `onChange(value)` */
function createSelect(options, value, onChange) {
  const opts = options || [];
  const current = opts.find(o => o.value === value) || opts[0] || { value: null, label: '' };

  const valEl = el('span', { class: 'sel__val', text: current.label });
  const trigger = el('button', {
    class: 'sel',
    type: 'button',
    onclick: (e) => {
      e.stopPropagation();
      Dropdown.open(trigger, opts, trigger._value, (picked) => {
        trigger._value = picked.value;
        valEl.textContent = picked.label;
        onChange(picked.value);
      });
    },
  }, valEl);

  trigger.insertAdjacentHTML('beforeend',
    '<svg viewBox="0 0 24 24"><path d="m6 9 6 6 6-6"/></svg>');
  trigger._value = current.value;
  return trigger;
}

/* ========================================================================== */
class SettingsView {
  /* `onChange` grava — vai ao Lua e a lista e reconstruida com a resposta.
     `onPreview` NAO grava: aplica o valor so na pagina, para se poder ver o
     efeito enquanto se arrasta um controlo. Ver a nota em _color(). */
  constructor(rail, list, onChange, onPreview) {
    this.rail = rail;
    this.list = list;
    this.onChange = onChange;
    this.onPreview = onPreview || (() => {});

    this.schema = { groups: [], settings: [] };
    this.values = {};
    this.overrides = {};
    this.activeGroup = null;
    this.query = '';
  }

  setSchema(schema) {
    this.schema = schema;
    if (!this.activeGroup || !schema.groups.some(g => g.id === this.activeGroup)) {
      this.activeGroup = schema.groups[0]?.id || null;
    }
    this.renderRail();
    this.renderList(true);
  }

  /* Sem animacao: isto corre a cada alteracao de uma definicao. Reanimar a
     lista inteira sempre que se mexe num interruptor faria a pagina saltar
     debaixo do cursor a cada clique. A entrada e para conteudo NOVO, nao para
     valores actualizados. */
  setValues(payload) {
    this.values = payload.values || {};
    this.overrides = payload.overrides || {};
    this.renderRail();
    this.renderList(false);
  }

  setQuery(q) {
    this.query = (q || '').trim().toLowerCase();
    this.renderRail();
    this.renderList(true);   // resultados novos: entram
  }

  /* ---------------------------------------------------------------- rail -- */
  /* A barra tem dois blocos: o que muda os FPS e o que muda o aspecto.
     Estavam todos numa lista corrida, e o resultado era que "Tema e cores"
     aparecia entre "Limpeza" e "Automacao" como se fosse mais uma definicao de
     desempenho. Sao decisoes de natureza diferente: uma paga-se em FPS, a
     outra e gosto. A ordem dos blocos e a das seccoes tal como vem do config;
     a ordem dentro de cada bloco tambem. */
  renderRail() {
    this.rail.replaceChildren();

    const order = [];
    const bySection = new Map();
    for (const g of this.schema.groups) {
      const s = g.section || 'performance';
      if (!bySection.has(s)) { bySection.set(s, []); order.push(s); }
      bySection.get(s).push(g);
    }

    for (const section of order) {
      // Com uma seccao so, o cabecalho seria uma etiqueta a dizer o obvio.
      if (order.length > 1) {
        this.rail.append(el('div', {
          class: 'grouprail__head',
          text: I18N.t(`se_sec_${section}`, section),
        }));
      }

      for (const g of bySection.get(section)) {
        const items = this._itemsOf(g.id);
        const modified = items.filter(s => this.overrides[s.id] !== undefined).length;

        const btn = el('button', {
          class: g.id === this.activeGroup && !this.query ? 'is-active' : '',
          onclick: () => { this.activeGroup = g.id; this.query = '';
                           const s = $('#settingSearch'); if (s) s.value = '';
                           this.renderRail(); this.renderList(true); },
        });
        btn.insertAdjacentHTML('beforeend', svgIcon(g.icon));
        btn.querySelector('svg').style.cssText = 'width:16px;height:16px;flex:none;';
        btn.append(el('span', { text: g.label }));
        btn.append(el('span', { class: 'count', text: modified > 0 ? `${modified}` : '' }));
        this.rail.append(btn);
      }
    }
  }

  /** Abre as definicoes numa seccao especifica, no primeiro grupo dela.
   *  Usado pelo botao "Personalizar" do cartao Personalizado: quem vem de la
   *  quer mexer nos FPS, e cair no grupo onde ficou da ultima vez — que podia
   *  ser o das cores — nao e o que pediu. */
  focusSection(section) {
    const g = this.schema.groups.find(x => (x.section || 'performance') === section);
    if (!g) return;
    this.activeGroup = g.id;
    this.query = '';
    const s = $('#settingSearch'); if (s) s.value = '';
    this.renderRail();
    this.renderList(true);
  }

  _itemsOf(groupId) {
    return this.schema.settings.filter(s => s.group === groupId);
  }

  _visibleItems() {
    if (this.query) {
      return this.schema.settings.filter(s =>
        s.label.toLowerCase().includes(this.query) ||
        (s.desc || '').toLowerCase().includes(this.query) ||
        s.id.toLowerCase().includes(this.query));
    }
    return this._itemsOf(this.activeGroup);
  }

  /* ---------------------------------------------------------------- list -- */
  renderList(animate = false) {
    this.list.replaceChildren();

    /* `animate` ja distingue exactamente os dois casos que aqui interessam:
       e verdadeiro quando a lista passa a mostrar conteudo NOVO — outro grupo,
       outra pesquisa, outro esquema — e falso quando so se actualizam valores
       de linhas que ja estao no ecra.

       So o primeiro caso leva a lista ao topo. Fazer isto tambem no segundo
       arrancaria a pagina de debaixo do cursor a cada clique num interruptor,
       que e precisamente o que a nota do setValues() existe para evitar. */
    if (animate) this.list.scrollTop = 0;

    const items = this._visibleItems();

    if (!items.length) {
      this.list.append(el('div', { class: 'empty anim-in', text: I18N.t('se_no_results') }));
      return;
    }

    for (const def of items) {
      this.list.append(this._renderSetting(def));
    }
    if (animate) stagger(this.list.children);
    // Uma lista nova comeca sempre no topo. Sem isto, mudar de grupo deixava
    // a posicao de rolamento do grupo anterior e o utilizador aterrava a meio.
    if (animate) this.list.scrollTop = 0;
  }

  _renderSetting(def) {
    const value    = this.values[def.id];
    const modified = this.overrides[def.id] !== undefined;
    const gated    = def.requires && !this.values[def.requires];

    const row = el('div', {
      class: [
        'setting',
        def.locked ? 'is-locked' : '',
        gated ? 'is-disabled' : '',
        modified ? 'is-modified' : '',
      ].filter(Boolean).join(' '),
      dataset: { id: def.id },
    });

    /* ---- texto ---- */
    const name = el('div', { class: 'setting__name' }, def.label);
    if (modified)     name.append(el('span', { class: 'tag tag--mod',   text: I18N.t('se_modified') }));
    if (def.locked)   name.append(el('span', { class: 'tag tag--lock',  text: I18N.t('se_locked') }));
    if (def.adminOnly)name.append(el('span', { class: 'tag tag--admin', text: I18N.t('se_admin') }));
    if (gated) {
      name.append(el('span', {
        class: 'tag tag--req',
        text: I18N.t('se_requires').replace('%s', def.requiresLabel || def.requires),
      }));
    }

    const text = el('div', { class: 'setting__text' }, name);
    if (def.desc) text.append(el('div', { class: 'setting__desc', text: def.desc }));

    // Barrinhas de impacto: so fazem sentido em definicoes de otimizacao.
    if (def.impact !== undefined || def.visual !== undefined) {
      const meta = el('div', { class: 'setting__desc', style: 'display:flex;gap:16px;margin-top:7px;' });
      if (def.impact !== undefined) meta.append(this._dots(I18N.t('pf_impact'), def.impact, false));
      if (def.visual !== undefined) meta.append(this._dots(I18N.t('pf_visual'), def.visual, true));
      text.append(meta);
    }

    const ctrl = el('div', { class: 'setting__ctrl' }, this._control(def, value));

    row.append(el('div', { class: 'setting__head' }, text, ctrl));
    return row;
  }

  _dots(label, level, isVisual) {
    const wrap = el('span', { style: 'display:flex;align-items:center;gap:6px;' });
    wrap.append(el('span', { style: 'font-size:9px;letter-spacing:.1em;font-weight:700;opacity:.65', text: label.toUpperCase() }));
    const dots = el('span', { class: 'impactdots' + (isVisual ? ' visual' : '') });
    for (let i = 0; i < 3; i++) dots.append(el('i', { class: i < level ? 'on' : '' }));
    wrap.append(dots);
    return wrap;
  }

  /* ------------------------------------------------------------ controlos -- */
  _control(def, value) {
    switch (def.type) {
      case 'toggle': return this._toggle(def, value);
      case 'range':  return this._range(def, value);
      case 'select': return this._select(def, value);
      case 'color':  return this._color(def, value);
      default:       return el('span', { text: String(value) });
    }
  }

  _toggle(def, value) {
    const node = el('div', {
      class: 'toggle' + (value ? ' on' : ''),
      role: 'switch',
      onclick: () => {
        const next = !node.classList.contains('on');
        node.classList.toggle('on', next);
        this.onChange(def.id, next);
      },
    });
    return node;
  }

  _range(def, value) {
    const scale = def.scale || 1;
    const unit  = def.unit || '';
    const dec   = (def.step && def.step < 1 && scale === 1) ? 2 : 0;

    const out = el('b', { class: 'rv', text: `${round((value ?? def.default) * scale, dec)}${unit}` });

    const input = el('input', {
      type: 'range',
      min: def.min, max: def.max, step: def.step,
      value: value ?? def.default,
    });

    // `input` actualiza o texto e da o valor a pre-visualizacao (as duas
    // coisas baratas); `change` e que envia para o Lua e grava. Sem esta
    // separacao, arrastar um slider dispararia dezenas de gravacoes por
    // segundo — cada uma com ida ao KVP e resposta.
    //
    // A pre-visualizacao e chamada para TODAS as definicoes; e o app.js que
    // decide quais consegue mostrar sem gravar (a cor e a escala). Uma que
    // ele nao conheca sai no primeiro `if` e nao custa nada.
    input.addEventListener('input', () => {
      out.textContent = `${round(parseFloat(input.value) * scale, dec)}${unit}`;
      this.onPreview(def.id, parseFloat(input.value));
    });
    input.addEventListener('change', () => {
      this.onChange(def.id, parseFloat(input.value));
    });

    return el('div', { class: 'rangectrl' }, input, out);
  }

  _select(def, value) {
    return createSelect(def.options || [], value, (v) => this.onChange(def.id, v));
  }

  /* Amostras rapidas + uma cor propria.
     As amostras cobrem o caso comum num clique. A cor propria existe porque
     quatro cores fixas nao chegam para um servidor que tem uma identidade:
     abre um cursor de matiz e um campo hexadecimal, e fica aberta enquanto a
     cor escolhida nao for nenhuma das amostras — assim o jogador ve de imediato
     que valor esta a usar. */
  _color(def, value) {
    const wrap = el('div', { class: 'colorctrl' });
    const swatches = def.swatches || ['#FF2E43', '#31E07A', '#22C7E8', '#A855F7'];
    const current = isHex(value) ? value : swatches[0];
    const isPreset = (hex) => swatches.some(s => s.toLowerCase() === hex.toLowerCase());

    const row = el('div', { class: 'colorctrl__row' });
    const custom = el('div', { class: 'colorctrl__custom', hidden: isPreset(current) });

    const marks = [];
    const paint = (hex) => {
      for (const m of marks) {
        m.node.classList.toggle('is-active', m.hex.toLowerCase() === hex.toLowerCase());
      }
      btnCustom.classList.toggle('is-active', !isPreset(hex));
      btnCustom.style.color = hex;
    };

    for (const hex of swatches) {
      const sw = el('button', {
        class: 'swatch',
        style: `background:${hex};color:${hex}`,
        title: hex,
        onclick: () => {
          custom.hidden = true;
          paint(hex);
          this.onChange(def.id, hex);
        },
      });
      marks.push({ node: sw, hex });
      row.append(sw);
    }

    const btnCustom = el('button', {
      class: 'swatch swatch--custom',
      title: I18N.t('se_color_custom'),
      onclick: () => { custom.hidden = !custom.hidden; if (!custom.hidden) hexField.focus(); },
    });
    btnCustom.innerHTML = svgIcon('palette');
    row.append(btnCustom);

    const hue = el('input', {
      type: 'range', class: 'huebar', min: '0', max: '360', step: '1',
    });
    hue.value = String(hexToHue(current));

    const hexField = el('input', {
      type: 'text', class: 'hexfield', maxlength: '7', spellcheck: 'false',
    });
    hexField.value = current.toUpperCase();

    /*  Arrastar previsualiza; largar e que grava.
        ------------------------------------------
        Gravar durante o arrasto nao funcionava, e nao por causa do cursor:
        gravar vai ao Lua, a resposta reconstroi a lista inteira de definicoes,
        e o proprio cursor que estava a ser arrastado era removido do DOM a
        meio do gesto. O rato perdia o elemento e a cor ficava presa no primeiro
        valor. Foi por isto que _range() sempre enviou so no `change`.

        Mas uma cor tem de se ver enquanto se escolhe. A saida e que a
        previsualizacao nao passa pelo Lua: a cor de destaque e inteiramente
        visual do lado da pagina, e aplica-la e so reescrever variaveis CSS.
        O Lua fica a saber quando o gesto acaba, e so entao a lista se
        reconstroi — ja sem ninguem a arrastar nada. */
    const preview = (hex) => {
      hexField.value = hex.toUpperCase();
      paint(hex);
      this.onPreview(def.id, hex);
    };
    const commit = (hex) => {
      preview(hex);
      this.onChange(def.id, hex);
    };

    hue.addEventListener('input',  () => preview(hueToHex(parseInt(hue.value, 10))));
    hue.addEventListener('change', () => commit(hueToHex(parseInt(hue.value, 10))));

    hexField.addEventListener('change', () => {
      let v = hexField.value.trim();
      if (v && v[0] !== '#') v = '#' + v;
      // Invalido: devolve o campo ao valor em vigor em vez de enviar lixo que o
      // Lua rejeitaria em silencio, repondo o vermelho por defeito.
      if (!isHex(v)) { hexField.value = (isHex(value) ? value : current).toUpperCase(); return; }
      hue.value = String(hexToHue(v));
      commit(v);
    });

    custom.append(hue, hexField);
    wrap.append(row, custom);
    paint(current);
    return wrap;
  }
}
