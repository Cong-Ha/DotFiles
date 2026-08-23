# GlazeWM

Tiling window manager config for Windows. GlazeWM **3.9.1**.

| | |
|---|---|
| Repo file | `glazewm/config.yaml` |
| Live path | `%USERPROFILE%\.glzr\glazewm\config.yaml` |
| Sync | Manual copy — see [TODO.md](../TODO.md) for the symlink plan |

---

## The modifier: both Alt keys

Every binding uses `lalt+ralt`. **Hold Left Alt and Right Alt together**, then press the key.

Below, `⎇⎇` is shorthand for that two-Alt chord.

Why both Alts instead of a single one: GlazeWM never fires on a lone Alt press, so
every normal Alt shortcut stays free for applications — `Alt+Tab`, `Alt+F4`, menu
accelerators, and game bindings all behave as usual.

GlazeWM modifier names, for reference when editing:

| Name | Matches |
|---|---|
| `alt` | Either Alt key |
| `lalt` / `ralt` | Left / right Alt specifically |
| `lctrl` / `rctrl`, `lshift` / `rshift`, `lwin` / `rwin` | Side-specific variants |

Side-specific names stack, which is what makes `lalt+ralt+<key>` work.

> On US-International and German layouts Right Alt is AltGr and sends Ctrl+Alt, so it
> must be written `ralt+control`. This machine is on the standard US layout
> (`0409:00000409`), where plain `ralt` works.

---

## Focus and move windows

| Keys | Action |
|---|---|
| `⎇⎇ + h` · `←` | Focus left |
| `⎇⎇ + j` · `↓` | Focus down |
| `⎇⎇ + k` · `↑` | Focus up |
| `⎇⎇ + l` · `→` | Focus right |
| `⎇⎇ + Shift + h` · `←` | Move window left |
| `⎇⎇ + Shift + j` · `↓` | Move window down |
| `⎇⎇ + Shift + k` · `↑` | Move window up |
| `⎇⎇ + Shift + l` · `→` | Move window right |

## Resize

| Keys | Action |
|---|---|
| `⎇⎇ + u` | Width −2% |
| `⎇⎇ + p` | Width +2% |
| `⎇⎇ + o` | Height +2% |
| `⎇⎇ + i` | Height −2% |
| `⎇⎇ + r` | Enter resize mode |

### Resize mode

Once in resize mode the Alt chord is no longer held — the keys are bare:

| Keys | Action |
|---|---|
| `h` · `←` | Width −2% |
| `l` · `→` | Width +2% |
| `k` · `↑` | Height +2% |
| `j` · `↓` | Height −2% |
| `Esc` · `Enter` | Return to normal bindings |

## Window state

| Keys | Action |
|---|---|
| `⎇⎇ + v` | Toggle tiling direction (where the next window lands) |
| `⎇⎇ + c` | Cycle focus: tiling → floating → fullscreen |
| `⎇⎇ + Shift + Space` | Toggle floating, centered |
| `⎇⎇ + t` | Toggle tiling |
| `⎇⎇ + f` | Toggle fullscreen |
| `⎇⎇ + m` | Minimize |
| `⎇⎇ + Shift + q` | Close window |

## Workspaces

| Keys | Action |
|---|---|
| `⎇⎇ + 1` … `9` | Focus workspace 1–9 |
| `⎇⎇ + Shift + 1` … `9` | Move window to workspace 1–9 and follow it |
| `⎇⎇ + s` | Next active workspace |
| `⎇⎇ + a` | Previous active workspace |
| `⎇⎇ + d` | Most recently focused workspace |

### Move a workspace to another monitor

| Keys | Action |
|---|---|
| `⎇⎇ + Shift + a` | Move workspace left |
| `⎇⎇ + Shift + f` | Move workspace right |
| `⎇⎇ + Shift + d` | Move workspace **up** |
| `⎇⎇ + Shift + s` | Move workspace **down** |

> Heads up: `Shift + d` is up and `Shift + s` is down, which is inverted relative to
> the `a`/`s`/`d` workspace-cycling keys just above. This is how upstream's default
> config ships; it has not been changed here.

## Window manager control

| Keys | Action |
|---|---|
| `⎇⎇ + Shift + p` | Pause / unpause window management (all bindings off) |
| `⎇⎇ + Shift + r` | Reload this config |
| `⎇⎇ + Shift + w` | Redraw all windows |
| `⎇⎇ + Shift + e` | Exit GlazeWM |

---

## Other settings in this config

- **Startup / shutdown** — launches and kills [Zebar](../zebar) automatically.
- **Gaps** — no inner gap; `40px` top outer gap to clear the Zebar bar, zero elsewhere.
- **Transparency** — disabled; focused windows render at 100% opacity.
- **Cursor jump** — cursor follows focus across monitors only, not between windows.
- **Hide method** — `cloak`, the recommended non-animated method.

## Applying changes

Edit the file here, then copy it live and reload:

```powershell
Copy-Item "$env:USERPROFILE\RiderProjects\DotFiles\glazewm\config.yaml" `
          "$env:USERPROFILE\.glzr\glazewm\config.yaml" -Force
glazewm command wm-reload-config
```

Or reload in place with `⎇⎇ + Shift + r`.

If a binding stops working after an edit, GlazeWM logs parse failures to
`%USERPROFILE%\.glzr\glazewm\errors.log` rather than failing visibly.
