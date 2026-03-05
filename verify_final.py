"""
chinitsu_trainer_v2.html 最終検証スクリプト
クリーンアップ後に全機能が正しく実装されているか確認
"""
from pathlib import Path
import re
import sys
sys.stdout.reconfigure(encoding='utf-8')

html_path = Path(r"C:\Users\haman\Downloads\チンイツ\chinitsu_trainer_v2.html")
content = html_path.read_text(encoding='utf-8')

checks = []

def check(name, condition):
    status = "✅" if condition else "❌"
    checks.append((name, condition))
    print(f"  {status} {name}")

print("=" * 60)
print("チンイツ練習アプリ v2 最終検証")
print("=" * 60)

# === 基本構造 ===
print("\n[基本構造]")
check("HTML開始タグ", "<html" in content)
check("script終了タグ", "</script>" in content)
check("HTML終了タグ", "</html>" in content)

# === DB削除確認 ===
print("\n[DB削除確認]")
check("const DB が存在しない", "const DB" not in content)
check("decomposeMentsu が存在しない", "decomposeMentsu" not in content)

# === 4枚制限 ===
print("\n[4枚制限対応]")
check("calcWaits に cnt[w]>=4 チェック", "cnt[w] >= 4" in content or "cnt[w]>=4" in content)
check("disabled クラスのCSS", ".ct-wrap.disabled" in content)
check("UI側の4枚無効化コード", "classList.add('disabled')" in content)

# === ランダム生成 ===
print("\n[ランダム生成]")
check("generateCompleteHand 関数", "function generateCompleteHand" in content)
check("generateTenpaiHand 関数", "function generateTenpaiHand" in content)
check("generateRandomHand 関数", "function generateRandomHand" in content)
check("generateProblem 関数", "function generateProblem" in content)
check("G.currentTiles", "G.currentTiles" in content)
check("G.probs が存在しない", "G.probs" not in content)

# === テンパイではない ===
print("\n[テンパイではない機能]")
check("toggleNotTenpai 関数", "function toggleNotTenpai" in content)
check("notTenpaiSel 状態変数", "notTenpaiSel" in content)
check("nt-wrap クラス", "nt-wrap" in content)
check("テンパイではない テキスト", "テンパイではない" in content)

# === 分解表示 ===
print("\n[分解表示]")
check("findAllDecompositions 関数", "function findAllDecompositions" in content)
check("decomposeHand 関数", "function decomposeHand" in content)
check("createGroup 関数", "function createGroup" in content)
check("decomp-group クラス", "decomp-group" in content)
check("decomp-tile クラス", "decomp-tile" in content)
# ラベルが削除されているか
check("createGroup にラベルなし", "decomp-label" not in content or
      content.count("decomp-label") == 0)

# === お気に入り・苦手 ===
print("\n[お気に入り・苦手機能]")
check("loadFavorites 関数", "function loadFavorites" in content)
check("saveFavorites 関数", "function saveFavorites" in content)
check("loadWeak 関数", "function loadWeak" in content)
check("saveWeak 関数", "function saveWeak" in content)
check("toggleFavorite 関数", "function toggleFavorite" in content)
check("chinitsu_favorites キー", "chinitsu_favorites" in content)
check("chinitsu_weak キー", "chinitsu_weak" in content)
check("startFiltered 関数", "function startFiltered" in content)

# === コアエンジン ===
print("\n[コアエンジン]")
check("calcWaits 関数", "function calcWaits" in content)
check("canWin 関数", "function canWin" in content)
check("solveM 関数", "function solveM" in content)

# === ゲーム機能 ===
print("\n[ゲーム機能]")
check("startGame 関数", "function startGame" in content)
check("loadQ 関数", "function loadQ" in content)
check("doConfirm 関数", "function doConfirm" in content)
check("doNext 関数", "function doNext" in content)
check("showResult 関数", "function showResult" in content)
check("toTop 関数", "function toTop" in content)
check("toggle 関数", "function toggle" in content)

# === UI要素 ===
print("\n[UI要素]")
check("スタート画面 id='ss'", "id='ss'" in content or "id=\"ss\"" in content)
check("ゲーム画面 id='gm'", "id='gm'" in content or "id=\"gm\"" in content)
check("リザルト画面 id='rs'", "id='rs'" in content or "id=\"rs\"" in content)

# === 構文チェック ===
print("\n[構文チェック]")
# scriptタグの数が一致
script_open = content.count("<script")
script_close = content.count("</script>")
check(f"scriptタグ対応 (開:{script_open} 閉:{script_close})", script_open == script_close)

# 括弧の大まかなバランス（script内）
script_match = re.search(r'<script[^>]*>(.*?)</script>', content, re.DOTALL)
if script_match:
    js = script_match.group(1)
    braces_open = js.count('{')
    braces_close = js.count('}')
    parens_open = js.count('(')
    parens_close = js.count(')')
    brackets_open = js.count('[')
    brackets_close = js.count(']')
    check(f"中括弧バランス ({braces_open}:{braces_close})", braces_open == braces_close)
    check(f"丸括弧バランス ({parens_open}:{parens_close})", parens_open == parens_close)
    check(f"角括弧バランス ({brackets_open}:{brackets_close})", brackets_open == brackets_close)
else:
    check("scriptタグ検出", False)

# === サマリ ===
print("\n" + "=" * 60)
passed = sum(1 for _, ok in checks if ok)
failed = sum(1 for _, ok in checks if not ok)
print(f"結果: {passed} パス / {failed} 失敗 / {len(checks)} 合計")
if failed == 0:
    print("🎉 全チェック通過！")
else:
    print("\n❌ 失敗した項目:")
    for name, ok in checks:
        if not ok:
            print(f"  - {name}")
