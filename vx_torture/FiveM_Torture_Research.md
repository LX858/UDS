# GTA V / FiveM torture — bản tra cứu kỹ thuật

Tra cứu ngày 13/10/2026. Dữ liệu lấy trực tiếp từ fbi3.c của YimMenu và dump DurtyFree; native đối chiếu citizenfx/natives. Đây là danh mục các tài nguyên torture của nhiệm vụ FBI3 đã tìm thấy, không phải cam kết bao phủ mọi resource thương mại/custom. Chưa kiểm thử trong GTA/FiveM; build game của server có thể khác bản decompile.

## Nguồn
- Script nhiệm vụ: https://github.com/YimMenu/GTA-V-Decompiled-Scripts/blob/master/decompiled_scripts/fbi3.c
- Animation: https://github.com/DurtyFree/gta-v-data-dumps/blob/master/animDictsCompact.json
- Particle: https://github.com/DurtyFree/gta-v-data-dumps/blob/master/particleEffectsCompact.json
- Native: https://github.com/citizenfx/natives
- Reference: https://docs.fivem.net/natives/

## Kiến trúc
Torture không phải một API bật/tắt. Script gốc phối hợp synchronized scene, ped, animated objects, camera, facial animation, audio, particle, UI và state machine. Logic mission/health không tự xuất hiện khi phát animation. Không nên chạy toàn bộ script Story Mode trên server.

Local scene: CreateSynchronizedScene, TaskSynchronizedScene, PlaySynchronizedEntityAnim, PlaySynchronizedCamAnim. Network scene: NetworkCreateSynchronisedScene, NetworkAddPedToSynchronisedScene, NetworkAddEntityToSynchronisedScene, NetworkStartSynchronisedScene, NetworkStopSynchronisedScene. Đổi network handle sang local bằng NetworkGetLocalSceneFromNetworkId trước khi đọc GetSynchronizedScenePhase.

## Vị trí cần đọc trong script
- Khối khởi tạo: model, dictionary, âm thanh, particle, origin.
- func_428: dựng scene và gán ped/object/camera, attachment, facial tracks, loop/hold.
- func_429: bảng mapping các scene ID. Một số electrocute case chỉ chọn dictionary; cần đọc logic ghi dữ liệu bổ sung và các hàm gọi.
- func_430: lọc các scene ID hợp lệ.
- func_431/432: camera lựa chọn dụng cụ, interpolation/shake; không phải mapping electrocute.
- func_251: wrapper phát sound từ entity.
- Tìm scr_fbi3_* để xem thời điểm phát particle; không phát mọi hiệu ứng suốt animation.
- Tên func_N là nhãn do decompiler tạo, có thể thay đổi theo build.

## Prop xác minh từ khối khởi tạo
| Model | Vai trò |
|---|---|
| prop_torture_ch_01 | Ghế |
| prop_cs_wrench | Cờ lê |
| p_pliers_01_s | Kìm |
| prop_torture_01 | Prop bộ điện/battery |
| p_ld_crocclips01_s / p_ld_crocclips02_s | Hai kẹp |
| prop_syringe_01 | Syringe |
| prop_ld_tooth | Prop răng |
| p_loose_rag_01_s | Khăn |
| p_wboard_clth_s | Cloth |
| p_arm_bind_cut_s | Arm binding; hand_l/hand_r là track của object, không phải hai ped mới |
| p_cs_trolley_01_s | Trolley |
| v_ilev_tort_stool | Stool |
| prop_ecg_01 | ECG |
| GetWeapontypeModel(joaat('WEAPON_PETROLCAN')) | Model can lấy qua native như script gốc |

Origin mission: position (142.99, -2201.98, 4.07). Rotation ghế (-0.45, 0, 96.61); scene lấy rotation ghế cộng thêm 180 độ quanh Z. Vector(...) trong decompile có thứ tự hiển thị khác Lua vector3: phải đọc đúng tọa độ thành phần. Không xem đây là offset universal cho mọi ghế/custom prop.

## Particle
Asset dictionary: scr_fbi3. Các effect đã đối chiếu dump:
scr_fbi3_elec_smoulder, scr_fbi3_elec_sparks, scr_fbi3_dirty_water_pour, scr_fbi3_dirty_wtr_splash_sp, scr_fbi3_blood_extraction, scr_fbi3_blood_mouth, scr_fbi3_blood_throwaway.

Load bằng RequestNamedPtfxAsset / HasNamedPtfxAssetLoaded. Gọi UseParticleFxAssetNextCall trước mỗi lần StartParticleFx*. Với bone native cần phân biệt bone ID và bone index đúng signature. StopParticleFxLooped khi dừng. Dùng networked variant hoặc phát local trên mỗi observer một lần; đừng kết hợp cả hai gây trùng.

## Audio
Các bank xuất hiện: FBI_03_TORTURE_General, FBI_03_TORTURE_Electric, FBI_03_TORTURE_Teeth, FBI_03_TORTURE_Water, FBI_03_TORTURE_Wrench.
Các sound name: FBI_03_TORTURE_Electric_Hum, FBI_03_TORTURE_Electric_Zap, FBI_03_TORTURE_Electric_Spark, FBI_03_TORTURE_Teeth_Pulling, FBI_03_TORTURE_Teeth_Tooth_Out, FBI_03_TORTURE_Water_Pour_Water, FBI_03_TORTURE_Heart_Monitor_Single, FBI_03_TORTURE_Heart_Monitor_Flatline.
FBI_03_Torture_Sounds là soundset ở một số lệnh, ví dụ Teeth_Initial_Pain. Bank, sound name, soundset khác nhau; không dùng một chuỗi chung cho cả ba. Một số sound của script gốc truyền soundset NULL. Cần thử RequestScriptAudioBank, GetSoundId, PlaySoundFromEntity / PlaySoundFromCoord, StopSound, ReleaseSoundId trên build đang dùng.

