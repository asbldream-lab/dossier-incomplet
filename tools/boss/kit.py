"""Tiny drawing kit for hand-inked SVG portraits (wobbly outlines, cross-hatching, stroke lettering).
Only uses SVG features Godot's rasterizer supports: paths, gradients, clipPath (no filters, no <text>)."""
import math, random
R = random.Random(7)
INK = "#0c0a08"
out, defs = [], []
_n = [0]

def nid(p="i"):
    _n[0] += 1
    return f"{p}{_n[0]}"

def raw(s): out.append(s)

def smooth(pts, closed=False):
    n = len(pts)
    g = (lambda i: pts[i % n]) if closed else (lambda i: pts[max(0, min(n - 1, i))])
    d = f"M{pts[0][0]:.1f} {pts[0][1]:.1f}"
    for i in range(n if closed else n - 1):
        p0, p1, p2, p3 = g(i - 1), g(i), g(i + 1), g(i + 2)
        d += "C%.1f %.1f %.1f %.1f %.1f %.1f" % (p1[0] + (p2[0] - p0[0]) / 6, p1[1] + (p2[1] - p0[1]) / 6,
            p2[0] - (p3[0] - p1[0]) / 6, p2[1] - (p3[1] - p1[1]) / 6, p2[0], p2[1])
    return d + ("Z" if closed else "")

def poly(pts, closed=True):
    return "M" + "L".join("%.1f %.1f" % p for p in pts) + ("Z" if closed else "")

def jit(pts, a): return [(x + R.uniform(-a, a), y + R.uniform(-a, a)) for x, y in pts]
def mirror(pts, cx=300): return [(2 * cx - x, y) for x, y in pts]

def _clip(d):
    c = nid("c"); defs.append(f'<clipPath id="{c}"><path d="{d}"/></clipPath>'); return c

def _wrap(s, clips):
    for d in clips or []:
        s = f'<g clip-path="url(#{_clip(d)})">{s}</g>'
    return s

def shape(pts, fill, stroke=INK, sw=2.2, op=1, j=0.7, hard=False, clips=None):
    """Filled outline. Returns the clean path (for clipping shading into it)."""
    d = poly(pts) if hard else smooth(pts, True)
    dj = poly(jit(pts, j)) if hard else smooth(jit(pts, j), True)
    st = f'stroke="{stroke}" stroke-width="{sw}" stroke-linejoin="round"' if sw else ""
    out.append(_wrap(f'<path d="{dj}" fill="{fill}" {st} opacity="{op}"/>', clips))
    return d

def tone(pts, fill, op=0.4, clips=None, hard=False):
    d = poly(pts) if hard else smooth(pts, True)
    out.append(_wrap(f'<path d="{d}" fill="{fill}" opacity="{op}"/>', clips))
    return d

def line(pts, stroke=INK, sw=1.5, op=1, j=0.6, sketch=1, clips=None, hard=False):
    s = ""
    for _ in range(sketch):
        p = jit(pts, j)
        s += f'<path d="{poly(p, False) if hard else smooth(p)}" fill="none" stroke="{stroke}" stroke-width="{sw}" stroke-linecap="round" stroke-linejoin="round" opacity="{op}"/>'
    out.append(_wrap(s, clips))

BOX = [0, 0, 600, 800]

def hatch(clips, angle, gap, stroke=INK, sw=0.9, op=0.5, box=None, wob=1.2, seg=(14, 55)):
    """Broken, slightly shaky parallel strokes clipped to every path in `clips`."""
    x0, y0, x1, y1 = box or BOX
    cx, cy, r = (x0 + x1) / 2, (y0 + y1) / 2, math.hypot(x1 - x0, y1 - y0) / 2
    ca, sa = math.cos(math.radians(angle)), math.sin(math.radians(angle))
    d, t = "", -r
    while t < r:
        px, py, s = cx - sa * t, cy + ca * t, -r + R.uniform(0, 20)
        while s < r:
            L = R.uniform(*seg)
            d += "M%.1f %.1f L%.1f %.1f" % (px + ca * s + R.uniform(-wob, wob), py + sa * s + R.uniform(-wob, wob),
                px + ca * (s + L) + R.uniform(-wob, wob), py + sa * (s + L) + R.uniform(-wob, wob))
            s += L + R.uniform(2, 9)
        t += gap * R.uniform(0.7, 1.3)
    out.append(_wrap(f'<path d="{d}" fill="none" stroke="{stroke}" stroke-width="{sw}" stroke-linecap="round" opacity="{op}"/>', clips))

def blob(cx, cy, rx, ry, n=10, wob=0.08, rot=0):
    pts = []
    for i in range(n):
        a = math.tau * i / n
        k = 1 + R.uniform(-wob, wob)
        x, y = math.cos(a) * rx * k, math.sin(a) * ry * k
        c, s = math.cos(math.radians(rot)), math.sin(math.radians(rot))
        pts.append((cx + x * c - y * s, cy + x * s + y * c))
    return pts

