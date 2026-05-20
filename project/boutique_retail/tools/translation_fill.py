#!/usr/bin/env python3
"""Fill translated_text in audit CSV using glossary + machine translation."""

from __future__ import annotations

import argparse
import csv
import re
import time
from pathlib import Path

GLOSSARY_DEFAULT = Path(__file__).resolve().parent.parent / "glossaire_traduction_fr.md"
PLACEHOLDER_RE = re.compile(
    r"(\{[^{}]+\}|%\([^)]+\)[sdif]|%\([a-zA-Z_]+\)s|%\d*\$?[sdif]|<[^>]+>)"
)


def load_glossary(path: Path) -> dict[str, str]:
    if not path.is_file():
        return {}
    glossary: dict[str, str] = {}
    for line in path.read_text(encoding="utf-8").splitlines():
        if not line.startswith("|") or line.startswith("| EN") or line.startswith("|-"):
            continue
        parts = [p.strip() for p in line.strip("|").split("|")]
        if len(parts) < 2:
            continue
        en, fr = parts[0], parts[1]
        if en and fr and en != "EN (source)":
            glossary[en] = fr
    return glossary


def protect_placeholders(text: str) -> tuple[str, list[str]]:
    tokens: list[str] = []

    def repl(match: re.Match[str]) -> str:
        tokens.append(match.group(0))
        return f"__PH{len(tokens) - 1}__"

    return PLACEHOLDER_RE.sub(repl, text), tokens


def restore_placeholders(text: str, tokens: list[str]) -> str:
    for i, token in enumerate(tokens):
        text = text.replace(f"__PH{i}__", token)
    return text


def translate_one(text: str, translator, glossary: dict[str, str]) -> str:
    stripped = text.strip()
    if stripped in glossary:
        return glossary[stripped]
    protected, tokens = protect_placeholders(text)
    try:
        translated = translator.translate(protected)
    except Exception:
        translated = protected
    return restore_placeholders(translated, tokens)


def translate_batch_safe(
    texts: list[str], translator, glossary: dict[str, str]
) -> list[str]:
    """Translate a batch; fall back to per-line on failure."""
    prepared: list[tuple[str, str, list[str]]] = []
    results: list[str | None] = [None] * len(texts)
    mt_indices: list[int] = []
    mt_payload: list[str] = []

    for idx, text in enumerate(texts):
        stripped = text.strip()
        if stripped in glossary:
            results[idx] = glossary[stripped]
            continue
        protected, tokens = protect_placeholders(text)
        prepared.append((text, protected, tokens))
        mt_indices.append(idx)
        mt_payload.append(protected)

    if not mt_payload:
        return [r or "" for r in results]

    try:
        mt_results = translator.translate_batch(mt_payload)
        for idx, (orig, _protected, tokens), fr in zip(
            mt_indices, prepared, mt_results
        ):
            results[idx] = restore_placeholders(fr, tokens)
    except Exception:
        for idx, (orig, _protected, tokens) in zip(mt_indices, prepared):
            results[idx] = translate_one(orig, translator, glossary)

    return [r or "" for r in results]


def main() -> None:
    parser = argparse.ArgumentParser(description="Fill FR translations in audit CSV")
    parser.add_argument(
        "--input",
        type=Path,
        default=Path("project/boutique_retail/reports/translation-gaps-retail-fr.csv"),
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=Path("project/boutique_retail/reports/translation-retail-fr-filled.csv"),
    )
    parser.add_argument("--glossary", type=Path, default=GLOSSARY_DEFAULT)
    parser.add_argument("--batch-size", type=int, default=40)
    parser.add_argument("--sleep", type=float, default=0.25)
    parser.add_argument("--limit", type=int, default=0, help="Max unique strings to translate (0=all)")
    args = parser.parse_args()

    try:
        from deep_translator import GoogleTranslator
    except ImportError as exc:
        raise SystemExit("pip install deep-translator") from exc

    glossary = load_glossary(args.glossary)
    rows: list[dict[str, str]] = []
    with args.input.open(newline="", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        fieldnames = list(reader.fieldnames or [])
        for row in reader:
            rows.append(dict(row))

    if not rows:
        print("no rows in input")
        return

    unique_sources: list[str] = []
    seen: set[str] = set()
    for row in rows:
        src = (row.get("source_text") or "").strip()
        if not src or src in seen:
            continue
        seen.add(src)
        unique_sources.append(src)

    translator = GoogleTranslator(source="en", target="fr")
    cache: dict[str, str] = dict(glossary)
    to_translate = [s for s in unique_sources if s not in cache]
    if args.limit:
        to_translate = to_translate[: args.limit]

    def log(msg: str) -> None:
        print(msg, flush=True)

    log(f"unique sources: {len(unique_sources)}, to translate: {len(to_translate)}")
    batch_size = max(1, args.batch_size)
    for i in range(0, len(to_translate), batch_size):
        batch = to_translate[i : i + batch_size]
        for src, fr in zip(batch, translate_batch_safe(batch, translator, glossary)):
            cache[src] = fr
        done = min(i + batch_size, len(to_translate))
        log(f"translated {done}/{len(to_translate)}")
        if args.sleep > 0:
            time.sleep(args.sleep)

    filled = 0
    for row in rows:
        src = (row.get("source_text") or "").strip()
        existing = (row.get("translated_text") or "").strip()
        if existing and existing != src:
            continue
        if src in cache and cache[src]:
            row["translated_text"] = cache[src]
            filled += 1

    args.output.parent.mkdir(parents=True, exist_ok=True)
    with args.output.open("w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames, quoting=csv.QUOTE_MINIMAL)
        writer.writeheader()
        writer.writerows(rows)

    log(f"wrote {args.output} ({filled} rows filled, {len(cache)} cached translations)")


if __name__ == "__main__":
    main()