## Native cần tra
| Nhóm | Functions |
|---|---|
| Load | DoesAnimDictExist, RequestAnimDict, HasAnimDictLoaded, RemoveAnimDict, RequestModel, HasModelLoaded, IsModelInCdimage, IsModelValid, SetModelAsNoLongerNeeded |
| Network scene | NetworkCreateSynchronisedScene, NetworkAddPedToSynchronisedScene, NetworkAddEntityToSynchronisedScene, NetworkStartSynchronisedScene, NetworkStopSynchronisedScene, NetworkGetLocalSceneFromNetworkId |
| Local scene | CreateSynchronizedScene, TaskSynchronizedScene, PlaySynchronizedEntityAnim, StopSynchronizedEntityAnim, IsSynchronizedSceneRunning, GetSynchronizedScenePhase, GetSynchronizedSceneRate, SetSynchronizedScenePhase, SetSynchronizedSceneRate, SetSynchronizedSceneLooped, SetSynchronizedSceneHoldLastFrame |
| Placement | GetAnimInitialOffsetPosition, GetAnimInitialOffsetRotation, GetAnimDuration, SetEntityCoordsNoOffset, SetEntityRotation |
| Object | CreateObjectNoOffset, AttachEntityToEntity, DetachEntity, GetPedBoneIndex, SetEntityCollision, DeleteEntity |
| Ownership | NetworkGetNetworkIdFromEntity, NetworkGetEntityFromNetworkId, NetworkDoesEntityExistWithNetworkId, NetworkHasControlOfEntity, NetworkRequestControlOfEntity |
| Ped | TaskPlayAnim, TaskPlayAnimAdvanced, ClearPedTasks, SetBlockingOfNonTemporaryEvents, SetPedCanRagdoll, PlayFacialAnim |
| Camera | CreateCam, PlaySynchronizedCamAnim, StopCamAnim, RenderScriptCams, DestroyCam |
| Particle | RequestNamedPtfxAsset, HasNamedPtfxAssetLoaded, UseParticleFxAssetNextCall, StartParticleFxLoopedOnEntity, StartParticleFxLoopedOnPedBone, StartParticleFxNonLoopedOnEntity, StopParticleFxLooped |
| Audio | RequestScriptAudioBank, ReleaseScriptAudioBank, GetSoundId, PlaySoundFromEntity, PlaySoundFromCoord, StopSound, ReleaseSoundId |
| UI | RequestScaleformMovie, HasScaleformMovieLoaded, BeginScaleformMovieMethod, DrawScaleformMovieFullscreen, SetScaleformMovieAsNoLongerNeeded |

ECG_MONITOR và TEETH_PULLING là Scaleform được script khai báo. Sự tồn tại không đảm bảo API method nào; đọc các BeginScaleformMovieMethod trong script để port giao diện hoặc tự làm NUI.

## Flags và replication
Network synchronized scene flags khác TaskPlayAnim flags. 4 = DONT_INTERRUPT, 8 = ON_ABORT_STOP_SCENE, 16 = ABORT_ON_WEAPON_DAMAGE, 64 = LOOP_WITHIN_SCENE, 1024 = HIDE_WEAPON, 2048 = ABORT_ON_DEATH. Kết hợp bitwise theo hành vi cần, không copy 49 từ emote.
NetworkCreateSynchronisedScene có thứ tự cuối: phaseToStopScene, phaseToStartScene, animSpeed. holdLastFrame=true phải chủ động stop; looped=true bỏ qua holdLastFrame.

Với hai player: server cấp session/lock; kiểm tra khoảng cách, bucket và trạng thái; một coordinator dựng network scene và start đúng một lần. Ped player có owner riêng: xử lý owner-side task/quyền điều khiển và kiểm thử theo artifact; không giả định RequestControl luôn thành công. Camera/UI local cho từng participant. Client không tồn tại entity handle của client khác: truyền netId rồi resolve. Người không stream entity không thể lập tức phát scene. Bổ sung timeout, disconnect, chết, resource stop và khôi phục trạng thái đã thay đổi.
Freeze ghế khi đang muốn animate ghế có thể gây lệch. Không vừa attach dụng cụ vừa animate object đó. Không dùng player coords thay cho scene origin. Không restart scene mỗi frame. Không Wait cố định khi cần chuyển đúng phase; load mạng có độ trễ. Cần test male/female freemode và clothing clipping: asset gốc không bảo đảm khớp mọi ped.

## Code mẫu
Lua dưới đây là helper minh họa cho coordinator đã có quyền điều khiển các entity networked. Không phải resource multiplayer hoàn chỉnh. Hàm không tự chuyển owner remote player, không áp dụng damage và không tự quản lý session.

```lua
-- Client-side illustration; call once on the coordinator.
-- Requires networked entities controlled by this client.
local function loadDict(dict)
    if not DoesAnimDictExist(dict) then error('Invalid dict: ' .. dict) end
    RequestAnimDict(dict)
    local deadline = GetGameTimer() + 5000
    while not HasAnimDictLoaded(dict) do
        if GetGameTimer() > deadline then error('Anim dict timeout') end
        Wait(0)
    end
end

function StartWrenchScene(actor, victim, chair, wrench, origin, rotation)
    for _, entity in ipairs({actor, victim, chair, wrench}) do
        assert(DoesEntityExist(entity), 'Missing entity')
        assert(NetworkGetEntityIsNetworked(entity), 'Entity must be networked')
        assert(NetworkHasControlOfEntity(entity), 'Coordinator lacks control')
    end
    local dict = 'missfbi3_wrench'
    loadDict(dict)
    local scene = NetworkCreateSynchronisedScene(
        origin.x, origin.y, origin.z,
        rotation.x, rotation.y, rotation.z,
        2, true, false, 1.0, 0.0, 1.0
    )
    local flags = 4 | 8 | 1024
    NetworkAddPedToSynchronisedScene(actor, scene, dict,
        'wrench_attack_left_player', 8.0, -8.0, flags, 0, 1000.0, 0)
    NetworkAddPedToSynchronisedScene(victim, scene, dict,
        'wrench_attack_left_victim', 8.0, -8.0, flags, 0, 1000.0, 0)
    NetworkAddEntityToSynchronisedScene(chair, scene, dict,
        'wrench_attack_left_chair', 8.0, -8.0, 0)
    NetworkAddEntityToSynchronisedScene(wrench, scene, dict,
        'wrench_attack_left_wrench', 8.0, -8.0, 0)
    NetworkStartSynchronisedScene(scene)
    return scene
end

-- Resolve the network scene to a local handle before phase/camera natives.
function WaitForTortureScene(scene, timeoutMs)
    local deadline = GetGameTimer() + (timeoutMs or 15000)
    local observedRunning = false
    while GetGameTimer() < deadline do
        local localScene = NetworkGetLocalSceneFromNetworkId(scene)
        if localScene ~= -1 then
            local running = IsSynchronizedSceneRunning(localScene)
            if running then
                observedRunning = true
                if GetSynchronizedScenePhase(localScene) >= 0.99 then
                    return true
                end
            elseif observedRunning then
                return false, 'aborted'
            end
        end
        Wait(0)
    end
    return false, 'timeout'
end

-- Optional camera on the current participant's client only.
function StartTortureCamera(scene)
    local localScene = NetworkGetLocalSceneFromNetworkId(scene)
    if localScene == -1 then return nil end
    local cam = CreateCam('DEFAULT_ANIMATED_CAMERA', true)
    local ok = PlaySynchronizedCamAnim(cam, localScene,
        'wrench_attack_left_cam', 'missfbi3_wrench')
    if not ok then DestroyCam(cam, false); return nil end
    RenderScriptCams(true, false, 0, true, false)
    return cam
end

function StopTortureScene(scene, cam)
    if scene then NetworkStopSynchronisedScene(scene) end
    if cam and DoesCamExist(cam) then
        StopCamAnim(cam)
        RenderScriptCams(false, false, 0, true, false)
        DestroyCam(cam, false)
    end
    -- Delete only props owned by this session.
    -- Restore original ped/control/collision state through the session manager.
end

```

