#!/usr/bin/env python3
"""
Find implemented items that don't have matching reference files.
"""

import os
import re

def normalize_name(name):
    """Normalize name by removing all non-alphanumeric chars and lowercasing."""
    name = os.path.splitext(name)[0]
    name = re.sub(r'[^a-zA-Z0-9]', '', name)
    return name.lower()

def find_unmatched(data_dir, ref_dir_impl, ref_dir_not_impl):
    """Find implemented files without matching reference files."""

    # Get all implemented .lua files
    implemented = {}
    for filename in os.listdir(data_dir):
        if filename.endswith('.lua'):
            normalized = normalize_name(filename)
            implemented[normalized] = filename

    # Get all reference files (both implemented and not implemented)
    reference = set()
    for filename in os.listdir(ref_dir_impl):
        if filename.endswith('.txt'):
            normalized = normalize_name(filename)
            reference.add(normalized)

    for filename in os.listdir(ref_dir_not_impl):
        if filename.endswith('.txt'):
            normalized = normalize_name(filename)
            reference.add(normalized)

    # Find missing
    unmatched = []
    for norm_name, orig_file in implemented.items():
        if norm_name not in reference:
            unmatched.append(orig_file)

    return unmatched

# Check cards
print("=" * 60)
print("CARDS - Implemented but no reference file:")
print("=" * 60)
missing_cards = find_unmatched(
    'Data/Cards',
    'Data/_reference/cards/already_implemented',
    'Data/_reference/cards/not_implemented'
)
for card in sorted(missing_cards):
    print(f"  {card}")
print(f"\nTotal: {len(missing_cards)}")

# Check relics
print("\n" + "=" * 60)
print("RELICS - Implemented but no reference file:")
print("=" * 60)
missing_relics = find_unmatched(
    'Data/Relics',
    'Data/_reference/relics/already_implemented',
    'Data/_reference/relics/not_implemented'
)
for relic in sorted(missing_relics):
    print(f"  {relic}")
print(f"\nTotal: {len(missing_relics)}")

# Check potions
print("\n" + "=" * 60)
print("POTIONS - Implemented but no reference file:")
print("=" * 60)
missing_potions = find_unmatched(
    'Data/Potions',
    'Data/_reference/potions/already_implemented',
    'Data/_reference/potions/not_implemented'
)
for potion in sorted(missing_potions):
    print(f"  {potion}")
print(f"\nTotal: {len(missing_potions)}")
