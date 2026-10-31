/* ==========================================================================
   oxlyn-fpsboost · charts.js
   --------------------------------------------------------------------------
   Tudo desenhado em canvas puro, sem bibliotecas.

   Porque nao Chart.js ou similar?
     A NUI do FiveM nao tem garantia de internet, e um CDN falhado deixaria o
     painel sem graficos. Uma dependencia local seria +200KB para desenhar
     linhas e arcos. Estas ~350 linhas fazem exactamente o que este painel
     precisa e nada mais.

   Todos os componentes:
     · respeitam o devicePixelRatio (sem isto fica tudo desfocado em 1440p+)
     · animam entre valores em vez de saltar
     · leem a cor de destaque actual, para mudarem de cor com o resto da UI
   ========================================================================== */

/* --------------------------------------------------------------- canvas -- */
/* NAO usar getBoundingClientRect aqui.
   Esse metodo devolve o rectangulo JA PROJECTADO no ecra, ou seja, depois de
   todas as transformacoes CSS dos ancestrais. Com os paineis laterais
   inclinados em 3D e com a animacao de abertura a mexer nos elementos, a
   medida vinha distorcida: o canvas era criado com a resolucao errada e
   depois esticado pelo CSS por cima do resto do painel.

   clientWidth/clientHeight sao medidas de LAYOUT — nao sao afectadas por
   transformacoes. Sao sempre o tamanho real da caixa, esteja ela rodada,
   afastada ou a meio de uma animacao. */
function fitCanvas(canvas) {
  const dpr = window.devicePixelRatio || 1;

  /* Escala da interface (ver UiScale em util.js). Entra aqui duas vezes, e
     por razoes diferentes:

       · como DIVISOR das medidas de layout, para o codigo de desenho
         continuar a trabalhar sempre no mesmo espaco logico — 700 pontos de
         largura sao 700 em 1080p e 700 em 4K, e por isso os tipos e as
         margens dos graficos crescem com o resto do painel em vez de ficarem
         miniaturas dentro de uma caixa maior;

       · como MULTIPLICADOR do backing store, que e o que impede o canvas de
         ser desenhado pequeno e depois ampliado pelo compositor. Sem isto o
         grafico e a unica parte do painel que fica esborratada em 4K.        */
  const us  = (typeof UiScale !== 'undefined') ? UiScale : null;
  const div = us ? us.layoutDivisor() : 1;
  const px  = dpr * (us ? us.pixelScale() : 1);

  let w = canvas.clientWidth  / div;
  let h = canvas.clientHeight / div;
  // Um canvas ainda nao apresentado nao tem caixa: cai para os atributos.
  if (!w || !h) { w = canvas.width / px; h = canvas.height / px; }
  w = Math.max(1, Math.floor(w));
  h = Math.max(1, Math.floor(h));
  const bw = Math.round(w * px);
  const bh = Math.round(h * px);
  if (canvas.width !== bw || canvas.height !== bh) {
    canvas.width = bw;
    canvas.height = bh;
  }
  const ctx = canvas.getContext('2d');
  ctx.setTransform(px, 0, 0, px, 0, 0);
  return { ctx, w, h };
}

/** Escala "bonita": devolve um passo legivel (1,2,5,10,20,50...) */
function niceStep(range, targetTicks = 4) {
  if (range <= 0) return 1;
  const raw = range / targetTicks;
  const mag = Math.pow(10, Math.floor(Math.log10(raw)));
  const norm = raw / mag;
  const step = norm <= 1 ? 1 : norm <= 2 ? 2 : norm <= 5 ? 5 : 10;
  return step * mag;
}

/* ==========================================================================
   LINE CHART
   ========================================================================== */
