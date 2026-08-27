class Zekr {
  final String id;
  String title;
  String text;
  int repeat;
  int remaining;
  bool isFavorite;
  DateTime lastModified;

  Zekr({
    required this.id,
    required this.title,
    required this.text,
    required this.repeat,
    int? remaining,
    this.isFavorite = false,
    DateTime? lastModified,
  })  : remaining = remaining ?? repeat,
        lastModified = lastModified ?? DateTime.now();

  bool get isCompleted => remaining <= 0;

  double get progress {
    if (repeat <= 0) return 1.0;
    return ((repeat - remaining) / repeat).clamp(0.0, 1.0);
  }

  Zekr copyWith({
    String? id,
    String? title,
    String? text,
    int? repeat,
    int? remaining,
    bool? isFavorite,
    DateTime? lastModified,
  }) {
    return Zekr(
      id: id ?? this.id,
      title: title ?? this.title,
      text: text ?? this.text,
      repeat: repeat ?? this.repeat,
      remaining: remaining ?? this.remaining,
      isFavorite: isFavorite ?? this.isFavorite,
      lastModified: lastModified ?? this.lastModified,
    );
  }

  void touch() {
    lastModified = DateTime.now();
  }

  void decrement() {
    if (remaining > 0) {
      remaining--;
      touch();
    }
  }

  void increment() {
    if (remaining < repeat) {
      remaining++;
      touch();
    }
  }

  void resetCounter() {
    remaining = repeat;
    touch();
  }

  void toggleFavorite() {
    isFavorite = !isFavorite;
    touch();
  }

  /// Plain text suitable for copy/share: title + body.
  String get shareText => '$title\n\n$text';

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'text': text,
        'repeat': repeat,
        'remaining': remaining,
        'isFavorite': isFavorite,
        'lastModified': lastModified.toIso8601String(),
      };

  factory Zekr.fromJson(Map<String, dynamic> json) {
    final repeat = (json['repeat'] as num?)?.toInt() ?? 1;
    return Zekr(
      id: json['id'] as String,
      title: json['title'] as String,
      text: json['text'] as String,
      repeat: repeat,
      remaining: (json['remaining'] as num?)?.toInt() ?? repeat,
      isFavorite: json['isFavorite'] as bool? ?? false,
      lastModified: json['lastModified'] != null
          ? DateTime.tryParse(json['lastModified'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
