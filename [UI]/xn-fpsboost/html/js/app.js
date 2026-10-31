/* ==========================================================================
   oxlyn-fpsboost · app.js
   Ponto de entrada da NUI. Recebe mensagens do Lua e mantem o painel a par.
   ========================================================================== */

const App = {
  open: false,
  view: 'overview',

  schema: { groups: [], settings: [], presets: [] },
  values: {},
  static: {},
  ui: {
    accent: '#FF2E43',
    // Escala: os mesmos valores de fabrica que o schema do Lua declara, para
    // o painel nunca aparecer com uma escala diferente daquela que a
    // definicao diz ter enquanto a configuracao nao chega.
    autoScale: true,
    scale: 1,
    blur: true,
    backdrop: 0.32,
    threeD: true,
    float: true,
    animations: true,
    sounds: true,
    chartRange: '1m',
    chartGlow: 0.55,
    showEstimates: true,
    showEstimateBadge: true,
  },

  chartRange: '1m',
  graphRange: '1m',
  graphSeries: 'fps',
  lastTick: null,
  previewResult: null,
};

/* ==========================================================================
   COMPONENTES
   ========================================================================== */
const mainChart = new LineChart($('#mainChart'), {
  xLabels: ['-60s', '-45s', '-30s', '-15s', 'Now'],
});
const bigChart = new LineChart($('#bigChart'), { padLeft: 52, padBottom: 30 });
const statusGauge = new ArcGauge($('#statusGauge'));
const hudSpark = new Sparkline($('#hudSpark'), { points: 64 });

const gauges = {};
$$('.gauge').forEach(node => {
  gauges[node.dataset.metric] = new RingGauge(node.querySelector('.gauge__ring'), {
    max: node.dataset.metric === 'ping' ? 300 : 100,
  });
});

const settingsView = new SettingsView($('#groupRail'), $('#settingsList'),
  onSettingChange, onSettingPreview);

/* ==========================================================================
   SONS
   --------------------------------------------------------------------------
   Quem toca e o jogo, atraves de PlaySoundFrontend no Lua. A NUI so pede.

   Um <audio> aqui teria de carregar ficheiros, sairia pelo canal de audio do
   browser — que ignora o volume de efeitos configurado pelo jogador — e nao
   soaria ao GTA. Assim, o som passa pelo mixer do proprio jogo.
   ========================================================================== */
function sfx(name) {
  if (App.ui.sounds === false) return;
  post('sound', { name });
}

/* Um so listener em vez de um por botao. Corre na fase de CAPTURA porque
   alguns alvos desaparecem no proprio clique — uma opcao do dropdown, por
   exemplo, e removida do DOM pelo seu handler, e na fase de bolha ja nao
   havia elemento nenhum para identificar. */
document.addEventListener('click', (e) => {
  if (App.ui.sounds === false) return;
  const t = e.target;
  if (!(t instanceof Element)) return;

  if (t.closest('.nav__item'))    return sfx('nav');
  if (t.closest('.toggle'))       return sfx('toggle');
  if (t.closest('.selmenu__opt')) return sfx('click');
  if (t.closest('.btn, .sel, .range, .iconbtn, .swatch, .preset, ' +
                '.segmented button, .grouprail button, .switchline')) {
    return sfx('click');
  }
}, true);

/* ==========================================================================
   TOASTS
   ========================================================================== */
function toast(message, kind = 'info', title = 'OXLYN FPS', duration = 4000) {
  // So erro e sucesso tocam. Um aviso sonoro em cada mensagem informativa
  // (boost automatico, alertas de FPS) tornar-se-ia ruido em poucos minutos.
  if (kind === 'error' || kind === 'success') sfx(kind);

  const node = el('div', { class: `toast toast--${kind}` },
    el('i', { class: 'toast__bar' }),
    el('div', {},
      el('div', { class: 'toast__title', text: title }),
      el('div', { text: message })
    )
  );
  $('#toasts').append(node);
  setTimeout(() => {
    node.classList.add('toast--out');
    setTimeout(() => node.remove(), 280);
  }, duration);
}

/* ==========================================================================
   MODAL DE CONFIRMACAO
   --------------------------------------------------------------------------
   O confirm() do browser abre uma caixa cinzenta do Chromium por cima do
   painel — mata o design e, em algumas versoes do CEF, bloqueia o render da
   NUI ate ser respondido. Este substitui-o e devolve uma Promise.
   ========================================================================== */
function confirmModal(title, body, yesLabel, noLabel) {
  return openModal({ title, body, yesLabel, noLabel });
}

/* Mesmo modal, com um campo de texto. Devolve a string escrita, ou null se o
   jogador desistiu — quem chama distingue "nao quis" de "escreveu algo".

   Nao e um prompt() do browser pela mesma razao que confirmModal nao e um
   confirm(): a caixa do Chromium por cima da NUI mata o design e, em algumas
   versoes do CEF, bloqueia o render ate ser respondida. */
function promptModal(title, body, { value = '', placeholder = '', yesLabel } = {}) {
  return openModal({ title, body, yesLabel, input: { value, placeholder } });
}

function openModal({ title, body, yesLabel, noLabel, input = null }) {
  return new Promise(resolve => {
    const node  = $('#modal');
    const field = $('#modalInput');

    $('#modalTitle').textContent = title;
    $('#modalBody').textContent  = body;
    $('#modalYes').textContent   = yesLabel || I18N.t('pf_confirm_y');
    $('#modalNo').textContent    = noLabel  || I18N.t('pf_confirm_n');

    field.hidden = !input;
    if (input) {
      field.value = input.value || '';
      field.placeholder = input.placeholder || '';
    }
    node.classList.remove('modal--hidden');
    // Depois de remover a classe: um elemento ainda escondido nao aceita foco.
    if (input) { field.focus(); field.select(); }

    const answer = () => input ? field.value.trim() : true;

    const finish = (ok) => {
      node.classList.add('modal--hidden');
      $('#modalYes').removeEventListener('click', onYes);
      $('#modalNo').removeEventListener('click', onNo);
      document.removeEventListener('keydown', onKey, true);
      resolve(ok ? answer() : (input ? null : false));
    };
    const onYes = () => {
      // Um nome vazio nao fecha o modal: fechar sem guardar e sem dizer porque
      // pareceria que o botao nao funcionou.
      if (input && !field.value.trim()) { field.focus(); return; }
      finish(true);
    };
    const onNo  = () => finish(false);
    const onKey = (e) => {
      if (e.key === 'Escape') { e.stopPropagation(); finish(false); }
      if (e.key === 'Enter')  { e.stopPropagation(); onYes(); }
    };

    $('#modalYes').addEventListener('click', onYes);
    $('#modalNo').addEventListener('click', onNo);
    document.addEventListener('keydown', onKey, true);
  });
}

/* ==========================================================================
   TEMA
   ========================================================================== */