class LineChart {
  constructor(canvas, opts = {}) {
    this.canvas = canvas;
    this.opts = Object.assign({
      accent: '#FF2E43',
      /* Filtra o RUIDO da serie, nao apenas a forma do traco.
         Ver _lowpass() e a nota em draw(). */
      smooth: true,
      // Intensidade do halo, 0..1. Controlada em Definicoes > Interface.
      // NAO tem relacao com `smooth`: esse mexe nos VALORES, este so em quanta
      // luz a linha emite.
      glow: 0.55,
      showBand: true,      // banda min/max por tras da linha
      showDot: true,       // ponto no valor actual
      // padRight/padTop deixam espaco para o glow da linha e para o halo do
      // ponto actual; sem isso o canvas corta-os numa aresta recta.
      padLeft: 40,
      padRight: 20,
      padTop: 16,
      padBottom: 24,
      unit: '',
      xLabels: [],
      minY: null,
      maxY: null,
    }, opts);

    this.data = { avg: [], min: [], max: [] };
    this.animated = [];   // copia interpolada, para a linha deslizar em vez de saltar
    this.raf = null;

    /* Buffers do filtro, reutilizados. O smoothing corre a cada frame da
       animacao — alocar tres arrays por frame daria ao GC trabalho constante
       para nada, e um pico de GC no meio de um grafico de performance seria
       ironico. */
    this._sAvg = [];
    this._sMin = [];
    this._sMax = [];
    this._bandRadius = -1;
  }

  setAccent(hex) { this.opts.accent = hex; }

  setData(payload) {
    // O json.encode do Lua serializa uma tabela vazia como {} e nao como [].
    // Sem esta normalizacao, um historico ainda vazio rebentaria em .slice().
    const arr = v => Array.isArray(v) ? v : [];
    const avg = arr(payload.avg);
    this._bandRadius = -1;
    this.data = {
      avg,
      min: arr(payload.min).length === avg.length ? arr(payload.min) : avg,
      max: arr(payload.max).length === avg.length ? arr(payload.max) : avg,
    };
    /* `payload.filled` ja nao e guardado aqui.
       Servia para encolher a serie contra a margem direita; agora quem o usa e
       o app.js, para gerar os rotulos do eixo. Manter uma copia por ler nesta
       classe so daria a entender que o desenho ainda depende dela. */

    // Se o numero de pontos mudou, nao ha animacao possivel: salta.
    if (this.animated.length !== this.data.avg.length) {
      this.animated = this.data.avg.slice();
    }
    this.start();
  }

  start() {
    if (this.raf) return;
    const loop = () => {
      const done = this.step();
      this.draw();
      this.raf = done ? null : requestAnimationFrame(loop);
    };
    this.raf = requestAnimationFrame(loop);
  }

  step() {
    let settled = true;
    const target = this.data.avg;
    for (let i = 0; i < target.length; i++) {
      const cur = this.animated[i] ?? target[i];
      const d = target[i] - cur;
      if (Math.abs(d) > 0.15) { settled = false; this.animated[i] = cur + d * 0.3; }
      else this.animated[i] = target[i];
    }
    return settled;
  }

  /** Media movel ponderada triangular. Escreve em `out` e devolve-o.
   *
   *  Porque triangular e nao uma media simples: uma janela plana da o mesmo
   *  peso ao vizinho imediato e ao que esta na ponta da janela, e isso deixa
   *  degraus — a curva assenta num patamar e salta quando um valor extremo
   *  entra ou sai da janela. Com pesos a decair para os lados (1,2,3,4,3,2,1)
   *  a entrada e a saida de cada amostra e gradual e o resultado nao tem
   *  arestas.
   *
   *  Nas pontas a janela e cortada e os pesos renormalizados, por isso a curva
   *  chega mesmo ao inicio e ao fim da serie em vez de desaparecer nas margens.
   */
  _lowpass(src, out, radius) {
    const n = src.length;
    out.length = n;
    if (radius < 1 || n < 3) {
      for (let i = 0; i < n; i++) out[i] = src[i];
      return out;
    }
    for (let i = 0; i < n; i++) {
      const a = i - radius < 0 ? 0 : i - radius;
      const b = i + radius > n - 1 ? n - 1 : i + radius;
      let sum = 0, wsum = 0;
      for (let j = a; j <= b; j++) {
        const d = j > i ? j - i : i - j;
        const w = radius + 1 - d;
        sum  += src[j] * w;
        wsum += w;
      }
      out[i] = sum / wsum;
    }
    return out;
  }

