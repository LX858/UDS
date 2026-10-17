# XN Fishing System - QBCore Version

## Overview
Advanced fishing system converted from ESX to QBCore framework with comprehensive fishing mechanics, zones, and progression system.

## Features
- Multiple fishing zones with XP requirements
- Fishing rod durability system
- Fish rarity and skill-based catching
- Integrated minigame system (xx_fishinggame export)
- SQL-based XP progression system
- Enhanced water detection system
- ox_inventory support
- ox_lib integration for UI
- NPC fishing shop with context menu
- Admin commands for XP management
- Vietnamese localization support

## Requirements
- QBCore Framework
- oxmysql (required for fishing XP database)
- ox_inventory (recommended)
- ox_lib (required for UI components)

## Installation

### 1. Dependencies
Make sure you have the following resources installed and started:
- `qb-core`
- `oxmysql` (required for XP system)
- `ox_inventory` (optional but recommended)
- `ox_lib` (required)

### 2. Database Setup
Import the fishing database table by running the SQL file:
```sql
-- Run fishing_database.sql in your database
-- This creates the xn_fishing_xp table for storing player fishing experience
```

The SQL creates a table to track:
- Player fishing XP
- Total fish caught
- Last updated timestamp

### 3. Items Setup
Add the following items to your `qb-core/shared/items.lua` or ox_inventory items database:

