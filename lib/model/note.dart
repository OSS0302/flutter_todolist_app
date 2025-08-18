import 'package:hive/hive.dart';

part 'note.g.dart';

@HiveType(typeId: 1) // typeId는 프로젝트에서 고유하게 설정
class Note extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String todoId;

  @HiveField(2)
  String title;

  @HiveField(3)
  String content;

  @HiveField(4)
  int createdAt;

  @HiveField(5)
  int? updatedAt;

  @HiveField(6)
  bool isPinned;

  int color;

  Note({
    required this.id,
    required this.todoId,
    required this.title,
    required this.content,
    required this.createdAt,
    this.updatedAt,
    this.isPinned = false,
    this.color = 0xFFFFF3E0,
  });

  Note copyWith({
    String? title,
    String? content,
    int? createdAt,
    int? updatedAt,
    bool? isPinned,
    int? color,
  }) {
    return Note(
      id: id,
      todoId: todoId,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isPinned: isPinned ?? this.isPinned,
      color: color ?? this.color,
    );
  }

  factory Note.fromJson(Map<String, dynamic> map) {
    return Note(
      id: map['id'] as String,
      todoId: map['todoId'] as String,
      title: map['title'] as String,
      content: map['content'] as String,
      createdAt: map['createdAt'] as int,
      updatedAt: map['updatedAt'] as int?,
      isPinned: map['isPinned'] as bool? ?? false,
      color: map['color'] as int? ?? 0xFFFFF3E0,
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
      'isPinned': isPinned,
      'color': color,
    };
  }
}