function applyUiConfig(cfg) {
  Object.assign(App.ui, cfg || {});
  const root = document.documentElement;
  const a = App.ui.accent;

  // Todos os derivados sao calculados aqui e injectados como variaveis CSS.
  // Ver o comentario em :root — nao usamos color-mix() por compatibilidade
  // com versoes mais antigas do CEF que o FiveM embute.
  root.style.setProperty('--accent',       a);
  root.style.setProperty('--accent-2',     shade(a, 0.28));
  root.style.setProperty('--accent-soft',  rgba(a, 0.16));
  root.style.setProperty('--accent-soft2', rgba(a, 0.30));
  root.style.setProperty('--accent-line',  rgba(a, 0.42));
  root.style.setProperty('--accent-glow',  rgba(a, 0.45));
  // Paragens intermedias: ver o comentario em :root. O w0 e a propria cor com
  // alfa 0, nao `transparent` — e o que evita a faixa escura no fim do degrade.
  root.style.setProperty('--accent-w1',    rgba(a, 0.22));
  root.style.setProperty('--accent-w2',    rgba(a, 0.12));
  root.style.setProperty('--accent-w3',    rgba(a, 0.05));
  root.style.setProperty('--accent-w0',    rgba(a, 0));
  root.style.setProperty('--accent-text',  shade(a, 0.34));
  // Aresta lateral do simbolo em relevo: a mesma cor, muito escurecida. Usar
  // preto puro faria a espessura parecer uma sombra solta em vez de material.
  root.style.setProperty('--accent-deep',  shade(a, -0.62));

  root.style.setProperty('--backdrop', String(App.ui.backdrop ?? 0.32));

  /* Escala da interface. Vem antes de tudo o que mede o DOM: mudar o zoom
     muda a caixa de todos os canvas, e desenha-los com a medida antiga
     deixava-os esticados ate ao proximo redesenho. */
  if (UiScale.apply({ autoScale: App.ui.autoScale, scale: App.ui.scale })) {
    // O marcador da navegacao guarda uma posicao em pixeis: com outra escala
    // essa posicao deixa de corresponder ao item activo.
    moveNavMarker();
  }

  document.body.classList.toggle('no-blur', !App.ui.blur);
  document.body.classList.toggle('no-anim', !App.ui.animations);
  document.body.classList.toggle('no-3d',    App.ui.threeD === false);
  document.body.classList.toggle('no-float', App.ui.float === false);

  mainChart.setAccent(App.ui.accent);
  bigChart.setAccent(App.ui.accent);
  statusGauge.setAccent(App.ui.accent);
  hudSpark.setAccent(App.ui.accent);
  Object.values(gauges).forEach(g => g.setAccent(App.ui.accent));

  // Brilho dos graficos. Vive numa definicao propria em vez de estar preso ao
  // "Suavizar": esse muda a FORMA da linha, este muda quanta luz ela emite.
  // Sao duas coisas diferentes e cada uma tem o seu controlo.
  const cg = (typeof App.ui.chartGlow === 'number') ? App.ui.chartGlow : 0.55;
  mainChart.opts.glow = cg;
  bigChart.opts.glow  = cg;
  hudSpark.opts.glow  = cg;
  // Redesenhar e sempre necessario depois de mexer na escala ou no brilho.
  if (App.open) redrawAllCanvases();

  // Estimativas escondidas: a linha de aneis inteira sai do layout.
  const row = $('#gaugeRow');
  const hideAll = !App.ui.showEstimates;
  $$('.gauge', row).forEach(node => {
    node.hidden = hideAll && node.dataset.metric !== 'ping';
  });
  row.hidden = false;
  $$('.gauge__tag.est', row).forEach(tag => { tag.hidden = !App.ui.showEstimateBadge; });

  if (App.ui.chartRange && App.ui.chartRange !== App.chartRange) {
    setChartRange(App.ui.chartRange);
  }
}

/* ==========================================================================
   NAVEGACAO
   ========================================================================== */
const VIEW_META = {
  overview:    ['ov_title', 'ov_sub'],
  performance: ['pf_title', 'pf_sub'],
  graph:       ['gr_title', 'gr_sub'],
  system:      ['sy_title', 'sy_sub'],
  settings:    ['se_title', 'se_sub'],
  about:       ['ab_title', 'ab_sub'],
};

/** Desloca o indicador de posicao para o item activo. */
function moveNavMarker() {
  const active = $('.nav__item.is-active');
  const marker = $('#navMarker');
  if (!active || !marker) return;

  // offsetTop e relativo a .nav, que e position:relative — o mesmo referencial
  // do marcador. Medir aqui, e nao guardar posicoes, e o que faz isto continuar
  // certo quando o item de admin aparece e empurra os restantes para baixo.
  const h = marker.offsetHeight || 20;
  const y = active.offsetTop + (active.offsetHeight - h) / 2;
  marker.style.transform = `translateY(${Math.round(y)}px)`;
  marker.style.opacity = '1';
}

function goto(view) {
  if (!VIEW_META[view]) return;
  App.view = view;

  $$('.nav__item').forEach(b => b.classList.toggle('is-active', b.dataset.view === view));
  moveNavMarker();
  $$('.view').forEach(v => v.classList.toggle('is-active', v.dataset.view === view));

  /* Cada vista tem o seu proprio scroll e guarda-o. Voltar a um separador que
     tinha ficado a meio devolvia-o exactamente onde estava — mas com a vista
     escondida entretanto, ninguem se lembra de onde a deixou, e o que aparece
     e um cabecalho cortado a meio.

     `scrollTop = 0` e nao scrollTo({behavior:'smooth'}): a vista esta a entrar
     com a animacao viewIn, e uma segunda animacao a deslizar o conteudo por
     dentro dela ao mesmo tempo le-se como um salto, nao como suavidade. */
  const next = $(`.view[data-view="${view}"]`);
  if (next) next.scrollTop = 0;

  const [tKey, sKey] = VIEW_META[view];
  $('#viewTitle').textContent = I18N.t(tKey);
  $('#viewSub').textContent   = I18N.t(sKey);

  // O indicador "AO VIVO" so faz sentido nas vistas que actualizam sozinhas.
  const live = ['overview', 'graph'].includes(view);
  $('#liveDot').style.display = live ? '' : 'none';
  $('.live__label').style.display = live ? '' : 'none';

  // Entrar num separador reconstroi o conteudo dele COM animacao. As
  // actualizacoes periodicas que se seguem passam `false` e limitam-se a
  // mexer nos valores.
  if (view === 'performance') renderPresets(true);
  if (view === 'graph')       refreshGraph();
  if (view === 'system')      renderSystem(true);
  if (view === 'about')       renderAbout(true);
  if (view === 'settings')    settingsView.renderList(true);
}

$('#nav').addEventListener('click', e => {
  const btn = e.target.closest('.nav__item');
  if (btn) goto(btn.dataset.view);
});

$('#btnOpenSettings').addEventListener('click', () => goto('settings'));
$('#btnQuickSettings').addEventListener('click', () => goto('settings'));

/* ==========================================================================
   OVERVIEW
   ========================================================================== */
function fpsColor(fps) {
  const t = App.thresholds || { excellent: 120, good: 60, poor: 30 };
  if (fps >= t.excellent) return '#34E08A';
  if (fps >= t.good)      return App.ui.accent;
  if (fps >= t.poor)      return '#FFC531';
  return '#FF4B57';
}

function pingColor(ping) {
  const t = App.thresholds || { pingGood: 60, pingWarn: 120 };
  if (ping <= t.pingGood) return '#34E08A';
  if (ping <= t.pingWarn) return '#FFC531';
  return '#FF4B57';
}

