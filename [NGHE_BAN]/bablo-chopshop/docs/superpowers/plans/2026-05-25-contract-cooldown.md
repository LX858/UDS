# Contract Cooldown Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add an optional in-memory cooldown that prevents players from requesting new contracts more than once per configurable interval (default: 30 minutes).

**Architecture:** A `contractCooldowns` local table on the server tracks `identifier → timestamp`. Two new helpers on `Main` check and stamp the cooldown. The `giveContract` callback enforces the gate server-side before issuing any contract item. Config flag is `false` by default so existing servers are unaffected until explicitly enabled.

**Tech Stack:** Lua 5.4, FiveM server runtime, QBCore/ESX/QBox framework abstraction already in place.

---

### Task 1: Add config block

**Files:**
- Modify: `config.lua` (after the closing `}` of `Config.Contracts`, before `Config.Rewards`)

- [ ] **Step 1: Open `config.lua` and locate the end of `Config.Contracts`**

  The block ends at line ~400 with `}`. Add the following block directly below it (before `Config.Rewards`):

```lua
--[[
    ContractCooldown - Prevents players from requesting contracts too quickly.

    enabled  : Set to true to activate the cooldown. Default: false (off).
    cooldown : Time in seconds a player must wait between contracts.
               1800 = 30 minutes. 600 = 10 minutes. 3600 = 1 hour.
]]
Config.ContractCooldown = {
    enabled  = false,
    cooldown = 1800,
}
```

- [ ] **Step 2: Verify the file parses without error**

  Start the resource (`ensure bablo-chopshop` in the server console) and confirm no Lua syntax errors appear. The feature will be invisible until `enabled = true`.

---

### Task 2: Add in-memory cooldown helpers to `Main`

**Files:**
- Modify: `src/resource/server/s_funcs.lua` (append to bottom of file)

- [ ] **Step 1: Open `src/resource/server/s_funcs.lua` and scroll to the very end (line ~246)**

  Append the following block after the last existing function:

```lua
-- ─────────────────────────────────────────────────────────────
-- Contract cooldown (in-memory, resets on server restart)
-- ─────────────────────────────────────────────────────────────
local contractCooldowns = {} -- [identifier] = os.time() stamp

---Returns whether a player is allowed to get a new contract.
---@param identifier string  The player's unique identifier (citizenid / license / etc.)
---@return table { allowed: boolean, remaining: number? }
function Main:canGetContract(identifier)
    if not Config.ContractCooldown or not Config.ContractCooldown.enabled then
        return { allowed = true }
    end

    if not identifier then
        return { allowed = true } -- fail-open if identifier is missing
    end

    local now      = os.time()
    local lastTime = contractCooldowns[identifier]

    if lastTime then
        local remaining = Config.ContractCooldown.cooldown - (now - lastTime)
        if remaining > 0 then
            return { allowed = false, remaining = math.ceil(remaining) }
        end
    end

    return { allowed = true }
end

---Stamps the current time as the player's last contract acquisition.
---No-ops when cooldown is disabled.
---@param identifier string
function Main:setContractCooldown(identifier)
    if not Config.ContractCooldown or not Config.ContractCooldown.enabled then
        return
    end
    contractCooldowns[identifier] = os.time()
end
```

- [ ] **Step 2: Verify no syntax error**

  Restart the resource and confirm the server console shows no errors.

- [ ] **Step 3: Quick smoke-test in server console (optional)**

  Run in F8/txAdmin console:
  ```
  lua_run_file bablo-chopshop print(json.encode(Main:canGetContract("test123")))
  ```
  Expected output: `{"allowed":true}`

---

### Task 3: Add locale string

**Files:**
- Modify: `locales/en-US.lua` (inside the `Locales['en-US']` table)

- [ ] **Step 1: Open `locales/en-US.lua` and add before the closing `}`**

```lua
    ["CONTRACT_COOLDOWN"] = "You must wait %s before getting a new contract.",
```

  The `%s` will be replaced with a human-readable time like `"29 min 42 sec"` or `"45 sec"`.

---

### Task 4: Enforce cooldown in `giveContract` callback

**Files:**
- Modify: `src/resource/server/s_callbacks.lua:180-271`

This task refactors the `giveContract` callback to:
1. Fetch `identifier` once at the top (currently only fetched inside the level-check block).
2. Add the cooldown gate right after basic validation.
3. Reuse `identifier` for the existing level check.
4. Stamp the cooldown after the contract item is successfully added.

- [ ] **Step 1: Replace the existing `giveContract` body**

  Find the full `giveContract` callback (starts at `eventName .. 'server:giveContract'`, line ~180). Replace the **entire inner body** with the version below. The outer `RegisterServerCallback({ ... })` wrapper stays the same.

