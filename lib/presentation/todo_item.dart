import 'package:flutter/material.dart';
import 'package:todolist/model/todo.dart';

class TodoItem extends StatelessWidget {
  final Todo todo;
  final String formattedDate;
  final Function(Todo) onTapCallBack; // 완료 토글용
  final Function(Todo) onDelete;
  final Widget trailing;

  const TodoItem({
    Key? key,
    required this.todo,
    required this.formattedDate,
    required this.onTapCallBack,
    required this.onDelete,
    required this.trailing,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () => onTapCallBack(todo),
      leading: todo.isDone
          ? const Icon(Icons.check_circle, color: Colors.green)
          : const Icon(Icons.check_circle_outline),
      title: Text(
        todo.title,
        style: TextStyle(color: todo.isDone ? Colors.grey : Colors.black),
      ),
      subtitle: Text(
        formattedDate,
        style: TextStyle(color: todo.isDone ? Colors.grey : Colors.black),
      ),
      trailing: todo.isDone
          ? GestureDetector(
        onTap: () => onDelete(todo),
        child: const Icon(Icons.delete),
      )
          : null,
    );
  }
}