def grad(kind, stops, **kw):
    g = nid("g")
    a = " ".join(f'{k}="{v}"' for k, v in kw.items())
    s = "".join(f'<stop offset="{o}" stop-color="{c}" stop-opacity="{al}"/>' for o, c, al in stops)
    defs.append(f'<{kind}Gradient id="{g}" {a}>{s}</{kind}Gradient>')
    return f"url(#{g})"

_F = {
 "A": [[(0,6),(2,0),(4,6)],[(1,4),(3,4)]], "B": [[(0,0),(0,6),(3,6),(4,5),(4,4),(3,3),(0,3)],[(0,0),(3,0),(4,1),(4,2),(3,3)]],
 "C": [[(4,1),(3,0),(1,0),(0,1),(0,5),(1,6),(3,6),(4,5)]], "D": [[(0,0),(0,6),(2,6),(4,4),(4,2),(2,0),(0,0)]],
 "E": [[(4,0),(0,0),(0,6),(4,6)],[(0,3),(3,3)]], "F": [[(4,0),(0,0),(0,6)],[(0,3),(3,3)]],
 "G": [[(4,1),(3,0),(1,0),(0,1),(0,5),(1,6),(3,6),(4,5),(4,3),(2,3)]], "H": [[(0,0),(0,6)],[(4,0),(4,6)],[(0,3),(4,3)]],
 "I": [[(2,0),(2,6)]], "K": [[(0,0),(0,6)],[(4,0),(0,3),(4,6)]], "L": [[(0,0),(0,6),(4,6)]], "M": [[(0,6),(0,0),(2,3),(4,0),(4,6)]], "N": [[(0,6),(0,0),(4,6),(4,0)]],
 "O": [[(1,0),(3,0),(4,1),(4,5),(3,6),(1,6),(0,5),(0,1),(1,0)]], "P": [[(0,6),(0,0),(3,0),(4,1),(4,2),(3,3),(0,3)]],
 "R": [[(0,6),(0,0),(3,0),(4,1),(4,2),(3,3),(0,3)],[(2,3),(4,6)]],
 "S": [[(4,1),(3,0),(1,0),(0,1),(0,2),(1,3),(3,3),(4,4),(4,5),(3,6),(1,6),(0,5)]], "T": [[(0,0),(4,0)],[(2,0),(2,6)]],
 "U": [[(0,0),(0,5),(1,6),(3,6),(4,5),(4,0)]], "V": [[(0,0),(2,6),(4,0)]], "X": [[(0,0),(4,6)],[(4,0),(0,6)]],
 "0": [[(1,0),(3,0),(4,1),(4,5),(3,6),(1,6),(0,5),(0,1),(1,0)]], "1": [[(1,1),(2,0),(2,6)]],
 "2": [[(0,1),(1,0),(3,0),(4,1),(4,2),(0,6),(4,6)]],
 "3": [[(0,1),(1,0),(3,0),(4,1),(4,2),(3,3),(1.5,3)],[(3,3),(4,4),(4,5),(3,6),(1,6),(0,5)]],
 "4": [[(3,6),(3,0),(0,4),(4,4)]], "7": [[(0,0),(4,0),(1.5,6)]],
 "8": [[(1,3),(0,2),(0,1),(1,0),(3,0),(4,1),(4,2),(3,3),(1,3),(0,4),(0,5),(1,6),(3,6),(4,5),(4,4),(3,3)]],
 " ": [], ".": [[(2,5.5),(2,6)]], "!": [[(2,0),(2,4)],[(2,5.6),(2,6)]], "-": [[(1,3),(3,3)]],
}
_F["É"] = _F["E"] + [[(1.5,-1.2),(3,-2.2)]]

def text(s, x, y, h, stroke=INK, sw=1.6, op=1, angle=0, track=5.6, j=0.25):
    """Hand-lettered capitals, top-left at (x, y), cap height h."""
    k, d = h / 6.0, ""
    for i, ch in enumerate(s):
        for st in _F.get(ch, []):
            d += "M" + "L".join("%.1f %.1f" % (x + (i * track + px) * k + R.uniform(-j, j), y + py * k + R.uniform(-j, j)) for px, py in st)
    out.append(f'<path transform="rotate({angle} {x} {y})" d="{d}" fill="none" stroke="{stroke}" stroke-width="{sw}" stroke-linecap="round" stroke-linejoin="round" opacity="{op}"/>')

def svg(w=600, h=800, scale=1):
    return f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {w} {h}" width="{w * scale}" height="{h * scale}">\n<defs>{"".join(defs)}</defs>\n' + "\n".join(out) + "\n</svg>\n"
