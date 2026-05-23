# Hyprdeck

Hyprdeck is a custom Hyprland layout for busy workspaces with many windows.

When a workspace has only one or two windows, the layout usually matters less. When many windows are open, common layouts start to break down.

## Motivation

[Master-stack](https://wiki.hypr.land/Configuring/Layouts/Master-Layout/) keeps one window large and shows the rest in a stack. This is useful for cross-referencing, but the stack becomes cramped when many windows are open.

```text
+----------------------+----------------------+
|                      |        Stack         |
|                      |----------------------|
|                      |        Stack         |
|        Master        |----------------------|
|                      |        Stack         |
|                      |----------------------|
|                      |        Stack         |
+----------------------+----------------------+
```

[DWM Deck](https://dwm.suckless.org/patches/deck/) layout solves the size problem by using a monocle layout for the stack area, showing only one secondary window at a time. The selected window is usable, but the others disappear from view.

```text
+----------------------+----------------------+
|                      |                      |
|                      |                      |
|                      |                      |
|        Master        |       Monocle        |
|                      |                      |
|                      |                      |
|                      |                      |
+----------------------+----------------------+
```

Hyprdeck keeps the large working areas from deck layouts, while still showing every window.

## Naming

Hyprdeck avoids the traditional master/slave wording. It uses a small office metaphor instead:

- The **CEO** is the main window.
- The **manager** is the large secondary window.
- The **interns** are the remaining windows in the deck.

In older layout terms, the CEO maps to the master window. The manager and interns map to slave windows.

## Layout

Hyprdeck has three areas:

- A CEO area for the main window.
- A manager area for the selected secondary window.
- A deck area for the interns.

```text
+----------------------+-----------------------------+
|                      | Intern | Intern | Intern    |
|                      |-----------------------------|
|         CEO          |                             |
|                      |                             |
|                      |          Manager            |
|                      |                             |
+----------------------+-----------------------------+
```

The CEO and manager stay large enough to use. The interns stay small, but visible, so the workspace still has an overview.

Hyprdeck is meant for people who want focus without losing track of the rest of the windows.

## Usage

- Require `hyprdeck.lua` in your `hyprland.lua` and set the layout to be `lua:hyprdeck`.
- Go to `hyprdeck.lua` and edit `hyprdeck_config` to change the CEO width ratio or deck height ratio.
- Layout message: use `promote` to perform dynamic window swap:
    - When the current focus is the CEO window: swap it with the manager.
    - When the current focus is the manager window: swap it with the CEO. 
    - When the current focus is an intern, swap it with the manager.
