# FAHRT — Fun Ad-Hoc Reminder Tool

A small, configurable popup reminder for Windows. One `.exe`, a handful of sound files, no install and no dependencies beyond what Windows already ships with. Curious how it came to be (and why it's named what it's named)? See [ABOUT.md](ABOUT.md).

## What it does

Running `FAHRT.exe` shows a topmost popup with your reminder text and an OK button. On open it plays an entrance sound; clicking OK plays a dismiss sound and closes the window.

## Quick start

```
FAHRT.exe -Setup     # configure your text + sound combo, once
FAHRT.exe            # show the reminder
```

## Setup

Run `FAHRT.exe -Setup` to open a small configuration window where you can set:

- **Reminder text** — up to 4 lines, 20 characters each (e.g. "Check ADP", "Stand up")
- **Sound combo** — one of four fixed pairs (entrance → dismiss):

  | # | Entrance | Dismiss |
  |---|----------|---------|
  | 1 | Rising Tone | Sad Trombone |
  | 2 | Red Alert | Sad Trombone |
  | 3 | Rising Tone | Mac Quack |
  | 4 | Red Alert | Mac Quack |

Click **Save**. This writes `FAHRT.config.json` next to the exe. If that file is missing or unreadable, FAHRT falls back to built-in defaults ("List Item #1" / "List Item number two", Rising Tone → Mac Quack) rather than failing outright.

## Running it

```
FAHRT.exe
```

Shows the popup once, using whatever's in `FAHRT.config.json` (or the defaults). Run it whenever you want the reminder to show — by hand, from a shortcut, or on a schedule (see below).

## Scheduling it

FAHRT itself doesn't schedule anything — that's on you, via Windows' own Task Scheduler. To get it running automatically (e.g., every weekday morning):

1. Open **Task Scheduler** (search for it in the Start menu).
2. **Create Task…** (not "Create Basic Task" — you want the full dialog).
3. **General tab:** give it a name. Under "Security options," select **"Run only when user is logged on."**
4. **Triggers tab → New:** set "Begin the task" to *On a schedule*, choose *Weekly*, pick your days, and set the time.
5. **Actions tab → New:** set "Action" to *Start a program*, and browse to your `FAHRT.exe`.
6. **Conditions/Settings tabs:** defaults are usually fine; you may want to uncheck "Stop the task if it runs longer than…" if present.
7. Save.

That's the whole setup — Task Scheduler runs `FAHRT.exe` at the times you picked, and it shows your configured reminder.

## Files

| File | What it is |
|---|---|
| `FAHRT.exe` | The tool itself — this is the only file you need to run |
| `FAHRT.ps1` | Its source (PowerShell + WinForms), if you want to read or modify it |
| `FAHRT.png` / `FAHRT.ico` | The clock icon shown in the popup and on the exe |
| `UpSound.wav`, `RedAlert.mp3`, `SadTrombone.mp3`, `MacQuack.mp3` | The four sound options |
| `FAHRT.config.json` | Created by `-Setup`; holds your text and sound choice. Not checked into this repo — it's yours, not shared. |

## Requirements

Windows only. No installation, no runtime to download — everything FAHRT uses (WinForms, the classic MCI audio interface) ships with Windows already.

## A note on the sounds

`RedAlert.mp3` is genuine *Star Trek: The Original Series* alert audio, and `MacQuack.mp3` is the classic Mac OS system alert sound — both sourced from long-standing fan/reference sound-effect archives, not created for this project. `SadTrombone.mp3` is a small public-domain effect. This is a personal/internal tool, not a commercial product — worth knowing if you ever repackage or redistribute it further.

## License

Personal-use tool, shared as-is. See the sounds note above before redistributing further.
