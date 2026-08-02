#!/usr/bin/env python3
"""cache-gen.py — Generate ~/Code/dk-digital-bank/dk.yaml

Scans the dk-digital-bank code_root for git repos, applies
blueprint↔provisioner auto-pairing, preserves manual entries,
and writes the updated cache.
"""

import os
import json
import subprocess
from datetime import datetime, timezone
from pathlib import Path
from collections import defaultdict

DK_YAML = Path.home() / "Code/dk-digital-bank/dk.yaml"
CODE_ROOT = Path.home() / "Code/dk-digital-bank"
SLUG = "dk-digital-bank"


def yq_json(path: str, query: str):
    result = subprocess.run(
        ["yq", "e", "-o", "json", query, path],
        capture_output=True, text=True, cwd=Path.home()
    )
    if not result.stdout.strip() or result.stdout.strip() == "null":
        return None
    return json.loads(result.stdout)


def expand_path(p: str) -> Path:
    return Path(p).expanduser().resolve()


def find_git_repos(root: Path) -> list[Path]:
    repos = []
    if not root.exists():
        return repos
    try:
        result = subprocess.run(
            ["find", str(root), "-name", ".git", "-type", "d", "-maxdepth", "6"],
            capture_output=True, text=True, timeout=30
        )
        for line in result.stdout.strip().split("\n"):
            if line:
                repos.append(Path(line).parent)
    except (subprocess.TimeoutExpired, FileNotFoundError):
        pass
    return repos


def relpath(path: Path, base: Path) -> str:
    try:
        return str(path.relative_to(base))
    except ValueError:
        return str(path)


def load_existing_cache() -> dict | None:
    if not DK_YAML.exists():
        return None
    return yq_json(str(DK_YAML), ".")


def auto_pair_blueprint_provisioner(repos: list[Path]) -> dict[str, dict]:
    """Find blueprint↔provisioner pairs by basename convention."""
    by_name = defaultdict(list)
    for repo in repos:
        by_name[repo.name].append(repo)

    workspaces = {}

    for name, dirs in by_name.items():
        if len(dirs) < 2:
            continue

        blueprint_dirs = [d for d in dirs if "blueprints" in d.parts]
        provisioner_dirs = [d for d in dirs if "provisioner" in d.parts]

        if not blueprint_dirs or not provisioner_dirs:
            continue

        all_dirs = blueprint_dirs + provisioner_dirs
        common = Path(os.path.commonpath([str(d) for d in all_dirs]))
        common_root = relpath(common, CODE_ROOT) if common != CODE_ROOT else "."

        # Determine suborg for disambiguation
        suborgs = set()
        for d in all_dirs:
            try:
                rel = d.relative_to(CODE_ROOT)
                parts = rel.parts
                for i, part in enumerate(parts):
                    if part in ("blueprints", "provisioner") and i > 0:
                        candidate = parts[i - 1]
                        if candidate not in ("platform", "apps", "services", "security"):
                            suborgs.add(candidate)
            except ValueError:
                pass

        if len(suborgs) == 1:
            session_name = f"{SLUG}/{suborgs.pop()}/{name}"
        else:
            session_name = f"{SLUG}/{name}"

        bp_paths = [relpath(d, CODE_ROOT) for d in blueprint_dirs]
        prov_paths = [relpath(d, CODE_ROOT) for d in provisioner_dirs]
        description = f"Blueprint{'s' if len(blueprint_dirs)>1 else ''}: {', '.join(bp_paths)} | Provisioner: {', '.join(prov_paths)}"

        workspaces[name] = {
            "description": description,
            "dirs": sorted([relpath(d, CODE_ROOT) for d in all_dirs]),
            "common_root": common_root,
            "session_name": session_name,
            "kind": "convention",
            "last_opened": None,
        }

    return workspaces


def build_discovered(repos: list[Path], workspace_dirs: set[str]) -> dict[str, str]:
    """Build flat name→path map of repos not covered by workspaces."""
    discovered = {}
    for repo in repos:
        rel = relpath(repo, CODE_ROOT)
        if rel in workspace_dirs:
            continue
        key = repo.name
        if key in discovered:
            key = rel.replace("/", "-")
        discovered[key] = rel
    return discovered


