"""
Desktop PC Simulator for Pocket Pet (RadioMaster Pocket / EdgeTX)
Simulates the 128x64 monochrome LCD display, sound effects, animations, and mini-game.
100% English Edition.
"""

import os
import sys
import time
import random
import tkinter as tk

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

SAVE_PATH = find_asset(os.path.join("SCRIPTS", "TOOLS", "POCKETPET", "pet.dat"))
SOUNDS_DIR = find_asset(os.path.join("SOUNDS", "POCKETPET"))
os.makedirs(os.path.dirname(SAVE_PATH), exist_ok=True)

SCALE = 6
WIDTH = 128
HEIGHT = 64

STAGE_EGG = 0
STAGE_BABY = 1
STAGE_CHILD = 2
STAGE_ADULT_DRONE = 3
STAGE_ADULT_PIKA = 4
STAGE_ADULT_DINO = 5

MODE_MAIN = 0
MODE_FEED_MENU = 1
MODE_STATS = 2
MODE_MINIGAME = 3

ICONS = ["FEED", "REST", "PLAY", "MEDS", "WASH", "STAT"]

class PocketPetSimulator:
    def __init__(self, root):
        self.root = root
        self.root.title("Pocket Pet (FPV Drone Simulator - 128x64 LCD)")
        self.root.resizable(False, False)

        self.BG_COLOR = "#9EAE82"
        self.PIXEL_COLOR = "#121A0E"

        self.canvas = tk.Canvas(
            root, width=WIDTH * SCALE, height=HEIGHT * SCALE,
            bg=self.BG_COLOR, highlightthickness=0
        )
        self.canvas.pack()

        self.status_label = tk.Label(
            root,
            text="[Space]: SE | [Enter]: Select | [<- / ->]: Menu/Fly | [E]: Switch Drone | [R]: Reset Pet | [Esc]: Exit",
            bg="#222", fg="#CCC", font=("Consolas", 10)
        )
        self.status_label.pack(fill=tk.X)

        # Pet State
        self.stage = STAGE_EGG
        self.egg_warmth = 0
        self.hunger = 4
        self.happiness = 4
        self.energy = 100
        self.is_sleeping = False
        self.poops = 0
        self.is_sick = False
        self.age_minutes = 0.0
        self.weight = 5
        self.care_mistakes = 0
        self.total_games = 0

        self.current_mode = MODE_MAIN
        self.selected_icon = 0
        self.feed_sub = 0

        self.pet_x = 64
        self.pet_y = 32
        self.anim_frame = 0
        self.last_anim_tick = time.time()
        self.active_anim = ""
        self.anim_timer = 0

        self.message = "Hello! Charge flight case [Space / SE]!"
        self.message_time = time.time() + 4

        # Mini-game state
        self.mg_score = 0
        self.mg_lives = 3
        self.mg_player_x = 64
        self.mg_items = []
        self.mg_timer = 30
        self.mg_last_sec = time.time()
        self.mg_last_spawn = time.time()

        self.load_state()

        # Bindings
        root.bind("<Left>", self.on_left)
        root.bind("<Right>", self.on_right)
        root.bind("<Return>", self.on_enter)
        root.bind("<space>", self.on_space)
        root.bind("<Escape>", self.on_exit)
        root.bind("1", lambda e: self.quick_action(0))
        root.bind("2", lambda e: self.quick_action(1))
        root.bind("3", lambda e: self.quick_action(2))
        root.bind("4", lambda e: self.quick_action(3))
        root.bind("5", lambda e: self.quick_action(4))
        root.bind("6", lambda e: self.quick_action(5))
        root.bind("<e>", lambda e: self.cycle_stage())
        root.bind("<E>", lambda e: self.cycle_stage())
        root.bind("<r>", lambda e: self.reset_pet())
        root.bind("<R>", lambda e: self.reset_pet())

        self.update_loop()

    def reset_pet(self):
        self.stage = STAGE_EGG
        self.egg_warmth = 0
        self.hunger = 4
        self.happiness = 4
        self.energy = 100
        self.is_sleeping = False
        self.poops = 0
        self.is_sick = False
        self.age_minutes = 0.0
        self.weight = 5
        self.care_mistakes = 0
        self.total_games = 0
        self.current_mode = MODE_MAIN
        self.save_state()
        self.play_sfx("hatch.wav")
        self.trigger_msg("RESET COMPLETE! New flight case!", 3)

    def cycle_stage(self):
        self.stage = (self.stage + 1) % 6
        names = ["CASE", "WHOOP 65mm", "TOOTHPICK 3\"", "5\" FREESTYLE", "CINEWHOOP", "FPV WING"]
        self.trigger_msg(f"Model: {names[self.stage]}!", 3)
        self.play_sfx("happy.wav")

    def play_sfx(self, filename):
        try:
            import winsound
            path = os.path.join(SOUNDS_DIR, filename)
            if os.path.exists(path):
                winsound.PlaySound(path, winsound.SND_FILENAME | winsound.SND_ASYNC)
        except Exception:
            pass

    def trigger_msg(self, text, duration=3):
        self.message = text
        self.message_time = time.time() + duration

    def save_state(self):
        try:
            with open(SAVE_PATH, "w") as f:
                f.write(f"{self.stage},{self.egg_warmth},{self.hunger},{self.happiness},{int(self.energy)},{1 if self.is_sleeping else 0},{self.poops},{1 if self.is_sick else 0},{int(self.age_minutes)},{self.weight},{self.care_mistakes},{self.total_games},50\n")
        except Exception as e:
            print("Save error:", e)

    def load_state(self):
        if not os.path.exists(SAVE_PATH):
            return
        try:
            with open(SAVE_PATH, "r") as f:
                line = f.read().strip()
                parts = [int(p) for p in line.split(",") if p.isdigit()]
                if len(parts) >= 11:
                    self.stage = parts[0]
                    self.egg_warmth = parts[1]
                    self.hunger = parts[2]
                    self.happiness = parts[3]
                    self.energy = parts[4]
                    self.is_sleeping = bool(parts[5])
                    self.poops = parts[6]
                    self.is_sick = bool(parts[7])
                    self.age_minutes = float(parts[8])
                    self.weight = parts[9]
                    self.care_mistakes = parts[10]
                    self.total_games = parts[11] if len(parts) > 11 else 0
        except Exception as e:
            print("Load error:", e)

    def check_evolution(self):
        if self.stage == STAGE_EGG and self.egg_warmth >= 100:
            self.stage = STAGE_BABY
            self.hunger = 2
            self.happiness = 3
            self.play_sfx("hatch.wav")
            self.trigger_msg("DRONE ACTIVATED! Welcome Tiny Whoop!", 4)
            self.save_state()
        elif self.stage == STAGE_BABY and self.age_minutes >= 3:
            self.stage = STAGE_CHILD
            self.play_sfx("win.wav")
            self.trigger_msg("EVOLUTION! Upgraded to Toothpick 3\"!", 4)
            self.save_state()
        elif self.stage == STAGE_CHILD and self.age_minutes >= 8:
            if self.total_games >= 3 and self.care_mistakes <= 1:
                self.stage = STAGE_ADULT_DRONE
                self.trigger_msg("EVOLUTION: 5\" Freestyle Beast Unlocked!", 4)
            elif self.care_mistakes <= 2:
                self.stage = STAGE_ADULT_PIKA
                self.trigger_msg("EVOLUTION: Cinewhoop 4K Pro Unlocked!", 4)
            else:
                self.stage = STAGE_ADULT_DINO
                self.trigger_msg("EVOLUTION: FPV Flying Wing Unlocked!", 4)
            self.play_sfx("win.wav")
            self.save_state()

    def on_left(self, event=None):
        if self.current_mode == MODE_MINIGAME:
            self.mg_player_x = max(15, self.mg_player_x - 5)
        elif self.current_mode == MODE_FEED_MENU:
            self.feed_sub = 0
        elif self.current_mode == MODE_MAIN:
            self.selected_icon = (self.selected_icon - 1) % len(ICONS)

    def on_right(self, event=None):
        if self.current_mode == MODE_MINIGAME:
            self.mg_player_x = min(113, self.mg_player_x + 5)
        elif self.current_mode == MODE_FEED_MENU:
            self.feed_sub = 1
        elif self.current_mode == MODE_MAIN:
            self.selected_icon = (self.selected_icon + 1) % len(ICONS)

    def on_space(self, event=None):
        if self.current_mode == MODE_MAIN:
            if self.stage == STAGE_EGG:
                self.egg_warmth = min(100, self.egg_warmth + 10)
                self.play_sfx("catch.wav")
                self.active_anim = "WOBBLE"
                self.anim_timer = time.time() + 0.3
                self.trigger_msg(f"Charging case! Power: {self.egg_warmth}%", 1.5)
                self.check_evolution()
            else:
                self.happiness = min(4, self.happiness + 1)
                self.play_sfx("happy.wav")
                self.active_anim = "HAPPY"
                self.anim_timer = time.time() + 0.8
                self.trigger_msg("❤️ Motors test OK! Pilot loved!", 2)
                self.save_state()

    def on_enter(self, event=None):
        if self.current_mode == MODE_STATS:
            self.reset_pet()
            self.current_mode = MODE_MAIN
            return
        elif self.current_mode == MODE_FEED_MENU:
            if self.feed_sub == 0:
                if self.hunger >= 4:
                    self.trigger_msg("Full battery! Not hungry! 🍗", 2)
                    self.play_sfx("sick.wav")
                else:
                    self.hunger = min(4, self.hunger + 2)
                    self.weight += 1
                    self.play_sfx("eat.wav")
                    self.active_anim = "EAT"
                    self.anim_timer = time.time() + 0.8
                    self.trigger_msg("Chomp! LiPo pack charged!", 2)
                    self.save_state()
            else:
                self.happiness = min(4, self.happiness + 1)
                self.weight += 2
                self.play_sfx("eat.wav")
                self.active_anim = "EAT"
                self.anim_timer = time.time() + 0.8
                self.trigger_msg("Snack fuel! Delicious! 🍬", 2)
                self.save_state()
            self.current_mode = MODE_MAIN
        elif self.current_mode == MODE_MAIN:
            self.quick_action(self.selected_icon)

    def quick_action(self, idx):
        action = ICONS[idx]
        if action == "FEED":
            if self.stage == STAGE_EGG:
                self.trigger_msg("Case doesn't eat! Charge with [Space / SE]", 2)
            elif self.is_sleeping:
                self.trigger_msg("Sleeping! Wake it up first! 💡", 2)
            else:
                self.current_mode = MODE_FEED_MENU
                self.feed_sub = 0
        elif action == "SLEEP":
            if self.stage == STAGE_EGG:
                self.on_space()
            else:
                self.is_sleeping = not self.is_sleeping
                if self.is_sleeping:
                    self.trigger_msg("Goodnight! Zzz... 💡", 2)
                else:
                    self.trigger_msg("Good morning! Ready to fly! ☀️", 2)
                    self.play_sfx("happy.wav")
                self.save_state()
        elif action == "GAME":
            if self.stage == STAGE_EGG:
                self.trigger_msg("Hatch the drone first!", 2)
            elif self.is_sleeping:
                self.trigger_msg("Sleeping! Wake it up first! 💡", 2)
            elif self.is_sick:
                self.trigger_msg("Glitch detected! Apply service! 💉", 2)
            else:
                self.start_minigame()
        elif action == "MEDS":
            if not self.is_sick:
                self.trigger_msg("Healthy! No service needed! 💉", 2)
            else:
                self.is_sick = False
                self.play_sfx("happy.wav")
                self.active_anim = "HAPPY"
                self.anim_timer = time.time() + 0.8
                self.trigger_msg("Repairs complete! Ready to fly! 💉", 2)
                self.save_state()
        elif action == "WASH":
            if self.poops == 0:
                self.trigger_msg("Already clean! No dirt on motors!", 2)
            else:
                self.poops = 0
                self.play_sfx("clean.wav")
                self.active_anim = "SHOWER"
                self.anim_timer = time.time() + 1.0
                self.trigger_msg("Clean! Props and motors washed! 🚿", 2)
                self.save_state()
        elif action == "STATS":
            self.current_mode = MODE_STATS

    def start_minigame(self):
        self.current_mode = MODE_MINIGAME
        self.mg_score = 0
        self.mg_lives = 3
        self.mg_player_x = 64
        self.mg_items = []
        self.mg_timer = 30
        self.mg_last_sec = time.time()
        self.mg_last_spawn = time.time()
        self.play_sfx("happy.wav")

    def on_exit(self, event=None):
        if self.current_mode != MODE_MAIN:
            self.current_mode = MODE_MAIN
        else:
            self.save_state()
            self.root.destroy()

    def update_loop(self):
        now = time.time()

        if now - self.last_anim_tick > 0.3:
            self.last_anim_tick = now
            self.anim_frame = 1 - self.anim_frame
            self.age_minutes += (0.3 / 60.0)

            if self.stage != STAGE_EGG and not self.is_sleeping:
                if random.random() < 0.01 and self.hunger > 0:
                    self.hunger -= 1
                    if self.hunger <= 1:
                        self.play_sfx("beep.wav")
                        self.trigger_msg("Low Battery! Feed LiPo pack! 🍗", 2)
                if random.random() < 0.008 and self.happiness > 0:
                    self.happiness -= 1
                if random.random() < 0.006 and self.poops < 3:
                    self.poops += 1
                    self.play_sfx("beep.wav")
                    self.trigger_msg("Motors dirty! Wash the props! 🚿", 2)

            self.check_evolution()

        if self.current_mode == MODE_MINIGAME:
            self.update_minigame(now)

        self.render()
        self.root.after(30, self.update_loop)

    def update_minigame(self, now):
        if now - self.mg_last_sec >= 1.0:
            self.mg_last_sec = now
            self.mg_timer -= 1
            if self.mg_timer <= 0:
                self.current_mode = MODE_MAIN
                self.total_games += 1
                self.happiness = min(4, self.happiness + 2)
                self.weight = max(3, self.weight - 1)
                self.play_sfx("win.wav")
                self.trigger_msg(f"GAME OVER! Score: {self.mg_score} pts!", 3)
                self.save_state()
                return

        if now - self.mg_last_spawn > random.uniform(0.6, 1.1):
            self.mg_last_spawn = now
            itype = random.choices([1, 2, 3], weights=[6, 2, 2])[0]
            self.mg_items.append({"x": random.randint(15, 112), "y": 12, "type": itype})

        new_items = []
        for it in self.mg_items:
            it["y"] += 1.8 if it["type"] == 3 else 1.3
            if 46 <= it["y"] <= 54 and abs(it["x"] - self.mg_player_x) < 14:
                if it["type"] == 1:
                    self.mg_score += 10
                    self.play_sfx("catch.wav")
                elif it["type"] == 2:
                    self.mg_score += 5
                    self.play_sfx("eat.wav")
                elif it["type"] == 3:
                    self.mg_lives -= 1
                    self.play_sfx("hurt.wav")
                    if self.mg_lives <= 0:
                        self.current_mode = MODE_MAIN
                        self.total_games += 1
                        self.happiness = min(4, self.happiness + 1)
                        self.trigger_msg("BOMB HIT! Out of lives!", 2)
                        self.save_state()
                        return
            elif it["y"] < 58:
                new_items.append(it)
        self.mg_items = new_items

    def render(self):
        self.canvas.delete("all")
        dark = self.PIXEL_COLOR
        light = self.BG_COLOR

        if self.current_mode == MODE_MINIGAME:
            # Header
            self.canvas.create_rectangle(0, 0, WIDTH * SCALE, 11 * SCALE, fill=dark, outline=dark)
            self.canvas.create_text(24 * SCALE, 5 * SCALE, text=f"SCORE: {self.mg_score}", fill=light, font=("Consolas", 10, "bold"))
            self.canvas.create_text(64 * SCALE, 5 * SCALE, text=f"TIME: {self.mg_timer}s", fill=light, font=("Consolas", 10, "bold"))
            for l in range(self.mg_lives):
                self.canvas.create_text((100 + l * 9) * SCALE, 5 * SCALE, text="♥", fill=light, font=("Consolas", 10, "bold"))

            self.canvas.create_line(0, 56 * SCALE, WIDTH * SCALE, 56 * SCALE, fill=dark, width=2)

            for it in self.mg_items:
                ix, iy = it["x"] * SCALE, it["y"] * SCALE
                if it["type"] == 1:
                    # Battery
                    self.canvas.create_rectangle(ix - 3*SCALE, iy - 3*SCALE, ix + 4*SCALE, iy + 3*SCALE, outline=dark, width=2)
                    self.canvas.create_rectangle(ix + 4*SCALE, iy - 1*SCALE, ix + 5*SCALE, iy + 1*SCALE, fill=dark, outline=dark)
                elif it["type"] == 2:
                    # Snack
                    self.canvas.create_rectangle(ix - 3*SCALE, iy - 3*SCALE, ix + 3*SCALE, iy + 3*SCALE, fill=dark, outline=dark)
                elif it["type"] == 3:
                    # Bomb
                    self.canvas.create_rectangle(ix - 3*SCALE, iy - 3*SCALE, ix + 3*SCALE, iy + 3*SCALE, outline=dark, width=2)
                    self.canvas.create_line(ix, iy - 3*SCALE, ix + 2*SCALE, iy - 5*SCALE, fill=dark, width=2)

            # Player Drone in Mini-game
            px = self.mg_player_x * SCALE
            py = 50 * SCALE
            self.canvas.create_rectangle(px - 6*SCALE, py - 2*SCALE, px + 6*SCALE, py + 3*SCALE, fill=dark, outline=dark)
            self.canvas.create_line(px - 6*SCALE, py, px - 13*SCALE, py - 3*SCALE, fill=dark, width=2)
            self.canvas.create_line(px + 6*SCALE, py, px + 13*SCALE, py - 3*SCALE, fill=dark, width=2)
            self.canvas.create_line(px - 17*SCALE, py - 5*SCALE, px - 9*SCALE, py - 5*SCALE, fill=dark, width=2)
            self.canvas.create_line(px + 9*SCALE, py - 5*SCALE, px + 17*SCALE, py - 5*SCALE, fill=dark, width=2)
            self.canvas.create_line(px + 2*SCALE, py - 2*SCALE, px + 5*SCALE, py - 7*SCALE, fill=dark, width=2)
            self.canvas.create_rectangle(px + 4*SCALE, py - 9*SCALE, px + 7*SCALE, py - 6*SCALE, fill=dark, outline=dark)
            self.canvas.create_rectangle(px - 2*SCALE, py - 1*SCALE, px + 2*SCALE, py + 2*SCALE, fill=light, outline=light)
            return

        if self.current_mode == MODE_STATS:
            self.canvas.create_rectangle(0, 0, WIDTH * SCALE, 11 * SCALE, fill=dark, outline=dark)
            self.canvas.create_text(64 * SCALE, 5 * SCALE, text="DRONE STATUS", fill=light, font=("Consolas", 10, "bold"))

            self.canvas.create_text(24 * SCALE, 16 * SCALE, text="LIPO:", fill=dark, font=("Consolas", 10, "bold"))
            for h in range(4):
                symbol = "♥" if h < self.hunger else "♡"
                self.canvas.create_text((48 + h * 12) * SCALE, 16 * SCALE, text=symbol, fill=dark, font=("Consolas", 12, "bold"))

            self.canvas.create_text(30 * SCALE, 26 * SCALE, text="HAPPINESS:", fill=dark, font=("Consolas", 10, "bold"))
            for h in range(4):
                symbol = "♥" if h < self.happiness else "♡"
                self.canvas.create_text((72 + h * 12) * SCALE, 26 * SCALE, text=symbol, fill=dark, font=("Consolas", 12, "bold"))

            self.canvas.create_text(28 * SCALE, 36 * SCALE, text="ENERGY:", fill=dark, font=("Consolas", 10, "bold"))
            self.canvas.create_rectangle(52 * SCALE, 33 * SCALE, 94 * SCALE, 39 * SCALE, outline=dark, width=1)
            efill = int(self.energy * 0.40)
            if efill > 0:
                self.canvas.create_rectangle(53 * SCALE, 34 * SCALE, (53 + efill) * SCALE, 38 * SCALE, fill=dark, outline=dark)
            self.canvas.create_text(108 * SCALE, 36 * SCALE, text=f"{int(self.energy)}%", fill=dark, font=("Consolas", 9, "bold"))

            self.canvas.create_text(40 * SCALE, 46 * SCALE, text=f"WEIGHT: {self.weight}g   TIME: {int(self.age_minutes)}m", fill=dark, font=("Consolas", 9, "bold"))
            self.canvas.create_text(48 * SCALE, 55 * SCALE, text="8.2V   [Enter]: Reset Pet", fill=dark, font=("Consolas", 9, "bold"))
            return

        # Main Screen
        slot_w = 21 * SCALE
        labels = ["FEED", "REST", "PLAY", "MEDS", "WASH", "STAT"]
        for i, lbl in enumerate(labels):
            x = i * slot_w + 1 * SCALE
            is_sel = (i == self.selected_icon and self.current_mode == MODE_MAIN)
            if is_sel:
                self.canvas.create_rectangle(x, 1 * SCALE, x + slot_w - 2 * SCALE, 10 * SCALE, fill=dark, outline=dark)
                self.canvas.create_text(x + slot_w // 2, 5 * SCALE, text=lbl, fill=light, font=("Consolas", 9, "bold"))
            else:
                self.canvas.create_text(x + slot_w // 2, 5 * SCALE, text=lbl, fill=dark, font=("Consolas", 9, "bold"))
        self.canvas.create_line(0, 11 * SCALE, WIDTH * SCALE, 11 * SCALE, fill=dark)

        # Status Bar
        stage_names = ["CASE", "WHOOP", "TOOTH", "5\"BEAST", "CINE", "WING"]
        self.canvas.create_text(18 * SCALE, 16 * SCALE, text=stage_names[self.stage], fill=dark, font=("Consolas", 8, "bold"))
        self.canvas.create_text(60 * SCALE, 16 * SCALE, text="8.2V", fill=dark, font=("Consolas", 8, "bold"))
        if self.is_sick:
            self.canvas.create_rectangle(86 * SCALE, 12 * SCALE, 124 * SCALE, 20 * SCALE, fill=dark, outline=dark)
            self.canvas.create_text(105 * SCALE, 16 * SCALE, text="SERVICE", fill=light, font=("Consolas", 7, "bold"))
        elif self.poops > 0:
            self.canvas.create_text(105 * SCALE, 16 * SCALE, text=f"{self.poops}xDIRT", fill=dark, font=("Consolas", 8, "bold"))
        elif self.hunger <= 1 and self.stage != STAGE_EGG:
            self.canvas.create_text(105 * SCALE, 16 * SCALE, text="LIPO!", fill=dark, font=("Consolas", 8, "bold"))
        else:
            self.canvas.create_text(105 * SCALE, 16 * SCALE, text="OK", fill=dark, font=("Consolas", 8, "bold"))
        self.canvas.create_line(0, 21 * SCALE, WIDTH * SCALE, 21 * SCALE, fill=dark)

        # Floor
        self.canvas.create_line(0, 53 * SCALE, WIDTH * SCALE, 53 * SCALE, fill=dark, dash=(4, 4))

        # Drone Pet Rendering
        now = time.time()
        is_wobble = (self.active_anim == "WOBBLE" and now < self.anim_timer)
        is_eating = (self.active_anim == "EAT" and now < self.anim_timer)
        px = self.pet_x * SCALE
        hover_off = (-2 if self.anim_frame == 1 else 1) * SCALE
        py = self.pet_y * SCALE + hover_off

        if self.stage == STAGE_EGG:
            # Stage 0: Flight Case / Charging Dock
            ox = px + ((random.randint(-2, 2) if is_wobble else 0) * SCALE)
            self.canvas.create_rectangle(ox - 14*SCALE, py - 8*SCALE, ox + 14*SCALE, py + 10*SCALE, fill=dark, outline=dark)
            self.canvas.create_rectangle(ox - 5*SCALE, py - 10*SCALE, ox + 5*SCALE, py - 7*SCALE, outline=dark, width=2)
            self.canvas.create_rectangle(ox - 9*SCALE, py + 2*SCALE, ox + 9*SCALE, py + 6*SCALE, fill=light, outline=light)
            wfill = int((self.egg_warmth / 100) * 16) * SCALE
            if wfill > 0:
                self.canvas.create_rectangle(ox - 8*SCALE, py + 3*SCALE, ox - 8*SCALE + wfill, py + 5*SCALE, fill=dark, outline=dark)
            self.canvas.create_line(ox + 7*SCALE, py - 8*SCALE, ox + 11*SCALE, py - 14*SCALE, fill=dark, width=2)
            self.canvas.create_rectangle(ox + 10*SCALE, py - 15*SCALE, ox + 13*SCALE, py - 12*SCALE, fill=dark, outline=dark)

        elif self.stage == STAGE_BABY:
            # Stage 1: Tiny Whoop
            self.canvas.create_rectangle(px - 15*SCALE, py - 8*SCALE, px - 5*SCALE, py, outline=dark, width=2)
            self.canvas.create_rectangle(px + 5*SCALE, py - 8*SCALE, px + 15*SCALE, py, outline=dark, width=2)
            self.canvas.create_rectangle(px - 12*SCALE, py + 1*SCALE, px - 3*SCALE, py + 9*SCALE, outline=dark, width=2)
            self.canvas.create_rectangle(px + 3*SCALE, py + 1*SCALE, px + 12*SCALE, py + 9*SCALE, outline=dark, width=2)
            if self.anim_frame == 0:
                self.canvas.create_line(px - 14*SCALE, py - 4*SCALE, px - 6*SCALE, py - 4*SCALE, fill=dark, width=2)
                self.canvas.create_line(px + 6*SCALE, py - 4*SCALE, px + 14*SCALE, py - 4*SCALE, fill=dark, width=2)
                self.canvas.create_line(px - 11*SCALE, py + 5*SCALE, px - 4*SCALE, py + 5*SCALE, fill=dark, width=2)
                self.canvas.create_line(px + 4*SCALE, py + 5*SCALE, px + 11*SCALE, py + 5*SCALE, fill=dark, width=2)
            else:
                self.canvas.create_line(px - 13*SCALE, py - 6*SCALE, px - 7*SCALE, py - 2*SCALE, fill=dark, width=2)
                self.canvas.create_line(px + 7*SCALE, py - 6*SCALE, px + 13*SCALE, py - 2*SCALE, fill=dark, width=2)
            self.canvas.create_rectangle(px - 5*SCALE, py - 5*SCALE, px + 5*SCALE, py + 6*SCALE, fill=dark, outline=dark)
            self.canvas.create_rectangle(px - 3*SCALE, py - 3*SCALE, px + 3*SCALE, py + 1*SCALE, fill=light, outline=light)
            if not is_eating:
                self.canvas.create_rectangle(px - 1*SCALE, py - 2*SCALE, px + 1*SCALE, py, fill=dark, outline=dark)
            self.canvas.create_line(px, py - 5*SCALE, px + 3*SCALE, py - 11*SCALE, fill=dark, width=2)

        elif self.stage == STAGE_CHILD:
            # Stage 2: Toothpick 3" Quad
            self.canvas.create_line(px - 6*SCALE, py - 2*SCALE, px - 17*SCALE, py - 7*SCALE, fill=dark, width=2)
            self.canvas.create_line(px + 6*SCALE, py - 2*SCALE, px + 17*SCALE, py - 7*SCALE, fill=dark, width=2)
            self.canvas.create_line(px - 5*SCALE, py + 3*SCALE, px - 15*SCALE, py + 8*SCALE, fill=dark, width=2)
            self.canvas.create_line(px + 5*SCALE, py + 3*SCALE, px + 15*SCALE, py + 8*SCALE, fill=dark, width=2)
            for mx, my in [(-18, -8), (16, -8), (-16, 7), (14, 7)]:
                self.canvas.create_rectangle((px + mx*SCALE), (py + my*SCALE), (px + (mx+3)*SCALE), (py + (my+3)*SCALE), fill=dark, outline=dark)
                pw = 5 * SCALE
                self.canvas.create_line((px + mx*SCALE) - pw, (py + my*SCALE), (px + (mx+3)*SCALE) + pw, (py + my*SCALE), fill=dark, width=2)
            self.canvas.create_rectangle(px - 6*SCALE, py - 3*SCALE, px + 6*SCALE, py + 5*SCALE, fill=dark, outline=dark)
            self.canvas.create_rectangle(px - 4*SCALE, py - 6*SCALE, px + 4*SCALE, py - 3*SCALE, fill=dark, outline=dark)
            self.canvas.create_rectangle(px - 3*SCALE, py - 1*SCALE, px + 3*SCALE, py + 3*SCALE, fill=light, outline=light)
            self.canvas.create_rectangle(px - 1*SCALE, py, px + 1*SCALE, py + 2*SCALE, fill=dark, outline=dark)
            self.canvas.create_line(px + 4*SCALE, py - 5*SCALE, px + 8*SCALE, py - 11*SCALE, fill=dark, width=2)
            self.canvas.create_rectangle(px + 7*SCALE, py - 12*SCALE, px + 10*SCALE, py - 9*SCALE, fill=dark, outline=dark)

        elif self.stage == STAGE_ADULT_DRONE:
            # Stage 3A: 5" Freestyle Beast
            self.canvas.create_line(px - 7*SCALE, py - 2*SCALE, px - 22*SCALE, py - 7*SCALE, fill=dark, width=3)
            self.canvas.create_line(px + 7*SCALE, py - 2*SCALE, px + 22*SCALE, py - 7*SCALE, fill=dark, width=3)
            self.canvas.create_line(px - 6*SCALE, py + 3*SCALE, px - 19*SCALE, py + 9*SCALE, fill=dark, width=3)
            self.canvas.create_line(px + 6*SCALE, py + 3*SCALE, px + 19*SCALE, py + 9*SCALE, fill=dark, width=3)
            for mx, my in [(-23, -9), (19, -9), (-20, 7), (16, 7)]:
                self.canvas.create_rectangle((px + mx*SCALE), (py + my*SCALE), (px + (mx+4)*SCALE), (py + (my+4)*SCALE), fill=dark, outline=dark)
                pw = 8 * SCALE
                self.canvas.create_line((px + mx*SCALE) - pw, (py + my*SCALE), (px + (mx+4)*SCALE) + pw, (py + my*SCALE), fill=dark, width=2)
            self.canvas.create_rectangle(px - 8*SCALE, py - 4*SCALE, px + 8*SCALE, py + 5*SCALE, fill=dark, outline=dark)
            self.canvas.create_rectangle(px - 6*SCALE, py - 8*SCALE, px + 6*SCALE, py - 4*SCALE, fill=dark, outline=dark)
            self.canvas.create_rectangle(px - 4*SCALE, py - 13*SCALE, px + 4*SCALE, py - 8*SCALE, fill=dark, outline=dark)
            self.canvas.create_rectangle(px - 2*SCALE, py - 12*SCALE, px + 1*SCALE, py - 9*SCALE, fill=light, outline=light)
            self.canvas.create_rectangle(px - 4*SCALE, py - 1*SCALE, px + 4*SCALE, py + 3*SCALE, fill=light, outline=light)
            self.canvas.create_rectangle(px - 2*SCALE, py, px + 2*SCALE, py + 2*SCALE, fill=dark, outline=dark)
            self.canvas.create_line(px + 5*SCALE, py - 6*SCALE, px + 9*SCALE, py - 14*SCALE, fill=dark, width=2)
            self.canvas.create_rectangle(px + 8*SCALE, py - 15*SCALE, px + 11*SCALE, py - 12*SCALE, fill=dark, outline=dark)
            if self.anim_frame == 1:
                self.canvas.create_rectangle(px - 19*SCALE, py + 12*SCALE, px - 16*SCALE, py + 15*SCALE, fill=dark, outline=dark)
                self.canvas.create_rectangle(px + 16*SCALE, py + 12*SCALE, px + 19*SCALE, py + 15*SCALE, fill=dark, outline=dark)

        elif self.stage == STAGE_ADULT_PIKA:
            # Stage 3B: Cinewhoop Pro
            self.canvas.create_rectangle(px - 20*SCALE, py - 9*SCALE, px - 6*SCALE, py + 2*SCALE, outline=dark, width=3)
            self.canvas.create_rectangle(px + 6*SCALE, py - 9*SCALE, px + 20*SCALE, py + 2*SCALE, outline=dark, width=3)
            self.canvas.create_rectangle(px - 16*SCALE, py + 3*SCALE, px - 3*SCALE, py + 13*SCALE, outline=dark, width=3)
            self.canvas.create_rectangle(px + 3*SCALE, py + 3*SCALE, px + 16*SCALE, py + 13*SCALE, outline=dark, width=3)
            self.canvas.create_line(px - 18*SCALE, py - 4*SCALE, px - 8*SCALE, py - 4*SCALE, fill=dark, width=2)
            self.canvas.create_line(px + 8*SCALE, py - 4*SCALE, px + 18*SCALE, py - 4*SCALE, fill=dark, width=2)
            self.canvas.create_rectangle(px - 6*SCALE, py - 6*SCALE, px + 6*SCALE, py + 6*SCALE, fill=dark, outline=dark)
            self.canvas.create_rectangle(px - 3*SCALE, py - 2*SCALE, px + 3*SCALE, py + 4*SCALE, fill=light, outline=light)
            self.canvas.create_rectangle(px - 1*SCALE, py, px + 1*SCALE, py + 2*SCALE, fill=dark, outline=dark)

        elif self.stage == STAGE_ADULT_DINO:
            # Stage 3C: FPV Flying Wing
            self.canvas.create_polygon(px, py - 8*SCALE, px - 22*SCALE, py + 4*SCALE, px + 22*SCALE, py + 4*SCALE, fill=dark, outline=dark)
            self.canvas.create_line(px - 22*SCALE, py + 4*SCALE, px - 22*SCALE, py - 4*SCALE, fill=dark, width=3)
            self.canvas.create_line(px + 22*SCALE, py + 4*SCALE, px + 22*SCALE, py - 4*SCALE, fill=dark, width=3)
            self.canvas.create_rectangle(px - 3*SCALE, py - 8*SCALE, px + 3*SCALE, py - 5*SCALE, fill=light, outline=light)
            self.canvas.create_rectangle(px - 3*SCALE, py + 5*SCALE, px + 3*SCALE, py + 8*SCALE, fill=dark, outline=dark)
            pw = 7 * SCALE
            self.canvas.create_line(px - pw, py + 8*SCALE, px + pw, py + 8*SCALE, fill=dark, width=2)

        # Dirt/Mud clumps
        for p_idx in range(self.poops):
            p_x = (16 + p_idx * 14) * SCALE
            p_y = 48 * SCALE
            self.canvas.create_rectangle(p_x - 3*SCALE, p_y - 2*SCALE, p_x + 3*SCALE, p_y + 2*SCALE, fill=dark)
            self.canvas.create_rectangle(p_x - 2*SCALE, p_y - 4*SCALE, p_x + 2*SCALE, p_y - 1*SCALE, fill=dark)

        # Sleep shading & Zzz
        if self.is_sleeping:
            for x_line in range(0, WIDTH, 3):
                self.canvas.create_line(x_line * SCALE, 22 * SCALE, x_line * SCALE, 52 * SCALE, fill=dark, dash=(2, 4))
            self.canvas.create_text(px + 14 * SCALE, py - 10 * SCALE, text="Z", fill=dark, font=("Consolas", 10, "bold"))
            self.canvas.create_text(px + 20 * SCALE, py - 15 * SCALE, text="z", fill=dark, font=("Consolas", 8, "bold"))

        # Happy Hearts
        if self.active_anim == "HAPPY" and now < self.anim_timer:
            self.canvas.create_text(px - 14 * SCALE, py - 8 * SCALE, text="♥", fill=dark, font=("Consolas", 12, "bold"))
            self.canvas.create_text(px + 14 * SCALE, py - 8 * SCALE, text="♥", fill=dark, font=("Consolas", 12, "bold"))

        # Shower
        if self.active_anim == "SHOWER" and now < self.anim_timer:
            for i in range(5):
                dy = (int(now * 100 + i * 15) % 25) + 24
                self.canvas.create_line((self.pet_x - 6 + i*3)*SCALE, dy*SCALE, (self.pet_x - 6 + i*3)*SCALE, (dy+4)*SCALE, fill=dark, width=2)

        # Feed Menu Modal
        if self.current_mode == MODE_FEED_MENU:
            mx, my, mw, mh = 24 * SCALE, 18 * SCALE, 80 * SCALE, 32 * SCALE
            self.canvas.create_rectangle(mx, my, mx + mw, my + mh, fill=light, outline=dark, width=2)
            self.canvas.create_text(mx + mw // 2, my + 6 * SCALE, text="SELECT FOOD:", fill=dark, font=("Consolas", 9, "bold"))

            items = ["1. LIPO PACK (+2)", "2. SNACK FUEL (+1)"]
            for i, itm in enumerate(items):
                iy = my + (16 + i * 9) * SCALE
                is_sel = (i == self.feed_sub)
                if is_sel:
                    self.canvas.create_rectangle(mx + 4 * SCALE, iy - 4 * SCALE, mx + mw - 4 * SCALE, iy + 4 * SCALE, fill=dark, outline=dark)
                    self.canvas.create_text(mx + mw // 2, iy, text=itm, fill=light, font=("Consolas", 8, "bold"))
                else:
                    self.canvas.create_text(mx + mw // 2, iy, text=itm, fill=dark, font=("Consolas", 8, "bold"))

        # Bottom Hint Bar
        self.canvas.create_line(0, 54 * SCALE, WIDTH * SCALE, 54 * SCALE, fill=dark)
        msg_text = self.message if now < self.message_time else ("[Space / SE] Action   [Enter] Menu   [Esc] Exit")
        self.canvas.create_text(64 * SCALE, 58 * SCALE, text=msg_text, fill=dark, font=("Consolas", 8, "bold"))

if __name__ == "__main__":
    root = tk.Tk()
    app = PocketPetSimulator(root)
    root.mainloop()
