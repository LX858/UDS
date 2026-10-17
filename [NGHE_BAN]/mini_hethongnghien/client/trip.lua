-- =======================================================
-- TRIP & ACID EFFECT SYSTEM (1:1 Converted from mf-drugfx)
-- =======================================================

Drugs                   = {}
Drugs.Queue             = {}
Drugs.Presets           = (Config and Config.TripPresets or {})
Drugs.DrivingIncidents  = (Config and Config.DrivingIncidents or {})

-- Math helper (1:1 from mf-drugfx functions.lua)
function PointOnSphere(alt,azu,radius,orgX,orgY,orgZ)
  local toradians = 0.017453292384744
  alt,azu,radius,orgX,orgY,orgZ = ( tonumber(alt or 0) or 0 ) * toradians, ( tonumber(azu or 0) or 0 ) * toradians, tonumber(radius or 0) or 0, tonumber(orgX or 0) or 0, tonumber(orgY or 0) or 0, tonumber(orgZ or 0) or 0
  if vector3 then
      return vector3(
           orgX + radius * math.sin( azu ) * math.cos( alt ),
           orgY + radius * math.cos( azu ) * math.cos( alt ),
           orgZ + radius * math.sin( alt )
      )
  end
end

Drugs.Init = function()
  local ply_id = PlayerId()
  while not NetworkIsPlayerActive(ply_id) do Wait(0); end
  Drugs.Update()
end

Drugs.Update = function()
  while true do
    if #Drugs.Queue > 0 then
      local target = Drugs.Queue[1]
      Drugs.Apply(target)
      Drugs.Dequeue()
    end

    Wait(0)
  end
end

Drugs.Enqueue = function(item)
  if item.instant then
    Drugs.Apply(item)
  else
    table.insert(Drugs.Queue,item)
  end
end

Drugs.Dequeue = function(i)
  table.remove(Drugs.Queue,(i or 1))
end

Drugs.SoberUp = function()
  Drugs.DoSober = true
  while Drugs.DoSober do Wait(0); end
end

Drugs.Apply = function(item)
  if item.sober and Drugs.Influenced then Drugs.SoberUp(); end

  Drugs.Influenced = true
  local preset = Drugs.GetPreset(item.type) 
  if preset.play_song then
    if preset.get_wave then
      local res = false
      TriggerEvent("Wave:Get",preset.play_song,true,100000,function(wave,duration)
        Drugs.StartFX(item,wave,duration)
        res = true
      end)
      while not res do Wait(0); end
    else
      SendNUIMessage({type = "playMusic", song = preset.play_song, seek = preset.song_start})
      Drugs.StartFX(item)
    end
  else
    Drugs.StartFX(item)
  end
  Wait(1000)
end

Drugs.DrawToon = function(bits,cols,loc)
  local height = 0
  local width = 0

  Drugs.ToonZ = math.min(0.0,(Drugs.ToonZ or -20.0) + (1.0 * GetFrameTime()))
  for k = #bits,1,-1 do
    local v = bits[k]
    local pos = vector3(loc.x,loc.y+width,loc.z+height)
    local col = cols[v]    

    if Drugs.ToonAlpha < 255.0 and not Drugs.ToonInit and not Drugs.DoSober then
      Drugs.ToonAlpha = Drugs.ToonAlpha + (50.0 * GetFrameTime())
      if Drugs.ToonAlpha >= 255.0 then
        Drugs.ToonInit = true
      end
    end

    if col and v ~= 133 and v ~= 132 then
      DrawBox(pos.x+0.5,pos.y+0.5,pos.z+0.5 + Drugs.ToonZ, pos.x-0.5,pos.y-0.5,pos.z-0.5 + Drugs.ToonZ, col.r,col.g,col.b,math.floor(Drugs.ToonAlpha))
    end

    width = width + 1
    if width >= 32 then
      width = 0
      height = height + 1
    end
  end
end

Drugs.GetPreset = function(drug_type)
  local presets = Drugs.Presets
  if type(presets) ~= 'table' or #presets == 0 then
    presets = Config.TripPresets or {}
  end
  local min = 1
  local max = #presets
  if max == 1 then
    return presets[1]
  else
    if max == 2 then
      if math.random(1000) > 800 then
        return presets[2]
      else
        return presets[1]
      end
    else
      local rand = math.random(1000)
      if rand > 900 then
        return presets[max]
      elseif rand > 500 then
        local key = math.random(1,max-1)
        return presets[key]
      else     
        return presets[1]
      end
    end
  end
