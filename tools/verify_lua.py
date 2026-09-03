import re
import sys

def check_file(path):
    with open(path, 'r', encoding='utf-8') as f:
        text = f.read()

    clean = re.sub(r'--\[\[.*?\]\]', '', text, flags=re.DOTALL)
    clean = re.sub(r'--[^\n]*', '', clean)
    clean = re.sub(r'"(\\.|[^"])*"', '""', clean)
    clean = re.sub(r"'(\\.|[^'])*'", "''", clean)

    tokens = re.findall(r'\b(if|then|elseif|else|end|function|for|while|do|repeat|until)\b', clean)

    stack = []
    for t in tokens:
        if t in ('function', 'for', 'while', 'if'):
            stack.append(t)
        elif t == 'repeat':
            stack.append('repeat')
        elif t == 'until':
            if stack and stack[-1] == 'repeat':
                stack.pop()
            else:
                print(f'{path}: Unmatched until')
        elif t == 'end':
            if not stack:
                print(f'{path}: Extra end found!')
            else:
                stack.pop()

    if stack:
        print(f'{path}: Unclosed blocks:', stack)
    else:
        print(f'{path}: SUCCESS - Perfectly balanced!')

if __name__ == '__main__':
    import glob
    raw_args = sys.argv[1:] if len(sys.argv) > 1 else [r'SCRIPTS\TOOLS\BadApple.lua']
    files = []
    for arg in raw_args:
        matched = glob.glob(arg)
        if matched:
            files.extend(matched)
        else:
            files.append(arg)
    for p in files:
        check_file(p)
