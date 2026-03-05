"""
chinitsu_trainer_v2.html から不要なコードを削除するクリーンアップスクリプト
1. 孤立したDB配列データ（旧問題DB）を削除
2. 未使用の decomposeMentsu 関数を削除
"""
from pathlib import Path

html_path = Path(r"C:\Users\haman\Downloads\チンイツ\chinitsu_trainer_v2.html")
lines = html_path.read_text(encoding='utf-8').split('\n')

print(f"元の行数: {len(lines)}")

# --- 1. 孤立したDB配列データを削除 ---
# solveM関数の閉じ括弧の後、ゲーム状態セクションの前にある孤立データを探す
remove_start = None
remove_end = None

for i, line in enumerate(lines):
    # "// ═══" の直後に配列データ "[1,1,..." が来るパターンを検出
    if line.strip().startswith('// ═══') and i + 1 < len(lines) and lines[i+1].strip().startswith('['):
        # これがDB残骸かチェック（前の行がsolveM関数の閉じ括弧付近）
        if i > 0 and (lines[i-1].strip() == '' or lines[i-1].strip() == '}'):
            remove_start = i
            break

if remove_start is not None:
    # ];の行を探す
    for i in range(remove_start, len(lines)):
        if lines[i].strip() == '];':
            remove_end = i
            break

if remove_start is not None and remove_end is not None:
    print(f"DB残骸を削除: 行 {remove_start+1} 〜 {remove_end+1}")
    # remove_end+1の次の空行も削除
    end = remove_end + 1
    if end < len(lines) and lines[end].strip() == '':
        end += 1
    lines = lines[:remove_start] + lines[end:]
else:
    print("DB残骸: 見つかりません（すでに削除済み？）")

# --- 2. 未使用の decomposeMentsu 関数を削除 ---
dm_start = None
dm_end = None

for i, line in enumerate(lines):
    if 'function decomposeMentsu(' in line:
        dm_start = i
        break

if dm_start is not None:
    # 関数の閉じ括弧を探す（ブレース数を追跡）
    brace_count = 0
    started = False
    for i in range(dm_start, len(lines)):
        for ch in lines[i]:
            if ch == '{':
                brace_count += 1
                started = True
            elif ch == '}':
                brace_count -= 1
        if started and brace_count == 0:
            dm_end = i
            break

if dm_start is not None and dm_end is not None:
    print(f"decomposeMentsu を削除: 行 {dm_start+1} 〜 {dm_end+1}")
    # 前後の空行も整理
    end = dm_end + 1
    if end < len(lines) and lines[end].strip() == '':
        end += 1
    start = dm_start
    if start > 0 and lines[start-1].strip() == '':
        start -= 1
    lines = lines[:start] + lines[end:]
else:
    print("decomposeMentsu: 見つかりません（すでに削除済み？）")

html_path.write_text('\n'.join(lines), encoding='utf-8')
print(f"クリーンアップ後の行数: {len(lines)}")
print("完了!")
