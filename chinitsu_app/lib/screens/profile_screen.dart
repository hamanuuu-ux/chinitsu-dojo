import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../models/stats.dart';

class ProfileScreen extends StatelessWidget {
  final Stats stats;
  const ProfileScreen({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final rank = stats.currentRank;
    final progress = stats.calcRankProgress();

    return Scaffold(
      appBar: AppBar(
        title: const Text('プロフィール'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 段位カード
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.paper2,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(rank.name,
                      style:
                          AppTheme.titleStyle(fontSize: 32, color: AppColors.gold)),
                  Text(rank.sub, style: AppTheme.bodyStyle(fontSize: 12)),
                  const SizedBox(height: 8),
                  Text('RP ${stats.rp}',
                      style:
                          AppTheme.bodyStyle(fontSize: 18, color: AppColors.gold)),
                  if (progress.nextName != null) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress.pct / 100,
                        backgroundColor: AppColors.paper3,
                        valueColor:
                            const AlwaysStoppedAnimation(AppColors.gold),
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('次: ${progress.nextName}',
                        style: AppTheme.bodyStyle(fontSize: 11)),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            // 累計統計
            _sectionTitle('累計統計'),
            _statRow('問題数', '${stats.totalQ}問'),
            _statRow('正解数', '${stats.totalCorrect}問'),
            _statRow('正解率', '${stats.accuracyPercent}%'),
            _statRow('累計スコア', '${stats.totalScore}点'),
            _statRow('最大連続正解', '${stats.maxStreak}問'),
            const SizedBox(height: 16),
            // TA統計
            _sectionTitle('タイムアタック統計'),
            _statRow('TA問題数', '${stats.taTotalQ}問'),
            _statRow('TA正解率', '${stats.taAccuracyPercent}%'),
            _statRow('TA最高スコア', '${stats.bestTAScore}点'),
            _statRow('TA累計スコア', '${stats.taTotalScore}点'),
            const SizedBox(height: 16),
            // Xシェアボタン
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _shareToX(context),
              icon: const Text('𝕏', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              label: const Text('プロフィールをシェア'),
            ),
            const SizedBox(height: 16),
            // バッジ一覧
            _sectionTitle('バッジ（${stats.earnedBadges.length}/${badges.length}）'),
            ...badgeCategories.map((cat) => _buildBadgeCategory(cat)),
          ],
        ),
      ),
    );
  }

  Future<void> _shareToX(BuildContext context) async {
    final rank = stats.currentRank;
    final buf = StringBuffer();
    buf.writeln('【清一色道場】プロフィール');
    buf.writeln('段位：${rank.name}（${rank.sub}）RP：${stats.rp}');
    buf.writeln('累計：${stats.totalQ}問 正解率${stats.accuracyPercent}%');
    buf.writeln('TA最高：${stats.bestTAScore}点 バッジ：${stats.earnedBadges.length}/${badges.length}');
    buf.writeln('#清一色道場 #メンチン道場 #麻雀');

    final uri = Uri.https('twitter.com', '/intent/tweet', {
      'text': buf.toString(),
    });
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        title,
        style: AppTheme.titleStyle(fontSize: 18),
      ),
    );
  }

  Widget _statRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTheme.bodyStyle(fontSize: 14)),
          Text(value,
              style: AppTheme.bodyStyle(fontSize: 14, color: AppColors.gold)),
        ],
      ),
    );
  }

  Widget _buildBadgeCategory(BadgeCategory cat) {
    final catBadges = badges.where((b) => b.cat == cat.key).toList();
    if (catBadges.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: Text(
            cat.label,
            style: AppTheme.bodyStyle(fontSize: 13, color: AppColors.gold),
          ),
        ),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: catBadges.map((b) {
            final earned = stats.earnedBadges.contains(b.id);
            return Tooltip(
              message: '${b.name}\n${b.desc}',
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: earned ? AppColors.paper2 : AppColors.paper3,
                  borderRadius: BorderRadius.circular(8),
                  border: earned
                      ? Border.all(color: AppColors.gold, width: 1.5)
                      : null,
                ),
                child: Center(
                  child: Text(
                    earned ? b.icon : '?',
                    style: TextStyle(
                      fontSize: earned ? 20 : 16,
                      color: earned ? null : AppColors.paper3,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
