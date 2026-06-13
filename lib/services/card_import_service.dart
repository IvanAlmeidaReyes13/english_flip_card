import 'dart:convert';

import '../models/flashcard.dart';
import 'database_service.dart';

class CardImportService {
  final DatabaseService _db;

  CardImportService(this._db);

  Future<CardImportResult> importFromJsonText(String jsonText) async {
    final decoded = jsonDecode(jsonText);
    if (decoded is! Map<String, dynamic>) {
      throw const CardImportException();
    }

    final version = decoded['version'];
    if (version != null && version != 1) {
      throw const CardImportException();
    }

    final rawCards = decoded['cards'];
    if (rawCards is! List) {
      throw const CardImportException();
    }

    final existingCards = await _db.getAllCards();
    final existingKeys =
        existingCards
            .map((card) => _duplicateKey(card.english, card.spanish))
            .toSet();

    var imported = 0;
    var skippedDuplicates = 0;
    var skippedInvalid = 0;

    for (final rawCard in rawCards) {
      if (rawCard is! Map) {
        skippedInvalid++;
        continue;
      }

      final english = _readString(rawCard['english']);
      final meaning = _readString(rawCard['meaning']);
      if (english.isEmpty || meaning.isEmpty) {
        skippedInvalid++;
        continue;
      }

      final key = _duplicateKey(english, meaning);
      if (existingKeys.contains(key)) {
        skippedDuplicates++;
        continue;
      }

      final example = _readString(rawCard['example']);
      final notes = _readString(rawCard['notes']);
      final importedNotes = _mergeNotes(example: example, notes: notes);

      await _db.addCard(
        Flashcard(
          english: _capitalizeWordFirstWord(english),
          spanish: _capitalizeWordFirstWord(meaning),
          notes:
              importedNotes.isEmpty ? null : _capitalizeSentence(importedNotes),
        ),
      );

      existingKeys.add(key);
      imported++;
    }

    return CardImportResult(
      imported: imported,
      skippedDuplicates: skippedDuplicates,
      skippedInvalid: skippedInvalid,
    );
  }

  String _readString(Object? value) {
    if (value is! String) return '';
    return value.trim();
  }

  String _duplicateKey(String english, String meaning) {
    return '${_normalize(english)}|${_normalize(meaning)}';
  }

  String _normalize(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  String _mergeNotes({required String example, required String notes}) {
    if (example.isEmpty) return notes;
    if (notes.isEmpty) return 'Example: $example';
    return 'Example: $example\n$notes';
  }

  String _capitalizeWordFirstWord(String value) { //capitalize the first word, this should not be empty
    var firstWord = value.split(' ')[0];
    return firstWord.toUpperCase() + value.substring(firstWord.length);
  }

  String _capitalizeSentence(String value) { //capitalize the first word, this could be empty
    final trimmed = value.trim();
    if (trimmed.isEmpty) return trimmed;
    return trimmed[0].toUpperCase() + trimmed.substring(1);
  }
}

class CardImportResult {
  final int imported;
  final int skippedDuplicates;
  final int skippedInvalid;

  const CardImportResult({
    required this.imported,
    required this.skippedDuplicates,
    required this.skippedInvalid,
  });
}

class CardImportException implements Exception {
  const CardImportException();
}
