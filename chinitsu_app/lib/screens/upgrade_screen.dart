import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/quota_service.dart';
import '../services/ad_service.dart';

/// 無料上限到達時に表示する画面。
/// リワード広告視聴で練習問題またはTAを追加できる。
class UpgradeScreen extends StatefulWidget {
  final QuotaService quota;
  final String requestedMode; // 'free' | 'time'

  const UpgradeScreen({
    super.key,
    required this.quota,
    required this.requestedMode,
  });

  @override
  State<UpgradeScreen> createState() => _UpgradeScreenState();
}

class _UpgradeScreenState extends State<UpgradeScreen> {
  bool _loading = false;

  Future<void> _watchAd() async {
    setState(() => _loading = true);
    final rewarded = await AdService.instance.showRewarded();
    if (rewarded && mounted) {
      if (widget.requestedMode == 'time') {
        await widget.quota.grantRewardTa();
      } else {
        await widget.quota.grantRewardPractice();
      }
      if (mounted) Navigator.pop(context, true); // trueで続行許可
    } else {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTa = widget.requestedMode == 'time';

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(flex: 2),
              Text(
                '無料問題の上限に達しました',
                style: AppTheme.titleStyle(fontSize: 22),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                '累計${widget.quota.totalUsed}問プレイ済み\n'
                '（無料上限：${QuotaService.freeTotalLimit}問）',
                style: AppTheme.bodyStyle(fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              // 動画を見て続ける
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _watchAd,
                  icon: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.play_circle_outline),
                  label: Text(
                    isTa ? '動画を見てTA1回追加' : '動画を見て${QuotaService.rewardPracticeGrant}問追加',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // リワード残量表示
              if (widget.quota.rewardPracticeRemaining > 0)
                Text(
                  'リワード残：練習${widget.quota.rewardPracticeRemaining}問',
                  style: AppTheme.bodyStyle(fontSize: 12),
                ),
              if (widget.quota.rewardTaRemaining > 0)
                Text(
                  'リワード残：TA${widget.quota.rewardTaRemaining}回',
                  style: AppTheme.bodyStyle(fontSize: 12),
                ),
              const SizedBox(height: 32),
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('ホームに戻る'),
              ),
              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }
}
