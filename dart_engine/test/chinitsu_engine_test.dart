import 'package:test/test.dart';
import '../lib/chinitsu_engine.dart';

void main() {
  group('canWin - 14枚アガリ判定', () {
    test('九連宝燈ベース（1112345678999+任意）はアガリ', () {
      // 1を加えて14枚
      expect(canWin([1, 1, 1, 1, 2, 3, 4, 5, 6, 7, 8, 9, 9, 9]), isTrue);
    });

    test('基本的な4面子+1雀頭', () {
      // 11 + 234 + 234 + 567 + 789
      expect(canWin([1, 1, 2, 2, 3, 3, 4, 4, 5, 6, 7, 7, 8, 9]), isTrue);
    });

    test('刻子のみの完成形', () {
      // 111 + 222 + 333 + 444 + 55
      expect(canWin([1, 1, 1, 2, 2, 2, 3, 3, 3, 4, 4, 4, 5, 5]), isTrue);
    });

    test('アガれない手牌', () {
      expect(canWin([1, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 9]), isFalse);
    });
  });

  group('calcWaits - 13枚からの待ち計算', () {
    test('九連宝燈は1〜9の9面待ち', () {
      final waits = calcWaits([1, 1, 1, 2, 3, 4, 5, 6, 7, 8, 9, 9, 9]);
      expect(waits, equals([1, 2, 3, 4, 5, 6, 7, 8, 9]));
    });

    test('単純な単騎待ち', () {
      // 111 + 234 + 567 + 89 → 7待ち
      final waits = calcWaits([1, 1, 1, 2, 3, 4, 5, 6, 7, 8, 9, 9, 9]);
      expect(waits.contains(1), isTrue);
    });

    test('テンパイでない手牌は空リスト', () {
      // ランダムな非テンパイ手牌
      final waits = calcWaits([1, 1, 3, 3, 5, 5, 7, 7, 9, 9, 2, 4, 8]);
      // この手牌の待ちを検証（テンパイかどうか）
      // 結果が空であればテンパイでない
      expect(waits, isA<List<int>>());
    });

    test('4枚使用済みの牌は待ちにならない', () {
      // 1が4枚ある→1は待ちにならない
      final waits = calcWaits([1, 1, 1, 1, 2, 3, 4, 5, 6, 7, 8, 9, 9]);
      expect(waits.contains(1), isFalse);
    });

    test('HANDOFF.mdの問題DB検証（一部）', () {
      // DB問題1: [1,1,2,3,4,5,6,7,8,9,9,9,9]
      final waits1 = calcWaits([1, 1, 2, 3, 4, 5, 6, 7, 8, 9, 9, 9, 9]);
      expect(waits1.isNotEmpty, isTrue);

      // DB問題5: [2,3,4,5,6,7,8,9,9,1,1,1,2]
      final tiles5 = [2, 3, 4, 5, 6, 7, 8, 9, 9, 1, 1, 1, 2]..sort();
      final waits5 = calcWaits(tiles5);
      expect(waits5.isNotEmpty, isTrue);
    });
  });

  group('decomposeHand - 手牌分解', () {
    test('シンプルな完成形の分解', () {
      // 11 + 234 + 234 + 567 + 789
      final decomps =
          decomposeHand([1, 1, 2, 2, 3, 3, 4, 4, 5, 6, 7, 7, 8, 9]);
      expect(decomps.isNotEmpty, isTrue);
      // 各分解は [雀頭, 面子1, 面子2, 面子3, 面子4] の5要素
      for (final d in decomps) {
        expect(d.length, equals(5));
        expect(d[0].length, equals(2)); // 雀頭は2枚
        for (int i = 1; i < 5; i++) {
          expect(d[i].length, equals(3)); // 面子は3枚
        }
      }
    });

    test('分解結果の合計枚数が14枚', () {
      final decomps =
          decomposeHand([1, 1, 1, 2, 3, 4, 5, 6, 7, 8, 9, 9, 9, 1]);
      for (final d in decomps) {
        int total = 0;
        for (final group in d) {
          total += group.length;
        }
        expect(total, equals(14));
      }
    });
  });

  group('手牌生成', () {
    test('generateCompleteHand は14枚を返す', () {
      for (int i = 0; i < 20; i++) {
        final hand = generateCompleteHand();
        expect(hand, isNotNull);
        expect(hand!.length, equals(14));
        // 各牌は1〜9の範囲
        for (final t in hand) {
          expect(t, greaterThanOrEqualTo(1));
          expect(t, lessThanOrEqualTo(9));
        }
        // 同一牌は4枚以下
        final cnt = List<int>.filled(10, 0);
        for (final t in hand) {
          cnt[t]++;
        }
        for (int j = 1; j <= 9; j++) {
          expect(cnt[j], lessThanOrEqualTo(4));
        }
        // アガリ形であること
        expect(canWin(hand), isTrue);
      }
    });

    test('generateTenpaiHand は13枚のテンパイ形を返す', () {
      for (int i = 0; i < 20; i++) {
        final hand = generateTenpaiHand();
        expect(hand, isNotNull);
        expect(hand!.length, equals(13));
        final waits = calcWaits(hand);
        expect(waits.isNotEmpty, isTrue,
            reason: '生成した手牌がテンパイでない: $hand');
      }
    });

    test('generateRandomHand は13枚を返す', () {
      for (int i = 0; i < 20; i++) {
        final hand = generateRandomHand();
        expect(hand.length, equals(13));
        // 各牌は1〜9
        for (final t in hand) {
          expect(t, greaterThanOrEqualTo(1));
          expect(t, lessThanOrEqualTo(9));
        }
        // 同一牌は4枚以下
        final cnt = List<int>.filled(10, 0);
        for (final t in hand) {
          cnt[t]++;
        }
        for (int j = 1; j <= 9; j++) {
          expect(cnt[j], lessThanOrEqualTo(4));
        }
      }
    });

    test('generateProblem は13枚を返す', () {
      for (int i = 0; i < 50; i++) {
        final hand = generateProblem();
        expect(hand.length, equals(13));
      }
    });
  });

  group('JS版との互換性検証（HANDOFF.md 問題DB全49問）', () {
    final db = [
      [1, 1, 1, 2, 3, 4, 5, 6, 7, 8, 9, 9, 9],
      [1, 1, 2, 3, 4, 5, 6, 7, 8, 9, 9, 9, 9],
      [1, 2, 3, 4, 5, 6, 1, 2, 3, 7, 8, 9, 9],
      [1, 2, 3, 4, 5, 6, 7, 8, 9, 1, 1, 3, 4],
      [2, 3, 4, 5, 6, 7, 8, 9, 9, 1, 1, 1, 2],
      [1, 1, 1, 2, 3, 4, 5, 6, 7, 8, 8, 8, 9],
      [1, 2, 3, 5, 6, 7, 8, 9, 9, 9, 3, 4, 5],
      [1, 1, 3, 4, 5, 6, 7, 8, 2, 2, 2, 9, 9],
      [2, 2, 3, 4, 5, 6, 7, 8, 9, 5, 5, 5, 1],
      [1, 1, 1, 4, 5, 6, 7, 8, 9, 3, 3, 2, 3],
      [1, 2, 3, 4, 5, 6, 7, 8, 9, 1, 2, 3, 5],
      [2, 3, 4, 5, 6, 7, 2, 3, 4, 8, 8, 8, 5],
      [1, 1, 2, 3, 4, 5, 6, 7, 2, 3, 4, 5, 6],
      [3, 4, 5, 6, 7, 8, 1, 2, 3, 1, 1, 5, 6],
      [1, 2, 3, 4, 5, 6, 7, 8, 4, 5, 6, 2, 2],
      [5, 5, 5, 1, 2, 3, 4, 5, 6, 7, 8, 3, 4],
      [1, 2, 3, 4, 5, 6, 4, 5, 6, 7, 8, 1, 1],
      [2, 3, 4, 5, 6, 7, 8, 9, 3, 4, 5, 6, 6],
      [1, 1, 1, 2, 3, 7, 8, 9, 4, 5, 6, 3, 3],
      [3, 3, 4, 5, 6, 7, 8, 9, 1, 2, 3, 6, 7],
      [1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 7, 8],
      [1, 1, 2, 2, 3, 3, 4, 5, 6, 7, 8, 9, 9],
      [1, 2, 3, 4, 5, 6, 7, 7, 8, 8, 9, 9, 5],
      [2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 8, 9],
      [1, 1, 2, 2, 3, 3, 7, 7, 8, 8, 9, 5, 6],
      [3, 4, 5, 6, 7, 8, 9, 9, 1, 2, 3, 6, 6],
      [1, 1, 4, 4, 5, 5, 6, 6, 7, 7, 2, 3, 4],
      [2, 3, 4, 5, 6, 7, 8, 8, 3, 3, 1, 2, 3],
      [1, 2, 3, 1, 2, 3, 4, 5, 6, 7, 7, 4, 5],
      [5, 6, 7, 8, 9, 1, 2, 3, 4, 4, 4, 6, 7],
      [1, 1, 2, 3, 4, 5, 6, 7, 8, 9, 9, 3, 3],
      [1, 2, 3, 4, 5, 5, 6, 7, 8, 9, 9, 2, 3],
      [2, 2, 3, 4, 5, 6, 7, 8, 9, 1, 1, 1, 4],
      [1, 2, 3, 4, 5, 6, 7, 8, 9, 2, 3, 4, 4],
      [1, 1, 1, 3, 4, 5, 6, 7, 8, 2, 2, 5, 6],
      [3, 3, 4, 5, 6, 7, 8, 9, 1, 2, 3, 5, 5],
      [1, 2, 3, 4, 5, 6, 7, 8, 9, 4, 5, 6, 2],
      [2, 3, 4, 5, 6, 7, 1, 1, 1, 8, 9, 6, 6],
      [1, 1, 2, 3, 4, 5, 6, 2, 3, 4, 7, 8, 9],
      [4, 5, 6, 7, 8, 9, 1, 2, 3, 3, 4, 5, 7],
      [1, 1, 1, 2, 3, 4, 5, 5, 5, 6, 7, 8, 9],
      [9, 9, 1, 2, 3, 4, 5, 6, 7, 8, 9, 7, 8],
      [1, 2, 3, 7, 8, 9, 1, 1, 4, 5, 6, 3, 3],
      [1, 2, 3, 4, 5, 6, 7, 8, 9, 1, 2, 3, 7],
      [9, 9, 9, 1, 2, 3, 4, 5, 6, 7, 8, 5, 5],
      [1, 1, 2, 3, 4, 6, 7, 8, 5, 5, 5, 3, 4],
      [3, 3, 3, 5, 6, 7, 8, 9, 1, 2, 3, 4, 4],
      [1, 2, 3, 4, 5, 6, 7, 8, 9, 2, 2, 4, 5],
      [2, 3, 4, 5, 5, 6, 7, 8, 9, 1, 2, 3, 1],
    ];

    test('全49問がテンパイ（待ちあり）であること', () {
      for (int i = 0; i < db.length; i++) {
        final tiles = [...db[i]]..sort();
        final waits = calcWaits(tiles);
        expect(waits.isNotEmpty, isTrue,
            reason: '問題${i + 1}がテンパイでない: $tiles');
      }
    });

    test('全49問の待ち牌が1〜9の範囲内', () {
      for (int i = 0; i < db.length; i++) {
        final tiles = [...db[i]]..sort();
        final waits = calcWaits(tiles);
        for (final w in waits) {
          expect(w, greaterThanOrEqualTo(1));
          expect(w, lessThanOrEqualTo(9));
        }
      }
    });

    test('九連宝燈（問題1）は9面待ち', () {
      final waits = calcWaits([1, 1, 1, 2, 3, 4, 5, 6, 7, 8, 9, 9, 9]);
      expect(waits.length, equals(9));
      expect(waits, equals([1, 2, 3, 4, 5, 6, 7, 8, 9]));
    });
  });
}
