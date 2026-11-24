# 🏷 guess-game

A command-line number guessing game written in Bash. You can pick a difficulty level, track your game history, and see how you rank on the leaderboard.

## 📌 Problem Statement

I built this project to practice writing clean Bash scripts—specifically handling user input, working with files, and breaking code into reusable functions.

## 🎯 Project Goals

- Let players guess a random number within a chosen range until they get it right
- Validate player names and ignore out-of-range guesses so they don't ruin the try count
- Save game results and track each player's personal best per difficulty level
- Display game history, a Top 5 leaderboard, and safely delete a player's records

## 🛠 Tech Stack

- Bash
- Git & GitHub

## 📷 Screenshots

![guess-game](<assets/images/Screenshot From 2026-10-24 09-18-08.png>)

## ⚙ Installation & Setup

Clone the repository and make the script executable:

    git clone https://github.com/NyapB/bash_05_guess_game.git
    cd bash_05_guess_game
    chmod +x guess-game.sh

## 💻 How to Start the Game

Run the script with your player name and an optional difficulty level (if you leave the level out, it defaults to normal):

    ./guessing-game.sh <name> [level]

Examples:

    # Play on the default level (normal)
    ./guessing-game.sh ama

    # Play on hard mode
    ./guessing-game.sh ama hard

    # Save logs to a custom file instead of history.log
    GAMES_FILE=test.txt ./guessing-game.sh ama easy

Note: Player names can only include letters, numbers, underscores, or hyphens, and are converted to lowercase automatically.

## 🎚 Difficulty Levels

- easy: 1 to 50
- normal: 1 to 100 (default)
- hard: 1 to 1000

## 📋 Menu Choices

Once the game starts, the menu displays your name, level, and range (for example: Player: ama · Level: hard (1-1000)) along with 5 options:

1. Play: Starts a round, tells you if your guess is too high or too low, skips out-of-range numbers without counting them, saves your result, and checks for a new personal best.
2. My History: Lists all your past games across every level, plus your total games, best score, average tries, and total time played.
3. Leaderboard: Shows the Top 5 players for your current level (one best game per player, sorted by fewest tries and then fastest time).
4. Delete My History: Asks for y/n confirmation, removes only your rows using a temporary file, and tells you how many games were deleted.
5. Quit: Exits the game.

## 📄 File Format

Completed games are stored in history.log (or whatever file you pass in GAMES_FILE) with 6 pipe-separated (|) fields per line:

    player|level|start|end|tries|seconds

Example:

    ama|normal|2026-11-20 10:00:00|2026-11-20 10:00:12|5|12

If any broken or incomplete lines end up in the file, the script skips them and prints a warning at the top of the menu.

## 🧠 Challenges Faced

- Keeping out-of-range guesses from increasing the player's try count
- Checking for damaged lines in history.log once at the start of the menu loop without crashing
- Sorting the leaderboard by fewest tries first and breaking ties with the fastest time

## 📚 What I Learned

- Working with RANDOM, arithmetic comparisons, and date timestamps in Bash
- Reading and filtering pipe-separated files using IFS='|' read and awk
- Splitting a script into functions and safely updating files with mktemp

## 👨🏽‍💻 Author

Nyap Becky Beri  
Junior Fullstack Developer  
beribecky8@gmail.com  
🌍 Based in Cameroon | Open to remote opportunities
