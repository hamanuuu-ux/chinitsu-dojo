import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// ═══════════════════════════════════════
// 定数
// ═══════════════════════════════════════

const int scoreBaseTime = 60;
const int timerSeconds = 120;
const double tenpaiRatio = 0.7;

// ═══════════════════════════════════════
// 段位テーブル（21段階）
// ═══════════════════════════════════════

class Rank {
  final String name;
  final String sub;
  final int minRP;
  final int baseline;
  const Rank(this.name, this.sub, this.minRP, this.baseline);
}

const List<Rank> ranks = [
  Rank('十段', '清一色の化身', 50000, 1800),
  Rank('九段', '人外の領域', 42000, 1520),
  Rank('八段', '達人', 35000, 1230),
  Rank('七段', '免許皆伝', 29000, 940),
  Rank('六段', '鬼神の眼', 24000, 720),
  Rank('五段', '一流の境地', 19500, 540),
  Rank('四段', '上級者', 15500, 425),
  Rank('三段', '中上級', 12000, 320),
  Rank('二段', '中級を超えた', 9000, 240),
  Rank('初段', '有段者', 7000, 168),
  Rank('一級', '黒帯目前', 5200, 135),
  Rank('二級', '上級修行者', 4000, 108),
  Rank('三級', '中級修行者', 3000, 82),
  Rank('四級', '基礎固め', 2200, 60),
  Rank('五級', '成長中', 1500, 40),
  Rank('六級', 'コツを掴んだ', 1000, 26),
  Rank('七級', '慣れてきた', 650, 16),
  Rank('八級', '初心者卒業', 350, 9),
  Rank('九級', '入門者', 150, 4),
  Rank('十級', '見習い', 50, 1),
  Rank('無級', '修行を始めましょう', 0, 0),
];

// ═══════════════════════════════════════
// バッジシステム（100個・12カテゴリ）
// ═══════════════════════════════════════

class BadgeCategory {
  final String key;
  final String label;
  const BadgeCategory(this.key, this.label);
}

const List<BadgeCategory> badgeCategories = [
  BadgeCategory('streak', '連続正解'),
  BadgeCategory('total', '累計問題'),
  BadgeCategory('correct', '累計正解'),
  BadgeCategory('score', '累計スコア'),
  BadgeCategory('speed', '速答'),
  BadgeCategory('spdrun', '速答連続'),
  BadgeCategory('wait', '多面待ち'),
  BadgeCategory('nt', '非テンパイ'),
  BadgeCategory('ta', 'タイムアタック'),
  BadgeCategory('rank', '段位到達'),
  BadgeCategory('special', '特殊'),
  BadgeCategory('acc', '正解率'),
];

class Badge {
  final String id;
  final String cat;
  final String icon;
  final String name;
  final String desc;
  final bool Function(BadgeCheckState s) check;
  const Badge(this.id, this.cat, this.icon, this.name, this.desc, this.check);
}

/// バッジ判定に渡す状態
class BadgeCheckState {
  final int streak;
  final int totalQ;
  final int totalCorrect;
  final int totalScore;
  final int maxWaitsCorrect;
  final int notTenpaiCorrect;
  final int speedStreak;
  final int speed3Streak;
  final int multi5Count;
  final int multi7Count;
  final int bestTAScore;
  final int rankIdx;
  final int taTotalQ;
  final int perfectScoreStreak;
  final int rate; // 正解率 (0-100)
  final bool perfect;
  final double elapsed;
  final int gain;
  final int hour;

  const BadgeCheckState({
    required this.streak,
    required this.totalQ,
    required this.totalCorrect,
    required this.totalScore,
    required this.maxWaitsCorrect,
    required this.notTenpaiCorrect,
    required this.speedStreak,
    required this.speed3Streak,
    required this.multi5Count,
    required this.multi7Count,
    required this.bestTAScore,
    required this.rankIdx,
    required this.taTotalQ,
    required this.perfectScoreStreak,
    required this.rate,
    required this.perfect,
    required this.elapsed,
    required this.gain,
    required this.hour,
  });
}

