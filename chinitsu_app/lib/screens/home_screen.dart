import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/stats.dart';
import '../services/quota_service.dart';
import 'game_screen.dart';
import 'legal_screen.dart';
import 'profile_screen.dart';
import 'upgrade_screen.dart';

class HomeScreen extends StatefulWidget {
  final Stats stats;
  final QuotaService quota;
  const HomeScreen({super.key, required this.stats, required this.quota});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _suit = 'm'; // デフォルト: マンズ

  Stats get stats => widget.stats;
  QuotaService get quota => widget.quota;

  void _startGame(String mode) async {
    // クォータチェック
    final canPlay = mode == 'time'
        ? quota.canPlayTa()
        : quota.canPlayPractice();

    if (!canPlay) {
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => UpgradeScreen(
            quota: quota,
            requestedMode: mode,
          ),
        ),
      );
      if (result != true) {
        setState(() {});
        return;
      }
    }

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GameScreen(
          mode: mode,
          suit: _suit,
          stats: stats,
          quota: quota,
        ),
      ),
    ).then((_) => setState(() {})); // 戻ってきたら段位表示を更新
  }

  void _openProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileScreen(stats: stats),
      ),
    ).then((_) => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    final rank = stats.currentRank;
    final progress = stats.calcRankProgress();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 16),
              // プロフィールボタン（右上）
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  onPressed: _openProfile,
                  icon: const Icon(Icons.person_outline, size: 28),
                  color: AppColors.ink,
                ),
              ),
              const Spacer(flex: 1),
              // タイトル
              Text(
                '清一色道場',
                style: AppTheme.titleStyle(fontSize: 36),
              ),
              const SizedBox(height: 8),
              Text(
                'チンイツ待ち当て練習',
                style: AppTheme.bodyStyle(fontSize: 14, color: AppColors.gold),
              ),
              const SizedBox(height: 32),
              // 段位表示
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.paper2,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      rank.name,
                      style: AppTheme.titleStyle(
                          fontSize: 28, color: AppColors.gold),
                    ),
                    Text(
                      rank.sub,
                      style: AppTheme.bodyStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'RP ${stats.rp}',
                      style: AppTheme.bodyStyle(
                          fontSize: 16, color: AppColors.gold),
                    ),
                    if (progress.nextName != null) ...[
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress.pct / 100,
                          backgroundColor: AppColors.paper3,
                          valueColor: const AlwaysStoppedAnimation(
                              AppColors.gold),
                          minHeight: 6,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '次: ${progress.nextName}',
                        style: AppTheme.bodyStyle(fontSize: 11),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // スーツ選択
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _suitButton('m', 'マンズ'),
                  const SizedBox(width: 12),
                  _suitButton('p', 'ピンズ'),
                  const SizedBox(width: 12),
                  _suitButton('s', 'ソーズ'),
                ],
              ),
              const SizedBox(height: 32),
              // モードボタン
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _startGame('free'),
                  child: const Text('れんしゅう', style: TextStyle(fontSize: 18)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _startGame('time'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.red,
                  ),
                  child: const Text('タイムアタック（2分）',
                      style: TextStyle(fontSize: 18)),
                ),
              ),
              const Spacer(flex: 2),
              // 法的リンク
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LegalScreen(
                          title: 'プライバシーポリシー',
                          content: privacyPolicyJa,
                        ),
                      ),
                    ),
                    child: Text('プライバシーポリシー',
                        style: AppTheme.bodyStyle(fontSize: 11)),
                  ),
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LegalScreen(
                          title: '利用規約',
                          content: termsOfServiceJa,
                        ),
                      ),
                    ),
                    child: Text('利用規約',
                        style: AppTheme.bodyStyle(fontSize: 11)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _suitButton(String suit, String label) {
    final selected = _suit == suit;
    return GestureDetector(
      onTap: () => setState(() => _suit = suit),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.ink : AppColors.paper2,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.ink, width: 1),
        ),
        child: Text(
          label,
          style: AppTheme.bodyStyle(
            fontSize: 14,
            color: selected ? AppColors.paper : AppColors.ink,
          ),
        ),
      ),
    );
  }
}
