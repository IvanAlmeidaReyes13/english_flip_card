import 'package:flutter/foundation.dart';
import '../models/flashcard.dart';
import '../services/database_service.dart';

class CardsViewModel extends ChangeNotifier {
  final DatabaseService _db;
  
  List<Flashcard> _cards = [];
  bool _isLoading = false;
  String? _errorMessage;
  
  CardsViewModel(this._db);
  
  List<Flashcard> get cards => _cards;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isEmpty => _cards.isEmpty;
  
  Future<void> loadCards() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      _cards = await _db.getAllCards();
    } catch (e) {
      _errorMessage = 'Error al cargar las tarjetas: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<bool> addCard(String english, String spanish, {String? notes}) async {
    try {
      final card = Flashcard(
        english: english,
        spanish: spanish,
        notes: notes,
      );
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
  
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
