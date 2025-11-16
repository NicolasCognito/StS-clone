#!/usr/bin/env python3
"""
Sort reference files into already_implemented or not_implemented subfolders.
Matches reference files against implemented files by converting names to the same format.
"""

import os
import shutil
import re

def normalize_name(name):
    """
    Convert a name to the format used in Data/Cards, Data/Relics, Data/Potions.
    - Remove all spaces, underscores, hyphens, special characters
    - Convert to lowercase
    """
    # Remove extension if present
    name = os.path.splitext(name)[0]
    # Remove all non-alphanumeric characters
    name = re.sub(r'[^a-zA-Z0-9]', '', name)
    # Convert to lowercase
    return name.lower()

def get_implemented_items(data_dir):
    """Get set of normalized names of implemented items."""
    if not os.path.exists(data_dir):
        return set()

    implemented = set()
    for filename in os.listdir(data_dir):
        if filename.endswith('.lua'):
            normalized = normalize_name(filename)
            implemented.add(normalized)

    return implemented

def sort_reference_files(ref_type, ref_dir, data_dir):
    """
    Sort reference files into subfolders based on implementation status.

    Args:
        ref_type: 'cards', 'potions', or 'relics'
        ref_dir: Directory containing reference .txt files
        data_dir: Directory containing implemented .lua files
    """
    print(f"\n{'='*60}")
    print(f"Sorting {ref_type.upper()}")
    print(f"{'='*60}")

    # Get implemented items
    implemented_set = get_implemented_items(data_dir)
    print(f"Found {len(implemented_set)} implemented {ref_type}")

    # Create subdirectories
    already_impl_dir = os.path.join(ref_dir, 'already_implemented')
    not_impl_dir = os.path.join(ref_dir, 'not_implemented')
    os.makedirs(already_impl_dir, exist_ok=True)
    os.makedirs(not_impl_dir, exist_ok=True)

    # Process reference files
    moved_to_implemented = 0
    moved_to_not_implemented = 0

    for filename in os.listdir(ref_dir):
        # Skip if not a .txt file or if it's a special file
        if not filename.endswith('.txt') or filename.startswith('_'):
            continue

        # Skip if already in a subdirectory
        filepath = os.path.join(ref_dir, filename)
        if not os.path.isfile(filepath):
            continue

        # Normalize the reference filename
        normalized = normalize_name(filename)

        # Determine destination
        if normalized in implemented_set:
            dest_dir = already_impl_dir
            moved_to_implemented += 1
            status = "✓"
        else:
            dest_dir = not_impl_dir
            moved_to_not_implemented += 1
            status = "✗"

        # Move file
        dest_path = os.path.join(dest_dir, filename)
        shutil.move(filepath, dest_path)
        print(f"{status} {filename} -> {os.path.basename(dest_dir)}/")

    print(f"\nSummary for {ref_type}:")
    print(f"  Already implemented: {moved_to_implemented}")
    print(f"  Not implemented: {moved_to_not_implemented}")
    print(f"  Total processed: {moved_to_implemented + moved_to_not_implemented}")

def main():
    # Sort cards
    sort_reference_files(
        ref_type='cards',
        ref_dir='Data/_reference/cards',
        data_dir='Data/Cards'
    )

    # Sort relics
    sort_reference_files(
        ref_type='relics',
        ref_dir='Data/_reference/relics',
        data_dir='Data/Relics'
    )

    # Sort potions
    sort_reference_files(
        ref_type='potions',
        ref_dir='Data/_reference/potions',
        data_dir='Data/Potions'
    )

    print(f"\n{'='*60}")
    print("SORTING COMPLETE!")
    print(f"{'='*60}")

if __name__ == '__main__':
    main()
