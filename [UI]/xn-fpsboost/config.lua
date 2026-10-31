

--[[
    ============================================================================
     UNDER STAR COMMUNITY  ·  oxlyn-fpsboost  ·  v1.0.0
    ============================================================================
     Ficheiro de configuracao principal.

     LEITURA IMPORTANTE
     ------------------
     Este script usa um sistema de "schema": cada opcao de otimizacao esta
     declarada em Config.Settings com o seu tipo, limites e valor por defeito.
     A interface (NUI) e construida automaticamente a partir desta lista.

     Isto significa que:
       * Se adicionares uma entrada nova em Config.Settings, ela aparece
         automaticamente no menu in-game, sem tocar em HTML/CSS/JS.
       * Se mudares um `default` aqui, muda o valor base para toda a gente.
       * O jogador pode alterar tudo in-game; as escolhas dele sao guardadas
         localmente (KVP) e sobrepoem-se aos defaults.

     Ver README.md (tecnico, EN/PT) e MANUAL_PT.md (utilizador, PT).
    ============================================================================
]]

Config = {}

-- ============================================================================
--  1. GERAL
-- ============================================================================

--- Default language of the UI and notifications: pt, en, es, fr, de, pl, nl, it, tr, ru, cs, sv.
--- O jogador pode trocar in-game (Definicoes > Interface > Idioma).
Config.Locale = 'en'

--- Framework a usar. 'auto' deteta sozinho pela ordem: Qbox > QBCore > ESX.
--- Valores validos: 'auto' | 'esx' | 'qb' | 'qbox' | 'standalone'
Config.Framework = 'auto'

--- Nomes dos resources, caso tenhas renomeado o teu framework.
Config.FrameworkResources = {
    esx  = 'es_extended',
    qb   = 'qb-core',
    qbox = 'qbx_core',
}

--- Imprime informacao extra na consola (F8 no cliente / consola do servidor).
Config.Debug = false

--- Mostra o banner ASCII da Oxlyn no arranque do resource.
Config.ShowBanner = true

-- ============================================================================
--  2. COMANDOS E TECLAS
-- ============================================================================

Config.Commands = {
    --- Comando principal que abre o painel.
    open       = 'fps',
    --- Liga/desliga o HUD flutuante sem abrir o painel.
    hud        = 'fpshud',
    --- Aplica um preset directamente: /fpsboost performance
    preset     = 'fpsboost',
    --- Reinicia todas as definicoes do jogador para os defaults do config.
    reset      = 'fpsreset',
    --- Mostra um resumo rapido no chat (FPS medio, 1% low, ping...).
    stats      = 'fpsstats',
}

--- Aliases extra para o comando de abertura. Deixa {} para nao criar nenhum.
Config.CommandAliases = { 'fpsboost-menu', 'oxlyn' }

--- Teclas por defeito. O jogador pode remapear em Definicoes > Teclado do FiveM.
--- Deixa a string vazia ('') para NAO registar o keymapping.
--- Lista de teclas: https://docs.fivem.net/docs/game-references/input-mapper-parameter-ids/
Config.Keys = {
    open       = '',   -- abre/fecha o painel
    hud        = '',     -- ex.: 'F6' para alternar o HUD
    quickBoost = '',     -- ex.: 'F8' para ciclar entre presets
}

-- ============================================================================
--  3. PERMISSOES DE ADMINISTRACAO
-- ============================================================================
--  Admins podem: forcar presets (comando fpsforce) e ignorar as restricoes
--  de Config.Restrictions. Nao ha painel nem recolha de dados dos jogadores.

Config.Admin = {
    --- Grupos do framework aceites (ESX: getGroup / QB-Qbox: PlayerData.job ou permission).
    groups = { 'admin', 'superadmin', 'god', 'owner' },

    --- Permissao ACE alternativa (server.cfg: add_ace group.admin oxlyn.fps allow).
    --- Deixa como nil/false para desactivar a via ACE.
    ace = 'oxlyn.fps',

    --- Se true, quem tiver a ACE 'command' (normalmente a consola/owner) tambem passa.
    allowConsoleAce = true,
}

-- ============================================================================
--  4. MONITORIZACAO / MOTOR DE FPS
-- ============================================================================

Config.Monitor = {
    --- Amostras por segundo guardadas no historico.
    --- O FPS instantaneo e sempre medido a cada frame; isto so controla a
    --- densidade do historico usado nos graficos. 10 = 10 pontos/segundo.
    sampleRate = 10,

    --- Minutos de historico mantidos em memoria (usado pelo grafico 1H).
    --- 60 minutos a 10 amostras/s = 36.000 floats. Impacto de RAM desprezavel.
    historyMinutes = 60,

    --- Janela (em segundos) usada para calcular AVERAGE / 1% LOW / 0.1% LOW
    --- no cartao principal.
    statsWindow = 60,

    --- Intervalo (ms) a que o cliente envia metricas para a NUI enquanto o
    --- painel esta aberto. 50ms = 20 updates/s, que e o que faz o contador
    --- parecer mesmo em tempo real. Sobe para 100 se tiveres PCs muito fracos.
    --- Nota: as dicas de performance sao recalculadas so 1x por segundo, nao a
    --- este ritmo — ver buildTips em client/main.lua.
    uiTickMs = 50,

    --- Intervalo (ms) de actualizacao do HUD flutuante (mais leve que a NUI).
    hudTickMs = 120,

    --- Guarda a sessao (FPS medio, minimo, maximo, duracao) ao sair.
    --- Fica disponivel no separador Estatisticas como "Sessoes anteriores".
    saveSessions = true,
    maxSavedSessions = 20,
}

-- ============================================================================
--  5. METRICAS DE SISTEMA (LEITURA OBRIGATORIA)
-- ============================================================================
--[[
    O QUE E REAL E O QUE E ESTIMADO
    -------------------------------
    Um resource de FiveM NAO tem acesso a sensores de hardware. Nao existe
    nenhuma native que devolva uso de CPU, uso de GPU, temperaturas, VRAM
    ocupada ou refresh rate do monitor. Qualquer script que te mostre
    "CPU 45C" esta a inventar o numero.

    Este script e honesto sobre isso:

    REAL (lido do jogo)               ESTIMADO (heuristica, badge "EST")
    --------------------------        ----------------------------------
    FPS instantaneo                   Carga de CPU
    Frametime (ms)                    Carga de GPU
    1% low / 0.1% low / max / avg     Pressao de RAM
    Ping ao servidor                  Pressao de VRAM
    Resolucao do ecra
    Peds / veiculos / objectos
    Memoria do VM Lua
    Nr. de resources activos
    Jogadores online / slots
    Tempo de sessao

    As estimativas sao derivadas de sinais reais:
      * Carga de CPU  -> estabilidade do frametime (variancia entre frames).
                         CPU saturada produz frametimes irregulares.
      * Carga de GPU  -> frametime medio vs. o melhor frametime observado
                         na sessao (o "teto" da tua maquina).
      * RAM           -> memoria do VM Lua + contagem de entidades no pool.
      * VRAM          -> densidade de entidades e objectos visiveis.

    Sao uteis como TENDENCIA (ver se algo piorou), nao como valor absoluto.
    Se preferires nao as mostrar, poe `showEstimates = false` abaixo — os
    aneis desaparecem da UI e o layout ajusta-se sozinho.
]]

Config.Metrics = {
    --- Mostra os aneis CPU / GPU / RAM / VRAM (estimados) no painel.
    showEstimates = true,

    --- Mostra o badge "EST" nesses aneis. Recomendado deixar true — e o que
    --- distingue este script de um que mente ao jogador.
    showEstimateBadge = true,

    --- NUNCA mostrar temperaturas. Nao existe forma de as obter num resource.
    --- Esta flag existe apenas para documentar a decisao; nao a mudes.
    showTemperatures = false,

    --- Anel de PING: limites (ms) para cor verde / amarela / vermelha.
    pingGood = 60,
    pingWarn = 120,

    --- Limites de FPS para o estado no painel (EXCELENTE / BOM / FRACO / MAU).
    fpsExcellent = 120,
    fpsGood      = 60,
    fpsPoor      = 30,
}

-- ============================================================================
--  6. PRESETS
-- ============================================================================
--  Cada preset define valores para os IDs declarados em Config.Settings.
--  Qualquer ID nao listado num preset mantem o `default` do schema.
--  `id` tem de ser unico. A ordem aqui e a ordem mostrada na UI.

Config.DefaultPreset = 'off'          -- preset aplicado a quem entra pela 1a vez
Config.AllowCustomPreset = true       -- permite ao jogador guardar perfis proprios

