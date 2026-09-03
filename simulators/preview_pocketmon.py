def find_asset(rel_path):
    base_dirs = [
        os.getcwd(),
        os.path.abspath(os.path.join(os.path.dirname(__file__), "..")),
        os.path.dirname(__file__),
    ]
    for b in base_dirs:
        p1 = os.path.join(b, rel_path)
        if os.path.exists(p1):
            return p1
        p2 = os.path.join(b, "POCKET", rel_path)
        if os.path.exists(p2):
            return p2
    return rel_path

"""
Pocketmon: Drone Edition - EdgeTX 128x64 Monochrome LCD Simulator
Authentic FPV Drone RPG for RadioMaster Pocket / MT12
"""

import tkinter as tk
import time
import random
import os
import math

try:
    import winsound
    def play_wav(filename):
        path = find_asset(os.path.join("SOUNDS", "POKEMON", filename))
        if os.path.exists(path):
            winsound.PlaySound(path, winsound.SND_FILENAME | winsound.SND_ASYNC)
except ImportError:
    def play_wav(filename):
        pass

WIDTH = 128
HEIGHT = 64
SCALE = 5

# Game Boy LCD Palette
BG_COLOR = "#8BAC0F"     # Retro light green
PIXEL_COLOR = "#0F380F"  # Retro dark green

# Game States
STATE_TITLE = 0
STATE_STARTER_SELECT = 1
STATE_OVERWORLD = 2
STATE_START_MENU = 3
STATE_BATTLE_INTRO = 4
STATE_BATTLE_MENU = 5
STATE_BATTLE_MOVES = 6
STATE_BATTLE_BAG = 7
STATE_BATTLE_DIALOGUE = 8
STATE_CATCH_ANIM = 9

# 24x24 FPV Drone Sprites
SPRITES_24 = {
    "WHOOPY": [
        "....####........####....",
        "...######......######...",
        "..##.##.##....##.##.##..",
        "..######.######.######..",
        "...######..##..######...",
        "....####..####..####....",
        ".........######.........",
        "........########........",
        "..##....########....##..",
        ".####...###..###...####.",
        "######..###..###..######",
        "######..########..######",
        ".####...########...####.",
        "..##....########....##..",
        ".........######.........",
        "....####..####..####....",
        "...######..##..######...",
        "..######.######.######..",
        "..##.##.##....##.##.##..",
        "...######......######...",
        "....####........####....",
        "........................",
        "........................",
        "........................"
    ],
    "5\"BEAST": [
        "###..................###",
        ".#####............#####.",
        "..######........######..",
        "...######......######...",
        "....######....######....",
        ".....######..######.....",
        "......############......",
        ".......##########.......",
        "........########........",
        ".........######.........",
        ".......##########.......",
        "......############......",
        "......############......",
        ".......##########.......",
        ".........######.........",
        "........########........",
        ".......##########.......",
        "......############......",
        ".....######..######.....",
        "....######....######....",
        "...######......######...",
        "..######........######..",
        ".#####............#####.",
        "###..................###"
    ],
    "TOOTHY": [
        "........................",
        "..##................##..",
        "...####..........####...",
        "....####........####....",
        ".....####......####.....",
        "......####....####......",
        ".......##########.......",
        "........########........",
        ".........######.........",
        ".........##..##.........",
        "........########........",
        ".......##########.......",
        ".......##########.......",
        "........########........",
        ".........##..##.........",
        ".........######.........",
        "........########........",
        ".......##########.......",
        "......####....####......",
        ".....####......####.....",
        "....####........####....",
        "...####..........####...",
        "..##................##..",
        "........................"
    ],
    "CINEMAX": [
        "..########....########..",
        ".##########..##########.",
        "############.###########",
        "############.###########",
        "###..##..##############.",
        "###..##..##############.",
        "############.###########",
        ".##########..##########.",
        "..########....########..",
        ".........######.........",
        "........########........",
        "........########........",
        "........########........",
        ".........######.........",
        "..########....########..",
        ".##########..##########.",
        "############.###########",
        "###..##..##############.",
        "###..##..##############.",
        "############.###########",
        "############.###########",
        ".##########..##########.",
        "..########....########..",
        "........................"
    ],
    "MOBULA 7": [
        "....####........####....",
        "...######......######...",
        "..########....########..",
        "..##.##.##....##.##.##..",
        "...######..##..######...",
        "....####..####..####....",
        ".........######.........",
        "........########........",
        "........###..###........",
        "........########........",
        ".........######.........",
        "....####..####..####....",
        "...######..##..######...",
        "..##.##.##....##.##.##..",
        "..########....########..",
        "...######......######...",
        "....####........####....",
        "........................",
        "........................",
        "........................",
        "........................",
        "........................",
        "........................",
        "........................"
    ],
    "NAZGUL 5": [
        "##....................##",
        ".####..............####.",
        "..####............####..",
        "...####..........####...",
        "....####........####....",
        ".....#####....#####.....",
        "......############......",
        ".......##########.......",
        "........########........",
        ".........######.........",
        ".......##########.......",
        "......############......",
        "......############......",
        ".......##########.......",
        ".........######.........",
        "........########........",
        ".......##########.......",
        "......############......",
        ".....#####....#####.....",
        "....####........####....",
        "...####..........####...",
        "..####............####..",
        ".####..............####.",
        "##....................##"
    ],
    "PHANTOM": [
        "........................",
        "...........##...........",
        "..........####..........",
        ".........######.........",
        "........########........",
        ".......##########.......",
        "......############......",
        ".....##############.....",
        "....################....",
        "...##################...",
        "..####################..",
        "..##..############..##..",
        "..##...##########...##..",
        "..##....########....##..",
        "..##.....######.....##..",
        "..##......####......##..",
        "..##.......##.......##..",
        "..##................##..",
        "..##................##..",
        "..##................##..",
        ".####..............####.",
        "######............######",
        "........................",
        "........................"
    ]
}

