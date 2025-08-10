import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:todolist/model/todo.dart';
import 'package:go_router/go_router.dart';

class TodoItem extends StatelessWidget {
  final Todo todo;
  final String formattedDate;
  final void Function(Todo) onTapCallBack;
  final void Function(Todo) onDelete;
  final Widget? trailing;

  const TodoItem({
    Key? key,
    required this.todo,
    required this.formattedDate,
    required this.onTapCallBack,
    required this.onDelete,
    this.trailing,
  }) : super(key: key);

  Color _priorityColor(String? priority) {
    switch (priority) {
      case 'high':
        return Colors.redAccent;
      case 'medium':
        return Colors.orangeAccent;
      case 'low':
        return Colors.greenAccent;
      default:
        return Colors.grey;
    }
  }

  IconData _priorityIcon(String? priority) {
    switch (priority) {
      case 'high':
        return Icons.priority_high;
      case 'medium':
        return Icons.low_priority;
      case 'low':
        return Icons.arrow_downward;
      default:
        return Icons.label_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dueDateText = todo.dueDate != null
        ? DateFormat('yyyy-MM-dd').format(todo.dueDate!)
        : '마감일 없음';

    return Card(
      color: todo.isDone ? Colors.grey[850] : Colors.black54,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        leading: IconButton(
          icon: Icon(
            todo.isDone ? Icons.check_circle : Icons.radio_button_unchecked,
            color: todo.isDone ? Colors.greenAccent : Colors.white54,
            size: 28,
          ),
          onPressed: () => onTapCallBack(todo),
        ),
        title: Text(
          todo.title,
          style: TextStyle(
            color: todo.isDone ? Colors.white54 : Colors.white,
            fontWeight: FontWeight.bold,
            decoration: todo.isDone ? TextDecoration.lineThrough : null,
            fontSize: 18,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '생성일: $formattedDate',
              style: const TextStyle(color: Colors.white70),
            ),
            Text(
              '마감일: $dueDateText',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
        trailing: Wrap(
          spacing: 12,
          children: [
            if (todo.isFavorite)
              const Icon(Icons.star, color: Colors.amber, size: 24),
            Icon(
              _priorityIcon(todo.priority),
              color: _priorityColor(todo.priority),
            ),
            // 📌 메모 버튼 추가
            IconButton(
              icon: const Icon(Icons.note, color: Colors.amber),
              onPressed: () {
                context.push(
                  '/noteScreen/${todo.id}/${Uri.encodeComponent(todo.title)}',
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: () => onDelete(todo),
            ),
          ],
        ),
      ),
    );
  }
}
