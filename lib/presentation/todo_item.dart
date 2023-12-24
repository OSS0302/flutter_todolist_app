import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:todolist/model/todo.dart';

class TodoItem extends StatelessWidget {
  final Todo todo;
  final Function(Todo) onTapCallBack;

  const TodoItem({super.key, required this.todo, required this.onTapCallBack});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () {
        onTapCallBack(todo);
      },
      leading: todo.isDone
          ? const Icon(
              Icons.check_circle,
              color: Colors.green,
            )
          : const Icon(
              Icons.check_circle_outline,
            ),
      title: Text(
        todo.title,
      ),
      subtitle: Text(
      '${todo.dateTime}'
      ),
    );
  }
}
