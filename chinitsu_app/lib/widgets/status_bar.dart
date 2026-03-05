import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// ゲーム中のステータスバー（スコア / 正解 / 問題 / 残り時間）。
class StatusBar extends StatelessWidget {
  final int score;
  final int correct;
  final int total;
  final bool isTimeAttack;
  final int timerSec;

  const StatusBar({
    super.key,
    required this.score,
    required this.correct,
    required this.total,
    this.isTimeAttack = false,
    this.timerSec = 0,
  });

  String _formatTime(int sec) {
    final m = sec ~/ 60;
    final s = sec % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.paper2,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem('スコア', '$score'),
          _statItem('正解', '$correct'),
          _statItem('問題', '$total'),
          if (isTimeAttack)
            _statItem('残り', _formatTime(timerSec),
                color: timerSec <= 10 ? AppColors.red : null),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, {Color? color}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: AppTheme.bodyStyle(fontSize: 10)),
        Text(value, style: AppTheme.bodyStyle(fontSize: 18, color: color)),
      ],
    );
  }
}
