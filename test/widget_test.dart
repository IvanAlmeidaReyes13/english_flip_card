import 'package:english_flip_card/main.dart';
import 'package:english_flip_card/services/database_service.dart';
import 'package:english_flip_card/services/game_service.dart';
import 'package:english_flip_card/viewmodels/cards_viewmodel.dart';
import 'package:english_flip_card/viewmodels/game_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('shows the empty practice state when there are no cards', (
    tester,
  ) async {
    final dbService = DatabaseService();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<DatabaseService>.value(value: dbService),
          ChangeNotifierProvider(
            create: (_) => GameViewModel(GameService(dbService)),
          ),
          ChangeNotifierProvider(create: (_) => CardsViewModel(dbService)),
        ],
        child: const MaterialApp(home: MainNavigation()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Práctica'), findsOneWidget);
    expect(find.text('No hay tarjetas disponibles'), findsOneWidget);
    expect(find.text('¡Sesión completada!'), findsNothing);
  });
}