function statusOf(fps) {
  const t = App.thresholds || { excellent: 120, good: 60, poor: 30 };
  if (fps >= t.excellent) return ['st_excellent', 'st_excellent_d', '#34E08A'];
  if (fps >= t.good)      return ['st_good',      'st_good_d',      App.ui.accent];
  if (fps >= t.poor)      return ['st_poor',      'st_poor_d',      '#FFC531'];
  return ['st_bad', 'st_bad_d', '#FF4B57'];
}

/** Redesenha todos os canvas. Usado depois da abertura e ao redimensionar. */
function redrawAllCanvases() {
  mainChart.draw();
  bigChart.draw();
  statusGauge.draw();
  Object.values(gauges).forEach(g => g.draw());
}

/* --------------------------------------------------------------------------
   O que esta SEMPRE visivel, seja qual for o separador aberto: a coluna
   direita (estado do FPS e dicas), a barra inferior e a pilula do servidor.

   Estava tudo dentro de updateOverview, que so corre no separador Resumo —
   por isso o "Estado do FPS" congelava assim que se mudava de separador,
   apesar de continuar a ver-se no ecra. Um indicador ao vivo que so esta vivo
   numa das vistas e pior do que nao existir.
   -------------------------------------------------------------------------- */
function updateChrome(d) {
  const f = d.fps, m = d.metrics.real;

  /* estado do FPS (coluna direita).
     A cor fica guardada em App._statusColor para o canal rapido a poder
     reutilizar sem recalcular o veredito vinte vezes por segundo. */
  const [vKey, dKey, color] = statusOf(f.average || f.current);
  App._statusColor = color;
  statusGauge.opts.max = Math.max(240, Math.ceil((f.sessionMax || 0) / 60) * 60);
  statusGauge.set(f.current, color);
  setText($('#statusFps'), f.current);
  const verdict = $('#statusVerdict');
  setText(verdict, I18N.t(vKey));
  verdict.style.color = color;
  setText($('#statusDesc'), I18N.t(dKey));

  renderTips(d.tips);

  /* barra inferior */
  setText($('#bbRes'), m.screenW ? `${m.screenW} x ${m.screenH}` : '—');
  setText($('#bbEnt'), fmtNum(m.totalEntities));
  setText($('#bbUptime'), fmtDuration(d.uptime));
  setText($('#bbClock'), `${pad2(d.clock.h)}:${pad2(d.clock.m)}`);
  // A data e a unica coisa aqui que nao muda ao ritmo do tick. Formata-la 20x
  // por segundo seria criar um Date e correr o Intl por nada.
  // O formato segue o idioma escolhido (chave date_locale), em vez de estar
  // fixo em pt-PT — 01/09/2026 e 09/01/2026 sao datas diferentes conforme a
  // convencao, e mostrar a errada e pior do que nao mostrar nenhuma.
  if (!App._dateStr) {
    App._dateStr = new Date().toLocaleDateString(I18N.t('date_locale', 'en-GB'));
  }
  if ($('#bbDate').textContent !== App._dateStr) setText($('#bbDate'), App._dateStr);

  const preset = App.schema.presets?.find(p => p.id === d.preset);
  setText($('#bbPreset'), preset ? preset.label : d.preset);

  /* pilula do servidor (cabecalho) */
  setText($('#serverName'), m.serverName || 'FiveM Server');
  setText($('#playerCount'), `${m.players}/${m.maxPlayers}`);
}

/* Apenas o que vive dentro do separador Resumo. */
function updateOverview(d) {
  const f = d.fps, m = d.metrics.real, e = d.metrics.estimated;

  setText($('#fpsBig'), f.current);
  $('#stAvg').textContent   = f.average;
  $('#stLow1').textContent  = f.low1;
  setText($('#stLow01'), f.low01);
  $('#stMax').textContent   = f.max;
  $('#stMin').textContent   = f.min;
  $('#stFt').textContent    = f.frametime.toFixed(1);

  /* delta vs. minuto anterior */
  const delta = $('#fpsDelta');
  const pct = f.deltaPct || 0;
  delta.classList.toggle('delta--down', pct < 0);
  delta.classList.toggle('delta--flat', pct === 0);
  setText(delta.querySelector('b'), `${pct > 0 ? '+' : ''}${pct}%`);

  /* aneis */
  gauges.cpu?.set(e.cpu, App.ui.accent);
  gauges.gpu?.set(e.gpu, App.ui.accent);
  gauges.ram?.set(e.ram, App.ui.accent);
  gauges.vram?.set(e.vram, App.ui.accent);
  gauges.ping?.set(Math.min(m.ping, 300), pingColor(m.ping));

  $('#gCpu').textContent  = e.cpu;
  $('#gGpu').textContent  = e.gpu;
  $('#gRam').textContent  = e.ram;
  setText($('#gVram'), e.vram);
  setText($('#gPing'), m.ping);

  /* carga do mundo */
  renderWorld(m);
}

/* ---------------------------------------------------------- carga do mundo --
   `ref` e um tecto tipico por categoria, usado so para dar escala a barrinha.
   Nao pretende ser um limite do jogo: serve para se ver de relance qual das
   categorias esta a pesar mais neste momento. */
const WORLD_METRICS = [
  { key: 'peds',        label: 'sy_peds',     ref: 250 },
  { key: 'vehicles',    label: 'sy_vehicles', ref: 120 },
  { key: 'objects',     label: 'sy_objects',  ref: 600 },
  { key: 'pickups',     label: 'sy_pickups',  ref: 60  },
  { key: 'nearPlayers', label: 'sy_players',  ref: 32  },
];

let worldTiles = null;

/** Constroi os mosaicos uma unica vez e depois so actualiza valores.
    A 20Hz, recriar estes nos em cada tick seria ~100 elementos por segundo
    deitados fora para mostrar cinco numeros. */
function renderWorld(m) {
  const grid = $('#worldGrid');
  if (!grid) return;

  if (!worldTiles) {
    grid.replaceChildren();
    worldTiles = WORLD_METRICS.map(def => {
      const value = el('b', { text: '0' });
      const bar   = el('i');
      grid.append(el('div', { class: 'wtile' },
        el('span', { text: I18N.t(def.label) }),
        value,
        el('div', { class: 'wbar' }, bar)));
      return { def, value, bar };
    });
  }

  for (const t of worldTiles) {
    const v = m[t.def.key] || 0;
    setText(t.value, fmtNum(v));
    const pct = clamp(v / t.def.ref, 0, 1);
    t.bar.style.width = (pct * 100).toFixed(1) + '%';
    t.bar.classList.toggle('is-high', pct > 0.8);
  }
}

function renderTips(tips) {
  const list = $('#tipsList');
  const sig = JSON.stringify(tips);
  if (list.dataset.sig === sig) return;   // evita re-render a 10Hz
  list.dataset.sig = sig;
  list.replaceChildren();
  for (const tip of tips || []) {
    list.append(el('li', { class: `is-${tip.kind}`, text: tip.text }));
  }
  // Chega-se aqui apenas quando as dicas mudaram mesmo — a assinatura acima
  // trava o resto. Por isso animar e seguro e assinala que ha texto novo.
  stagger(list.children, 50, 200);
}

/* ---------------------------------------------------------------- chart -- */
const RANGE_SECONDS = { '1m': 60, '5m': 300, '15m': 900, '1h': 3600 };

