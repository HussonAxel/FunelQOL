"""Check addon Lua 5.1 syntax, then run mocks (which use utf8) in Lua 5.4."""
import os
import sys
from pathlib import Path
from lupa.lua51 import LuaRuntime as Lua51
from lupa.lua54 import LuaRuntime

root = Path(__file__).resolve().parents[1]
os.chdir(root)
paths = sys.argv[1:] or [str(p.relative_to(root)) for p in sorted((root / "tests").glob("*.lua"))]
failed = []
compiler = Lua51().eval("function(source, name) local fn, err = loadstring(source, name); return fn ~= nil, err end")
for path in list(root.glob("*.lua")) + list((root / "Libs").rglob("*.lua")):
    valid, error = compiler(path.read_text(encoding="utf-8-sig"), str(path.relative_to(root)))
    if not valid:
        failed.append(str(path))
        print(f"FAIL syntax: {error}", flush=True)
for name in paths:
    print(f"TEST {name}", flush=True)
    runtime = LuaRuntime()
    runtime.execute("unpack = table.unpack; loadstring = load")
    runtime.globals().FUNEL_PERF_BASELINE = os.environ.get("FUNEL_PERF_BASELINE") == "1"
    try:
        runtime.execute(Path(name).read_text(encoding="utf-8-sig"))
    except Exception as error:
        failed.append(name)
        print(f"FAIL {name}: {error}", flush=True)
if failed:
    sys.exit(1)