## Mapping lấy từ func_429
Các field giữ số gốc để không suy diễn sai: 1 player, 2 victim, 3 third ped, 4 camera, 5 main tool, 6 chair, 8 rag, 9/10 binding object hand_l/hand_r. Field 11–19 là các track prop trên trolley. Cần xem điều kiện attachment của func_428 trước khi dùng. Các flag là field nội bộ mission, không phải native flags.
```json
[
  {
    "id": 20,
    "dict": "MISSFBI3_electrocute",
    "fields": {},
    "flags": {}
  },
  {
    "id": 21,
    "dict": "MISSFBI3_electrocute",
    "fields": {
      "1": "Electrocute_Spark_Player",
      "2": "Electrocute_Spark_Victim",
      "3": "",
      "4": "Electrocute_Spark_Cam",
      "5": "Electrocute_Spark",
      "6": "",
      "7": "",
      "8": "",
      "9": "Electrocute_Spark_hand_l",
      "10": "Electrocute_Spark_hand_r"
    },
    "flags": {
      "24": "0"
    }
  },
  {
    "id": 22,
    "dict": "MISSFBI3_electrocute",
    "fields": {
      "1": "Electrocute_Both_Outro_Player",
      "2": "Electrocute_Both_Outro_Victim",
      "3": "",
      "4": "Electrocute_Both_Outro_Cam",
      "5": "Electrocute_Both_Outro",
      "6": "Electrocute_Both_Outro_Chair",
      "7": "",
      "8": "",
      "9": "Electrocute_Both_Outro_hand_l",
      "10": "Electrocute_Both_Outro_hand_r"
    },
    "flags": {
      "24": "1"
    }
  },
  {
    "id": 15,
    "dict": "MISSFBI3_TOOTHPULL",
    "fields": {
      "1": "Pull_Tooth_Idle_Player",
      "2": "Pull_Tooth_Idle_Victim",
      "3": "",
      "4": "Pull_Tooth_Idle_Cam",
      "5": "Pull_Tooth_Idle_Pliers",
      "6": "",
      "7": "",
      "8": "",
      "9": "Pull_Tooth_Idle_hand_l",
      "10": "Pull_Tooth_Idle_hand_r"
    },
    "flags": {
      "24": "0"
    }
  },
  {
    "id": 12,
    "dict": "MISSFBI3_TOOTHPULL",
    "fields": {
      "1": "Pull_Tooth_Intro_Player",
      "2": "Pull_Tooth_Intro_Victim",
      "3": "",
      "4": "Pull_Tooth_Intro_Cam",
      "5": "Pull_Tooth_Intro_Pliers",
      "6": "",
      "7": "",
      "8": "",
      "9": "Pull_Tooth_Intro_hand_l",
      "10": "Pull_Tooth_Intro_hand_r"
    },
    "flags": {
      "24": "0"
    }
  },
  {
    "id": 11,
    "dict": "MISSFBI3_TOOTHPULL",
    "fields": {
      "1": "Pull_Tooth_Loop_Weak_Player",
      "2": "Pull_Tooth_Loop_Weak_Victim",
      "3": "",
      "4": "Pull_Tooth_Loop_Weak_Cam",
      "5": "Pull_Tooth_Loop_Weak_Pliers",
      "6": "",
      "7": "",
      "8": "",
      "9": "Pull_Tooth_Loop_Weak_hand_l",
      "10": "Pull_Tooth_Loop_Weak_hand_r"
    },
    "flags": {
      "24": "0",
      "25": "1"
    }
  },
  {
    "id": 10,
    "dict": "MISSFBI3_TOOTHPULL",
    "fields": {
      "1": "Pull_Tooth_Loop_Player",
      "2": "Pull_Tooth_Loop_Victim",
      "3": "",
      "4": "Pull_Tooth_Loop_Cam",
      "5": "Pull_Tooth_Loop_Pliers",
      "6": "",
      "7": "",
      "8": "",
      "9": "Pull_Tooth_Loop_hand_l",
      "10": "Pull_Tooth_Loop_hand_r"
    },
    "flags": {
      "24": "0",
      "25": "1"
    }
  },
  {
    "id": 13,
    "dict": "MISSFBI3_TOOTHPULL",
    "fields": {
      "1": "Pull_Tooth_Outro_Player",
      "2": "Pull_Tooth_Outro_Victim",
      "3": "",
      "4": "Pull_Tooth_Outro_Cam",
      "5": "Pull_Tooth_Outro_Pliers",
      "6": "Pull_Tooth_Outro_Chair",
      "7": "",
      "8": "",
      "9": "Pull_Tooth_Outro_hand_l",
      "10": "Pull_Tooth_Outro_hand_r"
    },
    "flags": {
      "24": "0"
    }
  },
  {
    "id": 14,
    "dict": "MISSFBI3_TOOTHPULL",
    "fields": {
      "1": "Pull_Tooth_Outro_B_Player",
      "2": "Pull_Tooth_Outro_B_Victim",
      "3": "",
      "4": "Pull_Tooth_Outro_B_Cam",
      "5": "Pull_Tooth_Outro_B_Pliers",
      "6": "",
      "7": "",
      "8": "",
      "9": "Pull_Tooth_Outro_B_hand_l",
      "10": "Pull_Tooth_Outro_B_hand_r"
    },
    "flags": {
      "24": "0"
    }
  },
  {
    "id": 16,
    "dict": "MISSFBI3_TOOTHPULL",
    "fields": {
      "1": "Pull_Tooth_Ready_Intro_Player",
      "2": "Pull_Tooth_Ready_Intro_Victim",
      "3": "",
      "4": "Pull_Tooth_Ready_Intro_Cam",
      "5": "Pull_Tooth_Ready_Intro_Pliers",
      "6": "",
      "7": "",
      "8": "",
      "9": "Pull_Tooth_Ready_Intro_hand_l",
      "10": "Pull_Tooth_Ready_Intro_hand_r"
    },
    "flags": {
      "24": "0"
    }
  },
  {
    "id": 17,
    "dict": "MISSFBI3_TOOTHPULL",
    "fields": {
      "1": "Pull_Tooth_Ready_Loop_Player",
      "2": "Pull_Tooth_Ready_Loop_Victim",
      "3": "",
      "4": "Pull_Tooth_Ready_Loop_Cam",
      "5": "Pull_Tooth_Ready_Loop_Pliers",
      "6": "",
      "7": "",
      "8": "",
      "9": "Pull_Tooth_Ready_Loop_hand_l",
      "10": "Pull_Tooth_Ready_Loop_hand_r"
    },
    "flags": {
      "24": "0"
    }
  },
  {
    "id": 18,
    "dict": "MISSFBI3_TOOTHPULL",
    "fields": {
      "1": "Pull_Tooth_Ready_Outro_Player",
      "2": "Pull_Tooth_Ready_Outro_Victim",
      "3": "",
      "4": "Pull_Tooth_Ready_Outro_Cam",
      "5": "Pull_Tooth_Ready_Outro_Pliers",
      "6": "",
      "7": "",
      "8": "",
      "9": "Pull_Tooth_Ready_Outro_hand_l",
      "10": "Pull_Tooth_Ready_Outro_hand_r"
    },
    "flags": {
      "24": "0"
    }
  },
  {
    "id": 35,
    "dict": "MISSFBI3_SYRINGE",
    "fields": {
      "1": "Syringe_Idle_Player",
      "2": "flatline_loop_Victim",
      "3": "",
      "4": "Syringe_Idle_Cam",
      "5": "",
      "6": "flatline_loop_chair",
      "7": "",
      "8": "",
      "9": "flatline_loop_hand_l",
      "10": "flatline_loop_hand_r"
    },
    "flags": {
      "24": "1"
    }
  },
  {
    "id": 34,
    "dict": "MISSFBI3_SYRINGE",
    "fields": {
      "1": "Syringe_Use_Player",
      "2": "Syringe_Use_Victim",
      "3": "",
      "4": "Syringe_Use_Cam",
      "5": "",
      "6": "Syringe_Use_Chair",
      "7": "",
      "8": "",
      "9": "Syringe_Use_hand_l",
      "10": "Syringe_Use_hand_r"
    },
    "flags": {
      "24": "1"
    }
  },
  {
    "id": 26,
    "dict": "MISSFBI3_WATERBOARD",
    "fields": {
      "1": "Waterboard_kick_Player",
      "2": "Waterboard_Kick_Victim",
      "3": "",
      "4": "Waterboard_Kick_Cam",
      "5": "",
      "6": "Waterboard_Kick_Chair",
      "7": "",
      "8": "Waterboard_Kick_Rag",
      "9": "Waterboard_Kick_hand_l",
      "10": "Waterboard_Kick_hand_r"
    },
    "flags": {
      "24": "1"
    }
  },
  {
    "id": 27,
    "dict": "MISSFBI3_WATERBOARD",
    "fields": {
      "1": "Waterboard_Idle_Player",
      "2": "Waterboard_Idle_Victim",
      "3": "",
      "4": "Waterboard_Idle_Cam",
      "5": "",
      "6": "Waterboard_Idle_Chair",
      "7": "",
      "8": "Waterboard_Idle_Rag",
      "9": "Waterboard_Idle_hand_l",
      "10": "Waterboard_Idle_hand_r"
    },
    "flags": {
      "24": "0"
    }
  },
  {
    "id": 31,
    "dict": "MISSFBI3_WATERBOARD",
    "fields": {
      "1": "Waterboard_Loop_To_Ready_Player",
      "2": "Waterboard_Loop_Victim",
      "3": "",
      "4": "Waterboard_Loop_Cam",
      "5": "",
      "6": "Waterboard_Loop_Chair",
      "7": "",
      "8": "Waterboard_Loop_Rag",
      "9": "Waterboard_Loop_hand_l",
      "10": "Waterboard_Loop_hand_r"
    },
    "flags": {
      "24": "0",
      "22": "1"
    }
  },
  {
    "id": 32,
    "dict": "MISSFBI3_WATERBOARD",
    "fields": {
      "1": "Waterboard_Outro_Player",
      "2": "Waterboard_Outro_Victim",
      "3": "Waterboard_Outro_Steve",
      "4": "Waterboard_Outro_Cam",
      "5": "",
      "6": "Waterboard_Outro_Chair",
      "7": "",
      "8": "Waterboard_Outro_Rag",
      "9": "Waterboard_Outro_hand_l",
      "10": "Waterboard_Outro_hand_r"
    },
    "flags": {
      "24": "1"
    }
  },
  {
    "id": 29,
    "dict": "MISSFBI3_WATERBOARD",
    "fields": {
      "1": "Waterboard_Loop_Player",
      "2": "Waterboard_Loop_Victim",
      "3": "",
      "4": "Waterboard_Loop_Cam",
      "5": "",
      "6": "Waterboard_Loop_Chair",
      "7": "",
      "8": "Waterboard_Loop_Rag",
      "9": "Waterboard_Loop_hand_l",
      "10": "Waterboard_Loop_hand_r"
    },
    "flags": {
      "24": "1"
    }
  },
  {
    "id": 28,
    "dict": "MISSFBI3_WATERBOARD",
    "fields": {
      "1": "Waterboard_Ready_To_Loop_Player",
      "2": "Waterboard_Ready_Loop_Victim",
      "3": "",
      "4": "Waterboard_Ready_To_Loop_Cam",
      "5": "",
      "6": "Waterboard_Ready_Loop_Chair",
      "7": "",
      "8": "Waterboard_Ready_To_Loop_Rag",
      "9": "Waterboard_Ready_Loop_hand_l",
      "10": "Waterboard_Ready_Loop_hand_r"
    },
    "flags": {
      "24": "0",
      "22": "1"
    }
  },
  {
    "id": 30,
    "dict": "MISSFBI3_WATERBOARD",
    "fields": {
      "1": "Waterboard_Loop_To_Ready_Player",
      "2": "Waterboard_Ready_Loop_Victim",
      "3": "",
      "4": "Waterboard_Loop_To_Ready_Cam",
      "5": "",
      "6": "Waterboard_Ready_Loop_Chair",
      "7": "",
      "8": "Waterboard_Loop_To_Ready_Rag",
      "9": "Waterboard_Ready_Loop_hand_l",
      "10": "Waterboard_Ready_Loop_hand_r"
    },
    "flags": {
      "24": "1",
      "22": "1"
    }
  },
  {
    "id": 33,
    "dict": "MISSFBI3_WATERBOARD",
    "fields": {
      "1": "Waterboard_Ready_Loop_Player",
      "2": "Waterboard_Ready_Loop_Victim",
      "3": "",
      "4": "Waterboard_Ready_Loop_Cam",
      "5": "",
      "6": "Waterboard_Ready_Loop_Chair",
      "7": "",
      "8": "Waterboard_Ready_Loop_Rag",
      "9": "Waterboard_Ready_Loop_hand_l",
      "10": "Waterboard_Ready_Loop_hand_r"
    },
    "flags": {
      "24": "0"
    }
  },
  {
    "id": 9,
    "dict": "MISSFBI3_WRENCH",
    "fields": {
      "1": "Wrench_Idle_Player",
      "2": "Wrench_Idle_Victim",
      "3": "",
      "4": "Wrench_Idle_Cam",
      "5": "Wrench_Idle_Wrench",
      "6": "Wrench_Idle_Chair",
      "7": "",
      "8": "",
      "9": "Wrench_Idle_hand_l",
      "10": "Wrench_Idle_hand_r"
    },
    "flags": {
      "24": "1",
      "23": "0"
    }
  },
  {
    "id": 6,
    "dict": "MISSFBI3_WRENCH",
    "fields": {
      "1": "Wrench_Attack_Left_Player",
      "2": "Wrench_Attack_Left_Victim",
      "3": "",
      "4": "Wrench_Attack_Left_Cam",
      "5": "Wrench_Attack_Left_Wrench",
      "6": "Wrench_Attack_Left_Chair",
      "7": "",
      "8": "",
      "9": "Wrench_Attack_Left_hand_l",
      "10": "Wrench_Attack_Left_hand_r"
    },
    "flags": {
      "24": "1",
      "23": "0"
    }
  },
  {
    "id": 7,
    "dict": "MISSFBI3_WRENCH",
    "fields": {
      "1": "Wrench_Attack_Mid_Player",
      "2": "Wrench_Attack_Mid_Victim",
      "3": "",
      "4": "Wrench_Attack_Mid_Cam",
      "5": "Wrench_Attack_Mid_Wrench",
      "6": "Wrench_Attack_Mid_Chair",
      "7": "",
      "8": "",
      "9": "Wrench_Attack_Mid_hand_l",
      "10": "Wrench_Attack_Mid_hand_r"
    },
    "flags": {
      "24": "1",
      "23": "0"
    }
  },
  {
    "id": 8,
    "dict": "MISSFBI3_WRENCH",
    "fields": {
      "1": "Wrench_Attack_Right_Player",
      "2": "Wrench_Attack_Right_Victim",
      "3": "",
      "4": "Wrench_Attack_Right_Cam",
      "5": "Wrench_Attack_Right_Wrench",
      "6": "Wrench_Attack_Right_Chair",
      "7": "",
      "8": "",
      "9": "Wrench_Attack_Right_hand_l",
      "10": "Wrench_Attack_Right_hand_r"
    },
    "flags": {
      "24": "1",
      "23": "0"
    }
  },
  {
    "id": 0,
    "dict": "MISSFBI3_WEAPON_SELECT",
    "fields": {
      "1": "Weapon_Select_Loop",
      "2": "waterboard_idle_victim",
      "3": "",
      "4": "",
      "5": "",
      "6": "waterboard_idle_chair",
      "7": "",
      "8": "",
      "9": "waterboard_idle_hand_l",
      "10": "waterboard_idle_hand_r",
      "11": "weapon_select_bench_wrench",
      "12": "weapon_select_bench_clip1",
      "13": "weapon_select_bench_clip2",
      "14": "weapon_select_bench_can",
      "15": "weapon_select_bench_pliers",
      "16": "weapon_select_bench_battery",
      "17": "weapon_select_bench_bench",
      "18": "weapon_select_bench_syringe",
      "19": "weapon_select_bench_rag"
    },
    "flags": {
      "21": "1",
      "22": "0",
      "24": "1",
      "23": "0"
    }
  },
  {
    "id": 3,
    "dict": "MISSFBI3_WEAPON_SELECT",
    "fields": {
      "1": "Weapon_Select_Electrocute_Player",
      "2": "waterboard_idle_Victim",
      "3": "",
      "4": "Weapon_Select_Electrocute_Cam",
      "5": "Weapon_Select_Electrocute",
      "6": "waterboard_idle_chair",
      "7": "",
      "8": "",
      "9": "waterboard_idle_hand_l",
      "10": "waterboard_idle_hand_r"
    },
    "flags": {
      "21": "0",
      "22": "1",
      "24": "1",
      "23": "0"
    }
  },
  {
    "id": 2,
    "dict": "MISSFBI3_WEAPON_SELECT",
    "fields": {
      "1": "Weapon_Select_Pliers_Player",
      "2": "weapon_select_pliers_victim",
      "3": "",
      "4": "Weapon_Select_Pliers_Cam",
      "5": "Weapon_Select_Pliers_Pliers",
      "6": "",
      "7": "",
      "8": "",
      "9": "Weapon_Select_Pliers_hand_l",
      "10": "Weapon_Select_Pliers_hand_r",
      "11": "weapon_bench_toothpull_wrench",
      "12": "weapon_bench_toothpull_clip1",
      "13": "weapon_bench_toothpull_clip2",
      "14": "weapon_bench_toothpull_can",
      "15": "",
      "16": "weapon_bench_toothpull_battery",
      "17": "weapon_bench_toothpull_trolley",
      "18": "weapon_bench_toothpull_syringe",
      "19": "weapon_bench_toothpull_rag"
    },
    "flags": {
      "21": "0",
      "22": "0",
      "24": "1",
      "23": "0"
    }
  },
  {
    "id": 5,
    "dict": "MISSFBI3_SYRINGE",
    "fields": {
      "1": "Weapon_Select_Syringe_Player",
      "2": "flatline_intro_victim",
      "3": "",
      "4": "Weapon_Select_Syringe_Cam",
      "5": "",
      "6": "flatline_intro_chair",
      "7": "",
      "8": "",
      "9": "flatline_intro_hand_l",
      "10": "flatline_intro_hand_r",
      "11": "weapon_bench_syringe_wrench",
      "12": "weapon_bench_syringe_clip1",
      "13": "weapon_bench_syringe_clip2",
      "14": "weapon_bench_syringe_can",
      "15": "weapon_bench_syringe_pliers",
      "16": "weapon_bench_syringe_battery",
      "17": "weapon_bench_syringe_trolley",
      "18": "",
      "19": "weapon_bench_syringe_rag"
    },
    "flags": {
      "21": "0",
      "22": "0",
      "25": "0",
      "23": "1"
    }
  },
  {
    "id": 4,
    "dict": "MISSFBI3_WEAPON_SELECT",
    "fields": {
      "1": "Weapon_Select_Waterboard_Player",
      "2": "waterboard_idle_victim",
      "3": "",
      "4": "Weapon_Select_Waterboard_Cam",
      "5": "Weapon_Select_Waterboard_jerryCan",
      "6": "waterboard_idle_chair",
      "7": "",
      "8": "Weapon_Select_Waterboard_rag",
      "9": "waterboard_idle_hand_l",
      "10": "waterboard_idle_hand_r",
      "11": "weapon_bench_waterboard_wrench",
      "12": "weapon_bench_waterboard_clip1",
      "13": "weapon_bench_waterboard_clip2",
      "14": "",
      "15": "weapon_bench_waterboard_pliers",
      "16": "weapon_bench_waterboard_battery",
      "17": "weapon_bench_waterboard_trolley",
      "18": "weapon_bench_waterboard_syringe",
      "19": ""
    },
    "flags": {
      "21": "0",
      "22": "1",
      "24": "1",
      "23": "0"
    }
  },
  {
    "id": 1,
    "dict": "MISSFBI3_WEAPON_SELECT",
    "fields": {
      "1": "Weapon_Select_Wrench_Player",
      "2": "waterboard_idle_victim",
      "3": "",
      "4": "Weapon_Select_Wrench_Cam",
      "5": "Weapon_Select_Wrench_Wrench",
      "6": "waterboard_idle_chair",
      "7": "",
      "8": "",
      "9": "waterboard_idle_hand_l",
      "10": "waterboard_idle_hand_r",
      "11": "",
      "12": "weapon_bench_wrench_clip1",
      "13": "weapon_bench_wrench_clip2",
      "14": "weapon_bench_wrench_can",
      "15": "weapon_bench_wrench_pliers",
      "16": "weapon_bench_wrench_battery",
      "17": "weapon_bench_wrench_trolley",
      "18": "weapon_bench_wrench_syringe",
      "19": "weapon_bench_wrench_rag"
    },
    "flags": {
      "21": "0",
      "22": "1",
      "24": "1",
      "23": "0"
    }
  }
]
```

