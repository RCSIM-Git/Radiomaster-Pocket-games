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
Pokemon Classic - EdgeTX 128x64 Monochrome LCD Simulator
Recreating Gen 1 Game Boy Pokemon Red/Blue for RadioMaster Pocket
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
MID_COLOR = "#306230"    # Accent green

# Game States
STATE_TITLE = 0
STATE_STARTER_SELECT = 1
STATE_OVERWORLD = 2
STATE_START_MENU = 3
STATE_BATTLE_INTRO = 4
STATE_BATTLE_MENU = 5
STATE_BATTLE_MOVES = 6
STATE_BATTLE_BAG = 7
STATE_BATTLE_PARTY = 8
STATE_BATTLE_ANIM = 9
STATE_BATTLE_DIALOGUE = 10
STATE_CATCH_ANIM = 11

# 24x24 Pokemon Sprites (1 = dark, 0 = bg)
SPRITES_24 = {
    "PIKACHU": [
        "......##........##......",
        ".....####......####.....",
        ".....####......####.....",
        "......##........##......",
        ".......##########.......",
        "......############......",
        ".....##############.....",
        "....################....",
        "....###..######..###....",
        "....###..######..###....",
        "....################....",
        "....##.##########.##....",
        "....################....",
        ".....##############.....",
        "......############......",
        ".....##############.....",
        "....################....",
        "...##################...",
        "...####..######..####...",
        "...####..........####...",
        "...####..........####.##",
        "....###..........######.",
        ".....##..........####...",
        "......############......"
    ],
    "CHARMANDER": [
        "........######..........",
        ".......########.........",
        "......##########........",
        ".....############.......",
        ".....###..#######.......",
        ".....###..#######.......",
        ".....############.......",
        "......##########........",
        ".......########.........",
        "........######..........",
        ".......########.........",
        "......##########........",
        ".....############.......",
        ".....############.......",
        ".....############.....#.",
        "......##########.....###",
        "......##########....####",
        ".......########....#####",
        ".......########...######",
        "......##########.#####..",
        ".....####....########...",
        ".....####....#######....",
        "......##......#####.....",
        "...............###......"
    ],
    "SQUIRTLE": [
        "........######..........",
        "......##########........",
        ".....############.......",
        "....##############......",
        "....###..####..###......",
        "....###..####..###......",
        "....##############......",
        ".....############.......",
        "......##########........",
        "....##############......",
        "...################.....",
        "..##################....",
        "..######......######....",
        "..######......######....",
        "..##################..##",
        "...################..###",
        "....##############..####",
        ".....############..####.",
        "......##########..####..",
        ".....####....####.###...",
        "....######..######......",
        "....######..######......",
        ".....####....####.......",
        "........................"
    ],
    "BULBASAUR": [
        "........................",
        ".........####...........",
        "........######..........",
        ".......########.........",
        "......##########........",
        ".....############.......",
        ".....############.......",
        "....###..####..###......",
        "....###..####..###......",
        "....##############......",
        ".....############.......",
        "....##############......",
        "...################.....",
        "..##################....",
        "..##################....",
        "..##################....",
        "..##################....",
        "...################.....",
        "....##############......",
        "....####......####......",
        "...######....######.....",
        "...######....######.....",
        "....####......####......",
        "........................"
    ],
    "PIDGEY": [
        "...........####.........",
        "..........######........",
        ".........########.......",
        "........##########......",
        "........###..#####......",
        "........###..#####......",
        "........##########......",
        ".........########.......",
        ".......############.....",
        "......##############....",
        ".....################...",
        "....##################..",
        "....##################..",
        ".....#################..",
        "......################..",
        ".......##############...",
        "........############....",
        ".........##########.....",
        "..........########......",
        "...........######.......",
        "...........##..##.......",
        "..........###..###......",
        "..........###..###......",
        "...........##...##......"
    ],
    "RATTATA": [
        ".....##........##.......",
        "....####......####......",
        "....####......####......",
        ".....##........##.......",
        "......##########........",
        ".....############.......",
        "....##############......",
        "....###..####..###......",
        "....###..####..###......",
        "....##############......",
        ".....############.......",
        "....##############......",
        "...################.....",
        "..##################..##",
        "..##################.###",
        "..#####################.",
        "...###################..",
        "....################....",
        ".....##############.....",
        "....####........####....",
        "...######......######...",
        "...######......######...",
        "....####........####....",
        "........................"
    ],
    "CATERPIE": [
        "........#..#............",
        ".........##.............",
        ".......######...........",
        "......########..........",
        ".....##########.........",
        ".....###..#####.........",
        ".....##########.........",
        "......########..........",
        ".......######...........",
        "......########..........",
        ".....##########.........",
        ".....##########.........",
        "......########..........",
        ".......######...........",
        "........####............",
        ".........####...........",
        "..........####..........",
        "...........####.........",
        "............####........",
        ".............####.......",
        "..............###.......",
        "...............##.......",
        "................#.......",
        "........................"
    ]
}

