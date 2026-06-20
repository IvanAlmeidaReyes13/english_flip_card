import 'package:english_flip_card/models/flashcard.dart';
import 'package:english_flip_card/services/database_service.dart';
import 'package:english_flip_card/services/game_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('archives a card when a correct answer raises it to 100%', () async {
    final card = Flashcard(
      id: 'card-1',
      english: 'Master',
      spanish: 'Dominar',
      knowledgeLevel: 90,
    );
    final database = _FakeDatabaseService([card]);
    final service = GameService(database);

    await service.startSession();
    final result = await service.answer(true);

    expect(result.becameCompleted, isTrue);
    expect(database.cards.single.knowledgeLevel, 100);
    expect(database.cards.single.isCompleted, isTrue);

    await service.loadNextCard();
    expect(service.sessionComplete, isTrue);
    expect(service.sessionTotalCards, 1);
    expect(service.reviewedCards, 1);
  });

  test('does not archive a card before it reaches 100%', () async {
    final card = Flashcard(
      id: 'card-1',
      english: 'Learn',
      spanish: 'Aprender',
      knowledgeLevel: 80,
    );
    final database = _FakeDatabaseService([card]);
    final service = GameService(database);

    await service.startSession();
    final result = await service.answer(true);

    expect(result.becameCompleted, isFalse);
    expect(database.cards.single.knowledgeLevel, 90);
    expect(database.cards.single.isCompleted, isFalse);
  });
}

class _FakeDatabaseService extends DatabaseService {
  final Map<String, Flashcard> _cards;

  _FakeDatabaseService(List<Flashcard> cards)
    : _cards = {for (final card in cards) card.id: card};

  List<Flashcard> get cards => _cards.values.toList(growable: false);

  @override
  Future<List<Flashcard>> getActiveCards() async {
    return _cards.values
        .where((card) => !card.isCompleted)
        .toList(growable: false);
  }

  @override
  Future<Flashcard?> getCard(String id) async => _cards[id];

  @override
  Future<void> updateCard(Flashcard card) async {
    _cards[card.id] = card;
  }
}