/* Rotulos do eixo do tempo, gerados a partir do historico que EXISTE.
   -----------------------------------------------------------------
   Eram fixos: o intervalo "1M" mostrava sempre -60s..Agora, mesmo com trinta
   segundos de historico. A serie desenhava-se a largura toda, e portanto trinta
   segundos de dados apareciam espalhados por um eixo que dizia sessenta — o
   grafico contradizia os proprios rotulos.

   O eixo passa a acompanhar o que ha: com 35s medidos le-se -35s..Agora e a
   linha comeca na esquerda. A medida que o historico enche, os rotulos sobem
   sozinhos ate ao intervalo escolhido.

   `filled` vem do Lua e e a fraccao do intervalo ja preenchida. */
function fmtAgo(sec) {
  if (sec < 100) return `-${Math.round(sec)}s`;
  const m = sec / 60;
  const r = Math.round(m);
  // Uma casa decimal so quando o valor nao e praticamente redondo: escrever
  // "-5.0m" onde "-5m" chega e ruido, e arredondar -5.3m para -5m e mentir.
  return Math.abs(m - r) < 0.06 ? `-${r}m` : `-${(Math.round(m * 10) / 10).toFixed(1)}m`;
}

function buildTimeLabels(range, filled) {
  const span = (RANGE_SECONDS[range] || 60) * clamp(filled ?? 1, 0.02, 1);
  // Cinco divisoes para 5M — 300s dividido em cinco da minutos inteiros — e
  // quatro para os restantes, que ja caem em valores redondos assim.
  const n = range === '5m' ? 5 : 4;
  const out = [];
  for (let i = 0; i < n; i++) out.push(fmtAgo(span * (1 - i / n)));
  out.push(I18N.t('ov_now', 'Now'));
  return out;
}

let mainChartRequest = 0;
async function refreshMainChart() {
  if (!App.open || App.view !== 'overview') return;
  const range = App.chartRange;
  const request = ++mainChartRequest;
  const res = await post('requestChart', { series: 'fps', range });
  if (!res.ok || !App.open || App.view !== 'overview'
      || request !== mainChartRequest || range !== App.chartRange) return;
  mainChart.opts.xLabels = buildTimeLabels(App.chartRange, res.chart.filled);
  mainChart.setData(res.chart);
  $('#chartEmpty').hidden = (res.chart.avg || []).length > 2;
}

function setChartRange(range) {
  App.chartRange = range;
  $$('#rangeBar .range').forEach(b => b.classList.toggle('is-active', b.dataset.range === range));
  refreshMainChart();
}

$('#rangeBar').addEventListener('click', e => {
  const btn = e.target.closest('.range');
  if (btn) setChartRange(btn.dataset.range);
});

/* ==========================================================================
   PRESETS
   ========================================================================== */
/* Quantas definicoes de OTIMIZACAO e que o jogador mexeu e ainda nao guardou.
   -------------------------------------------------------------------------
   O Lua tambem sabe isto e envia-o no schema, mas o schema so e reconstruido
   quando muda de estrutura. Mexer num interruptor nao o reconstroi — e o
   cartao do rascunho ficaria a dizer "3 definicoes" com cinco alteradas.

   Contando aqui, a partir dos overrides que vem em cada actualizacao de
   valores, o cartao acompanha cada clique sem uma ida ao Lua.

   Os grupos `interface` e `hud` nao contam: sao gostos pessoais e nao fazem
   parte de um perfil de desempenho. A mesma regra do lado do Lua. */
function draftCount() {
  const ov = App.values.overrides || {};
  const settings = App.schema.settings || [];
  let n = 0;
  for (const s of settings) {
    if (s.group === 'interface' || s.group === 'hud') continue;
    if (ov[s.id] !== undefined) n++;
  }
  return n;
}

function renderPresets(animate = false) {
  const grid = $('#presetGrid');
  grid.replaceChildren();

  for (const p of App.schema.presets || []) {
    const isActive = App.values.preset === p.id;

    // O rascunho e o unico cartao cujo conteudo muda sem o schema mudar.
    const count = p.kind === 'draft' ? draftCount() : 0;
    const desc  = p.kind === 'draft'
      ? (count > 0 ? I18N.t('pf_draft_d').replace('%s', count) : I18N.t('pf_draft_empty'))
      : p.desc;

    const card = el('div', {
      class: `preset${isActive ? ' is-active' : ''}${p.locked ? ' is-locked' : ''}`
           + (p.kind ? ` preset--${p.kind}` : ''),
    });

    const icon = el('div', { class: 'preset__icon' });
    icon.innerHTML = svgIcon(p.icon || 'sliders');

    /* "Ativo" e "Bloqueado" ficam ao lado do nome: sao curtas em qualquer
       idioma e cabem sempre.

       O selo de alteracoes por guardar NAO. "POR GUARDAR" ja nao cabia, e
       noutros idiomas e ainda mais longa — NIET OPGESLAGEN, NON ENREGISTRÉ.
       Numa linha partilhada com o nome nao ha largura que chegue: o nome nao
       encolhe, o selo tem flex:none, e o que sobra e cortado pelo overflow do
       cartao. Por isso vai para uma linha propria, logo abaixo do nome. */
    const top = el('div', { class: 'preset__top' },
      icon,
      el('div', { class: 'preset__name', text: p.label }),
      isActive ? el('div', { class: 'preset__badge', text: I18N.t('pf_applied') }) :
      p.locked ? el('div', { class: 'preset__badge', text: I18N.t('pf_locked') }) : null
    );

    card.append(top);

    if (!isActive && !p.locked && p.kind === 'draft' && count > 0) {
      card.append(el('div', {
        class: 'preset__badge preset__badge--draft',
        text: I18N.t('pf_unsaved'),
      }));
    }

    card.append(el('div', { class: 'preset__desc', text: desc }));

    /* As barras vem medidas do Lua (ver Oxlyn.PresetBars), de 0 a 1 e ja
       normalizadas entre os presets deste servidor. Um perfil guardado pelo
       jogador nao tem essas medidas, e inventa-las seria pior do que nao as
       mostrar.

       Cinco segmentos e nao tres: com tres, seis presets so tem quatro
       degraus possiveis e os do topo acabam todos iguais. Qualquer preset que
       faca alguma coisa acende pelo menos um — zero segmentos le-se como "nao
       muda nada", que so e verdade para o Desligado. */
    if (!p.kind) {
      /* Truncar, e nao arredondar: com arredondamento o Extremo (98%) e o
         Batata (100%) davam os mesmos cinco segmentos, e o degrau entre os
         dois presets mais agressivos e justamente o que interessa ver. A
         truncatura reserva o ultimo segmento para quem esta mesmo no topo.
         Qualquer preset que faca alguma coisa acende pelo menos um: zero
         segmentos le-se como "nao muda nada", e isso so e verdade para o
         Desligado. */
      const seg = (v) => {
        const n = Math.floor((v || 0) * BAR_SEGMENTS);
        return (v > 0 && n === 0) ? 1 : n;
      };
      const gain = seg(p.impact);
      const visual = seg(p.visual);
      card.append(el('div', { class: 'bars' },
        barline(I18N.t('pf_impact'), gain, 'gain'),
        barline(I18N.t('pf_visual'), visual, 'visual')
      ));
    }

    const actions = el('div', { class: 'preset__actions' });

    if (p.kind === 'draft') {
      /* O cartao do rascunho.
         Nao tem "Aplicar": um rascunho SAO as definicoes em vigor neste
         momento, nao ha nada para aplicar. Era esse o botao que nao fazia
         nada, ao lado de um "Testar" que media a configuracao contra ela
         propria.

         Com alteracoes por guardar oferece testa-las; sem elas, leva o jogador
         ao sitio onde as pode fazer. */
      if (count > 0) {
        actions.append(el('button', {
          class: 'btn btn--primary',
          text: I18N.t('pf_preview'),
          onclick: () => post('previewPreset', { id: p.id }),
        }));
        if (!p.full) {
          actions.append(el('button', {
            class: 'btn btn--ghost',
            text: I18N.t('pf_save_profile'),
            onclick: () => saveProfileFlow(),
          }));
        }
      } else {
        actions.append(el('button', {
          class: 'btn btn--primary',
          text: I18N.t('pf_customise'),
          // Nas definicoes de DESEMPENHO, nao onde o jogador ficou da ultima
          // vez — que podia ser no tema e nas cores, que nada tem a ver com o
          // perfil que ele veio criar.
          onclick: () => { goto('settings'); settingsView.focusSection('performance'); },
        }));
      }

    } else if (p.kind === 'saved') {
      actions.append(el('button', {
        class: 'btn btn--primary',
        text: I18N.t('pf_apply'),
        onclick: () => applyPreset(p),
      }));
      actions.append(el('button', {
        class: 'btn btn--ghost',
        text: I18N.t('pf_preview'),
        onclick: () => post('previewPreset', { id: p.id }),
      }));
      const del = el('button', {
        class: 'iconbtn iconbtn--danger',
        title: I18N.t('pf_delete'),
        onclick: () => deleteProfile(p),
      });
      del.innerHTML = svgIcon('trash');
      actions.append(del);

    } else {
      actions.append(el('button', {
        class: 'btn btn--primary',
        text: I18N.t('pf_apply'),
        onclick: () => applyPreset(p),
      }));
      actions.append(el('button', {
        class: 'btn btn--ghost',
        text: I18N.t('pf_preview'),
        onclick: () => post('previewPreset', { id: p.id }),
      }));
    }

    card.append(actions);

    grid.append(card);
  }

  // So ao entrar no separador. Sem esta condicao, aplicar um preset
  // reanimava a grelha inteira no instante em que se clicava nela.
  if (animate) stagger(grid.children, 40, 240);
}

