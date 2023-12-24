import 'package:hive/hive.dart';

part 'todo.g.dart';


@HiveType( typeId: 0)
class Todo extends HiveObject {
  @HiveField(0)
  int? id;
  @HiveField(1)
  String title; //제목
  @HiveField(2)
  int dateTime; // 시간

  Todo({
    required this.title,
    required this.dateTime,
  });
}
