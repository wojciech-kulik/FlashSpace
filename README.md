# ⚡ FlashSpace

FlashSpace is a blazingly fast virtual workspace manager for macOS.

🚧 This project is still under development 🚧

<img width="781" alt="FlashSpace" src="https://github.com/user-attachments/assets/67a97170-b9c0-462b-a5dd-ca13a8aa8a84" />

## 🎥 Demo

The video shows a sample configuration where I use 3 workspaces and switch
between them using hotkeys.

https://github.com/user-attachments/assets/af5951ce-8386-48d5-918e-914474d2c2b8

## ✨ Features

- [x] Blazingly fast workspace switching
- [x] Multiple displays support
- [x] Global hotkeys
- [x] Focusing an assigned app triggers workspace activation

## ⚙️ Installation

**Requirements:** macOS 14.0 or later.

Download the app from the [releases page](https://github.com/wojciech-kulik/FlashSpace/releases).

## 👉 How it works

FlashSpace allows to define virtual workspaces and assign apps to them. Each workspace is
also assigned to a specific display. When you switch to a workspace, the assigned apps are
automatically presented and all other apps from the assigned display are hidden.

The app allows switching workspaces on each display independently.

## 💬 How to use

1. Create a workspace.
1. Assign apps to the workspace.
1. Assign the workspace to a display.
1. Define a hotkey to switch to the workspace.
1. Save the workspace.

Now you can switch to the workspace using the configured hotkey.

## 📝 Notes

### Workspaces

FlashSpace doesn't manage windows, so if you switch to a workspace and call
another app that is not assigned to the workspace, it will be shown on top of
the workspace apps.

I consider this as a desired behavior, because it allows you quickly access other
apps without glitches or switching between workspaces.

This is a common issue with tiling window managers that they often cause glitches
when a small pop-up window is shown or some unexpected app is opened.

If you want to hide the new app, you can simply use the hotkey again.

### Focus

The last app on the list will be focused when switching to the workspace.

## 🚧 Limitations

The app is still in early development and has some limitations:

- It doesn't support individual app windows yet.
