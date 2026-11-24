#!/bin/bash

# Guessing Game - Weekend Edition

usage() {
    printf "Usage: %s <name> [level]\n" "$(basename "$0")" >&2
    printf "  name  : alphanumeric player name (letters, numbers, _, -)\n" >&2
    printf "  level : easy, normal, or hard (optional, defaults to normal)\n" >&2
    exit 1
}

if [[ "$#" -lt 1 || "$#" -gt 2 ]]; then
    usage
fi

name="$1"
# Day 3 name validation: must be non-empty and contain only letters, numbers, underscores, or hyphens
if [[ -z "$name" || ! "$name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    echo "Error: Invalid player name '$name'. Use letters, numbers, underscores, or hyphens only." >&2
    usage
fi
# Normalize player name to lowercase so 'Ama' and 'ama' are treated as the same player
name="${name,,}"

level="${2:-normal}"
level="${level,,}"

case "$level" in
    easy)
        min=1
        max=50
        ;;
    normal)
        min=1
        max=100
        ;;
    hard)
        min=1
        max=1000
        ;;
    *)
        usage
        ;;
esac

# Read log file path from GAMES_FILE environment variable, defaulting to history.log
log_file="${GAMES_FILE:-history.log}"

# Temporary staging file holding validated rows for the current menu iteration
clean_log_file=$(mktemp)
trap 'rm -f "$clean_log_file"' EXIT

