import 'package:hive/hive.dart';

part 'note.g.dart';

@HiveType(typeId: 1)
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

  @HiveField(7)
  List<String>? tags;

  @HiveField(8)
  bool isArchived;

  @HiveField(9)
  List<String>? checklist;

  @HiveField(10)
  int color;

  @HiveField(11)
  bool isStarred;

  @HiveField(12)
  bool isDeleted;

  @HiveField(13)
  int? reminder; // 🆕 리마인더 (timestamp)

  Note({
    required this.id,
    required this.todoId,
    required this.title,
    required this.content,
    required this.createdAt,
    this.updatedAt,
    this.isPinned = false,
    this.tags,
    this.color = 0xFFFFF3E0,
    this.isArchived = false,
    this.checklist,
    this.isStarred = false,
    this.isDeleted = false,
    this.reminder,
  });

  Note copyWith({
    String? title,
    String? content,
    int? createdAt,
    int? updatedAt,
    bool? isPinned,
    int? color,
    List<String>? tags,
    bool? isArchived,
    List<String>? checklist,
    bool? isStarred,
    bool? isDeleted,
    int? reminder,
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
      tags: tags ?? this.tags,
      isArchived: isArchived ?? this.isArchived,
      checklist: checklist ?? this.checklist,
      isStarred: isStarred ?? this.isStarred,
      isDeleted: isDeleted ?? this.isDeleted,
      reminder: reminder ?? this.reminder,
    );
  }
}
