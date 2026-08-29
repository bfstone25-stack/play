#!/usr/bin/env python3
"""Dump every form field on an itch game-edit page (read-only diagnostic).

Run on pop-os where the Firefox itch session lives. Reuses the helpers from
itch-analytics/jam_submit.py so cookies keep itchio_token from the GET.
"""
from __future__ import annotations

import argparse
import html as htmlmod
import re
import sys
from html.parser import HTMLParser
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from jam_submit import csrf_from, fetch, firefox_itch_cookies, opener_for, logged_in


class FormFields(HTMLParser):
    def __init__(self) -> None:
        super().__init__()
        self.fields: dict[str, str] = {}
        self._ta_name: str | None = None
        self._ta_buf: list[str] = []
        self._sel_name: str | None = None
        self._opt_value: str | None = None
        self._opt_selected = False
        self._opt_buf: list[str] = []
        self.options: dict[str, list[tuple[str, str, bool]]] = {}

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        a = dict(attrs)
        name = a.get("name")
        if tag == "input" and name:
            typ = (a.get("type") or "text").lower()
            if typ in {"button", "submit", "file"}:
                if typ == "file":
                    self.fields[f"FILE:{name}"] = ""
                return
            if typ == "radio":
                if "checked" in a:
                    self.fields[name] = a.get("value") or ""
                else:
                    self.fields.setdefault(f"RADIOOPT:{name}", a.get("value") or "")
                return
            if typ == "checkbox":
                if "checked" in a:
                    self.fields[name] = a.get("value") or "on"
                else:
                    self.fields.setdefault(f"CHKOPT:{name}", a.get("value") or "on")
                return
            self.fields[name] = a.get("value") or ""
        elif tag == "textarea" and name:
            self._ta_name = name
            self._ta_buf = []
        elif tag == "select" and name:
            self._sel_name = name
            self.options.setdefault(name, [])
        elif tag == "option" and self._sel_name:
            self._opt_value = a.get("value") or ""
            self._opt_selected = "selected" in a
            self._opt_buf = []

    def handle_data(self, data: str) -> None:
        if self._ta_name:
            self._ta_buf.append(data)
        if self._sel_name and self._opt_value is not None:
            self._opt_buf.append(data)

    def handle_endtag(self, tag: str) -> None:
        if tag == "textarea" and self._ta_name:
            self.fields[self._ta_name] = htmlmod.unescape("".join(self._ta_buf))
            self._ta_name = None
        elif tag == "option" and self._sel_name:
            label = "".join(self._opt_buf).strip()
            self.options[self._sel_name].append((self._opt_value or "", label, self._opt_selected))
            if self._opt_selected or self._sel_name not in self.fields:
                self.fields[self._sel_name] = self._opt_value or ""
            self._opt_value = None
        elif tag == "select":
            self._sel_name = None


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("game_id", type=int)
    ap.add_argument("--show-values", action="store_true", help="print long values too")
    args = ap.parse_args()
    cookies = firefox_itch_cookies()
    if "itchio" not in cookies:
        print("NOT LOGGED IN")
        return 2
    opener = opener_for(cookies)
    url = f"https://itch.io/game/edit/{args.game_id}"
    code, _, page = fetch(opener, url)
    print(f"GET {url} -> {code}, {len(page)} bytes, logged_in={logged_in(page)}")
    if code != 200:
        return 1
    token = csrf_from(page, cookies)
    print(f"csrf_token present: {bool(token)}")
    p = FormFields()
    p.feed(page)
    print(f"--- {len(p.fields)} fields ---")
    for k in sorted(p.fields):
        v = p.fields[k]
        if len(v) > 90 and not args.show_values:
            v = v[:90] + f"... <{len(v)} chars>"
        print(f"{k} = {v!r}")
    print("--- select options ---")
    for name, opts in p.options.items():
        print(f"[{name}]")
        for value, label, selected in opts:
            mark = "*" if selected else " "
            print(f"  {mark} {value!r}: {label}")
    # screenshot rows
    shots = re.findall(r'data-screenshot_id="(\d+)"', page)
    print(f"--- screenshots on page: {shots} ---")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
