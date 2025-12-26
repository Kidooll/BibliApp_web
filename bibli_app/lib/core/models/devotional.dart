class Devotional {
  final int id;
  final String title;
  final String? audioUrl;
  final DateTime publishedDate;
  final String? text;
  final String? word;
  final String? verse1;
  final String? citation;
  final String? reflection;
  final String? verse2;
  final String? author;
  final String? practicalApplication;
  final String? verse;
  final String? prayer;
  final DateTime createdAt;
  final DateTime updatedAt;

  Devotional({
    required this.id,
    required this.title,
    this.audioUrl,
    required this.publishedDate,
    this.text,
    this.word,
    this.verse1,
    this.citation,
    this.reflection,
    this.verse2,
    this.author,
    this.practicalApplication,
    this.verse,
    this.prayer,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Devotional.fromJson(Map<String, dynamic> json) {
    return Devotional(
      id: json['id'],
      title: json['title'],
      audioUrl: json['audio_url'],
      publishedDate: DateTime.parse(json['published_date']),
      text: json['text'],
      word: json['word'],
      verse1: json['verse1'],
      citation: json['citation'],
      reflection: json['reflection'],
      verse2: json['verse2'],
      author: json['author'],
      practicalApplication: json['practical_application'],
      verse: json['verse'],
      prayer: json['prayer'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'audio_url': audioUrl,
      'published_date': publishedDate.toIso8601String(),
      'text': text,
      'word': word,
      'verse1': verse1,
      'citation': citation,
      'reflection': reflection,
      'verse2': verse2,
      'author': author,
      'practical_application': practicalApplication,
      'verse': verse,
      'prayer': prayer,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
