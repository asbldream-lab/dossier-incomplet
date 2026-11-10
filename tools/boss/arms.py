"""Arms as separate layers: raised arm brandishing the REFUSÉ stamp, other hand drumming its nails on your file."""
import math
from kit import *
SKIN = "#b3a084"
CG = None

def sleeve(pts, box, ang):
    d = shape(pts, CG, INK, 2.6)
    hatch([d], ang, 5, "#2a2417", 0.9, 0.5, box=box, seg=(8, 28))
    return d

def finger(b, t, w, nail=True, col=SKIN):
    dx, dy = t[0] - b[0], t[1] - b[1]
    L = math.hypot(dx, dy); nx, ny = -dy / L * w / 2, dx / L * w / 2
    m = ((b[0] + t[0]) / 2, (b[1] + t[1]) / 2)
    d = shape([(b[0] + nx, b[1] + ny), (m[0] + nx * 1.05, m[1] + ny * 1.05), (t[0] + nx * 0.7, t[1] + ny * 0.7), (t[0] + dx / L * w * 0.35, t[1] + dy / L * w * 0.35),
               (t[0] - nx * 0.7, t[1] - ny * 0.7), (m[0] - nx * 1.05, m[1] - ny * 1.05), (b[0] - nx, b[1] - ny)], col, INK, 1.5, j=0.3)
    for k in (0.38, 0.7):
        c = (b[0] + dx * k, b[1] + dy * k)
        line([(c[0] + nx * 0.8, c[1] + ny * 0.8), (c[0] - nx * 0.8, c[1] - ny * 0.8)], "#4a3d30", 0.9, 0.8, j=0.3)
    hatch([d], math.degrees(math.atan2(dy, dx)) + 90, 3, INK, 0.6, 0.35, box=(min(b[0], t[0]) - w, min(b[1], t[1]) - w, max(b[0], t[0]) + w, max(b[1], t[1]) + w))
    if nail:
        raw(f'<ellipse cx="{t[0] - dx / L * w * 0.1:.1f}" cy="{t[1] - dy / L * w * 0.1:.1f}" rx="{w * 0.5:.1f}" ry="{w * 0.33:.1f}" transform="rotate({math.degrees(math.atan2(dy, dx)):.0f} {t[0]:.1f} {t[1]:.1f})" fill="#7d1620" stroke="{INK}" stroke-width="1"/>')

