"""Waiting room background (top-down 3/4, 20x11 tiles of 48). Usage: python3 -I tools/boss/room.py
Interactive things sit on the tiles named in data/rpg2d.json; the screen number and clock hands are drawn by the game."""
import os, sys, math
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import kit
from kit import *
T, W, H = 48, 960, 528
kit.BOX[:] = [0, 0, W, H]
def rect(x, y, w, h): return [(x, y), (x + w, y), (x + w, y + h), (x, y + h)]

def chair(c, r):
    x, y = c * T, r * T
    raw(f'<ellipse cx="{x + 24}" cy="{y + 43}" rx="20" ry="5" fill="#000" opacity="0.35"/>')
    line([(x + 9, y + 34), (x + 8, y + 44)], "#2a2a27", 2.4); line([(x + 39, y + 34), (x + 40, y + 44)], "#2a2a27", 2.4)
    d = shape([(x + 6, y + 3), (x + 24, y + 1), (x + 42, y + 3), (x + 43, y + 20), (x + 5, y + 20)], "#9c5226", INK, 1.6, j=0.5)     # back
    hatch([d], 80, 3.5, "#3d1c0a", 0.7, 0.45, box=(x, y, x + T, y + 24))
    raw(f'<rect x="{x + 19}" y="{y + 8}" width="10" height="3" rx="1.5" fill="#3d1c0a" opacity="0.8"/>')
    d = shape([(x + 4, y + 19), (x + 44, y + 19), (x + 45, y + 36), (x + 24, y + 39), (x + 3, y + 36)], "#b8662f", INK, 1.6, j=0.5)   # seat
    tone([(x + 4, y + 30), (x + 44, y + 30), (x + 45, y + 36), (x + 24, y + 39), (x + 3, y + 36)], "#3d1c0a", 0.45, [d])
    line([(x + 10, y + 23), (x + 38, y + 23)], "#e09a62", 1.2, 0.5)

def paper(x, y, w, h, ang=0, col="#cfc8ab", lines=3, head=None):
    raw(f'<g transform="rotate({ang} {x + w / 2} {y + h / 2})">')
    raw(f'<rect x="{x + 2}" y="{y + 2}" width="{w}" height="{h}" fill="#000" opacity="0.3"/>')
    shape(rect(x, y, w, h), col, INK, 1.1, hard=True, j=0.4)
    if head: raw(f'<rect x="{x + 3}" y="{y + 3}" width="{w - 6}" height="5" fill="{head}"/>')
    for i in range(lines):
        line([(x + 4, y + 13 + i * 5), (x + w - 4 - (i % 2) * 5, y + 13 + i * 5)], "#3a3327", 0.9, 0.7, j=0.3)
    raw('</g>')