# Validate log_file once per menu display, populate clean_log_file, and warn on damaged lines
load_clean_games() {
    : > "$clean_log_file"
    local damaged_count=0

    if [[ ! -f "$log_file" ]]; then
        return
    fi

    while IFS= read -r line || [[ -n "$line" ]]; do
        [[ -z "$line" ]] && continue

        # Verify exact 5 pipe characters (6 fields)
        local stripped="${line//[^|]/}"
        if (( ${#stripped} != 5 )); then
            ((damaged_count++))
            continue
        fi

        local f_player f_level f_start f_end f_tries f_seconds extra
        IFS='|' read -r f_player f_level f_start f_end f_tries f_seconds extra <<< "$line"

        # Validate required fields and numeric values
        if [[ -z "$f_player" || -z "$f_start" || -z "$f_end" || -n "$extra" ]] || \
           [[ ! "$f_level" =~ ^(easy|normal|hard)$ ]] || \
           [[ ! "$f_tries" =~ ^[0-9]+$ ]] || \
           [[ ! "$f_seconds" =~ ^[0-9]+$ ]]; then
            ((damaged_count++))
            continue
        fi

        printf "%s\n" "$line" >> "$clean_log_file"
    done < "$log_file"

    if (( damaged_count > 0 )); then
        echo "Warning: $damaged_count damaged line(s) were found and skipped"
    fi
}

show_history() {
    echo ""
    echo "=== History for $name ==="
    if [[ ! -s "$clean_log_file" ]]; then
        echo "No games yet"
        return
    fi

    # Check if this player has any valid games before printing the table
    local player_games=0
    local f_player f_level f_start f_end f_tries f_seconds
    while IFS='|' read -r f_player f_level f_start f_end f_tries f_seconds; do
        if [[ "$f_player" == "$name" ]]; then
            ((player_games++))
        fi
    done < "$clean_log_file"

    if (( player_games == 0 )); then
        echo "No games yet"
        return
    fi

    local games=0 total_tries=0 total_sec=0 best_tries=""
    printf "%-8s | %-19s | %-5s | %-7s\n" "Level" "Start Time" "Tries" "Seconds"
    echo "------------------------------------------------"

    while IFS='|' read -r f_player f_level f_start f_end f_tries f_seconds; do
        if [[ "$f_player" == "$name" ]]; then
            printf "%-8s | %-19s | %-5s | %-7s\n" "$f_level" "$f_start" "$f_tries" "$f_seconds"
            ((games++))
            ((total_tries += 10#$f_tries))
            ((total_sec += 10#$f_seconds))
            if [[ -z "$best_tries" ]] || (( 10#$f_tries < 10#$best_tries )); then
                best_tries=$f_tries
            fi
        fi
    done < "$clean_log_file"

    echo "------------------------------------------------"
    local avg_tries=$(( total_tries / games ))
    echo "Summary: $games game(s) | Best: $best_tries tries | Avg: $avg_tries tries | Total time: ${total_sec}s"
}

show_leaderboard() {
    echo ""
    echo "=== Top 5 Leaderboard ($level level) ==="
    if [[ ! -s "$clean_log_file" ]]; then
        echo "No ${level} games played yet."
        return
    fi

    local ranked
    ranked=$(awk -F'|' -v lvl="$level" '
        $2 == lvl {
            player = $1
            tries = $5 + 0
            secs = $6 + 0
            if (!(player in best_tries) || tries < best_tries[player] || (tries == best_tries[player] && secs < best_secs[player])) {
                best_tries[player] = tries
                best_secs[player] = secs
            }
        }
        END {
            for (p in best_tries) {
                printf "%d|%d|%s\n", best_tries[p], best_secs[p], p
            }
        }
    ' "$clean_log_file" | sort -t'|' -k1,1n -k2,2n | head -n 5)

    if [[ -z "$ranked" ]]; then
        echo "No ${level} games played yet."
        return
    fi

    printf "%s\n" "$ranked" | awk -F'|' '
        BEGIN { printf "%-4s | %-15s | %-5s | %-7s\n", "Rank", "Player", "Tries", "Seconds"; print "----------------------------------------" }
        { printf "%-4s | %-15s | %-5s | %-7s\n", NR, $3, $1, $2 }
    '
}

delete_history() {
    if [[ ! -f "$log_file" ]]; then
        echo "No games yet"
        return
    fi

    read -r -p "Are you sure you want to delete all history for '$name'? (y/n): " confirm
    case "${confirm,,}" in
        y)
            local removed_count
            removed_count=$(awk -F'|' -v p="$name" '$1 == p { count++ } END { print count + 0 }' "$log_file")
            local tmp_file
            tmp_file=$(mktemp)
            awk -F'|' -v p="$name" '$1 != p' "$log_file" > "$tmp_file" && mv "$tmp_file" "$log_file"
            echo "Deleted ${removed_count} game(s)"
            ;;
        n)
            echo "Nothing deleted."
            ;;
        *)
            echo "Please answer y or n. Nothing deleted."
            ;;
    esac
}

play_game() {
    local old_best=""

    # Read personal best for the current player and level from the clean data
    if [[ -s "$clean_log_file" ]]; then
        local f_player f_level f_start f_end f_tries f_seconds
        while IFS='|' read -r f_player f_level f_start f_end f_tries f_seconds; do
            if [[ "$f_player" == "$name" && "$f_level" == "$level" ]]; then
                if [[ -z "$old_best" ]] || (( 10#$f_tries < 10#$old_best )); then
                    old_best=$f_tries
                fi
            fi
        done < "$clean_log_file"
    fi

    local guess=-1
    local count=0
    local start_time start_sec end_time end_second duration number

    start_time=$(date '+%Y-%m-%d %H:%M:%S')
    start_sec=$(date +%s)
    number=$(( RANDOM % max + min ))

    echo ""
    while (( guess != number )); do
        read -r -p "Please guess a number between $min and $max (or 'q' to quit round): " guess

        if [[ "${guess,,}" == "q" ]]; then
            echo "Round cancelled."
            return
        fi

        if [[ ! "$guess" =~ ^[0-9]+$ ]]; then
            echo "Please enter a valid number."
            guess=-1
            continue
        fi

        if (( 10#$guess < min || 10#$guess > max )); then
            echo "Out of range! Please enter a number between $min and $max."
            guess=-1
            continue
        fi

        ((count++))

        if (( 10#$guess > number )); then
            echo "Your guess is higher than the number"
        elif (( 10#$guess < number )); then
            echo "Your guess is lower than the number"
        fi
    done

    end_time=$(date '+%Y-%m-%d %H:%M:%S')
    end_second=$(date +%s)
    duration=$(( end_second - start_sec ))

    echo "${name}|${level}|${start_time}|${end_time}|${count}|${duration}" >> "$log_file"

    echo ""
    echo "Performance summary"
    if [[ -z "$old_best" ]]; then
        echo "First time playing $level level! Record saved"
    elif (( count < old_best )); then
        echo "New personal best for $level level!"
    else
        echo "Your personal best of $level level is still $old_best tries."
    fi
    echo "Congratulations!! you guessed correctly after trying $count number time(s)"
}

echo "=========================="
echo "Hi $name, Welcome to our guessing game."
echo "==========================="

while true; do
    echo ""
    load_clean_games
    echo "Player: $name · Level: $level ($min-$max)"
    echo "Menu:"
    echo "  1) Play"
    echo "  2) My History"
    echo "  3) Leaderboard ($level)"
    echo "  4) Delete My History"
    echo "  5) Quit"
    read -r -p "Choose an option: " choice

    case "$choice" in
        1) play_game ;;
        2) show_history ;;
        3) show_leaderboard ;;
        4) delete_history ;;
        5)
            echo "Goodbye, $name!"
            exit 0
            ;;
        *)
            echo "Invalid option. Please choose 1, 2, 3, 4, or 5."
            ;;
    esac
done
