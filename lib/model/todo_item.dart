class Todo {
  final String title;
  final int dateTime;
  final DateTime? dueDate;   // 추가
  final String? priority;    // 추가

  Todo({
    required this.title,
    required this.dateTime,
    this.dueDate,        // optional
    this.priority,       // optional
  });
}