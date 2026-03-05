"""
チンイツ練習アプリ 問題DB自動生成スクリプト
有効なテンパイ形（13枚）を200問以上生成する
"""
import random
import json
import sys
sys.stdout.reconfigure(encoding='utf-8')

# ── 待ち計算エンジン（HTML版と同一ロジック） ──

def calc_waits(tiles13):
    """13枚からの待ち牌リスト（1〜9）"""
    waits = []
    for w in range(1, 10):
        h = sorted(tiles13 + [w])
        if can_win(h):
            waits.append(w)
    return waits

def can_win(h):
    """14枚のアガリ判定"""
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
    """面子取り出し再帰探索"""
    if rem == 0:
        return all(c[i] == 0 for i in range(1, 10))
    n = -1
    for i in range(1, 10):
        if c[i] > 0:
            n = i
            break
    if n < 0:
        return False
    # 刻子
    if c[n] >= 3:
        c[n] -= 3
        if solve_m(c, rem - 1):
            c[n] += 3
            return True
        c[n] += 3
    # 順子
    if n <= 7 and c[n] >= 1 and c[n+1] >= 1 and c[n+2] >= 1:
        c[n] -= 1; c[n+1] -= 1; c[n+2] -= 1
        if solve_m(c, rem - 1):
            c[n] += 1; c[n+1] += 1; c[n+2] += 1
            return True
        c[n] += 1; c[n+1] += 1; c[n+2] += 1
    return False

# ── 問題生成 ──

def check_tile_count(tiles):
    """各牌が4枚以下かチェック"""
    c = [0] * 10
    for t in tiles:
        c[t] += 1
        if c[t] > 4:
            return False
    return True

def generate_complete_hand():
    """
    完成形（4面子+1雀頭=14枚）をランダム生成
    各牌は最大4枚の制約
    """
    max_attempts = 100
    for _ in range(max_attempts):
        tiles = []
        c = [0] * 10  # 各牌の使用枚数

        # 雀頭
        head_val = random.randint(1, 9)
        if c[head_val] + 2 > 4:
            continue
        tiles.extend([head_val, head_val])
        c[head_val] += 2

        # 4面子
        ok = True
        for _ in range(4):
            mentsu_type = random.choice(['shuntsu', 'shuntsu', 'koutsu'])  # 順子多め
            if mentsu_type == 'shuntsu':
                start = random.randint(1, 7)
                if c[start] + 1 <= 4 and c[start+1] + 1 <= 4 and c[start+2] + 1 <= 4:
                    tiles.extend([start, start+1, start+2])
                    c[start] += 1; c[start+1] += 1; c[start+2] += 1
                else:
                    ok = False
                    break
            else:  # koutsu
                val = random.randint(1, 9)
                if c[val] + 3 <= 4:
                    tiles.extend([val, val, val])
                    c[val] += 3
                else:
                    ok = False
                    break
        if ok and len(tiles) == 14:
            return sorted(tiles)
    return None

def generate_tenpai():
    """
    テンパイ形（13枚）を生成
    14枚完成形から1枚を抜く
    """
    hand = generate_complete_hand()
    if hand is None:
        return None

    # ランダムに1枚を抜く（重複を避けるためユニークな位置をシャッフル）
    indices = list(range(14))
    random.shuffle(indices)

    for idx in indices:
        tiles13 = hand[:idx] + hand[idx+1:]
        waits = calc_waits(tiles13)
        if len(waits) >= 1:
            return sorted(tiles13), waits

    return None

# ── 既存DB ──
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

def main():
    # 既存DBをソートしてセットに
    existing = set()
    for hand in EXISTING_DB:
        key = json.dumps(sorted(hand))
        existing.add(key)

    print(f"既存DB: {len(existing)}問")

    target = 200
    new_problems = []
    attempts = 0
    max_attempts = 100000

    while len(existing) < target and attempts < max_attempts:
        attempts += 1
        result = generate_tenpai()
        if result is None:
            continue

        tiles13, waits = result
        key = json.dumps(tiles13)

        if key not in existing:
            existing.add(key)
            new_problems.append(tiles13)

    total = len(EXISTING_DB) + len(new_problems)
    print(f"新規生成: {len(new_problems)}問")
    print(f"合計: {total}問")
    print(f"試行回数: {attempts}")
    print()

    # 全問題を出力（既存+新規）
    all_problems = [sorted(h) for h in EXISTING_DB] + new_problems

    # 各問題の待ち数を確認
    print("// 待ち数分布:")
    wait_dist = {}
    for hand in all_problems:
        w = len(calc_waits(hand))
        wait_dist[w] = wait_dist.get(w, 0) + 1
    for k in sorted(wait_dist.keys()):
        print(f"//   {k}面待ち: {wait_dist[k]}問")
    print()

    # JS配列として出力
    print("const DB = [")
    for i, hand in enumerate(all_problems):
        comma = "," if i < len(all_problems) - 1 else ""
        print(f"  [{','.join(str(t) for t in hand)}]{comma}")
    print("];")

if __name__ == "__main__":
    main()
