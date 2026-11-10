"""Small inked characters for the waiting room (48x72, feet at y=66). Usage: python3 -I tools/boss/chars.py
Player: front/back/side x 3 walk frames. NPCs: one pose each (the game makes them breathe)."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import kit
from kit import *
kit.BOX[:] = [0, 0, 48, 72]
DST = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "assets", "2d", "chars")
def rect(x, y, w, h): return [(x, y), (x + w, y), (x + w, y + h), (x, y + h)]
def dot(x, y, r, c, o=1): raw(f'<circle cx="{x}" cy="{y}" r="{r}" fill="{c}" opacity="{o}"/>')

def legs(p, step, side=False, sit=False):
    if sit:                                             # knees toward us, feet dangling
        for x in (15, 26):
            shape(rect(x, 46, 8, 13), p["pants"], INK, 1.3, hard=True, j=0.3); shape(rect(x - 1, 58, 10, 5), p["shoes"], INK, 1.2, hard=True, j=0.3)
        return
    if side:
        for i, dx in enumerate((-step * 4, step * 4)):
            shape([(20 + dx * 0.3, 48), (28 + dx * 0.3, 48), (28 + dx, 62), (20 + dx, 62)], p["pants"], INK, 1.3, hard=True, j=0.3)
            shape(rect(17 + dx, 61, 12, 5), p["shoes"], INK, 1.2, hard=True, j=0.3)
        return
    for i, x in enumerate((15, 26)):
        up = 3 if (step == 1 and i == 0) or (step == -1 and i == 1) else 0
        shape(rect(x, 48, 8, 14 - up), p["pants"], INK, 1.3, hard=True, j=0.3)
        shape(rect(x - 1, 61 - up, 10, 5), p["shoes"], INK, 1.2, hard=True, j=0.3)

def person(p, d="front", step=0, sit=False, extra=None):
    raw('<ellipse cx="24" cy="66" rx="15" ry="4.5" fill="#000" opacity="0.4"/>')
    side = d == "side"
    by = 4 if sit else 0                                # sitting = whole upper body lower
    legs(p, step, side, sit)
    raw(f'<g transform="translate(0 {by + (1 if step else 0)})">')
    if side:
        body = [(16, 30), (24, 28), (32, 31), (33, 50), (15, 50)]
    else:
        body = [(11, 32), (18, 28), (30, 28), (37, 32), (38, 51), (10, 51)]
    bd = shape(body, p["coat"], INK, 1.6, j=0.4)
    hatch([bd], 70, 3, INK, 0.6, 0.4, seg=(4, 12))
    tone([(30, 28), (38, 32), (38, 51), (31, 51)], "#000", 0.25, [bd], hard=True)
    if not side and d == "front":
        line([(24, 30), (24, 50)], INK, 1, 0.8, j=0.2)
        if p.get("shirt"): shape([(20, 28), (28, 28), (24, 36)], p["shirt"], INK, 1, hard=True, j=0.2)
    if side:
        sw_ = step * 3
        shape([(21, 32), (27, 32), (27 + sw_, 46), (21 + sw_, 46)], p["coat"], INK, 1.3, hard=True, j=0.3); dot(24 + sw_, 47.5, 2.6, p["skin"])
    else:
        for i, x in enumerate((7, 36)):
            dy = (2 if (step == 1) == (i == 1) else -1) if step else 0
            shape(rect(x, 32 + dy, 5.5, 15), p["coat"], INK, 1.3, hard=True, j=0.3); dot(x + 2.7, 48.5 + dy, 2.6, p["skin"])
    if extra: extra("body", d)
    # head
    hx = 25.5 if side else 24
    hd = shape(blob(hx, 17, 12.5, 12, 12, 0.03), p["skin"], INK, 1.7, j=0.3)
    tone([(hx + 3, 6), (hx + 13, 10), (hx + 13, 28), (hx + 5, 29)], "#000", 0.18, [hd], hard=True)
    p["hair"](d, hx)
    if d == "front":
        for x in (19.5, 28.5):
            dot(x, 18, 1.7, INK); line([(x - 2.5, 21.5), (x, 22.5), (x + 2.5, 21.5)], "#3d3026", 0.8, 0.8, j=0.1)   # eyes + bags
        line([(21, 25.5), (24, 25), (27, 25.5)], INK, 1.1, j=0.1)
    elif side:
        dot(18.5, 18, 1.7, INK); line([(16, 21.5), (18.5, 22.5), (20.5, 21.5)], "#3d3026", 0.8, 0.8, j=0.1)
        line([(13.2, 19), (11.6, 21.5), (13.6, 22.5)], INK, 1.1, j=0.1); line([(15, 26), (18, 25.6)], INK, 1.1, j=0.1)
    if extra: extra("head", d)
    raw('</g>')

def save(name, scale=3):
    os.makedirs(DST, exist_ok=True)
    open(os.path.join(DST, name + ".svg"), "w", encoding="utf-8").write(kit.svg(48, 72, scale))
    kit.out.clear(); kit.defs.clear()

# ---- hair styles ----
def hair_player(d, hx):
    if d == "back": shape(blob(hx, 15, 13.5, 12.5, 12, 0.04), "#1d1612", INK, 1.6, j=0.3)
    elif d == "side": shape([(16, 6), (26, 3), (36, 7), (39, 17), (37, 27), (31, 28), (30, 18), (24, 12), (16, 12)], "#1d1612", INK, 1.6, j=0.3)
    else: shape([(11, 16), (12, 8), (19, 3.5), (29, 3.5), (36, 8), (37, 16), (33, 11), (27, 9.5), (20, 11), (14, 12)], "#1d1612", INK, 1.6, j=0.3)
def hair_mamie(d, hx):
    shape([(11, 17), (11, 9), (18, 4), (30, 4), (37, 9), (37, 17), (33, 11), (24, 8.5), (15, 11)], "#c9c7bd", INK, 1.5, j=0.3)
    shape(blob(24, 3.5, 6, 4.5, 8, 0.05), "#c9c7bd", INK, 1.5, j=0.2)
def hair_etu(d, hx):
    shape([(10.5, 15), (11, 7), (18, 2.5), (30, 2.5), (37, 7), (37.5, 15), (24, 12.5)], "#3c5a57", INK, 1.6, j=0.3)       # beanie
    shape(rect(10.5, 12, 27, 4.5), "#2c4442", INK, 1.2, hard=True, j=0.2)
def hair_homme(d, hx):
    shape([(10.8, 19), (11.5, 12), (15, 14), (15, 20)], "#4b4038", INK, 1.2, j=0.2); shape([(37.2, 19), (36.5, 12), (33, 14), (33, 20)], "#4b4038", INK, 1.2, j=0.2)
    line([(17, 6.5), (22, 5), (27, 6)], "#4b4038", 1, 0.8, j=0.2)

# ---- accessories ----
def x_player(part, d):
    if part == "body" and d != "back":                  # the precious file, held tight
        x = 5 if d == "front" else 13
        shape(rect(x + 1, 36, 13, 16), "#d6cfb4", INK, 0.9, hard=True, j=0.2); shape(rect(x, 37, 13, 16), "#c9a55a", INK, 1.3, hard=True, j=0.3)
        raw(f'<rect x="{x + 9}" y="37" width="2" height="16" fill="#1d1a15"/>'); dot(x + 12, 46, 2.6, "#b08a64")
    if part == "body" and d == "back":                  # backpack
        b = shape([(14, 30), (34, 30), (35, 48), (13, 48)], "#3a3d2e", INK, 1.5, j=0.3); hatch([b], 20, 3, INK, 0.6, 0.4); shape(rect(18, 38, 12, 7), "#2b2e22", INK, 1, hard=True, j=0.2)
def x_mamie(part, d):
    if part == "head":
        for x in (19.5, 28.5): raw(f'<circle cx="{x}" cy="18" r="3.8" fill="#dfeee6" fill-opacity="0.35" stroke="{INK}" stroke-width="1"/>')
        line([(23.3, 18), (24.7, 18)], INK, 1, j=0)
    if part == "body":                                  # the endless scarf
        s = shape([(13, 42), (35, 42), (36, 50), (40, 58), (38, 66), (30, 68), (22, 63), (12, 52)], "#5d7d4a", INK, 1.4, j=0.4)
        hatch([s], 0, 2.6, "#26381c", 0.7, 0.7, seg=(3, 8)); hatch([s], 90, 4, "#26381c", 0.6, 0.4, seg=(3, 8))
        line([(14, 36), (30, 46)], "#d9d2b8", 1.4, j=0.1); line([(34, 36), (18, 46)], "#d9d2b8", 1.4, j=0.1)
        dot(15, 43, 2.6, "#c9b095"); dot(33, 43, 2.6, "#c9b095")
def x_etu(part, d):
    if part == "head":
        for x in (19.5, 28.5): tone(blob(x, 21.5, 3.4, 1.8, 7, 0.1), "#4a3b52", 0.55)       # dark circles
        line([(11, 24), (12, 30), (20, 32)], "#15130f", 2.6, j=0.2); line([(37, 24), (36, 30), (28, 32)], "#15130f", 2.6, j=0.2)  # headphones
    if part == "body":                                  # folders piled on the knees
        for i, c in enumerate(("#8d5f66", "#b99a58", "#5f6f80", "#6f7a63")):
            shape(rect(10 + (i % 2) * 2, 50 - i * 3.6, 27, 4), c, INK, 1, hard=True, j=0.4)
        dot(13, 42, 2.6, "#a5805e"); dot(36, 42, 2.6, "#a5805e")
def x_homme(part, d):
    if part == "head": shape([(19, 23.5), (24, 22.5), (29, 23.5), (28, 25.5), (24, 24.8), (20, 25.5)], "#4b4038", INK, 0.9, j=0.2)   # moustache
    if part == "body":
        shape([(22.5, 30), (25.5, 30), (26, 40), (24, 42), (22, 40)], "#6d1f26", INK, 0.9, j=0.2)
        shape(rect(14, 35, 21, 14), "#d6cfb4", INK, 0.9, hard=True, j=0.3); f = shape(rect(13, 36, 22, 14), "#b99a58", INK, 1.4, hard=True, j=0.3)
        hatch([f], 30, 3, INK, 0.6, 0.35)
        shape(rect(8, 40, 12, 5), "#5c5a52", INK, 1.2, hard=True, j=0.3); shape(rect(28, 43, 12, 5), "#5c5a52", INK, 1.2, hard=True, j=0.3)
        dot(20.5, 42.5, 2.6, "#c2a184"); dot(27.5, 45.5, 2.6, "#c2a184")

PLAYER = {"skin": "#b08a64", "coat": "#2f4a6b", "shirt": "#c8c0a6", "pants": "#2b2a2e", "shoes": "#15130f", "hair": hair_player}
for d in ("front", "back", "side"):
    for st in (0, 1, -1):
        person(PLAYER, d, st, extra=x_player); save(f"player_{d}_{st % 3}")
person({"skin": "#c9b095", "coat": "#8a6f8f", "pants": "#4a4038", "shoes": "#2a2018", "hair": hair_mamie}, sit=True, extra=x_mamie); save("mamie")
person({"skin": "#a5805e", "coat": "#6b3d2a", "pants": "#2e3b4e", "shoes": "#d9d2b8", "hair": hair_etu}, sit=True, extra=x_etu); save("etudiant")
person({"skin": "#c2a184", "coat": "#5c5a52", "shirt": "#c8c0a6", "pants": "#33312c", "shoes": "#15130f", "hair": hair_homme}, extra=x_homme); save("homme")
print("ok", len(os.listdir(DST)))