--- Quantos perfis personalizados cada jogador pode guardar.
--- Ficam no KVP da maquina dele, por isso o custo e do lado do cliente e o
--- limite serve so para a grelha de presets nao ficar interminavel.
Config.MaxCustomPresets = 6

Config.Presets = {
    {
        id = 'off',
        label = { pt = 'Desligado', en = 'Tắt' },
        desc  = { pt = 'Jogo intacto. Nenhuma otimizacao aplicada.',
                  en = 'Giữ nguyên trò chơi. Không áp dụng tối ưu hóa.' },
        icon = 'power',
        values = {}, -- Để trống = dùng toàn bộ giá trị mặc định của schema
    },
    {
        id = 'thailor',
        label = { pt = 'Thailor Boots', en = 'UnderStar Boots' },
        desc  = { pt = 'Sem sombras dinamicas, luzes e cordas. FPS maximo, visual plano.',
                  en = 'Tắt bóng động, chiếu sáng từ xa và bóng dây. FPS tối đa, hình ảnh phẳng (ưu tiên hiệu suất cao, nên sử dụng).' },
        icon = 'zap',
        confirm = true,
        values = {
            thailorBoots = true,
        },
    },
    {
        id = 'light',
        label = { pt = 'Leve', en = 'Nhẹ' },
        desc  = { pt = 'Ganho pequeno, zero perda visual. Seguro para RP.',
                  en = 'Tăng nhẹ FPS, không giảm chất lượng hình ảnh. Phù hợp cho RP.' },
        icon = 'feather',
        values = {
            shadowMode          = 'reduced',
            shadowDistance      = 0.75,
            lodScale            = 0.90,
            disableDecals       = false,
            vehicleTrails       = false,
            oceanScaler         = 0.60,
            vehicleDistantLights= false,
            distantSirens       = false,
            pedDensity          = 0.85,
            vehicleDensity      = 0.85,
            parkedDensity       = 0.70,
            randomVehDensity    = 0.80,
            scenarioDensity     = 0.80,
            garbageTrucks       = false,
            randomBoats         = false,
            lowPriorityVehGens  = false,
            cleanupEnabled      = true,
            cleanupInterval     = 120,
            cleanupRadius       = 400,
            clearProjectiles    = true,
            clearGlass          = true,
        },
    },
    {
        id = 'balanced',
        label = { pt = 'Equilibrado', en = 'Cân bằng' },
        desc  = { pt = 'A melhor relacao FPS/visual. Recomendado para a maioria.',
                  en = 'Cân bằng tốt nhất giữa FPS và hình ảnh. Phù hợp với đa số người chơi.' },
        icon = 'scale',
        values = {
            shadowMode          = 'reduced',
            shadowDistance      = 0.45,
            lodScale            = 0.75,
            pedLodBudget        = 2,
            vehLodBudget        = 2,
            reduceModelBudget   = true,
            disableDecals       = false,
            vehicleTrails       = false,
            footstepTracks      = false,
            oceanScaler         = 0.30,
            screenBlur          = true,
            filmGrain           = true,
            vehicleDistantLights= false,
            distantSirens       = false,
            pedDensity          = 0.60,
            vehicleDensity      = 0.60,
            parkedDensity       = 0.40,
            randomVehDensity    = 0.55,
            scenarioDensity     = 0.55,
            ambientVehRange     = 0.60,
            ambientPedRange     = 0.60,
            distantCars         = false,
            renderLodLights     = 0.70,
            renderPuddles       = 0.60,
            renderVehicleLights = 0.80,
            entityLod           = 0.80,
            afkSaver            = true,
            randomCops          = false,
            garbageTrucks       = false,
            randomBoats         = false,
            randomTrains        = false,
            lowPriorityVehGens  = false,
            dispatchServices    = false,
            cleanupEnabled      = true,
            cleanupInterval     = 90,
            cleanupRadius       = 350,
            clearProjectiles    = true,
            clearGlass          = true,
            clearDecals         = true,
            clearObjects        = true,
        },
    },
    {
        id = 'performance',
        label = { pt = 'Performance', en = 'Hiệu năng' },
        desc  = { pt = 'FPS acima do visual. Cidade mais vazia e sombras curtas.',
                  en = 'Ưu tiên FPS hơn hình ảnh. Thành phố vắng hơn, khoảng cách bóng đổ ngắn hơn.' },
        icon = 'zap',
        values = {
            shadowMode          = 'aircraft',
            shadowDistance      = 0.15,
            lodScale            = 0.50,
            flatWater           = true,
            blockParkedSpawns   = true,
            pedLodBudget        = 1,
            vehLodBudget        = 1,
            reduceModelBudget   = true,
            disableDecals       = true,
            vehicleTrails       = false,
            footstepTracks      = false,
            oceanScaler         = 0.10,
            motionBlur          = false,
            screenBlur          = true,
            filmGrain           = true,
            artificialLightsVeh = false,
            vehicleDistantLights= false,
            distantSirens       = false,
            pedDensity          = 0.30,
            vehicleDensity      = 0.30,
            parkedDensity       = 0.15,
            randomVehDensity    = 0.25,
            scenarioDensity     = 0.20,
            ambientVehRange     = 0.30,
            ambientPedRange     = 0.30,
            distantCars         = false,
            entityLod           = 0.50,
            renderLodLights     = 0.35,
            renderCoronas       = 0.50,
            renderDistantLights = 0.40,
            renderPuddles       = 0.20,
            renderPostFx        = 0.50,
            renderVehicleLights = 0.60,
            afkSaver            = true,
            interiorSaver       = true,
            randomCops          = false,
            garbageTrucks       = false,
            randomBoats         = false,
            randomTrains        = false,
            lowPriorityVehGens  = false,
            dispatchServices    = false,
            forceClearWeather   = false,
            killRain            = true,
            killWind            = true,
            particleCleanup     = true,
            cleanupEnabled      = true,
            cleanupInterval     = 60,
            cleanupRadius       = 300,
            clearProjectiles    = true,
            clearGlass          = true,
            clearDecals         = true,
            clearObjects        = true,
            clearDeadPeds       = true,
            clearEmptyVehicles  = true,
        },
    },
 
}

-- ============================================================================
--  7. SCHEMA DE DEFINICOES
-- ============================================================================
--[[
    Cada entrada aceita:
      id       (string)  identificador unico, usado nos presets e no codigo
      group    (string)  id do grupo (ver Config.SettingGroups)
      type     (string)  'toggle' | 'range' | 'select' | 'color'
      default  (any)     valor base
      label    (table)   { pt = '...', en = '...' }
      desc     (table)   descricao curta mostrada por baixo
      impact   (number)  0-3, quantas barras de "ganho de FPS" a UI mostra
      visual   (number)  0-3, quanto degrada a imagem
      min/max/step       apenas para 'range'
      options  (table)   apenas para 'select': { { value=, label={pt=,en=} } }
      adminOnly(bool)    so aparece a admins
      requires (string)  id de outro toggle que tem de estar ligado
      unit     (string)  sufixo mostrado no valor ('%', 'm', 's', 'x')
      scale    (number)  multiplica o valor na apresentacao (ex.: 100 p/ %)
]]

--[[  `section` divide a barra lateral das definicoes em dois blocos.

      'performance' -> o que muda os FPS
      'appearance'  -> o que muda o aspecto do painel e do HUD

      A divisao nao e cosmetica. O botao "Personalizar" do preset Personalizado
      abre as definicoes ja neste primeiro bloco, e um perfil personalizado
      guarda apenas as definicoes de 'performance': a cor de destaque ou a
      posicao do HUD sao gostos que acompanham o jogador, nao fazem parte de uma
      configuracao de desempenho e nao devem mudar quando ele troca de perfil.

      Ver Oxlyn.SaveCustomProfile em client/state.lua.                       ]]
Config.SettingGroups = {
    { id = 'graphics',   section = 'performance', icon = 'monitor',  label = { pt = 'Graficos',    en = 'Graphics'   } },
    { id = 'lighting',   section = 'performance', icon = 'bulb',     label = { pt = 'Iluminacao',  en = 'Lighting'   } },
    { id = 'render',     section = 'performance', icon = 'monitor',  label = { pt = 'Motor de render', en = 'Render engine' } },
    { id = 'population', section = 'performance', icon = 'users',    label = { pt = 'Populacao',   en = 'Population' } },
    { id = 'effects',    section = 'performance', icon = 'sparkles', label = { pt = 'Efeitos',     en = 'Effects'    } },
    { id = 'cleanup',    section = 'performance', icon = 'broom',    label = { pt = 'Limpeza',     en = 'Cleanup'    } },
    { id = 'automation', section = 'performance', icon = 'robot',    label = { pt = 'Automacao',   en = 'Automation' } },
    { id = 'hud',        section = 'appearance',  icon = 'gauge',    label = { pt = 'HUD',         en = 'HUD'        } },
    { id = 'interface',  section = 'appearance',  icon = 'palette',  label = { pt = 'Tema e cores',en = 'Theme & colours' } },
}

