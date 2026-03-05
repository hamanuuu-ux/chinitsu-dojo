"""
問題DB拡充スクリプト（200問以上）
既存49問を含め、待ち数別にバランスよく生成する。

待ち数別の目標:
  9面待ち: 1問（九蓮宝燈のみ）
  8面待ち: 5問
  7面待ち: 10問
  6面待ち: 25問
  5面待ち: 35問
  4面待ち: 35問
  3面待ち: 35問
  2面待ち: 25問
  1面待ち: 15問
  非テンパイ: 14問
  合計: 200問
"""
import random
import json
import sys
sys.stdout.reconfigure(encoding='utf-8')

random.seed(2026)

# ── 待ち計算エンジン（HANDOFF.md準拠）──

def calc_waits(tiles13):
    waits = []
    cnt = [0] * 10
    for t in tiles13:
        cnt[t] += 1
    for w in range(1, 10):
        if cnt[w] >= 4:
            continue
        h = sorted(tiles13 + [w])
        if can_win(h):
            waits.append(w)
    return waits

def can_win(h):
    c = [0] * 10
    for t in h:
        c[t] += 1
    tried = set()
    for t in h:
        if t in tried:
            continue
        tried.add(t)
        if c[t] >= 2:
            c[t] -= 2
            if solve_m(c, 4):
                c[t] += 2
                return True
            c[t] += 2
    return False

def solve_m(c, rem):
    if rem == 0:
        return all(c[i] == 0 for i in range(1, 10))
    n = -1
    for i in range(1, 10):
        if c[i] > 0:
            n = i
            break
    if n < 0:
        return False
    if c[n] >= 3:
        c[n] -= 3
        if solve_m(c, rem - 1):
            c[n] += 3
            return True
        c[n] += 3
    if n <= 7 and c[n] >= 1 and c[n+1] >= 1 and c[n+2] >= 1:
        c[n] -= 1; c[n+1] -= 1; c[n+2] -= 1
        if solve_m(c, rem - 1):
            c[n] += 1; c[n+1] += 1; c[n+2] += 1
            return True
        c[n] += 1; c[n+1] += 1; c[n+2] += 1
    return False

# ── 手牌生成 ──

def generate_complete_hand():
    """完成形（4面子+1雀頭=14枚）をランダム生成"""
    for _ in range(200):
        tiles = []
        c = [0] * 10
        head_val = random.randint(1, 9)
        if c[head_val] + 2 > 4:
            continue
        tiles.extend([head_val, head_val])
        c[head_val] += 2
        ok = True
        for _ in range(4):
            if random.random() < 0.6:
                start = random.randint(1, 7)
                if c[start]+1<=4 and c[start+1]+1<=4 and c[start+2]+1<=4:
                    tiles.extend([start, start+1, start+2])
                    c[start] += 1; c[start+1] += 1; c[start+2] += 1
                else:
                    ok = False
                    break
            else:
                val = random.randint(1, 9)
                if c[val]+3 <= 4:
                    tiles.extend([val, val, val])
                    c[val] += 3
                else:
                    ok = False
                    break
        if ok and len(tiles) == 14:
            return sorted(tiles)
    return None

def generate_tenpai():
    """完成形から1枚抜いてテンパイ形を作る"""
    hand = generate_complete_hand()
    if not hand:
        return None
    indices = list(range(14))
    random.shuffle(indices)
    for idx in indices:
        tiles13 = hand[:idx] + hand[idx+1:]
        w = calc_waits(tiles13)
        if len(w) >= 1:
            return sorted(tiles13), w
    return None

def generate_random_non_tenpai():
    """テンパイでないランダム13枚を生成"""
    for _ in range(10000):
        tiles = []
        c = [0] * 10
        ok = True
        for _ in range(13):
            v = random.randint(1, 9)
            if c[v] >= 4:
                ok = False
                break
            tiles.append(v)
            c[v] += 1
        if ok and len(tiles) == 13:
            w = calc_waits(tiles)
            if len(w) == 0:
                return sorted(tiles)
    return None

# ── 既存49問DB ──