  /** Catmull-Rom convertido em curvas de Bezier: suave sem overshoot feio. */
  _spline(ctx, pts) {
    if (pts.length < 2) return;
    ctx.moveTo(pts[0].x, pts[0].y);
    if (!this.opts.smooth || pts.length < 3) {
      for (let i = 1; i < pts.length; i++) ctx.lineTo(pts[i].x, pts[i].y);
      return;
    }
    for (let i = 0; i < pts.length - 1; i++) {
      const p0 = pts[i - 1] || pts[i];
      const p1 = pts[i];
      const p2 = pts[i + 1];
      const p3 = pts[i + 2] || p2;
      ctx.bezierCurveTo(
        p1.x + (p2.x - p0.x) / 6, p1.y + (p2.y - p0.y) / 6,
        p2.x - (p3.x - p1.x) / 6, p2.y - (p3.y - p1.y) / 6,
        p2.x, p2.y
      );
    }
  }

  draw() {
    const { ctx, w, h } = fitCanvas(this.canvas);
    const o = this.opts;
    ctx.clearRect(0, 0, w, h);

    const raw = this.animated;
    if (!raw.length) return;

    /* ---- "Suavizar" -------------------------------------------------------
       Isto filtrava so a FORMA do traco: com o interruptor ligado os pontos
       eram unidos por curvas de Bezier, desligado por segmentos rectos. Com
       180 pontos numa area de ~650px, cada segmento tem 3,6px — a curva e a
       recta entre dois pontos tao proximos sao indistinguiveis. O interruptor
       funcionava; e o efeito e que era invisivel.

       Agora filtra os VALORES. Uma media movel ponderada tira o ruido de
       amostragem e deixa a tendencia, que e a leitura que interessa quando se
       compara presets: as quedas reais mantem-se, o serrilhado desaparece.

       O raio acompanha o numero de pontos para o efeito ser o mesmo em todos
       os intervalos — 1M e 1H tem contagens diferentes, um raio fixo suavizaria
       de menos num e demais no outro.

       A banda leva metade do raio: e um envelope de minimos e maximos, e achata
       -la tanto como a media apagaria justamente a dispersao que ela existe
       para mostrar. */
    const sm     = o.smooth && raw.length >= 5;
    const radius = sm ? Math.max(3, Math.round(raw.length / 32)) : 0;
    const values = sm ? this._lowpass(raw, this._sAvg, radius) : raw;

    const bandR   = sm ? Math.max(1, radius >> 1) : 0;
    // A banda nao interpola: o filtro so muda com os dados ou com o raio.
    // A media continua a ser filtrada em TODOS os frames da animacao.
    if (sm && this._bandRadius !== bandR) {
      this._lowpass(this.data.max, this._sMax, bandR);
      this._lowpass(this.data.min, this._sMin, bandR);
      this._bandRadius = bandR;
    }
    const bandMax = sm ? this._sMax : this.data.max;
    const bandMin = sm ? this._sMin : this.data.min;

    /* A ponta da serie volta ao valor real, progressivamente.
       O ponto do fim da linha e o marcador do AGORA, e ao lado dele — no mesmo
       ecra — esta o numero grande de FPS ao vivo. Filtrado, esse ponto passava
       a ser a media dos ultimos segundos e podia afastar-se do numero uns bons
       quinze FPS: dois sitios a dizer "agora" com valores diferentes le-se como
       avaria, nao como suavizacao.

       O peso do filtro desce ate zero ao longo das ultimas amostras, por isso a
       transicao nao tem degrau e a ultima amostra e exactamente a medida. */
    if (sm) {
      const n = values.length;
      const k = Math.min(radius, n - 1);
      for (let i = n - k; i < n; i++) {
        const t = (i - (n - k - 1)) / k;
        values[i] = values[i] * (1 - t) + raw[i] * t;
      }
    }

    const x0 = o.padLeft, x1 = w - o.padRight;
    const y0 = o.padTop,  y1 = h - o.padBottom;
    const plotW = Math.max(1, x1 - x0);
    const plotH = Math.max(1, y1 - y0);

    /* ---- escala vertical ---------------------------------------------- */
    let lo = o.minY, hi = o.maxY;
    if (lo === null || hi === null) {
      let dataMin = Infinity, dataMax = -Infinity;

      /* A escala TEM de incluir os valores que estao mesmo a ser desenhados.
         Antes era calculada apenas a partir de this.data (o alvo) enquanto a
         linha vinha de this.animated (a interpolacao em curso). Nos frames em
         que um pico grande de frametime sai do historico, `animated` ainda
         segura o valor antigo — muito acima do novo maximo — e yOf() devolvia
         uma coordenada acima do topo do grafico. O resultado era o traco a
         disparar para fora da area, exactamente o risco vertical vermelho.

         Somar `values` ao calculo garante que o que se desenha cabe sempre
         dentro da escala. */
      for (let i = 0; i < values.length; i++) {
        const v = values[i];
        if (v > dataMax) dataMax = v;
        if (v < dataMin) dataMin = v;
        if (o.showBand) {
          const hiB = bandMax[i], loB = bandMin[i];
          if (hiB !== undefined && hiB > dataMax) dataMax = hiB;
          if (loB !== undefined && loB < dataMin) dataMin = loB;
        }
      }
      if (!isFinite(dataMin)) { dataMin = 0; dataMax = 1; }
      const pad = Math.max((dataMax - dataMin) * 0.18, dataMax * 0.06, 1);
      lo = Math.max(0, dataMin - pad);
      hi = dataMax + pad;
    }
    if (hi - lo < 1) hi = lo + 1;

    const step = niceStep(hi - lo, 4);
    lo = Math.floor(lo / step) * step;
    hi = Math.ceil(hi / step) * step;
    const yOf = v => y1 - ((v - lo) / (hi - lo)) * plotH;

    /* A serie ocupa a largura TODA e comeca na esquerda.
       Quem trata de nao mentir sobre o tempo sao os rotulos, que sao gerados a
       partir do historico que existe mesmo — ver buildTimeLabels() no app.js.

       Ja foi ao contrario: a serie ficava encostada a direita numa fatia
       proporcional ao historico. Resolvia a honestidade do eixo, mas ao custo
       de uma area morta a esquerda que ocupava metade do cartao enquanto o
       historico enchia. Corrigir os rotulos em vez de encolher os dados resolve
       as duas coisas: a linha usa o cartao todo e o eixo continua certo. */
    const xOf = i => x0 + (values.length === 1 ? plotW : (i / (values.length - 1)) * plotW);

    /* ---- grelha + eixo Y ------------------------------------------------ */
    ctx.font = '600 10px "Segoe UI", system-ui, sans-serif';
    ctx.textAlign = 'right';
    ctx.textBaseline = 'middle';
    for (let v = lo; v <= hi + 0.0001; v += step) {
      const y = yOf(v);
      ctx.strokeStyle = 'rgba(255,255,255,0.045)';
      ctx.lineWidth = 1;
      ctx.beginPath();
      ctx.moveTo(x0, Math.round(y) + .5);
      ctx.lineTo(x1, Math.round(y) + .5);
      ctx.stroke();

      ctx.fillStyle = 'rgba(147,160,180,0.7)';
      ctx.fillText(Math.round(v).toString(), x0 - 9, y);
    }

    /* ---- eixo X --------------------------------------------------------- */
    if (o.xLabels.length) {
      ctx.textBaseline = 'top';
      const n = o.xLabels.length;
      for (let i = 0; i < n; i++) {
        const x = x0 + (i / (n - 1)) * plotW;
        ctx.textAlign = i === 0 ? 'left' : i === n - 1 ? 'right' : 'center';
        ctx.fillStyle = 'rgba(107,119,137,0.85)';
        ctx.fillText(o.xLabels[i], x, y1 + 9);
      }
    }

    /* ---- recorte de seguranca ---------------------------------------------
       A escala acima ja garante que a linha cabe. Isto e a rede por baixo:
       qualquer valor extremo que escape num frame de transicao fica contido
       na area do grafico em vez de atravessar o cartao.

       A margem existe para o halo poder desvanecer-se: recortar rente ao eixo
       cortaria o brilho a direito e criaria a mesma aresta dura que se andou
       a eliminar nos aneis. */
    ctx.save();
    ctx.beginPath();
    ctx.rect(x0 - 2, y0 - 10, (x1 - x0) + o.padRight + 2, plotH + 14);
    ctx.clip();

    /* ---- banda min/max --------------------------------------------------- */
    const pts = values.map((v, i) => ({ x: xOf(i), y: yOf(v) }));

    if (o.showBand && bandMin.length === values.length) {
      const top = bandMax.map((v, i) => ({ x: xOf(i), y: yOf(v) }));
      const bot = bandMin.map((v, i) => ({ x: xOf(i), y: yOf(v) })).reverse();
      ctx.beginPath();
      this._spline(ctx, top);
      bot.forEach(p => ctx.lineTo(p.x, p.y));
      ctx.closePath();
      ctx.fillStyle = rgba(o.accent, 0.10);
      ctx.fill();
    }

    /* ---- area sob a linha -------------------------------------------------
       O degrade arranca no ponto MAIS ALTO da serie, nao no topo da caixa.
       Ancorado ao topo da caixa, uma linha baixa ficava com um enchimento
       apagado e uma linha alta com um enchimento saturado — a mesma cor
       significava coisas diferentes. Ancorado a linha, o brilho fica sempre
       colado a ela e apaga-se ate a base. */
    let topY = y1;
    for (const p of pts) if (p.y < topY) topY = p.y;
    if (y1 - topY < 1) topY = y1 - 1;

    const fill = ctx.createLinearGradient(0, topY, 0, y1);
    fill.addColorStop(0,    rgba(o.accent, 0.32));
    fill.addColorStop(0.20, rgba(o.accent, 0.17));
    fill.addColorStop(0.55, rgba(o.accent, 0.055));
    fill.addColorStop(1,    rgba(o.accent, 0.0));

    ctx.beginPath();
    this._spline(ctx, pts);
    ctx.lineTo(pts[pts.length - 1].x, y1);
    ctx.lineTo(pts[0].x, y1);
    ctx.closePath();
    ctx.fillStyle = fill;
    ctx.fill();

    /* ---- linha desenhada como um raio -------------------------------------
       Um relampago nao e uma linha colorida: e um nucleo quase BRANCO com toda
       a cor no halo a volta. E dai que vem a sensacao de energia — se se pinta
       a linha inteira de vermelho, por mais brilho que se ponha continua a ler
       -se como um tracado grosso, nunca como luz.

       DUAS passagens sobre o MESMO caminho:

         A) halo   : uma unica sombra, contida
         B) nucleo : fino e clareado, sem sombra — o filamento

       Havia aqui DUAS passagens de halo, e isso era um erro que so se via na
       serie de frametime. Em troços quase VERTICAIS — e um pico de stutter e
       exactamente isso — as sombras das duas passagens sobrepoem-se ao longo
       de toda a subida e somam-se, formando um feixe que sai do grafico. Numa
       linha inclinada o efeito diluia-se e nao se dava por ele; num pico
       tornava-se um risco de luz vertical.

       Uma so passagem, com menos raio e menos alfa, mantem o brilho sem
       acumular. O grafico tem de se poder LER — e para isso que existe.

       Nota importante: a forma NUNCA e alterada. Um raio a serio seria
       irregular, mas isto e um grafico — distorcer o tracado seria mentir
       sobre os dados. O efeito vem todo da forma como e iluminado. */
    const core = shade(o.accent, 0.45);   // clareado, nao branco
    const g = clamp(o.glow ?? 0.55, 0, 1);

    ctx.save();
    ctx.lineJoin = 'round';
    ctx.lineCap = 'round';

    // A) halo, passagem unica. A 0 nao ha sombra nenhuma — nao vale a pena
    // pedir a GPU um blur de raio zero.
    ctx.beginPath(); this._spline(ctx, pts);
    ctx.strokeStyle = o.accent;
    ctx.lineWidth = 1.9;
    if (g > 0) {
      ctx.shadowColor = rgba(o.accent, 0.68 * g);
      ctx.shadowBlur  = 14 * g;
    }
    ctx.stroke();

    // B) nucleo, sem sombra propria
    ctx.beginPath(); this._spline(ctx, pts);
    ctx.strokeStyle = core;
    ctx.lineWidth = 1;
    ctx.shadowBlur = 0;
    ctx.stroke();
    ctx.restore();

    /* ---- marcador do instante actual --------------------------------------
       Fio vertical a descer do ultimo ponto ate a base. Ancora o "agora" no
       eixo do tempo, que num grafico que desliza e a leitura que falta. */
    if (o.showDot && pts.length) {
      const last = pts[pts.length - 1];

      const stem = ctx.createLinearGradient(0, last.y, 0, y1);
      stem.addColorStop(0, rgba(o.accent, 0.5));
      stem.addColorStop(1, rgba(o.accent, 0.0));
      ctx.save();
      ctx.beginPath();
      ctx.moveTo(last.x, last.y);
      ctx.lineTo(last.x, y1);
      ctx.strokeStyle = stem;
      ctx.lineWidth = 1;
      ctx.stroke();
      ctx.restore();

      /* ponto actual: halo, anel a cor de destaque, nucleo quente */
      ctx.save();
      ctx.beginPath();
      ctx.arc(last.x, last.y, 8, 0, Math.PI * 2);
      ctx.fillStyle = rgba(o.accent, 0.14);
      ctx.fill();

      ctx.beginPath();
      ctx.arc(last.x, last.y, 4.2, 0, Math.PI * 2);
      ctx.fillStyle = o.accent;
      if (g > 0) {
        ctx.shadowColor = rgba(o.accent, 0.6);
        ctx.shadowBlur = 16 * g;
      }
      ctx.fill();

      // Nucleo do ponto na mesma cor clareada da linha: e onde o tracado toca
      // o instante actual, por isso e o sitio mais claro do grafico.
      ctx.beginPath();
      ctx.arc(last.x, last.y, 1.9, 0, Math.PI * 2);
      ctx.fillStyle = shade(o.accent, 0.6);
      ctx.shadowBlur = 0;
      ctx.fill();
      ctx.restore();
    }

    // Fecha o recorte de seguranca aberto antes da banda min/max.
    ctx.restore();
  }
}