## Toàn bộ clip trong 8 dictionary trọng tâm

### missfbi3_electrocute (104 clips)
```text
clamp_both_idle_cam
clamp_both_idle_chair
clamp_both_idle_hand_l
clamp_both_idle_hand_r
clamp_both_idle_victim
clamp_left_intro_cam
clamp_left_intro_chair
clamp_left_intro_hand_l
clamp_left_intro_hand_r
clamp_left_intro_l_clip
clamp_left_intro_player
clamp_left_intro_r_clip
clamp_left_intro_victim
clamp_left_loop_cam
clamp_left_loop_chair
clamp_left_loop_hand_l
clamp_left_loop_hand_r
clamp_left_loop_l_clip
clamp_left_loop_player
clamp_left_loop_r_clip
clamp_left_loop_victim
clamp_left_loop_victim_facial
clamp_right_intro_cam
clamp_right_intro_chair
clamp_right_intro_hand_l
clamp_right_intro_hand_r
clamp_right_intro_l_clip
clamp_right_intro_player
clamp_right_intro_r_clip
clamp_right_intro_victim
clamp_right_loop_cam
clamp_right_loop_chair
clamp_right_loop_hand_l
clamp_right_loop_hand_r
clamp_right_loop_l_clip
clamp_right_loop_player
clamp_right_loop_r_clip
clamp_right_loop_victim
clamp_right_loop_victim_facial
clamp_wait_loop_cam
clamp_wait_loop_chair
clamp_wait_loop_hand_l
clamp_wait_loop_hand_r
clamp_wait_loop_l_clip
clamp_wait_loop_player
clamp_wait_loop_r_clip
clamp_wait_loop_victim
clamp_wait_loop_victim_facial
electrocute_both_intro_cam
electrocute_both_intro_chair
electrocute_both_intro_hand_l
electrocute_both_intro_hand_r
electrocute_both_intro_l_clip
electrocute_both_intro_player
electrocute_both_intro_r_clip
electrocute_both_intro_victim
electrocute_both_loop_cam
electrocute_both_loop_chair
electrocute_both_loop_hand_l
electrocute_both_loop_hand_r
electrocute_both_loop_l_clip
electrocute_both_loop_player
electrocute_both_loop_r_clip
electrocute_both_loop_victim
electrocute_both_loop_victim_facial
electrocute_both_outro_cam
electrocute_both_outro_chair
electrocute_both_outro_hand_l
electrocute_both_outro_hand_r
electrocute_both_outro_l_clip
electrocute_both_outro_player
electrocute_both_outro_r_clip
electrocute_both_outro_victim
electrocute_both_outro_victim_facial
electrocute_left_intro_cam
electrocute_left_intro_chair
electrocute_left_intro_hand_l
electrocute_left_intro_hand_r
electrocute_left_intro_l_clip
electrocute_left_intro_player
electrocute_left_intro_r_clip
electrocute_left_intro_victim
electrocute_left_intro_victim_facial
electrocute_right_intro_cam
electrocute_right_intro_chair
electrocute_right_intro_hand_l
electrocute_right_intro_hand_r
electrocute_right_intro_l_clip
electrocute_right_intro_player
electrocute_right_intro_player_facial
electrocute_right_intro_r_clip
electrocute_right_intro_victim
electrocute_right_intro_victim_facial
electrocute_spark_cam
electrocute_spark_chair
electrocute_spark_hand_l
electrocute_spark_hand_r
electrocute_spark_l_clip
electrocute_spark_player
electrocute_spark_player_facial
electrocute_spark_playerface
electrocute_spark_r_clip
electrocute_spark_victim
electrocute_spark_victim_facial
```

