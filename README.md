[![Homebrew](https://img.shields.io/homebrew/cask/v/flashspace?color=FBB03F&logo=homebrew&label=homebrew)](https://formulae.brew.sh/cask/flashspace)
[![GitHub Release](https://img.shields.io/github/v/release/wojciech-kulik/FlashSpace?logo=github)](https://github.com/wojciech-kulik/FlashSpace/releases)
[![min macOS](https://img.shields.io/badge/macOS-14.0+-silver?logo=apple)](#)
[![CI Status](https://img.shields.io/github/actions/workflow/status/wojciech-kulik/FlashSpace/xcode-build-check.yml?logo=githubactions&logoColor=white)](https://github.com/wojciech-kulik/FlashSpace/actions/workflows/xcode-build-check.yml)

# ⚡ FlashSpace

FlashSpace is a blazingly-fast virtual workspace manager for macOS, designed to
enhance and replace native macOS Spaces. No more waiting for macOS animations.

<img width="806" height="582" alt="FlashSpace" src="https://github.com/user-attachments/assets/8e75e0f5-8f31-44db-9e52-20fdc4c1dec4" />

## ⚙️ Installation

**Requirements:**

- macOS 14.0 or later.
- Enabled "Displays have separate Spaces" in "Desktop & Dock" system settings.

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

https://github.com/user-attachments/assets/09c574c5-512f-47b5-b644-feac0e1de4b0

## 💬 How to use

1. Move all your apps to a single macOS space (per display).
1. Create a workspace.
1. Assign apps to it.
1. Assign a display to the workspace (or use [dynamic mode](#%EF%B8%8F-display-assignment-modes)).
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
- [x] Swipe Gestures - customize swipe gesture actions for your trackpad
- [x] Floating apps - keep apps visible across all workspaces
- [x] Configuration through GUI and config file
- [x] Support for multiple config file formats: JSON, YAML, and TOML
- [x] [Dynamic display assignment](#%EF%B8%8F-display-assignment-modes)
- [x] [CLI](#-command-line-interface) - interact with the app using the command line interface
- [x] [Picture-in-Picture](#-picture-in-picture-support) support
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

https://github.com/user-attachments/assets/4c801433-2c70-4cb9-85d8-ff75dbbfab7e

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

Supported browsers: Safari, Zen Browser, Chrome, Firefox, Brave, Vivaldi, Arc, Dia, Opera, Microsoft Edge, Comet.

**Please note that this feature may not work if your browser language is not set to
English.**

## 🖥️ Display Assignment Modes

FlashSpace supports two modes of display assignment:

- **Static (default)** - Each workspace is assigned to a specific display. This is
  perfect for users who want to have a dedicated workspace for each display,
  similar to how macOS Spaces work. This mode can be challenging if you use
  multiple displays and change their arrangement frequently.

- **Dynamic** - Each workspace is automatically assigned to the displays where
  its apps are located. In this mode, one workspace can be shown on multiple
  displays at the same time. This is useful for users who want to rearrange
  workspaces by moving apps between displays without changing the configuration.
  You can't show empty workspaces with this mode.

The display assignment mode can be changed in the App Settings -> Workspaces.

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
WORKSPACES=$(/Applications/FlashSpace.app/Contents/Resources/flashspace list-workspaces)

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

## 💻 Command-Line Interface

FlashSpace provides a command-line interface to interact with the app. You can
use it to manage workspaces, apps, and profiles.

First, install the CLI in the App Settings -> CLI. Then, use the `flashspace`
command to interact with the app. Run the following command to see all
available commands:

```bash
flashspace --help
```

## 📝 Design Decisions

### 👉 Non-disruptive Behavior

FlashSpace doesn't actively manage windows, so if you switch to a workspace and call
another app that is not assigned to the workspace, it will be shown on top of
the workspace apps.

It is considered to be a desired behavior as it allows quickly accessing other
apps without glitches or switching between workspaces.

Glitches are common in tiling window managers, often caused by not configured
pop-ups or dialog windows. FlashSpace prevents these issues by not managing
windows & apps that are unassigned allowing you to interact with the system in
a non-disruptive way.

### 👉 No Support For Individual App Windows Per Workspace

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

### 👉 No Support For Layouts

FlashSpace doesn't support moving windows, resizing, or changing their layout.
This is a conscious decision to keep the app simple and fast.

This feature would introduce significant complexity and could negatively impact
the app's performance. Additionally, it would require a lot of work to support
all edge cases and glitches. The app is designed to manage workspaces and it
follows the UNIX philosophy of doing one thing and doing it well.

There are many great and free window management apps available that can be used
in conjunction with FlashSpace, so there is no need to duplicate this
functionality. Examples of such apps are Magnet, Rectangle, Raycast, and many
others.

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

## 💡 Tips & Tricks

### 👉 Apps Appear On The Wrong Display After Sleep

macOS has a bug that causes apps to appear on the wrong display after sleep.
This happens if the app is hidden while the Mac is in sleep mode.

There is one workaround that can help with this issue. When you wake up
your Mac, make sure to turn on all displays before logging in. This way,
all apps should be shown on the correct display.

### 👉 Move & Resize Windows

macOS 15 introduced new features that allow you to move & resize windows
without 3rd party apps. To see all available options, select "Window" from the
menu bar and go to "Move & Resize" submenu.

Adjusting shortcuts is quite limited, but it's possible: [see
here](https://discussions.apple.com/thread/255773494?sortBy=rank). However, the
most flexible approach would be to use Raycast, Magnet, or other window
management apps.

### 👉 Switch Between Windows

macOS allows you to switch focus between windows of the same app using the `` Cmd + ` `` shortcut.

### 👉 SKHD

There is a great command-line tool called [SKHD] that allows you to define
custom global shortcuts. You can use it also with FlashSpace through the CLI.

You could even define some shortcuts that are not available in FlashSpace, like
switching between specific profiles.

## 💛 Sponsors

Big thanks to all the sponsors who support this project 🍻!

### Monthly Sponsors

<a href="https://github.com/bjrmatos"><img src="https://avatars.githubusercontent.com/u/4262050" width="40" height="40" alt="@bjrmatos" title="bjrmatos"></a>
<a href="https://github.com/notlus"><img src="https://avatars.githubusercontent.com/u/828989" width="40" height="40" alt="@notlus" title="notlus"></a>
<a href="https://github.com/Cyberax"><img src="https://avatars.githubusercontent.com/u/1136550" width="40" height="40" alt="@Cyberax" title="Cyberax"></a>
<a href="https://github.com/dosboxd"><img src="https://avatars.githubusercontent.com/u/16291547" width="40" height="40" alt="@dosboxd" title="dosboxd"></a>

### One Time Sponsors

<a href="https://github.com/danscheer"><img src="https://avatars.githubusercontent.com/u/56642865" width="40" height="40" alt="@danscheer" title="danscheer"></a>
<a href="https://github.com/felipeva"><img src="https://avatars.githubusercontent.com/u/4754195" width="40" height="40" alt="@felipeva" title="felipeva"></a>
<a href="https://github.com/sinan-guler"><img src="https://avatars.githubusercontent.com/u/37443512" width="40" height="40" alt="@sinan-guler" title="sinan-guler"></a>
<a href="https://github.com/maxschipper"><img src="https://avatars.githubusercontent.com/u/150921823" width="40" height="40" alt="@maxschipper" title="maxschipper"></a>
<a href="https://github.com/sergiopatino"><img src="https://avatars.githubusercontent.com/u/868839" width="40" height="40" alt="@sergiopatino" title="sergiopatino"></a>
<a href="https://github.com/ashaney"><img src="https://avatars.githubusercontent.com/u/25646923" width="40" height="40" alt="@ashaney" title="ashaney"></a>
<a href="https://github.com/exsesx"><img src="https://avatars.githubusercontent.com/u/20399517" width="40" height="40" alt="@exsesx" title="exsesx"></a>
<a href="https://github.com/konpa"><img src="https://avatars.githubusercontent.com/u/778731" width="40" height="40" alt="@konpa" title="konpa"></a>
<a href="https://github.com/nbargnesi"><img src="https://avatars.githubusercontent.com/u/1265294" width="40" height="40" alt="@nbargnesi" title="nbargnesi"></a>
<a href="https://github.com/bchopson"><img src="https://avatars.githubusercontent.com/u/14081421" width="40" height="40" alt="@bchopson" title="bchopson"></a>
<a href="https://github.com/NextMerge"><img src="https://avatars.githubusercontent.com/u/178944810" width="40" height="40" alt="@NextMerge" title="NextMerge"></a>

### Past Monthly Sponsors

<a href="https://github.com/frankroeder"><img src="https://avatars.githubusercontent.com/u/19746932" width="40" height="40" alt="@frankroeder" title="frankroeder"></a>
<a href="https://github.com/aayio"><img src="https://avatars.githubusercontent.com/u/41933025" width="40" height="40" alt="@aayio" title="aayio"></a>

## 🤓 My Other Projects

- [Snippety](https://snippety.app) - Snippets manager for macOS & iOS
- [xcodebuild.nvim](https://github.com/wojciech-kulik/xcodebuild.nvim) - Neovim plugin
- [Smog Poland](https://smog-polska.pl) - Air quality monitoring app for Poland
- [XcodeProjectCLI] - Open Source CLI tool to manage Xcode project

&nbsp;

[SketchyBar]: https://github.com/FelixKratz/SketchyBar
[XcodeGen]: https://github.com/yonaskolb/XcodeGen
[Releases Page]: https://github.com/wojciech-kulik/FlashSpace/releases
[SKHD]: https://github.com/koekeishiya/skhd
[XcodeProjectCLI]: https://github.com/wojciech-kulik/XcodeProjectCLI
