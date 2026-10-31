/* ==========================================================================
   oxlyn-fpsboost · util.js
   Helpers partilhados por todos os modulos da NUI.
   ========================================================================== */

const RES = (typeof GetParentResourceName === 'function')
  ? GetParentResourceName()
  : 'xn-fpsboost';

/* ------------------------------------------------------------------ DOM -- */
const $  = (sel, root = document) => root.querySelector(sel);
const $$ = (sel, root = document) => Array.from(root.querySelectorAll(sel));

// Evita invalidar texto/layout quando o valor visivel nao mudou.
function setText(node, value) {
  const text = String(value ?? '');
  if (node && node.textContent !== text) node.textContent = text;
}

function el(tag, attrs = {}, ...children) {
  const node = document.createElement(tag);
  for (const [k, v] of Object.entries(attrs)) {
    if (v === null || v === undefined || v === false) continue;
    if (k === 'class')      node.className = v;
    else if (k === 'html')  node.innerHTML = v;
    else if (k === 'text')  node.textContent = v;
    else if (k.startsWith('on') && typeof v === 'function') node.addEventListener(k.slice(2), v);
    else if (k === 'dataset') Object.assign(node.dataset, v);
    else node.setAttribute(k, v === true ? '' : v);
  }
  for (const c of children.flat()) {
    if (c === null || c === undefined || c === false) continue;
    node.append(c instanceof Node ? c : document.createTextNode(String(c)));
  }
  return node;
}

/* --------------------------------------------------------------- numeros -- */
const clamp = (v, lo, hi) => v < lo ? lo : v > hi ? hi : v;
const lerp  = (a, b, t) => a + (b - a) * t;

/** Arredonda para `d` casas sem produzir "3.9999999999". */
const round = (v, d = 0) => {
  const p = Math.pow(10, d);
  return Math.round(v * p) / p;
};

/** Separador de milhares discreto (espaco fino), para nao competir com o design. */
function fmtNum(v) {
  const n = Math.round(v || 0);
  return n >= 10000 ? n.toLocaleString('en-GB').replace(/ /g, ' ') : String(n);
}

function fmtDuration(seconds) {
  const s = Math.max(0, Math.floor(seconds || 0));
  const h = Math.floor(s / 3600);
  const m = Math.floor((s % 3600) / 60);
  if (h > 0) return `${h}h ${m}m`;
  if (m > 0) return `${m}m`;
  return `${s}s`;
}

function fmtBytesKb(kb) {
  if (!kb) return '0 KB';
  if (kb < 1024) return `${Math.round(kb)} KB`;
  return `${(kb / 1024).toFixed(1)} MB`;
}

function pad2(n) { return String(n).padStart(2, '0'); }

/* ----------------------------------------------------------------- cores -- */
function hexToRgb(hex) {
  const h = (hex || '#FF2E43').replace('#', '');
  const v = h.length === 3 ? h.split('').map(c => c + c).join('') : h;
  return {
    r: parseInt(v.slice(0, 2), 16),
    g: parseInt(v.slice(2, 4), 16),
    b: parseInt(v.slice(4, 6), 16),
  };
}

function rgba(hex, a) {
  const { r, g, b } = hexToRgb(hex);
  return `rgba(${r},${g},${b},${a})`;
}

/** Clareia (amount > 0) ou escurece (amount < 0) um hex. */
function shade(hex, amount) {
  const { r, g, b } = hexToRgb(hex);
  const f = (c) => Math.round(clamp(amount > 0 ? c + (255 - c) * amount : c * (1 + amount), 0, 255));
  return `#${[f(r), f(g), f(b)].map(c => c.toString(16).padStart(2, '0')).join('')}`;
}

/* --------------------------------------------------------------- matiz --
   Cor propria: o seletor e um cursor de MATIZ, nao um quadrado de saturacao e
   luminosidade a que se junta um cursor.

   E deliberado. Uma cor de destaque tem de se ler sobre vidro escuro: muito
   clara desaparece no branco do texto, muito escura desaparece no fundo, e
   dessaturada deixa de ser destaque. Fixando saturacao e luminosidade nos
   valores em que este painel funciona, todas as cores que o cursor alcanca sao
   utilizaveis — nao ha como escolher uma que estrague a leitura.

   Quem quiser um valor exacto tem o campo hexadecimal ao lado, sem limites. */
const HUE_S = 0.78, HUE_L = 0.58;

function hueToHex(h, s = HUE_S, l = HUE_L) {
  const a = s * Math.min(l, 1 - l);
  const f = (n) => {
    const k = (n + h / 30) % 12;
    const c = l - a * Math.max(-1, Math.min(k - 3, 9 - k, 1));
    return Math.round(255 * c).toString(16).padStart(2, '0');
  };
  return `#${f(0)}${f(8)}${f(4)}`;
}

