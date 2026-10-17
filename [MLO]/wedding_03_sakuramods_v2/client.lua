local L0_1, L1_1, L2_1, L3_1, L4_1, L5_1, L6_1, L7_1
function L0_1(A0_2, A1_2)
  if nil == A0_2 then
    return A1_2
  end
  return A0_2
end
function L1_1(A0_2)
  local L1_2, L2_2
  L1_2 = nil ~= A0_2
  return L1_2
end
function L2_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L2_2 = A0_2.label
  if not L2_2 then
    L2_2 = "Effect #"
    L3_2 = tostring
    L4_2 = A1_2
    L3_2 = L3_2(L4_2)
    L2_2 = L2_2 .. L3_2
  end
  function L3_2(A0_3)
    local L1_3, L2_3, L3_3, L4_3, L5_3
    L1_3 = print
    L2_3 = "[ptfx][ERROR] %s: campo obrigatorio faltando: %s"
    L3_3 = L2_3
    L2_3 = L2_3.format
    L4_3 = L2_2
    L5_3 = A0_3
    L2_3, L3_3, L4_3, L5_3 = L2_3(L3_3, L4_3, L5_3)
    L1_3(L2_3, L3_3, L4_3, L5_3)
  end
  L4_2 = true
  L5_2 = type
  L6_2 = A0_2
  L5_2 = L5_2(L6_2)
  if "table" ~= L5_2 then
    L5_2 = print
    L6_2 = "[ptfx][ERROR] Effect #%d: efeito nao e table (tipo=%s)."
    L7_2 = L6_2
    L6_2 = L6_2.format
    L8_2 = A1_2
    L9_2 = type
    L10_2 = A0_2
    L9_2, L10_2 = L9_2(L10_2)
    L6_2, L7_2, L8_2, L9_2, L10_2 = L6_2(L7_2, L8_2, L9_2, L10_2)
    L5_2(L6_2, L7_2, L8_2, L9_2, L10_2)
    L5_2 = false
    return L5_2
  end
  L5_2 = A0_2.dict
  if nil ~= L5_2 then
    L5_2 = A0_2.dict
    if "" ~= L5_2 then
      goto lbl_37
    end
  end
  L5_2 = L3_2
  L6_2 = "dict"
  L5_2(L6_2)
  L4_2 = false
  ::lbl_37::
  L5_2 = A0_2.particle
  if nil ~= L5_2 then
    L5_2 = A0_2.particle
    if "" ~= L5_2 then
      goto lbl_47
    end
  end
  L5_2 = L3_2
  L6_2 = "particle"
  L5_2(L6_2)
  L4_2 = false
  ::lbl_47::
  L5_2 = A0_2.coords
  if nil == L5_2 then
    L5_2 = L3_2
    L6_2 = "coords"
    L5_2(L6_2)
    L4_2 = false
  else
    L5_2 = L1_1
    L6_2 = A0_2.coords
    L5_2 = L5_2(L6_2)
    if not L5_2 then
      L5_2 = print
      L6_2 = "[ptfx][ERROR] %s: coords invalido (esperado vector3, recebido %s)."
      L7_2 = L6_2
      L6_2 = L6_2.format
      L8_2 = L2_2
      L9_2 = type
      L10_2 = A0_2.coords
      L9_2, L10_2 = L9_2(L10_2)
      L6_2, L7_2, L8_2, L9_2, L10_2 = L6_2(L7_2, L8_2, L9_2, L10_2)
      L5_2(L6_2, L7_2, L8_2, L9_2, L10_2)
      L4_2 = false
    end
  end
  L5_2 = A0_2.scale
  if nil ~= L5_2 then
    L5_2 = type
    L6_2 = A0_2.scale
    L5_2 = L5_2(L6_2)
    if "number" == L5_2 then
      goto lbl_86
    end
  end
  L5_2 = print
  L6_2 = "[ptfx][ERROR] %s: scale obrigatorio e deve ser number."
  L7_2 = L6_2
  L6_2 = L6_2.format
  L8_2 = L2_2
  L6_2, L7_2, L8_2, L9_2, L10_2 = L6_2(L7_2, L8_2)
  L5_2(L6_2, L7_2, L8_2, L9_2, L10_2)
  L4_2 = false
  goto lbl_96
  ::lbl_86::
  L5_2 = A0_2.scale
  if L5_2 <= 0.0 then
    L5_2 = print
    L6_2 = "[ptfx][ERROR] %s: scale deve ser > 0."
    L7_2 = L6_2
    L6_2 = L6_2.format
    L8_2 = L2_2
    L6_2, L7_2, L8_2, L9_2, L10_2 = L6_2(L7_2, L8_2)
    L5_2(L6_2, L7_2, L8_2, L9_2, L10_2)
    L4_2 = false
  end
  ::lbl_96::
  L5_2 = A0_2.renderDistance
  if nil ~= L5_2 then
    L5_2 = type
    L6_2 = A0_2.renderDistance
    L5_2 = L5_2(L6_2)
    if "number" ~= L5_2 then
      L5_2 = print
      L6_2 = "[ptfx][WARN] %s: renderDistance deve ser number; usando default."
      L7_2 = L6_2
      L6_2 = L6_2.format
      L8_2 = L2_2
      L6_2, L7_2, L8_2, L9_2, L10_2 = L6_2(L7_2, L8_2)
      L5_2(L6_2, L7_2, L8_2, L9_2, L10_2)
      A0_2.renderDistance = nil
    end
  end
  L5_2 = A0_2.alpha
  if nil ~= L5_2 then
    L5_2 = type
    L6_2 = A0_2.alpha
    L5_2 = L5_2(L6_2)
    if "number" ~= L5_2 then
      L5_2 = print
      L6_2 = "[ptfx][WARN] %s: alpha deve ser number; ignorando alpha deste efeito."
      L7_2 = L6_2
      L6_2 = L6_2.format
      L8_2 = L2_2
      L6_2, L7_2, L8_2, L9_2, L10_2 = L6_2(L7_2, L8_2)
      L5_2(L6_2, L7_2, L8_2, L9_2, L10_2)
      A0_2.alpha = nil
    end
  end
  L5_2 = A0_2.colour
  if nil ~= L5_2 then
    L5_2 = type
    L6_2 = A0_2.colour
    L5_2 = L5_2(L6_2)
    if "table" == L5_2 then
      L5_2 = A0_2.colour
      L5_2 = L5_2[1]
      if nil ~= L5_2 then
        L5_2 = A0_2.colour
        L5_2 = L5_2[2]
        if nil ~= L5_2 then
          L5_2 = A0_2.colour
          L5_2 = L5_2[3]
          if nil ~= L5_2 then
            goto lbl_153
          end
        end
      end
    end
    L5_2 = print
    L6_2 = "[ptfx][WARN] %s: colour deve ser {r,g,b}; ignorando colour deste efeito."
    L7_2 = L6_2
    L6_2 = L6_2.format
    L8_2 = L2_2
    L6_2, L7_2, L8_2, L9_2, L10_2 = L6_2(L7_2, L8_2)
    L5_2(L6_2, L7_2, L8_2, L9_2, L10_2)
    A0_2.colour = nil
  end
  ::lbl_153::
  L5_2 = A0_2.interval
  if nil ~= L5_2 then
    L5_2 = type
    L6_2 = A0_2.interval
    L5_2 = L5_2(L6_2)
    if "number" ~= L5_2 then
      L5_2 = print
      L6_2 = "[ptfx][WARN] %s: interval deve ser number (ms); desativando restart deste efeito."
      L7_2 = L6_2
      L6_2 = L6_2.format
      L8_2 = L2_2
      L6_2, L7_2, L8_2, L9_2, L10_2 = L6_2(L7_2, L8_2)
      L5_2(L6_2, L7_2, L8_2, L9_2, L10_2)
      A0_2.interval = 0
    end
  end
  return L4_2
