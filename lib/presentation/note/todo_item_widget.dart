import 'package:flutter/material.dart';
import 'package:todolist/model/todo.dart';

class TodoItemWidget extends StatelessWidget {
  final Todo todo;
  final VoidCallback onToggleDone;
  final VoidCallback onToggleFavorite;
  final VoidCallback onTap;

  const TodoItemWidget({
    super.key,
    required this.todo,
    required this.onToggleDone,
    required this.onToggleFavorite,
    required this.onTap,
  });

  double _getChecklistProgress() {
    if (todo.checklist == null || todo.checklist!.isEmpty) return 0;
    final checked =
        todo.checklist!.where((e) => e['isChecked'] == true).length;
    return checked / todo.checklist!.length;
  }

  @override
  Widget build(BuildContext context) {
    final progress = _getChecklistProgress();
    final progressPercent = (progress * 100).toStringAsFixed(0);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Color(todo.color ?? 0xFF2E3440).withOpacity(0.8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(2, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: onToggleDone,
              child: Icon(
                todo.isDone
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked,
                color: todo.isDone ? Colors.lightBlueAccent : Colors.white54,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    todo.title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      decoration: todo.isDone
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                    ),
                  ),
                  if (todo.dueDate != null)
                    Text(
                      "마감: ${todo.dueDate!.year}.${todo.dueDate!.month}.${todo.dueDate!.day}",
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 12),
                    ),
                  if (todo.checklist != null && todo.checklist!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          LinearProgressIndicator(
                            value: progress,
                            backgroundColor: Colors.white12,
                            color: Colors.lightBlueAccent,
                            minHeight: 6,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "체크리스트 $progressPercent%",
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                todo.isFavorite
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                color:
                todo.isFavorite ? Colors.pinkAccent : Colors.white54,
              ),
              onPressed: onToggleFavorite,
            ),
          ],
        ),
      ),
    );
  }
}