def draw():
    global CG
    CG = grad("linear", [(0, "#85754e", 1), (1, "#4a4029", 1)], x1=0, y1=0, x2=0.3, y2=1)
    raw('<!-- RIGHT ARM (viewer left): raised, brandishing the stamp -->')
    d = sleeve([(150, 498), (192, 512), (200, 556), (150, 628), (104, 648), (68, 630), (62, 592), (100, 534)], (55, 490, 205, 650), 135)
    tone([(120, 600), (190, 540), (200, 556), (150, 628), (104, 648)], "#1c170e", 0.45, [d])
    d = sleeve([(64, 606), (80, 470), (140, 468), (146, 610), (108, 640)], (55, 460, 150, 645), 95)
    tone([(118, 468), (140, 468), (146, 610), (122, 630)], "#1c170e", 0.45, [d])
    for y in (520, 566):
        line([(72, y + 18), (100, y), (140, y + 10)], "#221c10", 1.2, 0.7)
    cuff = shape([(80, 448), (142, 446), (144, 474), (78, 476)], "#7c6c47", INK, 2, hard=True)
    hatch([cuff], 90, 3.2, "#2a2417", 0.8, 0.6, box=(75, 440, 148, 480), seg=(5, 14))
    # wooden handle through the fist
    hw = grad("linear", [(0, "#8a6238", 1), (1, "#3f2913", 1)], x1=0, y1=0, x2=1, y2=0)
    hd = shape([(98, 352), (134, 350), (132, 452), (102, 452)], hw, INK, 2, hard=True)
    hatch([hd], 88, 3.5, "#2a1808", 0.7, 0.5, box=(95, 345, 138, 455))
    # fist
    shape(blob(114, 424, 30, 27, 10, 0.05), SKIN, INK, 2)
    for i, y in enumerate((400, 413, 426, 439)):
        fd = shape([(86, y - 6), (112, y - 7.5), (138, y - 6), (143, y), (138, y + 6), (112, y + 7), (86, y + 6), (81, y)], SKIN, INK, 1.5, j=0.3)
        line([(106, y - 4), (108, y), (106, y + 4)], "#4a3d30", 0.9, 0.8, j=0.3)
        hatch([fd], 60, 3, INK, 0.6, 0.4, box=(80, y - 8, 145, y + 8))
        raw(f'<ellipse cx="88" cy="{y}" rx="6" ry="4.4" fill="#7d1620" stroke="{INK}" stroke-width="1"/>')
    finger((142, 440), (120, 396), 15)                                                              # thumb
    raw('<circle cx="134" cy="427" r="0.1" fill="none"/>')
    # the stamp block, tilted so the inked face stares at you
    raw('<g transform="translate(-16 -4) rotate(-9 118 312)">')
    shape([(40, 268), (196, 268), (204, 282), (204, 352), (196, 362), (40, 362), (32, 352), (32, 282)], hw, INK, 2.6, hard=True)   # wood
    hatch([poly([(32, 268), (204, 268), (204, 362), (32, 362)])], 2, 4, "#2a1808", 0.7, 0.45, box=(30, 265, 206, 365))
    ig = grad("linear", [(0, "#b3161b", 1), (1, "#5e070b", 1)], x1=0, y1=0, x2=0, y2=1)
    face = shape([(44, 278), (192, 278), (192, 352), (44, 352)], ig, INK, 2, hard=True)
    raw('<rect x="51" y="285" width="134" height="60" fill="none" stroke="#f0c9b8" stroke-width="2.6" opacity="0.9"/>')
    text("REFUSÉ", 59, 306, 21, "#f6d9cc", 4.2, 0.95, track=5.75, j=0.4)
    hatch([face], 40, 5, "#3a0306", 0.9, 0.4, box=(40, 275, 196, 356))
    # ink running off the edge
    for x, l in ((66, 34), (96, 58), (150, 26), (176, 44)):
        raw(f'<path d="M{x - 4} 361 q4 {l * 0.6:.0f} 3 {l} q1 7 5 0 q-2 {-l * 0.4:.0f} 4 {-l} z" fill="#7d0a10" stroke="{INK}" stroke-width="1"/>')
    raw('</g>')
    raw('<circle cx="92" cy="452" r="4" fill="#7d0a10"/><circle cx="160" cy="430" r="2.6" fill="#7d0a10"/>')

    raw('<!-- LEFT ARM (viewer right): resting on the desk, nails drumming -->')
    d = sleeve([(408, 500), (452, 498), (500, 548), (530, 620), (528, 668), (470, 672), (436, 610), (410, 556)], (400, 490, 535, 680), 60)
    tone([(470, 540), (500, 548), (530, 620), (528, 668), (500, 670)], "#1c170e", 0.5, [d])
    d = sleeve([(530, 640), (534, 690), (480, 716), (424, 712), (420, 676), (470, 656)], (415, 635, 540, 720), 15)
    tone([(534, 690), (480, 716), (424, 712), (440, 700), (500, 690)], "#1c170e", 0.5, [d])
    cuff = shape([(408, 674), (430, 670), (434, 714), (410, 716)], "#7c6c47", INK, 2, hard=True)
    hatch([cuff], 5, 3.2, "#2a2417", 0.8, 0.6, box=(405, 668, 437, 718), seg=(5, 14))
    shape(blob(384, 694, 30, 19, 10, 0.05), SKIN, INK, 2)                                           # back of the hand
    for a, b2 in (((372, 684), (366, 700)), ((384, 682), (380, 702)), ((396, 683), (394, 703))):
        line([a, b2], "#4a3d30", 1, 0.7)                                                           # tendons
    for b2, t in (((362, 682), (306, 690)), ((360, 692), (296, 708)), ((362, 702), (304, 726)), ((368, 710), (322, 740))):
        finger(b2, t, 13)
    finger((392, 708), (352, 742), 14)                                                              # thumb
    raw(f'<path d="M343 686 l2 9" stroke="#d9b64e" stroke-width="4" stroke-linecap="round"/>')     # wedding ring