end
function L3_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L1_2 = {}
  L2_2 = ipairs
  L3_2 = A0_2
  L2_2, L3_2, L4_2, L5_2 = L2_2(L3_2)
  for L6_2, L7_2 in L2_2, L3_2, L4_2, L5_2 do
    L8_2 = L7_2.dict
    if L8_2 then
      L8_2 = L7_2.dict
      L8_2 = L1_2[L8_2]
      if not L8_2 then
        L8_2 = L7_2.dict
        L1_2[L8_2] = true
      end
    end
  end
  L2_2 = pairs
  L3_2 = L1_2
  L2_2, L3_2, L4_2, L5_2 = L2_2(L3_2)
  for L6_2, L7_2 in L2_2, L3_2, L4_2, L5_2 do
    L8_2 = RequestNamedPtfxAsset
    L9_2 = L6_2
    L8_2(L9_2)
  end
  L2_2 = false
  while not L2_2 do
    L2_2 = true
    L3_2 = pairs
    L4_2 = L1_2
    L3_2, L4_2, L5_2, L6_2 = L3_2(L4_2)
    for L7_2, L8_2 in L3_2, L4_2, L5_2, L6_2 do
      L9_2 = HasNamedPtfxAssetLoaded
      L10_2 = L7_2
      L9_2 = L9_2(L10_2)
      if not L9_2 then
        L2_2 = false
        break
      end
    end
    L3_2 = Wait
    L4_2 = 0
    L3_2(L4_2)
  end