### missfbi3_rag (1 clips)
```text
weapon_select_loop_rag
```

### missfbi3_syringe (42 clips)
```text
flatline_intro_cam
flatline_intro_chair
flatline_intro_hand_l
flatline_intro_hand_r
flatline_intro_player
flatline_intro_victim
flatline_intro_victim_facial
flatline_loop_cam
flatline_loop_chair
flatline_loop_hand_l
flatline_loop_hand_r
flatline_loop_player
flatline_loop_victim
flatline_loop_victim_facial
syringe_idle_cam
syringe_idle_chair
syringe_idle_hand_l
syringe_idle_hand_r
syringe_idle_player
syringe_idle_player_facial
syringe_idle_trolley
syringe_idle_victim
syringe_idle_victim_chair
syringe_idle_victim_hand_l
syringe_idle_victim_hand_r
syringe_use_cam
syringe_use_chair
syringe_use_hand_l
syringe_use_hand_r
syringe_use_player
syringe_use_player_facial
syringe_use_trolley
syringe_use_victim
syringe_use_victim_facial
weapon_select_syringe_cam
weapon_select_syringe_chair
weapon_select_syringe_hand_l
weapon_select_syringe_hand_r
weapon_select_syringe_player
weapon_select_syringe_player_facial
weapon_select_syringe_trolley
weapon_select_syringe_victim
```

