import 'package:flutter/material.dart';
import 'package:todolist/model/todo.dart';

class TodoItem extends StatelessWidget {
  final Todo todo;
  final String formattedDate;
  final Function(Todo) onTapCallBack; // 완료 토글용
  final Function(Todo) onDelete;
  final Widget? trailing; // 수정: nullable 로 변경

  const TodoItem({
    Key? key,
    required this.todo,
    required this.formattedDate,
    required this.onTapCallBack,
    required this.onDelete,
    this.trailing, // trailing 은 선택적 전달
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
        style: TextStyle(
          color: todo.isDone ? Colors.grey : Colors.black,
          decoration: todo.isDone ? TextDecoration.lineThrough : null,
        ),
      ),
      subtitle: Text(
        formattedDate,
        style: TextStyle(color: todo.isDone ? Colors.grey : Colors.black),
      ),
      trailing: trailing ??
          (todo.isDone
              ? GestureDetector(
            onTap: () => onDelete(todo),
            child: const Icon(Icons.delete, color: Colors.redAccent),
          )
              : const Icon(Icons.arrow_forward_ios, size: 16)),
    );
  }
}
