import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'models/stats.dart';
import 'services/quota_service.dart';
import 'services/ad_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 縦向き固定
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  runApp(const ChinitsuApp());
}

class ChinitsuApp extends StatelessWidget {
  const ChinitsuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '清一色道場',
      theme: AppTheme.theme,
      home: const AppRoot(),
      debugShowCheckedModeBanner: false,
    );
  }
}

/// アプリ全体のルートWidget。Stats読み込み後にホーム画面を表示。
class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  final Stats _stats = Stats();
  final QuotaService _quota = QuotaService();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _stats.load();
    await _quota.init();
    // AdMob初期化（失敗してもアプリは動作する）
    try {
      await AdService.instance.init();
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return HomeScreen(stats: _stats, quota: _quota);
  }
}
