/// ゲームセッション中の状態（HTML v2のGオブジェクト相当）。
class GameState {
  String mode; // 'free' | 'time'
  int score;
  int correct;
  int total;
  Set<int> selected; // 選択中の待ち牌 (1-9)
  bool answered;
  bool notTenpaiSelected;
  int timerSec; // TA残り秒数
  String suit; // 'm' | 'p' | 's'
  List<int> waits; // 正解の待ち牌
  List<int> currentTiles; // 現在の手牌13枚
  DateTime? questionStart; // 問題開始時刻

  GameState({
    required this.mode,
    this.score = 0,
    this.correct = 0,
    this.total = 0,
    Set<int>? selected,
    this.answered = false,
    this.notTenpaiSelected = false,
    this.timerSec = 120,
    this.suit = 'm',
    List<int>? waits,
    List<int>? currentTiles,
    this.questionStart,
  })  : selected = selected ?? {},
        waits = waits ?? [],
        currentTiles = currentTiles ?? [];

  bool get isTimeAttack => mode == 'time';

  /// 新しい問題の開始時にリセット
  void resetForNewQuestion() {
    selected.clear();
    answered = false;
    notTenpaiSelected = false;
    questionStart = DateTime.now();
  }
}
