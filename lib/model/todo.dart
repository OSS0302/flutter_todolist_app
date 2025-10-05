import 'package:hive/hive.dart';

part 'todo.g.dart';

@HiveType(typeId: 0)
class Todo extends HiveObject {
  @HiveField(0)
  int? id;

  @HiveField(1)
  String title; // 제목

  @HiveField(2)
  int dateTime; // 생성 시간 (timestamp)

  @HiveField(3)
  bool isDone;

  @HiveField(4)
  DateTime? dueDate;

  @HiveField(5)
  String? priority;

  @HiveField(6)
  bool isFavorite;

  @HiveField(7)
  String? category;

  /// ✅ 새로 추가된 필드들
  @HiveField(8)
  int? color; // 선택된 색상 값 (Color.value)

  @HiveField(9)
  List<String>? tags; // 태그 목록

  @HiveField(10)
  List<Map<String, dynamic>>? checklist; // 체크리스트 목록

  Todo({
    required this.title,
    required this.dateTime,
    this.isDone = false,
    this.dueDate,
    this.priority,
    this.isFavorite = false,
    this.category,
    this.color,
    this.tags,
    this.checklist,
  });

  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo(
      title: json['title'],
      isDone: json['isDone'] ?? false,
      dateTime: json['dateTime'],
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
      priority: json['priority'],
      category: json['category'],
      color: json['color'],
      tags: (json['tags'] as List?)?.map((e) => e.toString()).toList(),
      checklist: (json['checklist'] as List?)
          ?.map((e) => Map<String, dynamic>.from(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'isDone': isDone,
      'dateTime': dateTime,
      'dueDate': dueDate?.toIso8601String(),
      'priority': priority,
      'category': category,
      'color': color,
      'tags': tags,
      'checklist': checklist,
    };
  }
}
