import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'tile_image.dart';

/// 1〜9の待ち牌選択ボタン列。
class TileSelector extends StatelessWidget {
  final String suit;
  final Set<int> selected;
  final List<int> waits;
  final bool answered;
  final ValueChanged<int> onToggle;

  const TileSelector({
    super.key,
    required this.suit,
    required this.selected,
    required this.waits,
    required this.answered,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      alignment: WrapAlignment.center,
      children: List.generate(9, (i) {
        final n = i + 1;
        final isSel = selected.contains(n);
        final isCorrectWait = answered && waits.contains(n);
        final isWrongSelection = answered && isSel && !waits.contains(n);
        final isMissed = answered && !isSel && waits.contains(n);

        Color bgColor;
        if (answered) {
          if (isCorrectWait && isSel) {
            bgColor = AppColors.greenLight;
          } else if (isWrongSelection) {
            bgColor = AppColors.red;
          } else if (isMissed) {
            bgColor = AppColors.gold.withValues(alpha: 0.5);
          } else {
            bgColor = AppColors.paper2;
          }
        } else {
          bgColor = isSel ? AppColors.ink : AppColors.paper2;
        }

        return GestureDetector(
          onTap: () => onToggle(n),
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.tileBorder),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 32,
                    child: TileImage(suit: suit, number: n, height: 32),
                  ),
                  Text(
                    '$n',
                    style: TextStyle(
                      fontSize: 10,
                      color: (!answered && isSel)
                          ? AppColors.paper
                          : AppColors.ink,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}