Config.Settings = {

    -- ---------------------------------------------------------------- GRAFICOS
    {
        id = 'shadowMode', group = 'graphics', type = 'select', default = 'default',
        label = { pt = 'Modo de sombras', en = 'Shadow mode' },
        desc  = { pt = 'Controla as cascade shadows. "Aviao" usa o modo de voo (muito mais barato).',
                  en = 'Controls cascade shadows. "Aircraft" uses flight mode (far cheaper).' },
        impact = 3, visual = 2,
        options = {
            { value = 'default',  label = { pt = 'Padrao',   en = 'Default'  } },
            { value = 'reduced',  label = { pt = 'Reduzido', en = 'Reduced'  } },
            { value = 'aircraft', label = { pt = 'Aviao',    en = 'Aircraft' } },
            { value = 'off',      label = { pt = 'Minimo',   en = 'Minimum'  } },
        },
    },
    {
        id = 'shadowDistance', group = 'graphics', type = 'range', default = 1.0,
        min = 0.0, max = 1.0, step = 0.05, scale = 100, unit = '%',
        label = { pt = 'Distancia das sombras', en = 'Shadow distance' },
        desc  = { pt = 'Profundidade dinamica das cascatas. Abaixo de 30% ganhas bastante FPS.',
                  en = 'Cascade dynamic depth. Below 30% you gain a lot of FPS.' },
        impact = 2, visual = 2,
    },
    {
        id = 'lodScale', group = 'graphics', type = 'range', default = 1.0,
        -- O chao desce a 10%: abaixo de 20% o mundo comeca a aparecer quase
        -- em cima do jogador, o que so faz sentido num preset de ultimo
        -- recurso, mas e' exactamente o que o Potato quer poder pedir.
        min = 0.10, max = 1.0, step = 0.05, scale = 100, unit = '%',
        label = { pt = 'Escala de LOD', en = 'LOD scale' },
        desc  = { pt = 'Distancia a que os modelos detalhados aparecem. O maior ganho single-setting.',
                  en = 'Distance at which detailed models appear. The biggest single-setting gain.' },
        impact = 3, visual = 3,
    },
    {
        id = 'pedLodBudget', group = 'graphics', type = 'range', default = 3,
        min = 0, max = 3, step = 1,
        label = { pt = 'Orcamento de peds', en = 'Ped budget' },
        desc  = { pt = 'Quantos modelos de pedestres o streaming mantem carregados (0 = minimo).',
                  en = 'How many ped models streaming keeps loaded (0 = minimum).' },
        impact = 2, visual = 1,
    },
    {
        id = 'vehLodBudget', group = 'graphics', type = 'range', default = 3,
        min = 0, max = 3, step = 1,
        label = { pt = 'Orcamento de veiculos', en = 'Vehicle budget' },
        desc  = { pt = 'O mesmo para modelos de veiculos.',
                  en = 'Same, for vehicle models.' },
        impact = 2, visual = 1,
    },
    {
        id = 'reduceModelBudget', group = 'graphics', type = 'toggle', default = false,
        label = { pt = 'Reduzir memoria de modelos', en = 'Reduce model memory' },
        desc  = { pt = 'Forca o jogo a usar menos memoria em modelos de peds e carros.',
                  en = 'Forces the game to use less memory on ped and car models.' },
        impact = 2, visual = 1,
    },
    {
        id = 'thailorBoots', group = 'graphics', type = 'toggle', default = false,
        label = { pt = 'Thailor Boots', en = 'Thailor Boots' },
        desc  = { pt = 'Timecycle sem luz direta, sombras de cascata e cordas desligadas, luzes sem alcance.',
                  en = 'Flat timecycle, cascade/rope shadows off, lights with no cutoff distance.' },
        impact = 3, visual = 3,
    },
    {
        id = 'disableDecals', group = 'graphics', type = 'toggle', default = false,
        label = { pt = 'Desligar decals', en = 'Disable decals' },
        desc  = { pt = 'Remove marcas de bala, sangue, rastos de travagem e sujidade.',
                  en = 'Removes bullet holes, blood, skid marks and dirt.' },
        impact = 1, visual = 2,
    },
    {
        id = 'vehicleTrails', group = 'graphics', type = 'toggle', default = true,
        label = { pt = 'Rastos de pneus', en = 'Tyre trails' },
        desc  = { pt = 'Marcas deixadas pelos pneus no chao.',
                  en = 'Marks left by tyres on the ground.' },
        impact = 1, visual = 1,
    },
    {
        id = 'footstepTracks', group = 'graphics', type = 'toggle', default = true,
        label = { pt = 'Pegadas', en = 'Footstep tracks' },
        desc  = { pt = 'Pegadas deixadas pelos peds em areia/neve.',
                  en = 'Footprints left by peds on sand/snow.' },
        impact = 1, visual = 1,
    },
    {
        id = 'oceanScaler', group = 'graphics', type = 'range', default = 1.0,
        min = 0.0, max = 1.0, step = 0.05, scale = 100, unit = '%',
        label = { pt = 'Qualidade do oceano', en = 'Ocean quality' },
        desc  = { pt = 'Simulacao de ondas em mar aberto. Grande ganho perto da costa.',
                  en = 'Open-sea wave simulation. Big gain near the coast.' },
        impact = 2, visual = 2,
    },
    {
        id = 'flatWater', group = 'graphics', type = 'toggle', default = false,
        label = { pt = 'Agua parada', en = 'Flat water' },
        desc  = { pt = 'Congela a simulacao de ondas, rebentacao e ondulacao. Vale mais do que baixar a qualidade do oceano sempre que haja agua a vista.',
                  en = 'Freezes wave, shore-break and ripple simulation. Worth more than lowering ocean quality whenever water is on screen.' },
        impact = 2, visual = 2,
    },
    {
        id = 'motionBlur', group = 'graphics', type = 'toggle', default = true,
        label = { pt = 'Motion blur', en = 'Motion blur' },
        desc  = { pt = 'Desfoque de movimento do jogador. Desligar ajuda a clareza.',
                  en = 'Player motion blur. Turning it off helps clarity.' },
        impact = 1, visual = 1,
    },
    {
        id = 'screenBlur', group = 'graphics', type = 'toggle', default = true,
        label = { pt = 'Desfoque de ecra', en = 'Screen blur' },
        desc  = { pt = 'Efeito de desfoque em transicoes e menus.',
                  en = 'Blur effect on transitions and menus.' },
        impact = 1, visual = 1,
    },
    {
        id = 'filmGrain', group = 'graphics', type = 'toggle', default = true,
        label = { pt = 'Grao de filme', en = 'Film grain' },
        desc  = { pt = 'Ruido cinematografico aplicado por cima da imagem.',
                  en = 'Cinematic noise applied over the image.' },
        impact = 1, visual = 1,
    },

    {
        id = 'entityLod', group = 'graphics', type = 'range', default = 1.0,
        min = 0.0, max = 1.0, step = 0.05, scale = 100, unit = '%',
        label = { pt = 'LOD de peds e veiculos', en = 'Ped and vehicle LOD' },
        desc  = { pt = 'Forca cada ped e cada carro a passar mais cedo para o modelo simplificado. A escala de LOD manda no mundo; esta manda em quem se mexe nele.',
                  en = 'Forces every ped and car to switch to its simplified model sooner. LOD scale rules the world; this one rules what moves in it.' },
        impact = 3, visual = 2,
    },

    -- ------------------------------------------------------------- ILUMINACAO
    {
        id = 'artificialLights', group = 'lighting', type = 'toggle', default = true,
        label = { pt = 'Luzes da cidade', en = 'City lights' },
        desc  = { pt = 'Candeeiros e luzes de edificios. Ganho enorme a noite, mas fica escuro.',
                  en = 'Street and building lights. Huge night gain, but it gets dark.' },
        impact = 3, visual = 3,
    },
    {
        --[[  NAO declarar `requires = 'artificialLights'` aqui.
              Esta opcao so faz alguma coisa quando o blackout esta LIGADO, ou
              seja quando 'artificialLights' esta DESLIGADA. Com o requires
              declarado, o motor caia no default (ligado) precisamente nos
              presets que pedem o contrario, e os carros ficavam com as luzes
              acesas numa cidade as escuras.                                ]]
        id = 'artificialLightsVeh', group = 'lighting', type = 'toggle', default = true,
        label = { pt = 'Luzes afectam veiculos', en = 'Lights affect vehicles' },
        desc  = { pt = 'So conta com as luzes da cidade desligadas: decide se o apagao tambem apanha os farois e as luzes dos carros.',
                  en = 'Only matters with city lights off: decides whether the blackout also catches car headlights and lights.' },
        impact = 1, visual = 1,
    },
    {
        id = 'vehicleDistantLights', group = 'lighting', type = 'toggle', default = true,
        label = { pt = 'Luzes distantes de veiculos', en = 'Distant vehicle lights' },
        desc  = { pt = 'Farois de transito ao longe. Barato de desligar, quase invisivel.',
                  en = 'Far-away traffic headlights. Cheap to disable, barely noticeable.' },
        impact = 2, visual = 1,
    },
    {
        id = 'distantSirens', group = 'lighting', type = 'toggle', default = false,
        label = { pt = 'Sirenes distantes', en = 'Distant sirens' },
        desc  = { pt = 'Luzes e som de policia ao longe.',
                  en = 'Distant police lights and sound.' },
        impact = 1, visual = 0,
    },

    -- -------------------------------------------------------------- POPULACAO
    {
        id = 'pedDensity', group = 'population', type = 'range', default = 1.0,
        min = 0.0, max = 1.0, step = 0.05, scale = 100, unit = '%',
        label = { pt = 'Densidade de peds', en = 'Ped density' },
        desc  = { pt = 'Quantidade de pedestres NPC. Nao afecta jogadores nem NPCs de scripts.',
                  en = 'Amount of NPC pedestrians. Does not affect players or scripted NPCs.' },
        impact = 3, visual = 2,
    },
    {
        id = 'vehicleDensity', group = 'population', type = 'range', default = 1.0,
        min = 0.0, max = 1.0, step = 0.05, scale = 100, unit = '%',
        label = { pt = 'Densidade de transito', en = 'Traffic density' },
        desc  = { pt = 'Veiculos NPC a circular. Nao afecta veiculos de jogadores.',
                  en = 'NPC vehicles driving around. Does not affect player vehicles.' },
        impact = 3, visual = 2,
    },
    {
        id = 'parkedDensity', group = 'population', type = 'range', default = 1.0,
        min = 0.0, max = 1.0, step = 0.05, scale = 100, unit = '%',
        label = { pt = 'Veiculos estacionados', en = 'Parked vehicles' },
        desc  = { pt = 'Carros parados nas ruas. Baixar isto liberta muita memoria.',
                  en = 'Cars parked on the streets. Lowering this frees a lot of memory.' },
        impact = 2, visual = 2,
    },
    {
        id = 'randomVehDensity', group = 'population', type = 'range', default = 1.0,
        min = 0.0, max = 1.0, step = 0.05, scale = 100, unit = '%',
        label = { pt = 'Veiculos aleatorios', en = 'Random vehicles' },
        desc  = { pt = 'Spawns aleatorios fora das rotas normais de transito.',
                  en = 'Random spawns outside normal traffic routes.' },
        impact = 2, visual = 1,
    },
    {
        id = 'scenarioDensity', group = 'population', type = 'range', default = 1.0,
        min = 0.0, max = 1.0, step = 0.05, scale = 100, unit = '%',
        label = { pt = 'Peds de cenario', en = 'Scenario peds' },
        desc  = { pt = 'NPCs em animacoes fixas (bancos, paragens, a fumar...).',
                  en = 'NPCs in fixed animations (benches, bus stops, smoking...).' },
        impact = 2, visual = 2,
    },
    {
        id = 'ambientVehRange', group = 'population', type = 'range', default = 1.0,
        min = 0.0, max = 1.0, step = 0.05, scale = 100, unit = '%',
        label = { pt = 'Alcance do transito', en = 'Traffic range' },
        desc  = { pt = 'A que distancia o transito ambiente continua a existir.',
                  en = 'How far ambient traffic keeps existing.' },
        impact = 2, visual = 1,
    },
    {
        id = 'ambientPedRange', group = 'population', type = 'range', default = 1.0,
        min = 0.0, max = 1.0, step = 0.05, scale = 100, unit = '%',
        label = { pt = 'Alcance dos peds', en = 'Ped range' },
        desc  = { pt = 'A que distancia os peds ambiente continuam a existir. E o par do alcance do transito, e vale tanto como ele numa rua movimentada.',
                  en = 'How far ambient peds keep existing. The counterpart of traffic range, and worth as much on a busy street.' },
        impact = 2, visual = 2,
    },
    {
        id = 'distantCars', group = 'population', type = 'toggle', default = true,
        label = { pt = 'Transito ao longe', en = 'Distant traffic' },
        desc  = { pt = 'Os carros simplificados que preenchem autoestradas e pontes ao fundo. Desligar quase nao se ve e alivia bastante as vistas largas.',
                  en = 'The simplified cars that fill motorways and bridges in the distance. Turning it off is barely visible and clears up wide views.' },
        impact = 2, visual = 1,
    },
    {
        id = 'randomCops', group = 'population', type = 'toggle', default = true,
        label = { pt = 'Policia NPC', en = 'NPC police' },
        desc  = { pt = 'Spawn automatico de policia. A maioria dos servidores RP desliga isto.',
                  en = 'Automatic police spawns. Most RP servers disable this.' },
        impact = 2, visual = 1,
    },
    {
        id = 'garbageTrucks', group = 'population', type = 'toggle', default = true,
        label = { pt = 'Camioes do lixo', en = 'Garbage trucks' },
        desc  = { pt = 'Camioes do lixo com equipa de NPCs (muito caros).',
                  en = 'Garbage trucks with NPC crew (very expensive).' },
        impact = 1, visual = 0,
    },
    {
        id = 'randomBoats', group = 'population', type = 'toggle', default = true,
        label = { pt = 'Barcos aleatorios', en = 'Random boats' },
        desc  = { pt = 'Barcos NPC na agua.',
                  en = 'NPC boats on the water.' },
        impact = 1, visual = 0,
    },
    {
        id = 'randomTrains', group = 'population', type = 'toggle', default = true,
        label = { pt = 'Comboios', en = 'Trains' },
        desc  = { pt = 'Comboios e metro a circular.',
                  en = 'Trains and metro running.' },
        impact = 1, visual = 1,
    },
    {
        id = 'lowPriorityVehGens', group = 'population', type = 'toggle', default = true,
        label = { pt = 'Geradores de baixa prioridade', en = 'Low-priority generators' },
        desc  = { pt = 'Pontos de spawn secundarios de veiculos. Seguro desligar.',
                  en = 'Secondary vehicle spawn points. Safe to disable.' },
        impact = 2, visual = 1,
    },
    {
        id = 'dispatchServices', group = 'population', type = 'toggle', default = true,
        label = { pt = 'Servicos de emergencia', en = 'Dispatch services' },
        desc  = { pt = 'Policia, ambulancia e bombeiros automaticos do GTA.',
                  en = "GTA's automatic police, ambulance and fire dispatch." },
        impact = 2, visual = 1,
    },
    {
        id = 'blockPedSpawns', group = 'population', type = 'toggle', default = false,
        label = { pt = 'Proibir spawn de peds', en = 'Block ped spawns' },
        desc  = { pt = 'Marca a zona a volta do jogador como area onde o motor nao pode criar pedestres. Vai mais longe do que por a densidade a zero, porque nem sequer chega a tentar.',
                  en = 'Marks the area around the player as one where the engine may not create pedestrians. Goes further than zero density, because it never even tries.' },
        impact = 3, visual = 3,
    },
    {
        id = 'blockParkedSpawns', group = 'population', type = 'toggle', default = false,
        label = { pt = 'Proibir carros estacionados', en = 'Block parked cars' },
        desc  = { pt = 'Poe a zero o numero de veiculos estacionados que o motor pode gerar. As ruas ficam sem transito parado.',
                  en = 'Sets the number of parked vehicles the engine may generate to zero. Streets are left with no stationary traffic.' },
        impact = 2, visual = 2,
    },

    -- ------------------------------------------------------- MOTOR DE RENDER
    --[[  Estas cinco entradas nao chamam natives de jogabilidade: escrevem
          directamente nos parametros de render do motor (o visualsettings.dat
          do GTA), atraves de SET_VISUAL_SETTING_FLOAT.

          Sao MULTIPLICADORES do valor de fabrica, nunca valores absolutos: o
          script le o original com GET_VISUAL_SETTING_FLOAT no arranque,
          multiplica-o, e repoe o original exacto quando a definicao volta a
          100%. E' por isso que nao ha aqui numeros magicos — e nao ha maneira
          de deixar o motor num estado que o script nao saiba desfazer.

          Nota sobre o que NAO e' possivel: as definicoes graficas do menu do
          jogo (textura, sombras, MSAA, agua) nao tem native de escrita. Um
          recurso consegue le-las com GET_PROFILE_SETTING e mais nada. Quem
          promete mudar isso in-game esta a mudar outra coisa qualquer.     ]]
    {
        id = 'renderLodLights', group = 'render', type = 'range', default = 1.0,
        min = 0.0, max = 1.0, step = 0.05, scale = 100, unit = '%',
        label = { pt = 'Alcance das luzes da cidade', en = 'City light range' },
        desc  = { pt = 'A que distancia as luzes de rua e de edificios continuam a ser desenhadas. De noite em Los Santos e o maior ganho isolado deste grupo.',
                  en = 'How far street and building lights keep being drawn. At night in Los Santos this is the single biggest gain in this group.' },
        impact = 3, visual = 2,
    },
    {
        id = 'renderCoronas', group = 'render', type = 'range', default = 1.0,
        min = 0.0, max = 1.0, step = 0.05, scale = 100, unit = '%',
        label = { pt = 'Halos das luzes', en = 'Light coronas' },
        desc  = { pt = 'O brilho redondo a volta de cada lampada e farol. A zero as luzes ficam pontos secos, sem halo.',
                  en = 'The round glow around every lamp and headlight. At zero, lights become dry points with no halo.' },
        impact = 2, visual = 2,
    },
    {
        id = 'renderDistantLights', group = 'render', type = 'range', default = 1.0,
        min = 0.0, max = 1.0, step = 0.05, scale = 100, unit = '%',
        label = { pt = 'Luzes do horizonte', en = 'Horizon lights' },
        desc  = { pt = 'Os pontos de luz que povoam a cidade e as auto-estradas ao fundo. Complementa "Transito ao longe", que so trata dos carros.',
                  en = 'The specks of light filling the city and motorways in the distance. Complements "Distant traffic", which only covers the cars.' },
        impact = 2, visual = 1,
    },
    {
        id = 'renderPuddles', group = 'render', type = 'range', default = 1.0,
        min = 0.0, max = 1.0, step = 0.05, scale = 100, unit = '%',
        label = { pt = 'Pocas e reflexos molhados', en = 'Puddles and wet reflections' },
        desc  = { pt = 'Pocas de agua reflectoras depois da chuva. Custam pouco com tempo seco e bastante com tempo humido.',
                  en = 'Reflective puddles after rain. Cheap in dry weather, expensive in wet.' },
        impact = 2, visual = 2,
    },
    {
        id = 'renderPostFx', group = 'render', type = 'range', default = 1.0,
        min = 0.0, max = 1.0, step = 0.05, scale = 100, unit = '%',
        label = { pt = 'Pos-processamento', en = 'Post-processing' },
        desc  = { pt = 'Bloom e desfoque de profundidade. A zero a imagem fica mais crua e mais nitida, e a placa grafica agradece.',
                  en = 'Bloom and depth-of-field blur. At zero the image gets rawer and sharper, and the GPU thanks you.' },
        impact = 2, visual = 2,
    },
    {
        id = 'renderVehicleLights', group = 'render', type = 'range', default = 1.0,
        -- O chao e 15% e nao 0%: as distancias de desvanecimento das luzes
        -- dos carros tambem apanham o carro do proprio jogador. A 0% os
        -- farois dele apagavam-se; a 15% ficam, e o resto da estrada nao.
        min = 0.15, max = 1.0, step = 0.05, scale = 100, unit = '%',
        label = { pt = 'Luzes dos veiculos', en = 'Vehicle lights' },
        desc  = { pt = 'Os feixes de luz visiveis dos farois e o alcance a que as luzes dos outros carros sao desenhadas. De noite, com transito, e dos efeitos mais caros que ha.',
                  en = 'The visible headlight beams and how far other cars\' lights are drawn. At night with traffic, one of the most expensive effects there is.' },
        impact = 3, visual = 2,
    },

    -- ---------------------------------------------------------------- EFEITOS
    {
        id = 'forceClearWeather', group = 'effects', type = 'toggle', default = false,
        label = { pt = 'Forcar tempo limpo', en = 'Force clear weather' },
        desc  = { pt = 'ATENCAO: so funciona se o servidor nao sincronizar o tempo a forca.',
                  en = 'WARNING: only works if the server does not force-sync weather.' },
        impact = 2, visual = 3,
    },
    {
        id = 'killRain', group = 'effects', type = 'toggle', default = false,
        label = { pt = 'Remover chuva', en = 'Remove rain' },
        desc  = { pt = 'Poe o nivel de chuva a zero no cliente.',
                  en = 'Sets client rain level to zero.' },
        impact = 2, visual = 2,
    },
    {
        id = 'killWind', group = 'effects', type = 'toggle', default = false,
        label = { pt = 'Remover vento', en = 'Remove wind' },
        desc  = { pt = 'Para a simulacao de vento (vegetacao e panos).',
                  en = 'Stops wind simulation (foliage and cloth).' },
        impact = 1, visual = 1,
    },
    {
        id = 'particleCleanup', group = 'effects', type = 'toggle', default = false,
        label = { pt = 'Limpar particulas', en = 'Clear particles' },
        desc  = { pt = 'Remove periodicamente particulas a volta do jogador (fumo, fogo, faiscas).',
                  en = 'Periodically removes particles around the player (smoke, fire, sparks).' },
        impact = 2, visual = 2,
    },
    {
        id = 'particleRadius', group = 'effects', type = 'range', default = 200.0,
        min = 25.0, max = 500.0, step = 25.0, unit = 'm', requires = 'particleCleanup',
        label = { pt = 'Raio de limpeza de particulas', en = 'Particle cleanup radius' },
        desc  = { pt = 'Raio, em metros, onde as particulas sao removidas.',
                  en = 'Radius, in metres, where particles are removed.' },
        impact = 1, visual = 1,
    },

    -- ---------------------------------------------------------------- LIMPEZA
    {
        id = 'cleanupEnabled', group = 'cleanup', type = 'toggle', default = false,
        label = { pt = 'Limpeza automatica', en = 'Automatic cleanup' },
        desc  = { pt = 'Remove periodicamente lixo do mundo a volta do jogador.',
                  en = 'Periodically removes world clutter around the player.' },
        impact = 2, visual = 1,
    },
    {
        id = 'cleanupInterval', group = 'cleanup', type = 'range', default = 120,
        min = 15, max = 600, step = 15, unit = 's', requires = 'cleanupEnabled',
        label = { pt = 'Intervalo de limpeza', en = 'Cleanup interval' },
        desc  = { pt = 'De quantos em quantos segundos a limpeza corre.',
                  en = 'How often, in seconds, cleanup runs.' },
        impact = 1, visual = 0,
    },
    {
        id = 'cleanupRadius', group = 'cleanup', type = 'range', default = 400,
        min = 50, max = 1000, step = 50, unit = 'm', requires = 'cleanupEnabled',
        label = { pt = 'Raio de limpeza', en = 'Cleanup radius' },
        desc  = { pt = 'Raio a volta do jogador onde a limpeza actua.',
                  en = 'Radius around the player where cleanup acts.' },
        impact = 1, visual = 0,
    },
    {
        id = 'clearProjectiles', group = 'cleanup', type = 'toggle', default = false,
        requires = 'cleanupEnabled',
        label = { pt = 'Limpar projecteis', en = 'Clear projectiles' },
        desc  = { pt = 'Remove balas, granadas e rockets em voo. Totalmente seguro.',
                  en = 'Removes bullets, grenades and rockets in flight. Completely safe.' },
        impact = 1, visual = 0,
    },
    {
        id = 'clearGlass', group = 'cleanup', type = 'toggle', default = false,
        requires = 'cleanupEnabled',
        label = { pt = 'Limpar vidros partidos', en = 'Clear broken glass' },
        desc  = { pt = 'Restaura vidros partidos. Seguro.',
                  en = 'Restores broken glass. Safe.' },
        impact = 1, visual = 1,
    },
    {
        id = 'clearDecals', group = 'cleanup', type = 'toggle', default = false,
        requires = 'cleanupEnabled',
        label = { pt = 'Limpar decals', en = 'Clear decals' },
        desc  = { pt = 'Remove sangue, buracos de bala e sujidade acumulada.',
                  en = 'Removes blood, bullet holes and accumulated dirt.' },
        impact = 1, visual = 1,
    },
    {
        id = 'clearObjects', group = 'cleanup', type = 'toggle', default = false,
        requires = 'cleanupEnabled',
        label = { pt = 'Limpar objectos soltos', en = 'Clear loose objects' },
        desc  = { pt = 'So remove objectos ambiente. Objectos de missao/scripts sao ignorados.',
                  en = 'Only removes ambient objects. Mission/script objects are skipped.' },
        impact = 2, visual = 1,
    },
    {
        id = 'clearDeadPeds', group = 'cleanup', type = 'toggle', default = false,
        requires = 'cleanupEnabled',
        label = { pt = 'Limpar peds mortos', en = 'Clear dead peds' },
        desc  = { pt = 'So NPCs ambiente ja mortos. Jogadores e NPCs de script nunca sao tocados.',
                  en = 'Only already-dead ambient NPCs. Players and script NPCs are never touched.' },
        impact = 2, visual = 1,
    },
    {
        id = 'clearEmptyVehicles', group = 'cleanup', type = 'toggle', default = false,
        requires = 'cleanupEnabled',
        label = { pt = 'Limpar veiculos vazios', en = 'Clear empty vehicles' },
        desc  = { pt = 'So veiculos ambiente, vazios, sem dono e nao-persistentes.',
                  en = 'Only ambient, empty, unowned, non-persistent vehicles.' },
        impact = 3, visual = 2,
    },

    -- -------------------------------------------------------------------- HUD
    {
        id = 'hudEnabled', group = 'hud', type = 'toggle', default = false,
        label = { pt = 'Mostrar HUD', en = 'Show HUD' },
        desc  = { pt = 'Contador flutuante sempre visivel no ecra.',
                  en = 'Always-visible floating counter on screen.' },
        impact = 0, visual = 0,
    },
    {
        id = 'hudPosition', group = 'hud', type = 'select', default = 'topright',
        requires = 'hudEnabled',
        label = { pt = 'Posicao', en = 'Position' },
        desc  = { pt = 'Canto do ecra onde o HUD aparece.',
                  en = 'Screen corner where the HUD appears.' },
        options = {
            { value = 'topleft',     label = { pt = 'Superior esquerdo', en = 'Top left'     } },
            { value = 'topright',    label = { pt = 'Superior direito',  en = 'Top right'    } },
            { value = 'bottomleft',  label = { pt = 'Inferior esquerdo', en = 'Bottom left'  } },
            { value = 'bottomright', label = { pt = 'Inferior direito',  en = 'Bottom right' } },
        },
    },
    {
        id = 'hudScale', group = 'hud', type = 'range', default = 1.0,
        min = 0.6, max = 1.8, step = 0.1, scale = 100, unit = '%', requires = 'hudEnabled',
        label = { pt = 'Tamanho', en = 'Size' },
        desc  = { pt = 'Escala do HUD.', en = 'HUD scale.' },
    },
    {
        id = 'hudOpacity', group = 'hud', type = 'range', default = 0.85,
        min = 0.1, max = 1.0, step = 0.05, scale = 100, unit = '%', requires = 'hudEnabled',
        label = { pt = 'Opacidade', en = 'Opacity' },
        desc  = { pt = 'Transparencia do fundo do HUD.', en = 'HUD background transparency.' },
    },
    {
        id = 'hudShowFrametime', group = 'hud', type = 'toggle', default = true,
        requires = 'hudEnabled',
        label = { pt = 'Mostrar frametime', en = 'Show frametime' },
        desc  = { pt = 'Tempo por frame em milissegundos.', en = 'Per-frame time in milliseconds.' },
    },
    {
        id = 'hudShowLows', group = 'hud', type = 'toggle', default = true,
        requires = 'hudEnabled',
        label = { pt = 'Mostrar 1% low', en = 'Show 1% low' },
        desc  = { pt = 'O indicador real de fluidez do jogo.', en = 'The real smoothness indicator.' },
    },
    {
        id = 'hudShowPing', group = 'hud', type = 'toggle', default = false,
        requires = 'hudEnabled',
        label = { pt = 'Mostrar ping', en = 'Show ping' },
        desc  = { pt = 'Latencia ao servidor.', en = 'Latency to the server.' },
    },
    {
        id = 'hudShowGraph', group = 'hud', type = 'toggle', default = true,
        requires = 'hudEnabled',
        label = { pt = 'Mostrar mini-grafico', en = 'Show mini graph' },
        desc  = { pt = 'Sparkline dos ultimos segundos.', en = 'Sparkline of the last few seconds.' },
    },
    {
        id = 'hudShowEntities', group = 'hud', type = 'toggle', default = false,
        requires = 'hudEnabled',
        label = { pt = 'Mostrar entidades', en = 'Show entities' },
        desc  = { pt = 'Contagem de peds / veiculos / objectos.', en = 'Ped / vehicle / object counts.' },
    },

    -- -------------------------------------------------------------- INTERFACE
    {
        id = 'uiAccent', group = 'interface', type = 'color', default = '#22C7E8',
        label = { pt = 'Cor de destaque', en = 'Accent colour' },
        desc  = { pt = 'Cor principal do painel e do HUD.', en = 'Main panel and HUD colour.' },
        swatches = { '#FF2E43', '#FF7A18', '#FFC531', '#31E07A', '#22C7E8', '#5B8CFF', '#A855F7', '#FF4FA3' },
    },
    {
        --[[  ESCALA EM 2K E 4K
              ----------------
              O painel foi desenhado numa caixa de 1300x780 pontos. Num ecra
              1080p isso enche a maior parte do ecra; em 1440p ocupa metade e
              em 4K pouco mais de um terco — o desenho nao encolhe, mas o ecra
              cresce a volta dele, e o resultado le-se como letra miuda.

              A adaptacao automatica devolve a MESMA fraccao de ecra em
              qualquer resolucao, com a curva descrita em html/js/util.js. O
              controlo abaixo e o ajuste fino por cima disso, para quem prefere
              o painel mais compacto ou maior do que a conta certa.        ]]
        id = 'uiAutoScale', group = 'interface', type = 'toggle', default = true,
        label = { pt = 'Adaptar a interface a resolucao', en = 'Adapt interface to resolution' },
        desc  = { pt = 'Aumenta o painel e o HUD em ecras 2K e 4K, para ocuparem a mesma parte do ecra que ocupam em 1080p. Desligado, o painel fica no tamanho original em qualquer resolucao.',
                  en = 'Grows the panel and HUD on 2K and 4K screens so they take up the same share of the screen as on 1080p. Off, the panel keeps its original size at any resolution.' },
    },
    {
        id = 'uiScale', group = 'interface', type = 'range', default = 1.0,
        min = 0.75, max = 1.50, step = 0.05, scale = 100, unit = '%',
        label = { pt = 'Escala da interface', en = 'Interface scale' },
        desc  = { pt = 'Ajuste fino do tamanho, aplicado por cima da adaptacao automatica. O painel nunca passa das bordas do ecra, por muito que subas este valor.',
                  en = 'Fine size adjustment, applied on top of the automatic adaptation. The panel never runs past the screen edges, however high you set this.' },
    },
    {
        id = 'uiBlur', group = 'interface', type = 'toggle', default = true,
        label = { pt = 'Vidro liquido (blur)', en = 'Liquid glass (blur)' },
        desc  = { pt = 'Desfoca o jogo por tras do painel e activa o vidro. Desliga se a interface te tirar FPS.',
                  en = 'Blurs the game behind the panel and enables the glass. Turn off if the interface costs you FPS.' },
    },
    {
        id = 'uiBackdrop', group = 'interface', type = 'range', default = 0.32,
        min = 0.0, max = 0.85, step = 0.05, scale = 100, unit = '%',
        label = { pt = 'Escurecer o fundo', en = 'Background dim' },
        desc  = { pt = 'Quanto o jogo e escurecido por tras do painel. 0% deixa o jogo totalmente visivel; sobe se estiveres de dia e o texto custar a ler.',
                  en = 'How much the game is dimmed behind the panel. 0% leaves the game fully visible; raise it in daylight if text becomes hard to read.' },
    },
    {
        id = 'ui3d', group = 'interface', type = 'toggle', default = true,
        label = { pt = 'Paineis laterais em 3D', en = '3D side panels' },
        desc  = { pt = 'Inclina a barra lateral e a coluna direita na direccao do centro. Desliga se o texto te parecer menos nitido — em 3D quem desenha o texto e a placa grafica.',
                  en = 'Angles the sidebar and right column toward the centre. Turn it off if text looks less sharp — in 3D the GPU rasterises the text.' },
    },
    {
        id = 'uiAnimations', group = 'interface', type = 'toggle', default = true,
        label = { pt = 'Animacoes', en = 'Animations' },
        desc  = { pt = 'Transicoes e movimento na interface.', en = 'Interface transitions and motion.' },
    },
    {
        id = 'uiFloat', group = 'interface', type = 'toggle', default = true,
        requires = 'uiAnimations',
        label = { pt = 'Menu flutuante', en = 'Floating menu' },
        desc  = { pt = 'O painel sobe e desce muito lentamente, como se estivesse suspenso. Desligado, fica completamente estatico.',
                  en = 'The panel drifts up and down very slowly, as if suspended. Off, it stays completely static.' },
    },
    {
        id = 'uiSounds', group = 'interface', type = 'toggle', default = true,
        label = { pt = 'Sons', en = 'Sounds' },
        desc  = { pt = 'Efeitos sonoros ao abrir, fechar e clicar.', en = 'Open, close and click sounds.' },
    },
    {
        id = 'uiChartGlow', group = 'interface', type = 'range', default = 0.55,
        min = 0.0, max = 1.0, step = 0.05, scale = 100, unit = '%',
        label = { pt = 'Brilho dos graficos', en = 'Chart glow' },
        desc  = { pt = 'Intensidade do halo da linha nos graficos. A 0% fica so a linha, sem luz. Nada a ver com "Suavizar", que muda a FORMA da linha e nao o brilho.',
                  en = 'Halo intensity of the chart line. At 0% only the line remains, with no light. Unrelated to "Smooth", which changes the line SHAPE, not its glow.' },
    },
    {
        id = 'uiChartRange', group = 'interface', type = 'select', default = '1m',
        label = { pt = 'Intervalo do grafico', en = 'Chart range' },
        desc  = { pt = 'Janela temporal por defeito do grafico principal.',
                  en = 'Default time window of the main chart.' },
        options = {
            { value = '1m',  label = { pt = '1 minuto',   en = '1 minute'   } },
            { value = '5m',  label = { pt = '5 minutos',  en = '5 minutes'  } },
            { value = '15m', label = { pt = '15 minutos', en = '15 minutes' } },
            { value = '1h',  label = { pt = '1 hora',     en = '1 hour'     } },
        },
    },
    {
        id = 'uiLocale', group = 'interface', type = 'select', default = 'en', -- overridden at runtime by Config.Locale
        label = { pt = 'Idioma', en = 'Language' },
        desc  = { pt = 'Idioma da interface e das notificacoes.', en = 'Interface and notification language.' },
        --- Os nomes ficam sempre no proprio idioma (endonimos). Um jogador
        --- turco procura "Turkce", nao "Turco" nem "Turkish" — traduzir os
        --- nomes das linguas so torna a lista dificil de percorrer para quem
        --- nao entende o idioma em que ela esta.
        options = {
            { value = 'pt', label = { pt = 'Portugues',  en = 'Portugues'  } },
            { value = 'en', label = { pt = 'English',    en = 'English'    } },
            { value = 'es', label = { pt = 'Espanol',    en = 'Espanol'    } },
            { value = 'fr', label = { pt = 'Francais',   en = 'Francais'   } },
            { value = 'de', label = { pt = 'Deutsch',    en = 'Deutsch'    } },
            { value = 'pl', label = { pt = 'Polski',     en = 'Polski'     } },
            { value = 'nl', label = { pt = 'Nederlands', en = 'Nederlands' } },
            { value = 'it', label = { pt = 'Italiano',   en = 'Italiano'   } },
            { value = 'tr', label = { pt = 'Turkce',     en = 'Turkce'     } },
            { value = 'ru', label = { pt = 'Russkiy',    en = 'Russkiy'    } },
            { value = 'cs', label = { pt = 'Cestina',    en = 'Cestina'    } },
            { value = 'sv', label = { pt = 'Svenska',    en = 'Svenska'    } },
        },
    },
    {
        id = 'uiShowEstimates', group = 'interface', type = 'toggle', default = true,
        label = { pt = 'Mostrar estimativas', en = 'Show estimates' },
        desc  = { pt = 'Aneis de CPU/GPU/RAM/VRAM. Sao heuristicas, nao leituras de hardware.',
                  en = 'CPU/GPU/RAM/VRAM rings. These are heuristics, not hardware readings.' },
    },

    -- -------------------------------------------------------------- AUTOMACAO
    {
        id = 'autoBoost', group = 'automation', type = 'toggle', default = false,
        label = { pt = 'Boost automatico', en = 'Automatic boost' },
        desc  = { pt = 'Sobe o preset sozinho quando o FPS cai, e desce quando recupera.',
                  en = 'Raises the preset when FPS drops and lowers it when it recovers.' },
        impact = 3, visual = 2,
    },
    {
        id = 'autoBoostFloor', group = 'automation', type = 'range', default = 45,
        min = 10, max = 120, step = 5, unit = ' FPS', requires = 'autoBoost',
        label = { pt = 'Subir preset abaixo de', en = 'Raise preset below' },
        desc  = { pt = 'FPS medio (10s) que dispara um preset mais agressivo.',
                  en = 'Average FPS (10s) that triggers a more aggressive preset.' },
    },
    {
        id = 'autoBoostCeiling', group = 'automation', type = 'range', default = 90,
        min = 20, max = 240, step = 5, unit = ' FPS', requires = 'autoBoost',
        label = { pt = 'Descer preset acima de', en = 'Lower preset above' },
        desc  = { pt = 'FPS medio (10s) que permite voltar a um preset mais bonito.',
                  en = 'Average FPS (10s) that allows returning to a prettier preset.' },
    },
    {
        id = 'autoBoostCooldown', group = 'automation', type = 'range', default = 30,
        min = 10, max = 300, step = 10, unit = 's', requires = 'autoBoost',
        label = { pt = 'Espera entre mudancas', en = 'Cooldown between changes' },
        desc  = { pt = 'Evita que o preset fique a saltar de um lado para o outro.',
                  en = 'Prevents the preset from flip-flopping.' },
    },
    {
        id = 'alertLowFps', group = 'automation', type = 'toggle', default = false,
        label = { pt = 'Alerta de FPS baixo', en = 'Low FPS alert' },
        desc  = { pt = 'Notifica quando o FPS fica abaixo do limite durante algum tempo.',
                  en = 'Notifies when FPS stays below the threshold for a while.' },
    },
    {
        id = 'alertThreshold', group = 'automation', type = 'range', default = 30,
        min = 10, max = 120, step = 5, unit = ' FPS', requires = 'alertLowFps',
        label = { pt = 'Limite do alerta', en = 'Alert threshold' },
        desc  = { pt = 'Abaixo deste valor recebes o aviso.', en = 'Below this value you get the warning.' },
    },

    -- --------------------------------------------------------- CAMADA ADAPTATIVA
    --[[  Os presets cortam onde se ve. Estas tres opcoes cortam onde NAO se
          ve: com o menu de pausa aberto, com o jogador ausente, e dentro de
          interiores — momentos em que baixar o render ou a populacao nao
          custa nada ao olho. Sao uma camada temporaria por cima do preset;
          quando a situacao acaba, o preset volta tal e qual estava.

          Nada disto e guardado no KVP nem aparece nas definicoes do jogador:
          a camada existe so em memoria e desaparece com a situacao.       ]]
    {
        id = 'pauseSaver', group = 'automation', type = 'toggle', default = true,
        label = { pt = 'Poupar no menu de pausa', en = 'Save in the pause menu' },
        desc  = { pt = 'Com o menu de pausa aberto o jogo continua a desenhar o mundo atras dele. Baixa sombras, LOD e render enquanto la estas; ao fechar, volta tudo.',
                  en = 'With the pause menu open the game keeps drawing the world behind it. Lowers shadows, LOD and render while you are there; closing it brings everything back.' },
        impact = 2, visual = 0,
    },
    {
        id = 'afkSaver', group = 'automation', type = 'toggle', default = false,
        label = { pt = 'Modo ausente', en = 'Away mode' },
        desc  = { pt = 'Sem movimento, sem camara e sem teclas durante uns minutos, o jogo passa ao minimo: mundo vazio e render no chao. Ao primeiro toque volta ao teu preset.',
                  en = 'No movement, no camera and no keys for a few minutes, and the game drops to its floor: empty world, render at minimum. The first input brings your preset back.' },
        impact = 3, visual = 0,
    },
    {
        id = 'afkMinutes', group = 'automation', type = 'range', default = 5,
        min = 1, max = 15, step = 1, unit = ' min', requires = 'afkSaver',
        label = { pt = 'Minutos ate ausente', en = 'Minutes until away' },
        desc  = { pt = 'Quanto tempo parado ate o modo ausente entrar.',
                  en = 'How long idle before away mode kicks in.' },
        impact = 0, visual = 0,
    },
    {
        id = 'interiorSaver', group = 'automation', type = 'toggle', default = false,
        label = { pt = 'Aliviar em interiores', en = 'Ease off indoors' },
        desc  = { pt = 'Dentro de um interior, o transito e os peds la fora continuam a ser simulados sem se verem. Reduz a populacao exterior enquanto estas dentro. Nota-se nas janelas de apartamentos.',
                  en = 'Inside an interior, the traffic and peds outside keep being simulated unseen. Reduces outside population while you are in. Noticeable through apartment windows.' },
        impact = 2, visual = 1,
    },
}

