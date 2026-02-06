# Simulator Interaction Toolkit

Standardized functions for interacting with the iOS Simulator from shell scripts and Claude Code sessions.

## Setup

```bash
source scripts/sim-interact.sh
```

Requires `cliclick` (`brew install cliclick`).

## Functions

| Function | Usage | Description |
|----------|-------|-------------|
| `sim_tap` | `sim_tap 200 400` | Tap at device coordinates |
| `sim_long_press` | `sim_long_press 200 400 [ms]` | Long press (default 800ms) |
| `sim_swipe` | `sim_swipe up [x] [y]` | Swipe: up/down/left/right |
| `sim_type` | `sim_type "hello"` | Type text into focused field |
| `sim_key` | `sim_key return` | Press key: return/escape/tab/delete/space |
| `sim_dismiss` | `sim_dismiss` | Dismiss sheet/alert via Escape |

## Coordinate System

- **Viewport**: 402 x 874 points (iPhone 16 Pro @ 1x scale)
- **Origin**: (0, 0) = top-left of device screen content
- **Center**: (201, 437)

### Reference Points

| Element | Approximate Coords |
|---------|-------------------|
| Tab bar (left tab) | (67, 845) |
| Tab bar (center tab) | (201, 845) |
| Tab bar (right tab) | (335, 845) |
| Navigation title area | (201, 50) |
| Search bar | (201, 60) |
| First grid item | (105, 250) |
| Second grid item | (297, 250) |

## How It Works

1. **AppleScript** queries Simulator window position and size
2. **Coordinate mapping** translates device coords to macOS screen coords:
   - Title bar = 28px, device viewport (402x874) centered in window
   - `screenX = winX + padX + deviceX`
   - `screenY = winY + 28 + padY + deviceY`
3. **cliclick** performs the actual mouse operations at screen coords

## Lessons Learned

- **Slow incremental drags required**: iOS Simulator ignores fast single-step drags. Swipes use 50px steps with 100ms delays (6 steps = 300px travel).
- **cliclick over AppleScript click**: `click at {x, y}` returns `missing value` for many UI regions. `cliclick c:x,y` works reliably everywhere.
- **Long press = dd + sleep + du**: Use `cliclick dd:` (mouse down), sleep, `cliclick du:` (mouse up). 800ms triggers context menus.
- **Focus before interaction**: Always bring Simulator to front with 150ms delay before any input.
