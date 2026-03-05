"""
Verification script for chinitsu_trainer_v2.html
"""
import sys
import re
from pathlib import Path

sys.stdout.reconfigure(encoding='utf-8')

html_path = Path('C:/Users/haman/Downloads/チンイツ/chinitsu_trainer_v2.html')
html = html_path.read_text(encoding='utf-8')

passed = 0
failed = 0
total = 0


def check(label, condition, detail=''):
    global passed, failed, total
    total += 1
    if condition:
        passed += 1
        status = 'PASS'
    else:
        failed += 1
        status = 'FAIL'
    msg = f'[{status}] {label}'
    if detail:
        msg += f'  -- {detail}'
    print(msg)


def extract_function_body(func_name, source):
    pat = r'function\s+' + re.escape(func_name) + r'\s*\([^)]*\)\s*\{'
    m = re.search(pat, source)
    if not m:
        return None
    brace_count = 0
    body_start = source.index('{', m.start())
    idx = body_start
    while idx < len(source):
        if source[idx] == '{':
            brace_count += 1
        elif source[idx] == '}':
            brace_count -= 1
            if brace_count == 0:
                break
        idx += 1
    return source[body_start:idx + 1]


print('======================================================================')
print('1. Required JS functions')
print('======================================================================')

required_functions = [
    'generateCompleteHand',
    'generateTenpaiHand',
    'generateRandomHand',
    'generateProblem',
    'toggleNotTenpai',
    'decomposeHand',
    'findAllDecompositions',
    'toggleFavorite',
    'updateFavBtn',
    'startFiltered',
    'toggleDecomp',
    'showDecomposition',
    'tileKey',
    'loadSet',
    'saveSet',
    'updateFilterUI',
    'renderDecomposition',
    'createGroup',
    'calcWaits',
    'canWin',
    'solveM',
    'startGame',
    'loadQ',
    'doConfirm',
    'doNext',
    'toggle',
    'tick',
    'showResult',
    'toTop',
    'updateBar',
    'scoreAnim',
]

for fn in required_functions:
    p1 = rf'\bfunction\s+{re.escape(fn)}\s*\('
    p2 = rf'\b{re.escape(fn)}\s*[:=]\s*function\s*\('
    p3 = rf'\b{re.escape(fn)}\s*[:=]\s*\([^)]*\)\s*=>'
    p4 = rf'\b{re.escape(fn)}\s*[:=]\s*[a-zA-Z_]\w*\s*=>'
    found = (
        re.search(p1, html) or re.search(p2, html) or
        re.search(p3, html) or re.search(p4, html)
    )
    check(f"Function \'{fn}\'", found is not None)

print()
print('======================================================================')
print('2. Required HTML element IDs')
print('======================================================================')

required_ids = ['filterModes', 'decompToggle', 'decompArea', 'favBtn', 'weakBtn']

for eid in required_ids:
    pattern = rf"id\s*=\s*[\x22\x27]{re.escape(eid)}[\x22\x27]"
    found = re.search(pattern, html)
    check(f"Element id=\'{eid}\'", found is not None)

print()
print('======================================================================')
print('3. CSS class nt-wrap')
print('======================================================================')

css_in_style = re.search(r'\.nt-wrap\b', html)
css_in_attr = re.search(r"class\s*=\s*[\x22\x27][^\x22\x27]*\bnt-wrap\b", html)
check("CSS class nt-wrap exists", css_in_style or css_in_attr,
      f'in style: {bool(css_in_style)}, in class attr: {bool(css_in_attr)}')

print()
print('======================================================================')
print('4. String テンパイではない')
print('======================================================================')

check('テンパイではない present', 'テンパイではない' in html)

print()
print('======================================================================')
print('5. calcWaits 4-copy check (cnt[w] >= 4)')
print('======================================================================')

calc_body = extract_function_body('calcWaits', html)
if calc_body:
    has_4copy = 'cnt[w]>=4' in calc_body.replace(' ', '')
    check("calcWaits contains cnt[w] >= 4", has_4copy,
          f'function body length: {len(calc_body)} chars')
else:
    check("calcWaits contains cnt[w] >= 4", False, 'calcWaits function not found')

print()
print('======================================================================')
print('6. createGroup must NOT contain decomp-group-label')
print('======================================================================')

cg_body = extract_function_body('createGroup', html)
if cg_body:
    has_label = 'decomp-group-label' in cg_body
    check("createGroup does NOT contain decomp-group-label", not has_label,
          f"decomp-group-label {'FOUND (bad)' if has_label else 'absent (good)'}")
else:
    check("createGroup does NOT contain decomp-group-label", False,
          'createGroup function not found')

print()
print('======================================================================')
print('7. G.notTenpaiSel in code')
print('======================================================================')

check('G.notTenpaiSel exists', 'G.notTenpaiSel' in html)

print()
print('======================================================================')
print('8. G.currentTiles in code')
print('======================================================================')

check('G.currentTiles exists', 'G.currentTiles' in html)

print()
print('======================================================================')
print('9. G.probs[G.idx] occurrences (expect 0)')
print('======================================================================')

count_probs = html.count('G.probs[G.idx]')
check('G.probs[G.idx] count == 0', count_probs == 0,
      f'found {count_probs} occurrence(s)')

print()
print('======================================================================')
print('10. HTML well-formedness (tag matching)')
print('======================================================================')

for tag in ['script', 'style', 'body', 'html']:
    open_t = len(re.findall(rf'<{tag}[\s>]', html, re.IGNORECASE))
    close_t = len(re.findall(rf'</{tag}\s*>', html, re.IGNORECASE))
    check(f'<{tag}> open({open_t}) == close({close_t})',
          open_t == close_t, f'open={open_t}, close={close_t}')

print()
print('======================================================================')
print('11. generateProblem called from loadQ')
print('======================================================================')

lq_body = extract_function_body('loadQ', html)
if lq_body:
    has_gen = 'generateProblem' in lq_body
    check('loadQ calls generateProblem', has_gen,
          f'loadQ body length: {len(lq_body)} chars')
else:
    check('loadQ calls generateProblem', False, 'loadQ function not found')

print()
print('======================================================================')
print(f'SUMMARY:  {passed} passed / {total} total  ({failed} failed)')
print('======================================================================')

if failed == 0:
    print('ALL CHECKS PASSED.')
else:
    print(f'WARNING: {failed} check(s) FAILED.')

sys.exit(0 if failed == 0 else 1)