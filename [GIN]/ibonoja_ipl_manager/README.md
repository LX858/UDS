# 🏢 Ibonoja IPL Manager

A powerful and flexible interior management system for FiveM servers, designed to control multiple Ibonoja map interiors from a single, easy-to-use interface.

---

## 📋 Features

- 🎮 **In-game Menu System** - Easy-to-use interface powered by ox_lib
- 🔄 **Real-time Synchronization** - Changes are instantly visible to all players
- 🔐 **Permission System** - Flexible access control (public, group-based, or custom)
- ⚙️ **Highly Configurable** - Customize default values and settings
- 🚀 **Optimized Performance** - Efficient state management and resource usage
- 🎨 **Multiple Maps Support** - Manage all your Ibonoja interiors in one place

---

## 🎮 Supported Maps

- **LEO Training Center** - Law enforcement training facility
- **Mission Row PD** - Police department interiors
- **Senora Sheriff Station** - Sheriff department settings
- **Davis Fire Station** - Fire station configurations
- **Paleto Sheriff Substation** - North county sheriff office
- **Vespucci Substation** - Beach patrol station

> **Note:** Only maps that are installed and running will appear in the menu.

---

## 📦 Installation

1. **Download** the resource and place it in your resources folder
2. **Ensure** you have `ox_lib` installed and working
3. **Add** to your `server.cfg`:
   ```
   ensure ox_lib
   ensure ibonoja_ipl_manager
   ```
4. **Restart** your server

---

## 🎮 How to Use

### Opening the Menu

**Configure Keybind:** You need to assign a keybind in FiveM settings:

1. Press `ESC` in-game
2. Go to **Settings** > **Key Bindings** > **FiveM**
3. Search for **"Open Ibonoja IPL manager"**
4. Assign your preferred key

> The keybind is registered automatically, but you must assign a key manually

### Menu Navigation

1. **Main Menu** - Shows all available maps
2. **Map Menu** - Shows all configurable options for the selected map
3. **Options** - Use arrow keys to scroll through values
4. **Apply** - Changes are applied instantly

### Example Usage

#### Example 1: Changing Fire Station Truck Bay

1. Open the menu with your assigned keybind
2. Select **"Davis Fire Station"**
3. Navigate to **"Truck Bay"**
4. Use arrow keys to select pattern (Off, Pattern 1-4)
5. Changes apply immediately!

#### Example 2: Configuring Police Station

1. Open the menu with your assigned keybind
2. Select **"Mission Row PD"**
3. Navigate to **"Toilets"**
4. Toggle between "Checked" and "Unchecked"
5. Done!

---

## ⚙️ Configuration

You can customize the IPL Manager by editing the `editable/config.lua` file.

### Access Control

#### Allow Everyone

```lua
Config.Menu = {
    Restricted = false  -- Anyone can access
}
```

#### Restrict to Specific Group

```lua
Config.Menu = {
    Restricted = "group.admin"  -- Only admins
}
```

#### Restrict to Multiple Groups

```lua
Config.Menu = {
    Restricted = {"group.admin", "group.police", "group.moderator"}
}
```

#### Custom Function

```lua
Config.Menu = {
    Restricted = function(source)
        -- Your custom logic here
        local identifier = GetPlayerIdentifier(source, 0)
        return identifier == "steam:110000100000000"
    end
}
```

### Default Values

Set the initial state when the server starts:

```lua
-- Davis Fire Station example
Config.DavisFireStation = {
    TruckBay = 1,         -- Start with size 1
    TruckBayColor = 5,    -- Use color 5
    DispatchBlinds = 1,   -- Blinds up
    MeetingBlinds = 1,
    LivingBlinds = 1,
    Lights = 1,           -- Lights on
}
```

### Custom Ymaps (LEO Training Center)

Add custom circuit ymaps to the LEO Training Center:

```lua
Config.LEOTrainingCenter = {
    Circuit = 1,  -- Default circuit
    
    -- Add custom ymaps (appear AFTER default options)
    CircuitYmaps = {
        {label = "Expert Circuit", ymap = "my_expert_track"},
        {label = "Night Circuit", ymap = "night_racing_track"},
    }
}
```

> Custom ymaps are **added** to existing options, not replaced. If the map has 4 default circuits, your custom ones will be options 5, 6, etc.

---

## 📝 Configuration Examples

### Example 1: Police Server Setup

```lua
-- Only police can access
Config.Menu = {
    Restricted = "group.police"
}

-- Default values for police stations
Config.MRPD = {
    Toilets = 1  -- Toilets visible
}

Config.SenoraStation = {
    BriefingRoom = 1,
    ExtraRoom = 1,
    DetectiveRoomBlinds = 1,
    WallLogos = 1,
}
```

> Only maps that are **installed and running** will appear in the menu. No need to disable maps.

### Example 2: Public Server

```lua
-- Everyone can access
Config.Menu = {
    Restricted = false
}

-- Set default values for all maps
Config.DavisFireStation = {
    TruckBay = 2,
    TruckBayColor = 1,
    Lights = 1,
}

Config.LEOTrainingCenter = {
    HangarKillHouse = 1,
    BriefingRoom = 1,
    Circuit = 1,
}
```

