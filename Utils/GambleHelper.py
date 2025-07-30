import os
import re
import pyautogui
import pygetwindow as gw
import time
from slpp import slpp as lua

# --- CONFIGURATION ---
# Path to your WoW Classic WTF folder. If empty, the script will try to find it.
WOW_WTF_PATH = ""
# Example: "C:\\Program Files (x86)\\World of Warcraft\\_classic_\\WTF"

ADDON_SAVED_VARS_FILE = "GambleDB.lua"

# --- DO NOT EDIT BELOW THIS LINE ---

def find_wow_wtf_folder():
    """Tries to find the WoW WTF folder automatically."""
    if WOW_WTF_PATH and os.path.isdir(WOW_WTF_PATH):
        print(f"Using provided WTF folder: {WOW_WTF_PATH}")
        return WOW_WTF_PATH

    print("No WTF path provided, searching in common locations...")
    common_paths = [
        "C:\\Program Files (x86)\\World of Warcraft\\_classic_\\WTF",
        "C:\\Program Files\\World of Warcraft\\_classic_\\WTF",
        "D:\\Games\\World of Warcraft\\_classic_\\WTF",
    ]
    for path in common_paths:
        if os.path.isdir(path):
            print(f"Found WoW WTF folder at: {path}")
            return path
    return None

def find_saved_vars_file(wtf_path):
    """Finds the GambleDB.lua file within the WTF folder."""
    print(f"Searching for {ADDON_SAVED_VARS_FILE} in {wtf_path}...")
    for root, _, files in os.walk(wtf_path):
        if ADDON_SAVED_VARS_FILE in files:
            file_path = os.path.join(root, ADDON_SAVED_VARS_FILE)
            print(f"Found addon database file: {file_path}")
            return file_path
    print(f"Error: Could not find {ADDON_SAVED_VARS_FILE}. Make sure the addon is installed and has been run at least once.")
    return None

def parse_lua_db(file_path):
    """Parses the Lua SavedVariables file."""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            # The file content is `GambleDB = { ... }`. We need to extract the table.
            content = f.read()
            # Basic extraction: find the first '{' and the last '}'
            match = re.search(r'=\s*(\{.*\})', content, re.DOTALL)
            if not match:
                print("Error: Could not find a valid Lua table in the file.")
                return None
            
            lua_table_str = match.group(1)
            parsed_data = lua.decode(lua_table_str)
            return parsed_data
    except FileNotFoundError:
        print(f"Error: File not found at {file_path}")
        return None
    except Exception as e:
        print(f"An error occurred while parsing the Lua file: {e}")
        return None

def get_player_debt(player_name, db_data):
    """Calculates the debt for a specific player."""
    if not db_data or "completeGames" not in db_data:
        # This can happen if the DB structure is unexpected or empty
        if "profile" in db_data and "players" in db_data["profile"]:
             # Fallback to checking the 'players' table if completeGames is missing
            player_stats = db_data["profile"]["players"].get(player_name)
            if player_stats and 'paid' in player_stats and 'won' in player_stats:
                debt = player_stats.get('paid', 0) - player_stats.get('won', 0)
                return int(debt) if debt > 0 else 0
        return 0 # Return 0 if no data is available

    player_name_lower = player_name.lower()
    total_paid = 0
    total_won = 0

    game_history = db_data.get("completeGames", {})
    for _, game in game_history.items():
        if game.get("name", "").lower() == player_name_lower:
            total_paid += game.get("bet", 0)
            if game.get("outcome") == "WIN":
                total_won += game.get("payout", 0)
    
    debt = total_paid - total_won
    # Return the debt only if it's a positive value, converted to gold (assuming input is in copper)
    return int(debt / 10000) if debt > 0 else 0

def main():
    print("--- Gamble Helper Script ---")
    wtf_path = find_wow_wtf_folder()
    if not wtf_path:
        input("Could not find WoW WTF folder. Press Enter to exit.")
        return

    db_file_path = find_saved_vars_file(wtf_path)
    if not db_file_path:
        input("Could not find addon database file. Press Enter to exit.")
        return

    print("\nMonitoring for WoW trade windows...")
    
    # This is a placeholder for the main loop
    # In the next step, we will implement the trade window detection
    # and interaction logic here.
    try:
        while True:
            db_data = parse_lua_db(db_file_path)
            if not db_data:
                print("Could not read or parse database file. Retrying in 10 seconds...")
                time.sleep(10)
                continue

            # Example usage:
            # trade_window = gw.getWindowsWithTitle("Trade")[0] # Example
            # if trade_window:
            #     player_name = trade_window.title.split("'s Trade")[0] # Example
            #     debt_in_gold = get_player_debt(player_name, db_data)
            #     if debt_in_gold > 0:
            #         print(f"{player_name} has a debt of {debt_in_gold}g.")
            #         # Here we would add the pyautogui logic to input the gold
            
            time.sleep(2) # Check every 2 seconds
            
    except KeyboardInterrupt:
        print("\nScript stopped by user.")


if __name__ == "__main__":
    # Note: This script requires the 'pygetwindow', 'pyautogui', and 'slpp' packages.
    # You can install them by running:
    # pip install pygetwindow pyautogui slpp
    main()