const BAR_SEGMENTS = 5;

function barline(label, level, kind) {
  const track = el('div', { class: 'track' });
  for (let i = 0; i < BAR_SEGMENTS; i++) track.append(el('i', { class: i < level ? 'on' : '' }));
  return el('div', { class: `barline barline--${kind}` }, el('span', { text: label }), track);
}

/* Pede o nome e guarda. Usado nos dois sitios onde se pode guardar um perfil:
   o botao do cartao do rascunho e o botao do resultado de um teste. */
async function saveProfileFlow() {
  const name = await promptModal(
    I18N.t('pf_name_t'), I18N.t('pf_name_d'),
    { placeholder: I18N.t('pf_name_ph'), yesLabel: I18N.t('pf_save') });
  if (name === null) return false;      // desistiu

  const res = await post('saveCustom', { name });
  if (res.schema) { App.schema = res.schema; settingsView.setSchema(res.schema); }
  if (res.values) applyValues(res.values);
  renderPresets();
  return !!res.ok;
}

async function deleteProfile(p) {
  const okToGo = await confirmModal(
    I18N.t('pf_delete_t'), I18N.t('pf_delete_d').replace('%s', p.label),
    I18N.t('pf_delete'));
  if (!okToGo) return;

  const res = await post('deleteCustom', { id: p.id });
  if (res.schema) { App.schema = res.schema; settingsView.setSchema(res.schema); }
  if (res.values) applyValues(res.values);
  renderPresets();
}

async function applyPreset(p) {
  if (p.confirm) {
    const okToGo = await confirmModal(I18N.t('pf_confirm_t'), I18N.t('pf_confirm_d'));
    if (!okToGo) return;
  }
  const res = await post('applyPreset', { id: p.id });
  if (res.values) applyValues(res.values);
}

/* ==========================================================================
   PREVIEW
   ========================================================================== */
function showPreviewOverlay(show) {
  $('#previewOverlay').classList.toggle('preview-overlay--hidden', !show);
}

/* Sem botao de cancelar: a medicao tem duracao fixa e curta, e o contador do
   cartao ja diz quanto falta.

   Nao foi substituido por uma tecla. Durante a medicao o painel esta fechado e
   sem foco de NUI — de outro modo o rato ficaria preso ao browser e o jogador
   nao poderia jogar aquilo que esta a ser medido — por isso o teclado pertence
   ao jogo e um keydown daqui nunca chegaria.

   `Oxlyn.CancelPreview()` e o callback `cancelPreview` continuam a existir do
   lado do Lua, mas deixaram de ter quem os chame a partir da interface. */

function renderPreviewResult(r) {
  App.previewResult = r;
  const card = $('#previewResult');
  card.hidden = false;

  $('#resultPreset').textContent = r.presetLabel;
  $('#resBefore').textContent = r.before.fps;
  $('#resAfter').textContent  = r.after.fps;
  $('#resBeforeLow').textContent = r.before.low1;
  $('#resAfterLow').textContent  = r.after.low1;

  const d = $('#resDelta');
  d.classList.toggle('is-negative', r.deltaFps < 0);
  d.querySelector('b').textContent  = `${r.deltaFps >= 0 ? '+' : ''}${r.deltaFps}`;
  d.querySelector('em').textContent = `${r.deltaPct >= 0 ? '+' : ''}${r.deltaPct}%`;

  /* Que par de botoes mostrar.

     Testou-se um RASCUNHO: nao ha nada para manter nem reverter — o que se
     mediu ja era o estado do jogador e continua aplicado. O que falta e a
     decisao que ele ainda nao tomou: dar-lhe um nome e guardar, ou nao.

     Testou-se um preset ou um perfil ja guardado: o par de sempre. */
  const draft = !!r.canSave;
  $('#resSave').hidden   = !draft;
  $('#resLater').hidden  = !draft;
  $('#resKeep').hidden   = draft || !r.reverted;
  $('#resRevert').hidden = draft ||  r.reverted;
}

$('#resultClose').addEventListener('click', () => { $('#previewResult').hidden = true; });

$('#resSave').addEventListener('click', async () => {
  // Fecha so se guardou mesmo. Desistir do nome deixa o resultado no ecra —
  // caso contrario o cartao desaparecia e o numero que ele acabou de medir
  // ia com ele.
  if (await saveProfileFlow()) $('#previewResult').hidden = true;
});
$('#resLater').addEventListener('click', () => {
  // "Agora nao" nao desfaz nada: as definicoes ficam como estao, apenas nao
  // ganham nome. Descarta-las aqui seria deitar fora o trabalho do jogador
  // por ele ter escolhido nao lhes dar um nome.
  $('#previewResult').hidden = true;
});
$('#resKeep').addEventListener('click', async () => {
  const res = await post('keepPreview');
  if (res.values) applyValues(res.values);
  $('#previewResult').hidden = true;
});
$('#resRevert').addEventListener('click', async () => {
  const res = await post('applyPreset', { id: App.values.preset });
  if (res.values) applyValues(res.values);
  $('#previewResult').hidden = true;
});

/* ==========================================================================
   GRAPH
   ========================================================================== */
