import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:io' show Platform;

/// AdMobリワード広告の管理サービス。
///
/// - アプリ起動時に [init] を呼んでSDKを初期化
/// - [loadRewardedAd] でリワード広告をプリロード
/// - [showRewardedAd] で表示、視聴完了時にコールバック
class AdService {
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

  void dispose() {
    _rewardedAd?.dispose();
    _rewardedAd = null;
  }
}