### missfbi3_toothpull (77 clips)
```text
pull_tooth_idle_cam
pull_tooth_idle_hand_l
pull_tooth_idle_hand_r
pull_tooth_idle_player
pull_tooth_idle_player_facial
pull_tooth_idle_pliers
pull_tooth_idle_victim
pull_tooth_idle_victim_facial
pull_tooth_intro_cam
pull_tooth_intro_hand_l
pull_tooth_intro_hand_r
pull_tooth_intro_player
pull_tooth_intro_player_facial
pull_tooth_intro_pliers
pull_tooth_intro_victim
pull_tooth_intro_victim_facial
pull_tooth_loop_cam
pull_tooth_loop_hand_l
pull_tooth_loop_hand_r
pull_tooth_loop_player
pull_tooth_loop_player_facial
pull_tooth_loop_pliers
pull_tooth_loop_victim
pull_tooth_loop_victim_facial
pull_tooth_loop_weak_cam
pull_tooth_loop_weak_hand_l
pull_tooth_loop_weak_hand_r
pull_tooth_loop_weak_old_cam
pull_tooth_loop_weak_old_hand_l
pull_tooth_loop_weak_old_hand_r
pull_tooth_loop_weak_old_pliers
pull_tooth_loop_weak_player
pull_tooth_loop_weak_player_facial
pull_tooth_loop_weak_pliers
pull_tooth_loop_weak_victim
pull_tooth_loop_weak_victim_facial
pull_tooth_outro_b_cam
pull_tooth_outro_b_hand_l
pull_tooth_outro_b_hand_r
pull_tooth_outro_b_player
pull_tooth_outro_b_player_facial
pull_tooth_outro_b_pliers
pull_tooth_outro_b_victim
pull_tooth_outro_b_victim_facial
pull_tooth_outro_cam
pull_tooth_outro_chair
pull_tooth_outro_hand_l
pull_tooth_outro_hand_r
pull_tooth_outro_player
pull_tooth_outro_player_facial
pull_tooth_outro_pliers
pull_tooth_outro_victim
pull_tooth_outro_victim_facial
pull_tooth_ready_intro_cam
pull_tooth_ready_intro_hand_l
pull_tooth_ready_intro_hand_r
pull_tooth_ready_intro_player
pull_tooth_ready_intro_player_facial
pull_tooth_ready_intro_pliers
pull_tooth_ready_intro_victim
pull_tooth_ready_intro_victim_facial
pull_tooth_ready_loop_cam
pull_tooth_ready_loop_hand_l
pull_tooth_ready_loop_hand_r
pull_tooth_ready_loop_player
pull_tooth_ready_loop_player_facial
pull_tooth_ready_loop_pliers
pull_tooth_ready_loop_victim
pull_tooth_ready_loop_victim_facial
pull_tooth_ready_outro_cam
pull_tooth_ready_outro_hand_l
pull_tooth_ready_outro_hand_r
pull_tooth_ready_outro_player
pull_tooth_ready_outro_player_facial
pull_tooth_ready_outro_pliers
pull_tooth_ready_outro_victim
pull_tooth_ready_outro_victim_facial
```

