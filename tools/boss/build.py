"""Build assets/2d/secretaire.svg. Usage: python3 -I tools/boss/build.py [parts...]"""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import kit, importlib
for name in (sys.argv[1:] or ["bg", "body", "head", "desk", "arms", "fx"]):
    importlib.import_module(name).draw()
dst = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "assets", "2d", "secretaire.svg")
open(dst, "w", encoding="utf-8").write(kit.svg())
print("wrote", len(kit.svg()) // 1024, "KB")
