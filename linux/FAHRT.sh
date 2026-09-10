#!/usr/bin/env bash
# FAHRT — Fun Ad-Hoc Reminder Tool (Linux)
#
# Run with -setup to configure reminder text (up to 4 lines, 20 chars each)
# and a sound combo; run with no arguments to show the reminder.
#
# Requires zenity (GUI dialogs — near-universal on GNOME-based desktops;
# install via your package manager if missing, e.g. `sudo apt install zenity`).
# Sound playback auto-detects whatever's already on your system (paplay/aplay
# for WAV; mpg123, ffplay, or cvlc for MP3 — install any one of those if none
# are found, e.g. `sudo apt install mpg123`).

set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG="$DIR/FAHRT.config.json"

# --- sound combos: name -> "entrance|dismiss" ---
declare -A COMBOS=(
    [UpTrombone]="UpSound.wav|SadTrombone.mp3"
    [RedAlertTrombone]="RedAlert.wav|SadTrombone.mp3"
    [UpQuack]="UpSound.wav|MacQuack.mp3"
    [RedAlertQuack]="RedAlert.wav|MacQuack.mp3"
)
declare -A COMBO_LABELS=(
    [UpTrombone]="Rising Tone -> Sad Trombone"
    [RedAlertTrombone]="Red Alert -> Sad Trombone"
    [UpQuack]="Rising Tone -> Mac Quack"
    [RedAlertQuack]="Red Alert -> Mac Quack"
)
DEFAULT_ITEMS=("List Item #1" "List Item number two")
DEFAULT_COMBO="UpQuack"

require() {
    command -v "$1" >/dev/null 2>&1
}

if ! require zenity; then
    echo "FAHRT needs zenity for its popups. Install it, e.g.: sudo apt install zenity" >&2
    exit 1
fi

play_sound() {
    local f="$DIR/$1"
    [ -f "$f" ] || return 0
    case "$f" in
        *.wav)
            if require paplay; then paplay "$f" >/dev/null 2>&1 &
            elif require aplay; then aplay -q "$f" >/dev/null 2>&1 &
            fi
            ;;
        *.mp3)
            if require mpg123; then mpg123 -q "$f" >/dev/null 2>&1 &
            elif require ffplay; then ffplay -nodisp -autoexit -loglevel quiet "$f" >/dev/null 2>&1 &
            elif require cvlc; then cvlc --play-and-exit --intf dummy "$f" >/dev/null 2>&1 &
            elif require paplay; then paplay "$f" >/dev/null 2>&1 &
            fi
            ;;
    esac
}

load_config() {
    if [ -f "$CONFIG" ] && require python3; then
        python3 - "$CONFIG" << 'PYEOF'
import json, sys
try:
    with open(sys.argv[1]) as f:
        cfg = json.load(f)
    items = [str(x)[:20] for x in cfg.get("Items", []) if str(x).strip()][:4]
    combo = cfg.get("SoundCombo", "")
    if not items:
        raise ValueError()
    print(combo)
    for i in items:
        print(i)
except Exception:
    print("__DEFAULT__")
PYEOF
    else
        echo "__DEFAULT__"
    fi
}

save_config() {
    local combo="$1"; shift
    if require python3; then
        python3 - "$CONFIG" "$combo" "$@" << 'PYEOF'
import json, sys
path, combo = sys.argv[1], sys.argv[2]
items = sys.argv[3:]
with open(path, "w") as f:
    json.dump({"Items": items, "SoundCombo": combo}, f, indent=2)
PYEOF
    fi
}

if [ "${1:-}" = "-setup" ]; then
    mapfile -t loaded < <(load_config)
    if [ "${loaded[0]:-}" = "__DEFAULT__" ]; then
        items=("${DEFAULT_ITEMS[@]}")
        combo="$DEFAULT_COMBO"
    else
        combo="${loaded[0]}"
        items=("${loaded[@]:1}")
    fi

    combo_list=""
    for key in UpTrombone RedAlertTrombone UpQuack RedAlertQuack; do
        combo_list+="${COMBO_LABELS[$key]}\n"
    done

    result=$(zenity --forms --title="FAHRT Setup" \
        --text="Reminder text (up to 4 lines, 20 chars each) and sound combo:" \
        --add-entry="Line 1" --add-entry="Line 2" --add-entry="Line 3" --add-entry="Line 4" \
        --add-list="Sound combo" --list-values="$(echo -e "$combo_list")" \
        2>/dev/null)

    [ -z "$result" ] && exit 0

    IFS='|' read -r l1 l2 l3 l4 chosen_label <<< "$result"
    new_items=()
    for l in "$l1" "$l2" "$l3" "$l4"; do
        [ -n "$l" ] && new_items+=("${l:0:20}")
    done
    [ ${#new_items[@]} -eq 0 ] && new_items=("${DEFAULT_ITEMS[@]}")

    chosen_combo="$DEFAULT_COMBO"
    for key in "${!COMBO_LABELS[@]}"; do
        [ "${COMBO_LABELS[$key]}" = "$chosen_label" ] && chosen_combo="$key"
    done

    save_config "$chosen_combo" "${new_items[@]}"
    zenity --info --title="FAHRT Setup" --text="Saved to $CONFIG" 2>/dev/null
    exit 0
fi

# --- normal reminder mode ---
mapfile -t loaded < <(load_config)
if [ "${loaded[0]:-}" = "__DEFAULT__" ]; then
    items=("${DEFAULT_ITEMS[@]}")
    combo_key="$DEFAULT_COMBO"
else
    combo_key="${loaded[0]}"
    items=("${loaded[@]:1}")
fi

combo_spec="${COMBOS[$combo_key]:-${COMBOS[$DEFAULT_COMBO]}}"
entrance="${combo_spec%%|*}"
dismiss="${combo_spec##*|}"

if [ "$entrance" = "RedAlert.wav" ]; then
    play_sound "RedAlert.wav"
    ( sleep 1.4; play_sound "RedAlert.wav" ) &
else
    play_sound "$entrance"
fi

text=$(printf '%s\n' "${items[@]}")
zenity --info --title="Morning Reminder" --text="$text" --ok-label="OK" \
    --window-icon="$DIR/FAHRT.png" 2>/dev/null

play_sound "$dismiss"