-- ============================================================================
--  7A. CAMADA ADAPTATIVA
-- ============================================================================
--[[  O que cada situacao poe por cima do preset activo.

      REGRA: cada valor aqui so conta se for MAIS agressivo do que o que o
      preset ja tem. Um jogador em Batata nao ganha nada com isto (ja esta no
      chao); um em Equilibrado ganha o que falta ate ao chao enquanto a
      situacao durar. A comparacao e feita por definicao, em client/adaptive.lua.

      Por isso so entram aqui definicoes em que "mais baixo" ou "desligado"
      significa mais agressivo: densidades, alcances, LOD, sombras, render.
      Nunca as de limpeza nem as que se ligam para poupar (blockPedSpawns e
      companhia), que teriam a semantica ao contrario.                     ]]
Config.Adaptive = {
    --- Menu de pausa: so render. O mundo fica intacto — ao fechar o menu a
    --- rua esta exactamente como estava, e nao vazia a repovoar-se.
    pause = {
        shadowMode          = 'off',
        shadowDistance      = 0.0,
        lodScale            = 0.30,
        entityLod           = 0.20,
        oceanScaler         = 0.0,
        renderLodLights     = 0.10,
        renderCoronas       = 0.10,
        renderDistantLights = 0.0,
        renderPuddles       = 0.0,
        renderPostFx        = 0.10,
        renderVehicleLights = 0.15,
    },

    --- Ausente: o mesmo que a pausa MAIS a populacao a zero. O jogador nao
    --- esta a olhar; quando voltar, a rua enche-se em poucos segundos.
    afk = {
        shadowMode          = 'off',
        shadowDistance      = 0.0,
        lodScale            = 0.20,
        entityLod           = 0.0,
        oceanScaler         = 0.0,
        renderLodLights     = 0.0,
        renderCoronas       = 0.0,
        renderDistantLights = 0.0,
        renderPuddles       = 0.0,
        renderPostFx        = 0.0,
        renderVehicleLights = 0.15,
        pedDensity          = 0.0,
        vehicleDensity      = 0.0,
        parkedDensity       = 0.0,
        randomVehDensity    = 0.0,
        scenarioDensity     = 0.0,
        ambientVehRange     = 0.0,
        ambientPedRange     = 0.0,
        distantCars         = false,
    },

    --- Interiores: so a populacao exterior. Nao ha volta a dar as janelas —
    --- quem olhar la para fora ve menos transito — mas o que esta dentro do
    --- interior nao muda, e e para isso que o jogador esta a olhar.
    interior = {
        pedDensity          = 0.35,
        vehicleDensity      = 0.35,
        parkedDensity       = 0.35,
        randomVehDensity    = 0.35,
        scenarioDensity     = 0.35,
        ambientVehRange     = 0.25,
        ambientPedRange     = 0.25,
        distantCars         = false,
        renderDistantLights = 0.0,
    },

    --- Segundos dentro/fora de um interior antes de a camada mudar, para
    --- uma porta nao a ligar e desligar a cada passagem.
    interiorHysteresis = 3,

    --- Deslocamento (metros) e rotacao da camara (graus) a partir dos quais
    --- o jogador conta como activo. Abaixo disto e' ruido de animacao idle.
    afkMoveThreshold = 0.25,
    afkLookThreshold = 0.5,
}