> All installed map resources will automatically appear in the menu.

### Example 3: Staff Only

```lua
-- Only admins and moderators
Config.Menu = {
    Restricted = {"group.admin", "group.moderator"}
}

-- Configure LEO Training Center with custom circuits
Config.LEOTrainingCenter = {
    Circuit = 1,
    CircuitYmaps = {
        {label = "Custom Track 1", ymap = "my_track_1"},
        {label = "Custom Track 2", ymap = "my_track_2"},
    }
}
```

---

## 🎨 Available Options by Map

### LEO Training Center

- **Hangar Kill House** - Toggle kill house configuration
- **Hangar Helicopter** - Toggle helicopter display
- **Hangar Helicopter Color** - Change hangar helicopter floor color
- **Briefing Room** - Toggle briefing room layout
- **Paleto Room** - Configure Paleto training room
- **Great Ocean Room** - Configure Great Ocean training room
- **Sandy Room** - Configure Sandy Shores training room
- **Mission Row Room** - Configure Mission Row training room
- **Senora Room** - Configure Senora training room
- **Vespucci Room** - Configure Vespucci training room
- **Vinewood Room** - Configure Vinewood training room
- **Under Left Section** - Toggle underground left section
- **Under Left Section Targets** - Toggle targets in left section
- **Under Right Section** - Toggle underground right section
- **Under Right Section Targets** - Toggle targets in right section
- **Car Generator** - Toggle vehicle spawn area
- **Perimetral Fence** - Toggle perimeter fencing
- **Circuit** - Select training circuits (supports custom ymaps)

### Mission Row PD (MRPD)

- **Toilets** - Show or hide toilet cells

### Senora Sheriff Station

- **Briefing Room** - Toggle briefing room layout (Off, Pattern 1, Pattern 2)
- **Extra Room** - Toggle additional room configuration (Off, Pattern 1, Pattern 2)
- **Detective Room Blinds** - Control detective office blinds (Off, Open, Closed)
- **Wall Logos** - Toggle wall signage and logos (Off, Wrap, Normal)

### Davis Fire Station

- **Truck Bay** - Select truck bay configuration (Off, Pattern 1-4)
- **Truck Bay Color** - Choose bay floor color scheme (Color 1-9)
- **Lights** - Toggle interior lighting (Off, Turned On, Turned Off)
- **Dispatch Blinds** - Control dispatch area blinds (Off, Open, Closed)
- **Meeting Room Blinds** - Control meeting room blinds (Off, Open, Closed)
- **Living Room Blinds** - Control living quarters blinds (Off, Open, Closed)

### Paleto Sheriff Substation

- **Briefing Room** - Toggle briefing room layout (Off, Pattern 1, Pattern 2)
- **Briefing Blinds** - Control briefing room blinds (Off, Open, Middle, Closed)
- **Reception Blinds** - Control reception area blinds (Off, Open, Middle, Closed)
- **Central Blinds** - Control central office blinds (Off, Open, Middle, Closed)
- **Chief Blinds** - Control chief's office blinds (Off, Open, Middle, Closed)
- **Meeting Blinds** - Control meeting room blinds (Off, Open, Middle, Closed)
- **Armory Blinds** - Control armory blinds (Off, Open, Middle, Closed)
- **Locker Blinds** - Control locker room blinds (Off, Open, Middle, Closed)

### Vespucci Substation

- **Central Blinds** - Control central office blinds (Off, Open, Closed)
- **Meeting Blinds** - Control meeting room blinds (Off, Open, Closed)

---

## 🔧 Troubleshooting

### Menu Won't Open

**Solutions:**

1. Check that you have permission (if restrictions are enabled)
2. Verify you have assigned a keybind in FiveM settings (ESC > Settings > Key Bindings > FiveM)
3. Make sure `ox_lib` is installed and working
4. Check console for errors

### Map Doesn't Appear in Menu

**Solutions:**

1. Verify the map resource is started
2. Check that the resource is running (use `ensure` or `start` in server.cfg)
3. Restart the IPL Manager resource after starting the map resource

> The system automatically detects which Ibonoja maps are running and shows only those in the menu.

### Getting Errors After Update

**Solutions:**
1. Restore your `editable/config.lua` from backup
2. Compare with the new default configuration
3. Restart the resource completely

---

## 🔄 Updating

When updating the resource:

1. **Backup** your `editable/config.lua`:
   ```
   Copy editable/config.lua to config.backup.lua
   ```

2. **Replace** all resource files with the new version

3. **Restore** your configuration:
   ```
   Copy config.backup.lua to editable/config.lua
   ```

4. **Restart** the resource:
   ```
   restart ibonoja_ipl_manager
   ```

> Your custom settings will be preserved across updates!

---

## 📌 Important Notes

### State Persistence

- Changes are **NOT saved** between server restarts
- Default values from `editable/config.lua` are applied each time the server starts
- To change defaults permanently, edit the map configuration values

