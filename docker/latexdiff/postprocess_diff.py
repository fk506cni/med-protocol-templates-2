#!/usr/bin/env python3
"""
Post-process latexdiff output to enable highlighting for title and abstract changes
"""
import sys
import re
import difflib

def replace_title(match):
    """Replace title with highlighted differences"""
    old_title = match.group(1)
    new_title = match.group(2)

    # Find differences word by word
    old_words = old_title.split()
    new_words = new_title.split()

    # Simple diff: mark changed words
    result = []
    for old, new in zip(old_words, new_words):
        if old != new:
            result.append(f'\\DIFdel{{{old}}} \\DIFadd{{{new}}}')
        else:
            result.append(new)

    # Handle length differences
    if len(old_words) > len(new_words):
        for word in old_words[len(new_words):]:
            result.append(f'\\DIFdel{{{word}}}')
    elif len(new_words) > len(old_words):
        for word in new_words[len(old_words):]:
            result.append(f'\\DIFadd{{{word}}}')

    return f'\\title{{{" ".join(result)}}}'

def word_level_diff(old_text, new_text):
    """Generate word-level diff between two texts"""
    old_words = old_text.split()
    new_words = new_text.split()

    # Use difflib to find differences
    matcher = difflib.SequenceMatcher(None, old_words, new_words)
    result = []

    for tag, i1, i2, j1, j2 in matcher.get_opcodes():
        if tag == 'equal':
            result.extend(new_words[j1:j2])
        elif tag == 'replace':
            # Words were changed
            if old_words[i1:i2]:
                result.append(f'\\DIFdel{{{" ".join(old_words[i1:i2])}}}')
            if new_words[j1:j2]:
                result.append(f'\\DIFadd{{{" ".join(new_words[j1:j2])}}}')
        elif tag == 'delete':
            result.append(f'\\DIFdel{{{" ".join(old_words[i1:i2])}}}')
        elif tag == 'insert':
            result.append(f'\\DIFadd{{{" ".join(new_words[j1:j2])}}}')

    return ' '.join(result)

def process_abstract_diff(content):
    """Convert sentence-level diffs to word-level diffs in abstract"""
    # Find abstract environment
    abstract_start = content.find(r'\begin{abstract}')
    abstract_end = content.find(r'\end{abstract}', abstract_start)

    if abstract_start == -1 or abstract_end == -1:
        return content

    abstract_section = content[abstract_start:abstract_end]

    lines = abstract_section.split('\n')
    new_lines = []
    deleted_sentences = []
    new_sentences = []
    in_diff_block = False

    for line in lines:
        line_stripped = line.strip()

        # Collect %DIF < sentences (deleted)
        if line_stripped.startswith('%DIF <'):
            deleted_text = line_stripped.replace('%DIF <', '').strip()
            if deleted_text:
                deleted_sentences.append(deleted_text)
                in_diff_block = True
            continue

        # Skip %DIF ------- separator
        elif line_stripped.startswith('%DIF -------'):
            continue

        # Collect new sentences (ones with %DIF > marker)
        elif line_stripped.endswith('%DIF >'):
            new_text = line_stripped.replace('%DIF >', '').strip()
            # Remove trailing \par if present
            new_text = re.sub(r'\\par\s*$', '', new_text)
            if new_text:
                new_sentences.append(new_text)
            continue

        # Also collect sentences with \DIFdelbegin format
        elif line_stripped.startswith('\\DIFdelbegin \\DIFdel{'):
            match = re.search(r'\\DIFdel\{(.+?)\}', line_stripped)
            if match:
                deleted_sentences.append(match.group(1))
                in_diff_block = True
            continue

        # When we hit a non-diff line or empty line, process collected sentences
        elif not line_stripped or (not line_stripped.startswith('%DIF') and not line_stripped.startswith('\\DIF')):
            if deleted_sentences or new_sentences:
                # Match sentences and create word-level diff
                max_len = max(len(deleted_sentences), len(new_sentences))
                for i in range(max_len):
                    if i < len(deleted_sentences) and i < len(new_sentences):
                        # Both old and new exist - create word-level diff
                        diff_result = word_level_diff(deleted_sentences[i], new_sentences[i])
                        new_lines.append(diff_result)
                    elif i < len(deleted_sentences):
                        # Only old exists - pure deletion
                        new_lines.append(f'\\DIFdel{{{deleted_sentences[i]}}}')
                    else:
                        # Only new exists - pure addition
                        new_lines.append(f'\\DIFadd{{{new_sentences[i]}}}')

                deleted_sentences = []
                new_sentences = []
                in_diff_block = False

            if line_stripped:
                new_lines.append(line)
        else:
            # Other DIF markers, skip
            continue

    # Process any remaining collected sentences at the end
    if deleted_sentences or new_sentences:
        max_len = max(len(deleted_sentences), len(new_sentences))
        for i in range(max_len):
            if i < len(deleted_sentences) and i < len(new_sentences):
                diff_result = word_level_diff(deleted_sentences[i], new_sentences[i])
                new_lines.append(diff_result)
            elif i < len(deleted_sentences):
                new_lines.append(f'\\DIFdel{{{deleted_sentences[i]}}}')
            else:
                new_lines.append(f'\\DIFadd{{{new_sentences[i]}}}')

    new_abstract = '\n'.join(new_lines)
    return content[:abstract_start] + new_abstract + content[abstract_end:]

