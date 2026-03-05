import 'dart:io' show Platform;
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ATT（App Tracking Transparency）管理サービス。
///
/// iOS 14.5+でトラッキング許可を求める前に、
/// プレパーミッションダイアログを表示してオプトイン率を向上させる。
///
/// 使い方:
/// 1. 初回練習完了後に [shouldShowPreprompt] を確認
/// 2. true → プレパーミッション画面を表示
/// 3. ユーザーが「許可する」→ [requestTracking] を呼ぶ
/// 4. ユーザーが「今はしない」→ [dismissPreprompt] を呼ぶ
class AttService {
  static const String _keyPrepromptShown = 'chinitsu_att_preprompt_shown';

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// ATTのプレパーミッションを表示すべきか
  /// - iOS以外では常にfalse
  /// - 既に表示済みならfalse
  /// - ATTステータスが未確定(notDetermined)の場合のみtrue
  Future<bool> shouldShowPreprompt() async {
    if (!Platform.isIOS) return false;
    if (_prefs.getBool(_keyPrepromptShown) ?? false) return false;

    final status =
        await AppTrackingTransparency.trackingAuthorizationStatus;
    return status == TrackingStatus.notDetermined;
  }

  /// プレパーミッション表示済みとして記録（「今はしない」選択時）
  Future<void> dismissPreprompt() async {
    await _prefs.setBool(_keyPrepromptShown, true);
  }

  /// ATTトラッキング許可をリクエスト（iOSシステムダイアログ表示）
  /// プレパーミッションで「許可する」を選択した後に呼ぶ
  Future<TrackingStatus> requestTracking() async {
    await _prefs.setBool(_keyPrepromptShown, true);

    final status =
        await AppTrackingTransparency.requestTrackingAuthorization();
    return status;
  }

  /// 現在のATTステータスを取得
  Future<TrackingStatus> getStatus() async {
    if (!Platform.isIOS) return TrackingStatus.authorized;
    return await AppTrackingTransparency.trackingAuthorizationStatus;
  }

  /// トラッキングが許可されているか
  Future<bool> isTrackingAuthorized() async {
    final status = await getStatus();
    return status == TrackingStatus.authorized;
  }
}

/// プレパーミッション画面の設定値
class AttPrepromptConfig {
  /// 画面タイトル
  static const String title = '広告表示についてのお願い';

  /// メリット説明（箇条書き）
  static const List<String> benefits = [
    '興味に合った広告が表示され、無関係な広告が減ります',
    'あなたのデータは広告の最適化にのみ使用されます',
  ];

  /// 許可ボタンのテキスト
  static const String allowButtonText = '許可する';

  /// スキップボタンのテキスト
  static const String skipButtonText = '今はしない';
}