def draw():
    # ---- floor: worn lino checker ----
    raw(f'<rect width="{W}" height="{H}" fill="#14160f"/>')
    for r in range(2, 10):
        for c in range(1, 19):
            col = "#7a7d66" if (r + c) % 2 else "#666a57"
            shape(rect(c * T, r * T, T, T), col, "#2b2e24", 0.9, hard=True, j=0.5)
    floor = poly(rect(T, 2 * T, 18 * T, 8 * T))
    hatch([floor], 20, 9, "#2b2e24", 0.7, 0.3, seg=(6, 26))
    for cx, cy, rx, ry, o in [(740, 190, 60, 90, 0.22), (420, 250, 240, 26, 0.16), (120, 150, 60, 40, 0.2), (500, 410, 200, 30, 0.12)]:
        tone(blob(cx, cy, rx, ry, 12, 0.2), "#33352a", o, [floor])                         # paths worn by years of queuing
    for cx, cy in [(300, 150), (600, 330), (860, 420), (200, 440)]:
        tone(blob(cx, cy, 16, 9, 9, 0.3), "#1d1f17", 0.3)
    tone(rect(T, 2 * T, 18 * T, 26), "#000", 0.38, hard=True)                                # wall shadow
    # confidentiality line in front of the door
    shape(rect(15 * T - 20, 3 * T + 30, 88, 7), "#c9a52c", INK, 1, hard=True)
    hatch([poly(rect(15 * T - 20, 3 * T + 30, 88, 7))], 60, 6, INK, 2.2, 0.8, box=(690, 170, 800, 185))
    for x, y, a in [(250, 230, 20), (540, 440, -30), (820, 300, 50), (150, 380, -12)]:
        paper(x, y, 13, 9, a, lines=0)                                                       # dropped tickets

    # ---- top wall ----
    wg = grad("linear", [(0, "#4e5a47", 1), (1, "#69755c", 1)], x1=0, y1=0, x2=0, y2=1)
    wall = shape(rect(0, 0, W, 2 * T), wg, INK, 0, hard=True)
    hatch([wall], 88, 8, "#1c2118", 0.8, 0.3, box=(0, 0, W, 96), seg=(12, 50))
    wains = shape(rect(0, 58, W, 38), "#2f3d33", INK, 0, hard=True)
    hatch([wains], 2, 5, "#0d120d", 0.8, 0.4, box=(0, 58, W, 96))
    line([(0, 58), (480, 59), (W, 58)], INK, 2.2); line([(0, 62), (W, 62)], "#86927a", 1, 0.4)
    shape(rect(0, 90, W, 6), "#1a1d17", INK, 1.2, hard=True)
    for cx, cy, rx, ry in [(330, 20, 50, 16), (640, 30, 40, 14), (880, 22, 36, 14)]:
        b = blob(cx, cy, rx, ry, 11, 0.25); tone(b, "#2f3628", 0.4); hatch([smooth(b, True)], 40, 4, "#161a12", 0.7, 0.4, box=(cx - rx, cy - ry, cx + rx, cy + ry))
    # posters (cols 2, 7, 17)
    paper(2 * T + 5, 12, 38, 50, -2, head="#a3181c", lines=5)
    raw(f'<g transform="rotate(-14 {2 * T + 24} 50)"><rect x="{2 * T + 9}" y="42" width="30" height="11" fill="none" stroke="#a3181c" stroke-width="1.8"/></g>')
    paper(7 * T + 5, 10, 38, 50, 2, head="#1d2f55", lines=2)
    for i in range(5):
        for j in range(5):
            if (i * 7 + j * 3 + i * j) % 3:
                raw(f'<rect x="{7 * T + 13 + i * 4.4:.1f}" y="{33 + j * 4.4:.1f}" width="4" height="4" fill="{INK}" transform="rotate(2 {7 * T + 24} 35)"/>')
    paper(17 * T + 5, 12, 38, 50, -1, lines=2)
    raw(f'<path d="M{17 * T + 17} 38h14l-6 9 6 9h-14l6-9z" fill="#a3181c" stroke="{INK}" stroke-width="1.2"/>')   # hourglass
    # call screen (col 4): the game writes the number on it
    line([(4 * T + 24, 0), (4 * T + 24, 16)], INK, 2)
    shape(rect(4 * T - 26, 14, 100, 40), "#15130f", INK, 2.2, hard=True)
    shape(rect(4 * T - 19, 20, 86, 28), "#1d0503", "#3a0a05", 1.2, hard=True)
    # clock (col 11): the game draws the hands
    cx, cy = 11 * T + 24, 32
    raw(f'<circle cx="{cx + 2}" cy="{cy + 3}" r="21" fill="#000" opacity="0.4"/><circle cx="{cx}" cy="{cy}" r="20" fill="#23221d" stroke="{INK}" stroke-width="2"/><circle cx="{cx}" cy="{cy}" r="16" fill="#cdc6a8" stroke="{INK}" stroke-width="1"/>')
    for i in range(12):
        a = math.tau * i / 12
        line([(cx + math.sin(a) * 12.5, cy - math.cos(a) * 12.5), (cx + math.sin(a) * 15, cy - math.cos(a) * 15)], INK, 1.6 if i % 3 == 0 else 0.8, j=0.1)
    paper(11 * T + 4, 60, 40, 22, 1, lines=1, head="#a3181c")
    # door of Bureau 3 (col 15)
    x = 15 * T
    shape(rect(x - 5, 4, 58, 92), "#2a2118", INK, 2, hard=True)
    dg = grad("linear", [(0, "#6b4c2a", 1), (1, "#3a2814", 1)], x1=0, y1=0, x2=1, y2=1)
    dd = shape(rect(x + 1, 10, 46, 86), dg, INK, 1.8, hard=True)
    hatch([dd], 88, 3.6, "#1f1408", 0.8, 0.5, box=(x, 8, x + 48, 96))
    shape(rect(x + 8, 16, 32, 26), "#93a89a", INK, 1.4, hard=True)                           # frosted glass
    tone(blob(x + 24, 34, 9, 12, 9, 0.1), "#1b241f", 0.75, [poly(rect(x + 8, 16, 32, 26))])  # a silhouette behind it
    tone([(x + 10, 16), (x + 16, 16), (x + 10, 42), (x + 8, 42)], "#fff", 0.3, hard=True)
    shape(rect(x + 7, 48, 34, 13), "#c9b46a", INK, 1.2, hard=True)
    text("BUREAU 3", x + 9.5, 52, 4.6, "#2a1c08", 1, track=5.3, j=0.1)
    raw(f'<circle cx="{x + 40}" cy="72" r="3.4" fill="#c2a550" stroke="{INK}" stroke-width="1.2"/>')
    raw(f'<rect x="{x + 1}" y="93" width="46" height="3" fill="#e9f7c8" opacity="0.75"/>')    # light under the door

    # ---- machines against the wall (row 2) ----
    x, y = 1 * T, 2 * T                                                                      # ticket kiosk
    raw(f'<ellipse cx="{x + 24}" cy="{y + 42}" rx="22" ry="6" fill="#000" opacity="0.4"/>')
    kd = shape(rect(x + 6, y - 46, 36, 86), "#8a1616", INK, 2, hard=True)
    hatch([kd], 85, 4, "#2a0505", 0.8, 0.45, box=(x, y - 50, x + 48, y + 44))
    tone(rect(x + 30, y - 46, 12, 86), "#000", 0.3, hard=True)
    shape(rect(x + 11, y - 40, 26, 18), "#10201a", INK, 1.4, hard=True)
    text("TICKET", x + 13.5, y - 34, 5, "#7dffb0", 1, track=4.8, j=0.1)
    for i in range(3):
        raw(f'<rect x="{x + 12}" y="{y - 16 + i * 9}" width="24" height="6" rx="2" fill="#d9d2b8" stroke="{INK}" stroke-width="1"/>')
    shape(rect(x + 13, y + 16, 22, 5), "#0c0a08", INK, 1, hard=True)
    paper(x + 17, y + 18, 14, 11, 4, col="#efe9d2", lines=1)
    x = 12 * T                                                                               # coffee machine, out of order
    raw(f'<ellipse cx="{x + 24}" cy="{y + 42}" rx="24" ry="6" fill="#000" opacity="0.4"/>')
    md = shape(rect(x + 2, y - 62, 44, 104), "#3b3530", INK, 2, hard=True)
    hatch([md], 86, 4, "#0f0d0b", 0.8, 0.45, box=(x, y - 64, x + 48, y + 44))
    shape(rect(x + 6, y - 56, 36, 30), "#5a3317", INK, 1.2, hard=True)
    raw(f'<path d="M{x + 16} {y - 36}h14l-2 8h-10z" fill="#d9d2b8" stroke="{INK}" stroke-width="1"/><path d="M{x + 20} {y - 40}q2-4 0-7m5 7q2-4 0-7" stroke="#d9d2b8" stroke-width="1.2" fill="none"/>')
    for i in range(6):
        raw(f'<circle cx="{x + 11 + (i % 3) * 9}" cy="{y - 16 + (i // 3) * 9}" r="2.6" fill="#8b8b84" stroke="{INK}" stroke-width="0.8"/>')
    shape(rect(x + 12, y + 8, 24, 20), "#0c0a08", INK, 1.2, hard=True)
    paper(x + 5, y - 22, 38, 20, -7, col="#efe9d2", lines=0)
    text("HORS", x + 12, y - 19, 6, "#a3181c", 1.4, angle=-7, track=5.6, j=0.1); text("SERVICE", x + 7, y - 10, 5, "#a3181c", 1.2, angle=-7, track=5.4, j=0.1)
    x = 13 * T                                                                               # photocopier, broken
    raw(f'<ellipse cx="{x + 24}" cy="{y + 42}" rx="24" ry="6" fill="#000" opacity="0.4"/>')
    pd = shape(rect(x + 2, y - 4, 44, 46), "#a9a798", INK, 2, hard=True)
    hatch([pd], 86, 4, "#3a3a34", 0.8, 0.4, box=(x, y - 6, x + 48, y + 44))
    shape([(x + 1, y - 16), (x + 47, y - 16), (x + 46, y - 2), (x + 2, y - 2)], "#c4c2b3", INK, 1.8, hard=True)
    shape(rect(x + 6, y + 6, 36, 10), "#33332e", INK, 1, hard=True); shape(rect(x + 6, y + 22, 36, 14), "#8d8b7d", INK, 1, hard=True)
    paper(x + 8, y - 20, 32, 16, 6, col="#efe9d2", lines=0)
    text("EN PANNE", x + 10, y - 15, 4.5, "#a3181c", 1.1, angle=6, track=5.2, j=0.1)

    # ---- chairs + dying ficus ----
    for r, row in enumerate(MAP):
        for c, ch in enumerate(row):
            if ch in "c12": chair(c, r)
    x, y = 17 * T, 6 * T
    raw(f'<ellipse cx="{x + 24}" cy="{y + 42}" rx="18" ry="5" fill="#000" opacity="0.4"/>')
    for a, l in [(-70, 44), (-100, 52), (-125, 40), (-50, 36), (-88, 30)]:
        ex, ey = x + 24 + math.cos(math.radians(a)) * l, y + 22 + math.sin(math.radians(a)) * l
        line([(x + 24, y + 24), ((x + 24 + ex) / 2 + 4, (y + 24 + ey) / 2), (ex, ey)], "#3a2f1c", 1.6)
        for k in (0.55, 0.8, 1.0):
            lx, ly = x + 24 + (ex - x - 24) * k, y + 24 + (ey - y - 24) * k
            shape(blob(lx + R.uniform(-5, 5), ly + 3, 6, 3.4, 7, 0.2, R.uniform(20, 80)), R.choice(["#6f6a2c", "#4d5a2e", "#7d5a24"]), INK, 0.9, j=0.2)
    shape([(x + 10, y + 20), (x + 38, y + 20), (x + 34, y + 42), (x + 14, y + 42)], "#8a4a2a", INK, 1.8, hard=True)
    shape(rect(x + 8, y + 16, 32, 7), "#9c5630", INK, 1.6, hard=True)
    for dx, dy in [(4, 44), (40, 40), (30, 46)]:
        shape(blob(x + dx, y + dy, 4, 2.4, 6, 0.2, 30), "#7d5a24", INK, 0.8, j=0.2)          # fallen leaves

    # ---- side / bottom walls (seen from above) ----
    for r_ in (rect(0, 96, T, H - 96), rect(W - T, 96, T, H - 96), rect(0, H - T, W, T)):
        shape(r_, "#1b1e18", INK, 2, hard=True)
    hatch([poly(rect(0, 96, T, H)), ], 45, 6, "#000", 0.9, 0.5, box=(0, 96, 48, H))
    hatch([poly(rect(W - T, 96, T, H))], 135, 6, "#000", 0.9, 0.5, box=(W - T, 96, W, H))
    hatch([poly(rect(0, H - T, W, T))], 0, 6, "#000", 0.9, 0.5, box=(0, H - T, W, H))
    line([(T, 96), (T, H - T), (W - T, H - T), (W - T, 96)], "#59624d", 1.4, 0.7, hard=True)

import json
root = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..")
MAP = json.load(open(os.path.join(root, "data", "rpg2d.json"), encoding="utf-8"))["map"]
draw()
open(os.path.join(root, "assets", "2d", "salle.svg"), "w", encoding="utf-8").write(kit.svg(W, H, 2))
print("wrote", len(kit.svg(W, H, 2)) // 1024, "KB")
