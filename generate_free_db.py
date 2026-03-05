"""
無料版用 固定50問DB生成スクリプト
待ち数別の内訳:
  9面待ち: 1問（九蓮宝燈のみ）
  8面待ち: 3問
  7面待ち: 5問
  6面待ち: 16問
  5面待ち: 10問
  4面待ち: 5問
  3面待ち: 5問
  2面待ち: 2問
  非テンパイ: 3問
  合計: 50問
"""
import random
import json
import sys
sys.stdout.reconfigure(encoding='utf-8')

random.seed(42)

# ── 待ち計算エンジン ──

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

# ── 待ち数別に収集 ──

TARGET = {
    8: 3,
    7: 5,
    6: 16,
    5: 10,
    4: 5,
    3: 5,
    2: 2,
}

collected = {k: [] for k in TARGET}
seen = set()

# 九蓮宝燈は固定で追加
nine_gates = [1,1,1,2,3,4,5,6,7,8,9,9,9]
seen.add(json.dumps(nine_gates))

print("生成中...")
attempts = 0
max_attempts = 1000000

while attempts < max_attempts:
    attempts += 1
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

# 非テンパイ3問
non_tenpai = []
for _ in range(100000):
    hand = generate_random_non_tenpai()
    if hand:
        key = json.dumps(hand)
        if key not in seen:
            non_tenpai.append(hand)
            seen.add(key)
            if len(non_tenpai) >= 3:
                break

print(f"試行回数: {attempts}")
print()

# ── 結果表示 ──
print("=" * 70)
print("無料版 固定50問DB サンプル")
print("=" * 70)

all_problems = []

# 9面待ち
print(f"\n【9面待ち: 1問】")
waits = calc_waits(nine_gates)
tiles_str = ','.join(str(t) for t in nine_gates)
waits_str = ','.join(str(w) for w in waits)
print(f"  1. [{tiles_str}]  → 待ち: [{waits_str}]")
all_problems.append((nine_gates, waits, 9))

for wait_count in sorted(TARGET.keys(), reverse=True):
    problems = collected[wait_count]
    print(f"\n【{wait_count}面待ち: {len(problems)}/{TARGET[wait_count]}問】")
    for i, tiles in enumerate(problems):
        waits = calc_waits(tiles)
        waits_str = ','.join(str(w) for w in waits)
        tiles_str = ','.join(str(t) for t in tiles)
        print(f"  {i+1}. [{tiles_str}]  → 待ち: [{waits_str}]")
        all_problems.append((tiles, waits, wait_count))

print(f"\n【非テンパイ: {len(non_tenpai)}/3問】")
for i, tiles in enumerate(non_tenpai):
    tiles_str = ','.join(str(t) for t in tiles)
    print(f"  {i+1}. [{tiles_str}]  → 待ちなし")
    all_problems.append((tiles, [], 0))

total = 1 + sum(len(collected[k]) for k in TARGET) + len(non_tenpai)
print(f"\n合計: {total}問")

# ── JS配列形式 ──
print("\n" + "=" * 70)
print("JS形式:")
print("=" * 70)
print("const FREE_DB = [")
for tiles, waits, wc in all_problems:
    comment = f"// {wc}面待ち [{','.join(str(w) for w in waits)}]" if wc > 0 else "// 非テンパイ"
    print(f"  [{','.join(str(t) for t in tiles)}], {comment}")
print("];")
