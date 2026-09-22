"""Read the GDScript story tables as real Python data.

The literals are Python-compatible once the `const NAME := ` header is stripped, so
slice to the matching bracket and ast.literal_eval. Anything else (a regex over quoted
strings) miscounts ids and coordinates as prose."""
import ast, os, re

SCRIPTS = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "scripts")

def _strip_comments(src):
    out = []
    for line in src.split("\n"):
        q = False; esc = False; cut = None
        for i, ch in enumerate(line):
            if esc: esc = False; continue
            if ch == "\\": esc = True; continue
            if ch == '"': q = not q; continue
            if ch == "#" and not q: cut = i; break
        out.append(line if cut is None else line[:cut])
    return "\n".join(out)

def const(path, name):
    src = _strip_comments(open(path, encoding="utf-8").read())
    m = re.search(r'\bconst\s+%s\s*:=\s*' % re.escape(name), src)
    if not m:
        return None
    i = m.end()
    open_ch = src[i]
    close_ch = {"[": "]", "{": "}"}[open_ch]
    depth = 0; q = False; esc = False; j = i
    while j < len(src):
        ch = src[j]
        if esc: esc = False
        elif ch == "\\": esc = True
        elif ch == '"': q = not q
        elif not q:
            if ch == open_ch: depth += 1
            elif ch == close_ch:
                depth -= 1
                if depth == 0: break
        j += 1
    return ast.literal_eval(src[i:j+1])

def body_strings(path):
    """Every string a player can read, as (route, text) pairs.

    Speaker labels are included: a Japanese build with English speaker names is still
    half-translated. Ids, hotspot coordinates and flag keys are not player-facing."""
    out = []
    areas = const(path, "AREAS") or []
    for a in areas:
        aid = a.get("id", "?")
        for k in ("place", "clock", "objective"):
            if k in a: out.append((f"{aid}.{k}", a[k]))
        for k in ("opening", "transition"):
            for n, pair in enumerate(a.get(k, [])):
                out.append((f"{aid}.{k}[{n}].who", pair[0]))
                out.append((f"{aid}.{k}[{n}].say", pair[1]))
        for h in a.get("hotspots", []):
            out.append((f"{aid}.hs.{h[0]}.label", h[1]))
            for n, pair in enumerate(h[3]):
                # ["CONDITIONAL", "KEY"] is a branch marker resolved at runtime, not prose.
                if pair[0] == "CONDITIONAL":
                    continue
                out.append((f"{aid}.hs.{h[0]}[{n}].who", pair[0]))
                out.append((f"{aid}.hs.{h[0]}[{n}].say", pair[1]))
        ch = a.get("choice")
        if ch:
            out.append((f"{aid}.choice.prompt", ch.get("prompt", "")))
            for n, opt in enumerate(ch.get("options", [])):
                out.append((f"{aid}.choice[{n}].label", opt.get("label", "")))
                if opt.get("result"): out.append((f"{aid}.choice[{n}].result", opt["result"]))
    ends = const(path, "ENDINGS") or {}
    for eid, lines in ends.items():
        for n, pair in enumerate(lines):
            if isinstance(pair, list) and len(pair) == 2:
                if pair[0] == "CONDITIONAL":
                    continue
                out.append((f"end.{eid}[{n}].who", pair[0]))
                out.append((f"end.{eid}[{n}].say", pair[1]))
    out.extend(conditional_strings(path))
    return [(r, t) for r, t in out if isinstance(t, str) and t.strip()]

# The function ends at a blank-line run OR at end of file. Requiring "\n\n\n" meant
# every story file whose conditional() was the last thing in it returned no lines at all
# — which is exactly where story_ja.gd was still holding 17 Chinese branch lines.
CONDFN = re.compile(r"static func conditional(?:_line)?\(.*?(?=\n\n\n|\Z)", re.S)
PAIR = re.compile(r'\["((?:[^"\\]|\\.)*)",\s*"((?:[^"\\]|\\.)*)"\]')
KEYLINE = re.compile(r'\s*"([A-Z_]+)":\s*$')


def conditional_strings(path):
    """The branching one-liners live inside a match statement, not a const."""
    src = _strip_comments(open(path, encoding="utf-8").read())
    m = CONDFN.search(src)
    if not m:
        return []
    out = []
    key = "?"
    for line in m.group(0).split("\n"):
        km = KEYLINE.match(line)
        if km:
            key = km.group(1)
            continue
        for n, pm in enumerate(PAIR.finditer(line)):
            who, say = pm.group(1), pm.group(2)
            if not say.strip():
                continue
            out.append((f"cond.{key}[{n}].who", who))
            out.append((f"cond.{key}[{n}].say", say))
    return out


def p(name):
    return os.path.join(SCRIPTS, name)

if __name__ == "__main__":
    import sys
    for f in ("story_data.gd", "story_zh.gd", "story_ja.gd"):
        print(f, len(body_strings(p(f))))