-- ============================================================================
--  7B. SEGURANCA DA LIMPEZA
-- ============================================================================
--  A limpeza de entidades e a unica parte do script que APAGA coisas do mundo.
--  Estes limites existem para que ela nunca apague algo importante.

Config.CleanupSafety = {
    --- Distancia minima (metros) a que uma entidade tem de estar do jogador
    --- para poder ser removida. Impede que carros desaparecam a tua frente.
    minDistance = 45.0,

    --- Numero maximo de entidades removidas por passagem e por categoria.
    --- Impede que a propria limpeza cause um stutter.
    maxPerPass = 40,

    --- Modelos que NUNCA sao removidos, mesmo que passem todos os filtros.
    --- Aceita nomes ('adder') ou hashes. Poe aqui os veiculos e props do teu
    --- servidor que sao criados sem serem marcados como mission entity.
    --- Exemplo: protectedModels = { 'police', 'ambulance', 'firetruk' },
    protectedModels = {},
}

-- ============================================================================
--  8. PREVIEW (COMPARACAO ANTES/DEPOIS)
-- ============================================================================

Config.Preview = {
    --- Segundos a medir o estado ACTUAL antes de aplicar o preset a testar.
    baselineSeconds = 8,
    --- Segundos a medir depois de aplicar o preset.
    testSeconds = 8,
    --- Descarta os primeiros N ms apos aplicar, para o streaming assentar.
    settleMs = 1500,
    --- Fecha o painel durante o preview (a NUI custa FPS e falseia o teste).
    hidePanel = true,
    --- Reverte automaticamente para o estado anterior no fim do teste.
    autoRevert = true,
}

