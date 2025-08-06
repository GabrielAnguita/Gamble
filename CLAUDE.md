# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a World of Warcraft addon called "Gamble" that implements a gambling system where players can bet gold on dice rolls. The addon supports multiple WoW versions (Vanilla, Cataclysm, Mists of Pandaria) and provides a complete gambling interface with VIP systems, loyalty programs, and jackpots.

## Architecture

### Core Components

- **Init.lua**: Initializes the addon base using RasuAddon framework and sets up database defaults
- **Core.lua**: Main addon logic, event handlers, and slash command registration (`/gamble`)
- **UI.lua**: Creates and manages the gambling interface frames and UI components
- **ChatCommands.lua**: Handles chat-based command processing

### Utility Modules (Utils/)

- **GameUtil.lua**: Core gambling logic, dice rolling, game state management
- **TradesUtil.lua**: Handles trade window interactions and bet validation
- **StatsUtil.lua**: Player statistics tracking (wins/losses, amounts)
- **VipUtil.lua**: VIP player management and loyalty system
- **MessageUtil.lua**: Whisper and chat message handling
- **PixelBus.lua**: Pixel-based communication system for external automation

### Configuration System

- **Constants/Constants.lua**: All addon constants, message templates, colors, and game rules
- Database system via RasuAddon framework stores player data, game history, and settings

### File Loading Order (embed.xml)

1. Libraries and constants
2. Addon initialization (Init.lua)
3. Utility modules
4. UI components
5. Core addon logic
6. Chat commands

## Game Mechanics

- **Betting**: Players bet gold amounts between configurable min/max limits
- **Choices**: Players choose "UNDER" (under 7), "OVER" (over 7), or "7" (exactly 7)
- **Payouts**: 2x for UNDER/OVER, 4x for exact 7
- **Jackpots**: Progressive jackpot system for consecutive wins
- **Loyalty**: VIP system with bonus payouts

## PixelBus System

The addon includes a sophisticated pixel communication system that creates 1x1 pixel frames at fixed screen coordinates to communicate with external automation scripts:

- **Payout Data**: Positions 101-104,100 encode gold amounts in RGB values
- **State Indicators**: Positions 105-109,100 show game states (IDLE, ACTIVE_GAMBLE, TRADE_ACCEPT, etc.)
- **Color Encoding**: Uses RGB channels to encode numerical data and state information
- **UI Scale Compensation**: Handles different UI scales to ensure pixel-perfect positioning

## External Automation

### AutoHotkey Scripts
- **Pixel Gambler.ahk**: Main automation script that reads pixel data and performs actions
- **colorandregionpicker.ahk**: Utility for color/region detection setup

The AHK script reads from the PixelBus system and automates:
- Trade acceptance/denial based on payout data
- Dice rolling when games require it
- Warning dialog acceptance
- Anti-detection measures with randomized timing

## Common Commands

### Testing
- `/gamble test` - Runs a test game with current target
- `/gamble stats <playername>` - Shows player statistics
- `/gamble vip add/remove/list <playername>` - Manages VIP players
- `/gamble pixelbus` - Debug pixel bus state and colors
- `/gamble testwin` - Forces a win outcome for testing

### Development Commands
This is a WoW addon, so testing requires:
- Running World of Warcraft with the addon loaded
- Using `/reload` to reload addon after code changes
- Checking `/console scriptErrors 1` for Lua errors

## Key Architectural Patterns

### Event-Driven System
- Uses WoW's event system for chat messages, trades, and system events
- Private module system with cross-module communication
- Timer-based state updates for UI and game logic

### Database Integration
- RasuAddon framework provides persistent storage
- Callback system for database operations
- Cached data structures for performance

### Modular Design
- Private namespace prevents global pollution
- Each utility has specific responsibilities
- Cross-module dependencies managed through Private table

### Error Handling
- C_Timer.After() used to prevent interface action failures
- Try-catch patterns in automation scripts
- Graceful degradation when components fail

## TOC Files
- **Gamble.toc**: Base TOC file
- **Gamble_Vanilla.toc, Gamble_Cata.toc, Gamble_MoP.toc**: Version-specific TOC files for different WoW expansions

## External Dependencies

- **LibStub**: Library loading system
- **RasuAddonBase**: Base addon framework for database and utility functions
- **World of Warcraft API**: Uses WoW's trading system, currency API, and UI framework

## Development Notes

### AutoHotkey Integration
- The PixelBus system requires precise coordinate management
- UI scaling must be compensated for reliable pixel positioning
- Color tolerance needed for different graphics settings
- Anti-detection features require careful timing randomization

### WoW Addon Constraints
- Combat lockdown doesn't affect this addon's functionality
- Interface actions must be queued with timers to avoid blocking
- Secure execution paths required for some operations
- Memory management important for pixel frame creation

### Cross-Platform Considerations
- AutoHotkey scripts are Windows-only
- WoW addon works across all platforms
- Pixel coordinates may need adjustment for different resolutions