### missfbi3_waterboard (90 clips)
```text
waterboard_idle_cam
waterboard_idle_chair
waterboard_idle_hand_l
waterboard_idle_hand_r
waterboard_idle_jerrycan
waterboard_idle_player
waterboard_idle_player_facial
waterboard_idle_rag
waterboard_idle_victim
waterboard_idle_victim_facial
waterboard_kick_cam
waterboard_kick_chair
waterboard_kick_hand_l
waterboard_kick_hand_r
waterboard_kick_jerrycan
waterboard_kick_player
waterboard_kick_player_facial
waterboard_kick_playerface
waterboard_kick_rag
waterboard_kick_victim
waterboard_kick_victim_facial
waterboard_loop_cam
waterboard_loop_chair
waterboard_loop_hand_l
waterboard_loop_hand_r
waterboard_loop_jerrycan
waterboard_loop_player
waterboard_loop_player_facial
waterboard_loop_rag
waterboard_loop_to_ready_cam
waterboard_loop_to_ready_chair
waterboard_loop_to_ready_hand_l
waterboard_loop_to_ready_hand_r
waterboard_loop_to_ready_jerrycan
waterboard_loop_to_ready_player
waterboard_loop_to_ready_player_facial
waterboard_loop_to_ready_rag
waterboard_loop_to_ready_victim
waterboard_loop_to_ready_victim_facial
waterboard_loop_victim
waterboard_loop_victim_facial
waterboard_outro_cam
waterboard_outro_chair
waterboard_outro_full_cam
waterboard_outro_full_rag
waterboard_outro_full_victim
waterboard_outro_hand_l
waterboard_outro_hand_r
waterboard_outro_jerrycan
waterboard_outro_player
waterboard_outro_player_facial
waterboard_outro_rag
waterboard_outro_steve
waterboard_outro_victim
waterboard_outro_victim_facial
waterboard_ready_loop_cam
waterboard_ready_loop_chair
waterboard_ready_loop_hand_l
waterboard_ready_loop_hand_r
waterboard_ready_loop_jerrycan
waterboard_ready_loop_player
waterboard_ready_loop_player_facial
waterboard_ready_loop_rag
waterboard_ready_loop_victim
waterboard_ready_loop_victim_facial
waterboard_ready_to_loop_cam
waterboard_ready_to_loop_chair
waterboard_ready_to_loop_hand_l
waterboard_ready_to_loop_hand_r
waterboard_ready_to_loop_jerrycan
waterboard_ready_to_loop_player
waterboard_ready_to_loop_player_facial
waterboard_ready_to_loop_rag
waterboard_ready_to_loop_victim
waterboard_ready_to_loop_victim_facial
weapon_bench_waterboard_battery
weapon_bench_waterboard_can
weapon_bench_waterboard_clip1
weapon_bench_waterboard_clip2
weapon_bench_waterboard_pliers
weapon_bench_waterboard_trolley
weapon_bench_waterboard_victim
weapon_bench_waterboard_wrench
weapon_select_waterboard_cam
weapon_select_waterboard_chair
weapon_select_waterboard_hand_l
weapon_select_waterboard_hand_r
weapon_select_waterboard_jerrycan
weapon_select_waterboard_player
weapon_select_waterboard_victim
```