# 8x8 Overworld Tiles
# 0: Airfield Tarmac, 1: Tall Weeds/Obstacles, 2: Trees, 3: Safety Fence, 4: Water, 5: Hangar Roof, 6: Hangar Wall, 7: Workbench Door, 8: Cones/Gates, 9: Windsock/Sign
TILES = {
    0: ["........","........","........","........","........","........","........","........"],
    1: [".#...#..","#.#.#.#.","#.###.#.","..#.#...","#...#.#.","#.#.#.#.","..#.#.#.","........"],
    2: ["..####..",".######.",".######.","########","########",".######.","...##...","...##..."],
    3: ["#..#..#.","########","#..#..#.","########","#..#..#.","#..#..#.",".#..#..#","........"],
    4: ["........","..####..","........","####....","........","..####..","........","####...."],
    5: ["########","########",".######.",".######.","..####..","..####..","...##...","........"],
    6: ["########","#..#..#.","########","..#..#..","########","#..#..#.","########","........"],
    7: ["..####..",".######.",".######.",".######.",".######.",".######.",".######.","........"],
    8: ["...##...","..####..",".######.","########","...##...","..####..",".######.","........"],
    9: [".######.",".#....#.",".######.","...##...","...##...","...##...","...##...","........"]
}

# Pilot Player Sprites (with FPV goggles on forehead!)
PLAYER_SPRITES = {
    "DOWN":  [".######.",".##..##.","..####..",".######.","..####..","..####..","..#..#..","..#..#.."],
    "UP":    [".######.",".######.","..####..",".######.","..####..","..####..","..#..#..","..#..#.."],
    "LEFT":  [".######.",".###....","..####..",".#####..","..####..","..####..","..##....","..##...."],
    "RIGHT": [".######.","....###.","..####..","..#####.","..####..","..####..","....##..","....##.."]
}

# ELRS Bind Packet Sprite (8x8 antenna)
BIND_SPRITE = [
    "...##...",
    "...##...",
    ".######.",
    "##.##.##",
    "...##...",
    "..####..",
    ".######.",
    "..####.."
]

MAP_W = 32
MAP_H = 24