final List<Badge> badges = [
  // ── 連続正解 (13) ──
  Badge('streak3', 'streak', '\u{1F525}', '三連', '3問連続正解', (s) => s.streak >= 3),
  Badge('streak5', 'streak', '\u{1F525}', '五連', '5問連続正解', (s) => s.streak >= 5),
  Badge('streak7', 'streak', '\u{1F525}', '七連', '7問連続正解', (s) => s.streak >= 7),
  Badge('streak10', 'streak', '\u{1F525}', '十連', '10問連続正解', (s) => s.streak >= 10),
  Badge('streak15', 'streak', '\u{1F31F}', '十五連', '15問連続正解', (s) => s.streak >= 15),
  Badge('streak20', 'streak', '\u{1F31F}', '二十連', '20問連続正解', (s) => s.streak >= 20),
  Badge('streak30', 'streak', '\u{1F31F}', '三十連', '30問連続正解', (s) => s.streak >= 30),
  Badge('streak50', 'streak', '\u{1F48E}', '五十連', '50問連続正解', (s) => s.streak >= 50),
  Badge('streak75', 'streak', '\u{1F48E}', '七十五連', '75問連続正解', (s) => s.streak >= 75),
  Badge('streak100', 'streak', '\u{1F451}', '百連', '100問連続正解', (s) => s.streak >= 100),
  Badge('streak150', 'streak', '\u{1F451}', '百五十連', '150問連続正解', (s) => s.streak >= 150),
  Badge('streak200', 'streak', '\u{1F451}', '二百連', '200問連続正解', (s) => s.streak >= 200),
  Badge('streak500', 'streak', '\u{1F3C6}', '五百連', '500問連続正解', (s) => s.streak >= 500),
  // ── 累計問題 (13) ──
  Badge('q10', 'total', '\u{1F4D6}', '十問', '累計10問', (s) => s.totalQ >= 10),
  Badge('q50', 'total', '\u{1F4D6}', '五十問', '累計50問', (s) => s.totalQ >= 50),
  Badge('q100', 'total', '\u{1F4D6}', '百問修行', '累計100問', (s) => s.totalQ >= 100),
  Badge('q200', 'total', '\u{1F4D6}', '二百問', '累計200問', (s) => s.totalQ >= 200),
  Badge('q300', 'total', '\u{1F4D6}', '三百問', '累計300問', (s) => s.totalQ >= 300),
  Badge('q500', 'total', '\u{1F4D6}', '五百問', '累計500問', (s) => s.totalQ >= 500),
  Badge('q750', 'total', '\u{1F4D8}', '七百五十問', '累計750問', (s) => s.totalQ >= 750),
  Badge('q1000', 'total', '\u{1F4D8}', '千問修行', '累計1000問', (s) => s.totalQ >= 1000),
  Badge('q1500', 'total', '\u{1F4D8}', '千五百問', '累計1500問', (s) => s.totalQ >= 1500),
  Badge('q2000', 'total', '\u{1F4D9}', '二千問', '累計2000問', (s) => s.totalQ >= 2000),
  Badge('q3000', 'total', '\u{1F4D9}', '三千問', '累計3000問', (s) => s.totalQ >= 3000),
  Badge('q5000', 'total', '\u{1F4D5}', '五千問', '累計5000問', (s) => s.totalQ >= 5000),
  Badge('q10000', 'total', '\u{1F4D5}', '万問', '累計10000問', (s) => s.totalQ >= 10000),
  // ── 累計正解 (7) ──
  Badge('c100', 'correct', '\u{2705}', '百問正解', '累計100問正解', (s) => s.totalCorrect >= 100),
  Badge('c200', 'correct', '\u{2705}', '二百問正解', '累計200問正解', (s) => s.totalCorrect >= 200),
  Badge('c500', 'correct', '\u{2705}', '五百問正解', '累計500問正解', (s) => s.totalCorrect >= 500),
  Badge('c1000', 'correct', '\u{2705}', '千問正解', '累計1000問正解', (s) => s.totalCorrect >= 1000),
  Badge('c2000', 'correct', '\u{2705}', '二千問正解', '累計2000問正解', (s) => s.totalCorrect >= 2000),
  Badge('c5000', 'correct', '\u{2705}', '五千問正解', '累計5000問正解', (s) => s.totalCorrect >= 5000),
  Badge('c10000', 'correct', '\u{2705}', '万問正解', '累計10000問正解', (s) => s.totalCorrect >= 10000),
  // ── 累計スコア (9) ──
  Badge('sc100', 'score', '\u{1F4B0}', '百点', '累計100点', (s) => s.totalScore >= 100),
  Badge('sc500', 'score', '\u{1F4B0}', '五百点', '累計500点', (s) => s.totalScore >= 500),
  Badge('sc1000', 'score', '\u{1F4B0}', '千点', '累計1000点', (s) => s.totalScore >= 1000),
  Badge('sc2000', 'score', '\u{1F4B0}', '二千点', '累計2000点', (s) => s.totalScore >= 2000),
  Badge('sc5000', 'score', '\u{1F4B0}', '五千点', '累計5000点', (s) => s.totalScore >= 5000),
  Badge('sc10000', 'score', '\u{1F48E}', '万点', '累計10000点', (s) => s.totalScore >= 10000),
  Badge('sc25000', 'score', '\u{1F48E}', '二万五千点', '累計25000点', (s) => s.totalScore >= 25000),
  Badge('sc50000', 'score', '\u{1F48E}', '五万点', '累計50000点', (s) => s.totalScore >= 50000),
  Badge('sc100k', 'score', '\u{1F48E}', '十万点', '累計100000点', (s) => s.totalScore >= 100000),
  // ── 速答 (6) ──
  Badge('fast10', 'speed', '\u{26A1}', '即答', '10秒以内に正解', (s) => s.elapsed <= 10 && s.perfect),
  Badge('fast5', 'speed', '\u{26A1}', '速答', '5秒以内に正解', (s) => s.elapsed <= 5 && s.perfect),
  Badge('fast3', 'speed', '\u{26A1}', '電光石火', '3秒以内に正解', (s) => s.elapsed <= 3 && s.perfect),
  Badge('fast2', 'speed', '\u{26A1}', '刹那', '2秒以内に正解', (s) => s.elapsed <= 2 && s.perfect),
  Badge('fast1', 'speed', '\u{26A1}', '一瞬', '1秒以内に正解', (s) => s.elapsed <= 1 && s.perfect),
  Badge('fast05', 'speed', '\u{26A1}', '神速', '0.5秒以内に正解', (s) => s.elapsed <= 0.5 && s.perfect),
  // ── 速答連続 (6) ──
  Badge('spd5_5', 'spdrun', '\u{26A1}', '速答師', '5問連続5秒以内正解', (s) => s.speedStreak >= 5),
  Badge('spd10_5', 'spdrun', '\u{26A1}', '速答達人', '10問連続5秒以内正解', (s) => s.speedStreak >= 10),
  Badge('spd20_5', 'spdrun', '\u{26A1}', '速答の鬼', '20問連続5秒以内正解', (s) => s.speedStreak >= 20),
  Badge('spd5_3', 'spdrun', '\u{26A1}', '瞬答師', '5問連続3秒以内正解', (s) => s.speed3Streak >= 5),
  Badge('spd10_3', 'spdrun', '\u{26A1}', '瞬答達人', '10問連続3秒以内正解', (s) => s.speed3Streak >= 10),
  Badge('spd20_3', 'spdrun', '\u{26A1}', '瞬答の鬼', '20問連続3秒以内正解', (s) => s.speed3Streak >= 20),
  // ── 多面待ち (10) ──
  Badge('wait2', 'wait', '\u{1F3AF}', '両面使い', '2面待ちを正解', (s) => s.maxWaitsCorrect >= 2),
  Badge('wait3', 'wait', '\u{1F3AF}', '三面使い', '3面待ちを正解', (s) => s.maxWaitsCorrect >= 3),
  Badge('wait4', 'wait', '\u{1F3AF}', '四面使い', '4面待ちを正解', (s) => s.maxWaitsCorrect >= 4),
  Badge('wait5', 'wait', '\u{1F3AF}', '五面使い', '5面待ちを正解', (s) => s.maxWaitsCorrect >= 5),
  Badge('wait6', 'wait', '\u{1F3AF}', '六面使い', '6面待ちを正解', (s) => s.maxWaitsCorrect >= 6),
  Badge('wait7', 'wait', '\u{1F3AF}', '七面使い', '7面待ちを正解', (s) => s.maxWaitsCorrect >= 7),
  Badge('wait8', 'wait', '\u{1F3AF}', '八面使い', '8面待ちを正解', (s) => s.maxWaitsCorrect >= 8),
  Badge('wait9', 'wait', '\u{1F3AF}', '九蓮', '9面待ちを正解', (s) => s.maxWaitsCorrect >= 9),
  Badge('m5x10', 'wait', '\u{1F3AF}', '多面の達人', '5面以上を10回正解', (s) => s.multi5Count >= 10),
  Badge('m7x5', 'wait', '\u{1F3AF}', '七面の達人', '7面以上を5回正解', (s) => s.multi7Count >= 5),
  // ── 非テンパイ (6) ──
  Badge('nt1', 'nt', '\u{1F6E1}\u{FE0F}', '初看破', '非テンパイ初正解', (s) => s.notTenpaiCorrect >= 1),
  Badge('nt5', 'nt', '\u{1F6E1}\u{FE0F}', '五看破', '非テンパイ5回正解', (s) => s.notTenpaiCorrect >= 5),
  Badge('nt10', 'nt', '\u{1F6E1}\u{FE0F}', '看破', '非テンパイ10回正解', (s) => s.notTenpaiCorrect >= 10),
  Badge('nt25', 'nt', '\u{1F6E1}\u{FE0F}', '看破師', '非テンパイ25回正解', (s) => s.notTenpaiCorrect >= 25),
  Badge('nt50', 'nt', '\u{1F6E1}\u{FE0F}', '看破達人', '非テンパイ50回正解', (s) => s.notTenpaiCorrect >= 50),
  Badge('nt100', 'nt', '\u{1F6E1}\u{FE0F}', '看破の鬼', '非テンパイ100回正解', (s) => s.notTenpaiCorrect >= 100),
  // ── タイムアタック (8) ──
  Badge('ta100', 'ta', '\u{1F3C6}', 'TA百点', 'TA 100点以上', (s) => s.bestTAScore >= 100),
  Badge('ta200', 'ta', '\u{1F3C6}', 'TA二百点', 'TA 200点以上', (s) => s.bestTAScore >= 200),
  Badge('ta400', 'ta', '\u{1F3C6}', 'TA四百点', 'TA 400点以上', (s) => s.bestTAScore >= 400),
  Badge('ta600', 'ta', '\u{1F3C6}', 'TA六百点', 'TA 600点以上', (s) => s.bestTAScore >= 600),
  Badge('ta800', 'ta', '\u{1F3C6}', 'TA八百点', 'TA 800点以上', (s) => s.bestTAScore >= 800),
  Badge('ta1200', 'ta', '\u{1F3C6}', 'TA千二百点', 'TA 1200点以上', (s) => s.bestTAScore >= 1200),
  Badge('ta1600', 'ta', '\u{1F3C6}', 'TA千六百点', 'TA 1600点以上', (s) => s.bestTAScore >= 1600),
  Badge('ta2000', 'ta', '\u{1F3C6}', 'TA二千点', 'TA 2000点以上', (s) => s.bestTAScore >= 2000),
  // ── 段位到達 (9) ──
  Badge('rank10', 'rank', '\u{1F396}\u{FE0F}', '十級到達', '十級に到達', (s) => s.rankIdx <= 19),
  Badge('rank5', 'rank', '\u{1F396}\u{FE0F}', '五級到達', '五級に到達', (s) => s.rankIdx <= 14),
  Badge('rank1', 'rank', '\u{1F396}\u{FE0F}', '一級到達', '一級に到達', (s) => s.rankIdx <= 10),
  Badge('rankD1', 'rank', '\u{1F396}\u{FE0F}', '初段到達', '初段に到達', (s) => s.rankIdx <= 9),
  Badge('rankD3', 'rank', '\u{1F396}\u{FE0F}', '三段到達', '三段に到達', (s) => s.rankIdx <= 7),
  Badge('rankD5', 'rank', '\u{1F396}\u{FE0F}', '五段到達', '五段に到達', (s) => s.rankIdx <= 5),
  Badge('rankD7', 'rank', '\u{1F396}\u{FE0F}', '七段到達', '七段に到達', (s) => s.rankIdx <= 3),
  Badge('rankD9', 'rank', '\u{1F396}\u{FE0F}', '九段到達', '九段に到達', (s) => s.rankIdx <= 1),
  Badge('rankD10', 'rank', '\u{1F396}\u{FE0F}', '十段到達', '十段に到達', (s) => s.rankIdx <= 0),
  // ── 特殊 (8) ──
  Badge('first', 'special', '\u{2B50}', 'はじめの一歩', '初めて問題を解いた', (s) => s.totalQ >= 1),
  Badge('firstTA', 'special', '\u{2B50}', '初挑戦', '初のタイムアタック', (s) => s.taTotalQ >= 1),
  Badge('perfect60', 'special', '\u{1F31F}', '満点', '1問で60点獲得', (s) => s.gain >= 60),
  Badge('pstreak3', 'special', '\u{1F31F}', '三連満点', '3問連続60点', (s) => s.perfectScoreStreak >= 3),
  Badge('pstreak5', 'special', '\u{1F31F}', '五連満点', '5問連続60点', (s) => s.perfectScoreStreak >= 5),
  Badge('pstreak10', 'special', '\u{1F31F}', '十連満点', '10問連続60点', (s) => s.perfectScoreStreak >= 10),
  Badge('night', 'special', '\u{1F319}', '深夜修行', '深夜0-5時に正解', (s) => s.perfect && s.hour >= 0 && s.hour < 5),
  Badge('morning', 'special', '\u{1F305}', '早朝修行', '早朝5-7時に正解', (s) => s.perfect && s.hour >= 5 && s.hour < 7),
  // ── 正解率 (5) ──
  Badge('acc50', 'acc', '\u{1F4CA}', '高精度', '50問以上で正解率90%', (s) => s.totalQ >= 50 && s.rate >= 90),
  Badge('acc100', 'acc', '\u{1F4CA}', '安定感', '100問以上で正解率85%', (s) => s.totalQ >= 100 && s.rate >= 85),
  Badge('acc200', 'acc', '\u{1F4CA}', '鉄壁', '200問以上で正解率80%', (s) => s.totalQ >= 200 && s.rate >= 80),
  Badge('acc500', 'acc', '\u{1F4CA}', '不動', '500問以上で正解率75%', (s) => s.totalQ >= 500 && s.rate >= 75),
  Badge('acc1000', 'acc', '\u{1F4CA}', '磐石', '1000問以上で正解率70%', (s) => s.totalQ >= 1000 && s.rate >= 70),
];