end
function L4_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2
  L1_2 = UseParticleFxAssetNextCall
  L2_2 = A0_2.dict
  L1_2(L2_2)
  L1_2 = A0_2.coords
  L2_2 = StartParticleFxLoopedAtCoord
  L3_2 = A0_2.particle
  L4_2 = L1_2.x
  L5_2 = L1_2.y
  L6_2 = L1_2.z
  L7_2 = 0.0
  L8_2 = 0.0
  L9_2 = 0.0
  L10_2 = A0_2.scale
  L11_2 = false
  L12_2 = false
  L13_2 = false
  L14_2 = false
  L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2)
  L3_2 = A0_2.alpha
  if nil ~= L3_2 then
    L3_2 = SetParticleFxLoopedAlpha
    L4_2 = L2_2
    L5_2 = A0_2.alpha
    L3_2(L4_2, L5_2)
  end
  L3_2 = A0_2.colour
  if nil ~= L3_2 then
    L3_2 = SetParticleFxLoopedColour
    L4_2 = L2_2
    L5_2 = A0_2.colour
    L5_2 = L5_2[1]
    L6_2 = A0_2.colour
    L6_2 = L6_2[2]
    L7_2 = A0_2.colour
    L7_2 = L7_2[3]
    L8_2 = false
    L3_2(L4_2, L5_2, L6_2, L7_2, L8_2)
  end
  return L2_2
end
function L5_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = A0_2.handle
  if L1_2 then
    L1_2 = StopParticleFxLooped
    L2_2 = A0_2.handle
    L3_2 = false
    L1_2(L2_2, L3_2)
    A0_2.handle = nil
  end
