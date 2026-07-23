"""Validate one JSON instance against a Draft 2020-12 schema.

Exit 0 means valid, exit 2 means the instance is invalid, and exit 3 means the validator could not
run or the schema itself is invalid. PowerShell 7.4+ uses Test-Json instead; this is the fail-closed
Windows PowerShell 5.1 fallback for development environments with jsonschema installed.
"""

from __future__ import annotations

import json
import sys
from pathlib import Path


def main() -> int:
    if len(sys.argv) != 3:
        print("usage: Validate-JsonSchema.py SCHEMA INSTANCE", file=sys.stderr)
        return 3

    try:
        from jsonschema import Draft202012Validator, FormatChecker

        schema = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8-sig"))
        instance = json.loads(Path(sys.argv[2]).read_text(encoding="utf-8-sig"))
        Draft202012Validator.check_schema(schema)
        errors = sorted(
            Draft202012Validator(schema, format_checker=FormatChecker()).iter_errors(instance),
            key=lambda error: [str(part) for part in error.absolute_path],
        )
    except Exception as error:  # dependency/schema/parser failures are infrastructure failures
        print(f"schema validation could not run: {error}", file=sys.stderr)
        return 3

    if errors:
        for error in errors[:20]:
            location = "/".join(str(part) for part in error.absolute_path) or "<root>"
            print(f"{location}: {error.message}")
        return 2

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
