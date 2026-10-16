# Hardware Pulse

An open-source macOS widget that shows live hardware utilization — CPU, memory, GPU, and disk — on your Desktop, in StandBy, and on the lock screen.

![macOS 14+](https://img.shields.io/badge/macOS-14%2B-blue) ![Swift 5.9](https://img.shields.io/badge/Swift-5.9-orange) ![License: MIT](https://img.shields.io/badge/License-MIT-green)

## Features

- **Desktop widgets** (small & medium) showing CPU / RAM / GPU / Disk usage bars
- **StandBy and lock-screen accessories** (circular, inline, rectangular)
- **Menu bar host app** (MenuBarExtra) that samples metrics every 5 seconds
- **Apple Silicon GPU utilization** via IOKit accelerator statistics
- Pure-Swift metrics core (`HardwarePulseCore`) with unit tests
- No third-party dependencies

## Architecture

```
┌────────────────────┐        App Group (JSON)        ┌────────────────────┐
│  HardwarePulse     │  ───────────────────────────► │  HardwarePulse     │
│  (menu bar app)    │     group.com.example.         │  Widget Extension  │
│  PulseSampler      │     hardwarepulse.json        │  (WidgetKit)       │
└────────────────────┘                               └────────────────────┘
```

The host app samples metrics with `host_statistics`/`host_statistics64` and IOKit, writes a `HardwarePulse` snapshot to the shared App Group container, and calls `WidgetCenter.shared.reloadAllTimelines()`. The widget extension reads the snapshot and renders it.

| Path | Contents |
|---|---|
| `Sources/Core` | `HardwarePulse` model, App Group store, `PulseSampler` |
| `Sources/HostApp` | Menu bar app (MenuBarExtra) |
| `Sources/Widget` | WidgetKit extension |
| `Tests/CoreTests` | XCTest suite for the metrics math |

## Building

Requirements: macOS 14+, Xcode 15+, [xcodegen](https://github.com/yonaskolb/XcodeGen).

```bash
brew install xcodegen
xcodegen generate
open HardwarePulse.xcodeproj
```

Then select the **HardwarePulse** scheme and run. To test the metrics core on its own:

```bash
swift test
```

> **Note:** the App Group identifier defaults to `group.com.example.hardwarepulse`.
> For distribution, change it in `project.yml`, both `.entitlements` files, and
> `AppConfiguration`/`WidgetConfiguration`, then regenerate.

## Usage

1. Launch the app — a speedometer icon appears in the menu bar.
2. Add the widget: right-click the Desktop → *Edit Widgets* → search for **Hardware Pulse**.
3. CPU/RAM/GPU/Disk update every 5 seconds while the app runs.

## Contributing

PRs welcome. Run `swift test` before submitting; keep the core dependency-free.

## License

MIT — see [LICENSE](LICENSE).
