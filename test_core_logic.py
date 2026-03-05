"""
チンイツ コアロジック テスト
JS実装と同等のPythonコードで動作を検証
"""
import sys
import random
sys.stdout.reconfigure(encoding='utf-8')

# === コアエンジン ===

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

def generate_complete_hand():
    for _ in range(100):
        tiles = []
        c = [0] * 10
        head_val = random.randint(1, 9)
        if c[head_val] + 2 > 4:
            continue
        tiles.extend([head_val, head_val])
        c[head_val] += 2
        ok = True
        for _ in range(4):
            if random.random() < 0.65:  # shuntsu
                start = random.randint(1, 7)
                if c[start]+1<=4 and c[start+1]+1<=4 and c[start+2]+1<=4:
                    tiles.extend([start, start+1, start+2])
                    c[start] += 1; c[start+1] += 1; c[start+2] += 1
                else:
                    ok = False
                    break
            else:  # koutsu
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

def generate_random_hand():
    for _ in range(100):
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
        if ok:
            return sorted(tiles)
    return None

# === テスト ===

print("=" * 60)
print("チンイツ コアロジックテスト")
print("=" * 60)

passed = 0
failed = 0

def test(name, condition):
    global passed, failed
    if condition:
        passed += 1
        print(f"  ✅ {name}")
    else:
        failed += 1
        print(f"  ❌ {name}")

# テスト1: 既知の手牌
print("\n[テスト1] 既知の手牌テスト")
waits = calc_waits([1,1,1,2,3,4,5,6,7,8,9,9,9])
test(f"九蓮宝燈形: 待ち={waits}", waits == [1,4,7,9])

waits2 = calc_waits([1,2,3,4,5,6,7,8,9,1,2,3,1])
test(f"[1,1,1,1,2,2,3,3,4,5,6,7,8,9] → 待ち={waits2}", len(waits2) >= 1)

# テスト2: 4枚制限
print("\n[テスト2] 4枚制限")
waits3 = calc_waits([1,1,1,1,2,3,4,5,6,7,8,9,9])
test(f"1が4枚→1は待ちに入らない: 待ち={waits3}", 1 not in waits3)

waits4 = calc_waits([9,9,9,9,1,2,3,4,5,6,7,8,8])
test(f"9が4枚→9は待ちに入らない: 待ち={waits4}", 9 not in waits4)

# テスト3: テンパイ手生成
print("\n[テスト3] テンパイ手生成 (100回)")
tenpai_ok = 0
for _ in range(100):
    result = generate_tenpai()
    if result:
        tiles, w = result
        if len(tiles) == 13 and len(w) >= 1:
            # 各牌4枚以下チェック
            c = [0]*10
            valid = True
            for t in tiles:
                c[t] += 1
                if c[t] > 4:
                    valid = False
            if valid:
                tenpai_ok += 1
test(f"成功率: {tenpai_ok}/100", tenpai_ok >= 90)

# テスト4: ランダム手生成（テンパイじゃないものも含む）
print("\n[テスト4] ランダム手生成 (100回)")
random_ok = 0
non_tenpai_count = 0
for _ in range(100):
    hand = generate_random_hand()
    if hand and len(hand) == 13:
        c = [0]*10
        valid = True
        for t in hand:
            c[t] += 1
            if c[t] > 4:
                valid = False
        if valid:
            random_ok += 1
            w = calc_waits(hand)
            if len(w) == 0:
                non_tenpai_count += 1
test(f"制約OK: {random_ok}/100", random_ok == 100)
print(f"  ℹ️ うちテンパイでない: {non_tenpai_count}/100")

# テスト5: 問題生成ミックス（70%テンパイ + 30%ランダム）
print("\n[テスト5] 問題生成ミックス (200回)")
tenpai_hands = 0
non_tenpai_hands = 0
for _ in range(200):
    if random.random() < 0.7:
        result = generate_tenpai()
        if result:
            tiles, w = result
            tenpai_hands += 1
            continue
    hand = generate_random_hand()
    if hand:
        w = calc_waits(hand)
        if len(w) > 0:
            tenpai_hands += 1
        else:
            non_tenpai_hands += 1
print(f"  ℹ️ テンパイ: {tenpai_hands}, 非テンパイ: {non_tenpai_hands}")
test("テンパイ手あり", tenpai_hands > 0)
test("非テンパイ手あり", non_tenpai_hands > 0)

# テスト6: 分解テスト
print("\n[テスト6] 手牌分解テスト")

def find_all_decompositions(c, rem, current, results):
    if rem == 0:
        if all(c[i] == 0 for i in range(1, 10)):
            results.append([list(m) for m in current])
        return
    n = -1
    for i in range(1, 10):
        if c[i] > 0:
            n = i
            break
    if n < 0:
        return
    if c[n] >= 3:
        c[n] -= 3
        current.append([n, n, n])
        find_all_decompositions(c, rem - 1, current, results)
        current.pop()
        c[n] += 3
    if n <= 7 and c[n] >= 1 and c[n+1] >= 1 and c[n+2] >= 1:
        c[n] -= 1; c[n+1] -= 1; c[n+2] -= 1
        current.append([n, n+1, n+2])
        find_all_decompositions(c, rem - 1, current, results)
        current.pop()
        c[n] += 1; c[n+1] += 1; c[n+2] += 1

def decompose_hand(tiles14):
    c = [0] * 10
    for t in tiles14:
        c[t] += 1
    all_results = []
    tried = set()
    for t in tiles14:
        if t in tried:
            continue
        tried.add(t)
        if c[t] >= 2:
            c[t] -= 2
            mentsu_results = []
            find_all_decompositions(c, 4, [], mentsu_results)
            for mr in mentsu_results:
                all_results.append({'head': [t, t], 'mentsu': mr})
            c[t] += 2
    return all_results

# 九蓮宝燈+9 = [1,1,1,2,3,4,5,6,7,8,9,9,9,9]
test_hand = [1,1,1,2,3,4,5,6,7,8,9,9,9,9]
decomps = decompose_hand(test_hand)
test(f"九蓮+9の分解パターン数={len(decomps)} (>=1)", len(decomps) >= 1)
for i, d in enumerate(decomps):
    head = d['head']
    mentsu = d['mentsu']
    total = head + [t for m in mentsu for t in m]
    test(f"  パターン{i+1}: 合計{len(total)}枚=14枚", len(total) == 14)
    if i >= 2:
        print(f"  ... (省略: 残り{len(decomps)-3}パターン)")
        break

# テスト7: 生成したテンパイ手の分解確認
print("\n[テスト7] 生成テンパイ手の分解確認 (10回)")
decomp_ok = 0
for _ in range(10):
    result = generate_tenpai()
    if result:
        tiles13, waits = result
        for w in waits[:2]:  # 最大2つの待ちで確認
            tiles14 = sorted(tiles13 + [w])
            decomps = decompose_hand(tiles14)
            if len(decomps) >= 1:
                decomp_ok += 1
                break
test(f"分解成功: {decomp_ok}/10", decomp_ok >= 8)

# === サマリ ===
print("\n" + "=" * 60)
print(f"結果: {passed} パス / {failed} 失敗 / {passed + failed} 合計")
if failed == 0:
    print("🎉 全テスト通過！")
else:
    print("⚠️ 失敗あり")
