import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../models/stats.dart';
import '../services/quota_service.dart';
import '../widgets/toast_overlay.dart';
import 'game_screen.dart';

class ResultScreen extends StatefulWidget {
  final String mode;
  final int score;
  final int correct;
  final int total;
  final Stats stats;
  final String suit;
  final QuotaService quota;

  const ResultScreen({
    super.key,
    required this.mode,
    required this.score,
    required this.correct,
    required this.total,
    required this.stats,
    required this.suit,
    required this.quota,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  int _rpDelta = 0;
  int _usedBaseline = 0;

  int _prevRankIdx = 0;

  @override
  void initState() {
    super.initState();
    if (widget.mode == 'time') {
      _usedBaseline = widget.stats.currentBaseline;
      _prevRankIdx = widget.stats.rankIdx; // BUG-05: use rankIdx directly
      final result = widget.stats.updateRPAfterTA(widget.score);
      _rpDelta = result.rpDelta;
      final rankBadges = widget.stats.checkRankBadges(); // BUG-15: capture result
      widget.stats.save();

      // 段位変動トースト + バッジトースト（initState後の次フレームで表示）
      final newRankIdx = widget.stats.rankIdx;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        // BUG-15: show rank/TA badge toasts
        for (final badge in rankBadges) {
          showBadgeToast(context, badge.icon, badge.name);
        }
        // BUG-01: fix inverted direction (lower index = higher rank)
        if (newRankIdx != _prevRankIdx) {
          final newRank = ranks[newRankIdx];
          if (newRankIdx < _prevRankIdx) {
            showRankUpToast(context, newRank.name);
          } else {
            showRankDownToast(context, newRank.name);
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final rank = widget.stats.currentRank;
    final isTA = widget.mode == 'time';
    final comment = Stats.resultComment(widget.score);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(flex: 1),
              // 段位
              Text(
                rank.name,
                style: AppTheme.titleStyle(fontSize: 40, color: AppColors.gold),
              ),
              Text(
                rank.sub,
                style: AppTheme.bodyStyle(fontSize: 14),
              ),
              const SizedBox(height: 24),
              // 結果
              _resultRow('スコア', '${widget.score}', '点'),
              _resultRow('正解問題', '${widget.correct}', '問'),
              _resultRow('挑戦問題', '${widget.total}', '問'),
              const SizedBox(height: 16),
              // コメント
              Text(
                comment,
                style: AppTheme.bodyStyle(fontSize: 13),
                textAlign: TextAlign.center,
              ),
              // RP変動（TAのみ）
              if (isTA) ...[
                const SizedBox(height: 16),
                Text(
                  '段位：${rank.name}　RP：${widget.stats.rp}　TA累計${widget.stats.taTotalQ}問',
                  style: AppTheme.bodyStyle(fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  _rpDelta >= 0
                      ? 'RP +$_rpDelta（基準：$_usedBaseline）'
                      : 'RP $_rpDelta（基準：$_usedBaseline）',
                  style: AppTheme.bodyStyle(
                    fontSize: 16,
                    color:
                        _rpDelta >= 0 ? AppColors.rpPlus : AppColors.rpMinus,
                  ),
                ),
              ],
              const SizedBox(height: 32),
              // Xシェアボタン
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _shareToX,
                  icon: const Text('𝕏', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  label: const Text('結果をシェア'),
                ),
              ),
              const SizedBox(height: 16),
              // ボタン
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // BUG-02: pushReplacement to start new game session
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => GameScreen(
                          mode: widget.mode,
                          suit: widget.suit,
                          stats: widget.stats,
                          quota: widget.quota,  // BUG-02
                        ),
                      ),
                    );
                  },
                  child: const Text('もう一度'),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('ホームに戻る'),
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _shareToX() async {
    final rank = widget.stats.currentRank;
    final isTA = widget.mode == 'time';

    final buf = StringBuffer();
    buf.writeln('【清一色道場】${isTA ? "タイムアタック" : "れんしゅう"}結果');
    buf.writeln('段位：${rank.name}（${rank.sub}）');
    buf.writeln('スコア：${widget.score}点 正解：${widget.correct}/${widget.total}問');
    if (isTA) {
      buf.writeln('RP：${widget.stats.rp}（${_rpDelta >= 0 ? "+$_rpDelta" : "$_rpDelta"}）');
    }
    buf.writeln('#清一色道場 #メンチン道場 #麻雀');

    final uri = Uri.https('twitter.com', '/intent/tweet', {
      'text': buf.toString(),
    });
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _resultRow(String label, String value, String unit) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label,
              style: AppTheme.bodyStyle(fontSize: 14)),
          const SizedBox(width: 12),
          Text(value,
              style: AppTheme.titleStyle(fontSize: 28)),
          Text(unit, style: AppTheme.bodyStyle(fontSize: 14)),
        ],
      ),
    );
  }
}
