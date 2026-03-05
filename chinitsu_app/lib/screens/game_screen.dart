import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../models/stats.dart';
import '../models/game_state.dart';
import '../engine/chinitsu_engine.dart' as engine;
import '../services/quota_service.dart';
import '../widgets/hand_display.dart';
import '../widgets/tile_selector.dart';
import '../widgets/status_bar.dart';
import '../widgets/toast_overlay.dart';
import 'result_screen.dart';

/// 既出DB問題のインデックスをSharedPreferencesで管理。
class _SeenDbTracker {
  static const _key = 'chinitsu_seen_db_indices';
  final Set<int> _seen = {};

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_key) ?? '';
    if (str.isNotEmpty) {
      // BUG-07: guard against corrupted data
      try {
        _seen.addAll(str.split(',').map(int.parse));
      } catch (_) {
        _seen.clear();
      }
    }
  }

  /// DBから未出題のインデックスをランダムに1つ返す。全て既出ならnull。
  int? pickUnseen() {
    final total = engine.problemDb.length;
    final unseen = <int>[];
    for (int i = 0; i < total; i++) {
      if (!_seen.contains(i)) unseen.add(i);
    }
    if (unseen.isEmpty) return null;
    return unseen[Random().nextInt(unseen.length)];
  }

  Future<void> markSeen(int idx) async {
    _seen.add(idx);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, _seen.join(','));
  }
}

class GameScreen extends StatefulWidget {
  final String mode; // 'free' | 'time'
  final String suit; // 'm' | 'p' | 's'
  final Stats stats;
  final QuotaService quota;

  const GameScreen({
    super.key,
    required this.mode,
    required this.suit,
    required this.stats,
    required this.quota,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late GameState _gs;
  Timer? _timer;
  String _feedback = '';
  final _seenDb = _SeenDbTracker();
  bool _ready = false;
  bool _showingResult = false; // BUG-10: guard against double navigation

  @override
  void initState() {
    super.initState();
    _gs = GameState(mode: widget.mode, suit: widget.suit);
    _initAndLoad();
  }

  Future<void> _initAndLoad() async {
    await _seenDb.load();
    // BUG-04: consume TA session at start
    if (_gs.isTimeAttack) {
      await widget.quota.consumeTa();
    }
    _loadQuestion();
    setState(() => _ready = true);
    // BUG-22: start timer AFTER loading completes
    if (_gs.isTimeAttack) {
      _gs.timerSec = timerSeconds;
      _startTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_showingResult) return; // BUG-10: prevent double-fire
      setState(() {
        _gs.timerSec--;
        if (_gs.timerSec <= 0) {
          _gs.timerSec = 0; // BUG-20: prevent negative display
          _timer?.cancel();
          _showResult();
        }
      });
    });
  }

  /// 出題ロジック: 無料50問内はDB、以降はランダム生成。
  void _loadQuestion() {
    List<int> tiles;

    if (widget.quota.totalUsed < QuotaService.freeTotalLimit) {
      // 無料枠内: DBから未出題を選択
      final idx = _seenDb.pickUnseen();
      if (idx != null) {
        tiles = List<int>.from(engine.problemDb[idx]);
        _seenDb.markSeen(idx);
      } else {
        // DB全問既出（50問で200問DBなので通常は到達しない）
        tiles = engine.generateProblem();
      }
    } else {
      // 無料枠超過（リワード後）: ランダム生成
      tiles = engine.generateProblem();
    }

    final waits = engine.calcWaits(tiles);
    setState(() {
      _gs.currentTiles = tiles;
      _gs.waits = waits;
      _gs.resetForNewQuestion();
      // BUG-09: removed _gs.total++ here; moved to _confirm()
      _feedback = '';
    });
  }

  void _toggleTile(int n) {
    if (_gs.answered) return;
    setState(() {
      if (_gs.notTenpaiSelected) _gs.notTenpaiSelected = false;
      if (_gs.selected.contains(n)) {
        _gs.selected.remove(n);
      } else {
        _gs.selected.add(n);
      }
    });
  }

  void _toggleNotTenpai() {
    if (_gs.answered) return;
    setState(() {
      _gs.notTenpaiSelected = !_gs.notTenpaiSelected;
      if (_gs.notTenpaiSelected) _gs.selected.clear();
    });
  }

