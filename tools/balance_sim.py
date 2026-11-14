"""Kampung Teduh economy + XP pacing model (Phase 10).

Run:  py -3 tools/balance_sim.py
Numbers are COPIED from src/shared/Config/*.luau — update both when you change a config.
This is a deterministic average-case model, not a bot: it answers "on which day does a
typical player reach Lv N, and can they afford the next unlock?".
"""

import math

# --- Config mirrors ---------------------------------------------------------------------
def xp_to_next(level):  # Progression.xpToNext
    return math.floor(20 * level ** 1.5 + 10 * max(0, level - 8) ** 2.1)

MAX_LEVEL = 30
LEVEL_UP_BUNGA = 2

CROPS = [  # id, unlock, seed, grow_s, sell, xp, harvests
    ("kangkung", 1, 5, 60, 9, 2, 1),
    ("cabai", 1, 10, 180, 20, 3, 1),
    ("tomat", 3, 15, 300, 30, 5, 1),
    ("terong", 5, 25, 600, 50, 8, 1),
    ("jagung", 8, 40, 1200, 85, 12, 1),
    ("singkong", 11, 60, 2700, 140, 20, 1),
    ("padi", 14, 80, 7200, 220, 35, 1),
    ("pisang", 18, 200, 28800, 120, 40, 3),
]
FARM_START, FARM_STEP, FARM_MAX = 6, 3, 21
FARM_COSTS = [300, 800, 2000, 5000, 12000]
WATER = 0.8

RODS = [("bambu", 0, 1, 1.0), ("rotan", 500, 5, 0.85), ("fiber", 2000, 10, 0.75), ("juragan", 6000, 18, 0.65)]
FISH_XP = {"C": 3, "U": 6, "R": 15, "L": 40}
# Average fish value / XP per catch by location for a mix of day phases (no rain), size mult ~1.2.
FISH_AVG = {  # location: (avg sell, avg xp)
    "sungai": (12 * 1.2, 3.6),
    "empang": (17 * 1.2, 4.2),
}
EMPANG_LV = 4
KOLAM_LV, POND_INTERVAL, POND_CAP = 6, 600, 12

def order_value(level):  # Orders.valueTarget
    return 40 + level * 15

ORDER_MULT, XP_PER_KOIN = 1.5, 0.25
WEEKLY_MULT, WEEKLY_COUNT, WEEKLY_TYPES, WEEKLY_XP_MULT, WEEKLY_BUNGA = 3, 3, 4, 0.5, 5
VISIT_KOIN_PER_WEEK = 50 + 75 + 100 + 150 + 200

# --- Player model -------------------------------------------------------------------------
SESSION_MIN = 35        # active minutes per day (target age 9+, casual)
FIRST_SESSION_MIN = 25
FISH_SHARE = 0.5        # share of active time spent fishing (rest: farm loop, walking, decor)
EFFICIENCY = 0.6        # walking, selling, menus, chatting
CAST_OVERHEAD = 4       # cast + reel + popup seconds on top of the bite wait
BITE_AVG = 7
DECOR_SHARE = 0.25      # share of income a player spends on decor (not on progress)


def fishing_rate(level, rod_mult):
    loc = "empang" if level >= EMPANG_LV else "sungai"
    value, xp = FISH_AVG[loc]
    cycle = BITE_AVG * rod_mult + CAST_OVERHEAD
    per_hour = 3600 / cycle * EFFICIENCY
    return value * per_hour, xp * per_hour


def best_active_crop(level):
    best = None
    for crop in CROPS:
        cid, unlock, seed, grow, sell, xp, harvests = crop
        if unlock > level or grow > 600:
            continue
        cycle = grow * WATER + 20
        score = xp / cycle
        if not best or score > best[0]:
            best = (score, crop)
    return best[1]


def best_offline_crop(level):
    best = None
    for crop in CROPS:
        cid, unlock, seed, grow, sell, xp, harvests = crop
        if unlock <= level and grow <= 20 * 3600:
            if not best or xp > best[5]:
                best = crop
    return best


