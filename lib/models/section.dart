import 'zekr.dart';

class Section {
  final String id;
  String name;
  List<Zekr> azkar;
  DateTime lastModified;

  Section({
    required this.id,
    required this.name,
    List<Zekr>? azkar,
    DateTime? lastModified,
  })  : azkar = azkar ?? [],
        lastModified = lastModified ?? DateTime.now();

  int get completedCount => azkar.where((z) => z.isCompleted).length;

  int get totalCount => azkar.length;

  double get overallProgress {
    if (azkar.isEmpty) return 0;
    return completedCount / totalCount;
  }

  int get favoriteCount => azkar.where((z) => z.isFavorite).length;

  void touch() {
    lastModified = DateTime.now();
  }

  Section copyWith({
    String? id,
    String? name,
    List<Zekr>? azkar,
    DateTime? lastModified,
  }) {
    return Section(
      id: id ?? this.id,
      name: name ?? this.name,
      azkar: azkar ?? List<Zekr>.from(this.azkar),
      lastModified: lastModified ?? this.lastModified,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'azkar': azkar.map((z) => z.toJson()).toList(),
        'lastModified': lastModified.toIso8601String(),
      };

  factory Section.fromJson(Map<String, dynamic> json) {
    return Section(
      id: json['id'] as String,
      name: json['name'] as String,
      azkar: (json['azkar'] as List<dynamic>?)
              ?.map((e) => Zekr.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      lastModified: json['lastModified'] != null
          ? DateTime.tryParse(json['lastModified'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