```lua
RegisterServerCallback({
    eventName = eventName .. 'server:giveContract',
    eventCallback = function(source, contractType)
        local character = Framework:fetchPlayer(source)

        if not character then
            return {
                status  = false,
                message = 'Character not found'
            }
        end

        local contract = Config.Contracts[contractType]
        if not contract then
            return {
                status  = false,
                message = 'Invalid contract type'
            }
        end

        -- Fetch identifier once — used for cooldown check and level check below
        local identifier = Framework:getIdentifier(source)
        if not identifier then
            return { status = false, message = 'Identifier not found' }
        end

        -- ── Cooldown gate ──────────────────────────────────────────────
        local cooldownCheck = Main:canGetContract(identifier)
        if not cooldownCheck.allowed then
            local remaining = cooldownCheck.remaining
            local mins      = math.floor(remaining / 60)
            local secs      = remaining % 60
            local timeStr   = mins > 0
                and string.format("%d min %d sec", mins, secs)
                or  string.format("%d sec", secs)
            return {
                status  = false,
                message = string.format(Translate('CONTRACT_COOLDOWN'), timeStr)
            }
        end
        -- ──────────────────────────────────────────────────────────────

        -- Check level requirement
        local minLevel = contract.minLevelRequired or 1
        if minLevel > 1 then
            local reputation = Reputation.Get(identifier)
            if reputation.success then
                local playerLevel = reputation.data.level or 1
                if playerLevel < minLevel then
                    return {
                        status  = false,
                        message = string.format(Translate('CONTRACT_LOCKED_LEVEL'), minLevel)
                    }
                end
            end
        end

        local shuffledVehicles = {}
        for _, v in ipairs(contract.vehicles) do
            table.insert(shuffledVehicles, v)
        end
        Shuffle(shuffledVehicles)

        local count = math.random(contract.min, math.min(contract.max, #shuffledVehicles))

        local vehicles_list = {}
        for i = 1, count do
            vehicles_list[shuffledVehicles[i]] = "ON_GOING"
        end

        local labels = {}
        for vehicle, _ in pairs(vehicles_list) do
            local label = Main.globalVehicles[vehicle] or vehicle
            table.insert(labels, label)
        end

        local vehicle_labels = table.concat(labels, ", ")
        local vehCount       = TableLength(vehicles_list)

        local item = {
            name   = "bchop_contract",
            amount = 1,
            metadata = {
                vehicles           = vehicles_list,
                completed_vehicles = {},
                vehicle_count      = vehCount,
                original_count     = vehCount,
                vehicle_labels     = vehicle_labels,
                display            = false,
            }
        }

        Inventory:addPlayerItem(
            source,
            item.name,
            item.amount,
            item.metadata,
            { label = contract.label }
        )

        -- Stamp the cooldown AFTER successful item grant
        Main:setContractCooldown(identifier)

        sendWebhook(source, 'RECEIVED_CONTRACT', contract.label)

        return {
            status       = true,
            message      = 'Contract given successfully',
            vehicleModel = vehCount == 1 and shuffledVehicles[1] or nil,
        }
    end
})
```

- [ ] **Step 2: Restart the resource and verify no errors**

  ```
  ensure bablo-chopshop
  ```
  Server console must show no Lua errors.

---

### Task 5: End-to-end manual test

- [ ] **Step 1: Test with cooldown disabled (default)**

  In `config.lua`: `enabled = false`  
  Connect as a player, open the chop shop NPC, request a contract twice in a row.  
  ✅ Expected: Both requests succeed (cooldown is off).

- [ ] **Step 2: Enable cooldown with a short timer for testing**

  In `config.lua`:
  ```lua
  Config.ContractCooldown = {
      enabled  = true,
      cooldown = 60,   -- 1 minute for easy testing
  }
  ```
  Restart: `ensure bablo-chopshop`

- [ ] **Step 3: Test cooldown enforcement**

  Complete or discard your contract, then immediately request a new one from the NPC.  
  ✅ Expected: Server returns a notification like `"You must wait 59 sec before getting a new contract."`

- [ ] **Step 4: Wait out the cooldown and request again**

  After 60 seconds, request another contract.  
  ✅ Expected: Contract is granted normally.

- [ ] **Step 5: Restore production cooldown**

  Set `cooldown = 1800` (or your desired value) and `enabled` to whatever you want live.

---

### Self-review checklist (completed)

- [x] All 4 files covered by tasks
- [x] No TBD / placeholder patterns
- [x] `identifier` fetched once and reused — no duplicate calls
- [x] `Main:canGetContract` and `Main:setContractCooldown` signatures match exactly across Task 2 and Task 4
- [x] `CONTRACT_COOLDOWN` locale key defined in Task 3, used in Task 4
- [x] Cooldown stamps **after** `Inventory:addPlayerItem` — if item grant fails the player is not penalised
- [x] Fail-open on missing identifier (safe default)
- [x] `enabled = false` default confirmed in Task 1
