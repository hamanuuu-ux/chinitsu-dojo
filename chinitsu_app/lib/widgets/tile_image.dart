import 'package:flutter/material.dart';

/// スーツキー ('m', 'p', 's') を画像ファイル名のプレフィックスに変換
String _suitPrefix(String suit) {
  switch (suit) {
    case 'm':
      return 'man';
    case 'p':
      return 'pin';
    case 's':
      return 'sou';
    default:
      return 'man';
  }
}

/// 牌画像Widget。suit ('m'/'p'/'s') と number (1-9) を指定。
class TileImage extends StatelessWidget {
  final String suit;
  final int number;
  final double? height;

  const TileImage({
    super.key,
    required this.suit,
    required this.number,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final prefix = _suitPrefix(suit);
    return Image.asset(
      'assets/tiles/$prefix$number-66-90-s.png',
      height: height,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
    );
  }
}