// ═══════════════════════════════════════
// 統計データ（SharedPreferencesで永続化）
// ═══════════════════════════════════════

class Stats {
  int totalQ = 0;
  int totalCorrect = 0;
  int totalScore = 0;
  int maxStreak = 0;
  int curStreak = 0;
  List<String> earnedBadges = [];
  int rankIdx = ranks.length - 1; // 無級
  int notTenpaiCorrect = 0;
  int maxWaitsCorrect = 0;
  int speedStreak = 0;
  int speed3Streak = 0;
  int taTotalQ = 0;
  int taTotalCorrect = 0;
  int taTotalScore = 0;
  int bestTAScore = 0;
  int rp = 0;
  int multi5Count = 0;
  int multi7Count = 0;
  int perfectScoreStreak = 0;

  Rank get currentRank => ranks[rankIdx];
  int get currentBaseline => ranks[rankIdx].baseline;

  int get accuracyPercent =>
      totalQ > 0 ? (totalCorrect * 100 / totalQ).round() : 0;

  int get taAccuracyPercent =>
      taTotalQ > 0 ? (taTotalCorrect * 100 / taTotalQ).round() : 0;

  /// RPから段位インデックスを計算
  int calcRank() {
    for (int i = 0; i < ranks.length; i++) {
      if (rp >= ranks[i].minRP) return i;
    }
    return ranks.length - 1;
  }