# 8x8 Overworld Tiles
# 0: Path, 1: Tall Grass, 2: Tree, 3: Fence, 4: Water, 5: Roof, 6: Wall, 7: Door, 8: Flower, 9: Sign
TILES = {
    0: ["........","........","........","........","........","........","........","........"],
    1: [".#...#..","#.#.#.#.","#.###.#.","..#.#...","#...#.#.","#.#.#.#.","..#.#.#.","........"],
    2: ["..####..",".######.",".######.","########","########",".######.","...##...","...##..."],
    3: ["#..#..#.","########","#..#..#.","########","#..#..#.","#..#..#.",".#..#..#","........"],
    4: ["........","..####..","........","####....","........","..####..","........","####...."],
    5: ["########","########",".######.",".######.","..####..","..####..","...##...","........"],
    6: ["########","#..#..#.","########","..#..#..","########","#..#..#.","########","........"],
    7: ["..####..",".######.",".######.",".######.",".######.",".######.",".######.","........"],
    8: ["........","...#....","..###...","...#....","........","....#...","...###..","....#..."],
    9: [".######.",".#....#.",".######.","...##...","...##...","...##...","...##...","........"]
}

# Player Sprites (8x8)
PLAYER_SPRITES = {
    "DOWN":  ["..####..","..####..",".######.",".######.","..####..","..####..","..#..#..","..#..#.."],
    "UP":    ["..####..","..####..",".######.",".######.","..####..","..####..","..#..#..","..#..#.."],
    "LEFT":  ["..####..",".#####..","..####..",".#####..","..####..","..####..","..##....","..##...."],
    "RIGHT": ["..####..","..#####.","..####..","..#####.","..####..","..####..","....##..","....##.."]
}

# Pokeball Sprite (8x8)
POKEBALL_SPRITE = [
    "..####..",
    ".######.",
    "########",
    "###..###",
    "########",
    ".######.",
    "..####..",
    "........"
]

# Overworld Map Layout (32 wide x 24 tall)
# 2: Tree, 0: Path, 1: Tall Grass, 3: Fence, 5: Roof, 6: Wall, 7: Door, 8: Flower, 9: Sign, 4: Water
MAP_W = 32
MAP_H = 24

