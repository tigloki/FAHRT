# FAHRT — Fun Ad-Hoc Reminder Tool

A small, configurable popup reminder. One tool per platform, no install beyond what's already there. Curious how it came to be (and why it's named what it's named)? See [ABOUT.md](ABOUT.md).

## What it does

Running FAHRT shows a topmost popup with your reminder text and an OK button. On open it plays an entrance sound; clicking OK plays a dismiss sound and closes the window.

## Pick your platform

| Platform | Folder | Run with |
|---|---|---|
| **Windows** | [`windows/`](windows/) | `FAHRT.exe` |
| **Linux** | [`linux/`](linux/) | `./FAHRT.sh` |
| **macOS** | [`mac/`](mac/) | `./FAHRT.sh` |

There's no phone version yet.

Each platform's folder is self-contained — the exe/script plus its own sound files. Grab the one folder you need; you don't need the whole repo.

## Setup (all platforms)

```
-Setup      (Windows: FAHRT.exe -Setup)
-setup      (Linux/Mac: ./FAHRT.sh -setup)
```

Configure:

- **Reminder text** — up to 4 lines, 20 characters each (e.g. "Check ADP", "Stand up")
- **Sound combo** — one of four fixed pairs (entrance → dismiss):

  | # | Entrance | Dismiss |
  |---|----------|---------|
  | 1 | Rising Tone | Sad Trombone |
  | 2 | Red Alert | Sad Trombone |
  | 3 | Rising Tone | Mac Quack |
  | 4 | Red Alert | Mac Quack |

This writes a small config file next to the tool (`FAHRT.config.json` on Windows/Linux, `FAHRT.config` on Mac). If it's missing or unreadable, FAHRT falls back to built-in defaults ("List Item #1" / "List Item number two", Rising Tone → Mac Quack) rather than failing outright. That config file is yours — it's gitignored, not shared.

## Running it

Windows: `FAHRT.exe` — Linux/Mac: `./FAHRT.sh`

Shows the popup once. Run it whenever you want the reminder to show — by hand, or on a schedule (see below).

## Platform notes

### Windows
No dependencies — everything (WinForms, the classic MCI audio interface) ships with Windows already. See [`windows/`](windows/) for the exe and its PowerShell source.

### Linux
Needs **zenity** for the popups (near-universal on GNOME-based desktops; `sudo apt install zenity` if missing) and one MP3 player already present or installed (`mpg123`, `ffplay`, or `cvlc` — try `sudo apt install mpg123` if none are found). WAV playback uses `paplay`/`aplay`, which come with essentially every desktop Linux audio stack.

### macOS
No dependencies — `osascript` and `afplay` both ship with every Mac. Run via Terminal (`./FAHRT.sh`), or rename to `FAHRT.command` to make it double-clickable from Finder.

## Scheduling it

FAHRT doesn't schedule itself on any platform — that's on you, using whatever your OS already provides:

- **Windows — Task Scheduler:**
  1. Open **Task Scheduler**, **Create Task…** (not "Create Basic Task").
  2. **General:** name it. Under "Security options," pick **"Run only when user is logged on."**
  3. **Triggers → New:** *On a schedule*, *Weekly*, pick your days/time.
  4. **Actions → New:** *Start a program*, browse to your `FAHRT.exe`.
  5. Save.

- **Linux — cron or a systemd user timer:**
  - Cron: `crontab -e`, then e.g. `25 8 * * 1-5 /path/to/FAHRT.sh` for weekdays at 8:25am.
  - Or a systemd user timer/service pair in `~/.config/systemd/user/` if you prefer that over cron.

- **macOS — launchd:**
  - Create a `.plist` in `~/Library/LaunchAgents/` with a `ProgramArguments` array pointing at your `FAHRT.sh`, and a `StartCalendarInterval` for the schedule. Load it with `launchctl load ~/Library/LaunchAgents/yourfile.plist`.

## A note on the sounds

`RedAlert` (mp3/wav) is genuine *Star Trek: The Original Series* alert audio, and `MacQuack.mp3` is the classic Mac OS system alert sound — both sourced from long-standing fan/reference sound-effect archives, not created for this project. `SadTrombone.mp3` is a small public-domain effect. This is a personal/internal tool, not a commercial product — worth knowing if you ever repackage or redistribute it further.

## License

MIT — see [LICENSE](LICENSE). The code is genuinely open for reuse and modification; the one ask is keeping the copyright notice intact. See the sounds note above before redistributing the bundled audio further, though — those weren't created for this project.

## Attribution

Built via direct collaboration between the author and Claude Sonnet 5, via Claude Code — see [ABOUT.md](ABOUT.md#attribution) for the honest breakdown of who did what.