  /// 次の段位への進捗
  ({double pct, String? nextName}) calcRankProgress() {
    if (rankIdx == 0) return (pct: 100.0, nextName: null);
    final next = ranks[rankIdx - 1];
    final cur = ranks[rankIdx];
    final range = next.minRP - cur.minRP;
    final progress = rp - cur.minRP;
    final pct =
        range > 0 ? (progress / range * 100).clamp(0.0, 100.0) : 100.0;
    return (pct: pct, nextName: next.name);
  }

  /// 結果画面のコメント（スコアに応じた一言）
  static String resultComment(int score) {
    if (score >= 500) return '完璧な正確性と圧倒的な速度。プロ級の実力です。';
    if (score >= 350) return '多面張も確実に捉えられています。ほぼ完璧。';
    if (score >= 220) return '基本形は確実。変則形のさらなる練習を。';
    if (score >= 120) return '見逃しを減らすことが次のステップです。';
    if (score >= 50) return '7枚形の基本パターンを覚えましょう。';
    return '焦らず一問ずつ丁寧に解いていきましょう。';
  }

  /// 解答後の統計更新。新規獲得バッジを返す。
  List<Badge> updateAfterAnswer({
    required bool perfect,
    required double elapsed,
    required int waitsCount,
    required bool isTenpai,
    required bool isTA,
  }) {
    final gain = perfect ? (scoreBaseTime - elapsed).round().clamp(0, 60) : 0;

    totalQ++;
    if (isTA) taTotalQ++;

    if (perfect) {
      totalCorrect++;
      totalScore += gain;
      if (isTA) {
        taTotalCorrect++;
        taTotalScore += gain;
      }
      curStreak++;
      if (curStreak > maxStreak) maxStreak = curStreak;
      if (isTenpai && waitsCount > 0) {
        if (waitsCount > maxWaitsCorrect) maxWaitsCorrect = waitsCount;
        if (waitsCount >= 5) multi5Count++;
        if (waitsCount >= 7) multi7Count++;
      }
      if (!isTenpai) notTenpaiCorrect++;
      speedStreak = elapsed <= 5 ? speedStreak + 1 : 0;
      speed3Streak = elapsed <= 3 ? speed3Streak + 1 : 0;
      perfectScoreStreak = gain >= 60 ? perfectScoreStreak + 1 : 0;
    } else {
      curStreak = 0;
      speedStreak = 0;
      speed3Streak = 0;
      perfectScoreStreak = 0;
    }

    // バッジチェック
    final state = BadgeCheckState(
      streak: curStreak,
      totalQ: totalQ,
      totalCorrect: totalCorrect,
      totalScore: totalScore,
      maxWaitsCorrect: maxWaitsCorrect,
      notTenpaiCorrect: notTenpaiCorrect,
      speedStreak: speedStreak,
      speed3Streak: speed3Streak,
      multi5Count: multi5Count,
      multi7Count: multi7Count,
      bestTAScore: bestTAScore,
      rankIdx: rankIdx,
      taTotalQ: taTotalQ,
      perfectScoreStreak: perfectScoreStreak,
      rate: accuracyPercent,
      perfect: perfect,
      elapsed: elapsed,
      gain: gain,
      hour: DateTime.now().hour,
    );

    final newBadges = <Badge>[];
    for (final b in badges) {
      if (earnedBadges.contains(b.id)) continue;
      if (b.check(state)) {
        earnedBadges.add(b.id);
        newBadges.add(b);
      }
    }
    return newBadges;
  }