/* --------------------------------------------------------------------------
   PINTURAS QUE NAO MOSTRAM NADA DE NOVO
   -------------------------------------
   Os dois mostradores animam com suavizacao exponencial: cada passo aproxima
   o valor do alvo por uma fraccao do que falta. Os primeiros passos movem-se
   muito, os ultimos movem-se micrometros — e sao a maior parte deles.

   Um arco de duzentos pixeis de perimetro precisa de mais de max/400 unidades
   para se mexer meio pixel. Abaixo disso, redesenhar produz exactamente a
   mesma imagem, e no CEF isso disputa a placa grafica com o jogo. A curva da
   animacao nao muda: continua a correr, so nao repinta o que nao mudou.

   O campo _painted guarda o valor efectivamente pintado (nao o valor corrente), para
   os erros nao se acumularem passo a passo.
   -------------------------------------------------------------------------- */
function needsRepaint(gauge, color) {
  const step = gauge.opts.max / 400;
  if (gauge._paintedColor !== color) return true;
  if (gauge._painted === undefined) return true;
  return Math.abs(gauge.value.v - gauge._painted) >= step;
}

function markPainted(gauge, color) {
  gauge._painted = gauge.value.v;
  gauge._paintedColor = color;
}

/* ==========================================================================
   RING GAUGE  ·  anel de 270 graus (CPU / GPU / RAM / VRAM / PING)
   ========================================================================== */