def simulate(days=42):
    level, xp, koin, bunga = 1, 0, 100, 10
    tiles, farm_step, rod_index = FARM_START, 0, 0
    reached = {1: 0.0}
    log = []
    for day in range(1, days + 1):
        minutes = FIRST_SESSION_MIN if day == 1 else SESSION_MIN
        day_xp, day_koin = 0.0, 0.0

        # Offline: one harvest of long crops planted at the end of yesterday's session.
        if day > 1:
            crop = best_offline_crop(level)
            day_xp += crop[5] * tiles
            day_koin += (crop[4] - crop[2]) * tiles
            if level >= KOLAM_LV:
                day_koin += POND_CAP * 12  # common pond fish ~12 Koin
                day_xp += POND_CAP * FISH_XP["C"]

        # Daily orders (avg 1 + level//3 capped at 3 types → average types)
        types = (1 + min(3, 1 + level // 3)) / 2
        order_koin = order_value(level) * types * ORDER_MULT * 3
        day_koin += order_koin
        day_xp += order_koin * XP_PER_KOIN
        if day % 7 == 0:
            weekly_koin = order_value(level) * WEEKLY_TYPES * WEEKLY_COUNT * WEEKLY_MULT
            day_koin += weekly_koin
            day_xp += weekly_koin * XP_PER_KOIN * WEEKLY_XP_MULT
            bunga += WEEKLY_BUNGA
        day_koin += VISIT_KOIN_PER_WEEK / 7

        # Active minutes, simulated per minute so unlocks mid-session apply.
        for minute in range(minutes):
            t = minute / 60
            if minute < minutes * FISH_SHARE:
                k, x = fishing_rate(level, RODS[rod_index][3])
                day_koin += k / 60
                day_xp += x / 60
            else:
                crop = best_active_crop(level)
                cycle = crop[3] * WATER + 20
                per_min = tiles * 60 / cycle
                day_koin += (crop[4] - crop[2]) * per_min
                day_xp += crop[5] * per_min
            # level ups as XP arrives
            xp_total = xp + day_xp
            while level < MAX_LEVEL and xp_total >= xp_to_next(level):
                xp_total -= xp_to_next(level)
                xp -= xp_to_next(level)
                level += 1
                bunga += LEVEL_UP_BUNGA
                reached.setdefault(level, day - 1 + (minute + 1) / minutes)

        xp += day_xp
        while level < MAX_LEVEL and xp >= xp_to_next(level):
            xp -= xp_to_next(level)
            level += 1
            bunga += LEVEL_UP_BUNGA
            reached.setdefault(level, day)
        koin += day_koin * (1 - DECOR_SHARE)

        # Spend on progress: next rod, then farm expansion.
        while rod_index + 1 < len(RODS) and RODS[rod_index + 1][2] <= level and koin >= RODS[rod_index + 1][1]:
            rod_index += 1
            koin -= RODS[rod_index][1]
        while farm_step < len(FARM_COSTS) and koin >= FARM_COSTS[farm_step] * 1.5:
            koin -= FARM_COSTS[farm_step]
            farm_step += 1
            tiles = min(FARM_MAX, tiles + FARM_STEP)

        log.append((day, level, int(koin), bunga, tiles, RODS[rod_index][0], int(day_koin), int(day_xp)))
    return reached, log


if __name__ == "__main__":
    reached, log = simulate()
    print("Level reached on day (fractional = during that day's session):")
    for lv in (5, 10, 15, 20, 25, 30):
        print(f"  Lv{lv:>2}: {reached.get(lv, 'not reached'):>}" if lv in reached else f"  Lv{lv:>2}: not reached in 42 days")
    print("\nday  lv  koin  bunga tiles rod      koin/day xp/day")
    for row in log:
        if row[0] in (1, 2, 3, 5, 7, 10, 14, 21, 28, 35, 42):
            print(f"{row[0]:>3} {row[1]:>3} {row[2]:>6} {row[3]:>5} {row[4]:>5} {row[5]:<8} {row[6]:>7} {row[7]:>6}")
    total = sum(xp_to_next(l) for l in range(1, MAX_LEVEL))
    print(f"\nTotal XP to Lv{MAX_LEVEL}: {total}")
