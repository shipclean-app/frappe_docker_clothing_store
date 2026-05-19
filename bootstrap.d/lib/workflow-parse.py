#!/usr/bin/env python3
"""Load bootstrap workflow YAML, resolve includes and variables, emit JSON."""

from __future__ import annotations

import json
import os
import re
import sys
from pathlib import Path

try:
    import yaml
except ImportError:
    sys.stderr.write("PyYAML requis: pip install pyyaml\n")
    sys.exit(1)

VAR_PATTERN = re.compile(
    r"\$\{([A-Za-z_][A-Za-z0-9_]*)(?::-([^}]*))?\}"
)


def substitute(value: str, env: dict[str, str]) -> str:
    if "${" not in value:
        return value

    def repl(match: re.Match[str]) -> str:
        key = match.group(1)
        default = match.group(2)
        if key in env and env[key] != "":
            return env[key]
        if default is not None:
            return substitute(default, env)
        return match.group(0)

    prev = None
    while prev != value and "${" in value:
        prev = value
        value = VAR_PATTERN.sub(repl, value)
    return value


def deep_substitute(obj, env: dict[str, str]):
    if isinstance(obj, dict):
        return {k: deep_substitute(v, env) for k, v in obj.items()}
    if isinstance(obj, list):
        return [deep_substitute(v, env) for v in obj]
    if isinstance(obj, str):
        return substitute(obj, env)
    return obj


def load_yaml(path: Path) -> dict:
    data = yaml.safe_load(path.read_text(encoding="utf-8"))
    return data if isinstance(data, dict) else {}


def resolve_includes(
    data: dict,
    workflows_dir: Path,
    seen: set[Path],
) -> list[dict]:
    steps: list[dict] = []
    for inc in data.get("include") or data.get("includes") or []:
        inc_path = workflows_dir / inc
        if not inc_path.is_file():
            inc_path = workflows_dir / "_fragments" / inc
        if not inc_path.is_file() and not str(inc).endswith(".yaml"):
            inc_path = workflows_dir / "_fragments" / f"{inc}.yaml"
        inc_path = inc_path.resolve()
        if inc_path in seen:
            raise SystemExit(f"include circulaire: {inc_path}")
        seen.add(inc_path)
        frag = load_yaml(inc_path)
        steps.extend(resolve_includes(frag, workflows_dir, seen))
    steps.extend(data.get("steps") or [])
    return steps


def build_env(extra: dict[str, str] | None = None) -> dict[str, str]:
    env = {k: str(v) for k, v in os.environ.items()}
    if extra:
        env.update({k: str(v) for k, v in extra.items()})
    return env


def parse_workflow(workflow_path: Path, extra_env: dict[str, str] | None = None) -> dict:
    workflows_dir = workflow_path.parent
    raw = load_yaml(workflow_path)
    seen: set[Path] = {workflow_path.resolve()}
    steps = resolve_includes(raw, workflows_dir, seen)

    env = build_env()
    for key, val in (raw.get("variables") or {}).items():
        if isinstance(val, str):
            resolved = substitute(val, env)
            env[key] = resolved
            env[key.upper()] = resolved
    if extra_env:
        env.update({k: str(v) for k, v in extra_env.items()})

    return {
        "name": raw.get("name") or workflow_path.stem,
        "description": raw.get("description", ""),
        "limits": raw.get("limits") or [],
        "steps": deep_substitute(steps, env),
    }


def main() -> None:
    if len(sys.argv) < 2:
        sys.stderr.write("usage: workflow-parse.py <workflow.yaml> [key=val ...]\n")
        sys.exit(2)

    workflow_path = Path(sys.argv[1]).resolve()
    extra: dict[str, str] = {}
    for arg in sys.argv[2:]:
        if "=" in arg:
            k, v = arg.split("=", 1)
            extra[k] = v

    if not workflow_path.is_file():
        sys.stderr.write(f"workflow introuvable: {workflow_path}\n")
        sys.exit(1)

    data = parse_workflow(workflow_path, extra)
    json.dump(data, sys.stdout, ensure_ascii=False)


if __name__ == "__main__":
    main()
