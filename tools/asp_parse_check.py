#!/usr/bin/env python3
"""
asp_parse_check.py - Classic ASP parse-time sanity checker.

The IIS ASP scanner is DELIMITER-BASED and NOT string-aware:
  - outside script blocks, "<%" opens a block
  - inside a block, "%>" closes it, and "<%" closes the current block
    and immediately opens a new one
  - the scanner does NOT understand VBScript string literals, so a "<%"
    or "%>" occurring inside a string (or inside a comment) splits the
    statement mid-token. When the split leaves a string quote open, the
    page fails with VBScript compilation error 800a0409
    ("Out of string space" / unterminated string constant).

This tool emulates that tokenizer, then runs a VBScript string/comment
aware quote-balance check on every resulting code chunk, reporting the
exact source file and line of any violation.
"""
import os
import re
import sys

INCLUDE_RE = re.compile(r'<!--\s*#INCLUDE\s+(FILE|VIRTUAL)="([^"]+)"\s*-->\s*')
APP_VIRTUAL_ROOT = '/webapppolimusicv1_asp'

# Project root: the directory containing this tools/ folder's parent.
_PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def _resolve_include(kind, target, containing_file):
    """Resolve an #INCLUDE target to an absolute filesystem path.
    FILE    -> relative to the directory of the file that contains it.
    VIRTUAL -> absolute from the application virtual root."""
    if kind == 'VIRTUAL':
        t = target
        if t.lower().startswith(APP_VIRTUAL_ROOT.lower()):
            t = t[len(APP_VIRTUAL_ROOT):]
        return os.path.normpath(os.path.join(_PROJECT_ROOT, t.lstrip('/\\')))
    return os.path.normpath(os.path.join(os.path.dirname(containing_file), target))


def load_page(path, stack=()):
    """Expand #INCLUDE directives -> list of (srcfile, srclineno, text)."""
    if path in stack:
        raise RuntimeError("CIRCULAR INCLUDE: %s -> %s" % (" -> ".join(s for s in stack), path))
    out = []
    with open(path, 'r', encoding='utf-8-sig', errors='replace', newline='') as f:
        content = f.read()
    for idx, raw in enumerate(content.split('\n'), 1):
        m = INCLUDE_RE.search(raw)
        if m:
            kind, target = m.group(1), m.group(2)
            inc = _resolve_include(kind, target, path)
            if not os.path.exists(inc):
                out.append((path, idx, raw + "  [MISSING INCLUDE TARGET: %s]" % inc))
                continue
            out.extend(load_page(inc, stack + (path,)))
        else:
            out.append((path, idx, raw))
    return out


def tokenize_iis(lines):
    """Split the merged page the way IIS does. Returns list of
    (kind, chunk_text, start_line_index) with kind in {'html','code'}."""
    text = ''.join(l[2] + '\n' for l in lines)
    line_start = []
    acc = 0
    for l in lines:
        line_start.append(acc)
        acc += len(l[2]) + 1

    def line_of(offset):
        lo, hi = 0, len(line_start) - 1
        while lo < hi:
            mid = (lo + hi + 1) // 2
            if line_start[mid] <= offset:
                lo = mid
            else:
                hi = mid - 1
        return lo

    chunks = []
    i, n = 0, len(text)
    state = 'html'
    chunk_start = 0
    while i < n:
        if state == 'html':
            j = text.find('<%', i)
            if j == -1:
                if chunk_start < n:
                    chunks.append(('html', text[chunk_start:n], line_of(chunk_start)))
                break
            if j > chunk_start:
                chunks.append(('html', text[chunk_start:j], line_of(chunk_start)))
            chunk_start = j + 2
            state = 'code'
            i = j + 2
        else:
            j = text.find('%>', i)
            k = text.find('<%', i)
            if j == -1 and k == -1:
                chunks.append(('code', text[chunk_start:n], line_of(chunk_start)))
                break
            if k != -1 and (j == -1 or k < j):
                if k > chunk_start:
                    chunks.append(('code', text[chunk_start:k], line_of(chunk_start)))
                chunk_start = k + 2
                i = k + 2
            else:
                chunks.append(('code', text[chunk_start:j], line_of(chunk_start)))
                chunk_start = j + 2
                state = 'html'
                i = j + 2
    return chunks


def check_chunk_quotes(chunk_text, lines, start_line):
    """Return list of (line_index, message) for unterminated strings.
    Stops at the first violation (that is where the compiler would fail)."""
    issues = []
    in_string = False
    for off, line in enumerate(chunk_text.split('\n')):
        li = start_line + off
        src = lines[li][2] if 0 <= li < len(lines) else ''
        k = 0
        while k < len(line):
            c = line[k]
            if in_string:
                if c == '"':
                    if k + 1 < len(line) and line[k + 1] == '"':
                        k += 2
                        continue
                    in_string = False
                k += 1
                continue
            else:
                if c == '"':
                    in_string = True
                    k += 1
                    continue
                if c == "'":
                    break  # comment runs to end of line
                k += 1
        if in_string:
            snippet = src.strip()[:90]
            issues.append((li, 'unterminated string at end of line (a delimiter sequence inside a string split the statement): "' + snippet + '"'))
            break
    return issues


def check_page(path):
    lines = load_page(path)
    chunks = tokenize_iis(lines)
    issues = []
    seen = set()
    # Check 1: parent-path includes (IIS "ASP 0131 - Parent Paths Not Enabled").
    for srcfile, srcline, srctext in lines:
        m = INCLUDE_RE.search(srctext)
        if m and m.group(1) == 'FILE' and '..' in m.group(2):
            entry = '  %s:%d: #INCLUDE FILE with ".." requires AspEnableParentPaths=True (off by default). Use #INCLUDE VIRTUAL instead.' % (srcfile, srcline)
            if entry not in seen:
                seen.add(entry)
                issues.append(entry)
    # Check 2: unterminated strings caused by delimiter-in-code.
    for kind, text, start in chunks:
        if kind != 'code':
            continue
        if text.lstrip().startswith('@'):
            continue  # compiler directive such as <%@ Language=VBScript %>
        for li, msg in check_chunk_quotes(text, lines, start):
            srcfile, srcline, srctext = lines[li]
            entry = '  %s:%d: %s' % (srcfile, srcline, msg)
            if entry not in seen:
                seen.add(entry)
                issues.append(entry)
    # also flag unterminated script blocks (missing %>)
    tail = chunks[-1]
    if tail[0] == 'code' and not ''.join(l[2] + '\n' for l in lines).endswith('%>\n'):
        issues.append('  ' + path + ': code chunk reaches end of file without a closing delimiter')
    return issues


def main():
    pages = sys.argv[1:]
    if not pages:
        print("usage: asp_parse_check.py <page.asp> [page.asp ...]")
        return 2
    failed = 0
    for p in pages:
        issues = check_page(os.path.abspath(p))
        if issues:
            failed += 1
            print('[FAIL] %s' % p)
            print('\n'.join(issues))
        else:
            print('[ OK ] %s parses cleanly' % p)
    return 1 if failed else 0


if __name__ == '__main__':
    sys.exit(main())
