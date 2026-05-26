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
- Edit `hyprdeck_config` to tune the split:
  - `ceo_ratio` controls how much space the CEO gets.
  - `ceo_direction` and `opposite_direction` control which side the CEO and staff areas use.
  - `deck_ratio` controls how much of the staff area is reserved for interns.
  - `deck_direction` and `manager_direction` control where the intern deck and manager area sit inside the staff area.
- Send layout messages to rotate roles:
  - `promote ceo` makes the focused intern the CEO. When the CEO or manager is focused, it swaps the CEO and manager.
  - `promote manager` makes the focused intern the manager. When the CEO or manager is focused, it swaps the CEO and manager.
- New windows join the intern deck by default. They do not replace the CEO or the manager until promoted.
