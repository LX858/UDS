"""Run Lua control-flow regressions with mocked FiveM natives.

Requires lupa (pip install lupa). This does not validate GTA animation geometry,
network replication, or rendered cameras. Run from any working directory.
"""
from pathlib import Path
import json
from lupa import LuaRuntime

root = Path(__file__).resolve().parents[1]
lua = LuaRuntime(unpack_returned_tuples=True)
lua.globals().RESOURCE_ROOT = root.as_posix()
reference = json.loads((root / 'tests' / 'fbi3_clip_reference.json').read_text())
lua.globals().FBI3_CLIPS = lua.table_from({
    dictionary: lua.table_from({clip: True for clip in clips})
    for dictionary, clips in reference['clips'].items()
})
lua.execute((root / "tests" / "scene_flow.lua").read_text(encoding="utf-8"))