const SERIES_UNITS = { fps: '', frametime: ' ms', ping: ' ms', entities: '' };

let graphRequest = 0;
async function refreshGraph() {
  if (!App.open || App.view !== 'graph') return;
  const series = App.graphSeries, range = App.graphRange;
  const request = ++graphRequest;
  const res = await post('requestChart', { series, range });
  if (!res.ok || !App.open || App.view !== 'graph'
      || request !== graphRequest || range !== App.graphRange
      || series !== App.graphSeries) return;

  bigChart.opts.xLabels = buildTimeLabels(App.graphRange, res.chart.filled);
  bigChart.opts.smooth = $('#chkSmooth').checked;
  bigChart.setData(res.chart);
  $('#bigChartEmpty').hidden = (res.chart.avg || []).length > 2;

  renderMiniStats(res.chart);
}

function renderMiniStats(chart) {
  const data = chart.avg || [];
  const row = $('#miniStats');
  row.replaceChildren();
  if (!data.length) return;

  let sum = 0, lo = Infinity, hi = -Infinity;
  for (const v of data) { sum += v; if (v < lo) lo = v; if (v > hi) hi = v; }
  const avg = sum / data.length;
  const variance = data.reduce((a, v) => a + (v - avg) ** 2, 0) / data.length;

  const unit = SERIES_UNITS[App.graphSeries] || '';
  const stats = [
    [I18N.t('ov_average'), round(avg, 1) + unit],
    [I18N.t('ov_min'),     round(lo, 1) + unit],
    [I18N.t('ov_max'),     round(hi, 1) + unit],
    ['σ',                  round(Math.sqrt(variance), 2)],
    [I18N.t('b_session'),  `${Math.round((chart.filled || 0) * 100)}%`],
  ];

  for (const [label, value] of stats) {
    row.append(el('div', { class: 'ministat' },
      el('span', { text: label }), el('b', { text: value })));
  }

  // O grafico recarrega de 2 em 2 segundos. So animamos quando a serie ou o
  // intervalo mudam — que e quando os numeros passam a significar outra coisa.
  const sig = `${App.graphSeries}|${App.graphRange}`;
  if (sig !== App._miniSig) { stagger(row.children, 34, 160); App._miniSig = sig; }
}

$('#seriesBar').addEventListener('click', e => {
  const btn = e.target.closest('button');
  if (!btn) return;
  App.graphSeries = btn.dataset.series;
  $$('#seriesBar button').forEach(b => b.classList.toggle('is-active', b === btn));
  refreshGraph();
});

$('#graphRangeBar').addEventListener('click', e => {
  const btn = e.target.closest('button');
  if (!btn) return;
  App.graphRange = btn.dataset.range;
  $$('#graphRangeBar button').forEach(b => b.classList.toggle('is-active', b === btn));
  refreshGraph();
});

$('#chkSmooth').addEventListener('change', () => {
  bigChart.opts.smooth = $('#chkSmooth').checked;
  bigChart.draw();
});

$('#btnExport').addEventListener('click', async () => {
  const res = await post('exportCsv', { range: App.graphRange });
  if (res.ok && res.csv) {
    toast(copyText(res.csv) ? I18N.t('gr_exported') : 'CSV: ' + res.csv.length + ' bytes',
          'success');
  }
});

/* ==========================================================================
   SISTEMA
   ========================================================================== */
function kv(label, value, isCode) {
  return el('div', { class: 'kv' },
    el('span', { text: label }),
    isCode ? el('code', { text: String(value) }) : el('b', { text: String(value) }));
}

/* As linhas do separador Sistema, declaradas como dados.
   `code: true` mostra o valor com tipo monoespacado. */
const SYS_REAL_ROWS = [
  { label: 'sy_screen',    get: (m) => m.screenW ? `${m.screenW} × ${m.screenH}` : '—' },
  { label: 'm_ping',       get: (m) => `${m.ping} ms` },
  { label: 'sy_peds',      get: (m) => fmtNum(m.peds) },
  { label: 'sy_vehicles',  get: (m) => fmtNum(m.vehicles) },
  { label: 'sy_objects',   get: (m) => fmtNum(m.objects) },
  { label: 'sy_pickups',   get: (m) => fmtNum(m.pickups) },
  { label: 'sy_players',   get: (m) => fmtNum(m.nearPlayers) },
  { label: 'sy_luamem',    get: (m) => fmtBytesKb(m.luaMemKb) },
  { label: 'sy_resources', get: (m) => fmtNum(m.resources) },
  { label: 'sy_uptime',    get: (m, d) => fmtDuration(d.uptime) },
  { label: 'sy_gamebuild', get: () => App.static.gameBuild || '—', code: true },
  { label: 'sy_onesync',   get: () => App.static.onesync || '—', code: true },
  { label: 'sy_framework', get: () => (App.static.framework || '—').toUpperCase(), code: true },
];
const SYS_EST_ROWS = [
  { label: 'm_cpu',  get: (m, d, e) => `${e.cpu}%` },
  { label: 'm_gpu',  get: (m, d, e) => `${e.gpu}%` },
  { label: 'm_ram',  get: (m, d, e) => `${e.ram}%` },
  { label: 'm_vram', get: (m, d, e) => `${e.vram}%` },
];

let sysRefs = null;

/* Construir uma vez, actualizar sempre.
   Antes esta vista reconstruia as 17 linhas em CADA tick — 20 vezes por
   segundo — para mudar meia duzia de numeros. Alem do desperdicio, tornava
   impossivel animar a entrada: a animacao reiniciava a cada 50ms e a lista
   ficava permanentemente a tremer. */
function buildSystem() {
  const build = (rows, host) => {
    host.replaceChildren();
    return rows.map(r => {
      const val = r.code ? el('code', { text: '—' }) : el('b', { text: '—' });
      host.append(el('div', { class: 'kv' }, el('span', { text: I18N.t(r.label) }), val));
      return { r, val };
    });
  };
  sysRefs = {
    real: build(SYS_REAL_ROWS, $('#sysReal')),
    est:  build(SYS_EST_ROWS,  $('#sysEst')),
  };
  $('#estNote').textContent = I18N.t('m_est_tip');
  renderSessions();
}

function renderSessions() {
  const list = $('#sessionList');
  const sessions = App.static.sessions || [];
  if (!sessions.length) {
    list.replaceChildren(el('div', { class: 'empty', text: I18N.t('sy_no_sessions') }));
    return;
  }
  list.replaceChildren(...sessions.map(s => el('div', { class: 'session' },
    el('div', { class: 't', text: s.date }),
    metric(I18N.t('ov_average'), s.avg),
    metric(I18N.t('ov_min'), s.min),
    metric(I18N.t('ov_max'), s.max),
    metric(I18N.t('ov_low1'), s.low1),
    el('div', { class: 't', text: `${s.minutes}m · ${s.preset}` })
  )));
}

function renderSystem(rebuild = false) {
  const d = App.lastTick;
  if (!d) return;

  if (rebuild || !sysRefs) {
    buildSystem();
    stagger($('#sysReal').children, 16, 200);
    stagger($('#sysEst').children,  16, 100);
    stagger($('#sessionList').children, 22, 200);
  }

  const m = d.metrics.real, e = d.metrics.estimated;
  for (const { r, val } of sysRefs.real) val.textContent = r.get(m, d, e);
  for (const { r, val } of sysRefs.est)  val.textContent = r.get(m, d, e);
}

