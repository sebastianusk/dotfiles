# Cross-Platform Keyboard Shortcut Design

## Objective
Create a unified keyboard shortcut scheme that works consistently across Mac and Linux environments with minimal conflicts.

## Foundation: Homerow Modification Layer

### Design Decision
Use homerow keys as modifier keys when held, regular keys when tapped:

- **F/J (hold)** → Ctrl modifier
- **D/K (hold)** → Super modifier (Cmd on Mac, Windows key on Linux)
- **S/L (hold)** → Alt modifier (Option on Mac, Alt on Linux)
- **A (hold)** → Navigation layer activation
- **Caps Lock (hold)** → Cmd+Opt modifier
- **F/J/D/K/S/L/A (tap)** → Regular letter input
- **Caps Lock (tap)** → Escape

**Rationale:**
- Eliminates need to reach for physical modifier keys
- Creates consistent modifier access regardless of keyboard layout
- Reduces hand movement and strain
- Works identically across different physical keyboards
- Enables Super+Key pattern without desktop environment conflicts


## Part 1: Universal Copy & Paste - Super+C/V

### Design Decision
Use `Super+C` for copy and `Super+V` for paste **across all applications and contexts** on both Mac and Linux.

**Rationale:**
- No application detection required (works with pure kanata)
- Consistent across terminal, GUI, and web applications
- Super key exists on both platforms (Windows key on PC, Cmd key on Mac)
- Avoids all existing shortcut conflicts (Ctrl+C interrupt, platform differences)
- Simple unified configuration


---

## Part 2: Universal Application Shortcuts - Ctrl+Key Pattern

### Design Decision
Use `Ctrl+Key` combinations for common application shortcuts **across all applications and contexts** on both Mac and Linux:

- `Ctrl+S` - Save
- `Ctrl+F` - Find
- `Ctrl+A` - Select All
- `Ctrl+Z` - Undo
- `Ctrl+T` - New Tab
- `Ctrl+W` - Close Tab/Window
- `Ctrl+R` - Refresh/Reload
- `Ctrl+N` - New Window
- `Ctrl+=/-` - Zoom In/Out

**Rationale:**
- Linux uses Ctrl+Key natively (no changes needed)
- Mac can remap Ctrl+Key → Cmd+Key via Kanata
- Eliminates platform muscle memory differences
- No conflicts with terminal process control (Ctrl+C handled separately in Part 1)
- Simpler than configuring each desktop environment


---

## Part 3: Navigation Layer - A+hjkl Arrow Keys

### Design Decision
Use `A (hold)` + navigation keys for arrow movement and word navigation **across all applications and contexts**:

**Basic Navigation:**
- **A+H** → Left Arrow
- **A+J** → Down Arrow
- **A+K** → Up Arrow
- **A+L** → Right Arrow

**Word Movement (Alt-based):**
- **A+S+H** → Word Left (Alt+Left, mapped appropriately per platform)
- **A+S+L** → Word Right (Alt+Right, mapped appropriately per platform)

**Text Selection:**
- **Shift+A+H/L** → Select by character (Shift+Arrow)
- **Shift+A+S+H/L** → Select by word (Shift+Alt+Arrow, mapped per platform)

**Rationale:**
- Extends existing homerow modifier philosophy to navigation
- Uses vim-style hjkl directional mapping (familiar to developers)
- 'A' key accessible with left pinky, no hand position change
- Leverages existing S/L (Alt) homerow modifier for word movement
- More ergonomic than F+H/L combination (S closer to A)
- Native Alt+Arrow approach aligns with Mac behavior
- Shift combinations naturally extend for text selection


---

## Part 4: Desktop Commands - Cmd+Opt+Key

### Design Decision
Use `Caps Lock (hold)` as Cmd+Opt modifier for system-wide desktop productivity commands:

**System Launcher:**
- **Caps+Space** → Application launcher

**Screenshot & Visual:**
- **Caps+A** → Scroll screenshot
- **Caps+S** → Text extraction screenshot
- **Caps+X** → Take screenshot

**Clipboard Management:**
- **Caps+C** → Browse clipboard history
- **Caps+V** → Browse clipboard

**AI & Tools:**
- **Caps+G** → AI assistant
- **Caps+Comma** → Password manager (1Password)
- **Caps+B** → Bookmark manager (Raindrop)

**Productivity:**
- **Caps+D** → Open daily note
- **Caps+F** → Call homerow app
- **Caps+T** → Create todo

**Quick App Access:**
- **Caps+1** → Open Slack
- **Caps+2** → Open Alacritty (Terminal)
- **Caps+3** → Open Browser
- **Caps+4** → Open Todoist
- **Caps+5** → Open Obsidian

**Rationale:**
- Caps Lock is perfectly positioned for thumb/pinky access
- Eliminates unused Caps Lock functionality
- More ergonomic than D+S combination or reaching for physical Cmd+Opt
- Single modifier creates clean, memorable shortcuts
- Logical grouping: Launcher (Space), Screenshots (A/S/X), Clipboard (C/V), Productivity (D/F/T)
- Works system-wide regardless of active application
- Prevents conflicts with application shortcuts


---

## Part 5: Tiling Window Manager - Amethyst Commands

### Design Decision
Use `Caps Lock (hold)` + window management keys for Amethyst tiling window manager control:

**Layout Control:**
- **Caps+M** → Change layout (cycle through layouts)
- **Caps+H** → Shrink main pane
- **Caps+L** → Expand main pane

**Window Navigation:**
- **Caps+J** → Focus next window
- **Caps+K** → Focus previous window

**Window Movement between Desktop/Space:**
- **Caps+Y** → Throw window to left desktop
- **Caps+O** → Throw window to right desktop
- **Caps+U** → Next desktop (Ctrl+Cmd+Shift+→)
- **Caps+I** → Previous desktop (Ctrl+Cmd+Shift+←)

**Screen/Monitor Management:**
- **Caps+N** → Move focus to next screen
- **Caps+P** → Throw window to next screen

**System Control:**
- **Caps+Z** → Restart Windows manager

**Rationale:**
- Leverages same Caps Lock modifier as other desktop commands
- Uses vim-style hjkl navigation (J/K for window focus, H/L for sizing)
- Logical groupings: Layout (M), Navigation (J/K), Desktop Movement (Y/O/U/I), Screen Management (N/P)
- Single modifier prevents conflicts with application shortcuts
- Consistent with homerow philosophy for window management


---
