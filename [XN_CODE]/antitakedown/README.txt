UNDERSTAR MELEE GUARD V1.8.2
=============================

WEAPONS
-------
- WEAPON_WRENCH
- WEAPON_BAT
- WEAPON_CROWBAR
- WEAPON_HATCHET

FIX V1.8.2
----------
Log V1.8.1 cho thấy đôi lúc:

    NATIVE SWING - NO TARGET WEAPON_WRENCH

sau đó các cú kế tiếp lại bắt NPC bình thường.

=> weapon detection đã đúng.
=> reset flags vẫn active.
=> vấn đề là GTA native target có thể trả 0 trong vài frame đầu.

V1.8.2 thêm RECENT NATIVE TARGET CACHE.

CƠ CHẾ
------
Chỉ nhớ target mà GTA vừa trả về từ:

    GetPlayerTargetEntity
    GetMeleeTargetForPed

Không:
    GetActivePlayers
    GetGamePool
    shape-test scan
    tìm player gần nhất
    tìm NPC gần nhất

Nếu bấm melee và trong TargetAcquireMs vẫn chưa thấy target:

    lấy recent native target

chỉ khi:
    age <= 320ms
    entity vẫn tồn tại
    chưa chết
    distance <= 5.50m

Log khi fallback:

    RECENT TARGET FALLBACK
    WEAPON_WRENCH
    <entity>
    ageMs=...
    source=RECENT_MELEE / RECENT_LOCKON

ANTI TAKEDOWN
-------------
Giữ nguyên Reset Flags V1.8:

Attacker:
    155 SuppressLethalMeleeActions
    438 SuppressTakedownMeleeActions

Victim:
    187 PreventAllMeleeTakedowns
    457 PreventAllStealthKills

ANTI BORROW TARGET
------------------
Giữ nguyên:
    CPED_CONFIG_FLAG_DontChangeTargetFromMelee = 458

và snapshot target.
Nếu GTA đổi target:
    TARGET CHANGED - CANCEL

DAMAGE
------
Không pre-shield.
Không invincible normal hit.
Không scripted damage.

PERFORMANCE
-----------
Recent cache chỉ gồm:
    entity handle
    timestamp
    source

Không scan entity pool.
Wait(0) vẫn chỉ khi đang cầm guarded weapon / victim guard lease.

INSTALL
-------
stop understar_melee_guard_v1_8_1_weapon_detect_fix

ensure ox_inventory
ensure understar_melee_guard_v1_8_2_recent_target

Prefix:
    [understar_melee_guard_v1_8_2]
