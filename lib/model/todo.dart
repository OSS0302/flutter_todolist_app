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

  Todo({
    required this.title,
    required this.dateTime,
    this.isDone = false,
    this.dueDate,
    this.priority,
  });
}
