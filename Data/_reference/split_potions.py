#!/usr/bin/env python3
"""
Split potions.txt into individual named text files.
Each potion becomes its own file named after the potion name.
"""

import re
import os

def clean_filename(name):
    """Convert potion name to valid filename."""
    # Remove special characters, replace spaces with underscores
    name = re.sub(r'[^\w\s-]', '', name)
    name = name.replace(' ', '_').lower()
    return name + '.txt'

def split_potions():
    input_file = 'Data/_reference/potions/_potions.txt'
    output_dir = 'Data/_reference/potions/'

    # Read the entire file
    with open(input_file, 'r', encoding='utf-8') as f:
        content = f.read()

    # Split by potion entries (each starts with {Name = "...")
    pattern = r'\{Name = "(.*?)",(.*?)\},'

    matches = re.finditer(pattern, content, re.DOTALL)

    count = 0
    for match in matches:
        potion_name = match.group(1)
        potion_data = match.group(0)  # Full match including braces

        filename = clean_filename(potion_name)
        filepath = os.path.join(output_dir, filename)

        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(potion_data)

        count += 1
        print(f"Created: {filename}")

    print(f"\nTotal potions processed: {count}")

if __name__ == '__main__':
    split_potions()
