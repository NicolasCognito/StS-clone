#!/usr/bin/env python3
"""
Extract card/relic names and effects into a readable summary format.
"""

import os
import re

def extract_card_info(filepath):
    """Extract Name and Text from card reference file."""
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # Extract Name
    name_match = re.search(r'Name = "(.*?)"', content)
    name = name_match.group(1) if name_match else "Unknown"

    # Extract Text (description)
    text_match = re.search(r'Text = "(.*?)"', content, re.DOTALL)
    text = text_match.group(1) if text_match else "No description"

    # Clean up text - remove newlines for readability
    text = text.replace('\n', ' ')

    return name, text

def extract_relic_info(filepath):
    """Extract Name and Description from relic reference file."""
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # Extract Name
    name_match = re.search(r'Name = "(.*?)"', content)
    name = name_match.group(1) if name_match else "Unknown"

    # Extract Description
    desc_match = re.search(r'Description = "(.*?)"', content, re.DOTALL)
    desc = desc_match.group(1) if desc_match else "No description"

    # Clean up description
    desc = desc.replace('\n', ' ')

    return name, desc

def generate_cards_summary(input_dir, output_file):
    """Generate summary of all cards in directory."""
    cards = []

    for filename in sorted(os.listdir(input_dir)):
        if filename.endswith('.txt'):
            filepath = os.path.join(input_dir, filename)
            name, text = extract_card_info(filepath)
            cards.append((name, text))

    with open(output_file, 'w', encoding='utf-8') as f:
        f.write("=" * 80 + "\n")
        f.write("CARDS SUMMARY - Name and Effect Only\n")
        f.write("=" * 80 + "\n\n")

        for name, text in cards:
            f.write(f"{name}\n")
            f.write(f"  {text}\n\n")

        f.write(f"\nTotal cards: {len(cards)}\n")

    print(f"Generated {output_file} with {len(cards)} cards")

def generate_relics_summary(input_dir, output_file):
    """Generate summary of all relics in directory."""
    relics = []

    for filename in sorted(os.listdir(input_dir)):
        if filename.endswith('.txt'):
            filepath = os.path.join(input_dir, filename)
            name, desc = extract_relic_info(filepath)
            relics.append((name, desc))

    with open(output_file, 'w', encoding='utf-8') as f:
        f.write("=" * 80 + "\n")
        f.write("RELICS SUMMARY - Name and Description Only\n")
        f.write("=" * 80 + "\n\n")

        for name, desc in relics:
            f.write(f"{name}\n")
            f.write(f"  {desc}\n\n")

        f.write(f"\nTotal relics: {len(relics)}\n")

    print(f"Generated {output_file} with {len(relics)} relics")

if __name__ == '__main__':
    # Generate cards summary
    generate_cards_summary(
        'Data/_reference/cards/not_implemented',
        'Data/_reference/cards/not_implemented/_SUMMARY.txt'
    )

    # Generate relics summary
    generate_relics_summary(
        'Data/_reference/relics/not_implemented',
        'Data/_reference/relics/not_implemented/_SUMMARY.txt'
    )

    print("\nSummary files created successfully!")
