import 'package:flutter/foundation.dart';
import '../models/flashcard.dart';
import '../services/database_service.dart';

class CardsViewModel extends ChangeNotifier {
  final DatabaseService _db;

  List<Flashcard> _cards = [];
  bool _isLoading = false;
  String? _errorMessage;
  CardsFilter _filter = CardsFilter.active;

  CardsViewModel(this._db);

  List<Flashcard> get cards => _cards;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isEmpty => _cards.isEmpty;
  CardsFilter get filter => _filter;
  bool get showingCompleted => _filter == CardsFilter.completed;

  Future<void> loadCards({CardsFilter? filter}) async {
    if (filter != null) {
      _filter = filter;
    }
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _cards = await _db.getCards(completed: showingCompleted);
    } catch (e) {
      _errorMessage = 'Error al cargar las tarjetas: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addCard(String english, String spanish, {String? notes}) async {
    try {
      final card = Flashcard(english: english, spanish: spanish, notes: notes);
      await _db.addCard(card);
      await loadCards();
      return true;
    } catch (e) {
      _errorMessage = 'Error al añadir la tarjeta: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateCard(Flashcard card) async {
    try {
      await _db.updateCard(card);
      await loadCards();
      return true;
    } catch (e) {
      _errorMessage = 'Error al actualizar la tarjeta: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteCard(String id) async {
    try {
      await _db.deleteCard(id);
      await loadCards();
      return true;
    } catch (e) {
      _errorMessage = 'Error al eliminar la tarjeta: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> restoreCard(String id) async {
    try {
      await _db.restoreCard(id);
      await loadCards();
      return true;
    } catch (e) {
      _errorMessage = 'Error al restaurar la tarjeta: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> resetCard(String id) async {
    try {
      await _db.resetCard(id);
      await loadCards();
      return true;
    } catch (e) {
      _errorMessage = 'Error al reiniciar la tarjeta: $e';
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

enum CardsFilter { active, completed }
