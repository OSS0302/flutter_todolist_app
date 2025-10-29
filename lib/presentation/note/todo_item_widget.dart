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

  /// ✅ 체크리스트 진행률 계산
  double _getChecklistProgress() {
    if (todo.checklist == null || todo.checklist!.isEmpty) return 0;
    final checked = todo.checklist!.where((e) => e['isChecked'] == true).length;
    return checked / todo.checklist!.length;
  }

  /// ✅ D-Day 계산
  String _getDDayText() {
    if (todo.dueDate == null) return '';
    final now = DateTime.now();
    final diff = todo.dueDate!.difference(now).inDays;
    if (diff == 0) return "D-Day";
    if (diff > 0) return "D-${diff}";
    return "D+${diff.abs()}";
  }

  /// ✅ 우선순위 색상
  Color _getPriorityColor() {
    switch (todo.priority) {
      case '높음':
        return Colors.redAccent;
      case '보통':
        return Colors.amberAccent;
      case '낮음':
        return Colors.greenAccent;
      default:
        return Colors.white38;
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = _getChecklistProgress();
    final progressPercent = (progress * 100).toStringAsFixed(0);
    final dday = _getDDayText();
    final priorityColor = _getPriorityColor();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Color(todo.color ?? 0xFF2E3440).withOpacity(0.85),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 8,
              offset: const Offset(2, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// ✅ 체크박스
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

            /// ✅ 본문
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// 제목 + 카테고리
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          todo.title,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            decoration: todo.isDone
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                          ),
                        ),
                      ),
                      if (todo.category != null && todo.category!.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: Text(
                            todo.category!,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 11),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  /// D-Day, 우선순위
                  Row(
                    children: [
                      if (dday.isNotEmpty)
                        Text(
                          dday,
                          style: TextStyle(
                              color: Colors.lightBlueAccent, fontSize: 12),
                        ),
                      const SizedBox(width: 8),
                      if (todo.priority != null)
                        Row(
                          children: [
                            Icon(Icons.circle, color: priorityColor, size: 8),
                            const SizedBox(width: 4),
                            Text(
                              todo.priority!,
                              style: TextStyle(
                                  color: priorityColor, fontSize: 12),
                            ),
                          ],
                        ),
                    ],
                  ),

                  /// 체크리스트 진행률
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
                                color: Colors.white70, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            /// 즐겨찾기
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
