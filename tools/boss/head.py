"""Head: aubergine perm with grey roots, top-lit sagging face, half-closed eyes over half-moon glasses on a chain."""
import math
from kit import *
SKIN_D = "#7b6d58"
HAIR = [(300, 82), (348, 88), (390, 114), (410, 158), (412, 212), (400, 262), (388, 306), (366, 318), (300, 300), (234, 318), (212, 306), (200, 262), (188, 212), (190, 158), (210, 114), (252, 88)]
FACE = [(250, 186), (300, 174), (350, 186), (368, 228), (373, 272), (368, 312), (362, 346), (352, 376), (328, 397), (300, 404), (272, 397), (248, 376), (238, 346), (232, 312), (227, 272), (232, 228)]

def curls(d, box, n, light="#7d3a5a", dark="#12050c"):
    x0, y0, x1, y1 = box
    for i in range(n):
        cx, cy, r = R.uniform(x0, x1), R.uniform(y0, y1), R.uniform(7, 15)
        a0, sw = R.uniform(0, math.tau), R.uniform(2.6, 4.6) * R.choice([-1, 1])
        pts = [(cx + math.cos(a0 + sw * t / 7) * r * (1 - t / 11), cy + math.sin(a0 + sw * t / 7) * r * (1 - t / 11)) for t in range(8)]
        if i % 3 == 0:
            line(pts, light, R.uniform(0.9, 1.6), 0.6, j=0.3, clips=[d])
        else:
            line(pts, dark, R.uniform(1, 2), 0.75, j=0.3, clips=[d])

def eye(m):
    f = (lambda p: mirror(p)) if m else (lambda p: p)
    tone(f(blob(268, 266, 27, 17, 10, 0.05)), "#3f332b", 0.6)                                   # socket
    e = f([(249, 271), (258, 265), (270, 263), (281, 265), (289, 272), (280, 277), (268, 278), (257, 276)])
    ed = shape(e, "#d6cfb6", INK, 1.2, j=0.2)
    cx = 332 if m else 268
    raw(f'<g clip-path="url(#{_clipid(ed)})"><circle cx="{cx + 1}" cy="271.5" r="6.4" fill="#4b5632" stroke="{INK}" stroke-width="1.2"/><circle cx="{cx + 1}" cy="271.5" r="2.8" fill="{INK}"/><circle cx="{cx - 1}" cy="269.6" r="1.3" fill="#fff" opacity="0.85"/><rect x="{cx - 22}" y="262" width="44" height="6.5" fill="#000" opacity="0.35"/></g>')
    lid = f([(247, 271), (256, 260), (270, 256), (283, 259), (291, 272), (281, 266), (270, 264), (258, 266)])
    shape(lid, "#56706a", INK, 1.3, j=0.2)                                                          # heavy lid, blue-green eyeshadow
    line(f([(247, 271), (258, 266), (270, 264), (281, 266), (291, 272)]), INK, 2.8, j=0.2)          # mascara line
    for a, b in [((250, 269), (244, 264)), ((248, 271), (241, 269)), ((254, 267), (249, 261))]:
        line(f([a, b]), INK, 1.4, j=0.2)                                                            # clumped lashes
    line(f([(252, 257), (268, 251), (286, 256)]), "#4a3d30", 1, 0.7)                                # lid fold
    bag = f([(251, 280), (268, 286), (287, 279), (285, 290), (268, 296), (253, 290)])
    bd = tone(bag, "#5b4a3f", 0.5)
    hatch([bd], 20 if m else 160, 3, INK, 0.7, 0.5, box=(240, 275, 360, 300))
    line(f([(251, 280), (268, 286), (287, 279)]), "#3d3026", 1.3, 0.85)
    line(f([(256, 291), (269, 296), (283, 290)]), "#3d3026", 1, 0.6)
    for p in ([(245, 262), (238, 258)], [(245, 266), (237, 265)], [(246, 270), (239, 273)]):
        line(f(p), "#4a3d30", 0.9, 0.6)                                                             # crow's feet

