#!/usr/bin/env bash
# FAHRT — Fun Ad-Hoc Reminder Tool (macOS)
#
# Run with -setup to configure reminder text (up to 4 lines, 20 chars each)
# and a sound combo; run with no arguments to show the reminder.
#
# Zero extra installs: osascript and afplay both ship with every Mac.
# Rename to FAHRT.command (or leave as-is and run via Terminal/a shell) if
# you want to double-click it from Finder.

set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG="$DIR/FAHRT.config"

DEFAULT_ITEM1="List Item #1"
DEFAULT_ITEM2="List Item number two"
DEFAULT_COMBO="UpQuack"

combo_files() {
    case "$1" in
        UpTrombone)       echo "UpSound.wav|SadTrombone.mp3" ;;
        RedAlertTrombone) echo "RedAlert.mp3|SadTrombone.mp3" ;;
        UpQuack)          echo "UpSound.wav|MacQuack.mp3" ;;
        RedAlertQuack)    echo "RedAlert.mp3|MacQuack.mp3" ;;
        *)                echo "UpSound.wav|MacQuack.mp3" ;;
    esac
}

combo_label() {
    case "$1" in
        UpTrombone)       echo "Rising Tone -> Sad Trombone" ;;
        RedAlertTrombone) echo "Red Alert -> Sad Trombone" ;;
        UpQuack)          echo "Rising Tone -> Mac Quack" ;;
        RedAlertQuack)    echo "Red Alert -> Mac Quack" ;;
    esac
}

play_sound() {
    local f="$DIR/$1"
    [ -f "$f" ] && afplay "$f" >/dev/null 2>&1 &
}

# --- config: simple KEY=VALUE lines, no parser dependency needed ---
load_config() {
    ITEM1="$DEFAULT_ITEM1"; ITEM2="$DEFAULT_ITEM2"; ITEM3=""; ITEM4=""; COMBO="$DEFAULT_COMBO"
    [ -f "$CONFIG" ] || return 0
    local key val
    while IFS='=' read -r key val; do
        case "$key" in
            Item1) ITEM1="${val:0:20}" ;;
            Item2) ITEM2="${val:0:20}" ;;
            Item3) ITEM3="${val:0:20}" ;;
            Item4) ITEM4="${val:0:20}" ;;
            SoundCombo) COMBO="$val" ;;
        esac
    done < "$CONFIG"
    if [ -z "$ITEM1" ] && [ -z "$ITEM2" ] && [ -z "$ITEM3" ] && [ -z "$ITEM4" ]; then
        ITEM1="$DEFAULT_ITEM1"; ITEM2="$DEFAULT_ITEM2"
    fi
}

save_config() {
    {
        echo "Item1=$1"
        echo "Item2=$2"
        echo "Item3=$3"
        echo "Item4=$4"
        echo "SoundCombo=$5"
    } > "$CONFIG"
}

if [ "${1:-}" = "-setup" ]; then
    load_config

    ask_line() {
        osascript -e "text returned of (display dialog \"Reminder text, line $1 of 4 (up to 20 characters, leave blank to skip):\" default answer \"$2\" with title \"FAHRT Setup\" buttons {\"Next\"} default button \"Next\")" 2>/dev/null
    }
    l1=$(ask_line 1 "$ITEM1"); l1="${l1:0:20}"
    l2=$(ask_line 2 "$ITEM2"); l2="${l2:0:20}"
    l3=$(ask_line 3 "$ITEM3"); l3="${l3:0:20}"
    l4=$(ask_line 4 "$ITEM4"); l4="${l4:0:20}"

    combo_choice=$(osascript -e "choose from list {\"$(combo_label UpTrombone)\", \"$(combo_label RedAlertTrombone)\", \"$(combo_label UpQuack)\", \"$(combo_label RedAlertQuack)\"} with title \"FAHRT Setup\" with prompt \"Sound combo:\" default items {\"$(combo_label "$COMBO")\"}" 2>/dev/null)

    [ "$combo_choice" = "false" ] && exit 0

    new_combo="$DEFAULT_COMBO"
    for key in UpTrombone RedAlertTrombone UpQuack RedAlertQuack; do
        [ "$(combo_label "$key")" = "$combo_choice" ] && new_combo="$key"
    done

    if [ -z "$l1$l2$l3$l4" ]; then l1="$DEFAULT_ITEM1"; l2="$DEFAULT_ITEM2"; fi
    save_config "$l1" "$l2" "$l3" "$l4" "$new_combo"
    osascript -e "display dialog \"Saved to $CONFIG\" with title \"FAHRT Setup\" buttons {\"OK\"} default button \"OK\"" >/dev/null 2>&1
    exit 0
fi

# --- normal reminder mode ---
load_config
spec=$(combo_files "$COMBO")
entrance="${spec%%|*}"
dismiss="${spec##*|}"

if [ "$entrance" = "RedAlert.mp3" ]; then
    play_sound "RedAlert.mp3"
    ( sleep 1.4; play_sound "RedAlert.mp3" ) &
else
    play_sound "$entrance"
fi

text=""
for item in "$ITEM1" "$ITEM2" "$ITEM3" "$ITEM4"; do
    [ -n "$item" ] && text+="$item\\n"
done

osascript -e "display dialog \"$text\" with title \"Morning Reminder\" buttons {\"OK\"} default button \"OK\" with icon note" >/dev/null 2>&1

play_sound "$dismiss"