class RingGauge {
  constructor(canvas, opts = {}) {
    this.canvas = canvas;
    this.opts = Object.assign({
      accent: '#FF2E43',
      thickness: 6,
      glow: 10,                   // raio do shadowBlur do arco
      start: Math.PI * 0.75,      // canto inferior esquerdo
      sweep: Math.PI * 1.5,       // 270 graus
      max: 100,
    }, opts);
    this.value = new Smoothed(0, 0.14);
    this.color = this.opts.accent;
    this.raf = null;
  }

  set(value, color) {
    this.value.set(clamp(value, 0, this.opts.max));
    if (color) this.color = color;
    this.start();
  }
  setAccent(hex) { this.opts.accent = hex; if (!this._customColor) this.color = hex; }
  setColor(hex) { this._customColor = true; this.color = hex; }

  start() {
    if (this.raf) return;
    const loop = () => {
      const before = this.value.v;
      this.value.step();
      if (needsRepaint(this, this.color)) { this.draw(); markPainted(this, this.color); }
      if (Math.abs(this.value.target - this.value.v) < 0.05 && Math.abs(before - this.value.v) < 0.05) {
        this.value.v = this.value.target;
        // A ultima pintura e sempre feita, com o valor exacto do alvo: e ela
        // que deixa o mostrador no sitio certo em vez de meio pixel aquem.
        this.draw();
        markPainted(this, this.color);
        this.raf = null;
      } else {
        this.raf = requestAnimationFrame(loop);
      }
    };
    this.raf = requestAnimationFrame(loop);
  }