/** Matiz (0-360) de um hex. Serve para o cursor abrir na cor que ja esta. */
function hexToHue(hex) {
  if (!isHex(hex)) return 0;
  const { r, g, b } = hexToRgb(hex);
  const R = r / 255, G = g / 255, B = b / 255;
  const mx = Math.max(R, G, B), mn = Math.min(R, G, B), d = mx - mn;
  if (d === 0) return 0;
  let h;
  if (mx === R)      h = ((G - B) / d) % 6;
  else if (mx === G) h = (B - R) / d + 2;
  else               h = (R - G) / d + 4;
  h = Math.round(h * 60);
  return h < 0 ? h + 360 : h;
}

/** O Lua rejeita qualquer coisa que nao seja #rrggbb e cai no valor por
    defeito — silenciosamente. Validar aqui evita que uma cor mal escrita
    apareca como um "reset" inexplicavel. */
function isHex(v) {
  return typeof v === 'string' && /^#[0-9a-fA-F]{6}$/.test(v);
}

/* ------------------------------------------------------------------- NUI -- */
async function post(name, data = {}) {
  try {
    const res = await fetch(`https://${RES}/${name}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json; charset=UTF-8' },
      body: JSON.stringify(data),
    });
    return await res.json();
  } catch (e) {
    // Fora do jogo (browser), os callbacks nao existem. Nao rebentar a UI.
    console.warn('[oxlyn] callback falhou:', name, e);
    return { ok: false };
  }
}

/* ------------------------------------------------------------------ i18n -- */
const I18N = {
  dict: {},
  set(dict) { this.dict = dict || {}; this.apply(); },
  t(key, fallback) { return this.dict[key] ?? fallback ?? key; },
  apply(root = document) {
    $$('[data-i18n]', root).forEach(node => {
      const key = node.dataset.i18n;
      if (this.dict[key]) node.textContent = this.dict[key];
    });
    const search = $('#settingSearch');
    if (search && this.dict['se_search']) search.placeholder = this.dict['se_search'];
  },
};

/* ------------------------------------------------------------------ misc -- */
/** Interpolador suave para os valores nao saltarem entre ticks de 100ms. */
class Smoothed {
  constructor(value = 0, speed = 0.22) { this.v = value; this.target = value; this.speed = speed; }
  set(target) { this.target = target; }
  step() { this.v += (this.target - this.v) * this.speed; return this.v; }
  jump(v) { this.v = this.target = v; return v; }
}

/** Entrada escalonada numa lista ja inserida no DOM.
    O atraso e limitado por `max`: numa lista de 40 definicoes, um incremento
    sem tecto faria o ultimo item aparecer mais de um segundo depois do
    primeiro — o utilizador ficava a olhar para uma lista a preencher-se em
    vez de a poder usar. Com tecto, a onda percorre o inicio da lista e o
    resto entra junto. */
function stagger(nodes, step = 26, max = 240) {
  let i = 0;
  for (const node of nodes) {
    node.classList.add('anim-in');
    node.style.animationDelay = `${Math.min(i * step, max)}ms`;
    i++;
  }
}

function debounce(fn, ms) {
  let id;
  return (...args) => { clearTimeout(id); id = setTimeout(() => fn(...args), ms); };
}

/** Copia texto sem depender do clipboard API (bloqueado dentro da NUI). */
function copyText(text) {
  const ta = el('textarea', { style: 'position:fixed;opacity:0;top:-1000px' });
  ta.value = text;
  document.body.append(ta);
  ta.select();
  let ok = false;
  try { ok = document.execCommand('copy'); } catch (_) { ok = false; }
  ta.remove();
  return ok;
}

/* ==========================================================================
   ESCALA DA INTERFACE  ·  2K e 4K
   --------------------------------------------------------------------------
   O painel foi desenhado numa caixa de 1300x780 pontos, com tipos, margens e
   raios em pixeis absolutos. Isso e uma escolha deliberada — em pixeis o
   desenho e sempre o mesmo — mas tem uma consequencia: o desenho nao encolhe,
   e o ecra cresce a volta dele. Em 1080p a caixa enche a maior parte do ecra;
   em 1440p ocupa metade; em 4K pouco mais de um terco, e le-se como letra
   miuda vista de longe.

   A correccao e escalar o painel INTEIRO, e nao cada regra de CSS. Usamos
   `zoom` e nao `transform: scale()` por uma razao concreta: o zoom entra no
   LAYOUT — a caixa passa mesmo a medir mais, e o centramento, o `place-items`
   do pai e as posicoes `fixed` continuam a bater certo sozinhos. Com um
   transform a caixa continuaria a medir 1300 pontos para o pai, o painel
   ficaria descentrado e todos os menus que abrem por coordenadas teriam de
   ser corrigidos a mao.

   A curva nao e proporcional. Escalar 4K por 2.0 daria um painel correcto na
   proporcao e desagradavel na pratica — texto enorme, muito espaco morto. O
   expoente 0.72 devolve cerca de +23% em 1440p e +62% em 4K: o suficiente
   para o painel voltar a ler-se a distancia normal de jogo, sem virar um
   cartaz. Abaixo de 1080p nao encolhemos nada (ha um breakpoint no CSS que
   trata dos ecras pequenos, e encolher texto ja pequeno so o tornaria
   ilegivel).
   ========================================================================== */
const UiScale = {
  /** Escala em vigor. 1 = tamanho de desenho original. */
  value: 1,

  /** Preferencias vindas do Lua. */
  auto: true,
  user: 1,

  /* Dimensoes de desenho do painel (as mesmas do .app__grid no CSS). Servem
     para garantir que a escala nunca empurra o painel para fora do ecra. */
  DESIGN_W: 1300,
  DESIGN_H: 780,

  /** Fraccao maxima do ecra que o painel pode ocupar depois de escalado. */
  FIT: 0.96,

  autoFactor() {
    const vw = window.innerWidth  || 1920;
    const vh = window.innerHeight || 1080;
    // A dimensao mais apertada manda: num ultrawide 3440x1440 quem decide e a
    // altura, senao o painel crescia para lá do que a altura aguenta.
    const rel = Math.min(vw / 1920, vh / 1080);
    if (rel <= 1) return 1;
    return Math.pow(rel, 0.72);
  },

  compute() {
    const z = (this.auto ? this.autoFactor() : 1) * (this.user || 1);
    const vw = window.innerWidth  || 1920;
    const vh = window.innerHeight || 1080;
    // Tecto de seguranca: com a escala manual no maximo e um ecra pequeno, o
    // painel chegaria as bordas e a barra inferior sairia do ecra.
    const fitW = (vw * this.FIT) / this.DESIGN_W;
    const fitH = (vh * this.FIT) / this.DESIGN_H;
    return clamp(Math.min(z, Math.max(1, fitW), Math.max(1, fitH)), 0.75, 2.2);
  },

  /** Recalcula e aplica. Devolve true se a escala mudou. */
  apply(cfg) {
    if (cfg) {
      if (typeof cfg.autoScale === 'boolean') this.auto = cfg.autoScale;
      if (typeof cfg.scale === 'number' && cfg.scale > 0) this.user = cfg.scale;
    }
    const z = round(this.compute(), 3);
    if (z === this.value) return false;
    this.value = z;
    document.documentElement.style.setProperty('--ui-zoom', String(z));
    return true;
  },

  /* ------------------------------------------------------------------------
     NITIDEZ DOS CANVAS COM ZOOM
     ---------------------------
     Um canvas dentro de um elemento com zoom e desenhado a resolucao logica e
     so depois ampliado — o que em 4K se ve como texto e linhas ligeiramente
     esborratados. A correccao e multiplicar o backing store pela escala.

     O problema e que os motores nao concordam sobre o que `clientWidth`
     devolve dentro de um zoom: as versoes antigas do Chromium devolvem a
     medida JA multiplicada, as recentes devolvem a medida logica. Adivinhar
     errado dava um canvas com metade ou o dobro da resolucao certa.

     Por isso perguntamos ao proprio motor, uma vez: medimos uma caixa de
     100px dentro de um zoom de 2 e vemos o que ele responde.
   ------------------------------------------------------------------------ */
  _reports: null,

  /** true se clientWidth ja vem multiplicado pelo zoom neste motor. */
  reportsZoom() {
    if (this._reports !== null) return this._reports;
    let probe = null;
    try {
      probe = el('div', {
        style: 'position:absolute;left:-9999px;top:0;width:100px;height:10px;zoom:2',
      });
      document.body.append(probe);
      this._reports = probe.clientWidth > 150;
    } catch (_) {
      this._reports = false;
    } finally {
      if (probe) probe.remove();
    }
    return this._reports;
  },

  /** Divisor a aplicar a clientWidth para voltar ao espaco de desenho. */
  layoutDivisor() {
    return this.reportsZoom() ? this.value : 1;
  },

  /*  NAO existe aqui um par toScreen/toLocal, e a ausencia e deliberada.

      Existiu, e converteu coordenadas dividindo e multiplicando pela escala.
      A conta esta certa para UM dos dois modelos de zoom que os motores
      implementam, e errada para o outro — getBoundingClientRect() devolve
      pixeis de ecra no Chromium recente e pixeis de layout no CEF que o
      FiveM embute. Resultado: menus alinhados no browser e deslocados
      duzentos pixeis no jogo, sem nada no codigo a dizer porque.

      Quem precisar de posicionar um elemento por coordenadas deve MEDIR a
      relacao em vez de a assumir: escrever duas posicoes conhecidas, ver
      onde o rectangulo aterra e derivar o factor. Ha um exemplo completo
      em Dropdown.open (html/js/settings.js).                            */

  /** Multiplicador do backing store, por cima do devicePixelRatio. */
  pixelScale() {
    return this.value;
  },
};
