# Ambient Police Vehicles

This script enables native GTA V police spawning on your FiveM server. Police officers will spawn at their default single-player locations inside police stations, and parked police vehicles will appear at native spawn points around the map.

## Features

- **Native Police Station Officers** - Police spawn at all default police stations (Mission Row, Del Perro, Vespucci, Davis, Sandy Shores, Paleto Bay, etc.) using GTA V's built-in spawn system
- **Native Parked Police Vehicles** - Police cars and bikes spawn at their single-player parking spots
- Enable/disable police vehicles in traffic
- Enable/disable police helicopters
- Enable/disable police boats
- Control traffic and pedestrian density
- All settings configurable in config.lua

## Commands

- `/togglepolicecars` - Toggle ambient police vehicles on streets
- `/togglestationpolice` - Toggle native police officers at stations
- `/toggleparkedpolice` - Toggle native parked police vehicles
- `/togglepolicehelis` - Toggle police helicopter spawns
- `/settraffic [0.0-1.0]` - Set traffic density
- `/policestatus` - Show current police spawn settings

## Installation

1. Place the `ambient_police` folder in your server's resources directory
2. Add `ensure ambient_police` to your server.cfg
3. Restart your server or start the resource manually

## Configuration

All settings can be found in the `config.lua` file.

## Requirements

- None - works with any FiveM server
