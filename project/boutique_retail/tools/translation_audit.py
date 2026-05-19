#!/usr/bin/env python3
"""Audit missing French translations in Frappe/ERPNext .po files (retail priority)."""

from __future__ import annotations

import argparse
import csv
import re
from dataclasses import dataclass
from pathlib import Path

# Priority path prefixes (#: comments in .po files)
PRIORITY_PATTERNS = {
    "P0": [
        r"erpnext/selling/page/point_of_sale",
        r"erpnext/selling/",
    ],
    "P1": [
        r"erpnext/stock/",
        r"erpnext/buying/",
        r"erpnext/setup/",
        r"erpnext/accounts/doctype/mode_of_payment",
        r"erpnext/accounts/doctype/pos_profile",
        r"erpnext/accounts/doctype/payment_entry",
        r"erpnext/accounts/doctype/sales_invoice",
        r"erpnext/accounts/doctype/sales_taxes",
    ],
    "P2": [
        r"frappe/desk/",
        r"frappe/core/",
    ],
}

DEFAULT_PO_PATHS = [
    Path("apps/frappe/frappe/locale/fr.po"),
    Path("apps/erpnext/erpnext/locale/fr.po"),
]


@dataclass
class Entry:
    app: str
    source_text: str
    translated_text: str
    refs: str
    priority: str
    status: str


def parse_po(path: Path, app: str) -> list[dict]:
    text = path.read_text(encoding="utf-8", errors="replace")
    blocks = re.split(r"\n\n+", text)
    entries = []
    for block in blocks:
        if "msgid " not in block:
            continue
        mid_m = re.search(r"^msgid\s+\"(.*)\"", block, re.M | re.S)
        if not mid_m:
            continue
        msgid = mid_m.group(1).replace("\\n", "\n")
        if not msgid:
            continue
        mstr_m = re.search(r"^msgstr\s+\"(.*)\"", block, re.M | re.S)
        msgstr = mstr_m.group(1).replace("\\n", "\n") if mstr_m else ""
        refs = " ".join(re.findall(r"^#:\s*(.+)$", block, re.M))
        entries.append({"app": app, "msgid": msgid, "msgstr": msgstr, "refs": refs})
    return entries


def classify_priority(refs: str) -> str:
    for prio, patterns in PRIORITY_PATTERNS.items():
        for pat in patterns:
            if re.search(pat, refs):
                return prio
    return "P3"


def status(msgid: str, msgstr: str) -> str:
    if not msgstr:
        return "missing"
    if msgstr == msgid:
        return "untranslated_copy"
    return "ok"


def main():
    parser = argparse.ArgumentParser(description="Audit FR .po gaps for retail ERPNext")
    parser.add_argument(
        "--priority",
        choices=["P0", "P1", "P2", "P3", "all", "retail"],
        default="retail",
        help="retail = P0+P1+P2",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=Path("translation-gaps-retail-fr.csv"),
    )
    parser.add_argument("--frappe-po", type=Path, default=DEFAULT_PO_PATHS[0])
    parser.add_argument("--erpnext-po", type=Path, default=DEFAULT_PO_PATHS[1])
    args = parser.parse_args()

    allowed = {"P0", "P1", "P2", "P3"}
    if args.priority == "retail":
        allowed = {"P0", "P1", "P2"}
    elif args.priority != "all":
        allowed = {args.priority}

    rows: list[Entry] = []
    for path, app in ((args.frappe_po, "frappe"), (args.erpnext_po, "erpnext")):
        if not path.is_file():
            print(f"skip missing: {path}")
            continue
        for e in parse_po(path, app):
            prio = classify_priority(e["refs"])
            if prio not in allowed:
                continue
            st = status(e["msgid"], e["msgstr"])
            if st == "ok":
                continue
            rows.append(
                Entry(
                    app=e["app"],
                    source_text=e["msgid"],
                    translated_text=e["msgstr"],
                    refs=e["refs"],
                    priority=prio,
                    status=st,
                )
            )

    args.output.parent.mkdir(parents=True, exist_ok=True)
    with args.output.open("w", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        w.writerow(["app", "priority", "status", "source_text", "translated_text", "refs"])
        for r in sorted(rows, key=lambda x: (x.priority, x.app, x.source_text)):
            w.writerow([r.app, r.priority, r.status, r.source_text, r.translated_text, r.refs])

    print(f"wrote {len(rows)} gaps to {args.output}")


if __name__ == "__main__":
    main()
