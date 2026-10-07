#!/usr/bin/env python3
"""ScrapeCraft JSON Explorer - map unknown API response trees.

stdlib-only (no third-party dependencies). Maps every occurrence of a key
in a JSON document, counts repeating renderer structures, and extracts
subtrees so an agent can design parsers for unknown internal APIs.

Usage:
    python3 scripts/json-explorer.py --url https://api.example.com/data
    python3 scripts/json-explorer.py --file response.json
    python3 scripts/json-explorer.py --file response.json --key videoId
    python3 scripts/json-explorer.py --file response.json --renderers
    python3 scripts/json-explorer.py --file response.json --key videoId --extract 2
"""
import argparse
import json
import re
import sys
import urllib.request
from collections import Counter

RENDERER_PATTERN = re.compile(r"^[A-Za-z]+Renderer$")


def load_json(args):
    if args.file:
        with open(args.file, "r", encoding="utf-8") as handle:
            return json.load(handle)
    if args.url:
        request = urllib.request.Request(
            args.url,
            headers={"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36"},
        )
        with urllib.request.urlopen(request, timeout=30) as response:
            charset = response.headers.get_content_charset() or "utf-8"
            return json.loads(response.read().decode(charset, errors="replace"))
    raw = sys.stdin.read()
    if not raw.strip():
        print("ERROR: No input provided. Use --url, --file, or pipe JSON via stdin.", file=sys.stderr)
        sys.exit(1)
    return json.loads(raw)


def walk(node, path="$"):
    """Yield (path, key, value) tuples for every node in the tree."""
    if isinstance(node, dict):
        for key, value in node.items():
            child_path = f"{path}.{key}"
            yield child_path, key, value
            yield from walk(value, child_path)
    elif isinstance(node, list):
        for index, item in enumerate(node):
            child_path = f"{path}[{index}]"
            yield from walk(item, child_path)


def find_key_occurrences(tree, key):
    occurrences = []
    for path, node_key, value in walk(tree):
        if node_key == key:
            occurrences.append({"path": path, "value": value})
    return occurrences


def count_renderers(tree):
    counter = Counter()
    for _, key, _ in walk(tree):
        if RENDERER_PATTERN.match(key):
            counter[key] += 1
    return counter


def get_by_path(tree, path):
    """Resolve a path like $.a.b[0].c onto the tree."""
    tokens = re.findall(r"\.([A-Za-z0-9_-]+)|\[(\d+)\]", path.lstrip("$"))
    current = tree
    for name, index in tokens:
        try:
            if name:
                current = current[name]
            else:
                current = current[int(index)]
        except (KeyError, IndexError, TypeError):
            return None
    return current


def truncate(value, limit=120):
    text = json.dumps(value, ensure_ascii=False) if isinstance(value, (dict, list)) else str(value)
    if len(text) > limit:
        return text[:limit] + "..."
    return text


def main():
    parser = argparse.ArgumentParser(
        description="ScrapeCraft JSON Explorer: map keys, renderers, and subtrees in unknown JSON payloads."
    )
    source = parser.add_mutually_exclusive_group(required=True)
    source.add_argument("--url", help="Fetch JSON from an HTTP(S) endpoint")
    source.add_argument("--file", help="Read JSON from a local file")
    parser.add_argument("--key", help="Find every occurrence of this key in the tree")
    parser.add_argument("--extract", type=int, metavar="N", help="Print full subtree of the Nth occurrence of --key (1-based)")
    parser.add_argument("--renderers", action="store_true", help="Count all *Renderer structures (Innertube-style payloads)")
    parser.add_argument("--top", type=int, default=20, metavar="N", help="Limit key listing to top N most frequent keys (default: 20)")
    args = parser.parse_args()

    tree = load_json(args)

    if args.key:
        occurrences = find_key_occurrences(tree, args.key)
        print(f"KEY: {args.key}")
        print(f"OCCURRENCES: {len(occurrences)}")
        print("-" * 60)
        for index, occurrence in enumerate(occurrences, start=1):
            print(f"  [{index}] path: {occurrence['path']}")
            print(f"      value: {truncate(occurrence['value'])}")
        if args.extract:
            if 1 <= args.extract <= len(occurrences):
                path = occurrences[args.extract - 1]["path"]
                subtree = get_by_path(tree, path)
                print("-" * 60)
                print(f"SUBTREE AT [{args.extract}] {path}:")
                print(json.dumps(subtree, indent=2, ensure_ascii=False))
            else:
                print(f"ERROR: --extract {args.extract} out of range (1-{len(occurrences)})", file=sys.stderr)
                sys.exit(1)
        return

    if args.renderers:
        counter = count_renderers(tree)
        print("RENDERER STRUCTURES FOUND:")
        print("-" * 60)
        if not counter:
            print("  (none - payload does not use *Renderer structures)")
        for name, count in counter.most_common():
            print(f"  {name}: {count}")
        return

    # Default overview mode: key frequency + structure summary
    key_counter = Counter()
    for _, key, _ in walk(tree):
        key_counter[key] += 1

    print("JSON STRUCTURE OVERVIEW")
    print("-" * 60)
    if isinstance(tree, dict):
        print(f"Root type: object with {len(tree)} top-level keys: {list(tree.keys())[:15]}")
    elif isinstance(tree, list):
        print(f"Root type: array with {len(tree)} items")
    else:
        print(f"Root type: {type(tree).__name__}")

    print(f"\nTOP {args.top} KEYS BY FREQUENCY:")
    for name, count in key_counter.most_common(args.top):
        print(f"  {name}: {count}")

    renderers = count_renderers(tree)
    if renderers:
        print("\nRENDERER STRUCTURES DETECTED (use --renderers for detail):")
        for name, count in renderers.most_common(10):
            print(f"  {name}: {count}")
        print("\nTIP: run again with --renderers, or --key <name> to locate specific data.")


if __name__ == "__main__":
    main()
