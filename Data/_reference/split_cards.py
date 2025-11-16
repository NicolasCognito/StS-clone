#!/usr/bin/env python3
"""
Split cards.txt into individual named text files.
Each card becomes its own file named after the card name.
"""

import re
import os

def clean_filename(name):
    """Convert card name to valid filename."""
    # Remove special characters, replace spaces with underscores
    name = re.sub(r'[^\w\s-]', '', name)
    name = name.replace(' ', '_').lower()
    return name + '.txt'

def split_cards():
    input_file = 'Data/_reference/cards/_cards.txt'
    output_dir = 'Data/_reference/cards/'

    # Read the entire file
    with open(input_file, 'r', encoding='utf-8') as f:
        content = f.read()

    # Split by card entries (each starts with {Name = "...")
    # Pattern: find entries between { and },
    pattern = r'\{Name = "(.*?)",(.*?)\},'

    matches = re.finditer(pattern, content, re.DOTALL)

    count = 0
    for match in matches:
        card_name = match.group(1)
        card_data = match.group(0)  # Full match including braces

        filename = clean_filename(card_name)
        filepath = os.path.join(output_dir, filename)

        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(card_data)

        count += 1
        print(f"Created: {filename}")

    print(f"\nTotal cards processed: {count}")

if __name__ == '__main__':
    split_cards()