```lua
-- Fishing Rods
['can_cau_go'] = {['name'] = 'can_cau_go', ['label'] = 'Cần câu gỗ', ['weight'] = 1500, ['type'] = 'item', ['image'] = 'fishing_rod.png', ['unique'] = false, ['useable'] = true, ['shouldClose'] = false, ['combinable'] = nil, ['description'] = 'Cần câu cơ bản làm từ gỗ'},
['can_cau_thep'] = {['name'] = 'can_cau_thep', ['label'] = 'Cần câu thép', ['weight'] = 2000, ['type'] = 'item', ['image'] = 'fishing_rod.png', ['unique'] = false, ['useable'] = true, ['shouldClose'] = false, ['combinable'] = nil, ['description'] = 'Cần câu chắc chắn làm từ thép'},
['can_cau_carbon'] = {['name'] = 'can_cau_carbon', ['label'] = 'Cần câu carbon', ['weight'] = 1200, ['type'] = 'item', ['image'] = 'fishing_rod.png', ['unique'] = false, ['useable'] = true, ['shouldClose'] = false, ['combinable'] = nil, ['description'] = 'Cần câu nhẹ và bền làm từ carbon'},
['can_cau_titan'] = {['name'] = 'can_cau_titan', ['label'] = 'Cần câu titan', ['weight'] = 1800, ['type'] = 'item', ['image'] = 'fishing_rod.png', ['unique'] = false, ['useable'] = true, ['shouldClose'] = false, ['combinable'] = nil, ['description'] = 'Cần câu cao cấp làm từ titan'},
['can_cau_vip'] = {['name'] = 'can_cau_vip', ['label'] = 'Cần câu VIP', ['weight'] = 1000, ['type'] = 'item', ['image'] = 'fishing_rod.png', ['unique'] = false, ['useable'] = true, ['shouldClose'] = false, ['combinable'] = nil, ['description'] = 'Cần câu đặc biệt với độ bền vượt trội'},

-- Bait
['moi_cau'] = {['name'] = 'moi_cau', ['label'] = 'Mồi câu', ['weight'] = 50, ['type'] = 'item', ['image'] = 'bait.png', ['unique'] = false, ['useable'] = false, ['shouldClose'] = false, ['combinable'] = nil, ['description'] = 'Mồi để câu cá'},

-- Fish
['anchovy'] = {['name'] = 'anchovy', ['label'] = 'Cá cơm', ['weight'] = 200, ['type'] = 'item', ['image'] = 'fish_anchovy.png', ['unique'] = false, ['useable'] = false, ['shouldClose'] = false, ['combinable'] = nil, ['description'] = 'Cá cơm tươi'},
['smallbluefish'] = {['name'] = 'smallbluefish', ['label'] = 'Cá xanh nhỏ', ['weight'] = 300, ['type'] = 'item', ['image'] = 'fish_blue.png', ['unique'] = false, ['useable'] = false, ['shouldClose'] = false, ['combinable'] = nil, ['description'] = 'Cá xanh nhỏ tươi'},
['bach_tuoc'] = {['name'] = 'bach_tuoc', ['label'] = 'Bạch tuộc', ['weight'] = 800, ['type'] = 'item', ['image'] = 'octopus.png', ['unique'] = false, ['useable'] = false, ['shouldClose'] = false, ['combinable'] = nil, ['description'] = 'Bạch tuộc tươi'},
['perch'] = {['name'] = 'perch', ['label'] = 'Cá rô', ['weight'] = 400, ['type'] = 'item', ['image'] = 'fish_perch.png', ['unique'] = false, ['useable'] = false, ['shouldClose'] = false, ['combinable'] = nil, ['description'] = 'Cá rô tươi'},
['ca_thu'] = {['name'] = 'ca_thu', ['label'] = 'Cá thu', ['weight'] = 1200, ['type'] = 'item', ['image'] = 'fish_mackerel.png', ['unique'] = false, ['useable'] = false, ['shouldClose'] = false, ['combinable'] = nil, ['description'] = 'Cá thu tươi'},
['ca_chim'] = {['name'] = 'ca_chim', ['label'] = 'Cá chim', ['weight'] = 600, ['type'] = 'item', ['image'] = 'fish_bird.png', ['unique'] = false, ['useable'] = false, ['shouldClose'] = false, ['combinable'] = nil, ['description'] = 'Cá chim tươi'},
['tom_hum'] = {['name'] = 'tom_hum', ['label'] = 'Tôm hùm', ['weight'] = 1500, ['type'] = 'item', ['image'] = 'lobster.png', ['unique'] = false, ['useable'] = false, ['shouldClose'] = false, ['combinable'] = nil, ['description'] = 'Tôm hùm tươi'},
['ca_ngu'] = {['name'] = 'ca_ngu', ['label'] = 'Cá ngừ', ['weight'] = 2000, ['type'] = 'item', ['image'] = 'fish_tuna.png', ['unique'] = false, ['useable'] = false, ['shouldClose'] = false, ['combinable'] = nil, ['description'] = 'Cá ngừ tươi'},
['rua_bien'] = {['name'] = 'rua_bien', ['label'] = 'Rùa biển', ['weight'] = 3000, ['type'] = 'item', ['image'] = 'sea_turtle.png', ['unique'] = false, ['useable'] = false, ['shouldClose'] = false, ['combinable'] = nil, ['description'] = 'Rùa biển quý hiếm'},
['ca_duoi'] = {['name'] = 'ca_duoi', ['label'] = 'Cá đuối', ['weight'] = 1800, ['type'] = 'item', ['image'] = 'stingray.png', ['unique'] = false, ['useable'] = false, ['shouldClose'] = false, ['combinable'] = nil, ['description'] = 'Cá đuối tươi'},
['shark'] = {['name'] = 'shark', ['label'] = 'Cá mập', ['weight'] = 5000, ['type'] = 'item', ['image'] = 'shark.png', ['unique'] = false, ['useable'] = false, ['shouldClose'] = false, ['combinable'] = nil, ['description'] = 'Cá mập khổng lồ'}
```

### 4. ox_inventory Integration
If you're using ox_inventory, you have several options to add the items:

#### Option 1: Lua Format (Recommended)
Copy the contents of `ox_inventory_items.lua` and add them to your `ox_inventory/data/items.lua` file.

#### Option 2: JSON Format  
If your ox_inventory uses JSON format, use the `ox_inventory_items.json` file instead.

#### Option 3: Manual Addition
Add each item manually to your ox_inventory items file with the following format:

```lua
['can_cau_go'] = {
    label = 'Cần câu gỗ',
    weight = 1500,
    stack = false,
    close = true,
    description = 'Cần câu cơ bản làm từ gỗ',
    client = {
        export = 'xn_cauca.useFishingRod'
    },
    server = {
        export = 'xn_cauca.useFishingRod'
    },
    durability = 604800, -- 7 days
    degrade = 2592000,   -- 30 days
},
-- Add similar entries for other fishing rods
```

**Important Notes for ox_inventory:**
- Fishing rods are configured as useable items with client/server exports
- Durability system is built-in for fishing rods
- All fish items are stackable for easier inventory management
- Proper weight distribution based on fish rarity

