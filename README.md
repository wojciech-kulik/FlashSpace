[![GitHub Release](https://img.shields.io/github/v/release/wojciech-kulik/FlashSpace?color=8A2BE2)](https://github.com/wojciech-kulik/FlashSpace/releases)
[![Homebrew Cask Version](https://img.shields.io/homebrew/cask/v/flashspace)](https://formulae.brew.sh/cask/flashspace)
[![min macOS](https://img.shields.io/badge/macOS-14.0+-silver)](#)
[![CI Status](https://img.shields.io/github/actions/workflow/status/wojciech-kulik/FlashSpace/xcode-build-check.yml)](https://github.com/wojciech-kulik/FlashSpace/actions/workflows/xcode-build-check.yml)
[![Supported Xcode](https://img.shields.io/badge/xcode-16.2-blue)](#)

# ⚡ FlashSpace

FlashSpace is a blazingly-fast virtual workspace manager for macOS, designed to
enhance and replace native macOS Spaces. No more waiting for macOS animations.

<img width="797" alt="FlashSpace" src="https://github.com/user-attachments/assets/36f4933d-3711-4acf-9171-9137073010d7" />

## ⚙️ Installation

**Requirements:** macOS 14.0 or later.

### Homebrew

```bash
brew install flashspace
```

### Download Binary

See: [Releases Page].

### Build From Source

See: [Build From Source](#%EF%B8%8F-build-from-source).

## 🎥 Demo

The video shows a sample configuration where I use 3 workspaces and switch
between them using hotkeys.

https://github.com/user-attachments/assets/03498386-7c3d-4d9e-8fbd-cd49dea36661

## 💬 How to use

1. Move all your apps to a single macOS space. You can keep separate spaces on
   each display.
1. Create a workspace.
1. Assign apps to it.
1. Assign a display to the workspace.
1. Set a hotkey for quick workspace activation.
1. Follow the same steps for other workspaces.
1. Switch between configured workspaces using hotkeys.

### The Same App In Multiple Workspaces

If you want to keep the same app in multiple workspaces, you can use the
"Floating Apps" feature from the app settings or you can add the app to multiple
workspaces from the main app window.

## 👉 How it works

FlashSpace allows to define virtual workspaces and assign apps to them. Each workspace is
also assigned to a specific display. When you switch to a workspace, the assigned apps are
automatically presented and all other apps from the assigned display are hidden.

The app allows workspaces to be switched independently on each display.

## ✨ Features

- [x] Blazingly fast workspace switching
- [x] Multiple displays support
- [x] Space Control - preview all workspaces and switch between them
- [x] Hotkeys - manage apps and workspaces using keyboard
- [x] Focus detection - activate workspace on app focus
- [x] Focus manager - switch focus between apps using keyboard
- [x] Cursor manager - auto-center the cursor in the active window
- [x] Profiles - quickly switch between different configurations
- [x] Menu bar - configurable icon & text (per workspace)
- [x] Floating apps - keep apps visible across all workspaces
- [x] Configuration through GUI and config file
- [x] Support for multiple config file formats: JSON, YAML, and TOML
- [x] [Picture-in-Picture](https://github.com/wojciech-kulik/FlashSpace#-picture-in-picture-support) support
- [x] [SketchyBar] integration

## ⚖️ Project Values

- **Performance** - The app should be as fast as possible.
- **Simplicity** - The app should be easy to use and configure.
- **Reliability** - The app should work without glitches and unexpected behavior.
- **Invisible** - The app should help, not disturb.
- **UNIX Philosophy** - The app should do one thing and do it well - manage workspaces.

## 🔭 Space Control

Space Control allows you to preview all workspaces on a grid and switch between them.

Use 0-9 and arrow keys to switch between workspaces.

![FlashSpace-Space Control](https://github.com/user-attachments/assets/97d8f94a-00c3-47c1-af82-5934bcba4d13)

## 🪟 Focus Manager

FlashSpace enables fast switching of focus between windows. Use hotkeys to
shift focus in any desired direction. It also allows you to jump between
displays.

https://github.com/user-attachments/assets/9bc22b19-7cd7-48f8-a679-0adf4adc3aef

## 🎥 Picture-In-Picture Support

FlashSpace supports Picture-In-Picture mode. This is an experimental feature
and can be disabled in the App Settings -> Workspaces.

macOS does not offer a public API to hide a specific window, and hiding the app
also hides the PiP window. To work around this issue, FlashSpace identifies if
the app supports PiP and **hides in a screen corner** all windows except the
PiP window.

If the PiP window is not visible, the standard behavior is applied.

Supported browsers: Safari, Zen Browser, Chrome, Firefox, Brave, Vivaldi, Arc, Opera.

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
SELECTED_PROFILE_ID=$(jq -r ".selectedProfileId" ~/.config/flashspace/profiles.json)
WORKSPACES=$(jq -r --arg id "$SELECTED_PROFILE_ID" 'first(.profiles[] | select(.id == $id)) | .workspaces[].name' ~/.config/flashspace/profiles.json)

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

## 📝 Design Decisions

### Non-disruptive Behavior

FlashSpace doesn't actively manage windows, so if you switch to a workspace and call
another app that is not assigned to the workspace, it will be shown on top of
the workspace apps.

It is considered to be a desired behavior as it allows quickly accessing other
apps without glitches or switching between workspaces.

Glitches are common in tiling window managers, often caused by not configured
pop-ups or dialog windows. FlashSpace prevents these issues by not managing
windows & apps that are unassigned allowing you to interact with the system in
a non-disruptive way.

### No Support For Individual App Windows Per Workspace

FlashSpace doesn't support the concept of individual app windows per workspace.
This is a conscious decision to keep the app simple and fast.

This way, FlashSpace can rely on native show & hide functionality ensuring the
most efficient way of managing and switching between workspaces. Additionally,
this hack-free approach is battery-friendly and doesn't break other features in
the system like Mission Control.

Supporting individual windows per workspace would introduce significant
complexity and could negatively impact the app's performance. This limitation
results from the lack of a public API in macOS to hide specific windows.
Currently, the only options are to move a window to a screen corner or minimize
it - neither of which provides an ideal user experience.

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

## 💛 Sponsors

Big thanks to all the sponsors who support this project 🍻!

### Monthly Sponsors

<a href="https://github.com/bjrmatos"><img src="https://avatars.githubusercontent.com/u/4262050" width="40" height="40" alt="@bjrmatos" title="bjrmatos"></a>
<a href="https://github.com/notlus"><img src="https://avatars.githubusercontent.com/u/828989" width="40" height="40" alt="@notlus" title="notlus"></a>
<a href="https://github.com/frankroeder"><img src="https://avatars.githubusercontent.com/u/19746932" width="40" height="40" alt="@frankroeder" title="frankroeder"></a>

### One Time Sponsors

<a href="https://github.com/danscheer"><img src="https://avatars.githubusercontent.com/u/56642865" width="40" height="40" alt="@danscheer" title="danscheer"></a>
<a href="https://github.com/felipeva"><img src="https://avatars.githubusercontent.com/u/4754195" width="40" height="40" alt="@felipeva" title="felipeva"></a>

&nbsp;

[SketchyBar]: https://github.com/FelixKratz/SketchyBar
[XcodeGen]: https://github.com/yonaskolb/XcodeGen
[Releases Page]: https://github.com/wojciech-kulik/FlashSpace/releases
