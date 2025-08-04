# Job Posting: Python Developer for Game Trade & State Automation

## Project Overview

We are looking for an experienced Python developer to create a robust automation script for a custom addon in the game World of Warcraft. The addon, "Gamble," facilitates a gold-betting game between players.

The primary goal of this project is to **fully automate the game host's role**. The script must intelligently handle all player interactions, including accepting valid bets, rejecting invalid ones, paying out winnings, and managing inactive players to ensure the game flows smoothly without getting stuck. This requires advanced screen recognition (for colors and text) and human-like mouse/keyboard inputs.

## Key Responsibilities

- Develop a Python script that acts as a state machine, reacting to visual cues from the in-game addon.
- Implement visual recognition to identify:
    - The addon's high-level state via the color of a specific UI frame (Yellow, Purple).
    - The validity of a trade via colored squares that appear next to the trade window (Green, Red).
- Automate the following actions based on the visual cues:
    - **Accept valid bets** by clicking the trade buttons.
    - **Cancel invalid bets** (too high, too low, or no bet placed).
    - **Click the "Roll Dice" button** when the addon indicates it's time.
    - **Pay out winnings** by reading the amount due and entering it into the trade window.
- Ensure all interactions (mouse movements, clicks, delays) are randomized and appear human-like to avoid detection.
- Compile the final Python script into a standalone `.exe` executable.
- Stress-test the application to ensure stability and reliability during long sessions.
- Write clean, well-documented, and extensible code.

---

# Technical Development Requirements

## 1. Core Objective

Create a Python executable that fully automates the "Gamble" addon's game loop. The script must run on Windows and interact with the game client reliably without getting blocked.

## 2. The State-Driven Automation Workflow

The script must operate as a continuous loop that detects and reacts to different states.

### Visual Cues to Monitor:
1.  **Main Frame Color:** The addon's main panel (`mainFrame`) changes color to indicate the overall game state.
    -   **Yellow:** A trade window is open with a player. This is the trigger to begin monitoring the trade details.
    -   **Purple:** A valid bet has been accepted, and it is time to roll the dice.
2.  **Trade Indicator Squares:** Small colored squares appear next to the trade window (`TradeFrame`) to indicate the status of the bet.
    -   **Green Square:** The player has placed a valid bet (within min/max limits) OR there is a pending payout due to the player.
    -   **Red Square:** The player has placed an invalid bet (too high/low) OR has opened a trade and placed no gold for a set period.
3.  **Payout Text:** A text element (`owedMoney`) appears next to the trade window showing the amount of gold due if a player has winnings to collect.

### Required Actions for Each State:

**State 1: Trade Initiated (Yellow Frame appears)**
- **Action:** The script must immediately start monitoring for a Green or Red square next to the trade window.

**State 2: Valid Bet Placed (Green Square appears)**
- **Context:** The player has put the correct amount of gold in the trade window.
- **Action:**
    1.  Move the mouse and click the "Trade" button.
    2.  Wait for the confirmation button to appear.
    3.  Move the mouse and click the final "Accept Trade" button.

**State 3: Invalid Bet or Inactivity (Red Square appears)**
- **Context:** The player's bet is too high/low, or they have been inactive for too long.
- **Action:**
    1.  Move the mouse and click to **cancel** the trade. This is crucial for unblocking the bot for the next player.

**State 4: Payout Due (Green Square + Payout Text appears)**
- **Context:** The player has opened a trade and the addon shows they have a pending payout.
- **Action:**
    1.  Determine the payout amount (see Section 3).
    2.  Move the mouse and click the gold input field in the trade window.
    3.  Type the correct gold amount.
    4.  Proceed to accept the trade as in State 2.

**State 5: Ready to Roll (Purple Frame appears)**
- **Context:** A bet has been successfully accepted. The addon is now waiting for the host to roll the dice.
- **Action:**
    1.  Move the mouse and click the "Roll Dice" button (`GambleAddonRollButton`) on the addon's main panel.

## 3. Determining Payout Amount

The script must accurately determine the amount of gold to be paid. There are two potential methods:

-   **Method A (Preferred - File Monitoring):**
    -   The addon stores its data in a `Gamble.lua` file within the `WTF/Account/<ACCOUNT_NAME>/SavedVariables/` directory.
    -   Inside this file, there is a Lua table `GambleDB["profileKeys"]["<Your_Player_Name> - <Your_Server>"]["pendingPayout"]`. This table contains `playerGUID` -> `amount` pairs.
    -   The script needs to monitor this file for changes, parse the Lua structure, and retrieve the correct payout amount. This is the most reliable method.
-   **Method B (Alternative - OCR):**
    -   Use OCR to read the gold amount from the `owedMoney` text frame on the screen. This requires robust OCR capable of handling the game's font and gold/silver/copper icons.

## 4. Human-like Automation (Critical Requirement)

-   **Mouse Movement:** The mouse cursor must not jump instantly. It should travel in a slightly curved, non-linear path from its current position to the target.
-   **Random Delays:** Introduce variable, randomized delays (e.g., between 0.3s and 1.1s) between each action.
-   **Click Variation:** Clicks should not always happen on the exact same pixel. Define a small bounding box for each target and choose a random coordinate within it for each click.

## 5. Technical Specifications & Deliverables

-   **Language:** Python 3.x.
-   **Libraries:** `pyautogui`, `pydirectinput`, `opencv-python`, `pytesseract` / `easyocr`, or other suitable libraries.
-   **Deliverables:**
    1.  Full, commented Python Source Code.
    2.  A standalone `.exe` file (created with `PyInstaller` or similar).
    3.  `requirements.txt` file.
    4.  `README.md` with setup and usage instructions.