### Performance

- Only installed and running maps are loaded
- Changes are synchronized efficiently across all clients
- Minimal resource usage when not in use

### Permissions

- If using ACE permissions, ensure groups are properly configured in your server
- Test permission system with `Restricted = false` first
- Custom functions receive the player's `source` as parameter

---

## 💡 Tips & Best Practices

### For Server Owners

1. **Set sensible defaults** - Configure initial states in `editable/config.lua` that fit your server
2. **Restrict access** - Not everyone needs to change interiors
3. **Review option names** - Check the config file to understand available options
4. **Test thoroughly** - Try all options before opening to players

### For Players

1. **Don't spam changes** - Give time for props to load
2. **Communicate with others** - Coordinate interior changes
3. **Report issues** - Help improve the system
4. **Respect permissions** - Don't attempt to bypass restrictions

---

## 📚 API for Developers

### Server Export

The resource provides a single server-side export to programmatically change interior options:

```lua
-- Change an interior option via code (SERVER ONLY)
exports.ibonoja_ipl_manager:SetVariant(mapName, optionName, variant)
```

#### Parameters:

- **`mapName`** (string): The internal map name
  - `"LEOTrainingCenter"`
  - `"MRPD"`
  - `"SenoraStation"`
  - `"DavisFireStation"`
  - `"PaletoSubstation"`
  - `"VespucciSubstation"`

- **`optionName`** (string): The internal option name (see config file)
  - Examples: `"HangarKillHouse"`, `"Toilets"`, `"TruckBay"`, `"BriefingRoom"`

- **`variant`** (number/boolean): The value to set
  - For **checkboxes**: `true`/`false` or `1`/`0`
  - For **scroll options**: The option ID number (1, 2, 3, etc.)

#### Examples:

```lua
-- Turn on LEO Training Center hangar kill house
exports.ibonoja_ipl_manager:SetVariant("LEOTrainingCenter", "HangarKillHouse", 2)

-- Hide MRPD toilets
exports.ibonoja_ipl_manager:SetVariant("MRPD", "Toilets", 0)

-- Change Davis Fire Station truck bay size to option 3
exports.ibonoja_ipl_manager:SetVariant("DavisFireStation", "TruckBay", 3)

-- Enable Senora Station briefing room layout
exports.ibonoja_ipl_manager:SetVariant("SenoraStation", "BriefingRoom", 1)
```

#### Use Cases:

- **Event-based changes**: Change interiors during specific server events
- **Time-based automation**: Schedule interior changes (day/night cycles)
- **Integration**: Connect with other resources (dispatch systems, admin panels)
- **Scripted scenarios**: Trigger interior changes during missions or roleplay

#### Notes:

- Changes apply **instantly** to all connected players
- Changes are **not persistent** - they reset on server restart
- Invalid map/option names will log errors to server console
- Only works from **server-side** scripts

---

## 🤝 Support

### Before Asking for Help

1. ✅ Check this README thoroughly
2. ✅ Check console for errors (F8 in-game)
3. ✅ Verify all dependencies are installed (`ox_lib`)
4. ✅ Ensure map resources are started
5. ✅ Test with default configuration

### Reporting Issues

When reporting issues, please include:

- Server framework (QBCore, ESX, Standalone, etc.)
- FiveM server version
- ox_lib version
- Steps to reproduce the issue
- Console errors (client F8 and server console)
- Your configuration (relevant parts from `editable/config.lua`)

---

## 📄 License

This resource is property of **Ibonoja**. Please respect the terms of use included with your map purchases.

---

## ⭐ Features Overview

| Feature | Description |
|---------|-------------|
| **Real-time Sync** | Changes visible instantly to all players |
| **Permission System** | Control who can access the menu |
| **Multiple Maps** | Manage all Ibonoja interiors |
| **Easy Configuration** | Simple config file for customization |
| **Performance** | Optimized resource usage |
| **User-Friendly** | Intuitive menu interface |
| **Persistent Defaults** | Set initial states for server start |
| **Server Export** | Programmatic control via SetVariant |
| **Auto-Detection** | Automatically finds installed maps |

---

## 🎉 Quick Start Guide

**5 Minutes Setup:**

1. Install the resource
2. Add to server.cfg
3. Set permissions in config (or leave public)
4. Restart server
5. Assign a keybind in-game (ESC > Settings > Key Bindings > FiveM)
6. Use your keybind to open the menu!

That's it! You're ready to manage your interiors.

---

## 📞 Getting Started Checklist

- [ ] Resource installed in correct folder
- [ ] ox_lib dependency installed
- [ ] Added to server.cfg
- [ ] Ibonoja map resources installed and running
- [ ] Configuration reviewed (optional)
- [ ] Permissions configured (optional)
- [ ] Server restarted
- [ ] Keybind assigned in FiveM settings
- [ ] Tested in-game

---

**Version:** 2.0.0  
**Author:** Ibonoja  
**Last Updated:** November 2025

**Enjoy managing your Ibonoja interiors!** 🎮