EXISTING_DB = [
    [1,1,1,2,3,4,5,6,7,8,9,9,9],
    [1,1,2,3,4,5,6,7,8,9,9,9,9],
    [1,2,3,4,5,6,1,2,3,7,8,9,9],
    [1,2,3,4,5,6,7,8,9,1,1,3,4],
    [2,3,4,5,6,7,8,9,9,1,1,1,2],
    [1,1,1,2,3,4,5,6,7,8,8,8,9],
    [1,2,3,5,6,7,8,9,9,9,3,4,5],
    [1,1,3,4,5,6,7,8,2,2,2,9,9],
    [2,2,3,4,5,6,7,8,9,5,5,5,1],
    [1,1,1,4,5,6,7,8,9,3,3,2,3],
    [1,2,3,4,5,6,7,8,9,1,2,3,5],
    [2,3,4,5,6,7,2,3,4,8,8,8,5],
    [1,1,2,3,4,5,6,7,2,3,4,5,6],
    [3,4,5,6,7,8,1,2,3,1,1,5,6],
    [1,2,3,4,5,6,7,8,4,5,6,2,2],
    [5,5,5,1,2,3,4,5,6,7,8,3,4],
    [1,2,3,4,5,6,4,5,6,7,8,1,1],
    [2,3,4,5,6,7,8,9,3,4,5,6,6],
    [1,1,1,2,3,7,8,9,4,5,6,3,3],
    [3,3,4,5,6,7,8,9,1,2,3,6,7],
    [1,1,2,2,3,3,4,4,5,5,6,7,8],
    [1,1,2,2,3,3,4,5,6,7,8,9,9],
    [1,2,3,4,5,6,7,7,8,8,9,9,5],
    [2,2,3,3,4,4,5,5,6,6,7,8,9],
    [1,1,2,2,3,3,7,7,8,8,9,5,6],
    [3,4,5,6,7,8,9,9,1,2,3,6,6],
    [1,1,4,4,5,5,6,6,7,7,2,3,4],
    [2,3,4,5,6,7,8,8,3,3,1,2,3],
    [1,2,3,1,2,3,4,5,6,7,7,4,5],
    [5,6,7,8,9,1,2,3,4,4,4,6,7],
    [1,1,2,3,4,5,6,7,8,9,9,3,3],
    [1,2,3,4,5,5,6,7,8,9,9,2,3],
    [2,2,3,4,5,6,7,8,9,1,1,1,4],
    [1,2,3,4,5,6,7,8,9,2,3,4,4],
    [1,1,1,3,4,5,6,7,8,2,2,5,6],
    [3,3,4,5,6,7,8,9,1,2,3,5,5],
    [1,2,3,4,5,6,7,8,9,4,5,6,2],
    [2,3,4,5,6,7,1,1,1,8,9,6,6],
    [1,1,2,3,4,5,6,2,3,4,7,8,9],
    [4,5,6,7,8,9,1,2,3,3,4,5,7],
    [1,1,1,2,3,4,5,5,5,6,7,8,9],
    [9,9,1,2,3,4,5,6,7,8,9,7,8],
    [1,2,3,7,8,9,1,1,4,5,6,3,3],
    [1,2,3,4,5,6,7,8,9,1,2,3,7],
    [9,9,9,1,2,3,4,5,6,7,8,5,5],
    [1,1,2,3,4,6,7,8,5,5,5,3,4],
    [3,3,3,5,6,7,8,9,1,2,3,4,4],
    [1,2,3,4,5,6,7,8,9,2,2,4,5],
    [2,3,4,5,5,6,7,8,9,1,2,3,1],
]

# ── 収集 ──

TARGET = {
    8: 5,
    7: 10,
    6: 25,
    5: 35,
    4: 35,
    3: 35,
    2: 25,
    1: 15,
}
NON_TENPAI_TARGET = 14

# 既存問題を登録
collected = {k: [] for k in TARGET}
non_tenpai_list = []
seen = set()

# 九蓮宝燈は固定
nine_gates = [1,1,1,2,3,4,5,6,7,8,9,9,9]
seen.add(json.dumps(nine_gates))

# 既存49問を分類して登録
for tiles in EXISTING_DB:
    s = sorted(tiles)
    key = json.dumps(s)
    if key in seen:
        continue
    seen.add(key)
    waits = calc_waits(s)
    wc = len(waits)
    if wc == 0:
        if len(non_tenpai_list) < NON_TENPAI_TARGET:
            non_tenpai_list.append(s)
    elif wc in collected and len(collected[wc]) < TARGET[wc]:
        collected[wc].append(s)

