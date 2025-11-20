# ESPLibrary Documentation

## Overview

ESPLibrary is a Lua library designed for Roblox that provides ESP (Extra Sensory Perception) functionality. It allows you to visualize game objects (typically players) with boxes, name tags, tracers, health bars, and distance indicators.

## Features

- **Boxes**: Draw bounding boxes around objects
- **Names**: Display object names above the boxes
- **Tracers**: Draw lines from the center-bottom of the screen to objects
- **Health Bars**: Show health status with color-coded bars (red to green based on health)
- **Distance Display**: Show distance to objects in meters
- **Customizable Colors**: Support for default colors or custom color functions
- **Distance Threshold**: Limit rendering to objects within a specified distance
- **Local Player Filtering**: Option to include or exclude the local player

## Installation

The library is available globally via `getgenv().ESP` after loading the script.

```lua
local ESP = require(path.to.ESPLibrary)
-- or access via getgenv().ESP
```

## Settings

The `ESP.Settings` table contains all configuration options:

### `Boxes` (boolean)
- **Default**: `true`
- **Description**: Enable/disable bounding boxes around objects

### `Names` (boolean)
- **Default**: `true`
- **Description**: Enable/disable name tags above objects

### `Tracers` (boolean)
- **Default**: `true`
- **Description**: Enable/disable tracer lines from screen center to objects

### `ShowHealth` (boolean)
- **Default**: `true`
- **Description**: Enable/disable health bar display

### `ShowDistance` (boolean)
- **Default**: `true`
- **Description**: Enable/disable distance text display

### `DefaultColor` (Color3)
- **Default**: `Color3.fromRGB(255, 255, 255)` (white)
- **Description**: Default color for ESP elements when no custom color function is provided

### `CustomColorFunction` (function | nil)
- **Default**: `nil`
- **Description**: Custom function to determine object colors
- **Parameters**: 
  - `object` (Instance): The object to get the color for
- **Returns**: `Color3` - The color to use for the object
- **Example**:
  ```lua
  ESP.Settings.CustomColorFunction = function(object)
      if object:IsA("Player") then
          return Color3.fromRGB(255, 0, 0) -- Red for players
      end
      return Color3.fromRGB(0, 255, 0) -- Green for others
  end
  ```

### `IncludeLocalPlayer` (boolean)
- **Default**: `false`
- **Description**: Whether to show ESP on the local player's character

### `DistanceThreshold` (number)
- **Default**: `300`
- **Description**: Maximum distance (in studs) to render ESP elements. Objects beyond this distance will not be displayed.

## API Methods

### `ESP:AddObject(object)`

Adds an object to the ESP system and starts rendering ESP elements for it.

**Parameters:**
- `object` (Instance): The object to add (typically a Player's Character or Model with HumanoidRootPart and Humanoid)

**Example:**
```lua
-- Add a player's character
ESP:AddObject(player.Character)

-- Add all players
for _, player in pairs(game.Players:GetPlayers()) do
    if player.Character then
        ESP:AddObject(player.Character)
    end
end
```

**Notes:**
- Objects must have a `HumanoidRootPart` and `Humanoid` child
- Objects with health <= 0 will not be rendered
- If the object is already being tracked, this method does nothing

### `ESP:RemoveObject(object)`

Removes an object from the ESP system and stops rendering ESP elements for it.

**Parameters:**
- `object` (Instance): The object to remove

**Example:**
```lua
ESP:RemoveObject(player.Character)
```

### `ESP:Destruct()`

Completely destroys the ESP system, disconnecting all connections and removing all drawings.

**Example:**
```lua
ESP:Destruct()
```

**Notes:**
- This method cleans up all resources
- Calls `cleardrawcache()` if available
- After calling this, you'll need to re-add objects to use ESP again

## Usage Examples

### Basic Usage

```lua
local ESP = require(path.to.ESPLibrary)

-- Configure settings
ESP.Settings.Boxes = true
ESP.Settings.Names = true
ESP.Settings.Tracers = true
ESP.Settings.ShowHealth = true
ESP.Settings.ShowDistance = true
ESP.Settings.DistanceThreshold = 500

-- Add all players
for _, player in pairs(game.Players:GetPlayers()) do
    if player.Character then
        ESP:AddObject(player.Character)
    end
end

-- Listen for new players
game.Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(character)
        ESP:AddObject(character)
    end)
    if player.Character then
        ESP:AddObject(player.Character)
    end
end)

-- Clean up when players leave
game.Players.PlayerRemoving:Connect(function(player)
    if player.Character then
        ESP:RemoveObject(player.Character)
    end
end)
```

### Custom Color Function

```lua
ESP.Settings.CustomColorFunction = function(object)
    if object:IsA("Player") then
        local team = object.TeamColor
        return team.Color
    end
    return Color3.fromRGB(255, 255, 255)
end
```

### Toggle Features

```lua
-- Toggle boxes
ESP.Settings.Boxes = not ESP.Settings.Boxes

-- Toggle tracers
ESP.Settings.Tracers = not ESP.Settings.Tracers

-- Change distance threshold
ESP.Settings.DistanceThreshold = 1000
```

### Include Local Player

```lua
ESP.Settings.IncludeLocalPlayer = true
ESP:AddObject(game.Players.LocalPlayer.Character)
```

## Technical Details

### Object Requirements

Objects must meet the following criteria to be rendered:
1. Must have a `HumanoidRootPart` child
2. Must have a `Humanoid` child
3. Humanoid health must be greater than 0
4. Object must be within the distance threshold
5. Object must be on screen (visible to camera)

### Rendering

- ESP elements are rendered using the Drawing API
- Updates occur every frame via `RunService.RenderStepped`
- Box size scales inversely with distance (closer = larger)
- Health bar color transitions from red (low health) to green (full health)

### Performance Considerations

- Each tracked object creates a RenderStepped connection
- Consider using `DistanceThreshold` to limit rendering
- Call `ESP:Destruct()` when no longer needed to free resources
- Remove objects when they're no longer needed

## Dependencies

- Roblox Drawing API (must be available in the execution environment)
- `RunService` (Roblox service)
- `workspace.CurrentCamera` (Roblox camera)
- `game.Players.LocalPlayer` (Roblox player)

## Notes

- The library stores the ESP object in `getgenv().ESP` for global access
- All drawing elements are automatically cleaned up when objects are removed
- The health bar uses a gradient color system (red → yellow → green)
- Box outlines are always black with 50% transparency for visibility
- Tracers originate from the center-bottom of the viewport