-- ============================================================================
--  9. NOTIFICACOES
-- ============================================================================

Config.Notify = {
    --- 'auto'   -> usa o do framework detectado (ESX.ShowNotification / QBCore Notify)
    --- 'native' -> notificacao do GTA
    --- 'chat'   -> mensagem no chat
    --- 'ui'     -> toast desenhado pela propria NUI (recomendado)
    --- 'none'   -> silencio
    type = 'ui',
    duration = 4000,
    title = 'UNDER STAR',
}

-- ============================================================================
--  9B. SONS DA INTERFACE
-- ============================================================================
--[[
    Os sons vem do proprio GTA, atraves de PlaySoundFrontend. Nao ha nenhum
    ficheiro de audio no resource, nada para transferir e nada para fazer
    stream — e tambem por isso que soam exactamente como o resto do jogo em
    vez de soarem a "site" colado por cima.

    Formato: { nomeDoSom, soundset }

    Se puseres um nome que nao existe, a native simplesmente nao toca nada:
    nao rebenta nem enche a consola de erros. Podes experimentar a vontade.

    Sons uteis do HUD_FRONTEND_DEFAULT_SOUNDSET:
      SELECT · BACK · CANCEL · YES · NO · ERROR · NAV_UP_DOWN
      HIGHLIGHT_NAV_UP_DOWN · FOCUSIN · FOCUSOUT

    O jogador pode desligar tudo em Definicoes > Interface > Sons.
]]

