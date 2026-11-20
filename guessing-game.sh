#!/bin/bash

#this is a guessing game

usage() {
    printf "usage: %s <name> [level]\n" "$0"
    printf "  name  : name of the user playing the game\n"
    printf "  level : easy, normal, or hard (optional, defaults to normal)\n"
    exit 1
}

if [[ "$#" -lt 1 || "$#" -gt 2 ]]; then
    usage
fi

name="$1"
if [[ -z "$name" ]]; then
    usage
fi

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

log_file="history.log"
damaged_count=0

echo "=========================="
echo "Hi $name, Welcome to our guessing game."
echo "==========================="

old_best=$(grep "^${name}|${level}|" "$log_file" 2>/dev/null | cut -d'|' -f5 | sort -n | head -n 1)

guess=-1
count=0
start_time=$(date '+%Y-%m-%d %H:%M:%S')
start_sec=$(date +%s)
number=$(( RANDOM % max + min ))

while (( guess != number )); do
    read -r -p "Please guess a number between $min and $max: " guess

    if [[ ! "$guess" =~ ^[0-9]+$ ]]; then
        echo "Please enter a valid number."
        guess=-1
        continue
    fi

    ((count++))

    if (( guess > number )); then
        echo "Your guess is higher than the number"
    elif (( guess < number )); then
        echo "Your guess is lower than the number"
    fi
done

end_time=$(date '+%Y-%m-%d %H:%M:%S')
end_second=$(date +%s)
duration=$(( $end_second - $start_sec ))

if [[ -f "$log_file" ]];then 
    while IFS= read -r line  || [[ -n "$line" ]]; do    
        #skip empty lines
        [[ -z "$line" ]] && continue

        #rule 1: must have exactly 6 fields (which means exactly 5 pipe characters)
        pipe_count=$(echo -n "$line" | tr -cd '|' | wc -c)
        if (( pipr_count != 5)); then   
            (( damaged_count++))
            continue
        fi

        #extract fields to test them
        level=$(echo "$line" | cut -d '|' -f2)
        count=$(echo "$line" | cut -d '|' -f5)
        seconds=$(echo "$line" | cut -d '|' -f6)

        #level must be easy/hard/normal, tries and seconds must be whole numbers
        if [[ ! "$level" =~ ^(easy|normal|hard)$ ]] || [[ ! "$count" =~ ^[0-9]+$ ]] || [[ ! "seconds" =~ ^[0-9]+$ ]]; then
            ((damaged_count++))
        fi
    done < "$log_file"
fi

#show the menu warning if any broken lines exist
if (( damaged_count > 0 )); then
    echo "Warninf: $damaged_count damaged line(s) were found and skipped"
fi

echo "${name}|${level}|${start_time}|${end_time}|${duration}" >> "$log_file"

echo "Performance summary"
if [ -z "$old_best" ]; then
    echo "First time playing $level level! Record saved"
elif  [[ $count -lt $old_best ]]; then
    echo "New personal best for $level level!"
else 
    echo "Your personal best of $level level is still $old_best tries."
fi
    echo "Congratulations!! you guessed correctly after trying $count number time(s)"
