# Player Data Manager

Centralized data management system for all player data. All player information is stored in a single file per player.

## File Structure

```
saved_data/
  player_license_abc123.json
  player_license_def456.json
  time_data.json
```

## Player File Format

```json
{
  "character": {
    "model": "a_m_y_business_01",
    "position": {
      "x": -516.8,
      "y": -253.4,
      "z": 34.6,
      "heading": 26.2
    }
  },
  "money": {
    "cash": 5000,
    "dirty": 0
  }
}
```

## Exported Functions

### GetPlayerData(source)
Get all player data
```lua
local playerData, license = exports['my_datamanager']:GetPlayerData(source)
```

### GetPlayerDataKey(source, key)
Get specific data key
```lua
local characterData = exports['my_datamanager']:GetPlayerDataKey(source, 'character')
local moneyData = exports['my_datamanager']:GetPlayerDataKey(source, 'money')
```

### SetPlayerDataKey(source, key, value)
Set specific data key (auto-saves)
```lua
exports['my_datamanager']:SetPlayerDataKey(source, 'character', { model = "mp_m_freemode_01" })
exports['my_datamanager']:SetPlayerDataKey(source, 'inventory', { ... })
```

### SavePlayerData(source)
Force save player data
```lua
exports['my_datamanager']:SavePlayerData(source)
```

### DeletePlayerData(source)
Delete all player data (for character deletion on death)
```lua
exports['my_datamanager']:DeletePlayerData(source)
```

### GetPlayerLicense(source)
Get player's license identifier
```lua
local license = exports['my_datamanager']:GetPlayerLicense(source)
```

## Features

- ✅ **Centralized**: All scripts use the same data file
- ✅ **Cached**: Data loaded once per player session
- ✅ **Auto-save**: Data saved on disconnect
- ✅ **Thread-safe**: No race conditions between scripts
- ✅ **Easy deletion**: One file to delete per player

## Usage in Other Scripts

Just use the exports - no need to handle files directly:

```lua
-- Get player's inventory
local inventory = exports['my_datamanager']:GetPlayerDataKey(source, 'inventory')

-- Save player's skills
exports['my_datamanager']:SetPlayerDataKey(source, 'skills', {
    driving = 50,
    shooting = 75
})
```
