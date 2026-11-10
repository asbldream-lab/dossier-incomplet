"""Desk in front of her: your file (INCOMPLET), a pile of other people's, ink pad, ticket spike, name plate."""
from kit import *

def folder(x, y, w, h, col, ang=0, strap=True):
    raw(f'<g transform="rotate({ang} {x + w / 2} {y + h / 2})">')
    shape([(x + 5, y - 4), (x + w - 6, y - 5), (x + w - 4, y + h - 6), (x + 6, y + h - 4)], "#d6cfb4", INK, 1, hard=True)   # sheets
    d = shape([(x, y), (x + w, y), (x + w, y + h), (x, y + h)], col, INK, 1.8, hard=True, j=1)
    hatch([d], 25, 5, INK, 0.6, 0.3, box=(x, y, x + w, y + h))
    if strap:
        shape([(x + w * 0.8, y), (x + w * 0.8 + 9, y), (x + w * 0.8 + 9, y + h), (x + w * 0.8, y + h)], "#1d1a15", INK, 1, hard=True)
    raw('</g>')

def draw():
    raw('<!-- desk -->')
    dg = grad("linear", [(0, "#5a4630", 1), (0.25, "#3e2f1f", 1), (1, "#150f09", 1)], x1=0, y1=0, x2=0, y2=1)
    top = shape([(0, 650), (600, 650), (600, 800), (0, 800)], dg, INK, 0, hard=True)
    hatch([top], 1, 4.5, "#150d06", 0.9, 0.5, box=(0, 650, 600, 800), seg=(40, 160))
    line([(0, 650), (200, 651), (400, 649), (600, 650)], INK, 3)
    line([(0, 655), (300, 656), (600, 655)], "#9a7d55", 1.2, 0.5)
    tone([(120, 652), (480, 652), (500, 668), (100, 668)], "#000", 0.4, hard=True)      # her shadow on the desk
    # pile of other people's files
    for i, (c, a) in enumerate([("#6f7a63", 2), ("#b08f4e", -3), ("#8d5f66", 1), ("#5f6f80", -2), ("#b99a58", 3)]):
        folder(8 + i * 3, 742 - i * 15, 128, 16, c, a, False)
        line([(14 + i * 3, 750 - i * 15), (130 + i * 3, 750 - i * 15)], "#d6cfb4", 1, 0.5)
    folder(14, 656, 122, 26, "#b99a58", -4)
    # your file, right under her nails
    folder(250, 676, 208, 118, "#bfa160", -5)
    raw('<g transform="rotate(-13 330 760)">')
    raw('<rect x="262" y="744" width="140" height="30" fill="none" stroke="#a3121a" stroke-width="2.6" opacity="0.9"/>')
    text("INCOMPLET", 269, 751, 15, "#a3121a", 2.6, 0.9, track=5.75)
    raw('</g>')
    raw('<g transform="translate(-366 0)">')
    # ticket spike: the numbers already "treated"
    raw(f'<ellipse cx="566" cy="770" rx="27" ry="9" fill="#2a2a27" stroke="{INK}" stroke-width="1.8"/>')
    line([(566, 768), (566, 672)], "#9a9a90", 2, j=0.2)
    for i, (n, a) in enumerate([("844", -14), ("845", 9), ("846", -6), ("848", 12)]):
        y = 748 - i * 13
        raw(f'<g transform="rotate({a} 566 {y})">')
        shape([(540, y - 9), (594, y - 9), (594, y + 9), (540, y + 9)], "#d9d2b8", INK, 1.2, hard=True)
        text(n, 547, y - 5, 10, "#2a2118", 1.5, track=5.8)
        raw('</g>')
    raw('</g>')
    # name plate
    raw('<g transform="translate(2 -8) rotate(-2 520 770)">')
    shape([(430, 772), (590, 772), (596, 798), (424, 798)], "#2a2018", INK, 1.8, hard=True)
    bp = grad("linear", [(0, "#cdb268", 1), (1, "#7d6630", 1)], x1=0, y1=0, x2=0, y2=1)
    shape([(436, 776), (584, 776), (586, 794), (434, 794)], bp, INK, 1.2, hard=True)
    text("MME BERTRAND", 442, 780, 10, "#2a1c08", 1.6, track=5.8)
    raw('</g>')
