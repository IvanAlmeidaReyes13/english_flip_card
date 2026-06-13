import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'flashcard.g.dart';

@HiveType(typeId: 0)
class Flashcard extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String english;
  
  @HiveField(2)
  final String spanish;
  
  @HiveField(3)
  final int knowledgeLevel;
  
  @HiveField(4)
  final String? notes;
  
  @HiveField(5)
  final int colorIndex;

  Flashcard({
    String? id,
    required this.english, 
    required this.spanish, 
    this.knowledgeLevel = 0,
    this.notes,
    int? colorIndex,
  }) : id = id ?? const Uuid().v4(),
       colorIndex = colorIndex ?? (DateTime.now().millisecondsSinceEpoch % 8);

  Flashcard copyWith({
    String? id,
    String? english,
    String? spanish,
    int? knowledgeLevel,
    String? notes,
    int? colorIndex,
  }) {
    return Flashcard(
      id: id ?? this.id,
      english: english ?? this.english,
      spanish: spanish ?? this.spanish,
      knowledgeLevel: knowledgeLevel ?? this.knowledgeLevel,
      notes: notes ?? this.notes,
      colorIndex: colorIndex ?? this.colorIndex,
    );
  }
}
