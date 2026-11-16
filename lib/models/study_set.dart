class Flashcard {
  const Flashcard({
    required this.id,
    required this.term,
    required this.definition,
  });

  final String id;
  final String term;
  final String definition;

  Flashcard copyWith({String? term, String? definition}) => Flashcard(
    id: id,
    term: term ?? this.term,
    definition: definition ?? this.definition,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'term': term,
    'definition': definition,
  };

  factory Flashcard.fromJson(Map<String, dynamic> json) => Flashcard(
    id: json['id'] as String,
    term: json['term'] as String,
    definition: json['definition'] as String,
  );
}

class StudySet {
  const StudySet({
    required this.id,
    required this.title,
    this.description = '',
    this.cards = const [],
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String description;
  final List<Flashcard> cards;
  final DateTime updatedAt;

  StudySet copyWith({
    String? title,
    String? description,
    List<Flashcard>? cards,
    DateTime? updatedAt,
  }) => StudySet(
    id: id,
    title: title ?? this.title,
    description: description ?? this.description,
    cards: cards ?? this.cards,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'cards': cards.map((c) => c.toJson()).toList(),
    'updatedAt': updatedAt.toUtc().toIso8601String(),
  };

  factory StudySet.fromJson(Map<String, dynamic> json) => StudySet(
    id: json['id'] as String,
    title: json['title'] as String,
    description: (json['description'] as String?) ?? '',
    cards: ((json['cards'] as List?) ?? const [])
        .map((c) => Flashcard.fromJson(Map<String, dynamic>.from(c as Map)))
        .toList(),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );
}