def _clipid(d):
    c = nid("c"); defs.append(f'<clipPath id="{c}"><path d="{d}"/></clipPath>'); return c

def draw():
    raw('<g transform="rotate(-3.5 300 400) translate(300 404) scale(1.13) translate(-300 -404)">')
    hg = grad("radial", [(0, "#5c2140", 1), (0.55, "#341126", 1), (1, "#16060f", 1)], cx=0.45, cy=0.18, r=0.85)
    hd = shape(HAIR, hg, INK, 3, j=1.6)
    curls(hd, (190, 84, 410, 318), 150)
    # ears + clip earrings
    for m in (0, 1):
        f = (lambda p: mirror(p)) if m else (lambda p: p)
        shape(f([(232, 268), (222, 266), (217, 280), (220, 298), (229, 308), (235, 300)]), "#a8977c", INK, 1.6)
        line(f([(226, 276), (223, 288), (228, 298)]), "#4a3d30", 1, 0.8)
        x = 2 * 300 - 226 if m else 226
        raw(f'<circle cx="{x}" cy="312" r="6.5" fill="#d9d2bd" stroke="{INK}" stroke-width="1.4"/><circle cx="{x - 2}" cy="310" r="2" fill="#fff" opacity="0.7"/>')
    # face
    fg = grad("linear", [(0, "#d3c4a4", 1), (0.45, "#b4a386", 1), (1, "#7f705a", 1)], x1=0, y1=0, x2=0.15, y2=1)
    fd = shape(FACE, fg, INK, 2.6)
    tone(blob(300, 212, 44, 15), "#efe5c8", 0.3, [fd])                                              # neon on the forehead
    side = tone([(352, 190), (373, 272), (362, 346), (328, 397), (336, 350), (350, 290), (344, 215)], "#3c3127", 0.45, [fd])
    hatch([fd, side], 65, 3.6, INK, 0.8, 0.5, box=(320, 180, 380, 400))
    for m in (0, 1):
        f = (lambda p: mirror(p)) if m else (lambda p: p)
        ch = tone(f([(234, 304), (254, 316), (262, 350), (250, 372), (239, 346)]), "#4a3b30", 0.4, [fd])   # cheek hollow
        hatch([fd, ch], 115 if not m else 65, 3.4, INK, 0.7, 0.5, box=(225, 295, 375, 380))
        raw(f'<ellipse cx="{352 if m else 248}" cy="322" rx="15" ry="9" fill="#a34a4c" opacity="0.28"/>')  # too much blush
        line(f([(242, 348), (247, 370), (260, 388)]), "#3d3026", 1.5, 0.8)                           # jowl
        line(f([(281, 331), (268, 346), (262, 364), (265, 376)]), "#33281f", 1.7, 0.9)               # nasolabial fold
        line(f([(274, 365), (270, 374), (272, 384)]), "#33281f", 1.3, 0.8)                           # marionette line
    for y, w in ((203, 30), (213, 38), (223, 34)):
        line([(300 - w, y + 2), (300 - w / 3, y - 1), (300 + w / 3, y + 2), (300 + w, y - 1)], "#5a4b3a", 1, 0.55)
    line([(295, 240), (293, 256)], "#33281f", 1.4, 0.85); line([(304, 239), (306, 255)], "#33281f", 1.4, 0.85)   # frown
    eye(0); eye(1)
    # drawn-on eyebrows, one permanently raised
    line([(245, 248), (257, 238), (272, 235), (289, 242)], "#2a121d", 2.6, 0.95, j=0.3)
    line([(311, 238), (327, 226), (343, 227), (357, 241)], "#2a121d", 2.6, 0.95, j=0.3)
    # nose
    ns = tone([(303, 258), (310, 290), (320, 322), (312, 334), (303, 318), (300, 290)], "#4a3b30", 0.45)
    hatch([ns], 75, 3, INK, 0.7, 0.55, box=(295, 255, 325, 340))
    line([(306, 258), (310, 290), (315, 312), (321, 324), (316, 334)], "#2a2018", 1.8, j=0.3)
    line([(284, 322), (279, 330), (286, 336)], "#2a2018", 1.6, j=0.3)
    line([(288, 334), (300, 340), (312, 334)], "#2a2018", 1.5, j=0.3)
    raw(f'<ellipse cx="292" cy="333" rx="3.6" ry="2" fill="{INK}"/><ellipse cx="309" cy="333" rx="3.6" ry="2" fill="{INK}"/>')
    tone([(286, 338), (300, 343), (314, 338), (310, 347), (290, 347)], "#3c3127", 0.5)
    for x in (284, 290, 296, 304, 310, 316):
        line([(x, 347), (x + (x - 300) * 0.06, 355)], "#4a3b30", 0.9, 0.7, j=0.3)                    # smoker's lines
    # pursed mouth, dark lipstick, corners pulled down
    shape([(277, 362), (288, 357), (296, 355), (300, 357), (304, 355), (312, 357), (323, 362), (300, 363)], "#6e1a23", INK, 1.2, j=0.2)
    shape([(280, 363), (300, 364), (320, 363), (312, 369), (300, 371), (288, 369)], "#852530", INK, 1.2, j=0.2)
    line([(272, 366), (278, 362), (300, 363), (322, 362), (328, 366)], INK, 2, j=0.2)
    raw('<path d="M291 366.5q9 2 18 0" fill="none" stroke="#d98a8f" stroke-width="1" opacity="0.5"/>')
    tone([(286, 372), (300, 375), (314, 372), (308, 379), (292, 379)], "#3c3127", 0.5)
    line([(288, 384), (300, 381), (312, 384)], "#3d3026", 1.2, 0.8)
    cs = tone([(268, 392), (300, 386), (332, 392), (326, 400), (300, 406), (274, 400)], "#3c3127", 0.4, [fd])
    hatch([fd, cs], 10, 3, INK, 0.7, 0.5, box=(260, 380, 340, 410))
    raw(f'<circle cx="334" cy="377" r="2.6" fill="#2a1a12"/>'); line([(334, 377), (339, 370)], INK, 0.8)   # the mole
    # fringe
    fr = [(232, 236), (236, 200), (258, 180), (300, 170), (342, 180), (364, 200), (368, 236), (356, 214), (340, 204), (323, 213), (306, 200), (290, 213), (272, 202), (256, 215), (244, 214)]
    frd = shape(fr, hg, INK, 2.4, j=1)
    curls(frd, (232, 172, 368, 232), 46)
    for x in range(286, 316, 4):
        line([(x, 86 + abs(x - 300) * 0.3), (x + R.uniform(-3, 3), 112)], "#9a968a", 1.3, 0.7)        # grey roots
    # half-moon glasses perched low + bead chain
    for m in (0, 1):
        f = (lambda p: mirror(p)) if m else (lambda p: p)
        ln = f([(245, 291), (291, 291), (290, 305), (281, 314), (257, 314), (246, 305)])
        ld = shape(ln, "#cfe6d8", "#c2a550", 2.4, j=0.2)
        out[-1] = out[-1].replace('fill="#cfe6d8"', 'fill="#cfe6d8" fill-opacity="0.2"')
        tone(f([(252, 291), (262, 291), (254, 314), (246, 310)]), "#fff", 0.3, [ld], hard=True)
        tone(f([(268, 291), (272, 291), (263, 314), (259, 314)]), "#fff", 0.22, [ld], hard=True)
        line(f([(245, 293), (236, 288), (229, 284)]), "#c2a550", 2.2, j=0.2)
        ch = smooth(f([(231, 288), (222, 340), (228, 400), (246, 446), (262, 466)]))
        raw(f'<path d="{ch}" fill="none" stroke="#8a6f2c" stroke-width="3.2" stroke-linecap="round" stroke-dasharray="0.1 5.2"/>')
        raw(f'<path d="{ch}" fill="none" stroke="#ecd68a" stroke-width="1.4" stroke-linecap="round" stroke-dasharray="0.1 5.2"/>')
    line([(291, 295), (300, 290), (309, 295)], "#c2a550", 2.4, j=0.2)
    raw('</g>')