existing_count = 1 + sum(len(v) for v in collected.values()) + len(non_tenpai_list)
print(f"既存DB登録: {existing_count}問")
for wc in sorted(collected.keys(), reverse=True):
    print(f"  {wc}面待ち: {len(collected[wc])}/{TARGET[wc]}")

# 新規問題の収集
print("\n新規問題を生成中...")
attempts = 0
max_attempts = 5000000

while attempts < max_attempts:
    attempts += 1
    if attempts % 500000 == 0:
        progress = sum(len(collected[k]) for k in TARGET)
        total_target = sum(TARGET.values())
        print(f"  ...{attempts}回試行 ({progress}/{total_target}問)")

    result = generate_tenpai()
    if result is None:
        continue
    tiles13, waits = result
    key = json.dumps(tiles13)
    if key in seen:
        continue

    wait_count = len(waits)
    if wait_count in collected and len(collected[wait_count]) < TARGET[wait_count]:
        collected[wait_count].append(tiles13)
        seen.add(key)

    if all(len(collected[k]) >= TARGET[k] for k in TARGET):
        break

# 非テンパイ問題を追加
while len(non_tenpai_list) < NON_TENPAI_TARGET:
    hand = generate_random_non_tenpai()
    if hand:
        key = json.dumps(hand)
        if key not in seen:
            non_tenpai_list.append(hand)
            seen.add(key)

print(f"\n生成完了（{attempts}回試行）")

# ── 結果集計 ──
print("\n" + "=" * 70)
print("問題DB 集計")
print("=" * 70)

all_problems = []

# 9面待ち
w9 = calc_waits(nine_gates)
all_problems.append((nine_gates, w9))
print(f"  9面待ち: 1問")

for wc in sorted(TARGET.keys(), reverse=True):
    problems = collected[wc]
    print(f"  {wc}面待ち: {len(problems)}/{TARGET[wc]}問")
    for tiles in problems:
        waits = calc_waits(tiles)
        all_problems.append((tiles, waits))

print(f"  非テンパイ: {len(non_tenpai_list)}/{NON_TENPAI_TARGET}問")
for tiles in non_tenpai_list:
    all_problems.append((tiles, []))

total = len(all_problems)
print(f"\n合計: {total}問")

# ── JS配列形式で出力 ──
print("\n" + "=" * 70)
print("JS形式（chinitsu_trainer_v2.html の DB に埋め込み用）")
print("=" * 70)

print("const PROBLEM_DB = [")
for tiles, waits in all_problems:
    tiles_str = ','.join(str(t) for t in tiles)
    if len(waits) > 0:
        waits_str = ','.join(str(w) for w in waits)
        comment = f"// {len(waits)}面待ち [{waits_str}]"
    else:
        comment = "// 非テンパイ"
    print(f"  [{tiles_str}], {comment}")
print("];")

# ── Dart形式で出力 ──
print("\n" + "=" * 70)
print("Dart形式（chinitsu_engine.dart の DB 用）")
print("=" * 70)

print("const problemDb = <List<int>>[")
for tiles, waits in all_problems:
    tiles_str = ', '.join(str(t) for t in tiles)
    if len(waits) > 0:
        waits_str = ', '.join(str(w) for w in waits)
        comment = f"// {len(waits)}面待ち [{waits_str}]"
    else:
        comment = "// 非テンパイ"
    print(f"  [{tiles_str}], {comment}")
print("];")

# ── 検証 ──
print("\n" + "=" * 70)
print("検証")
print("=" * 70)
errors = 0
for i, (tiles, expected_waits) in enumerate(all_problems):
    actual = calc_waits(tiles)
    if actual != expected_waits:
        print(f"  NG 問題{i+1}: expected={expected_waits}, actual={actual}")
        errors += 1
    # 13枚であること
    if len(tiles) != 13:
        print(f"  NG 問題{i+1}: {len(tiles)}枚")
        errors += 1
    # 各牌1〜9
    for t in tiles:
        if t < 1 or t > 9:
            print(f"  NG 問題{i+1}: 無効な牌 {t}")
            errors += 1
    # 同一牌4枚以下
    cnt = [0] * 10
    for t in tiles:
        cnt[t] += 1
    for j in range(1, 10):
        if cnt[j] > 4:
            print(f"  NG 問題{i+1}: 牌{j}が{cnt[j]}枚")
            errors += 1

if errors == 0:
    print(f"  全{total}問 検証OK ✓")
else:
    print(f"  エラー: {errors}件")