end
L6_1 = CreateThread
function L7_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2
  L0_2 = Config
  if L0_2 then
    L0_2 = Config
    L0_2 = L0_2.Effects
    if L0_2 then
      goto lbl_12
    end
  end
  L0_2 = print
  L1_2 = "[ptfx][ERROR] Config ou Config.Effects nao existe. Verifique se config.lua esta como shared_script."
  L0_2(L1_2)
  do return end
  ::lbl_12::
  L0_2 = type
  L1_2 = Config
  L1_2 = L1_2.Effects
  L0_2 = L0_2(L1_2)
  if "table" == L0_2 then
    L0_2 = Config
    L0_2 = L0_2.Effects
    L0_2 = #L0_2
    if 0 ~= L0_2 then
      goto lbl_27
    end
  end
  L0_2 = print
  L1_2 = "[ptfx][ERROR] Config.Effects vazio ou invalido."
  L0_2(L1_2)
  do return end
  ::lbl_27::
  L0_2 = Config
  L1_2 = Config
  L1_2 = L1_2.Defaults
  if not L1_2 then
    L1_2 = {}
  end
  L0_2.Defaults = L1_2
  L0_2 = Config
  L0_2 = L0_2.Defaults
  L1_2 = L0_1
  L2_2 = Config
  L2_2 = L2_2.Defaults
  L2_2 = L2_2.renderDistance
  L3_2 = 50.0
  L1_2 = L1_2(L2_2, L3_2)
  L0_2.renderDistance = L1_2
  L0_2 = Config
  L0_2 = L0_2.Defaults
  L1_2 = L0_1
  L2_2 = Config
  L2_2 = L2_2.Defaults
  L2_2 = L2_2.interval
  L3_2 = 0
  L1_2 = L1_2(L2_2, L3_2)
  L0_2.interval = L1_2
  L0_2 = {}
  L1_2 = ipairs
  L2_2 = Config
  L2_2 = L2_2.Effects
  L1_2, L2_2, L3_2, L4_2 = L1_2(L2_2)
  for L5_2, L6_2 in L1_2, L2_2, L3_2, L4_2 do
    L7_2 = type
    L8_2 = L6_2
    L7_2 = L7_2(L8_2)
    if "table" == L7_2 then
      L7_2 = L6_2.label
      if L7_2 then
        L7_2 = L6_2.label
        if L7_2 then
          goto lbl_76
        end
      end
    end
    L7_2 = "Effect #"
    L8_2 = tostring
    L9_2 = L5_2
    L8_2 = L8_2(L9_2)
    L7_2 = L7_2 .. L8_2
    ::lbl_76::
    L8_2 = type
    L9_2 = L6_2
    L8_2 = L8_2(L9_2)
    if "table" == L8_2 then
      L8_2 = L0_1
      L9_2 = L6_2.renderDistance
      L10_2 = Config
      L10_2 = L10_2.Defaults
      L10_2 = L10_2.renderDistance
      L8_2 = L8_2(L9_2, L10_2)
      L6_2.renderDistance = L8_2
      L8_2 = L6_2.alpha
      if nil == L8_2 then
        L8_2 = Config
        L8_2 = L8_2.Defaults
        L8_2 = L8_2.alpha
        L6_2.alpha = L8_2
      end
      L8_2 = L6_2.colour
      if nil == L8_2 then
        L8_2 = Config
        L8_2 = L8_2.Defaults
        L8_2 = L8_2.colour
        L6_2.colour = L8_2
      end
      L8_2 = L0_1
      L9_2 = L6_2.interval
      L10_2 = Config
      L10_2 = L10_2.Defaults
      L10_2 = L10_2.interval
      L8_2 = L8_2(L9_2, L10_2)
      L6_2.interval = L8_2
      L8_2 = L6_2.interval
      if L8_2 < 0 then
        L6_2.interval = 0
      end
    end
    L8_2 = L2_1
    L9_2 = L6_2
    L10_2 = L5_2
    L8_2 = L8_2(L9_2, L10_2)
    if L8_2 then
      L8_2 = table
      L8_2 = L8_2.insert
      L9_2 = L0_2
      L10_2 = L6_2
      L8_2(L9_2, L10_2)
    else
      L8_2 = print
      L9_2 = "[ptfx][INFO] %s ignorado por configuracao invalida."
      L10_2 = L9_2
      L9_2 = L9_2.format
      L11_2 = L7_2
      L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2 = L9_2(L10_2, L11_2)
      L8_2(L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2)
    end
  end
  L1_2 = #L0_2
  if 0 == L1_2 then
    L1_2 = print
    L2_2 = "[ptfx][ERROR] Nenhum efeito valido. Nada sera iniciado."
    L1_2(L2_2)
    return
  end
  L1_2 = print
  L2_2 = "[ptfx][INFO] Iniciando %d efeitos validos. (interval=0 = modo leve; interval>0 = restart opcional)"
  L3_2 = L2_2
  L2_2 = L2_2.format
  L4_2 = #L0_2
  L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2 = L2_2(L3_2, L4_2)
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2)
  L1_2 = L3_1
  L2_2 = L0_2
  L1_2(L2_2)
  L1_2 = {}
  L2_2 = 1
  L3_2 = #L0_2
  L4_2 = 1
  for L5_2 = L2_2, L3_2, L4_2 do
    L6_2 = {}
    L6_2.handle = nil
    L6_2.nextRestartAt = 0
    L1_2[L5_2] = L6_2
  end
  while true do
    L2_2 = PlayerPedId
    L2_2 = L2_2()
    L3_2 = GetEntityCoords
    L4_2 = L2_2
    L3_2 = L3_2(L4_2)
    L4_2 = GetGameTimer
    L4_2 = L4_2()
    L5_2 = false
    L6_2 = ipairs
    L7_2 = L0_2
    L6_2, L7_2, L8_2, L9_2 = L6_2(L7_2)
    for L10_2, L11_2 in L6_2, L7_2, L8_2, L9_2 do
      L12_2 = L1_2[L10_2]
      L13_2 = L11_2.coords
      L14_2 = L3_2 - L13_2
      L14_2 = #L14_2
      L15_2 = L11_2.renderDistance
      if L14_2 <= L15_2 then
        L5_2 = true
        L15_2 = L12_2.handle
        if nil == L15_2 then
          L15_2 = L4_1
          L16_2 = L11_2
          L15_2 = L15_2(L16_2)
          L12_2.handle = L15_2
          L15_2 = L11_2.interval
          if L15_2 > 0 then
            L15_2 = L11_2.interval
            L15_2 = L4_2 + L15_2
            L12_2.nextRestartAt = L15_2
          else
            L12_2.nextRestartAt = 0
          end
        else
          L15_2 = L11_2.interval
          if L15_2 > 0 then
            L15_2 = L12_2.nextRestartAt
            if L15_2 > 0 then
              L15_2 = L12_2.nextRestartAt
              if L4_2 >= L15_2 then
                L15_2 = L5_1
                L16_2 = L12_2
                L15_2(L16_2)
                L15_2 = L4_1
                L16_2 = L11_2
                L15_2 = L15_2(L16_2)
                L12_2.handle = L15_2
                L15_2 = L11_2.interval
                L15_2 = L4_2 + L15_2
                L12_2.nextRestartAt = L15_2
              end
            end
          end
        end
      else
        L15_2 = L12_2.handle
        if nil ~= L15_2 then
          L15_2 = L5_1
          L16_2 = L12_2
          L15_2(L16_2)
        end
        L12_2.nextRestartAt = 0
      end
    end
    if L5_2 then
      L6_2 = Wait
      L7_2 = 200
      L6_2(L7_2)
    else
      L6_2 = Wait
      L7_2 = 1000
      L6_2(L7_2)
    end
  end
end
L6_1(L7_1)
