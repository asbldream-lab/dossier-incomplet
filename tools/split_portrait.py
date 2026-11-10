"""Split a portrait SVG into layers by comment markers (same viewBox, transparent bg).
Usage: python3 -I tools/split_portrait.py assets/2d/secretaire.svg
Writes <name>_base.svg, <name>_arm_stamp.svg, <name>_arm_phone.svg, <name>_fx.svg"""
import sys, re
src = sys.argv[1]
s = open(src, encoding="utf-8").read()
head = s[:s.index("</defs>") + len("</defs>")]
body = s[len(head):s.rindex("</svg>")]
M = {"arm_stamp": ("<!-- RIGHT ARM", "<!-- LEFT ARM"), "arm_phone": ("<!-- LEFT ARM", "<!-- atmosphere -->"), "fx": ("<!-- atmosphere -->", None)}
parts = {}
base = body
for name, (a, b) in M.items():
    i = body.index(a); j = body.index(b) if b else len(body)
    parts[name] = body[i:j]
    base = base.replace(body[i:j], "")
parts["base"] = base
for name, chunk in parts.items():
    open(src.replace(".svg", f"_{name}.svg"), "w", encoding="utf-8").write(head + chunk + "</svg>\n")
    print("wrote", name, len(chunk))