  draw() {
    const { ctx, w, h } = fitCanvas(this.canvas);
    const o = this.opts;
    ctx.clearRect(0, 0, w, h);

    const cx = w / 2, cy = h / 2;

    // O raio tem de deixar espaco para METADE da espessura MAIS o shadowBlur.
    // Sem esta margem o glow bate no limite do canvas e o corte le-se como um
    // quadrado a volta do circulo — o canvas nao esbate o que corta.
    const pad = o.thickness / 2 + o.glow + 2;
    const r = Math.max(4, Math.min(w, h) / 2 - pad);
    const pct = clamp(this.value.v / o.max, 0, 1);

    /* trilho */
    ctx.beginPath();
    ctx.arc(cx, cy, r, o.start, o.start + o.sweep);
    ctx.strokeStyle = 'rgba(255,255,255,0.075)';
    ctx.lineWidth = o.thickness;
    ctx.lineCap = 'round';
    ctx.stroke();

    if (pct <= 0.001) return;

    /* valor, com gradiente ao longo do arco */
    const grad = ctx.createLinearGradient(cx - r, cy - r, cx + r, cy + r);
    grad.addColorStop(0, shade(this.color, 0.25));
    grad.addColorStop(1, this.color);

    ctx.save();
    ctx.beginPath();
    ctx.arc(cx, cy, r, o.start, o.start + o.sweep * pct);
    ctx.strokeStyle = grad;
    ctx.lineWidth = o.thickness;
    ctx.lineCap = 'round';
    ctx.shadowColor = rgba(this.color, 0.7);
    ctx.shadowBlur = o.glow;
    ctx.stroke();
    ctx.restore();
  }
}

