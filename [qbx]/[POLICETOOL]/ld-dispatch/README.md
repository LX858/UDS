# LD Dispatch - QBCore & ox_lib Version

## Overview
This is a converted version of the LD Dispatch system that has been updated from ESX to work with QBCore and ox_lib. The dispatch system allows emergency services (Police, EMS) to manage units and dispatch calls.

## Requirements
- QBCore Framework
- ox_lib (for enhanced notifications and callbacks)

## Installation

1. **Dependencies**: Make sure you have the following resources installed and started:
   - qb-core
   - ox_lib

2. **Installation**: 
   - Extract the resource to your resources folder
   - Add `ensure ld-dispatch` to your server.cfg
   - Make sure it starts after qb-core and ox_lib

## Changes Made in Conversion

### Framework Changes
- **ESX → QBCore**: All ESX functions have been replaced with QBCore equivalents
- **Player Data**: Updated to use QBCore's PlayerData structure
- **Job System**: Updated to work with QBCore's job system
- **Callbacks**: Converted from ESX callbacks to QBCore callbacks

### Key Function Changes
- `ESX.GetPlayerData()` → `QBCore.Functions.GetPlayerData()`
- `ESX.GetPlayerFromId()` → `QBCore.Functions.GetPlayer()`
- `ESX.TriggerServerCallback()` → `QBCore.Functions.TriggerCallback()`
- `ESX.RegisterServerCallback()` → `QBCore.Functions.CreateCallback()`
- `player.getName()` → `player.PlayerData.charinfo.firstname .. " " .. player.PlayerData.charinfo.lastname`

### Configuration Updates
- Updated job names to match QBCore defaults
- Enhanced notification system integration
- Improved error handling

## Features
- **Unit Management**: Create, join, and leave units
- **Dispatch System**: Send and receive dispatch calls
- **Job-based Access**: Only relevant jobs can see specific dispatches
- **Blip System**: Automatic map blips for dispatch locations
- **Real-time Updates**: Live updates for all connected units

## Commands
- `/openDispatchMenu` (or PAGEDOWN key) - Opens the dispatch menu

## Test Commands
- `/dp1` - Test dispatch 1
- `/dp2` - Test dispatch 2

## Job Configuration
The system supports multiple emergency jobs. You can configure them in `config.lua`:

```lua
Config.EmergencyJobs = {
    {
        name = "police",
        displayname = "LSPD",
    },
    {
        name = "ambulance", 
        displayname = "EMS",
    }
}
```

## Export Usage
Other resources can send dispatches using:

```lua
exports['ld-dispatch']:sendDispatch({
    title = "Title",
    code = "10-XX",
    values = {
        {
            text = "Location Info",
            icon = "fa-solid fa-earth-americas",
        },
        {
            text = "Priority Level", 
            icon = "fa-solid fa-hashtag",
        },
    },
    jobs = {"police", "ambulance"},
    coords = vector3(x, y, z),
    blip = {
        blipid = 80,
        blipcolor = 1,
    }
})
```

## Support
This conversion maintains full compatibility with the original dispatch system while adding QBCore and ox_lib support for enhanced functionality and modern framework integration.
