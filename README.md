![App Version](https://img.shields.io/badge/version-v0.9.11-8A2BE2)
![Homebrew Cask Version](https://img.shields.io/homebrew/cask/v/flashspace)
![min macOS](https://img.shields.io/badge/macOS-14.0+-silver)
![CI Status](https://img.shields.io/github/actions/workflow/status/wojciech-kulik/FlashSpace/xcode-build-check.yml)
![Supported Xcode](https://img.shields.io/badge/xcode-16.2-blue)

# ⚡ FlashSpace

FlashSpace is a blazingly-fast virtual workspace manager for macOS, designed to
enhance and replace native macOS Spaces. No more waiting for macOS animations.

🚧 This project is still in early development. 🚧

<img width="797" alt="FlashSpace" src="https://github.com/user-attachments/assets/18d5b84e-77a8-4950-ac4f-ccf4117401db" />

## ⚙️ Installation

**Requirements:** macOS 14.0 or later.

### Homebrew

```bash
brew install flashspace
```

> [!NOTE]
> The app is now available in the main Homebrew repository.
> If you previously installed it from `wojciech-kulik/tap/flashspace`,
> you should switch to the main repository by following these steps:
>
> ```bash
> brew uninstall flashspace
> brew untap wojciech-kulik/tap
> brew install flashspace
> ```

### Download Binary

See: [Releases Page].

### Build From Source

See: [Build From Source](#%EF%B8%8F-build-from-source).

## 🎥 Demo

The video shows a sample configuration where I use 3 workspaces and switch
between them using hotkeys.

https://github.com/user-attachments/assets/53044f38-6d2e-47dd-9159-1858623bd959

## 👉 How it works

FlashSpace allows to define virtual workspaces and assign apps to them. Each workspace is
also assigned to a specific display. When you switch to a workspace, the assigned apps are
automatically presented and all other apps from the assigned display are hidden.

The app allows workspaces to be switched independently on each display.

## ✨ Features

- [x] Blazingly fast workspace switching
- [x] Multiple displays support
- [x] Activate workspace on app focus
- [x] Move apps between workspaces with a hotkey
- [x] Floating apps visible across all workspaces
- [x] Focus manager - set hotkeys to switch between apps quickly
- [x] Cursor manager - auto-center the cursor in the active window
- [x] Profiles - quickly switch between different configurations
- [x] Configurable Menu Bar icon (per workspace)
- [x] [SketchyBar] integration

## ⚖️ Project Values

- **Performance** - The app should be as fast as possible.
- **Simplicity** - The app should be easy to use and configure.
- **Reliability** - The app should work without glitches and unexpected behavior.
- **Invisible** - The app should help, not disturb.
- **UNIX Philosophy** - The app should do one thing and do it well - manage workspaces.

## 💬 How to use

1. Create a workspace.
1. Assign apps to the workspace.
1. Assign the workspace to a display.
1. Define a hotkey to switch to the workspace.
1. Save the workspace.

Now you can switch to the workspace using the configured hotkey.

## 🪟 Focus Manager

FlashSpace enables fast switching of focus between windows. Use hotkeys to
shift focus in any desired direction. It also allows you to jump between
displays.

https://github.com/user-attachments/assets/de0db253-d3a5-495a-b4b7-2a65e2776254

## 📝 Notes

FlashSpace doesn't manage windows, so if you switch to a workspace and call
another app that is not assigned to the workspace, it will be shown on top of
the workspace apps.

I consider this as a desired behavior because it allows you to quickly access other
apps without glitches or switching between workspaces.

This is a common issue with tiling window managers that they often cause glitches
when a small pop-up window is shown or some unexpected app is opened.

If you want to hide the new app, you can simply use the hotkey again.

## 🖥️ SketchyBar Integration

FlashSpace can be integrated with [SketchyBar] and other tools. The app runs a
configurable script when the workspace is changed.

You can enable the integration in the app settings.

<details>
  <summary>Configuration Example</summary>

### Only Active Workspace

##### `sketchybarrc`

```bash
sketchybar --add item flashspace left \
  --set flashspace \
  background.color=0x22ffffff \
  background.corner_radius=5 \
  label.padding_left=5 \
  label.padding_right=5 \
  script="$CONFIG_DIR/plugins/flashspace.sh" \
  --add event flashspace_workspace_change \
  --subscribe flashspace flashspace_workspace_change
```

##### `plugins/flashspace.sh`

```bash
#!/bin/bash

sketchybar --set $NAME label="$WORKSPACE - $DISPLAY"
```

### All Workspaces

##### `sketchybarrc`

```bash
sketchybar --add event flashspace_workspace_change

SID=1
WORKSPACES=$(cat ~/.config/flashspace/workspaces.json | jq -r ".[].name")

for workspace in $WORKSPACES; do
  sketchybar --add item flashspace.$SID left \
    --subscribe flashspace.$SID flashspace_workspace_change \
    --set flashspace.$SID \
    background.color=0x22ffffff \
    background.corner_radius=5 \
    background.padding_left=5 \
    label.padding_left=5 \
    label.padding_right=5 \
    label="$workspace" \
    script="$CONFIG_DIR/plugins/flashspace.sh $workspace"

  SID=$((SID + 1))
done
```

##### `plugins/flashspace.sh`

```bash
#!/bin/bash

if [ "$1" = "$WORKSPACE" ]; then
  sketchybar --set $NAME label.color=0xffff0000
else
  sketchybar --set $NAME label.color=0xffffffff
fi
```

</details>

## 🚧 Limitations

The app is still in early development and has some limitations:

- It doesn't support individual app windows yet.

## 🛠️ Build From Source

FlashSpace uses [XcodeGen] to generate the Xcode project from the `project.yml`
file.

1. Clone the repository.
1. Navigate to the project directory.
1. Run `brew bundle` to install dependencies.
1. Run `xcodegen generate`.
1. Open `FlashSpace.xcodeproj` in Xcode.
1. Click on the `FlashSpace` target, click on the `Signing & Capabilities` tab,
   and select your team.
1. Build & run the app.

Remember to run `xcodegen generate` every time you change branch or pull changes.

If you want to generate the project with configured signing, you can run:

```bash
XCODE_DEVELOPMENT_TEAM=YOUR_TEAM_ID xcodegen generate
```

You can also set this variable globally in your shell.

[SketchyBar]: https://github.com/FelixKratz/SketchyBar
[XcodeGen]: https://github.com/yonaskolb/XcodeGen
[Releases Page]: https://github.com/wojciech-kulik/FlashSpace/releases
