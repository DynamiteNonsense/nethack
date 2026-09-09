#!/usr/bin/env python3
"""Regenerate an ASCII-only C header from the UTF-8 translation catalog."""
from pathlib import Path
import json
ROOT = Path(__file__).resolve().parent.parent

def literal(text):
    out = '"'
    for byte in text.encode('utf-8'):
        if byte == 34: out += '\\"'
        elif byte == 92: out += '\\\\'
        elif 32 <= byte < 127: out += chr(byte)
        else: out += '\\%03o' % byte
    return out + '"'

def main():
    rows = json.loads((ROOT/'ru-project/messages.ru.json').read_text(encoding='utf-8'))
    seen = set()
    lines = []
    for row in rows:
        en, ru = row['en'], row['ru']
        assert en and en not in seen, en
        seen.add(en)
        assert all(32 <= ord(c) < 127 for c in en), en
        assert len(en.encode('ascii')) < 256, en
        assert ru and all(32 <= ord(c) < 127 or 'А' <= c <= 'я' or c in 'Ёё' for c in ru), ru
        assert chr(0x2014) not in ru, ru
        assert len((ru+' ('+en+')').encode('utf-8')) < 10000
        lines.append('    { %s, %s },' % (literal(en),literal(ru+' ('+en+')')))
    h = ROOT/'win/tty/nhr_messages.h'
    text = h.read_text(encoding='ascii')
    start = '/* NHR_CATALOG_BEGIN */\n'
    end = '/* NHR_CATALOG_END */'
    left, rest = text.split(start,1)
    _, right = rest.split(end,1)
    h.write_text(left+start+'\n'.join(lines)+'\n'+end+right,encoding='ascii')
    print('Generated %d messages.' % len(rows))
if __name__ == '__main__': main()