function metric(label, value) {
  return el('div', { class: 'm' }, el('span', { text: label }), el('b', { text: fmtNum(value) }));
}

/* ==========================================================================
   SOBRE
   ========================================================================== */
function renderAbout(animate = false) {
  $('#aboutMeta').textContent =
    `v${App.static.version || '1.0.0'} · ${App.static.author || 'Oxlyn Software'} · ` +
    `${(App.static.framework || 'standalone').toUpperCase()}`;
  $('#buildVersion').textContent = App.static.version || '1.0.0';

  // As descricoes vem do dicionario de traducoes (chaves cmd_* e key_*), nao
  // de um objecto escrito aqui em portugues — que era o que fazia esta lista
  // continuar em portugues com o painel em ingles.
  $('#aboutCommands').replaceChildren(
    ...(App.static.commands || []).map(c =>
      kv(I18N.t(`cmd_${c.key}`, c.key), c.command, true)));

  const keys = App.static.keys || {};
  const rows = Object.entries(keys)
    .filter(([, v]) => v && v !== '')
    .map(([k, v]) => kv(I18N.t(`key_${k}`, k), v, true));
  $('#aboutKeys').replaceChildren(...(rows.length ? rows : [
    el('div', { class: 'empty', text: '—' })]));

  $('#honestyNote').textContent = I18N.t('ab_honesty_d');

  if (animate) {
    stagger($('#aboutCommands').children, 20, 180);
    stagger($('#aboutKeys').children, 20, 120);
  }
}

/* ==========================================================================
   DEFINICOES
   ========================================================================== */
async function onSettingChange(id, value) {
  const res = await post('setSetting', { id, value });
  if (res.values) applyValues(res.values);
}

/* Pre-visualizacao: aplica o valor SO na pagina, sem ir ao Lua e sem
   reconstruir a lista de definicoes.

   Existe para os controlos que se arrastam. Ver a nota em _color(), em
   settings.js: gravar a cada movimento reconstroi a lista e arranca o proprio
   controlo de debaixo do rato.

   So a cor de destaque entra aqui, e por uma razao concreta: e a unica
   definicao cujo efeito vive inteiramente no CSS desta pagina. Tudo o resto —
   sombras, densidade de transito, o HUD — e aplicado por natives do lado do
   Lua, e nao ha maneira de o previsualizar sem lho pedir. */
/* Pre-visualizacao enquanto se arrasta, antes de o valor ser gravado.
   So faz sentido para o que se ve mudar: a cor e o tamanho. Um slider de
   tamanho que so mostra o resultado quando se larga o rato obriga a tentar
   as vezes todas as vezes. */
function onSettingPreview(id, value) {
  if (id === 'uiAccent' && isHex(value)) applyUiConfig({ accent: value });
  /* Caminho curto de proposito: nao passa por applyUiConfig, que reescreve
     duas dezenas de variaveis de cor a cada passo do slider para nada. Aqui
     so o que a escala mesmo afecta — e apply() ja devolve false quando o
     valor arredondado nao mudou, por isso arrastar devagar nao redesenha
     nada de novo. */
  if (id === 'uiScale' || id === 'uiAutoScale') {
    if (id === 'uiScale' && typeof value === 'number') App.ui.scale = value;
    if (id === 'uiAutoScale') App.ui.autoScale = value !== false;

    if (UiScale.apply({ autoScale: App.ui.autoScale, scale: App.ui.scale })) {
      moveNavMarker();
      if (App.open) redrawAllCanvases();
    }
  }
}

$('#settingSearch').addEventListener('input', debounce(e => {
  settingsView.setQuery(e.target.value);
}, 140));

$('#btnResetAll').addEventListener('click', async () => {
  const okToGo = await confirmModal(I18N.t('se_reset'), I18N.t('se_reset_c'));
  if (!okToGo) return;
  const res = await post('resetAll');
  if (res.schema) { App.schema = res.schema; settingsView.setSchema(res.schema); renderPresets(); }
  if (res.values) applyValues(res.values);
});

$('#btnRunCleanup').addEventListener('click', async (e) => {
  const btn = e.currentTarget;
  btn.disabled = true;
  const res = await post('runCleanup');
  btn.disabled = false;
  const r = res.result;
  if (!r) { toast(I18N.t('se_cleanup_none'), 'warn'); return; }
  toast(I18N.t('se_cleanup_done')
          .replace('%1', r.peds)
          .replace('%2', r.vehicles)
          .replace('%3', r.objects), 'success');
});

// O mesmo fluxo do cartao do rascunho: guardar um perfil pede sempre um nome,
// venha o clique de onde vier.
$('#btnSaveCustom').addEventListener('click', () => saveProfileFlow());

function applyValues(payload) {
  App.values = payload;
  settingsView.setValues(payload);
  renderPresets();

  const preset = App.schema.presets?.find(p => p.id === payload.preset);
  $('#bbPreset').textContent = preset ? preset.label : payload.preset;
}

/* ==========================================================================
   HUD
   ========================================================================== */
const Hud = {

  node: $('#hud'),
  suppressed: false,
  visible: false,
  cfg: {},

  configure(visible, cfg, thresholds) {
    this.visible = visible;
    this.cfg = cfg || {};
    if (thresholds) App.thresholds = thresholds;

    this.node.dataset.pos = this.cfg.position || 'topright';
    this.node.style.setProperty('--hud-scale', this.cfg.scale || 1);

    const glass = $('.hud__glass', this.node);
    glass.style.opacity = this.cfg.opacity ?? 0.85;
    glass.style.transform = `scale(${this.cfg.scale || 1})`;

    $('#hudSpark').hidden = !this.cfg.showGraph;
    $('.hud__row[data-k="frametime"]', this.node).hidden = !this.cfg.showFrametime;
    $('.hud__row[data-k="lows"]',      this.node).hidden = !this.cfg.showLows;
    $('.hud__row[data-k="ping"]',      this.node).hidden = !this.cfg.showPing;
    $('.hud__row[data-k="entities"]',  this.node).hidden = !this.cfg.showEntities;

    if (cfg?.accent) hudSpark.setAccent(cfg.accent);
    this.sync();
  },

  sync() {
    this.node.classList.toggle('hud--hidden', !this.visible || this.suppressed);
  },

  tick(d) {
    if (!this.visible || this.suppressed) return;
    const color = fpsColor(d.fps);
    const fpsEl = $('#hudFps');
    fpsEl.textContent = d.fps;
    fpsEl.style.setProperty('--hud-color', color);
    fpsEl.style.setProperty('--hud-glow', rgba(color, 0.45));

    $('#hudFt').textContent   = d.frametime.toFixed(1);
    $('#hudLow').textContent  = d.low1;
    $('#hudPing').textContent = d.ping;
    $('#hudEnt').textContent  = fmtNum(d.entities);

    if (this.cfg.showGraph) hudSpark.push(d.fps);
  },
};

/* ==========================================================================
   ABERTURA E FECHO
   --------------------------------------------------------------------------
   A abertura e toda em CSS (ver "SEQUENCIA DE ABERTURA" em style.css). O
   fecho precisa de JS por uma razao simples: `display: none` corta qualquer
   animacao a meio. O elemento tem de continuar visivel enquanto a animacao de
   saida corre e so depois ser escondido.

   O temporizador tem de ser cancelavel. Sem isso, abrir o painel logo a
   seguir a fecha-lo deixava um temporizador antigo pendente que o escondia
   outra vez a meio da animacao de entrada.
   ========================================================================== */
