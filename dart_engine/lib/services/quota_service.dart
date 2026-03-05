import 'package:shared_preferences/shared_preferences.dart';

/// 無料版のクォータ（問題数制限）を管理するサービス。
///
/// - 累計 [freeTotalLimit] 問まで無料
/// - 以降はリワード広告視聴で [rewardPracticeGrant] 問
///   または [rewardTaGrant] 回のTA追加
class QuotaService {
  static const int freeTotalLimit = 50;
  static const int rewardPracticeGrant = 20;
  static const int rewardTaGrant = 1;

  static const String _keyTotalUsed = 'chinitsu_total_play_count';
  static const String _keyRewardPractice = 'chinitsu_reward_practice_remaining';
  static const String _keyRewardTa = 'chinitsu_reward_ta_remaining';

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// 累計プレイ済み問題数
  int get totalUsed => _prefs.getInt(_keyTotalUsed) ?? 0;

  /// リワードで獲得した練習問題の残数
  int get rewardPracticeRemaining =>
      _prefs.getInt(_keyRewardPractice) ?? 0;

  /// リワードで獲得したTA回数の残数
  int get rewardTaRemaining => _prefs.getInt(_keyRewardTa) ?? 0;

  /// 無料枠の残り問題数
  int get freeRemaining => (freeTotalLimit - totalUsed).clamp(0, freeTotalLimit);

  /// プレミアムユーザーかどうか（将来IAP連携）
  bool isPremium = false;

  /// 練習モードの問題をプレイ可能か判定
  bool canPlayPractice() {
    if (isPremium) return true;
    if (totalUsed < freeTotalLimit) return true;
    if (rewardPracticeRemaining > 0) return true;
    return false;
  }

  /// TAモードをプレイ可能か判定
  bool canPlayTa() {
    if (isPremium) return true;
    if (totalUsed < freeTotalLimit) return true;
    if (rewardTaRemaining > 0) return true;
    return false;
  }

  /// 練習問題1問消費（loadQ時に呼ぶ）
  Future<void> consumePractice() async {
    if (isPremium) return;
    if (totalUsed < freeTotalLimit) {
      await _prefs.setInt(_keyTotalUsed, totalUsed + 1);
    } else if (rewardPracticeRemaining > 0) {
      await _prefs.setInt(
          _keyRewardPractice, rewardPracticeRemaining - 1);
    }
  }

  /// TA1回消費（TA開始時に呼ぶ）
  /// TA中の個別問題は消費カウントしない（セッション単位）
  Future<void> consumeTa() async {
    if (isPremium) return;
    if (totalUsed < freeTotalLimit) {
      // 無料枠内：TAの問題数分をまとめてカウントはせず、
      // TA中の各問題でconsumePractice()を呼ぶ設計も可能。
      // ここではTA開始時の権利チェックのみ。
      return;
    }
    if (rewardTaRemaining > 0) {
      await _prefs.setInt(_keyRewardTa, rewardTaRemaining - 1);
    }
  }

  /// TA中の問題1問をカウント（無料枠内の場合のみ消費）
  Future<void> consumeTaQuestion() async {
    if (isPremium) return;
    if (totalUsed < freeTotalLimit) {
      await _prefs.setInt(_keyTotalUsed, totalUsed + 1);
    }
    // リワードTA分はセッション単位なので個別カウントしない
  }

  /// リワード広告視聴完了: 練習問題追加
  Future<void> grantRewardPractice() async {
    await _prefs.setInt(
        _keyRewardPractice, rewardPracticeRemaining + rewardPracticeGrant);
  }

  /// リワード広告視聴完了: TA追加
  Future<void> grantRewardTa() async {
    await _prefs.setInt(_keyRewardTa, rewardTaRemaining + rewardTaGrant);
  }
}
