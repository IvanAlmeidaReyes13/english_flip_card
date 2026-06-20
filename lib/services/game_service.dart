import '../models/flashcard.dart';
import 'database_service.dart';

class GameService {
  final DatabaseService _db;

  Flashcard? _currentCard;
  bool _isFlipped = false;
  bool _isCurrentCardReversed = false;
  int _streak = 0;
  int _bestStreak = 0;
  final Set<String> _seenCardIds = {};
  List<Flashcard> _sessionCards = [];
  bool _sessionComplete = false;
  int _sessionTotalCards = 0;

  GameService(this._db);

  Future<void> startSession() async {
    _streak = 0;
    _bestStreak = 0;
    _seenCardIds.clear();
    _sessionComplete = false;
    _sessionCards = await _db.getActiveCards();
    _sessionTotalCards = _sessionCards.length;
    await loadNextCard();
  }

  Future<void> loadNextCard() async {
    _currentCard = await _getNextCard();
    _isFlipped = false;
    _isCurrentCardReversed = _shouldReverseCard(_currentCard);

    if (_currentCard == null) {
      _sessionComplete = true;
    }
  }

  Future<Flashcard?> _getNextCard() async {
    if (_sessionCards.isEmpty) return null;

    final unseenCards =
        _sessionCards.where((c) => !_seenCardIds.contains(c.id)).toList();

    if (unseenCards.isEmpty) return null;
    final pool = unseenCards;

    const maxKnowledgeLevel = 100;
    final weights = <Flashcard, int>{};
    int totalWeight = 0;

    for (final card in pool) {
      final weight = maxKnowledgeLevel - card.knowledgeLevel + 1;
      weights[card] = weight;
      totalWeight += weight;
    }

    if (totalWeight == 0) return pool.first;

    final random = DateTime.now().millisecondsSinceEpoch % totalWeight;
    int current = 0;

    for (final entry in weights.entries) {
      current += entry.value;
      if (random < current) {
        return entry.key;
      }
    }

    return pool.last;
  }

  bool _shouldReverseCard(Flashcard? card) {
    if (card == null) return false;
    return card.knowledgeLevel >= 50 && card.knowledgeLevel < 100;
  }

  void flipCard() {
    _isFlipped = true;
  }

  Future<GameAnswerResult> answer(bool correct) async {
    if (_currentCard == null) return const GameAnswerResult();

    if (correct) {
      _streak++;
      if (_streak > _bestStreak) _bestStreak = _streak;
    } else {
      _streak = 0;
    }

    _seenCardIds.add(_currentCard!.id);
    final becameCompleted = await _updateKnowledgeLevel(
      _currentCard!.id,
      correct,
    );

    return GameAnswerResult(
      becameCompleted: becameCompleted,
      card: _currentCard,
    );
  }

  Future<bool> _updateKnowledgeLevel(String id, bool correct) async {
    final card = await _db.getCard(id);
    if (card == null) return false;

    const maxKnowledgeLevel = 100;
    int newLevel = card.knowledgeLevel;

    if (correct) {
      newLevel = (card.knowledgeLevel + 10).clamp(0, maxKnowledgeLevel);
    } else {
      newLevel = (card.knowledgeLevel - 20).clamp(0, maxKnowledgeLevel);
    }

    final becameCompleted = !card.isCompleted && newLevel >= maxKnowledgeLevel;
    final updatedCard = card.copyWith(
      knowledgeLevel: newLevel,
      isCompleted: card.isCompleted || becameCompleted,
    );
    await _db.updateCard(updatedCard);
    return becameCompleted;
  }

  Future<void> refreshCards() async {
    await startSession();
  }

  Future<bool> isTutorialDismissed() => _db.isTutorialDismissed();

  Future<void> setTutorialDismissed(bool dismissed) {
    return _db.setTutorialDismissed(dismissed);
  }

  Flashcard? get currentCard => _currentCard;
  bool get isFlipped => _isFlipped;
  bool get isCurrentCardReversed => _isCurrentCardReversed;
  int get streak => _streak;
  int get bestStreak => _bestStreak;
  bool get sessionComplete => _sessionComplete;
  bool get hasCards => _currentCard != null;
  int get sessionTotalCards => _sessionTotalCards;
  int get reviewedCards => _seenCardIds.length;
  int get currentPosition {
    if (_sessionTotalCards == 0) return 0;
    if (_sessionComplete) return _sessionTotalCards;
    return (_seenCardIds.length + 1).clamp(1, _sessionTotalCards);
  }
}

class GameAnswerResult {
  final bool becameCompleted;
  final Flashcard? card;

  const GameAnswerResult({this.becameCompleted = false, this.card});
}