const CLOSE_MS = 180;   // tem de acompanhar a duracao de panelOut no CSS
let closeTimer = null;

function cancelClose() {
  if (closeTimer) { clearTimeout(closeTimer); closeTimer = null; }
  $('#app').classList.remove('is-closing');
}

function beginClose() {
  const app = $('#app');
  cancelClose();

  // Com animacoes desligadas nao ha nada para esperar.
  if (document.body.classList.contains('no-anim')) {
    app.classList.add('app--hidden');
    return;
  }

  app.classList.add('is-closing');
  closeTimer = setTimeout(() => {
    closeTimer = null;
    app.classList.remove('is-closing');
    app.classList.add('app--hidden');
  }, CLOSE_MS);
}

/* ==========================================================================
   MENSAGENS DO LUA
   ========================================================================== */
window.addEventListener('message', ({ data }) => {
  switch (data.action) {

    case 'open': {
      // Se ainda estava a correr a animacao de fecho, cancela-a — senao o
      // painel reabria e desaparecia logo a seguir, quando o temporizador
      // antigo disparasse.
      cancelClose();

      App.schema = data.schema;
      App.static = data.static;
      I18N.set(data.schema.locale);

      settingsView.setSchema(data.schema);
      applyValues(data.values);

      $('#buildVersion').textContent = data.static.version || '1.0.0';

      App.open = true;
      $('#app').classList.remove('app--hidden');
      goto(App.view);
      refreshMainChart();
      // Redesenho depois de as pecas assentarem. As medidas ja sao de layout
      // e nao dependem da animacao, mas a grelha so tem larguras definitivas
      // depois do primeiro layout — este segundo desenho garante que nenhum
      // canvas fica com o tamanho do frame inicial.
      setTimeout(redrawAllCanvases, 850);
      break;
    }

    case 'close':
      App.open = false;
      // O menu vive em <body>, fora de #app — esconder o painel nao o esconde.
      Dropdown.close();
      beginClose();
      break;

    case 'schema':
      App.schema = data.schema;
      I18N.set(data.schema.locale);
      // Os rotulos destes blocos sao escritos uma unica vez na construcao,
      // por isso uma troca de idioma obriga a reconstrui-los.
      worldTiles = null;
      sysRefs = null;
      App._dateStr = null;   // o formato da data depende do idioma
      settingsView.setSchema(data.schema);
      applyValues(data.values);
      renderPresets();
      // Retraduz o cabecalho e re-renderiza a vista activa, para uma troca de
      // idioma nao deixar meia interface na lingua antiga.
      goto(App.view);
      break;

    case 'values':
      applyValues(data.payload);
      break;

    case 'static':
      App.static = data.static;
      moveNavMarker();
      if (App.view === 'about')  renderAbout();
      if (App.view === 'system') renderSystem();
      break;

    case 'uiConfig':
      applyUiConfig(data.config);
      break;

    /* Canal rapido (20Hz). So o que se ve mudar frame a frame: o numero
       grande, o frametime e o mostrador de estado. Payload de tres campos —
       ver o comentario "DOIS CANAIS EM VEZ DE UM" em client/main.lua. */
    case 'live': {
      if (!App.open) break;
      const big = $('#fpsBig');
      if (big) setText(big, data.fps);
      const ft = $('#stFt');
      if (ft && App.view === 'overview') setText(ft, data.ft.toFixed(1));

      const sf = $('#statusFps');
      if (sf) setText(sf, data.fps);
      statusGauge.set(data.fps, App._statusColor || App.ui.accent);
      break;
    }

    /* Canal lento (4Hz). Agregados, aneis, dicas, barra inferior. */
    case 'tick':
      App.lastTick = data;
      if (App.open) {
        // Sempre: coluna direita, barra inferior, cabecalho.
        updateChrome(data);
        // Só na vista respectiva.
        if (App.view === 'overview') updateOverview(data);
        if (App.view === 'system')   renderSystem();
      }
      break;

    case 'goto':
      goto(data.view);
      break;

    case 'toast':
      toast(data.message, data.kind, data.title, data.duration);
      break;

    /* ---- HUD ---- */
    case 'hudConfig':
      Hud.configure(data.visible, data.config, data.thresholds);
      break;
    case 'hudTick':
      Hud.tick(data);
      break;
    case 'hudSuppress':
      Hud.suppressed = data.suppressed;
      Hud.sync();
      break;

    /* ---- preview ---- */
    case 'previewStart':
      showPreviewOverlay(true);
      $('#pvPreset').textContent = data.preset;
      break;
    case 'previewProgress': {
      $('#pvPhase').textContent = data.phase === 'baseline'
        ? I18N.t('pf_baseline').toUpperCase() : I18N.t('pf_result').toUpperCase();
      $('#pvFps').textContent = data.fps;
      $('#pvBar').style.width = `${Math.round(data.progress * 100)}%`;
      $('#pvSeconds').textContent = data.seconds;
      break;
    }
    case 'previewResult':
      showPreviewOverlay(false);
      renderPreviewResult(data.result);
      break;
    case 'previewCancelled':
      showPreviewOverlay(false);
      break;
  }
});

/* ==========================================================================
   TECLADO
   ========================================================================== */
document.addEventListener('keydown', e => {
  if (!App.open) return;
  if (e.key === 'Escape') {
    // Escape fecha primeiro o dropdown aberto; so fecha o painel se nao houver
    // nenhum. Fechar as duas coisas de uma vez apanha sempre o utilizador de
    // surpresa.
    if (Dropdown.isOpen()) { Dropdown.close(); return; }
    post('close');
    return;
  }

  // Atalhos numericos para as vistas — mais rapido que ir ao rato.
  const order = ['overview', 'performance', 'graph', 'system', 'settings', 'about'];
  const n = parseInt(e.key, 10);
  if (n >= 1 && n <= order.length && document.activeElement?.tagName !== 'INPUT') {
    goto(order[n - 1]);
  }
});

/* ==========================================================================
   LOOPS
   ========================================================================== */
// O grafico nao precisa de 10Hz: os dados sao agregados e 2s e mais que
// suficiente para parecer vivo sem gastar CPU a redesenhar.
setInterval(() => {
  if (!App.open) return;
  if (App.view === 'overview') refreshMainChart();
  if (App.view === 'graph')    refreshGraph();
}, 2000);

/* A NUI e redimensionada quando o jogador muda a resolucao do jogo ou passa
   de janela para ecra inteiro. A escala tem de ser recalculada AQUI: e o unico
   sitio onde damos por isso sem depender de o Lua nos avisar. */
window.addEventListener('resize', debounce(() => {
  UiScale.apply();
  redrawAllCanvases();
  moveNavMarker();   // a altura dos items muda com os breakpoints e com a escala
}, 120));

// Primeira aplicacao, antes de o Lua enviar as preferencias: um painel aberto
// por um comando no primeiro segundo ja aparece na escala certa.
UiScale.apply();

/* Fora do jogo (abrir index.html no browser) o painel fica visivel para se
   poder trabalhar no CSS sem estar dentro do FiveM. */
if (typeof GetParentResourceName !== 'function') {
  document.body.style.background = '#0b1018';
  $('#app').classList.remove('app--hidden');
}
