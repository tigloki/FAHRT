# About FAHRT

## The short version

FAHRT reminds you to check two things at work. That's it. Everything else here is how it got weirdly over-engineered along the way, on purpose, for fun.

## The origin

This started as a lost cause, literally — a popup reminder for ADP and Dynamics that had existed on a machine that suffered a hard drive failure. Nobody remembered what it was built in. Python? C#? It didn't matter — it was gone, and the only path forward was to rebuild it.

The rebuild went through more architectures than a reminder popup has any right to:

1. **AutoHotkey**, first — fast, familiar, already the house style for this kind of thing.
2. **A VBScript + Task Scheduler combo**, chasing the smallest possible footprint — no persistent process, just a script that fires and exits.
3. **An HTA** (`mshta.exe`), because the footprint-obsessed version needed a real GUI and a custom icon, which plain `MsgBox` can't do.
4. **WinForms**, finally — because HTA's audio support (`<audio>` tags via Internet Explorer's ancient Trident engine) turned out to be almost comically unreliable, and getting real, responsive sound required dropping the whole HTA/`mshta` layer for a proper compiled tool.

Along the way: a Task Scheduler gotcha where the whole job got torn down out from under the popup the instant the launcher script exited (nothing was "wrong" — Windows just does that); an MCI error 282 from asking a sound file to play past its own actual length; and a very real, very human "wait, why is a click sound produced by *spawning a brand new PowerShell process*" moment that explained a stubborn, mysterious pause before every dismiss sound.

## The sounds

Once the basic mechanism worked, the question became: what should it actually *sound* like? This is where "ad-hoc" earns its place in the name. The reminder needed:

- **An entrance sound** — either a simple synthesized rising tone, or two blasts of the genuine *Star Trek: The Original Series* Red Alert klaxon.
- **A dismiss sound** — either a real "sad trombone" (the classic comedic fail sting), or the equally classic Mac OS System 7 "Quack" alert.

All four combinations got built, tested live, and kept — because there was no good reason to throw three of them away just because one got picked as a daily driver. `-Setup` exists specifically so nobody has to choose in advance.

## The name

**F**un **A**d-**H**oc **R**eminder **T**ool. Say it out loud. That's on purpose too.

## Philosophy, if a reminder popup can be said to have one

- **Ad-hoc, not automated.** FAHRT doesn't manage its own schedule — Task Scheduler already does that well, and duplicating it would just be another thing to maintain. FAHRT does one job: show up, make noise, get dismissed.
- **Zero install.** Everything it uses — WinForms, the classic MCI audio interface — already ships with Windows. No runtime to download, no dependency to explain to a coworker before they can run it.
- **Fun is the point.** A work reminder doesn't have to be dour. If it has to interrupt your morning, it might as well do it with a Red Alert klaxon and a sad trombone.

## Attribution

FAHRT was built through direct, extensive collaboration between its author and Claude Sonnet 5, via Claude Code. The concept, every creative call — the name, the sound combos, the insistence on doing it properly instead of settling for the first working version — and all testing and correction came from the author. The code, architecture, and iteration were Claude's, working live against that direction. Neither half tells the whole story alone, so both are stated plainly here rather than left for the reader to guess at.