  /// TA終了後のRP更新。rpDeltaと段位変動情報を返す。
  ({int rpDelta, int prevRankIdx, int newRankIdx}) updateRPAfterTA(int taScore) {
    if (taScore > bestTAScore) bestTAScore = taScore;

    final baseline = currentBaseline;
    final rpDelta = taScore - baseline;
    rp = (rp + rpDelta).clamp(0, 999999);

    final prevRankIdx = rankIdx;
    rankIdx = calcRank();

    return (rpDelta: rpDelta, prevRankIdx: prevRankIdx, newRankIdx: rankIdx);
  }

  /// RP更新後のバッジチェック（段位バッジ用）
  List<Badge> checkRankBadges() {
    final state = BadgeCheckState(
      streak: curStreak,
      totalQ: totalQ,
      totalCorrect: totalCorrect,
      totalScore: totalScore,
      maxWaitsCorrect: maxWaitsCorrect,
      notTenpaiCorrect: notTenpaiCorrect,
      speedStreak: speedStreak,
      speed3Streak: speed3Streak,
      multi5Count: multi5Count,
      multi7Count: multi7Count,
      bestTAScore: bestTAScore,
      rankIdx: rankIdx,
      taTotalQ: taTotalQ,
      perfectScoreStreak: perfectScoreStreak,
      rate: accuracyPercent,
      perfect: false,
      elapsed: 999,
      gain: 0,
      hour: DateTime.now().hour,
    );

    final newBadges = <Badge>[];
    for (final b in badges) {
      if (earnedBadges.contains(b.id)) continue;
      if (b.check(state)) {
        earnedBadges.add(b.id);
        newBadges.add(b);
      }
    }
    return newBadges;
  }

