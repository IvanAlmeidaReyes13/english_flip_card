import 'package:hive_flutter/hive_flutter.dart';
import '../models/flashcard.dart';

class DatabaseService {
  static const String _boxName = 'flashcards';
  static const String _settingsBoxName = 'settings';
  static const String _tutorialDismissedKey = 'tutorialDismissed';

  Box<Flashcard>? _box;
  Box<bool>? _settingsBox;

  Future<void> init() async {
    await Hive.initFlutter();

    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(FlashcardAdapter());
    }

    _box = await Hive.openBox<Flashcard>(_boxName);
    _settingsBox = await Hive.openBox<bool>(_settingsBoxName);
  }

  Future<void> addCard(Flashcard card) async {
    await _box?.put(card.id, card);
  }

  Future<void> updateCard(Flashcard card) async {
    await _box?.put(card.id, card);
  }

  Future<void> deleteCard(String id) async {
    await _box?.delete(id);
  }

  Future<List<Flashcard>> getAllCards() async {
    return _box?.values.toList() ?? [];
  }

  Future<bool> isEmpty() async {
    return _box?.isEmpty ?? true;
  }

  Future<Flashcard?> getCard(String id) async {
    return _box?.get(id);
  }

  Future<bool> isTutorialDismissed() async {
    return _settingsBox?.get(_tutorialDismissedKey) ?? false;
  }

  Future<void> setTutorialDismissed(bool dismissed) async {
    await _settingsBox?.put(_tutorialDismissedKey, dismissed);
  }
}
