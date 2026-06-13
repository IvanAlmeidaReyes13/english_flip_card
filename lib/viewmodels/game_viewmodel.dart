import 'package:flutter/foundation.dart';
import '../models/flashcard.dart';
import '../services/game_service.dart';

class GameViewModel extends ChangeNotifier {
  final GameService _gameService;

  bool _isLoading = false;
  String? _errorMessage;
  bool _showTutorial = false;
  bool _animateStreak = false;
  bool _tutorialPreferenceLoaded = false;

  GameViewModel(this._gameService);

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get showTutorial => _showTutorial;
  bool get animateStreak => _animateStreak;

  Flashcard? get currentCard => _gameService.currentCard;
  bool get isFlipped => _gameService.isFlipped;
  bool get isCurrentCardReversed => _gameService.isCurrentCardReversed;
  int get streak => _gameService.streak;
  int get bestStreak => _gameService.bestStreak;
  bool get sessionComplete => _gameService.sessionComplete;
  bool get hasCards => _gameService.hasCards;
  int get sessionTotalCards => _gameService.sessionTotalCards;
  int get reviewedCards => _gameService.reviewedCards;
  int get currentPosition => _gameService.currentPosition;

  Future<void> startGame() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _gameService.startSession();
      if (!_tutorialPreferenceLoaded) {
        _tutorialPreferenceLoaded = true;
      }
    } catch (e) {
      _errorMessage = 'Error al iniciar el juego: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> dismissTutorial() async {
    _showTutorial = false;
    notifyListeners();
    await _gameService.setTutorialDismissed(true);
  }

  void toggleTutorial() {
    _showTutorial = !_showTutorial;
    notifyListeners();
  }

  void flipCard() {
    _gameService.flipCard();
    notifyListeners();
  }

  Future<void> answer(bool correct) async {
    if (currentCard == null) return;

    await _gameService.answer(correct);

    if (correct && _gameService.streak >= 5 && _gameService.streak % 5 == 0) {
      _animateStreak = true;
      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 800));
      _animateStreak = false;
      notifyListeners();
    }

    await _gameService.loadNextCard();
    notifyListeners();
  }

  Future<void> swipeLeft() async {
    await answer(false);
  }

  Future<void> swipeRight() async {
    await answer(true);
  }

  Future<void> refreshCards() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _gameService.refreshCards();
    } catch (e) {
      _errorMessage = 'Error al refrescar: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