MAP_DATA = [
    [2,2,2,2,2,2,2,2,2,2,2,2,2,2,0,0,0,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2],
    [2,2,1,1,1,1,2,2,1,1,1,1,2,2,0,0,0,2,2,1,1,1,1,2,2,1,1,1,1,2,2,2],
    [2,2,1,1,1,1,2,2,1,1,1,1,2,2,0,0,0,2,2,1,1,1,1,2,2,1,1,1,1,2,2,2],
    [2,2,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,2,2,2],
    [2,2,2,2,3,3,3,3,0,0,0,0,3,3,3,0,3,3,3,0,0,0,0,3,3,3,3,2,2,2,2,2],
    [2,2,1,1,1,1,1,1,0,0,0,0,1,1,1,0,1,1,1,0,0,0,0,1,1,1,1,1,1,2,2,2],
    [2,2,1,1,1,1,1,1,0,0,9,0,1,1,1,0,1,1,1,0,0,0,0,1,1,1,1,1,1,2,2,2],
    [2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,2],
    [2,2,0,0,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,0,0,0,2,2,2],
    [2,2,0,0,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,0,0,0,2,2,2],
    [2,2,3,3,3,3,3,3,0,0,0,0,2,2,2,0,2,2,2,0,0,0,3,3,3,3,3,3,0,2,2,2],
    [2,2,1,1,1,1,1,1,0,0,0,0,2,2,2,0,2,2,2,0,0,0,1,1,1,1,1,1,0,2,2,2],
    [2,2,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,0,2,2,2],
    [2,2,2,2,2,2,2,2,3,3,0,0,0,0,0,9,0,0,0,0,3,3,2,2,2,2,2,2,2,2,2,2],
    [2,2,2,2,2,2,2,2,2,2,0,0,0,0,0,0,0,0,0,0,2,2,2,2,2,2,2,2,2,2,2,2],
    [2,2,2,2,2,2,2,2,2,2,0,0,0,0,0,0,0,0,0,0,2,2,2,2,2,2,2,2,2,2,2,2],
    [2,2,0,5,5,5,0,0,0,0,0,5,5,5,0,0,0,0,0,0,0,4,4,4,4,4,4,2,2,2,2,2],
    [2,2,0,6,6,6,0,0,0,0,0,6,6,6,0,0,0,0,0,0,0,4,4,4,4,4,4,2,2,2,2,2],
    [2,2,0,6,7,6,0,8,8,0,0,6,7,6,0,8,8,0,0,0,0,4,4,4,4,4,4,2,2,2,2,2],
    [2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,4,4,4,4,4,4,2,2,2,2,2],
    [2,2,0,0,0,5,5,5,5,0,0,0,0,0,0,0,0,0,0,0,0,4,4,4,4,4,4,2,2,2,2,2],
    [2,2,0,0,0,6,6,6,6,0,0,0,0,9,0,0,0,8,8,0,0,4,4,4,4,4,4,2,2,2,2,2],
    [2,2,0,0,0,6,7,6,6,0,0,0,0,0,0,0,0,8,8,0,0,4,4,4,4,4,4,2,2,2,2,2],
    [2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2]
]

DRONEDEX = {
    "WHOOPY":   {"type": "MICRO", "hp": 22, "atk": 13, "def": 9,  "spd": 16, "moves": ["THROTTLE PUNCH", "PROP CHOP", "TURTLE MODE"]},
    "5\"BEAST":  {"type": "ACRO",  "hp": 26, "atk": 16, "def": 12, "spd": 12, "moves": ["POWER LOOP", "PROP CHOP", "BEEPER BLAST"]},
    "TOOTHY":   {"type": "RACE",  "hp": 20, "atk": 14, "def": 8,  "spd": 18, "moves": ["THROTTLE PUNCH", "YAW SPIN", "TURTLE MODE"]},
    "CINEMAX":  {"type": "CINE",  "hp": 28, "atk": 11, "def": 15, "spd": 9,  "moves": ["DUST BLOW", "PROP CHOP", "SMOOTH ROLL"]},
    "MOBULA 7": {"type": "MICRO", "hp": 18, "atk": 11, "def": 8,  "spd": 14, "moves": ["PROP CHOP", "YAW SPIN"]},
    "NAZGUL 5": {"type": "ACRO",  "hp": 24, "atk": 15, "def": 11, "spd": 13, "moves": ["POWER LOOP", "PROP CHOP", "BEEPER BLAST"]},
    "PHANTOM":  {"type": "GPS",   "hp": 30, "atk": 10, "def": 16, "spd": 7,  "moves": ["RETURN HOME", "DUST BLOW"]}
}

MOVES = {
    "THROTTLE PUNCH": {"power": 14, "type": "ACRO",  "pp": 25},
    "PROP CHOP":      {"power": 10, "type": "MICRO", "pp": 30},
    "POWER LOOP":     {"power": 15, "type": "ACRO",  "pp": 20},
    "YAW SPIN":       {"power": 11, "type": "RACE",  "pp": 25},
    "SMOOTH ROLL":    {"power": 12, "type": "CINE",  "pp": 25},
    "DUST BLOW":      {"power": 8,  "type": "CINE",  "pp": 30},
    "RETURN HOME":    {"power": 14, "type": "GPS",   "pp": 15},
    "TURTLE MODE":    {"power": 0,  "type": "MICRO", "stat": "DEF_UP",   "pp": 40},
    "BEEPER BLAST":   {"power": 0,  "type": "ACRO",  "stat": "DEF_DOWN", "pp": 40}
}

