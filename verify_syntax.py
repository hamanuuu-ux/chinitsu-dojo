"""構文チェック"""
from pathlib import Path
import re, sys
sys.stdout.reconfigure(encoding='utf-8')

html = Path(r"C:\Users\haman\Downloads\チンイツ\chinitsu_trainer_v2.html").read_text(encoding='utf-8')
lines = html.split('\n')
print(f"行数: {len(lines)}")

# scriptタグ
so = html.count("<script")
sc = html.count("</script>")
print(f"scriptタグ: 開{so} 閉{sc} {'✅' if so==sc else '❌'}")

# JS部分の括弧チェック
m = re.search(r'<script[^>]*>(.*?)</script>', html, re.DOTALL)
if m:
    js = m.group(1)
    bo = js.count('{'); bc = js.count('}')
    po = js.count('('); pc = js.count(')')
    so2 = js.count('['); sc2 = js.count(']')
    print(f"中括弧: {bo}:{bc} {'✅' if bo==bc else '❌'}")
    print(f"丸括弧: {po}:{pc} {'✅' if po==pc else '❌'}")
    print(f"角括弧: {so2}:{sc2} {'✅' if so2==sc2 else '❌'}")

# 重要関数の存在チェック
funcs = ['generateProblem','generateTenpaiHand','generateRandomHand','generateCompleteHand',
         'calcWaits','canWin','solveM','startGame','loadQ','doConfirm','doNext',
         'toggleNotTenpai','toggleFavorite','toggleDecomp','showDecomposition',
         'renderDecomposition','createGroup','decomposeHand','findAllDecompositions',
         'goHome','toTop','showResult','toggle','startFiltered']
missing = [f for f in funcs if f'function {f}' not in html]
if missing:
    print(f"❌ 未検出関数: {missing}")
else:
    print(f"✅ 全{len(funcs)}関数検出OK")

# 種類表示が消えたか
if 'suit-badge' in html and '${si.cls}' not in html and '${si.label}' not in html:
    print("✅ 種類バッジのJS参照削除済み")
elif '${si.' in html:
    print("❌ まだ種類バッジのJS参照あり")
else:
    print("✅ 種類バッジ参照OK")

# れんしゅう
if '>れんしゅう<' in html:
    print("❌ 「れんしゅう」テキストがまだ表示中")
else:
    print("✅ 「れんしゅう」非表示")

# goHome
print(f"✅ goHome関数あり" if 'function goHome' in html else "❌ goHome関数なし")
print(f"✅ bhomeボタンあり" if 'bhome' in html else "❌ bhomeボタンなし")

# decomp待ち牌除外
if 'waitRemoved' in html:
    print("✅ 分解で待ち牌除外ロジックあり")
else:
    print("❌ 分解で待ち牌除外ロジックなし")
