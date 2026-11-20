#!/bin/bash

# Usage check for name and level
name="$1"
level="${2,,}"

if [[ -z "$name" || -z "$level" ]] || [[ "$#" -gt 2 ]]; then
    printf "Usage: ./intro.sh <name> <level>\n"
    printf "Levels: easy, normal, hard\n"
    exit 1
fi

# Set difficulty range
case "$level" in
    easy)   max=50 ;;
    normal) max=100 ;;
    hard)   max=1000 ;;
    *)
        echo "Error: Invalid level '$level'. Choose easy, normal, or hard."
        exit 1
        ;;
esac

log_file="history.log"
damaged_count=0
old_best=""

# Validate existing log file and find personal best safely
if [[ -f "$log_file" ]]; then
    while IFS= read -r line || [[ -n "$line" ]]; do
        [[ -z "$line" ]] && continue

        # Rule 1: Must have 6 fields (5 pipes)
        pipe_count=$(echo -n "$line" | tr -cd '|' | wc -c)
        if (( pipe_count != 5 )); then
            ((damaged_count++))
            continue
        fi

        # Use separate variables so we don't overwrite the current game's stats
        log_name=$(echo "$line" | cut -d '|' -f1)
        log_level=$(echo "$line" | cut -d '|' -f2)
        log_count=$(echo "$line" | cut -d '|' -f5)
        log_seconds=$(echo "$line" | cut -d '|' -f6)

        if [[ ! "$log_level" =~ ^(easy|normal|hard)$ ]] || [[ ! "$log_count" =~ ^[0-9]+$ ]] || [[ ! "$log_seconds" =~ ^[0-9]+$ ]]; then
            ((damaged_count++))
            continue
        fi

        # Track personal best from valid lines only
        if [[ "$log_name" == "$name" && "$log_level" == "$level" ]]; then
            if [[ -z "$old_best" ]] || (( log_count < old_best )); then
                old_best=$log_count
            fi
        fi
    done < "$log_file"
fi

echo "=========================================="
echo "Hi $name, Welcome to our guessing game!"
echo "=========================================="

if (( damaged_count > 0 )); then
    echo "Warning: $damaged_count damaged line(s) were found in $log_file and skipped."
fi

# Game initialization
guess=-1
count=0
number=$(( RANDOM % max + 1 ))
start_time=$(date '+%Y-%m-%d %H:%M:%S')
start_sec=$(date +%s)

# Main guessing loop
while (( guess != number )); do
    read -r -p "Please guess a number between 1 and $max: " guess

    # Validate that input is a positive whole number
    if [[ ! "$guess" =~ ^[0-9]+$ ]]; then
        echo "Invalid input. Please enter a whole number."
        guess=-1
        continue
    fi

    ((count++))

    if (( guess > number )); then
        echo "Your guess is higher than the number."
    elif (( guess < number )); then
        echo "Your guess is lower than the number."
    fi
done

# End timer and calculate duration
end_time=$(date '+%Y-%m-%d %H:%M:%S')
end_sec=$(date +%s)
duration=$(( end_sec - start_sec ))

# Save all 6 fields to history.log
echo "${name}|${level}|${start_time}|${end_time}|${count}|${duration}" >> "$log_file"

# Performance summary
echo ""
echo "--- Performance Summary ---"
echo "Congratulations!! You guessed $number after $count try(s) in ${duration}s."

if [[ -z "$old_best" ]]; then
    echo "First time playing $level level! Record saved."
elif (( count < old_best )); then
    echo "New personal best for $level level! (Previous best: $old_best)"
else
    echo "Your personal best for $level level is still $old_best try(s)."
fi
