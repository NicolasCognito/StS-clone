#!/usr/bin/env python3
"""
Check that every file that sets tempContext also clears it.
Enforces the principle: "clear context where it was created, after use"
"""

import os
import re
from collections import defaultdict

def find_lua_files(root_dir):
    """Find all .lua files in the directory tree."""
    lua_files = []
    for dirpath, _, filenames in os.walk(root_dir):
        for filename in filenames:
            if filename.endswith('.lua'):
                lua_files.append(os.path.join(dirpath, filename))
    return lua_files

def analyze_tempcontext_usage(filepath):
    """Find all lines that set or clear tempContext in a file."""
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
        lines = content.split('\n')

    sets = []
    clears = []

    for i, line in enumerate(lines, 1):
        # Look for assignments to tempContext (setting it)
        # Patterns: tempContext = ..., tempContext={...}, etc.
        if re.search(r'\.tempContext\s*=\s*(?!nil)', line):
            sets.append((i, line.strip()))

        # Look for clearing tempContext (setting to nil)
        if re.search(r'\.tempContext\s*=\s*nil', line):
            clears.append((i, line.strip()))

    return sets, clears

def main():
    root_dir = '/home/user/Kill-the-Tower'
    lua_files = find_lua_files(root_dir)

    # Track files that set/clear tempContext
    files_setting = {}
    files_clearing = {}

    for filepath in lua_files:
        sets, clears = analyze_tempcontext_usage(filepath)

        if sets:
            files_setting[filepath] = sets
        if clears:
            files_clearing[filepath] = clears

    print("=" * 80)
    print("TEMPCONTEXT USAGE AUDIT")
    print("=" * 80)

    # Report files that set tempContext
    print("\n📝 Files that SET tempContext:")
    print("-" * 80)
    for filepath, sets in sorted(files_setting.items()):
        rel_path = os.path.relpath(filepath, root_dir)
        print(f"\n{rel_path}")
        for line_num, line in sets:
            print(f"  Line {line_num}: {line[:70]}")

    # Report files that clear tempContext
    print("\n\n🧹 Files that CLEAR tempContext:")
    print("-" * 80)
    for filepath, clears in sorted(files_clearing.items()):
        rel_path = os.path.relpath(filepath, root_dir)
        print(f"\n{rel_path}")
        for line_num, line in clears:
            print(f"  Line {line_num}: {line[:70]}")

    # Check for violations: files that set but don't clear
    print("\n\n⚠️  VIOLATION CHECK:")
    print("-" * 80)
    violations = []
    for filepath in files_setting:
        if filepath not in files_clearing:
            violations.append(filepath)

    if violations:
        print("❌ Files that SET tempContext but DON'T CLEAR it:")
        for filepath in sorted(violations):
            rel_path = os.path.relpath(filepath, root_dir)
            print(f"  - {rel_path}")
            sets, _ = analyze_tempcontext_usage(filepath)
            for line_num, line in sets:
                print(f"      Line {line_num}: {line[:70]}")
    else:
        print("✅ All files that set tempContext also clear it!")

    # Summary
    print("\n\n📊 SUMMARY:")
    print("-" * 80)
    print(f"Files that set tempContext:   {len(files_setting)}")
    print(f"Files that clear tempContext: {len(files_clearing)}")
    print(f"Violations (set but no clear): {len(violations)}")

    if violations:
        print("\n⚠️  ACTION REQUIRED: Fix violations above")
        return 1
    else:
        print("\n✅ PASS: All tempContext usage follows the cleanup principle")
        return 0

if __name__ == '__main__':
    exit(main())