end

Drugs.StartFX = function(drug,wave,duration)
  local preset = Drugs.GetPreset(drug.type) 
  local time   = (duration or preset.effect_timeout * drug.quality)

  if preset.draw_toon and not Drugs.DrawToons and Toons then
    Drugs.DrawToons = true
    Drugs.ToonZ     = -20.0
    Drugs.ToonAlpha = 0.0
    Drugs.ToonInit  = false

    local toons  = Toons.bits[preset.draw_toon[math.random(#preset.draw_toon)]]
    local state  = 1
    local adder  = 1
    local timer  = GetGameTimer()
    
    Citizen.CreateThread(function()
      while Drugs.DrawToons do
        if (GetGameTimer() - timer) > 1000 and not Drugs.DoSober then
          timer = GetGameTimer()
          state = state + (adder or 0)

          if state > #toons then
            adder = -1
            state = #toons-1
          elseif state <= 0 then
            adder = 1
            state = 2
          end
        end

        local plyPed = GetPlayerPed(-1)
        local plyPos = GetEntityCoords(plyPed)
        local infront = vector3(plyPos.x+35.0, plyPos.y-8.0,plyPos.z)
        local behind  = vector3(plyPos.x-35.0, plyPos.y-8.0,plyPos.z)

        if preset.toon_count == 2 then
          Drugs.DrawToon(toons[state],Toons.cols,behind)
        end
        Drugs.DrawToon(toons[state],Toons.cols,infront)

        Wait(0)
      end
    end)
  end

  if preset.draw_box and not Drugs.Cubes then
    Drugs.Cubes = {}
    for i=1,preset.draw_box,1 do
      local r = math.random(5,255)
      local g = math.random(5,255)
      local b = math.random(5,255)
      local a = math.random(40,50)

      local x = math.random(1,180)
      local y = math.random(1,359)
      local z = math.random(15,35)

      Drugs.Cubes[i] = {pos=PointOnSphere(x,y,z),points={x=x,y=y,z=z},col={r=r, g=g, b=b, a=a}}
    end  

    Citizen.CreateThread(function()    
      local start = GetGameTimer()
      Drugs.CubeMod = 1.0
      while (duration and (GetGameTimer() - start)/1000 or (GetGameTimer() - start)/1000) < (duration and duration / 5 or (time / 1000) / 5) and not Drugs.DoSober do
        local plyPos = GetEntityCoords(GetPlayerPed(-1))
        Drugs.CubeMod = math.min(15.0,Drugs.CubeMod + (0.7 * GetFrameTime()))
        for k,v in pairs(Drugs.Cubes) do
          local pos = plyPos + v.pos
          local r,g,b 
          if Drugs.Wave then
            local wave_factor = math.min(1.2, math.max(0.4, 0.4 + (Drugs.Wave * 0.8)))
            r,g,b = math.min(255,math.max(40,math.floor(v.col.r * wave_factor))),math.min(255,math.max(40,math.floor(v.col.g * wave_factor))),math.min(255,math.max(40,math.floor(v.col.b * wave_factor)))
          else
            r,g,b = v.col.r,v.col.g,v.col.b
          end
          DrawBox(pos.x+Drugs.CubeMod,pos.y+Drugs.CubeMod,pos.z+Drugs.CubeMod,pos.x-Drugs.CubeMod,pos.y-Drugs.CubeMod,pos.z-Drugs.CubeMod, r,g,b,v.col.a)
          local points = {x=v.points.x+0.1,y=v.points.y+0.1,z=v.points.z}
          Drugs.Cubes[k].points = points
          Drugs.Cubes[k].pos = PointOnSphere(points.x,points.y,points.z)
        end
        Wait(0)
      end

      while Drugs.CubeMod and Drugs.CubeMod > 0.0 do
        local position = GetEntityCoords(GetPlayerPed(-1))
        for k,v in pairs(Drugs.Cubes) do
          local addX = 0.1
          local addY = 0.1

          if k%4 == 0 then
            addY = -0.2
          elseif k%3 == 0 then
            addX = -0.2
          elseif k%2 == 0 then
            addX = -0.1
            addY = -0.1
          end

          local r,g,b 
          if Drugs.Wave then
            local wave_factor = math.min(1.2, math.max(0.4, 0.4 + (Drugs.Wave * 0.8)))
            r,g,b = math.min(255,math.max(40,math.floor(v.col.r * wave_factor))),math.min(255,math.max(40,math.floor(v.col.g * wave_factor))),math.min(255,math.max(40,math.floor(v.col.b * wave_factor)))
          else
            r,g,b = v.col.r,v.col.g,v.col.b
          end
          local pos = position + v.pos
          DrawBox(pos.x+Drugs.CubeMod,pos.y+Drugs.CubeMod,pos.z+Drugs.CubeMod,pos.x-Drugs.CubeMod,pos.y-Drugs.CubeMod,pos.z-Drugs.CubeMod, r,g,b,v.col.a)
          local points = {x=v.points.x+addX,y=v.points.y+addY,z=v.points.z}
          Drugs.Cubes[k].points = points
          Drugs.Cubes[k].pos = PointOnSphere(points.x,points.y,points.z)
        end
        Wait(0)
      end
      Drugs.Cubes = false
    end)
  end

  if preset.spawn_clone and not Drugs.Clone then
    if math.random(500) >= 0 then 
      local plyPed = GetPlayerPed(-1)
      local pos = GetEntityCoords(plyPed)

      local randomAlt     = math.random(0,359)*1.0
      local randomDist    = math.random(50,80)*1.0
      local spawnPos      = pos + PointOnSphere(0.0,randomAlt,randomDist)

      Drugs.Clone = ClonePed(plyPed, GetEntityHeading(plyPed), false, false)
      while not DoesEntityExist(Drugs.Clone) do Wait(0); end

      local f,z = GetGroundZFor_3dCoord(spawnPos.x,spawnPos.y,spawnPos.z + 1.0)
      SetEntityCoordsNoOffset(Drugs.Clone, spawnPos.x,spawnPos.y,z + 0.5)
      SetPedComponentVariation(Drugs.Clone, 1, 60, 0, 0, 0)
      NetworkSetEntityInvisibleToNetwork(Drugs.Clone,true)
      SetEntityLocallyInvisible(Drugs.Clone,false)

      SetEntityInvincible(Drugs.Clone,true)
      SetBlockingOfNonTemporaryEvents(Drugs.Clone,true)

      Citizen.CreateThread(function()
        local LastPedTurn = 0
        while DoesEntityExist(Drugs.Clone) and not Drugs.DoSober do
          local dist = Vdist(GetEntityCoords(GetPlayerPed(-1)), GetEntityCoords(Drugs.Clone))
          if dist > 5.0 then
            TaskGoToEntity(Drugs.Clone, GetPlayerPed(-1), -1, 4.0, 100.0, 1073741824, 0)
            Wait(1000)
          else       
            if not IsTaskMoveNetworkActive(Drugs.Clone) then
              Drugs.LoadAnimDict('anim@mp_point')
              TaskMoveNetworkByName(Drugs.Clone, "task_mp_pointing", 0.5, 0, "anim@mp_point", 24)
              SetPedCurrentWeaponVisible(Drugs.Clone, 0, 1, 1, 1)
              SetPedConfigFlag(Drugs.Clone, 36, 1)
            end

            if not LastPedTurn or (GetGameTimer() - LastPedTurn) > 1000 then
              LastPedTurn = GetGameTimer()
              TaskTurnPedToFaceEntity(Drugs.Clone, GetPlayerPed(-1), -1)
            end

            SetTaskMoveNetworkSignalFloat (Drugs.Clone, "Pitch",          0.4)
            SetTaskMoveNetworkSignalFloat (Drugs.Clone, "Heading",        0.5)
            SetTaskMoveNetworkSignalBool  (Drugs.Clone, "isBlocked",      false)
            SetTaskMoveNetworkSignalBool  (Drugs.Clone, "isFirstPerson",  false)

            if IsPedRagdoll(Drugs.Clone) then
              while IsPedRagdoll(Drugs.Clone) do Wait(0); end
              ClearPedTasksImmediately(Drugs.Clone)
              Wait(10)
            end
          end
          Wait(0)
        end
      end)
    end
  end

  
  if preset.timecycle then
    SetTimecycleModifierStrength(0.0) 
    SetTimecycleModifier(preset.timecycle)
    if not wave then
      Citizen.CreateThread(function()
        local cur_strength = 0.0
        local max_strength = math.max(preset.timecycle_min_strength,math.min(preset.timecycle_min_strength * drug.quality,preset.timecycle_max_strength))

        while (cur_strength < max_strength) and not Drugs.DoSober do
          cur_strength = cur_strength + (0.1 * GetFrameTime())
          SetTimecycleModifierStrength(cur_strength)
          Wait(0)
        end
      end)
    end
  end

  if preset.secondary_timecycle then
    SetExtraTimecycleModifierStrength(0.0) 
    SetExtraTimecycleModifier(preset.secondary_timecycle)
    if not wave then
      Citizen.CreateThread(function()

        local cur_strength = 0.0
        local max_strength = math.max(preset.secondary_timecycle_min_strength,math.min(preset.secondary_timecycle_min_strength * drug.quality,preset.secondary_timecycle_max_strength))

        while (cur_strength < max_strength) and not Drugs.DoSober do
          cur_strength = cur_strength + (0.1 * GetFrameTime())
          SetExtraTimecycleModifierStrength(cur_strength)
          Wait(0)
        end
      end)
    end
  end

  if preset.cam_shake then
    ShakeGameplayCam(preset.cam_shake, 0.0) 
    Citizen.CreateThread(function()      
      local cur_strength = 0.0
      local max_strength = math.max(preset.cam_shake_min_strength,math.min(preset.cam_shake_min_strength * drug.quality,preset.cam_shake_max_strength))  

      while (cur_strength < max_strength) and not Drugs.DoSober do
        cur_strength = cur_strength + (0.1 * GetFrameTime())
        ShakeGameplayCam(preset.cam_shake, cur_strength) 
        Wait(0)
      end
    end)
  end

  if preset.motion_blur then    
    SetPedMotionBlur(GetPlayerPed(-1), true)
  end

  -- Drunk Walkstyle & Ngã loạng choạng
  local initialPed = PlayerPedId()
  SetPedIsDrunk(initialPed, true)
  RequestAnimSet("move_m@drunk@verydrunk")
  while not HasAnimSetLoaded("move_m@drunk@verydrunk") do Wait(10) end
  SetPedMovementClipset(initialPed, "move_m@drunk@verydrunk", 1.0)

  -- Té ngã (Ragdoll) ngấm thuốc khi bắt đầu (nếu không ngồi trong xe)
  if not IsPedInAnyVehicle(initialPed, false) then
    SetPedToRagdoll(initialPed, 3500, 3500, 0, true, true, false)
  end

  if drug.effects.add_health then
    local ped = GetPlayerPed(-1)
    local hp  = GetEntityHealth(ped)
    SetEntityHealth(ped,math.min(200,hp + drug.effects.add_health))
  elseif drug.effects.take_health then
    local ped = GetPlayerPed(-1)
    local hp  = GetEntityHealth(ped)
    SetEntityHealth(ped,math.max(0,hp - drug.effects.take_health))
  end

  if drug.effects.add_armor then
    local ped = GetPlayerPed(-1)
    local arm = GetPedArmour(ped)
    SetPedArmour(ped,arm + drug.effects.add_armor)
  elseif drug.effects.take_armor then
    local ped = GetPlayerPed(-1)
    local arm = GetPedArmour(ped)
    SetPedArmour(ped,arm - drug.effects.take_armor)
  end

  if (drug.effects.health_regen) then
    SetPlayerHealthRechargeMultiplier(PlayerId(),drug.effects.health_regen)
  end

  local durations = (wave and (#wave / duration))
  local start_time = GetGameTimer()
  local last_drunk_check = nil
  local drunk_interval = nil
  local last_stumble_check = nil
  local stumble_interval = math.random(15000, 25000)
  local smooth_wave = 0.0

  while (duration and (GetGameTimer() - start_time)/1000 or GetGameTimer() - start_time) < time and not Drugs.DoSober do  
    if drug.effects.move_speed then
      SetPedMoveRateOverride(GetPlayerPed(-1),drug.effects.move_speed)
    end

    -- Loạng choạng / Vấp ngã khi đang đi bộ trong cơn phê
    local curPed = PlayerPedId()
    if not IsPedInAnyVehicle(curPed, false) then
      local nowT = GetGameTimer()
      if not last_stumble_check or (nowT - last_stumble_check) > stumble_interval then
        last_stumble_check = nowT
        stumble_interval = math.random(15000, 25000)
        if IsPedWalking(curPed) or IsPedRunning(curPed) or IsPedSprinting(curPed) then
          SetPedToRagdoll(curPed, 1800, 1800, 0, true, true, false)
        end
      end
    end

    if wave then
      local now         = (GetGameTimer() / 1000)
      local since       = (now - (start_time / 1000))
      local target      = math.max(1,math.min(#wave,math.floor(since * durations)))
      local wave_target = wave[target] or 0.0

      -- Bộ lọc Envelope Follower (Làm mượt sóng âm: tăng mượt và hạ từ từ)
      local dt = GetFrameTime()
      local current_abs = math.min(1.0, math.abs(wave_target) * 1.8)
      
      if current_abs > smooth_wave then
        smooth_wave = smooth_wave + (current_abs - smooth_wave) * math.min(1.0, 3.0 * dt)
      else
        smooth_wave = smooth_wave + (current_abs - smooth_wave) * math.min(1.0, 1.5 * dt)
      end

      Drugs.Wave = smooth_wave

      if preset.timecycle then
        local base_strength = (preset.timecycle_min_strength or 0.4) * drug.quality
        local max_strength  = (preset.timecycle_max_strength or 1.2) * drug.quality
        local pulse_range   = (max_strength - base_strength)
        local targetS       = base_strength + (smooth_wave * pulse_range)
        SetTimecycleModifierStrength(targetS)
      end

      if preset.secondary_timecycle then
        local base_strength = (preset.secondary_timecycle_min_strength or 0.2) * drug.quality
        local max_strength  = (preset.secondary_timecycle_max_strength or 0.8) * drug.quality
        local pulse_range   = (max_strength - base_strength)
        local targetS       = base_strength + (smooth_wave * pulse_range)
        SetExtraTimecycleModifierStrength(targetS)
      end
    end

    if preset.drunk_drive then
      local now = GetGameTimer()
      if not last_drunk_check or now - last_drunk_check > (drunk_interval or 1) then 
        local ped = GetPlayerPed(-1)
        local veh = GetVehiclePedIsUsing(ped,false)
        last_drunk_check = now

        if veh and veh > 0 then
          if GetPedInVehicleSeat(veh,-1) == ped then
            local class = GetVehicleClass(veh)
            if class ~= 15 and class ~= 16 and class ~= 21 and class ~= 13 then  
              local disaster = Drugs.DrivingIncidents[math.random(#Drugs.DrivingIncidents)]          
              if disaster then
                TaskVehicleTempAction(ped, veh, disaster.interaction, disaster.time) 
              end
              drunk_interval = math.random(5000,10000)
            end
          end
        end
      end
    end
    Wait(0)
  end

  Drugs.StopFX(drug,preset)
end

Drugs.StopFX = function(drug,preset)
  local time   = (Drugs.DoSober and 1000 or preset.effect_timeout * drug.quality)

  -- Reset Drunk Walkstyle & Say xỉn
  local plyPed = PlayerPedId()
  SetPedIsDrunk(plyPed, false)
  ResetPedMovementClipset(plyPed, 0.0)
  RemoveAnimSet("move_m@drunk@verydrunk")

  local done = false
  local done_a,done_b,done_c,done_d,done_e = false,false,false,false,false

  if preset.draw_toon then
    Citizen.CreateThread(function()
      while Drugs.ToonAlpha and Drugs.ToonAlpha > 0.0 do
        Drugs.ToonAlpha = Drugs.ToonAlpha - (50.0 * GetFrameTime())
        Wait(0)
      end
      Drugs.DrawToons = false
    end)
  end

  if preset.draw_box and Drugs.Cubes then
    Citizen.CreateThread(function()
      while Drugs.CubeMod and Drugs.CubeMod > 0.0 do
        local plyPos = GetEntityCoords(GetPlayerPed(-1))
        Drugs.CubeMod = Drugs.CubeMod - (1.0 * GetFrameTime())
        Wait(0)
      end
      Drugs.Cubes = nil
      done_d = true
    end)
  else
    done_d = true
  end

  if preset.play_song then    
    if preset.get_wave then
      TriggerEvent("Wave:Stop")
    else
      SendNUIMessage({type = "stopMusic", song = preset.play_song})
    end
  end

  if preset.spawn_clone and Drugs.Clone then
    SetEntityAsMissionEntity(Drugs.Clone,true,true)
    DeleteEntity(Drugs.Clone)
    Drugs.Clone = false
    done_e = true
  else
    done_e = true
  end

  if preset.timecycle then
    Citizen.CreateThread(function()
      local cur_strength = math.max(preset.timecycle_min_strength,math.min(preset.timecycle_min_strength * drug.quality,preset.timecycle_max_strength))

      while (cur_strength > 0.0) do
        cur_strength = cur_strength - (0.2 * GetFrameTime())
        SetTimecycleModifierStrength(cur_strength)
        Wait(0)
      end
      done_a = true
      ClearTimecycleModifier()
    end)
  else
    done_a = true
  end

  if preset.secondary_timecycle then
    Citizen.CreateThread(function()
      local cur_strength = math.max(preset.secondary_timecycle_min_strength,math.min(preset.secondary_timecycle_min_strength * drug.quality,preset.secondary_timecycle_max_strength))

      while (cur_strength > 0.0) do
        cur_strength = cur_strength - (0.2 * GetFrameTime())
        SetExtraTimecycleModifierStrength(cur_strength)
        Wait(0)
      end
      done_b = true
      ClearExtraTimecycleModifier()
    end)
  else
    done_b = true
  end

  if preset.cam_shake then
    Citizen.CreateThread(function()    
      local cur_strength = math.max(preset.cam_shake_min_strength,math.min(preset.cam_shake_min_strength * drug.quality,preset.cam_shake_max_strength))  

      while (cur_strength > 0.0) do
        cur_strength = cur_strength - (0.2 * GetFrameTime())
        ShakeGameplayCam(preset.cam_shake, cur_strength) 
        Wait(0)
      end
      done_c = true
    end)
  else
    done_c = true
  end

  if preset.motion_blur then    
    SetPedMotionBlur(GetPlayerPed(-1), false)
  end

  if preset.health_regen then    
    SetPlayerHealthRechargeMultiplier(PlayerId(),1.0)
  end

  while (not done_a) or (not done_b) or (not done_c) or (not done_d) or (not done_e) do Wait(0); end

  Drugs.Wave        = false
  Drugs.DoSober     = false
  Drugs.Influenced  = false
end

Drugs.LoadAnimDict = function(ad)
  RequestAnimDict(ad)
  while not HasAnimDictLoaded(ad) do Wait(0); end
end

Drugs.LoadModel = function(hash_or_model)
  local hash = (type(hash_or_model) == "number" and hash_or_model or GetHashKey(hash_or_model))
  RequestModel(hash)
  while not HasModelLoaded(hash) do Wait(0); end
end

Drugs.CreateProp = function(drug)
  local prop,bone,pos,rot = drug.animation.prop,drug.animation.bone,(drug.animation.pos or vector3(0.0,0.0,0.0)),(drug.animation.rot or vector3(0.0,0.0,0.0))
  local hash = GetHashKey(prop)  
  Drugs.LoadModel(hash)

  local ped = GetPlayerPed(-1)
  local prop = CreateObject(hash, 1.0, 1.0, 1.0, 1, 1, 0)
  local bone = GetPedBoneIndex(ped, bone)

  SetEntityAsMissionEntity(prop,true,true)
  AttachEntityToEntity(prop, ped, bone, pos.x,pos.y,pos.z,rot.x,rot.y,rot.z, 1, 0, 0, 0, 2, 1)

  return prop
end

Drugs.Animate = function(drug)
  if drug.animation then
    while Drugs.Animating do Wait(0); end
    Drugs.Animating = true
    if drug.animation.prop then 
      Drugs.Prop = Drugs.CreateProp(drug) 
    end
    if drug.animation.type == "animation" then
      local ped = GetPlayerPed(-1)
      local pos = GetEntityCoords(ped)
      Drugs.LoadAnimDict(drug.animation.dict)
      TaskPlayAnimAdvanced(ped,drug.animation.dict,drug.animation.anim,pos.x,pos.y,pos.z,0.0,0.0,GetEntityHeading(ped),(drug.animation.blend_in or 1.0),(drug.animation.blend_out or 1.0),(drug.animation.duration or -1),(drug.animation.flag or 0),(drug.animation.start or 0.0),0,0)
      if drug.animation.wait then
        if drug.animation.timeout then
          Wait(drug.animation.timeout)
          ClearPedTasks(ped)
        else
          while not IsEntityPlayingAnim(ped,drug.animation.dict,drug.animation.anim,3) do Wait(0); end
          while IsEntityPlayingAnim(ped,drug.animation.dict,drug.animation.anim,3)     do Wait(0); end
        end
      end
    end
    if drug.animation.prop and Drugs.Prop and DoesEntityExist(Drugs.Prop) then
      DeleteObject(Drugs.Prop)
      Drugs.Prop = nil
    end
    Drugs.Animating = false
  end
end

Drugs.GetQueue = function(minimal)
  local res = (minimal and {} or Drugs.Queue)
  if minimal then
    for k,v in ipairs(Drugs.Queue) do
      table.insert(res,v.name)
    end
  end
  return res
end

-- =======================================================
-- EXPORTS & EVENTS
-- =======================================================

AddEventHandler("Drugs:GetQueue",function(callback,minimal)
  callback(Drugs.GetQueue(minimal))
end)

exports("GetQueue",function(minimal)
  return Drugs.GetQueue(minimal)
end)

exports("GetDrugQueue",function(minimal)
  return Drugs.GetQueue(minimal)
end)

exports('TripEffect', function(quality, duration, instant)
  local item = {
    name    = 'Acid',
    type    = 'trip',
    quality = quality or 1.0,
    instant = (instant ~= nil and instant or false),
    sober   = false,
    effects = {}
  }
  if duration then
    item.effect_timeout = duration
  end
  Drugs.Enqueue(item)
end)

exports('StartTrip', function(quality, duration, instant)
  exports['mini_hethongnghien']:TripEffect(quality, duration, instant)
end)

exports('StartDrugEffect', function(drugType, quality, duration)
  local item = {
    name    = drugType or 'Drug',
    type    = drugType or 'trip',
    quality = quality or 1.0,
    instant = false,
    sober   = false,
    effects = {}
  }
  if duration then
    item.effect_timeout = duration
  end
  Drugs.Enqueue(item)
end)

exports('SoberUp', function()
  Drugs.SoberUp()
end)

exports('UseAcidClient', function(data, slot)
  if Config.Blacklist and Config.Blacklist.enabled then
    local ped = PlayerPedId()
    local playerCoords = GetEntityCoords(ped)
    for _, zone in ipairs(Config.Blacklist.zones) do
      local distance = #(playerCoords - vector3(zone.coords.x, zone.coords.y, zone.coords.z))
      if distance <= zone.radius then
        lib.notify({
          description = Config.Notify.blacklist_zone,
          type = 'error',
          duration = 5000
        })
        return
      end
    end
  end
  TriggerServerEvent('mini_hethongnghien:server:useAcid', slot)
end)

RegisterNetEvent("Drugs:Consume")
AddEventHandler("Drugs:Consume",function(item,random_id)
  if not item then item = Config.Acid end
  Drugs.Animate(item)
  Drugs.Enqueue(item)
end)

RegisterNetEvent('mini_hethongnghien:client:consumeDrug', function(item, random_id)
  if not item then item = Config.Acid end
  Drugs.Animate(item)
  Drugs.Enqueue(item)
end)

RegisterNetEvent('mini_hethongnghien:client:startTrip', function(quality, duration)
  exports['mini_hethongnghien']:TripEffect(quality, duration)
end)

RegisterNetEvent('Drugs:SoberUp', function()
  Drugs.SoberUp()
end)

Citizen.CreateThread(Drugs.Init)