MAP_DATA = [
    # 0 - 7 (Route 1 north / Viridian transition)
    [2,2,2,2,2,2,2,2,2,2,2,2,2,2,0,0,0,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2],
    [2,2,1,1,1,1,2,2,1,1,1,1,2,2,0,0,0,2,2,1,1,1,1,2,2,1,1,1,1,2,2,2],
    [2,2,1,1,1,1,2,2,1,1,1,1,2,2,0,0,0,2,2,1,1,1,1,2,2,1,1,1,1,2,2,2],
    [2,2,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,2,2,2],
    [2,2,2,2,3,3,3,3,0,0,0,0,3,3,3,0,3,3,3,0,0,0,0,3,3,3,3,2,2,2,2,2],
    [2,2,1,1,1,1,1,1,0,0,0,0,1,1,1,0,1,1,1,0,0,0,0,1,1,1,1,1,1,2,2,2],
    [2,2,1,1,1,1,1,1,0,0,9,0,1,1,1,0,1,1,1,0,0,0,0,1,1,1,1,1,1,2,2,2],
    [2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,2],
    # 8 - 15 (Route 1 south towards Pallet Town)
    [2,2,0,0,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,0,0,0,2,2,2],
    [2,2,0,0,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,0,0,0,2,2,2],
    [2,2,3,3,3,3,3,3,0,0,0,0,2,2,2,0,2,2,2,0,0,0,3,3,3,3,3,3,0,2,2,2],
    [2,2,1,1,1,1,1,1,0,0,0,0,2,2,2,0,2,2,2,0,0,0,1,1,1,1,1,1,0,2,2,2],
    [2,2,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,0,2,2,2],
    [2,2,2,2,2,2,2,2,3,3,0,0,0,0,0,9,0,0,0,0,3,3,2,2,2,2,2,2,2,2,2,2],
    [2,2,2,2,2,2,2,2,2,2,0,0,0,0,0,0,0,0,0,0,2,2,2,2,2,2,2,2,2,2,2,2],
    [2,2,2,2,2,2,2,2,2,2,0,0,0,0,0,0,0,0,0,0,2,2,2,2,2,2,2,2,2,2,2,2],
    # 16 - 23 (Pallet Town: Ash's House, Oak's Lab, Water)
    [2,2,0,5,5,5,0,0,0,0,0,5,5,5,0,0,0,0,0,0,0,4,4,4,4,4,4,2,2,2,2,2],
    [2,2,0,6,6,6,0,0,0,0,0,6,6,6,0,0,0,0,0,0,0,4,4,4,4,4,4,2,2,2,2,2],
    [2,2,0,6,7,6,0,8,8,0,0,6,7,6,0,8,8,0,0,0,0,4,4,4,4,4,4,2,2,2,2,2],
    [2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,4,4,4,4,4,4,2,2,2,2,2],
    [2,2,0,0,0,5,5,5,5,0,0,0,0,0,0,0,0,0,0,0,0,4,4,4,4,4,4,2,2,2,2,2],
    [2,2,0,0,0,6,6,6,6,0,0,0,0,9,0,0,0,8,8,0,0,4,4,4,4,4,4,2,2,2,2,2],
    [2,2,0,0,0,6,7,6,6,0,0,0,0,0,0,0,0,8,8,0,0,4,4,4,4,4,4,2,2,2,2,2],
    [2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2]
]

# Pokemon Base Data
POKEDEX = {
    "PIKACHU":    {"type": "ELEC",  "hp": 22, "atk": 14, "def": 8,  "spd": 15, "moves": ["THUNDERSHOCK", "QUICK ATTACK", "TAIL WHIP"]},
    "CHARMANDER": {"type": "FIRE",  "hp": 24, "atk": 15, "def": 9,  "spd": 12, "moves": ["EMBER", "SCRATCH", "GROWL"]},
    "SQUIRTLE":   {"type": "WATER", "hp": 26, "atk": 12, "def": 14, "spd": 10, "moves": ["WATER GUN", "TACKLE", "TAIL WHIP"]},
    "BULBASAUR":  {"type": "GRASS", "hp": 25, "atk": 13, "def": 12, "spd": 11, "moves": ["VINE WHIP", "TACKLE", "GROWL"]},
    "PIDGEY":     {"type": "FLY",   "hp": 18, "atk": 11, "def": 7,  "spd": 13, "moves": ["GUST", "QUICK ATTACK"]},
    "RATTATA":    {"type": "NORM",  "hp": 17, "atk": 12, "def": 7,  "spd": 14, "moves": ["TACKLE", "QUICK ATTACK", "TAIL WHIP"]},
    "CATERPIE":   {"type": "BUG",   "hp": 15, "atk": 9,  "def": 8,  "spd": 8,  "moves": ["TACKLE", "STRING SHOT"]}
}

