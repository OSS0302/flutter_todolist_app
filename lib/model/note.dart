class Note {
  final String title;
  final String content;
  final int createdAt;
  final int? updatedAt;

//<editor-fold desc="Data Methods">
  const Note({
    required this.title,
    required this.content,
    required this.createdAt,
    this.updatedAt,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Note &&
          runtimeType == other.runtimeType &&
          title == other.title &&
          content == other.content &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt);

  @override
  int get hashCode =>
      title.hashCode ^
      content.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode;

  @override
  String toString() {
    return 'Note{' +
        ' title: $title,' +
        ' content: $content,' +
        ' createdAt: $createdAt,' +
        ' updatedAt: $updatedAt,' +
        '}';
  }

  Note copyWith({
    String? title,
    String? content,
    int? createdAt,
    int? updatedAt,
  }) {
    return Note(
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': this.title,
      'content': this.content,
      'createdAt': this.createdAt,
      'updatedAt': this.updatedAt,
    };
  }

  factory Note.fromJson(Map<String, dynamic> map) {
    return Note(
      title: map['title'] as String,
      content: map['content'] as String,
      createdAt: map['createdAt'] as int,
      updatedAt: map['updatedAt'] as int,
    );
  }
}