  // ═══════════════════════════════════════
  // SharedPreferences 永続化
  // ═══════════════════════════════════════

  static const _key = 'chinitsu_stats';

  Map<String, dynamic> toJson() => {
        'totalQ': totalQ,
        'totalCorrect': totalCorrect,
        'totalScore': totalScore,
        'maxStreak': maxStreak,
        'curStreak': curStreak,
        'badges': earnedBadges,
        'rankIdx': rankIdx,
        'notTenpaiCorrect': notTenpaiCorrect,
        'maxWaitsCorrect': maxWaitsCorrect,
        'speedStreak': speedStreak,
        'speed3Streak': speed3Streak,
        'taTotalQ': taTotalQ,
        'taTotalCorrect': taTotalCorrect,
        'taTotalScore': taTotalScore,
        'bestTAScore': bestTAScore,
        'rp': rp,
        'multi5Count': multi5Count,
        'multi7Count': multi7Count,
        'perfectScoreStreak': perfectScoreStreak,
      };

  void fromJson(Map<String, dynamic> j) {
    totalQ = j['totalQ'] as int? ?? 0;
    totalCorrect = j['totalCorrect'] as int? ?? 0;
    totalScore = j['totalScore'] as int? ?? 0;
    maxStreak = j['maxStreak'] as int? ?? 0;
    curStreak = j['curStreak'] as int? ?? 0;
    earnedBadges = List<String>.from(j['badges'] as List? ?? []);
    rankIdx = (j['rankIdx'] as int? ?? ranks.length - 1).clamp(0, ranks.length - 1); // BUG-23
    notTenpaiCorrect = j['notTenpaiCorrect'] as int? ?? 0;
    maxWaitsCorrect = j['maxWaitsCorrect'] as int? ?? 0;
    speedStreak = j['speedStreak'] as int? ?? 0;
    speed3Streak = j['speed3Streak'] as int? ?? 0;
    taTotalQ = j['taTotalQ'] as int? ?? 0;
    taTotalCorrect = j['taTotalCorrect'] as int? ?? 0;
    taTotalScore = j['taTotalScore'] as int? ?? 0;
    bestTAScore = j['bestTAScore'] as int? ?? 0;
    rp = j['rp'] as int? ?? 0;
    multi5Count = j['multi5Count'] as int? ?? 0;
    multi7Count = j['multi7Count'] as int? ?? 0;
    perfectScoreStreak = j['perfectScoreStreak'] as int? ?? 0;
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(toJson()));
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_key);
    if (str != null) {
      fromJson(jsonDecode(str) as Map<String, dynamic>);
    }
  }
}