def make_markup_cjk_safe(content):
    """Replace ulem-based diff markup with colour-only markup.

    latexdiff の既定（UNDERLINE タイプ）は \\DIFadd に ulem の \\uwave、
    \\DIFdel に \\sout を用いる。ulem は空白位置でしか行分割できないため、
    分かち書きをしない和文では変更箇所が 1 つの分割不能な塊となり、
    長い変更が版面の右端からはみ出して「見切れる」。
    和文でも正しく折り返すよう、取り消し線・波下線を外して色のみで標示する。
    （青字＝追加、赤字＝削除）
    """
    replacements = [
        (r'\providecommand{\DIFadd}[1]{{\protect\color{blue}\uwave{#1}}}',
         r'\providecommand{\DIFadd}[1]{{\protect\color{blue}#1}}'),
        (r'\providecommand{\DIFdel}[1]{{\protect\color{red}\sout{#1}}}',
         r'\providecommand{\DIFdel}[1]{{\protect\color{red}#1}}'),
        # listings 環境内の差分標示も同様に色のみとする
        (r'moredelim=[il][\color{red}\sout]',
         r'moredelim=[il][\color{red}]'),
        (r'moredelim=[il][\color{blue}\uwave]',
         r'moredelim=[il][\color{blue}]'),
    ]

    for old, new in replacements:
        content = content.replace(old, new)

    return content

def main():
    if len(sys.argv) != 2:
        print("Usage: postprocess_diff.py <diff_file>")
        sys.exit(1)

    diff_file = sys.argv[1]

    with open(diff_file, 'r', encoding='utf-8') as f:
        content = f.read()

    # Process title changes
    title_pattern = r'%DIF < \\title\{([^}]+)\}\s*%DIF -------\s*\\title\{([^}]+)\}'
    content = re.sub(title_pattern, replace_title, content, flags=re.DOTALL)

    # Process abstract
    content = process_abstract_diff(content)

    # 和文が折り返せるよう ulem ベースの標示を色のみの標示に置き換える
    content = make_markup_cjk_safe(content)

    with open(diff_file, 'w', encoding='utf-8') as f:
        f.write(content)

    print(f"Post-processed {diff_file}: enabled highlighting for title and abstract")
    print("  差分標示: 青字＝追加、赤字＝削除（和文の行分割のため取り消し線・下線は使用しません）")

if __name__ == '__main__':
    main()