def merge_with_existing(new_cache: dict, existing: dict | None) -> dict:
    """Preserve manual entries, descriptions, and last_opened."""
    if not existing:
        return new_cache

    existing_workspaces = existing.get("workspaces", {})

    for ws_key, ws in new_cache.get("workspaces", {}).items():
        if ws_key in existing_workspaces:
            ews = existing_workspaces[ws_key]
            if ews.get("kind") == "manual":
                new_cache["workspaces"][ws_key] = ews
            else:
                if ews.get("description"):
                    ws["description"] = ews["description"]
                if ews.get("session_name"):
                    ws["session_name"] = ews["session_name"]
                if ews.get("last_opened"):
                    ws["last_opened"] = ews["last_opened"]
                new_cache["workspaces"][ws_key] = ws

    # Carry over manual workspaces not in new auto-detected set
    for ws_key, ews in existing_workspaces.items():
        if ws_key not in new_cache["workspaces"]:
            if ews.get("kind") in ("manual", "adhoc"):
                new_cache["workspaces"][ws_key] = ews

    # Preserve remote_only
    if "remote_only" in existing:
        new_cache["remote_only"] = existing["remote_only"]

    return new_cache


def build_cache(existing: dict | None = None) -> dict:
    repos = find_git_repos(CODE_ROOT)
    workspaces = auto_pair_blueprint_provisioner(repos)

    ws_dirs: set[str] = set()
    for ws in workspaces.values():
        for d in ws["dirs"]:
            ws_dirs.add(d)

    discovered = build_discovered(repos, ws_dirs)

    now = datetime.now(timezone.utc).isoformat()
    cache = {
        "version": 1,
        "generated_at": now,
        "code_root": "~/Code/dk-digital-bank",
        "workspaces": workspaces,
        "discovered": discovered,
        "remote_only": [],
    }

    cache = merge_with_existing(cache, existing)
    return cache


def write_yaml(cache: dict) -> None:
    header = (
        "# dk.yaml — DK Digital Bank Workspace Cache\n"
        "# Auto-generated by cache-gen.py. Edits to manual entries are preserved.\n"
        "# Schema version 1.\n"
        "#\n"
        "#   workspaces:  confirmed workspace definitions (opened at least once)\n"
        "#   discovered:  all repos on disk, for search fallback\n"
        "#   remote_only: repos on GitLab not yet cloned\n"
        "\n"
    )

    with open(DK_YAML, "w") as f:
        f.write(header)
        f.write(f"version: {cache['version']}\n")
        f.write(f'generated_at: "{cache["generated_at"]}"\n')
        f.write(f'code_root: {cache["code_root"]}\n')
        f.write("\n")

        f.write("workspaces:\n")
        if cache["workspaces"]:
            for ws_key, ws in cache["workspaces"].items():
                f.write(f"  {ws_key}:\n")
                f.write(f'    description: {_yaml_str(ws["description"])}\n')
                f.write("    dirs:\n")
                for d in ws["dirs"]:
                    f.write(f"      - {d}\n")
                f.write(f'    common_root: {_yaml_str(ws["common_root"])}\n')
                f.write(f'    session_name: {_yaml_str(ws["session_name"])}\n')
                f.write(f'    kind: {_yaml_str(ws["kind"])}\n')
                f.write(f'    last_opened: {_yaml_val(ws["last_opened"])}\n')
        else:
            f.write("  {}\n")
        f.write("\n")

        f.write("discovered:\n")
        if cache["discovered"]:
            for name in sorted(cache["discovered"].keys()):
                path = cache["discovered"][name]
                f.write(f'  {name}: {path}\n')
        else:
            f.write("  {}\n")
        f.write("\n")

        f.write("remote_only:\n")
        if cache["remote_only"]:
            for entry in cache["remote_only"]:
                f.write(f"  - name: {entry.get('name', '')}\n")
                f.write(f"    path_with_namespace: {entry.get('path_with_namespace', '')}\n")
                f.write(f'    description: {_yaml_str(entry.get("description", ""))}\n')
        else:
            f.write("  []\n")

    print(f"Cache written to {DK_YAML}")


def _yaml_str(val) -> str:
    """Quote strings that could be ambiguous in YAML."""
    if val is None:
        return "null"
    s = str(val)
    if s in ("null", "true", "false", "yes", "no", ""):
        return f'"{s}"'
    if any(c in s for c in (":", "#", "{", "}", "[", "]", "&", "*", "!", "|", ">", "%", "@", "`", "'")):
        return f'"{s}"'
    return s


def _yaml_val(val) -> str:
    if val is None:
        return "null"
    if isinstance(val, bool):
        return "true" if val else "false"
    return _yaml_str(val)


def main():
    existing = load_existing_cache()
    cache = build_cache(existing)
    write_yaml(cache)

    ws_count = len(cache.get("workspaces", {}))
    disc_count = len(cache.get("discovered", {}))
    print(f"  workspaces: {ws_count} (convention-paired)")
    print(f"  discovered: {disc_count} repos")


if __name__ == "__main__":
    main()
