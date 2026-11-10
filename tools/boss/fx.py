"""Atmosphere on top: counter-glass reflections, dust in the neon light, heavy vignette."""
from kit import *

def draw():
    raw('<!-- atmosphere -->')
    for pts, op in (([(60, 0), (150, 0), (-40, 520), (-130, 520)], 0.05), ([(430, 0), (470, 0), (250, 800), (210, 800)], 0.035), ([(500, 0), (600, 0), (420, 800), (320, 800)], 0.045)):
        tone(pts, "#eaffee", op, hard=True)
    for _ in range(60):
        raw(f'<circle cx="{R.uniform(80, 520):.0f}" cy="{R.uniform(40, 520):.0f}" r="{R.uniform(0.6, 1.8):.1f}" fill="#f1ffe6" opacity="{R.uniform(0.08, 0.3):.2f}"/>')
    v = grad("radial", [(0, "#000", 0), (0.55, "#000", 0.08), (0.85, "#000", 0.45), (1, "#000", 0.8)], cx=0.5, cy=0.42, r=0.75)
    raw(f'<rect width="600" height="800" fill="{v}"/>')
    b = grad("linear", [(0, "#000", 0), (1, "#000", 0.3)], x1=0, y1=0, x2=0, y2=1)
    raw(f'<rect y="640" width="600" height="160" fill="{b}"/>')
