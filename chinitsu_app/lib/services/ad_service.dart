import 'dart:async';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:io' show Platform;

/// AdMobリワード広告の管理サービス。
///
/// - アプリ起動時に [init] を呼んでSDKを初期化
/// - [loadRewardedAd] でリワード広告をプリロード
/// - [showRewardedAd] で表示、視聴完了時にコールバック
class AdService {
  AdService._();
  static final AdService instance = AdService._();

  RewardedAd? _rewardedAd;
  bool _isLoading = false;

  /// テスト用広告ユニットID（リリース時に本番IDに差し替え）
  String get _rewardedAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/5224354917'; // Android test
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/1712485313'; // iOS test
    }
    throw UnsupportedError('Unsupported platform');
  }

  /// AdMob SDK初期化
  Future<void> init() async {
    await MobileAds.instance.initialize();
    await loadRewardedAd();
  }

  /// リワード広告をプリロード
  Future<void> loadRewardedAd() async {
    if (_rewardedAd != null || _isLoading) return;
    _isLoading = true;

    await RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isLoading = false;
        },
        onAdFailedToLoad: (error) {
          _rewardedAd = null;
          _isLoading = false;
        },
      ),
    );
  }

  /// 広告がロード済みか
  bool get isAdReady => _rewardedAd != null;

  /// リワード広告を表示。視聴完了時に [onRewardEarned] が呼ばれる。
  /// 広告未ロードの場合は false を返す。
  Future<bool> showRewardedAd({
    required void Function() onRewardEarned,
    void Function()? onAdDismissed,
  }) async {
    if (_rewardedAd == null) return false;

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        onAdDismissed?.call();
        loadRewardedAd(); // 次の広告をプリロード
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _rewardedAd = null;
        loadRewardedAd();
      },
    );

    await _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) {
        onRewardEarned();
      },
    );

    return true;
  }

  /// シンプルなリワード表示。視聴完了でtrue、それ以外はfalse。
  Future<bool> showRewarded() async {
    if (_rewardedAd == null) {
      await loadRewardedAd();
      // ロード待ち（最大5秒）
      for (int i = 0; i < 50 && _rewardedAd == null; i++) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      if (_rewardedAd == null) return false;
    }

    bool rewarded = false;
    final completer = Completer<void>(); // BUG-11: use dart:async Completer

    // BUG-25: capture reference to avoid null race
    final ad = _rewardedAd!;
    _rewardedAd = null;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        loadRewardedAd();
        if (!completer.isCompleted) completer.complete();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        loadRewardedAd();
        if (!completer.isCompleted) completer.complete();
      },
    );

    await ad.show(
      onUserEarnedReward: (ad, reward) {
        rewarded = true;
      },
    );

    // BUG-11: add timeout to prevent infinite wait
    await completer.future.timeout(
      const Duration(seconds: 30),
      onTimeout: () {},
    );
    return rewarded;
  }

  void dispose() {
    _rewardedAd?.dispose();
    _rewardedAd = null;
  }
}