  void _confirm() {
    if (_gs.answered) return;

    // BUG-16: prevent empty submission (no tiles selected and not-tenpai not toggled)
    if (_gs.selected.isEmpty && !_gs.notTenpaiSelected) return;

    // BUG-03: guard against null questionStart
    final start = _gs.questionStart;
    final elapsed = start != null
        ? max(0.0, DateTime.now().difference(start).inMilliseconds / 1000.0)
        : 0.0;

    final waits = _gs.waits;
    final isTenpai = waits.isNotEmpty;

    // BUG-09: increment total on answer, not on load
    _gs.total++;

    bool perfect;
    if (_gs.notTenpaiSelected) {
      perfect = !isTenpai;
    } else {
      final selectedSet = _gs.selected;
      final correctSet = waits.toSet();
      perfect = selectedSet.length == correctSet.length &&
          selectedSet.containsAll(correctSet);
    }

    final gain = perfect ? (scoreBaseTime - elapsed).round().clamp(0, 60) : 0;
    if (perfect) {
      _gs.score += gain;
      _gs.correct++;
    }

    // 統計更新
    final newBadges = widget.stats.updateAfterAnswer(
      perfect: perfect,
      elapsed: elapsed,
      waitsCount: waits.length,
      isTenpai: isTenpai,
      isTA: _gs.isTimeAttack,
    );
    widget.stats.save();

    // クォータ消費
    if (_gs.isTimeAttack) {
      widget.quota.consumeTaQuestion();
    } else {
      widget.quota.consumePractice();
    }

    setState(() {
      _gs.answered = true;
      if (perfect) {
        _feedback = waits.isEmpty
            ? '正解！テンパイではありません'
            : '正解！+$gain点（${elapsed.toStringAsFixed(1)}秒）';
      } else {
        final correctStr =
            waits.isEmpty ? 'テンパイではない' : '待ち: ${waits.join(",")}';
        _feedback = '不正解… $correctStr';
      }
    });

    // バッジ獲得トースト
    for (final badge in newBadges) {
      showBadgeToast(context, badge.icon, badge.name);
    }
  }

  void _next() {
    if (_gs.isTimeAttack && _gs.timerSec <= 0) {
      _showResult();
      return;
    }
    // BUG-13: check quota mid-session for practice mode
    if (!_gs.isTimeAttack && !widget.quota.canPlayPractice()) {
      _showResult();
      return;
    }
    _loadQuestion();
  }

  void _showResult() {
    if (_showingResult) return; // BUG-10: prevent double navigation
    _showingResult = true;
    _timer?.cancel();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ResultScreen(
          mode: _gs.mode,
          score: _gs.score,
          correct: _gs.correct,
          total: _gs.total,
          stats: widget.stats,
          suit: widget.suit,
          quota: widget.quota, // BUG-02: pass quota for "Play Again"
        ),
      ),
    );
  }

  String get _suitLabel {
    switch (widget.suit) {
      case 'm':
        return 'マンズ';
      case 'p':
        return 'ピンズ';
      case 's':
        return 'ソーズ';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ステータスバー
            StatusBar(
              score: _gs.score,
              correct: _gs.correct,
              total: _gs.total,
              isTimeAttack: _gs.isTimeAttack,
              timerSec: _gs.timerSec,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    // モードタグ
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: _gs.isTimeAttack
                            ? AppColors.red
                            : AppColors.greenLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _gs.isTimeAttack
                            ? 'タイムアタック'
                            : 'れんしゅう（$_suitLabel）',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // 問題番号 (BUG-09: total is answered count, show +1 for current)
                    Text(
                      '問題 ${_gs.total + 1}',
                      style: AppTheme.bodyStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    // 手牌表示
                    HandDisplay(tiles: _gs.currentTiles, suit: _gs.suit),
                    const SizedBox(height: 16),
                    // 待ち選択ボタン
                    TileSelector(
                      suit: _gs.suit,
                      selected: _gs.selected,
                      waits: _gs.waits,
                      answered: _gs.answered,
                      onToggle: _toggleTile,
                    ),
                    const SizedBox(height: 8),
                    // テンパイではないボタン
                    _buildNotTenpaiButton(),
                    const SizedBox(height: 12),
                    // フィードバック
                    if (_feedback.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          _feedback,
                          style: AppTheme.bodyStyle(
                            fontSize: 14,
                            color: _feedback.startsWith('正解')
                                ? AppColors.greenLight
                                : AppColors.red,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    const SizedBox(height: 8),
                    // ボタン群
                    if (!_gs.answered)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _confirm,
                          child: const Text('答え合わせ'),
                        ),
                      ),
                    if (_gs.answered) ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _next,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.greenLight,
                          ),
                          child: const Text('次の問題 →'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          _timer?.cancel();
                          Navigator.pop(context);
                        },
                        child: const Text('◁ ホームに戻る'),
                      ),
                    ],
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotTenpaiButton() {
    final active = _gs.notTenpaiSelected;
    final isCorrect = _gs.answered && _gs.waits.isEmpty;

    Color bgColor;
    if (_gs.answered) {
      if (isCorrect && active) {
        bgColor = AppColors.greenLight;
      } else if (active && !isCorrect) {
        bgColor = AppColors.red;
      } else if (!active && _gs.waits.isEmpty) {
        bgColor = AppColors.gold.withValues(alpha: 0.5);
      } else {
        bgColor = AppColors.paper2;
      }
    } else {
      bgColor = active ? AppColors.green : AppColors.paper2;
    }

    return GestureDetector(
      onTap: _toggleNotTenpai,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.green),
        ),
        child: Text(
          'テンパイではない',
          style: TextStyle(
            fontSize: 14,
            color: (!_gs.answered && active) ? Colors.white : AppColors.ink,
          ),
        ),
      ),
    );
  }
}