class PocketmonSimulator:
    def __init__(self, root):
        self.root = root
        self.root.title("Pocketmon: Drone Edition (EdgeTX 128x64 LCD Simulator)")
        self.root.resizable(False, False)

        self.canvas = tk.Canvas(
            root, width=WIDTH * SCALE, height=HEIGHT * SCALE,
            bg=BG_COLOR, highlightthickness=0
        )
        self.canvas.pack()

        # Keyboard bindings
        self.root.bind("<Up>", lambda e: self.on_move(0, -1))
        self.root.bind("<Down>", lambda e: self.on_move(0, 1))
        self.root.bind("<Left>", lambda e: self.on_move(-1, 0))
        self.root.bind("<Right>", lambda e: self.on_move(1, 0))
        self.root.bind("<w>", lambda e: self.on_move(0, -1))
        self.root.bind("<s>", lambda e: self.on_move(0, 1))
        self.root.bind("<a>", lambda e: self.on_move(-1, 0))
        self.root.bind("<d>", lambda e: self.on_move(1, 0))

        self.root.bind("<Return>", self.on_enter)
        self.root.bind("<space>", self.on_action)
        self.root.bind("<Escape>", self.on_back)
        self.root.bind("<BackSpace>", self.on_back)

        # State
        self.state = STATE_TITLE
        self.player_x = 14
        self.player_y = 19
        self.facing = "DOWN"
        self.step_count = 0

        # Hangar & Gear
        self.hangar = []
        self.active_drone_idx = 0
        self.bag = {"BIND PACKET": 5, "LIPO 4S": 3}

        # Starters
        self.starter_choices = ["WHOOPY", "5\"BEAST", "TOOTHY", "CINEMAX"]
        self.starter_sel = 0

        # Start menu
        self.menu_items = ["HANGAR", "GEAR", "SAVE", "EXIT"]
        self.menu_sel = 0

        # Battle
        self.enemy_drone = None
        self.battle_menu_sel = 0
        self.battle_move_sel = 0
        self.battle_bag_sel = 0
        self.battle_msg = ""
        self.battle_msg_timer = 0
        self.after_msg_state = None
        self.screen_shake = 0

        # Bind anim
        self.catch_step = 0
        self.catch_timer = 0
        self.catch_wiggles = 0
        self.catch_success = False

        play_wav("intro.wav")

        self.loop()

    def create_drone(self, name, level):
        base = DRONEDEX[name]
        hp_max = base["hp"] + (level * 3)
        return {
            "name": name,
            "level": level,
            "hp": hp_max,
            "max_hp": hp_max,
            "atk": base["atk"] + (level * 2),
            "def": base["def"] + (level * 2),
            "spd": base["spd"] + (level * 2),
            "type": base["type"],
            "moves": list(base["moves"]),
            "exp": 0,
            "next_exp": level * 15
        }

    def on_move(self, dx, dy):
        if self.state == STATE_STARTER_SELECT:
            if dx < 0: self.starter_sel = (self.starter_sel - 1) % len(self.starter_choices)
            if dx > 0: self.starter_sel = (self.starter_sel + 1) % len(self.starter_choices)
            play_wav("select.wav")
            return

        if self.state == STATE_START_MENU:
            if dy < 0: self.menu_sel = (self.menu_sel - 1) % len(self.menu_items)
            if dy > 0: self.menu_sel = (self.menu_sel + 1) % len(self.menu_items)
            play_wav("select.wav")
            return

        if self.state == STATE_BATTLE_MENU:
            if dx != 0: self.battle_menu_sel ^= 1
            if dy != 0: self.battle_menu_sel ^= 2
            play_wav("select.wav")
            return

        if self.state == STATE_BATTLE_MOVES:
            drone = self.hangar[self.active_drone_idx]
            num_moves = len(drone["moves"])
            if dy < 0: self.battle_move_sel = (self.battle_move_sel - 1) % num_moves
            if dy > 0: self.battle_move_sel = (self.battle_move_sel + 1) % num_moves
            play_wav("select.wav")
            return

        if self.state == STATE_BATTLE_BAG:
            items = list(self.bag.keys())
            if dy < 0: self.battle_bag_sel = (self.battle_bag_sel - 1) % len(items)
            if dy > 0: self.battle_bag_sel = (self.battle_bag_sel + 1) % len(items)
            play_wav("select.wav")
            return

        if self.state == STATE_OVERWORLD:
            if dx > 0: self.facing = "RIGHT"
            elif dx < 0: self.facing = "LEFT"
            elif dy > 0: self.facing = "DOWN"
            elif dy < 0: self.facing = "UP"

            nx = self.player_x + dx
            ny = self.player_y + dy

            if 0 <= nx < MAP_W and 0 <= ny < MAP_H:
                tile = MAP_DATA[ny][nx]
                if tile not in [2, 3, 4, 5, 6, 9]:
                    self.player_x = nx
                    self.player_y = ny
                    self.step_count += 1
                    if tile == 1 and random.random() < 0.18:
                        self.trigger_wild_encounter()

    def on_enter(self, event=None):
        if self.state == STATE_TITLE:
            play_wav("select.wav")
            if len(self.hangar) == 0:
                self.state = STATE_STARTER_SELECT
            else:
                self.state = STATE_OVERWORLD
            return

        if self.state == STATE_STARTER_SELECT:
            choice_name = self.starter_choices[self.starter_sel]
            drone = self.create_drone(choice_name, 5)
            self.hangar.append(drone)
            self.active_drone_idx = 0
            play_wav("catch.wav")
            self.state = STATE_OVERWORLD
            return

        if self.state == STATE_START_MENU:
            item = self.menu_items[self.menu_sel]
            if item == "EXIT" or item == "HANGAR":
                self.state = STATE_OVERWORLD
            elif item == "SAVE":
                play_wav("catch.wav")
                self.state = STATE_OVERWORLD
            return

        if self.state == STATE_BATTLE_DIALOGUE:
            if self.after_msg_state is not None:
                next_st = self.after_msg_state
                self.after_msg_state = None
                self.state = next_st
            return

        if self.state == STATE_BATTLE_MENU:
            if self.battle_menu_sel == 0:  # FIGHT
                self.battle_move_sel = 0
                self.state = STATE_BATTLE_MOVES
                play_wav("select.wav")
            elif self.battle_menu_sel == 1:  # BAG
                self.battle_bag_sel = 0
                self.state = STATE_BATTLE_BAG
                play_wav("select.wav")
            elif self.battle_menu_sel == 2:  # HANGAR
                self.trigger_battle_dialogue("Only 1 Quad in Hangar!", STATE_BATTLE_MENU)
            elif self.battle_menu_sel == 3:  # DISARM
                play_wav("run.wav")
                self.trigger_battle_dialogue("Disarmed & flew away safely!", STATE_OVERWORLD)
            return

        if self.state == STATE_BATTLE_MOVES:
            drone = self.hangar[self.active_drone_idx]
            move_name = drone["moves"][self.battle_move_sel]
            self.execute_turn(move_name)
            return

        if self.state == STATE_BATTLE_BAG:
            item_name = list(self.bag.keys())[self.battle_bag_sel]
            if self.bag[item_name] > 0:
                self.bag[item_name] -= 1
                if item_name == "BIND PACKET":
                    self.start_bind_attempt()
                elif item_name == "LIPO 4S":
                    drone = self.hangar[self.active_drone_idx]
                    drone["hp"] = min(drone["max_hp"], drone["hp"] + 20)
                    play_wav("levelup.wav")
                    self.trigger_battle_dialogue(f"Swapped LiPo! +20 mAh to {drone['name']}!", STATE_BATTLE_MENU)
            else:
                self.trigger_battle_dialogue(f"No {item_name} in bag!", STATE_BATTLE_BAG)
            return

    def on_action(self, event=None):
        if self.state == STATE_OVERWORLD:
            for p in self.hangar:
                p["hp"] = p["max_hp"]
            play_wav("levelup.wav")

    def on_back(self, event=None):
        if self.state == STATE_OVERWORLD:
            self.state = STATE_START_MENU
            self.menu_sel = 0
            play_wav("select.wav")
        elif self.state == STATE_START_MENU:
            self.state = STATE_OVERWORLD
        elif self.state in [STATE_BATTLE_MOVES, STATE_BATTLE_BAG]:
            self.state = STATE_BATTLE_MENU
            play_wav("select.wav")

    def trigger_wild_encounter(self):
        play_wav("battle.wav")
        r = random.random()
        if r < 0.45:
            name = "MOBULA 7"
            lvl = random.randint(2, 4)
        elif r < 0.80:
            name = "NAZGUL 5"
            lvl = random.randint(2, 4)
        elif r < 0.95:
            name = "TOOTHY"
            lvl = random.randint(2, 3)
        else:
            name = "PHANTOM"
            lvl = random.randint(4, 6)

        self.enemy_drone = self.create_drone(name, lvl)
        self.state = STATE_BATTLE_INTRO
        self.battle_msg = f"Rogue {name} buzzed in!"
        self.battle_msg_timer = time.time() + 1.5
        self.after_msg_state = STATE_BATTLE_MENU

    def trigger_battle_dialogue(self, msg, next_state):
        self.battle_msg = msg
        self.after_msg_state = next_state
        self.state = STATE_BATTLE_DIALOGUE
        self.battle_msg_timer = time.time() + 1.4

    def execute_turn(self, p_move):
        player = self.hangar[self.active_drone_idx]
        enemy = self.enemy_drone

        p_move_data = MOVES[p_move]
        play_wav("hit.wav")
        self.screen_shake = 3

        dmg = max(1, int((p_move_data["power"] * (player["atk"] / enemy["def"])) * (0.85 + random.random()*0.3)))
        # Type matchup
        if (p_move_data["type"] == "ACRO" and enemy["type"] == "GPS") or \
           (p_move_data["type"] == "RACE" and enemy["type"] == "ACRO") or \
           (p_move_data["type"] == "CINE" and enemy["type"] == "RACE") or \
           (p_move_data["type"] == "MICRO" and enemy["type"] == "CINE"):
            dmg = int(dmg * 1.5)

        enemy["hp"] = max(0, enemy["hp"] - dmg)

        if enemy["hp"] == 0:
            play_wav("faint.wav")
            exp_gain = enemy["level"] * 8
            player["exp"] += exp_gain
            if player["exp"] >= player["next_exp"]:
                player["level"] += 1
                player["max_hp"] += 3
                player["hp"] = player["max_hp"]
                player["atk"] += 2
                player["def"] += 2
                player["spd"] += 2
                player["next_exp"] = player["level"] * 15
                play_wav("levelup.wav")
                self.trigger_battle_dialogue(f"{player['name']} tuned to Lv {player['level']}!", STATE_OVERWORLD)
            else:
                self.trigger_battle_dialogue(f"Rogue {enemy['name']} crashed!", STATE_OVERWORLD)
            return

        # Enemy turn
        e_move = random.choice(enemy["moves"])
        e_move_data = MOVES[e_move]
        play_wav("hit.wav")
        e_dmg = max(1, int((e_move_data["power"] * (enemy["atk"] / player["def"])) * (0.85 + random.random()*0.3)))
        player["hp"] = max(0, player["hp"] - e_dmg)

        if player["hp"] == 0:
            play_wav("faint.wav")
            for p in self.hangar:
                p["hp"] = p["max_hp"]
            self.player_x = 14
            self.player_y = 19
            self.trigger_battle_dialogue(f"{player['name']} crashed! Repaired at Paddock!", STATE_OVERWORLD)
            return

        self.trigger_battle_dialogue(f"{player['name']} dealt {dmg}! Rogue used {e_move}!", STATE_BATTLE_MENU)

    def start_bind_attempt(self):
        self.state = STATE_CATCH_ANIM
        self.catch_step = 1
        self.catch_timer = time.time() + 0.6
        self.catch_wiggles = 0
        enemy = self.enemy_drone
        hp_ratio = enemy["hp"] / enemy["max_hp"]
        chance = 0.85 - (hp_ratio * 0.5)
        self.catch_success = (random.random() < chance)

    def update_bind_anim(self):
        now = time.time()
        if now >= self.catch_timer:
            if self.catch_step <= 3:
                self.catch_wiggles += 1
                play_wav("select.wav")
                self.catch_step += 1
                self.catch_timer = now + 0.5
            else:
                if self.catch_success:
                    play_wav("catch.wav")
                    self.hangar.append(self.enemy_drone)
                    self.trigger_battle_dialogue(f"Telemetry Bound! {self.enemy_drone['name']} in Hangar!", STATE_OVERWORLD)
                else:
                    play_wav("faint.wav")
                    self.trigger_battle_dialogue("Signal lost! Quad failed to bind!", STATE_BATTLE_MENU)

    def draw_bitmap(self, x, y, rows_pattern):
        for r_idx, row in enumerate(rows_pattern):
            for c_idx, ch in enumerate(row):
                if ch == '#':
                    px = (x + c_idx) * SCALE
                    py = (y + r_idx) * SCALE
                    self.canvas.create_rectangle(px, py, px + SCALE, py + SCALE, fill=PIXEL_COLOR, outline="")

    def render(self):
        self.canvas.delete("all")
        if self.state == STATE_TITLE:
            self.render_title()
        elif self.state == STATE_STARTER_SELECT:
            self.render_starter_select()
        elif self.state == STATE_OVERWORLD:
            self.render_overworld()
        elif self.state == STATE_START_MENU:
            self.render_overworld()
            self.render_start_menu()
        elif self.state in [STATE_BATTLE_INTRO, STATE_BATTLE_MENU, STATE_BATTLE_MOVES, STATE_BATTLE_BAG, STATE_BATTLE_DIALOGUE, STATE_CATCH_ANIM]:
            self.render_battle()

    def render_title(self):
        self.canvas.create_rectangle(0, 0, WIDTH * SCALE, HEIGHT * SCALE, fill=BG_COLOR, outline="")
        self.canvas.create_text(64 * SCALE, 14 * SCALE, text="POCKETMON", fill=PIXEL_COLOR, font=("Consolas", 16, "bold"))
        self.canvas.create_text(64 * SCALE, 27 * SCALE, text="DRONE EDITION", fill=PIXEL_COLOR, font=("Consolas", 9, "bold"))
        
        bx = 64
        by = 38 + int(math.sin(time.time() * 6) * 2)
        self.draw_bitmap(bx - 4, by, BIND_SPRITE)

        if int(time.time() * 2) % 2 == 0:
            self.canvas.create_text(64 * SCALE, 54 * SCALE, text="PRESS [ENT] TO ARM", fill=PIXEL_COLOR, font=("Consolas", 8, "bold"))

    def render_starter_select(self):
        self.canvas.create_rectangle(0, 0, WIDTH * SCALE, 12 * SCALE, fill=PIXEL_COLOR, outline="")
        self.canvas.create_text(64 * SCALE, 6 * SCALE, text="CHOOSE YOUR FIRST QUAD!", fill=BG_COLOR, font=("Consolas", 8, "bold"))

        choice = self.starter_choices[self.starter_sel]
        spr = SPRITES_24[choice]
        self.draw_bitmap(52, 16, spr)

        self.canvas.create_text(64 * SCALE, 44 * SCALE, text=f"< {choice} >", fill=PIXEL_COLOR, font=("Consolas", 9, "bold"))
        base = DRONEDEX[choice]
        self.canvas.create_text(64 * SCALE, 55 * SCALE, text=f"T:{base['type']}  HP:{base['hp']}  ATK:{base['atk']}  SPD:{base['spd']}", fill=PIXEL_COLOR, font=("Consolas", 7, "bold"))

    def render_overworld(self):
        cam_x = max(0, min(MAP_W - 16, self.player_x - 8))
        cam_y = max(0, min(MAP_H - 8, self.player_y - 4))

        for ty in range(8):
            for tx in range(16):
                mx = cam_x + tx
                my = cam_y + ty
                t_idx = MAP_DATA[my][mx]
                self.draw_bitmap(tx * 8, ty * 8, TILES[t_idx])

        px = (self.player_x - cam_x) * 8
        py = (self.player_y - cam_y) * 8
        self.draw_bitmap(px, py, PLAYER_SPRITES[self.facing])

    def render_start_menu(self):
        mx = 78
        my = 2
        mw = 48
        mh = 58
        self.canvas.create_rectangle(mx * SCALE, my * SCALE, (mx + mw) * SCALE, (my + mh) * SCALE, fill=BG_COLOR, outline=PIXEL_COLOR, width=2)
        for i, item in enumerate(self.menu_items):
            y = (my + 6 + i * 13) * SCALE
            prefix = "▶" if i == self.menu_sel else " "
            self.canvas.create_text((mx + 4) * SCALE, y, text=f"{prefix}{item}", anchor="w", fill=PIXEL_COLOR, font=("Consolas", 8, "bold"))

    def render_battle(self):
        off_x = random.randint(-self.screen_shake, self.screen_shake) * SCALE if self.screen_shake > 0 else 0
        self.screen_shake = max(0, self.screen_shake - 1)

        enemy = self.enemy_drone
        self.canvas.create_text((4 + off_x//SCALE) * SCALE, 6 * SCALE, text=f"{enemy['name']} Lv{enemy['level']}", anchor="w", fill=PIXEL_COLOR, font=("Consolas", 8, "bold"))
        
        hp_pct = max(0.0, min(1.0, enemy["hp"] / enemy["max_hp"]))
        self.canvas.create_rectangle(4 * SCALE, 12 * SCALE, 50 * SCALE, 16 * SCALE, outline=PIXEL_COLOR, width=1)
        if hp_pct > 0:
            self.canvas.create_rectangle(5 * SCALE, 13 * SCALE, (5 + int(hp_pct * 44)) * SCALE, 15 * SCALE, fill=PIXEL_COLOR, outline="")

        if self.state == STATE_CATCH_ANIM and self.catch_step >= 1:
            wiggle_off = (-2 if (self.catch_wiggles % 2 == 1) else 2) if self.catch_step > 1 else 0
            self.draw_bitmap(86 + wiggle_off, 12, BIND_SPRITE)
        else:
            e_spr = SPRITES_24[enemy["name"]]
            self.draw_bitmap(78 + off_x//SCALE, 2, e_spr)

        player = self.hangar[self.active_drone_idx]
        p_spr = SPRITES_24[player["name"]]
        self.draw_bitmap(8, 20, p_spr)

        self.canvas.create_text(74 * SCALE, 24 * SCALE, text=f"{player['name']} Lv{player['level']}", anchor="w", fill=PIXEL_COLOR, font=("Consolas", 8, "bold"))
        p_hp_pct = max(0.0, min(1.0, player["hp"] / player["max_hp"]))
        self.canvas.create_rectangle(74 * SCALE, 30 * SCALE, 118 * SCALE, 34 * SCALE, outline=PIXEL_COLOR, width=1)
        if p_hp_pct > 0:
            self.canvas.create_rectangle(75 * SCALE, 31 * SCALE, (75 + int(p_hp_pct * 42)) * SCALE, 33 * SCALE, fill=PIXEL_COLOR, outline="")
        self.canvas.create_text(74 * SCALE, 39 * SCALE, text=f"HP:{player['hp']}/{player['max_hp']}", anchor="w", fill=PIXEL_COLOR, font=("Consolas", 7, "bold"))

        self.canvas.create_rectangle(0, 44 * SCALE, WIDTH * SCALE, HEIGHT * SCALE, fill=BG_COLOR, outline=PIXEL_COLOR, width=2)

        if self.state in [STATE_BATTLE_INTRO, STATE_BATTLE_DIALOGUE]:
            self.canvas.create_text(6 * SCALE, 53 * SCALE, text=self.battle_msg, anchor="w", fill=PIXEL_COLOR, font=("Consolas", 8, "bold"))

        elif self.state == STATE_CATCH_ANIM:
            w_txt = f"Binding... Packet {self.catch_wiggles}" if self.catch_wiggles > 0 else "Sending ELRS Bind phrase!"
            self.canvas.create_text(6 * SCALE, 53 * SCALE, text=w_txt, anchor="w", fill=PIXEL_COLOR, font=("Consolas", 8, "bold"))
            self.update_bind_anim()

        elif self.state == STATE_BATTLE_MENU:
            opts = ["FIGHT", "BAG", "HANGAR", "DISARM"]
            coords = [(8, 49), (68, 49), (8, 57), (68, 57)]
            for i, opt in enumerate(opts):
                pfx = "▶" if i == self.battle_menu_sel else " "
                cx, cy = coords[i]
                self.canvas.create_text(cx * SCALE, cy * SCALE, text=f"{pfx}{opt}", anchor="w", fill=PIXEL_COLOR, font=("Consolas", 8, "bold"))

        elif self.state == STATE_BATTLE_MOVES:
            moves = player["moves"]
            for i, m in enumerate(moves[:2]):
                pfx = "▶" if i == self.battle_move_sel else " "
                m_info = MOVES[m]
                self.canvas.create_text(6 * SCALE, (49 + i * 8) * SCALE, text=f"{pfx}{m}", anchor="w", fill=PIXEL_COLOR, font=("Consolas", 8, "bold"))
                self.canvas.create_text(84 * SCALE, (49 + i * 8) * SCALE, text=f"PP {m_info['pp']}", anchor="w", fill=PIXEL_COLOR, font=("Consolas", 7, "bold"))

        elif self.state == STATE_BATTLE_BAG:
            items = list(self.bag.items())
            for i, (it, count) in enumerate(items):
                pfx = "▶" if i == self.battle_bag_sel else " "
                self.canvas.create_text(6 * SCALE, (49 + i * 8) * SCALE, text=f"{pfx}{it} x{count}", anchor="w", fill=PIXEL_COLOR, font=("Consolas", 8, "bold"))

    def loop(self):
        if self.state in [STATE_BATTLE_INTRO, STATE_BATTLE_DIALOGUE]:
            if time.time() > self.battle_msg_timer:
                if self.after_msg_state is not None:
                    next_st = self.after_msg_state
                    self.after_msg_state = None
                    self.state = next_st

        self.render()
        self.root.after(33, self.loop)

if __name__ == "__main__":
    root = tk.Tk()
    sim = PocketmonSimulator(root)
    root.mainloop()