Config.Sounds = {
    open    = { 'SELECT',      'HUD_FRONTEND_DEFAULT_SOUNDSET' },
    close   = { 'BACK',        'HUD_FRONTEND_DEFAULT_SOUNDSET' },
    nav     = { 'NAV_UP_DOWN', 'HUD_FRONTEND_DEFAULT_SOUNDSET' },
    click   = { 'NAV_UP_DOWN', 'HUD_FRONTEND_DEFAULT_SOUNDSET' },
    toggle  = { 'SELECT',      'HUD_FRONTEND_DEFAULT_SOUNDSET' },
    success = { 'YES',         'HUD_FRONTEND_DEFAULT_SOUNDSET' },
    error   = { 'ERROR',       'HUD_FRONTEND_DEFAULT_SOUNDSET' },
}

-- ============================================================================
--  10. RESTRICOES DO SERVIDOR
-- ============================================================================

Config.Restrictions = {
    --- IDs de Config.Settings que os jogadores NAO podem alterar.
    --- Util se quiseres proibir, por exemplo, desligar as luzes da cidade.
    --- Exemplo: lockedSettings = { 'artificialLights', 'forceClearWeather' },
    lockedSettings = {},

    --- IDs de presets bloqueados para jogadores normais (admins passam sempre).
    --- Exemplo: lockedPresets = { 'extreme' },
    lockedPresets = {},

    --- Preset maximo permitido a jogadores normais. nil = sem limite.
    --- Exemplo: maxPreset = 'performance',
    maxPreset = nil,

    --- Se true, o servidor forca Config.DefaultPreset a cada entrada,
    --- ignorando o que o jogador tinha guardado.
    forceDefaultOnJoin = false,
}

-- ============================================================================
--  12. INTEGRACAO
-- ============================================================================

Config.Integration = {
    --- Desliga o painel quando o jogador esta morto/incapacitado.
    blockWhenDead = true,
    --- Desliga o painel dentro de veiculo em movimento (evita acidentes).
    blockWhileDriving = false,
    --- Nomes de eventos que, ao dispararem, fecham o painel (ex.: menus de outros scripts).
    closeOnEvents = {},
    --- Se outro resource ja mostra um contador de FPS, poe o nome aqui e o HUD
    --- deste script nao arranca ligado por defeito.
    conflictingHudResources = { 'fps-counter', 'ps-hud' },
}

