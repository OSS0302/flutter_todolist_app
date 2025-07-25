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

  String? category;

  Todo({
    required this.title,
    required this.dateTime,
    this.isDone = false,
    this.dueDate,
    this.priority,
    this.isFavorite = false,
    this.category
  });

  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo(
      title: json['title'],
      isDone: json['isDone'] ?? false,
      dateTime: json['dateTime'],
      dueDate: json['dueDate'] != null
          ? DateTime.parse(json['dueDate'])
          : null,
      priority: json['priority'],
      category: json['category'], // ✅ JSON 파싱
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
      'category': category, // ✅ JSON 직렬화
    };
  }
}


