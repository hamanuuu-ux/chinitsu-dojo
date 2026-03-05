import 'package:flutter_test/flutter_test.dart';
import 'package:chinitsu_dojo/engine/chinitsu_engine.dart';

void main() {
  test('calcWaits returns correct waits for simple hand', () {
    // 1112345678999 → waits: [1,9]
    final tiles = [1, 1, 1, 2, 3, 4, 5, 6, 7, 8, 9, 9, 9];
    final waits = calcWaits(tiles);
    expect(waits, containsAll([1, 9]));
    expect(waits.length, 2);
  });
}