MOVES = {
    "THUNDERSHOCK": {"power": 14, "type": "ELEC",  "pp": 25},
    "QUICK ATTACK": {"power": 10, "type": "NORM",  "pp": 30, "prio": 1},
    "EMBER":        {"power": 14, "type": "FIRE",  "pp": 25},
    "WATER GUN":    {"power": 14, "type": "WATER", "pp": 25},
    "VINE WHIP":    {"power": 14, "type": "GRASS", "pp": 20},
    "GUST":         {"power": 12, "type": "FLY",   "pp": 30},
    "TACKLE":       {"power": 10, "type": "NORM",  "pp": 35},
    "SCRATCH":      {"power": 10, "type": "NORM",  "pp": 35},
    "GROWL":        {"power": 0,  "type": "NORM",  "stat": "ATK_DOWN", "pp": 40},
    "TAIL WHIP":    {"power": 0,  "type": "NORM",  "stat": "DEF_DOWN", "pp": 40},
    "STRING SHOT":  {"power": 0,  "type": "BUG",   "stat": "SPD_DOWN", "pp": 40}
}

class PokemonGameSimulator:
    def __init__(self, root):
        self.root = root
        self.root.title("Pokemon Classic (EdgeTX 128x64 LCD Simulator)")
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

        # Game State
        self.state = STATE_TITLE
        self.title_anim = 0

        # Player
        self.player_x = 14  # tile coords (Pallet town start)
        self.player_y = 19
        self.facing = "DOWN"
        self.step_count = 0

        # Party & Bag
        self.party = []
        self.active_pkmn_idx = 0
        self.bag = {"POKE BALL": 5, "POTION": 3}
        self.money = 300

        # Starter selection
        self.starter_choices = ["PIKACHU", "CHARMANDER", "SQUIRTLE", "BULBASAUR"]
        self.starter_sel = 0

        # Start menu selection
        self.menu_items = ["POKEMON", "BAG", "SAVE", "EXIT"]
        self.menu_sel = 0

        # Battle variables
        self.enemy_pkmn = None
        self.battle_menu_sel = 0  # 0: FIGHT, 1: BAG, 2: PKMN, 3: RUN
        self.battle_move_sel = 0
        self.battle_bag_sel = 0
        self.battle_msg = ""
        self.battle_msg_timer = 0
        self.after_msg_state = None
        self.screen_shake = 0
        self.flash_screen = False

        # Pokeball catch anim
        self.catch_step = 0
        self.catch_timer = 0
        self.catch_wiggles = 0
        self.catch_success = False

        play_wav("intro.wav")

        self.loop()

    def create_pokemon(self, name, level):
        base = POKEDEX[name]
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

    # Input Handlers
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
            # 2x2 grid: 0: FIGHT, 1: BAG, 2: PKMN, 3: RUN
            if dx != 0: self.battle_menu_sel ^= 1
            if dy != 0: self.battle_menu_sel ^= 2
            play_wav("select.wav")
            return

        if self.state == STATE_BATTLE_MOVES:
            pkmn = self.party[self.active_pkmn_idx]
            num_moves = len(pkmn["moves"])
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

            # Check bounds and collision
            if 0 <= nx < MAP_W and 0 <= ny < MAP_H:
                tile = MAP_DATA[ny][nx]
                # Solids: Tree(2), Fence(3), Water(4), Roof(5), Wall(6), Sign(9)
                if tile not in [2, 3, 4, 5, 6, 9]:
                    self.player_x = nx
                    self.player_y = ny
                    self.step_count += 1

                    # Check Tall Grass (1)
                    if tile == 1:
                        # 18% wild encounter roll
                        if random.random() < 0.18:
                            self.trigger_wild_encounter()

    def on_enter(self, event=None):
        if self.state == STATE_TITLE:
            play_wav("select.wav")
            if len(self.party) == 0:
                self.state = STATE_STARTER_SELECT
            else:
                self.state = STATE_OVERWORLD
            return

        if self.state == STATE_STARTER_SELECT:
            choice_name = self.starter_choices[self.starter_sel]
            pkmn = self.create_pokemon(choice_name, 5)
            self.party.append(pkmn)
            self.active_pkmn_idx = 0
            play_wav("catch.wav")
            self.state = STATE_OVERWORLD
            return

        if self.state == STATE_START_MENU:
            item = self.menu_items[self.menu_sel]
            if item == "EXIT":
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
            elif self.battle_menu_sel == 2:  # PKMN
                self.trigger_battle_dialogue("No other PKMN!", STATE_BATTLE_MENU)
            elif self.battle_menu_sel == 3:  # RUN
                play_wav("run.wav")
                self.trigger_battle_dialogue("Got away safely!", STATE_OVERWORLD)
            return

        if self.state == STATE_BATTLE_MOVES:
            pkmn = self.party[self.active_pkmn_idx]
            move_name = pkmn["moves"][self.battle_move_sel]
            self.execute_turn(move_name)
            return

        if self.state == STATE_BATTLE_BAG:
            item_name = list(self.bag.keys())[self.battle_bag_sel]
            if self.bag[item_name] > 0:
                self.bag[item_name] -= 1
                if item_name == "POKE BALL":
                    self.start_catch_attempt()
                elif item_name == "POTION":
                    pkmn = self.party[self.active_pkmn_idx]
                    pkmn["hp"] = min(pkmn["max_hp"], pkmn["hp"] + 20)
                    play_wav("levelup.wav")
                    self.trigger_battle_dialogue(f"Healed 20 HP to {pkmn['name']}!", STATE_BATTLE_MENU)
            else:
                self.trigger_battle_dialogue(f"No {item_name} left!", STATE_BATTLE_BAG)
            return

        if self.state == STATE_OVERWORLD:
            # Check if facing signpost
            dx, dy = 0, 0
            if self.facing == "UP": dy = -1
            elif self.facing == "DOWN": dy = 1
            elif self.facing == "LEFT": dx = -1
            elif self.facing == "RIGHT": dx = 1
            tx = self.player_x + dx
            ty = self.player_y + dy
            if 0 <= tx < MAP_W and 0 <= ty < MAP_H:
                if MAP_DATA[ty][tx] == 9:
                    play_wav("select.wav")
                    return

    def on_action(self, event=None):
        # Space key = [SE] Action / Quick heal at home
        if self.state == STATE_OVERWORLD:
            # Heal party
            for p in self.party:
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
        # Wild pool: Pidgey, Rattata, Caterpie, or rare Pikachu
        r = random.random()
        if r < 0.40:
            name = "PIDGEY"
            lvl = random.randint(2, 4)
        elif r < 0.80:
            name = "RATTATA"
            lvl = random.randint(2, 4)
        elif r < 0.95:
            name = "CATERPIE"
            lvl = random.randint(2, 3)
        else:
            name = "PIKACHU"
            lvl = random.randint(3, 5)

        self.enemy_pkmn = self.create_pokemon(name, lvl)
        self.state = STATE_BATTLE_INTRO
        self.flash_screen = True
        self.battle_msg = f"Wild {name} appeared!"
        self.battle_msg_timer = time.time() + 1.5
        self.after_msg_state = STATE_BATTLE_MENU

    def trigger_battle_dialogue(self, msg, next_state):
        self.battle_msg = msg
        self.after_msg_state = next_state
        self.state = STATE_BATTLE_DIALOGUE
        self.battle_msg_timer = time.time() + 1.4

    def execute_turn(self, player_move):
        player = self.party[self.active_pkmn_idx]
        enemy = self.enemy_pkmn

        # Player attacks
        p_move_data = MOVES[player_move]
        play_wav("hit.wav")
        self.screen_shake = 3

        dmg = max(1, int((p_move_data["power"] * (player["atk"] / enemy["def"])) * (0.85 + random.random()*0.3)))
        # Type advantage check
        if (p_move_data["type"] == "ELEC" and enemy["type"] == "FLY") or \
           (p_move_data["type"] == "WATER" and enemy["type"] == "FIRE") or \
           (p_move_data["type"] == "FIRE" and enemy["type"] == "GRASS") or \
           (p_move_data["type"] == "GRASS" and enemy["type"] == "WATER"):
            dmg = int(dmg * 1.5)

        enemy["hp"] = max(0, enemy["hp"] - dmg)

        if enemy["hp"] == 0:
            play_wav("faint.wav")
            # EXP gain
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
                self.trigger_battle_dialogue(f"Grew to Lv {player['level']}!", STATE_OVERWORLD)
            else:
                self.trigger_battle_dialogue(f"Enemy {enemy['name']} fainted!", STATE_OVERWORLD)
            return

        # Enemy retaliates
        e_move = random.choice(enemy["moves"])
        e_move_data = MOVES[e_move]
        play_wav("hit.wav")
        e_dmg = max(1, int((e_move_data["power"] * (enemy["atk"] / player["def"])) * (0.85 + random.random()*0.3)))
        player["hp"] = max(0, player["hp"] - e_dmg)

        if player["hp"] == 0:
            play_wav("faint.wav")
            # Fainted: respawn at home with full health
            for p in self.party:
                p["hp"] = p["max_hp"]
            self.player_x = 14
            self.player_y = 19
            self.trigger_battle_dialogue(f"{player['name']} fainted! Respawned at home!", STATE_OVERWORLD)
            return

        self.trigger_battle_dialogue(f"{player['name']} hit {dmg} dmg! Enemy used {e_move}!", STATE_BATTLE_MENU)

    def start_catch_attempt(self):
        self.state = STATE_CATCH_ANIM
        self.catch_step = 1
        self.catch_timer = time.time() + 0.6
        self.catch_wiggles = 0
        enemy = self.enemy_pkmn
        # Catch chance
        hp_ratio = enemy["hp"] / enemy["max_hp"]
        chance = 0.85 - (hp_ratio * 0.5)
        self.catch_success = (random.random() < chance)

    def update_catch_anim(self):
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
                    self.party.append(self.enemy_pkmn)
                    self.trigger_battle_dialogue(f"All right! {self.enemy_pkmn['name']} was caught!", STATE_OVERWORLD)
                else:
                    play_wav("faint.wav")
                    self.trigger_battle_dialogue("Oh no! The POKEMON broke free!", STATE_BATTLE_MENU)

    # Rendering Methods
    def draw_bitmap(self, x, y, rows_pattern, invert=False):
        fill = BG_COLOR if invert else PIXEL_COLOR
        for r_idx, row in enumerate(rows_pattern):
            for c_idx, ch in enumerate(row):
                if ch == '#':
                    px = (x + c_idx) * SCALE
                    py = (y + r_idx) * SCALE
                    self.canvas.create_rectangle(px, py, px + SCALE, py + SCALE, fill=fill, outline="")

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
        # Game Boy style title
        self.canvas.create_rectangle(0, 0, WIDTH * SCALE, HEIGHT * SCALE, fill=BG_COLOR, outline="")
        self.canvas.create_text(64 * SCALE, 14 * SCALE, text="POKEMON", fill=PIXEL_COLOR, font=("Consolas", 16, "bold"))
        self.canvas.create_text(64 * SCALE, 28 * SCALE, text="CLASSIC", fill=PIXEL_COLOR, font=("Consolas", 10, "bold"))
        
        # Little bouncing Pokeball
        bx = 64
        by = 38 + int(math.sin(time.time() * 6) * 2)
        self.draw_bitmap(bx - 4, by, POKEBALL_SPRITE)

        if int(time.time() * 2) % 2 == 0:
            self.canvas.create_text(64 * SCALE, 54 * SCALE, text="PRESS [ENT] TO START", fill=PIXEL_COLOR, font=("Consolas", 8, "bold"))

    def render_starter_select(self):
        self.canvas.create_rectangle(0, 0, WIDTH * SCALE, 12 * SCALE, fill=PIXEL_COLOR, outline="")
        self.canvas.create_text(64 * SCALE, 6 * SCALE, text="CHOOSE YOUR STARTER!", fill=BG_COLOR, font=("Consolas", 8, "bold"))

        choice = self.starter_choices[self.starter_sel]
        spr = SPRITES_24[choice]
        self.draw_bitmap(52, 16, spr)

        self.canvas.create_text(64 * SCALE, 44 * SCALE, text=f"< {choice} >", fill=PIXEL_COLOR, font=("Consolas", 9, "bold"))
        base = POKEDEX[choice]
        self.canvas.create_text(64 * SCALE, 55 * SCALE, text=f"TYPE: {base['type']}  HP: {base['hp']}  ATK: {base['atk']}", fill=PIXEL_COLOR, font=("Consolas", 7, "bold"))

    def render_overworld(self):
        # 128x64 LCD = 16x8 tiles of 8x8
        cam_x = self.player_x - 8
        cam_y = self.player_y - 4

        cam_x = max(0, min(MAP_W - 16, cam_x))
        cam_y = max(0, min(MAP_H - 8, cam_y))

        for ty in range(8):
            for tx in range(16):
                mx = cam_x + tx
                my = cam_y + ty
                tile_idx = MAP_DATA[my][mx]
                self.draw_bitmap(tx * 8, ty * 8, TILES[tile_idx])

        # Draw Player in center
        px = (self.player_x - cam_x) * 8
        py = (self.player_y - cam_y) * 8
        p_spr = PLAYER_SPRITES[self.facing]
        self.draw_bitmap(px, py, p_spr)

    def render_start_menu(self):
        # Classic right-side popup menu
        mx = 80
        my = 2
        mw = 46
        mh = 60
        self.canvas.create_rectangle(mx * SCALE, my * SCALE, (mx + mw) * SCALE, (my + mh) * SCALE, fill=BG_COLOR, outline=PIXEL_COLOR, width=2)
        for i, item in enumerate(self.menu_items):
            y = (my + 6 + i * 13) * SCALE
            prefix = "▶" if i == self.menu_sel else " "
            self.canvas.create_text((mx + 6) * SCALE, y, text=f"{prefix}{item}", anchor="w", fill=PIXEL_COLOR, font=("Consolas", 8, "bold"))

    def render_battle(self):
        # Screen shake offset
        off_x = random.randint(-self.screen_shake, self.screen_shake) * SCALE if self.screen_shake > 0 else 0
        self.screen_shake = max(0, self.screen_shake - 1)

        # 1. Top Right: Enemy Pokemon Info & Sprite
        enemy = self.enemy_pkmn
        # Info
        self.canvas.create_text((6 + off_x//SCALE) * SCALE, 6 * SCALE, text=f"{enemy['name']} Lv{enemy['level']}", anchor="w", fill=PIXEL_COLOR, font=("Consolas", 8, "bold"))
        # Enemy HP bar
        hp_pct = max(0.0, min(1.0, enemy["hp"] / enemy["max_hp"]))
        self.canvas.create_rectangle(6 * SCALE, 12 * SCALE, 50 * SCALE, 16 * SCALE, outline=PIXEL_COLOR, width=1)
        if hp_pct > 0:
            self.canvas.create_rectangle(7 * SCALE, 13 * SCALE, (7 + int(hp_pct * 42)) * SCALE, 15 * SCALE, fill=PIXEL_COLOR, outline="")

        # Enemy Sprite (if not in Pokeball)
        if self.state == STATE_CATCH_ANIM and self.catch_step >= 1:
            # Draw bouncing Pokeball instead of enemy
            wiggle_off = (-2 if (self.catch_wiggles % 2 == 1) else 2) if self.catch_step > 1 else 0
            self.draw_bitmap(86 + wiggle_off, 12, POKEBALL_SPRITE)
        else:
            e_spr = SPRITES_24[enemy["name"]]
            self.draw_bitmap(78 + off_x//SCALE, 2, e_spr)

        # 2. Bottom Left: Player Pokemon Info & Sprite
        player = self.party[self.active_pkmn_idx]
        p_spr = SPRITES_24[player["name"]]
        self.draw_bitmap(8, 20, p_spr)

        # Player Info (Right of player)
        self.canvas.create_text(74 * SCALE, 24 * SCALE, text=f"{player['name']} Lv{player['level']}", anchor="w", fill=PIXEL_COLOR, font=("Consolas", 8, "bold"))
        p_hp_pct = max(0.0, min(1.0, player["hp"] / player["max_hp"]))
        self.canvas.create_rectangle(74 * SCALE, 30 * SCALE, 118 * SCALE, 34 * SCALE, outline=PIXEL_COLOR, width=1)
        if p_hp_pct > 0:
            self.canvas.create_rectangle(75 * SCALE, 31 * SCALE, (75 + int(p_hp_pct * 42)) * SCALE, 33 * SCALE, fill=PIXEL_COLOR, outline="")
        self.canvas.create_text(74 * SCALE, 39 * SCALE, text=f"HP: {player['hp']}/{player['max_hp']}", anchor="w", fill=PIXEL_COLOR, font=("Consolas", 7, "bold"))

        # 3. Bottom Panel (128x20 box: y=44..63)
        self.canvas.create_rectangle(0, 44 * SCALE, WIDTH * SCALE, HEIGHT * SCALE, fill=BG_COLOR, outline=PIXEL_COLOR, width=2)

        if self.state in [STATE_BATTLE_INTRO, STATE_BATTLE_DIALOGUE]:
            self.canvas.create_text(6 * SCALE, 53 * SCALE, text=self.battle_msg, anchor="w", fill=PIXEL_COLOR, font=("Consolas", 8, "bold"))

        elif self.state == STATE_CATCH_ANIM:
            w_txt = f"Wiggle {self.catch_wiggles}..." if self.catch_wiggles > 0 else "Throwing Poke Ball!"
            self.canvas.create_text(6 * SCALE, 53 * SCALE, text=w_txt, anchor="w", fill=PIXEL_COLOR, font=("Consolas", 8, "bold"))
            self.update_catch_anim()

        elif self.state == STATE_BATTLE_MENU:
            # 2x2 Grid: 0: FIGHT, 1: BAG, 2: PKMN, 3: RUN
            opts = ["FIGHT", "BAG", "PKMN", "RUN"]
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
                self.canvas.create_text(80 * SCALE, (49 + i * 8) * SCALE, text=f"PP {m_info['pp']}", anchor="w", fill=PIXEL_COLOR, font=("Consolas", 7, "bold"))

        elif self.state == STATE_BATTLE_BAG:
            items = list(self.bag.items())
            for i, (it, count) in enumerate(items):
                pfx = "▶" if i == self.battle_bag_sel else " "
                self.canvas.create_text(6 * SCALE, (49 + i * 8) * SCALE, text=f"{pfx}{it} x{count}", anchor="w", fill=PIXEL_COLOR, font=("Consolas", 8, "bold"))

    def loop(self):
        # Auto-advance dialogue after timer
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
    sim = PokemonGameSimulator(root)
    root.mainloop()