### missfbi3_weapon_select (63 clips)
```text
waterboard_idle_cam
waterboard_idle_chair
waterboard_idle_hand_l
waterboard_idle_hand_r
waterboard_idle_jerrycan
waterboard_idle_player
waterboard_idle_player_facial
waterboard_idle_rag
waterboard_idle_victim
waterboard_idle_victim_facial
weapon_select_bench_battery
weapon_select_bench_bench
weapon_select_bench_can
weapon_select_bench_clip1
weapon_select_bench_clip2
weapon_select_bench_clip_l
weapon_select_bench_clip_r
weapon_select_bench_pliers
weapon_select_bench_rag
weapon_select_bench_syringe
weapon_select_bench_wrench
weapon_select_electrocute_cam
weapon_select_electrocute_chair
weapon_select_electrocute_hand_l
weapon_select_electrocute_hand_r
weapon_select_electrocute_l_clip
weapon_select_electrocute_player
weapon_select_electrocute_player_facial
weapon_select_electrocute_r_clip
weapon_select_electrocute_victim
weapon_select_loop
weapon_select_loop_rag
weapon_select_pliers_cam
weapon_select_pliers_hand_l
weapon_select_pliers_hand_r
weapon_select_pliers_player
weapon_select_pliers_player_facial
weapon_select_pliers_pliers
weapon_select_pliers_victim
weapon_select_pliers_victim_facial
weapon_select_syringe_cam
weapon_select_syringe_hand_l
weapon_select_syringe_hand_r
weapon_select_syringe_player_facial
weapon_select_waterboard_cam
weapon_select_waterboard_chair
weapon_select_waterboard_hand_l
weapon_select_waterboard_hand_r
weapon_select_waterboard_jerrycan
weapon_select_waterboard_player
weapon_select_waterboard_player_facial
weapon_select_waterboard_rag
weapon_select_waterboard_victim
weapon_select_waterboard_victim_facial
weapon_select_wrench_cam
weapon_select_wrench_chair
weapon_select_wrench_hand_l
weapon_select_wrench_hand_r
weapon_select_wrench_player
weapon_select_wrench_player_facial
weapon_select_wrench_victim
weapon_select_wrench_victim_facial
weapon_select_wrench_wrench
```

### missfbi3_weapon_select_trolley (35 clips)
```text
weapon_bench_syringe_battery
weapon_bench_syringe_can
weapon_bench_syringe_clip1
weapon_bench_syringe_clip2
weapon_bench_syringe_pliers
weapon_bench_syringe_rag
weapon_bench_syringe_trolley
weapon_bench_syringe_wrench
weapon_bench_toothpull_battery
weapon_bench_toothpull_can
weapon_bench_toothpull_clip1
weapon_bench_toothpull_clip2
weapon_bench_toothpull_pliers
weapon_bench_toothpull_rag
weapon_bench_toothpull_syringe
weapon_bench_toothpull_trolley
weapon_bench_toothpull_wrench
weapon_bench_waterboard_battery
weapon_bench_waterboard_can
weapon_bench_waterboard_clip1
weapon_bench_waterboard_clip2
weapon_bench_waterboard_pliers
weapon_bench_waterboard_syringe
weapon_bench_waterboard_trolley
weapon_bench_waterboard_victim
weapon_bench_waterboard_wrench
weapon_bench_wrench_battery
weapon_bench_wrench_can
weapon_bench_wrench_clip1
weapon_bench_wrench_clip2
weapon_bench_wrench_pliers
weapon_bench_wrench_rag
weapon_bench_wrench_syringe
weapon_bench_wrench_trolley
weapon_bench_wrench_wrench
```

### missfbi3_wrench (37 clips)
```text
waterboard_idle_cam
waterboard_idle_player
wrench_attack_left_cam
wrench_attack_left_chair
wrench_attack_left_hand_l
wrench_attack_left_hand_r
wrench_attack_left_player
wrench_attack_left_player_facial
wrench_attack_left_victim
wrench_attack_left_victim_facial
wrench_attack_left_wrench
wrench_attack_mid_cam
wrench_attack_mid_chair
wrench_attack_mid_hand_l
wrench_attack_mid_hand_r
wrench_attack_mid_player
wrench_attack_mid_player_facial
wrench_attack_mid_victim
wrench_attack_mid_victim_facial
wrench_attack_mid_wrench
wrench_attack_right_cam
wrench_attack_right_chair
wrench_attack_right_hand_l
wrench_attack_right_hand_r
wrench_attack_right_player
wrench_attack_right_player_facial
wrench_attack_right_victim
wrench_attack_right_victim_facial
wrench_attack_right_wrench
wrench_idle_cam
wrench_idle_chair
wrench_idle_hand_l
wrench_idle_hand_r
wrench_idle_player
wrench_idle_player_facial
wrench_idle_victim
wrench_idle_wrench
```

## Giới hạn xác minh
Đã kiểm tra dữ liệu/mapping tĩnh, chưa chạy scene trong FiveM. Không có full source của các resource escrow thương mại. Có thể còn asset custom/DLC hoặc cutscene khác ngoài nhóm FBI3. Không phân loại các dictionary missfbi3_party/camcrew/sniping thành torture chỉ vì chúng có cùng prefix.
