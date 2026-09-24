# Touchline Menu

A charcoal, silver and champagne menu theme for **SP Football Life 2026**, with Touchline / Prologue branding, portrait main-menu scenes and quiet `#040B12` information screens.

**[Download the latest release](https://github.com/ahmadsk-cell/Touchline-Menu/releases/latest)** · [Installation](#installation) · [Credits](CREDITS.md)

![Touchline main-menu scene](docs/images/main-menu.png)

## Included

- Main menu ordered as Kick-off, Master League, Become a Legend, MyClub, Gallery, Music & Audio, Settings.
- Seven portrait scenes and short introductions for Master League and Become a Legend.
- Dark information backgrounds with subtle smoke, fine gold lines and BootShapes branding.
- Silver-and-gold icons for the default Game Plan menu, negotiations, notifications and calendar events.
- Custom loading, saving and controlled-club indicators, plus the Touchline intro movie.
- Readability changes for league/team rows, team ratings and text-entry dialogs.
- The latest working Schedule and text-input files from the author's installation.

![Default Game Plan icons](docs/images/game-plan.png)

![Information background](docs/images/information-background.png)

## Requirements

- Windows with **SP Football Life 2026**, Sider and LiveCPK enabled.
- **MenuC1987** installed and enabled as the underlying menu pack.
- **UIColors by Zlac** installed, with its LiveCPK root and `UIColors.lua` enabled.
- English game text. This package includes an English string-table override.

This is an overlay for that setup. It does not bundle Football Life, PES, Sider, MenuC1987 or UIColors. It uses PES 2021-format assets, but other PES/Football Life versions have not been validated. The FL 2027 wordmark is artwork; the tested game is Football Life 2026.

Touchline and Prologue gameplay/story systems are separate projects. Their names appear in the menu artwork; this download installs the visual theme and intro only.

## Installation

1. Close Football Life and Sider.
2. Download **Touchline-Menu-v1.0.0.zip** from the release page and extract it completely.
3. Confirm MenuC1987 and UIColors are already installed and working.
4. Double-click **Install.cmd** and enter the full path to your **SiderAddons** folder, the folder containing `sider.ini`.
5. Start Sider and Football Life again.

Alternatively, from PowerShell in the extracted package:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Install.ps1 -SiderDir 'D:\Football Life\SiderAddons'
```

Replace the example path with your installation. Administrator privileges are normally unnecessary if you can write to that folder.

The installer verifies the package, backs up affected files, places `TouchlinePrologue2` first in LiveCPK order, installs the theme and applies its UIColors text palette. It preserves unrelated Sider settings, mods and save files. Keep MenuC1987 and UIColors enabled underneath the theme.

Earlier development versions used the same `TouchlinePrologue2` folder. The installer backs them up and removes the obsolete `teamPower.bin` override only when its hash matches a known development copy. An independently edited copy is left for you to resolve.

## Restore the previous setup

Each installation prints its backup directory under `SiderAddons\TouchlineMenu-backups`. Close the game and Sider, then run:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Uninstall.ps1 -SiderDir 'D:\Football Life\SiderAddons' -BackupDirectory 'D:\Football Life\SiderAddons\TouchlineMenu-backups\YOUR-BACKUP-FOLDER'
```

This restores overwritten files and settings and removes files created by that installation. It stops if a file has changed since installation, so later edits are not silently lost. Keep the extracted package and backup until you no longer need to restore them.

## Compatibility and troubleshooting

- **No visual changes:** restart both Sider and the game; confirm the theme root is above MenuC1987 and UIColors in `sider.ini`.
- **Schedule or a text-entry screen is blank:** use this complete release, not an older development ZIP. If another mod overrides the same files, check LiveCPK priority. Report the game version and active menu mods with a screenshot.
- **Different icons during a licensed competition:** the premium Game Plan set targets the default menu. Competitions can provide their own menu layouts and icons.
- **Other menu mods:** they may override these files or the UIColors palette. The installer backs up existing theme files and palette settings; it does not merge conflicting layouts.
- The intro overrides `movie/intro/FL2026.usm`. Competition-specific intro movies remain controlled by the existing setup.

The author has reviewed the current theme in Football Life. Packaging checks cover asset hashes, the repaired live files, archive integrity, and installer/restore behavior. Every game mode, competition and third-party mod combination has not been tested.

## Repository and packaging

The repository includes the ready-to-install assets, portable scripts, preview images, five high-resolution Game Plan icon masters, and the editable information-background SVG. The release ZIP is the easiest download for players.

To verify and package the checked-in release using Python 3:

```text
python tools/package_release.py
```

The ZIP and its SHA-256 checksum are written to `dist/`. No extraction of your game, local credentials or personal save data is required.

See [CREDITS.md](CREDITS.md) for the underlying menu work and tools, and [CHANGELOG.md](CHANGELOG.md) for release notes.
