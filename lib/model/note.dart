class Note {
  final String id;
  final String todoId;
  final String title;
  final String content;
  final int createdAt;
  final int? updatedAt;

  const Note({
    required this.id,
    required this.todoId,
    required this.title,
    required this.content,
    required this.createdAt,
    this.updatedAt,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          (other is Note &&
              id == other.id &&
              todoId == other.todoId &&
              title == other.title &&
              content == other.content &&
              createdAt == other.createdAt &&
              updatedAt == other.updatedAt);

  @override
  int get hashCode =>
      id.hashCode ^
      todoId.hashCode ^
      title.hashCode ^
      content.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode;

  @override
  String toString() {
    return 'Note{id: $id, todoId: $todoId, title: $title, content: $content, createdAt: $createdAt, updatedAt: $updatedAt}';
  }

  Note copyWith({
    String? title,
    String? content,
    int? createdAt,
    int? updatedAt,
  }) {
    return Note(
      id: id,
      todoId: todoId,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'todoId': todoId,
      'title': title,
      'content': content,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory Note.fromJson(Map<String, dynamic> map) {
    return Note(
      id: map['id'] as String,
      todoId: map['todoId'] as String,
      title: map['title'] as String,
      content: map['content'] as String,
      createdAt: map['createdAt'] as int,
      updatedAt: map['updatedAt'] as int?,
    );
  }
}