/* ==========================================================================
   ARC GAUGE  ·  meia-lua do "ESTADO DO FPS"
   ========================================================================== */
class ArcGauge {
  constructor(canvas, opts = {}) {
    this.canvas = canvas;
    this.opts = Object.assign({
      accent: '#FF2E43',
      thickness: 11,
      glow: 14,
      start: Math.PI * 0.82,
      sweep: Math.PI * 1.36,
      max: 240,
    }, opts);
    this.value = new Smoothed(0, 0.12);
    this.color = this.opts.accent;
    this.raf = null;
  }

  set(value, color) {
    this.value.set(clamp(value, 0, this.opts.max));
    if (color) this.color = color;
    this.start();
  }
  setAccent(hex) { this.opts.accent = hex; }

  start() {
    if (this.raf) return;
    const loop = () => {
      this.value.step();
      if (needsRepaint(this, this.color)) { this.draw(); markPainted(this, this.color); }
      if (Math.abs(this.value.target - this.value.v) < 0.08) {
        this.value.v = this.value.target;
        this.draw();
        markPainted(this, this.color);
        this.raf = null;
      } else this.raf = requestAnimationFrame(loop);
    };
    this.raf = requestAnimationFrame(loop);
  }

  draw() {
    const { ctx, w, h } = fitCanvas(this.canvas);
    const o = this.opts;
    ctx.clearRect(0, 0, w, h);

    const cx = w / 2, cy = h * 0.58;
    // Mesma regra do RingGauge: reservar espaco para o glow, senao o corte do
    // canvas desenha uma aresta recta em vez de esbater.
    const pad = o.thickness / 2 + o.glow + 2;
    const r = Math.max(6, Math.min(w / 2, h * 0.72) - pad);
    const pct = clamp(this.value.v / o.max, 0, 1);

    ctx.beginPath();
    ctx.arc(cx, cy, r, o.start, o.start + o.sweep);
    ctx.strokeStyle = 'rgba(255,255,255,0.07)';
    ctx.lineWidth = o.thickness;
    ctx.lineCap = 'round';
    ctx.stroke();

    if (pct <= 0.002) return;

    const grad = ctx.createLinearGradient(cx - r, cy, cx + r, cy);
    grad.addColorStop(0, shade(this.color, 0.3));
    grad.addColorStop(1, this.color);

    ctx.save();
    ctx.beginPath();
    ctx.arc(cx, cy, r, o.start, o.start + o.sweep * pct);
    ctx.strokeStyle = grad;
    ctx.lineWidth = o.thickness;
    ctx.lineCap = 'round';
    ctx.shadowColor = rgba(this.color, 0.65);
    ctx.shadowBlur = o.glow;
    ctx.stroke();
    ctx.restore();
  }
}

