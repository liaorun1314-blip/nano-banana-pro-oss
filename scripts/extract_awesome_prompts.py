#!/usr/bin/env python3
"""Extract prompt blocks from markdown files into JSON.

Designed for prompt-collection style markdown files where entries typically look like:

### 1.2. Prompt Title
...
**Prompt:**
```text
...
```
*Source: ...*
"""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path


def slugify(text: str) -> str:
    lower = text.lower()
    lower = re.sub(r"[^a-z0-9]+", "-", lower)
    return lower.strip("-")[:60] or "prompt"


def extract_prompts(markdown: str) -> list[dict[str, str]]:
    lines = markdown.splitlines()
    results: list[dict[str, str]] = []

    current_category = "General"
    current_title = ""
    waiting_for_prompt_block = False
    in_code_block = False
    code_lines: list[str] = []
    source = "Unknown"
    pending_source_index: int | None = None

    for line in lines:
        h2_match = re.match(r"^##\s+\d+\.\s+(.+)$", line)
        if h2_match:
            current_category = h2_match.group(1).strip()
            continue

        h3_match = re.match(r"^###\s+\d+\.\d+\.\s+(.+)$", line)
        if h3_match:
            current_title = h3_match.group(1).strip()
            waiting_for_prompt_block = False
            in_code_block = False
            code_lines = []
            source = "Unknown"
            pending_source_index = None
            continue

        if line.strip().lower() == "**prompt:**":
            waiting_for_prompt_block = True
            continue

        if waiting_for_prompt_block and line.strip().startswith("```"):
            in_code_block = True
            waiting_for_prompt_block = False
            code_lines = []
            continue

        if in_code_block and line.strip().startswith("```"):
            in_code_block = False
            prompt_text = "\n".join(code_lines).strip()
            if current_title and prompt_text:
                prompt_id = f"{slugify(current_title)}-{len(results) + 1:03d}"
                results.append(
                    {
                        "id": prompt_id,
                        "title": current_title,
                        "category": current_category,
                        "source": source,
                        "prompt": prompt_text,
                    }
                )
                pending_source_index = len(results) - 1
            continue

        if in_code_block:
            code_lines.append(line)
            continue

        source_match = re.match(r"^\*Source:\s*(.+)\*$", line.strip())
        if source_match:
            source = source_match.group(1).strip()
            if pending_source_index is not None:
                results[pending_source_index]["source"] = source
                pending_source_index = None

    return results


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Extract prompt blocks from markdown")
    parser.add_argument("--input", required=True, help="Input markdown file path")
    parser.add_argument("--output", required=True, help="Output JSON file path")
    parser.add_argument("--limit", type=int, default=0, help="Optional max record count")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    input_path = Path(args.input).expanduser().resolve()
    output_path = Path(args.output).expanduser().resolve()

    if not input_path.is_file():
        raise FileNotFoundError(f"Input markdown file not found: {input_path}")

    markdown = input_path.read_text(encoding="utf-8")
    prompts = extract_prompts(markdown)

    if args.limit and args.limit > 0:
        prompts = prompts[: args.limit]

    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(json.dumps(prompts, indent=2, ensure_ascii=False), encoding="utf-8")

    print(f"Extracted {len(prompts)} prompts")
    print(f"Saved to: {output_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