### 5. Resource Installation
1. Place the `xn_cauca` folder in your resources directory
2. Add `ensure xn_cauca` to your server.cfg
3. Restart your server

## Configuration

### Fishing Zones
Configure fishing zones in `config.lua`:
- Set coordinates and radius for fishing areas
- Define XP requirements for access
- Specify allowed fishing rods per zone
- Configure available fish types per zone

### Fishing Rods
Configure rod durability and tier system:
- Different rods have different durability loss rates
- Higher tier rods last longer and are required for advanced zones

### Fish Settings
Each fish has configurable:
- Difficulty levels and minigame rounds
- XP rewards
- Rarity classification

## Usage

### For Players
1. Obtain a fishing rod and bait (moi_cau)
2. Go to a fishing zone (marked with blips on map)
3. Use the fishing rod when near water
4. Complete the skill check minigames to catch fish
5. Gain XP to access higher tier fishing zones

### Admin Commands
No admin commands are currently implemented. Fish and rods can be given through normal item giving methods.

## Fishing XP System
The system uses a separate SQL database table to track fishing experience:
- XP is stored in the `xn_fishing_xp` table with player citizenid
- Includes tracking for total fish caught
- Can be completely disabled via config (`Config.EnableXPSystem = false`)
- Server-side validation prevents client-side XP manipulation

## Fishing Zones
1. **Beginner Zone** (XP: 0-99999)
   - Location: Vespucci Beach area
   - Fish: Anchovy, Small Blue Fish, Octopus
   - All rods allowed

2. **Advanced Zone** (XP: 9500+)
   - Location: Alamo Sea
   - Fish: Perch, Mackerel, Bird Fish, Lobster
   - Requires steel rod or better

3. **Black Fish Zone** (XP: 28500+)
   - Location: Deep ocean
   - Fish: Stingray, Tuna, Sea Turtle, Shark
   - Requires carbon rod or better

## Water Detection System
The resource includes an advanced water detection system to ensure players can only fish when near water.

### Configuration
```lua
Config.WaterDetection = {
    enabled = true,                    -- Enable/disable enhanced water detection
    maxDistanceFromWater = 10.0,      -- Maximum distance from water (meters)
    minWaterDepth = 0.5,              -- Minimum water depth required
    checkRadius = 5.0                 -- Radius to check around player
}
```

### Features
- **Multi-point detection**: Checks 8 points around the player
- **Depth validation**: Ensures minimum water depth
- **Distance checking**: Validates proximity to water
- **Performance optimized**: Can be disabled for better performance
- **Edge case handling**: Works on bridges, docks, and near shores

For detailed information, see `WATER_DETECTION_GUIDE.md`

## Minigame Integration
The fishing system now uses the `xx_fishinggame` export for minigames:
```lua
local success = exports["xx_fishinggame"]:fishingGameStart(difficulty)
```

Supported difficulty levels:
- `"easy"` - For beginner fish
- `"medium"` - For intermediate fish  
- `"hard"` - For advanced fish
- `"veryhard"` - For rare/legendary fish

For minigame setup, see `XX_FISHINGGAME_UPDATE.md`

## NPC Fishing Shop
Interact with the fishing NPC to:
- Check your fishing XP and level
- Buy fishing rods and bait
- View fishing zone information
- Access shop via context menu

NPC Location: Configured in `Config.NPCs`

## Admin Commands
- `/setfishingxp [id] [amount]` - Set player fishing XP
- `/getfishingxp [id]` - Check player fishing XP and level

## Fishing Zones
1. **Beginner Zone** (XP: 0-99999)
   - Location: Vespucci Beach area
   - Fish: Anchovy, Small Blue Fish, Octopus
   - All rods allowed

2. **Advanced Zone** (XP: 9500+)
   - Location: Alamo Sea
   - Fish: Perch, Mackerel, Bird Fish, Lobster
   - Requires steel rod or better

3. **Black Fish Zone** (XP: 28500+)
   - Location: Deep ocean
   - Fish: Stingray, Tuna, Sea Turtle, Shark
   - Requires carbon rod or better

## Support
For issues or questions, contact the development team.

## Changelog
### Version 2.0.0
- Converted from ESX to QBCore framework
- Replaced esx_xp with QBCore metadata system
- Updated inventory integration for QBCore compatibility
- Maintained all original fishing mechanics and features
