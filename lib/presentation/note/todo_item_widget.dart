import 'package:flutter/material.dart';
import 'package:todolist/model/todo.dart';

class TodoItemWidget extends StatefulWidget {
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

  @override
  State<TodoItemWidget> createState() => _TodoItemWidgetState();
}

class _TodoItemWidgetState extends State<TodoItemWidget>
    with SingleTickerProviderStateMixin {
  double _scale = 1.0;

  /// ✅ 터치 애니메이션
  void _tapDown(TapDownDetails d) => setState(() => _scale = 0.97);
  void _tapUp(TapUpDetails d) => setState(() => _scale = 1.0);
  void _cancel() => setState(() => _scale = 1.0);

  double get checklistProgress {
    if (widget.todo.checklist == null || widget.todo.checklist!.isEmpty) return 0;
    final done = widget.todo.checklist!.where((e) => e['isChecked'] == true).length;
    return done / widget.todo.checklist!.length;
  }

  String get dday {
    if (widget.todo.dueDate == null) return '';
    final diff = widget.todo.dueDate!.difference(DateTime.now()).inDays;
    if (diff == 0) return "D-Day";
    if (diff > 0) return "D-$diff";
    return "D+${diff.abs()}";
  }

  Color get priorityColor {
    switch (widget.todo.priority) {
      case '높음':
        return Colors.redAccent;
      case '보통':
        return Colors.yellowAccent.shade700;
      case '낮음':
        return Colors.greenAccent;
      default:
        return Colors.white24;
    }
  }

  @override
  Widget build(BuildContext context) {
    final todo = widget.todo;
    final progress = checklistProgress;

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: _tapDown,
      onTapUp: _tapUp,
      onTapCancel: _cancel,
      child: AnimatedScale(
        scale: _scale,
        curve: Curves.easeOut,
        duration: const Duration(milliseconds: 120),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Color(todo.color ?? 0xFF3B4252).withOpacity(0.75),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withOpacity(0.08), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.45),
                blurRadius: 18,
                offset: const Offset(3, 6),
              ),
              BoxShadow( // ✅ 3D 반사광
                color: Colors.white.withOpacity(0.07),
                blurRadius: 6,
                offset: const Offset(-3, -2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// ✅ 체크박스
              GestureDetector(
                onTap: widget.onToggleDone,
                child: Icon(
                  todo.isDone
                      ? Icons.check_circle_rounded
                      : Icons.circle_outlined,
                  size: 28,
                  color: todo.isDone ? Colors.lightBlueAccent : Colors.white38,
                ),
              ),
              const SizedBox(width: 12),

              /// ✅ 텍스트 + 진행률
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
                              fontSize: 17,
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
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              todo.category!,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    /// D-Day + 우선순위
                    Row(
                      children: [
                        if (dday.isNotEmpty)
                          Text(
                            dday,
                            style: const TextStyle(
                                color: Colors.lightBlueAccent, fontSize: 12),
                          ),
                        if (todo.priority != null) ...[
                          const SizedBox(width: 10),
                          Icon(Icons.circle, size: 8, color: priorityColor),
                          const SizedBox(width: 4),
                          Text(
                            todo.priority!,
                            style: TextStyle(
                                color: priorityColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w500),
                          ),
                        ],
                      ],
                    ),

                    /// 체크리스트
                    if (todo.checklist != null && todo.checklist!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 6,
                                backgroundColor: Colors.white12,
                                color: Colors.lightBlueAccent,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "체크리스트 ${(progress * 100).toStringAsFixed(0)}%",
                              style: const TextStyle(
                                  color: Colors.white54, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              /// 즐겨찾기
              IconButton(
                onPressed: widget.onToggleFavorite,
                icon: Icon(
                  todo.isFavorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_outline_rounded,
                  color:
                  todo.isFavorite ? Colors.pinkAccent : Colors.white38,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
