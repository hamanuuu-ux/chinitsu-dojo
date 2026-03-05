"""9面待ちのパターンが他にも存在するか全探索"""
import sys
from itertools import combinations_with_replacement
sys.stdout.reconfigure(encoding='utf-8')

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

# 13枚の組み合わせを全探索（各牌1-9、最大4枚）
# combinations_with_replacement で重複組み合わせを列挙
print("9面待ちパターンを全探索中...")
count = 0
results = []

for combo in combinations_with_replacement(range(1, 10), 13):
    tiles = list(combo)
    # 各牌4枚以下チェック
    c = [0] * 10
    valid = True
    for t in tiles:
        c[t] += 1
        if c[t] > 4:
            valid = False
            break
    if not valid:
        continue

    count += 1
    if count % 100000 == 0:
        print(f"  {count}パターン探索済み...")

    waits = calc_waits(tiles)
    if len(waits) == 9:
        results.append(tiles)

print(f"\n探索完了: {count}パターン中")
print(f"9面待ち: {len(results)}パターン発見")
for tiles in results:
    waits = calc_waits(tiles)
    print(f"  [{','.join(str(t) for t in tiles)}] → 待ち: [{','.join(str(w) for w in waits)}]")
