#!/usr/bin/env python3
"""
Normalize LaTeX files before latexdiff to improve diff quality
- Remove leading spaces in abstract
- Normalize paragraph breaks
"""
import sys
import re

def normalize_abstract(content):
    """Normalize abstract environment for better diffing"""
    # Find abstract
    abstract_match = re.search(
        r'(\\begin\{abstract\})(.*?)(\\end\{abstract\})',
        content,
        re.DOTALL
    )

    if not abstract_match:
        return content

    before = content[:abstract_match.start()]
    abstract_content = abstract_match.group(2)
    after = content[abstract_match.end():]

    # Normalize abstract content:
    # 1. Remove leading/trailing whitespace from each line
    lines = [line.strip() for line in abstract_content.split('\n')]

    # 2. Remove empty lines at start/end
    while lines and not lines[0]:
        lines.pop(0)
    while lines and not lines[-1]:
        lines.pop()

    # 3. Join into paragraphs (preserve paragraph breaks)
    paragraphs = []
    current_para = []

    for line in lines:
        if not line:  # Empty line = paragraph break
            if current_para:
                paragraphs.append(' '.join(current_para))
                current_para = []
        else:
            current_para.append(line)

    if current_para:
        paragraphs.append(' '.join(current_para))

    # 4. Split into sentences for better diff granularity
    # Split on '. ' but be careful with abbreviations
    sentences = []
    for para in paragraphs:
        # Simple sentence splitting - split on '. ' followed by capital letter or number
        para_sentences = re.split(r'\.\s+(?=[A-Z0-9])', para)
        # Add periods back except for the last one (which should already have it)
        for i, sent in enumerate(para_sentences[:-1]):
            sentences.append(sent + '.')
        if para_sentences:
            sentences.append(para_sentences[-1])

    # 5. Reconstruct with consistent formatting (one sentence per line)
    normalized_abstract = '\n\n' + '\n'.join(sentences) + '\n\n'

    return before + '\\begin{abstract}' + normalized_abstract + '\\end{abstract}' + after

def main():
    if len(sys.argv) != 3:
        print("Usage: normalize_tex.py <input_file> <output_file>")
        sys.exit(1)

    input_file = sys.argv[1]
    output_file = sys.argv[2]

    with open(input_file, 'r', encoding='utf-8') as f:
        content = f.read()

    # Normalize abstract
    content = normalize_abstract(content)

    with open(output_file, 'w', encoding='utf-8') as f:
        f.write(content)

    print(f"Normalized {input_file} -> {output_file}")

if __name__ == '__main__':
    main()