/* ==========================================================================
   SPARKLINE  ·  mini-grafico do HUD
   ========================================================================== */
class Sparkline {
  constructor(canvas, opts = {}) {
    this.canvas = canvas;
    this.opts = Object.assign({ accent: '#FF2E43', points: 60, glow: 0.55 }, opts);
    this.buf = [];
  }
  setAccent(hex) { this.opts.accent = hex; }

  push(v) {
    this.buf.push(v);
    while (this.buf.length > this.opts.points) this.buf.shift();
    this.draw();
  }
  clear() { this.buf = []; }

  draw() {
    const { ctx, w, h } = fitCanvas(this.canvas);
    ctx.clearRect(0, 0, w, h);
    if (this.buf.length < 2) return;

    let lo = Infinity, hi = -Infinity;
    for (const v of this.buf) { if (v < lo) lo = v; if (v > hi) hi = v; }
    if (hi - lo < 4) { const mid = (hi + lo) / 2; lo = mid - 2; hi = mid + 2; }

    const pad = 6;   // espaco para o glow nao ser cortado em cima e em baixo
    const xOf = i => (i / (this.buf.length - 1)) * w;
    const yOf = v => h - pad - ((v - lo) / (hi - lo)) * (h - pad * 2);

    const grad = ctx.createLinearGradient(0, 0, 0, h);
    grad.addColorStop(0, rgba(this.opts.accent, 0.4));
    grad.addColorStop(1, rgba(this.opts.accent, 0));

    ctx.beginPath();
    ctx.moveTo(0, yOf(this.buf[0]));
    for (let i = 1; i < this.buf.length; i++) ctx.lineTo(xOf(i), yOf(this.buf[i]));
    ctx.lineTo(w, h); ctx.lineTo(0, h); ctx.closePath();
    ctx.fillStyle = grad;
    ctx.fill();

    /* Mesma logica do grafico grande, em versao reduzida: halo colorido mais
       nucleo claro. So duas passagens — a sparkline redesenha a 4Hz e tem 34px
       de altura, nao ha espaco nem orcamento para mais. */
    const trace = () => {
      ctx.beginPath();
      ctx.moveTo(0, yOf(this.buf[0]));
      for (let i = 1; i < this.buf.length; i++) ctx.lineTo(xOf(i), yOf(this.buf[i]));
    };

    ctx.save();
    ctx.lineJoin = 'round';
    ctx.lineCap = 'round';

    const g = clamp(this.opts.glow ?? 0.55, 0, 1);

    trace();
    ctx.strokeStyle = this.opts.accent;
    ctx.lineWidth = 1.6;
    if (g > 0) {
      ctx.shadowColor = rgba(this.opts.accent, 0.55);
      ctx.shadowBlur = 11 * g;
    }
    ctx.stroke();

    trace();
    ctx.strokeStyle = shade(this.opts.accent, 0.45);
    ctx.lineWidth = 0.9;
    ctx.shadowBlur = 0;
    ctx.stroke();
    ctx.restore();
  }
}
