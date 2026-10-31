# Manual de Utilização — oxlyn-fpsboost

**Manual prático em português.** Comandos, teclas, menus e receitas para o dia a dia.

Para a documentação técnica (arquitetura, API, natives), vê o [`README.md`](README.md).

`v2.0.1` · Oxlyn Software

---

## Índice

- [1. Instalar em 3 passos](#1-instalar-em-3-passos)
- [2. Comandos](#2-comandos)
- [3. Teclas](#3-teclas)
- [4. O painel, separador a separador](#4-o-painel-separador-a-separador)
- [5. Presets — qual devo usar?](#5-presets--qual-devo-usar)
- [6. Preview — testar antes de decidir](#6-preview--testar-antes-de-decidir)
- [7. O HUD flutuante](#7-o-hud-flutuante)
- [8. Definições — todas as opções explicadas](#8-definições--todas-as-opções-explicadas)
- [9. Administração](#9-administração)
- [10. O que mexer no config.lua](#10-o-que-mexer-no-configlua)
- [11. Receitas rápidas](#11-receitas-rápidas)
- [12. Perguntas frequentes](#12-perguntas-frequentes)
- [13. O que os números querem mesmo dizer](#13-o-que-os-números-querem-mesmo-dizer)

---

## 1. Instalar em 3 passos

**1.** Põe a pasta `oxlyn-fpsboost` dentro dos teus `resources`.
Neste servidor, o sítio certo é:

```
txData\ESXLegacy_95D229.base\resources\[standalone]\oxlyn-fpsboost
```

**2.** No `server.cfg`, **depois** do `es_extended`:

```cfg
ensure oxlyn-fpsboost
```

**3.** *(Opcional, mas recomendado)* Dá acesso de admin:

```cfg
add_ace group.admin oxlyn.fps allow
```

Reinicia o servidor. Na consola deve aparecer o logo da Oxlyn e a linha
`framework: esx`. Se disser `standalone`, o `es_extended` ainda não tinha
arrancado — verifica a ordem no `server.cfg`.

> Não precisas de base de dados. As escolhas de cada jogador ficam guardadas
> no computador dele.

---

## 2. Comandos

### Para todos os jogadores

| Comando | O que faz |
|---|---|
| `/fps` | **Abre e fecha o painel.** É o comando principal. |
| `/fpshud` | Liga/desliga o contador flutuante, sem abrir o painel. |
| `/fpsboost <preset>` | Aplica um preset directamente. |
| `/fpsstats` | Mostra um resumo rápido (FPS, média, 1% low, ping, preset). |
| `/fpsreset` | Repõe **tudo** nos valores por defeito. |

**Aliases de `/fps`** (fazem exactamente o mesmo):
`/oxlyn` · `/fpsboost-menu`

### Exemplos de `/fpsboost`

```
/fpsboost off            → desliga todas as otimizações
/fpsboost light          → ganho pequeno, sem perda visual
/fpsboost balanced       → o recomendado
/fpsboost performance    → FPS acima do visual
/fpsboost extreme        → máximo FPS, jogo fica feio
/fpsboost custom         → as tuas definições guardadas
```

Se escreveres só `/fpsboost` sem nada, ele mostra-te a lista de presets
disponíveis.

### Para administradores

| Comando | Onde | O que faz |
|---|---|---|
| `/fpsadmin` | in-game | Abre o painel directamente no separador de Administração. |
| `fpsforce <id\|all> <preset>` | in-game ou consola | Força um preset a um jogador ou a todos. |
| `fpsreport` | in-game ou consola | Tabela com o FPS de todos os jogadores online. |
| `fpstelemetry` | in-game ou consola | Mostra quantos jogadores têm histórico guardado. |
| `fpstelemetry clear` | in-game ou consola | Apaga o histórico de performance guardado. |

**Exemplos:**

```
fpsforce 12 performance      → aplica "performance" ao jogador com ID 12
fpsforce all balanced        → aplica "balanced" a toda a gente
fpsreport                    → tabela ordenada do pior para o melhor FPS
```

> `fpsforce` e `fpsreport` funcionam na consola do servidor (sem barra `/`) e
> também no chat (com barra `/`), desde que sejas admin.

---

## 3. Teclas

| Tecla | Acção | Por defeito |
|---|---|---|
| `F7` | Abrir/fechar o painel | ✅ activa |
| `ESC` | Fechar o painel | sempre |
| `1`–`6` | Saltar entre separadores (com o painel aberto) | sempre |

**Trocar as teclas:** qualquer jogador pode fazê-lo no próprio FiveM, sem
mexer no script:

> **Definições do FiveM → Atalhos de teclado (Key Bindings) → FiveM**
> Procura por *"Oxlyn FPS"*.

**Adicionar mais teclas:** no `config.lua`, secção 2:

```lua
Config.Keys = {
    open       = 'F7',   -- painel
    hud        = 'F6',   -- ligar/desligar o HUD  ← põe uma tecla aqui
    quickBoost = 'F8',   -- ciclar entre presets  ← e aqui
}
```

Deixa `''` (vazio) para não registar a tecla.

---

## 4. O painel, separador a separador

### 🏠 Resumo

O ecrã principal, igual à imagem de referência.

- **FPS ACTUAL** — o número grande. Suavizado, para não tremer.
- **+X% vs. último minuto** — se subiste ou desceste face ao minuto anterior.
- **Gráfico** — os últimos 1M / 5M / 15M / 1H. Carrega nos botões para mudar.
- **MÉDIA / 1% LOW / 0.1% LOW / MAX / MIN / FRAMETIME** — ver a
  [secção 13](#13-o-que-os-números-querem-mesmo-dizer).
- **Anéis CPU / GPU / RAM / VRAM** — têm um selo `EST` porque são
  **estimativas**, não leituras do teu hardware. O FiveM não deixa um script
  ler sensores. Ver a [secção 12](#12-perguntas-frequentes).
- **Anel PING** — este é **real**, vem do servidor.
- **ESTADO DO FPS** (direita) — EXCELENTE / BOM / FRACO / MAU.
- **DICAS DE PERFORMANCE** (direita) — não são genéricas: mudam conforme o
  que está mesmo a acontecer no teu jogo.
- **Barra inferior** — hora do jogo, resolução, preset activo, entidades à
  tua volta, tempo de sessão.

### ⚡ Performance

Todos os presets em cartões. Cada um mostra:

- **Ganho** — quantas barras verdes = quanto FPS costuma dar
- **Custo visual** — quantas barras amarelas = quanto estraga a imagem
- **Aplicar** — aplica já
- **Preview** — mede o ganho real antes de decidires ([secção 6](#6-preview--testar-antes-de-decidir))

### 📈 Gráfico

Histórico detalhado, com quatro séries:

- **FPS** — o normal
- **Frametime** — para caçar stutters. Picos aqui = engasgos.
- **Ping** — latência ao longo do tempo
- **Entidades** — quantos peds/carros/objectos há à tua volta

Extras: **Suavizar** (liga/desliga a curva suave) e
**Copiar dados (CSV)** — copia os números todos para a área de transferência,
para colares no Excel.

Por baixo, cinco mini-estatísticas: média, mínimo, máximo, desvio-padrão (σ)
e quanto do intervalo já tem dados.

### 🖥️ Sistema

Está dividido em duas colunas:

- **DADOS REAIS** — tudo o que o script consegue mesmo ler
- **DADOS ESTIMADOS** — as heurísticas, com a explicação de como são feitas

No fundo, o histórico das tuas **sessões anteriores** (últimas 20).

### ⚙️ Definições

Todas as opções, organizadas por grupos, com pesquisa.
Ver a [secção 8](#8-definições--todas-as-opções-explicadas).

- Uma opção **alterada** por ti fica com uma barra colorida à esquerda e a
  etiqueta `alterado`.
- Uma opção **bloqueada** pelo servidor fica cinzenta com um cadeado.
- Uma opção que **depende** de outra fica cinzenta até ligares a principal.

### 🛡️ Administração

Só aparece a admins. Ver [secção 9](#9-administração).

### ℹ️ Sobre

Versão, framework detectado, lista de comandos e teclas activas.

---

## 5. Presets — qual devo usar?

| Preset | Para quem | O que muda |
|---|---|---|
| **Desligado** | Quem tem PC forte | Nada. Jogo intacto. |
| **Leve** | Toda a gente, sempre | Ganho pequeno mas **de borla**: quase não se nota na imagem. Sombras e LOD ligeiramente reduzidos, menos trânsito parado. |
| **Equilibrado** ⭐ | **A maioria** | O melhor compromisso. LOD a 75%, sombras reduzidas, metade do trânsito, limpeza automática ligada. |
| **Performance** | PCs fracos ou zonas cheias | Cidade bastante mais vazia, sombras de avião, sem serviços de emergência do GTA. |
| **Extremo** | Último recurso | Tudo no mínimo que o motor aceita: LOD a 20%, sombras sem profundidade, cidade às escuras e sem população, água parada, spawn de peds proibido, limpeza de 15 em 15 segundos. **Vais notar.** Pede confirmação antes de aplicar. |
| **Batata** 🥔 | Máquinas que não deviam correr o jogo | O Extremo mais três coisas que mais nenhum preset toca: LOD no chão do intervalo (10%), peds e carros no modelo simplificado logo à saída, e os cinco parâmetros de render a zero. O mundo aparece quase em cima de ti. Pede confirmação. |
| **Personalizado** | Quem gosta de mexer | As tuas definições, guardadas por ti (botão em Definições). |

**Se não sabes qual escolher:** carrega em **Preview** no *Equilibrado*. Em 20
segundos ficas a saber quanto ganhas na tua máquina, no sítio onde estás.

---

## 6. Preview — testar antes de decidir

O botão **Preview** existe porque *"este preset dá +40 FPS"* não quer dizer
nada. O ganho depende do teu PC, da zona do mapa, da hora e dos resources do
servidor.

**O que acontece quando carregas:**

1. O painel fecha-se (a própria interface gasta GPU e falsearia o teste)
2. Mede **8 segundos** com as tuas definições actuais
3. Aplica o preset
4. Espera 1,5 s para o streaming assentar (esses frames são deitados fora)
5. Mede mais **8 segundos**
6. Volta ao que estava e mostra-te a comparação

**No resultado tens:** FPS médio antes, FPS médio depois, 1% low de cada um, e
a diferença em número e em percentagem.

Depois escolhes: **Manter preset** ou **Reverter**.

> **Dica:** faz o preview no sítio onde costumas ter menos FPS (centro da
> cidade, aeroporto, evento com muita gente). Um preview no meio do deserto
> não te diz nada de útil.

---

## 7. O HUD flutuante

O contador que fica sempre no ecrã. Ligas com `/fpshud` ou em
**Definições → HUD → Mostrar HUD**.

**O que podes configurar:**

| Opção | Escolhas |
|---|---|
| Posição | Superior/inferior · esquerdo/direito |
| Tamanho | 60% a 180% |
| Opacidade | 10% a 100% |
| Mostrar frametime | ms por frame |
| Mostrar 1% low | o indicador de fluidez |
| Mostrar ping | latência |
| Mostrar mini-gráfico | sparkline dos últimos segundos |
| Mostrar entidades | contagem de peds/carros/objectos |

O número muda de cor sozinho conforme o FPS:
🟢 verde (excelente) · 🔴 cor de destaque (bom) · 🟡 amarelo (fraco) · 🔴 vermelho (mau)

O HUD esconde-se automaticamente enquanto o painel está aberto, para não
apareceres com dois contadores ao mesmo tempo.

---

## 8. Definições — todas as opções explicadas

> **Regra de ouro:** cada opção mostra duas barras. **Ganho** (verde) = quanto
> FPS costuma dar. **Custo visual** (amarelo) = quanto estraga a imagem.
> Procura as que têm muito verde e pouco amarelo.

### 🖥️ Gráficos

| Opção | O que faz | Notas |
|---|---|---|
| **Modo de sombras** | Padrão / Reduzido / Avião / Mínimo | "Avião" usa o modo de voo do GTA — muito mais barato e quase não se nota a pé. |
| **Distância das sombras** | 0–100% | Abaixo de 30% ganhas bastante. |
| **Escala de LOD** | 10–100% | **O maior ganho de uma só opção.** Controla a que distância os modelos detalhados aparecem. Abaixo de 50% nota-se pop-in. |
| **LOD de peds e veículos** | 0–100% | Força cada ped e cada carro a passar mais cedo para o modelo simplificado. A escala de LOD manda no cenário; esta manda em quem se mexe nele. |
| **Orçamento de peds** | 0–3 | Quantos modelos de pedestres o jogo mantém carregados. |
| **Orçamento de veículos** | 0–3 | O mesmo para carros. |
| **Reduzir memória de modelos** | Sim/Não | Força o jogo a gastar menos memória em modelos. |
| **Desligar decals** | Sim/Não | Remove buracos de bala, sangue, travagens, sujidade. |
| **Rastos de pneus** | Sim/Não | Marcas dos pneus no chão. |
| **Pegadas** | Sim/Não | Pegadas em areia/neve. |
| **Qualidade do oceano** | 0–100% | Grande ganho perto da costa, zero no interior. |
| **Água parada** | Sim/Não | Congela ondas, rebentação e ondulação. Quando há água à vista rende mais do que baixar a qualidade do oceano. |
| **Motion blur** | Sim/Não | Desligar também melhora a nitidez. |
| **Desfoque de ecrã** | Sim/Não | Blur em transições e menus. |
| **Grão de filme** | Sim/Não | O "ruído" cinematográfico por cima da imagem. |

### 💡 Iluminação

| Opção | O que faz | Notas |
|---|---|---|
| **Luzes da cidade** | Sim/Não | ⚠️ **Ganho enorme à noite**, mas a cidade fica às escuras. Só usar em emergência. |
| **Luzes afectam veículos** | Sim/Não | Se as luzes artificiais também iluminam carros. |
| **Luzes distantes de veículos** | Sim/Não | Faróis do trânsito ao longe. **Barato de desligar e quase não se vê.** Recomendado. |
| **Sirenes distantes** | Sim/Não | Luzes/som de polícia ao longe. |

### 👥 População

> Estas opções **só afectam NPCs do GTA**. Jogadores, veículos de jogadores e
> NPCs criados por scripts (empregos, lojas, missões) nunca são afectados.

| Opção | Notas |
|---|---|
| **Densidade de peds** | Pedestres NPC. Grande ganho em zonas movimentadas. |
| **Densidade de trânsito** | Carros NPC a circular. |
| **Veículos estacionados** | Carros parados nas ruas. **Baixar isto liberta muita memória.** |
| **Veículos aleatórios** | Spawns fora das rotas normais. |
| **Peds de cenário** | NPCs em animações fixas (bancos, paragens, a fumar). |
| **Alcance do trânsito** | A que distância o trânsito continua a existir. |
| **Alcance dos peds** | O mesmo para pedestres. Numa rua movimentada vale tanto como o do trânsito. |
| **Trânsito ao longe** | Os carros simplificados que enchem autoestradas e pontes ao fundo. Quase não se vê e alivia as vistas largas. |
| **Polícia NPC** | A maioria dos servidores RP já desliga isto. |
| **Camiões do lixo** | Vêm com equipa de NPCs. Caros. |
| **Barcos aleatórios** | Barcos NPC na água. |
| **Comboios** | Comboios e metro. |
| **Geradores de baixa prioridade** | Pontos de spawn secundários. Seguro desligar. |
| **Serviços de emergência** | Polícia/ambulância/bombeiros automáticos do GTA. |
| **Proibir spawn de peds** | Marca a zona à tua volta como área onde o motor não pode criar pedestres. Vai mais longe do que densidade a zero: nem sequer tenta. Só no preset Extremo. |
| **Proibir carros estacionados** | Põe a zero os veículos estacionados que o motor gera. As ruas ficam sem trânsito parado. |

### 🖥️ Motor de render

> Estas cinco opções não mexem no jogo: mexem nos **parâmetros internos de
> render** do motor. São multiplicadores do valor de fábrica — a 100% ficas
> exatamente com o que o GTA traz, e voltar a 100% repõe o número original.

| Opção | Notas |
|---|---|
| **Alcance das luzes da cidade** | A que distância as luzes de rua e de edifícios continuam a ser desenhadas. **De noite em Los Santos é o maior ganho deste grupo.** De dia quase não conta. |
| **Halos das luzes** | O brilho redondo à volta de cada lâmpada e farol. |
| **Luzes do horizonte** | Os pontinhos de luz que enchem a cidade e as autoestradas ao fundo. |
| **Poças e reflexos molhados** | Poças refletoras depois da chuva. Custam pouco com tempo seco e bastante com tempo húmido. |
| **Pós-processamento** | Bloom e desfoque de profundidade. A zero a imagem fica mais crua e mais nítida. |
| **Luzes dos veículos** | Os feixes visíveis dos faróis e o alcance a que as luzes dos outros carros são desenhadas. **De noite com trânsito é dos efeitos mais caros que há.** O mínimo é 15%, para os teus próprios faróis não se apagarem. |

> ⚠️ **O que nenhum script consegue fazer.** As definições gráficas do menu do
> GTA — qualidade de texturas, sombras, água, MSAA, resolução — **não têm
> forma de ser alteradas em jogo**. O motor deixa lê-las e mais nada. Se um
> script te promete "baixar as tuas definições gráficas automaticamente",
> está a mexer noutra coisa qualquer. Para as descer a sério, tens de o fazer
> no menu do próprio jogo.

### ✨ Efeitos

| Opção | Notas |
|---|---|
| **Forçar tempo limpo** | ⚠️ **Só funciona se o servidor não sincronizar o tempo à força.** Se tens `weathersync`, `vSync` ou `cd_easytime`, isto não vai pegar. |
| **Remover chuva** | Põe a chuva a zero no teu cliente. |
| **Remover vento** | Pára a simulação de vento (vegetação, panos). |
| **Limpar partículas** | Remove fumo, fogo e faíscas à tua volta periodicamente. |
| **Raio de limpeza de partículas** | 25 a 500 metros. |

### 🧹 Limpeza

> Esta é a única parte que **apaga** coisas do mundo. Foi feita para nunca
> apagar nada importante — mas lê as notas.

| Opção | Notas |
|---|---|
| **Limpeza automática** | O interruptor principal. Tudo o resto depende dele. |
| **Intervalo** | De quantos em quantos segundos corre (15 a 600). |
| **Raio** | Até que distância actua (50 a 1000 m). |
| **Limpar projécteis** | Balas, granadas, rockets em voo. **Totalmente seguro.** |
| **Limpar vidros partidos** | Restaura vidros. Seguro. |
| **Limpar decals** | Sangue, buracos de bala, sujidade. Seguro. |
| **Limpar objectos soltos** | Só objectos **locais** (não sincronizados). Props de scripts nunca são tocados. |
| **Limpar peds mortos** | Só NPCs ambiente **já mortos**. Jogadores e NPCs de script nunca. |
| **Limpar veículos vazios** | Só carros ambiente, vazios, sem dono e que nunca tiveram um jogador dentro. **Carros de garagem estão protegidos.** |

**Salvaguardas que estão sempre activas:**

- Nada é apagado a menos de **45 metros** de ti
- Máximo de **40 entidades** por passagem, por categoria
- Não corre enquanto estás a disparar ou em combate corpo a corpo
- Nada marcado como *mission entity* é tocado (todos os frameworks marcam o que criam)

### 📊 HUD

Ver [secção 7](#7-o-hud-flutuante).

### 🎨 Interface

| Opção | Notas |
|---|---|
| **Cor de destaque** | 8 cores à escolha. Muda o painel **e** o HUD. |
| **Adaptar a interface à resolução** | Ligado de origem. Em 2K e 4K o painel e o HUD crescem para ocuparem a mesma parte do ecrã que ocupam em 1080p. Desligado, ficam no tamanho original — mais pequenos quanto maior for o teu ecrã. |
| **Escala da interface** | 75% a 150%, por cima da adaptação automática. Serve para quem quer o painel mais compacto ou maior do que a conta certa. O painel nunca passa das bordas do ecrã. |
| **Vidro líquido (blur)** | Desfoca o **jogo** por trás do painel (a mesma coisa que o menu de pausa faz). Se a interface te tirar FPS, desliga — os painéis passam a quase opacos. |
| **Escurecer o fundo** | 0% a 85%. Quanto o jogo é escurecido por trás do painel. **0% deixa o jogo totalmente visível**; sobe se estiveres de dia e o texto custar a ler. |
| **Animações** | Transições e movimento. |
| **Sons** | Efeitos ao abrir/fechar/clicar. |
| **Intervalo do gráfico** | Qual dos 4 intervalos abre por defeito. |
| **Idioma** | Português ou Inglês. Muda tudo na hora. |
| **Mostrar estimativas** | Desliga os anéis CPU/GPU/RAM/VRAM. Fica só o ping (que é real). |

### 🤖 Automação

> **Os presets cortam onde se vê. Estas três opções cortam onde não se vê.**
> São uma camada temporária por cima do teu preset: entram quando a situação
> começa, saem quando acaba, e nunca ficam guardadas. O painel continua a
> mostrar o que **tu** escolheste, mesmo enquanto a camada está ativa.

| Opção | Notas |
|---|---|
| **Boost automático** | O script sobe o preset sozinho quando o FPS cai, e desce quando recupera. |
| **Poupar no menu de pausa** | Ligado de origem. Com o menu aberto o jogo continua a desenhar o mundo atrás dele sem ninguém o ver: baixa sombras, LOD e render enquanto lá estás. Ao fechar volta tudo, e a rua está como a deixaste. |
| **Modo ausente** | Uns minutos sem mexer, sem rodar a câmara e sem carregar em nada, e o jogo passa ao mínimo: mundo vazio, render no chão. O primeiro toque repõe o teu preset. Ligado no Equilibrado e acima. |
| **Minutos até ausente** | 1 a 15. O Batata usa 2. |
| **Aliviar em interiores** | Dentro de um interior o trânsito e os peds lá fora continuam a ser simulados sem se verem. Reduz a população exterior enquanto estás dentro. Nota-se nas janelas de apartamentos, por isso só vem ligado no Desempenho e acima. |
| **Subir preset abaixo de** | FPS médio (10 s) que dispara um preset mais agressivo. Defeito: 45. |
| **Descer preset acima de** | FPS médio que permite voltar a um preset mais bonito. Defeito: 90. |
| **Espera entre mudanças** | Evita que o preset ande a saltar. Defeito: 30 s. |
| **Alerta de FPS baixo** | Avisa-te quando o FPS fica baixo. |
| **Limite do alerta** | Abaixo deste valor recebes o aviso. |

> O alerta só dispara depois de **15 segundos seguidos** abaixo do limite, e no
> máximo de 2 em 2 minutos. Um pico isolado de streaming não te chateia.

---

## 9. Administração

### O painel de admin

`/fpsadmin` (ou o separador **Administração**) mostra uma tabela com todos os
jogadores online, **ordenada do pior FPS para o melhor**:

| Coluna | O que é |
|---|---|
| ID | ID do jogador no servidor |
| NOME | Nome |
| FPS | FPS no último relatório |
| MÉDIA | Média dele |
| 1% LOW | Fluidez real |
| PING | Latência (real, ao vivo) |
| PRESET | Preset activo |
| *(dropdown)* | Muda o preset dele na hora |

Linhas a cinzento = sem dados recentes (jogador entrou há menos de ~45 s ou
tem a telemetria desligada).

**Aplicar a todos:** escolhe o preset no canto superior direito e carrega em
**Aplicar a todos**.

### Bloquear opções aos jogadores

No `config.lua`, secção 10:

```lua
Config.Restrictions = {
    -- Impede os jogadores de mexer nestas opções
    lockedSettings = { 'artificialLights', 'forceClearWeather' },

    -- Presets que os jogadores normais não podem usar (admins podem sempre)
    lockedPresets = { 'extreme' },

    -- Preset máximo permitido a jogadores normais
    maxPreset = 'performance',

    -- Se true, ignora o que o jogador tinha guardado e força o preset
    -- por defeito sempre que ele entra
    forceDefaultOnJoin = false,
}
```

**Porque é que quererias bloquear alguma coisa?**
O exemplo clássico é `artificialLights`. Desligar as luzes da cidade dá muito
FPS à noite — mas também dá **vantagem injusta** em situações de RP nocturno.
Muitos servidores proíbem.

### Permissões de admin

Duas formas, e qualquer uma serve:

**1. ACE (recomendado)** — no `server.cfg`:

```cfg
add_ace group.admin oxlyn.fps allow
```

**2. Grupos do framework** — no `config.lua`:

```lua
Config.Admin = {
    groups = { 'admin', 'superadmin', 'god', 'owner' },
    ace    = 'oxlyn.fps',
}
```

No ESX, isto compara com o `group` do jogador (`xPlayer.getGroup()`).

---

## 10. O que mexer no config.lua

Não precisas de perceber o ficheiro todo. Isto é o que te interessa:

| Quero... | Vai a... | Muda |
|---|---|---|
| Mudar a tecla do painel | Secção 2 | `Config.Keys.open` |
| Mudar o nome dos comandos | Secção 2 | `Config.Commands` |
| Definir quem é admin | Secção 3 | `Config.Admin.groups` / `.ace` |
| Mudar o preset que toda a gente começa com | Secção 6 | `Config.DefaultPreset` |
| Esconder os anéis CPU/GPU/RAM/VRAM | Secção 5 | `Config.Metrics.showEstimates = false` |
| Mudar os limites de "excelente/bom/mau" | Secção 5 | `Config.Metrics.fpsExcellent` etc. |
| Criar/editar presets | Secção 6 | `Config.Presets` |
| Mudar o valor de defeito de uma opção | Secção 7 | o `default` da opção |
| Proteger modelos da limpeza | Secção 7B | `Config.CleanupSafety.protectedModels` |
| Tornar a limpeza mais/menos agressiva | Secção 7B | `minDistance`, `maxPerPass` |
| Mudar a duração do preview | Secção 8 | `Config.Preview` |
| Mudar o tipo de notificações | Secção 9 | `Config.Notify.type` |
| Bloquear opções aos jogadores | Secção 10 | `Config.Restrictions` |
| Desligar a telemetria | Secção 11 | `Config.Telemetry.enabled = false` |
| Impedir abrir o painel a conduzir | Secção 12 | `blockWhileDriving = true` |
| Ver o que se passa (debug) | Secção 1 | `Config.Debug = true` |

**Depois de mexer no `config.lua`:**

```
restart oxlyn-fpsboost
```

---

## 11. Receitas rápidas

**"Quero o máximo de FPS sem que o jogo fique feio."**
`/fpsboost balanced` → depois desliga também *Luzes distantes de veículos* e
*Camiões do lixo* em Definições. São gratuitos.

**"Tenho stutters, não FPS baixo."**
Vai ao **Gráfico → Frametime**. Se vires picos altos e isolados, é streaming ou
um resource pesado — não é falta de FPS. Liga a **Limpeza automática** e baixa
os **Veículos estacionados**.

**"Só quero o contador, não quero o painel."**
`/fpshud` e pronto. Depois configura-o em **Definições → HUD**.

**"Quero que toda a gente entre com o preset equilibrado."**

```lua
Config.DefaultPreset = 'balanced'
Config.Restrictions.forceDefaultOnJoin = true
```

**"Não quero que ninguém desligue as luzes da cidade."**

```lua
Config.Restrictions.lockedSettings = { 'artificialLights' }
```

**"Quero saber quem está com problemas de FPS."**
Consola do servidor: `fpsreport`

**"Quero o painel noutra cor."**
**Definições → Interface → Cor de destaque.** Muda painel e HUD ao mesmo tempo.

**"A interface está a tirar-me FPS."**
**Definições → Interface → Vidro líquido (blur) → Desligar.**
Deixa de desfocar o jogo por trás do painel, que é a parte mais cara.

**"O painel tapa demasiado o jogo / quero ver melhor o que está atrás."**
**Definições → Interface → Escurecer o fundo** e baixa para 0–15%.

**"Quero criar o meu próprio preset."**
Mexe em tudo o que quiseres em Definições → depois carrega em
**Guardar como preset personalizado**. Fica disponível como `/fpsboost custom`.

**"Quero levar os números para o Excel."**
**Gráfico → Copiar dados (CSV)** → cola no Excel.

---

## 12. Perguntas frequentes

### Porque é que o CPU/GPU/RAM/VRAM têm um selo `EST`?

Porque são **estimativas**, não leituras do teu hardware.

Um script de FiveM **não tem acesso a sensores**. Não existe nenhuma função
que devolva o uso real do processador, a temperatura da placa gráfica ou a
VRAM ocupada. **Nenhuma.** Se algum dia viste um script de FPS a mostrar-te
`CPU 65°C`, esse número era inventado.

Este script prefere ser honesto:
- **Real** → FPS, frametime, 1% low, ping, entidades, resolução
- **Estimado** (selo `EST`) → CPU, GPU, RAM, VRAM
- **Não disponível** → temperaturas, uso real, VRAM em MB, Hz do monitor

As estimativas são calculadas a partir de dados reais (estabilidade do
frametime, densidade de entidades, memória Lua) e servem para ver
**tendências** — "isto piorou depois de eu entrar naquele MLO?" — e não como
valores absolutos.

Se preferires não as ver: **Definições → Interface → Mostrar estimativas**.

### Porque é que "Forçar tempo limpo" não faz nada?

Porque o teu servidor sincroniza o tempo à força. Scripts como `weathersync`,
`vSync` ou `cd_easytime` reescrevem o tempo no cliente de poucos em poucos
segundos, e o teu pedido é apagado. É uma limitação do servidor, não um erro
do script — por isso é que a descrição da opção avisa disso.

### A limpeza pode apagar o meu carro?

Não deve. Um veículo só é apagado se cumprir **tudo** isto: estar vazio, não
ser mission entity, nunca ter tido um jogador dentro, estar a mais de 45 m de
ti, e não estar na lista de modelos protegidos.

Se mesmo assim acontecer, o problema é do script que criou o carro (não o
marcou como mission entity). Solução imediata:

```lua
Config.CleanupSafety.protectedModels = { 'adder', 'police', 'ambulance' }
```

### Isto vai fazer-me apanhar ban por anti-cheat?

Não. O script só usa natives oficiais de otimização que qualquer script de FPS
boost usa, todos do lado do cliente e todos documentados no README. Não mexe
em memória, não injecta nada, não altera ficheiros do jogo.

### Perco as minhas definições quando saio?

Não. Ficam guardadas no teu PC (KVP do FiveM) e voltam quando entrares outra
vez — a menos que o dono do servidor tenha activado `forceDefaultOnJoin`.

### O script gasta FPS?

Com o painel fechado e sem preset, praticamente nada — três threads a dormir.
Com um preset activo, corre um ciclo por frame com ~10 chamadas (é obrigatório;
as funções `ThisFrame` do GTA têm de ser chamadas todos os frames).
Com o painel aberto é quando gasta mais — por isso é que o **Preview fecha o
painel** antes de medir.

### Posso usar isto com o meu HUD actual?

Sim. O HUD deste script é independente e podes deixá-lo desligado. Se quiseres
usar o FPS deste script no teu HUD:

```lua
local fps = exports['oxlyn-fpsboost']:GetFps()
local stats = exports['oxlyn-fpsboost']:GetStats()  -- média, 1% low, etc.
```

### Como sei se está a funcionar?

Faz um **Preview**. Ele mede antes e depois e diz-te o número exacto. Se um
preset não te der ganho nenhum, é porque o teu gargalo está noutro sítio
(normalmente CPU ou um resource pesado do servidor) — e isso é informação útil.

---

## 13. O que os números querem mesmo dizer

### FPS médio

Quantos frames por segundo em média. É o número que toda a gente conhece, mas
sozinho **engana**.

### 1% low ⭐

**O número mais importante do painel.**

É a média do 1% de frames mais lentos. Traduzindo: quão mau fica o jogo nos
piores momentos.

- **1% low perto da média** → jogo fluido e consistente
- **1% low muito abaixo da média** → *stutter*

> **Exemplo real:**
> **PC A:** média 120, 1% low 110 → sente-se lindamente
> **PC B:** média 140, 1% low 35 → engasga constantemente
>
> O PC B tem mais FPS médio e joga muito pior. É por isso que o 1% low existe.

### 0.1% low

O mesmo, mas para o 0.1% de frames mais lentos. Apanha os engasgos grandes e
raros — normalmente streaming a carregar coisas novas.

### Frametime

Quantos milissegundos demora cada frame. É o inverso do FPS:

| FPS | Frametime |
|---|---|
| 30 | 33.3 ms |
| 60 | 16.7 ms |
| 120 | 8.3 ms |
| 144 | 6.9 ms |

Para caçar stutters, olha para o **frametime no gráfico**, não para o FPS. Os
picos vêem-se muito melhor.

### Entidades

Quantos peds + veículos + objectos + pickups estão à tua volta. É o número que
melhor explica porque é que o centro da cidade corre pior que o deserto.

Acima de **700** já vale a pena baixar as densidades.

### Ping

Latência ao servidor, em milissegundos. **Não afecta o teu FPS** — mas afecta
a fluidez do que vês (outros jogadores a "teleportar", carros a corrigir
posição).

- 🟢 até 60 ms — óptimo
- 🟡 60–120 ms — aceitável
- 🔴 acima de 120 ms — vais notar

---

## Suporte

**Oxlyn Software** · `oxlyn-fpsboost` v2.0.1

Antes de reportares um problema:

1. Põe `Config.Debug = true` no `config.lua` e faz `restart oxlyn-fpsboost`
2. Abre a consola do cliente com **F8** e vê se há erros
3. Confirma na consola do servidor que o framework foi detectado

Documentação técnica completa: [`README.md`](README.md)
