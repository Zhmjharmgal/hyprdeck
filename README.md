# Hyprdeck

Hyprdeck is a custom master-based Hyprland layout for busy workspaces with many windows.

It keeps two windows large enough to use, while keeping the rest visible in a small deck.

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

The **CEO** is the main window. The **manager** is a secondary large window. The **interns** are the other windows, shown as small previews in one row.

## Why

When a workspace only has one or two windows, the layout (tiling algorithm) usually doesn't matter a lot. The problem starts when many windows are open in one workspace.

There are two common layout ideas I love a lot:

- [Master-stack](https://wiki.hypr.land/Configuring/Layouts/Master-Layout/) keeps one window large and shows the rest in a stack. This gives a useful overview, but the stack becomes cramped when many windows are stacked, and every single window becomes useless. You have to constantly swap a slave window with the master window to reference its content.

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

---

-  [DWM Deck](https://dwm.suckless.org/patches/deck/) fixes the cramped stack by showing only one secondary window at a time, leaving others invisible. That window can be used for cross-referencing, but the users loses the overview to the opened windows.

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

---

Hyprdeck sits between these two ideas: the CEO and manager stay readable for cross-referencing, and the interns stay visible to provide a compact overview.

## Usage

- Require `hyprdeck.lua` in your `hyprland.lua` and set the layout to `lua:hyprdeck`.
- Edit `hyprdeck_config` to change the CEO width ratio or deck height ratio.
- Send the `promote` layout message to rotate roles:
  - When the CEO or the manager window is focused, swap them.
  - When an intern window is focused, swap that intern with the manager.
