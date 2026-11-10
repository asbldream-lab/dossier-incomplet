"""Background: two-tone administrative wall, binder shelves, clock stuck near noon, ticket display, neon."""
import math
from kit import *

def draw():
    wall = grad("linear", [(0, "#5f6b55", 1), (0.5, "#4a5545", 1), (1, "#2b332b", 1)], x1=0, y1=0, x2=0, y2=1)
    raw(f'<rect width="600" height="800" fill="{wall}"/>')
    full = poly([(0, 0), (600, 0), (600, 800), (0, 800)])
    # lower wainscot, darker glossy paint
    raw('<rect y="430" width="600" height="370" fill="#27332c" opacity="0.85"/>')
    line([(0, 430), (200, 431), (400, 429), (600, 430)], "#12160f", 3, 0.9)
    line([(0, 436), (300, 437), (600, 436)], "#7d8a6c", 1, 0.35)
    hatch([full], 88, 9, "#1a2018", 0.8, 0.28, seg=(20, 90))
    hatch([poly([(0, 430), (600, 430), (600, 800), (0, 800)])], 2, 7, "#0d120d", 0.8, 0.3)
    # damp stains and cracks
    for cx, cy, rx, ry in [(520, 60, 70, 40), (90, 90, 60, 30), (430, 390, 50, 25)]:
        tone(blob(cx, cy, rx, ry, 12, 0.25), "#2a3024", 0.35)
        hatch([smooth(blob(cx, cy, rx, ry, 12, 0.25), True)], 40, 5, "#161a12", 0.7, 0.35, box=(cx - rx, cy - ry, cx + rx, cy + ry))
    line([(560, 0), (548, 50), (556, 95), (540, 150), (546, 190)], INK, 1.2, 0.7)
    line([(548, 50), (530, 70), (526, 96)], INK, 0.9, 0.6)

    # --- binder shelves (left) ---
    cols = ["#5a2326", "#2e3b4e", "#6b5a2c", "#3f4a3a", "#4a4a4a", "#5b3a22", "#2d2d38"]
    for row, sy in enumerate([150, 290, 430]):
        x = 6
        while x < 205:
            w = R.uniform(20, 31); h = R.uniform(104, 122); lean = R.choice([0, 0, 0, 0, -5, 6])
            c = R.choice(cols)
            raw(f'<g transform="rotate({lean} {x:.0f} {sy + 126})">')
            d = shape([(x, sy + 126 - h), (x + w, sy + 126 - h), (x + w, sy + 126), (x, sy + 126)], c, INK, 1.6, hard=True, j=0.9)
            tone([(x + w * 0.62, sy + 126 - h), (x + w, sy + 126 - h), (x + w, sy + 126), (x + w * 0.62, sy + 126)], "#000", 0.3, hard=True)
            shape([(x + 4, sy + 30), (x + w - 4, sy + 30), (x + w - 4, sy + 74), (x + 4, sy + 74)], "#c9c2a4", INK, 0.9, 0.9, hard=True, j=0.6)
            for k in range(4):
                line([(x + 7, sy + 38 + k * 9), (x + w - 7, sy + 38 + k * 9)], "#3a3327", 0.8, 0.7, j=0.8)
            raw(f'<circle cx="{x + w / 2:.1f}" cy="{sy + 104:.1f}" r="4.2" fill="#0c0a08" stroke="#8c8672" stroke-width="1.2"/>')
            hatch([d], 80, 4, INK, 0.6, 0.35, box=(x - 5, sy, x + w + 5, sy + 130))
            raw('</g>')
            x += w + R.uniform(0.5, 3)
        # shelf board + shadow under it
        shape([(0, sy + 126), (214, sy + 126), (214, sy + 138), (0, sy + 138)], "#4c4636", INK, 1.8, hard=True)
        tone([(0, sy + 138), (214, sy + 138), (206, sy + 158), (0, sy + 158)], "#000", 0.45, hard=True)
    shape([(206, 120), (218, 120), (218, 600), (206, 600)], "#3b3629", INK, 1.8, hard=True)  # upright
    # loose sheets poking out, one falling
    shape([(150, 262), (196, 255), (199, 276), (153, 283)], "#cfc8ab", INK, 1.1, hard=True)

    # --- clock, forever 11:58 ---
    cx, cy = 492, 132
    raw(f'<circle cx="{cx + 5}" cy="{cy + 7}" r="50" fill="#000" opacity="0.4"/>')
    raw(f'<circle cx="{cx}" cy="{cy}" r="48" fill="#23221d" stroke="{INK}" stroke-width="2.5"/>')
    raw(f'<circle cx="{cx}" cy="{cy}" r="40" fill="#cdc6a8" stroke="{INK}" stroke-width="1.5"/>')
    for i in range(12):
        a = math.tau * i / 12
        line([(cx + math.sin(a) * 33, cy - math.cos(a) * 33), (cx + math.sin(a) * 38, cy - math.cos(a) * 38)], INK, 2 if i % 3 == 0 else 1, j=0.2)
    a = math.tau * 58 / 60
    line([(cx, cy), (cx + math.sin(a) * 31, cy - math.cos(a) * 31)], INK, 2.2, j=0.2)
    a = math.tau * (11 + 58 / 60) / 12
    line([(cx, cy), (cx + math.sin(a) * 21, cy - math.cos(a) * 21)], INK, 3.2, j=0.2)
    raw(f'<circle cx="{cx}" cy="{cy}" r="3" fill="{INK}"/>')
    hatch([smooth(blob(cx + 12, cy + 12, 30, 30), True)], 45, 4, "#4b4534", 0.7, 0.5, box=(cx - 45, cy - 45, cx + 45, cy + 45))

    # --- ticket display: the number that never moves ---
    shape([(428, 212), (566, 208), (568, 268), (430, 272)], "#15130f", INK, 2.4, hard=True)
    shape([(438, 221), (557, 218), (558, 259), (440, 262)], "#1d0503", "#3a0a05", 1.2, hard=True)
    text("N 004", 452, 230, 20, "#ff3b1f", 3.2, 0.95, angle=-1.2, track=5.9)
    text("N 004", 452, 230, 20, "#ffb199", 1.0, 0.8, angle=-1.2, track=5.9)
    line([(498, 180), (497, 210)], INK, 1.4)
    # --- little sign ---
    shape([(440, 300), (556, 296), (558, 332), (442, 336)], "#b9b294", INK, 1.6, hard=True)
    text("GUICHET 3", 451, 309, 12, "#2a2118", 1.7, angle=-1.6, track=5.6)
    shape([(452, 352), (548, 346), (552, 418), (456, 424)], "#a8a184", INK, 1.3, 0.9, hard=True)
    text("FERMETURE", 461, 360, 8, "#5a1512", 1.3, angle=-3, track=6)
    text("12H00", 466, 378, 15, "#5a1512", 2.2, angle=-3, track=5.8)
    for k in range(2):
        line([(464, 404 + k * 7), (540, 399 + k * 7)], "#3a3327", 0.9, 0.6)

    # --- neon tube ---
    shape([(140, 8), (460, 8), (466, 30), (134, 30)], "#2a2b25", INK, 2, hard=True)
    glow = grad("linear", [(0, "#f3ffe8", 1), (1, "#b9d6a8", 1)], x1=0, y1=0, x2=0, y2=1)
    raw(f'<rect x="152" y="24" width="296" height="11" rx="5" fill="{glow}" stroke="#55664a" stroke-width="1"/>')
    cone = grad("radial", [(0, "#e8ffd8", 0.33), (0.6, "#cfeec0", 0.08), (1, "#cfeec0", 0)], cx=0.5, cy=0, r=0.8)
    raw(f'<rect width="600" height="520" fill="{cone}"/>')
