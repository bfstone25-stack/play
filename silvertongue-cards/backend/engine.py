"""The parent's persuasion engine, imported from the parent tree unchanged.

`play/silvertongue-x/backend/persuasion_engine.py` is the single authority on progression
(`advance()`), on what a line means (`decompose()`), and on which plates a turn earns
(`plate()`). The card game does not copy it and does not fork it: it loads the file from
where it lives, so a rule fix in the parent is a rule fix here. `ST_ENGINE_PATH` overrides
the location for a deployment that ships the two trees apart.
"""
from __future__ import annotations

import importlib.util
import os

HERE = os.path.dirname(os.path.abspath(__file__))
_DEFAULT = os.path.join(os.path.dirname(os.path.dirname(HERE)), "silvertongue-x", "backend", "persuasion_engine.py")
ENGINE_PATH = os.getenv("ST_ENGINE_PATH", _DEFAULT)

_spec = importlib.util.spec_from_file_location("st_persuasion_engine", ENGINE_PATH)
_mod = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(_mod)

advance = _mod.advance
decompose = _mod.decompose
plate = _mod.plate
RULES = _mod.RULES
COMMON = _mod.COMMON
NEGATIVE = _mod.NEGATIVE
load_state = _mod.load_state
dump_state = _mod.dump_state
