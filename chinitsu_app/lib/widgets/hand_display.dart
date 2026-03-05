import 'package:flutter/material.dart';
import 'tile_image.dart';

/// 手牌13枚を横一列に表示するWidget。
class HandDisplay extends StatelessWidget {
  final List<int> tiles;
  final String suit;

  const HandDisplay({super.key, required this.tiles, required this.suit});

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: tiles.map((n) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1),
            child: TileImage(suit: suit, number: n, height: 72),
          );
        }).toList(),
      ),
    );
  }
}
