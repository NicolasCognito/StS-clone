#!/usr/bin/env python3
"""
Split relics.txt into individual named text files.
Each relic becomes its own file named after the relic name.
"""

import re
import os

def clean_filename(name):
    """Convert relic name to valid filename."""
    # Remove special characters, replace spaces with underscores
    name = re.sub(r'[^\w\s-]', '', name)
    name = name.replace(' ', '_').lower()
    return name + '.txt'

def split_relics():
    input_file = 'Data/_reference/relics/_relics.txt'
    output_dir = 'Data/_reference/relics/'

    # Read the entire file
    with open(input_file, 'r', encoding='utf-8') as f:
        content = f.read()

    # Split by relic entries (each starts with {Name = "...")
    pattern = r'\{Name = "(.*?)",(.*?)\},'

    matches = re.finditer(pattern, content, re.DOTALL)

    count = 0
    for match in matches:
        relic_name = match.group(1)
        relic_data = match.group(0)  # Full match including braces

        filename = clean_filename(relic_name)
        filepath = os.path.join(output_dir, filename)

        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(relic_data)

        count += 1
        print(f"Created: {filename}")

    print(f"\nTotal relics processed: {count}")

if __name__ == '__main__':
    split_relics()
