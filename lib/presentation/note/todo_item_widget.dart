import 'package:flutter/material.dart';
import 'package:todolist/model/todo.dart';

class TodoItemWidget extends StatefulWidget {
  final Todo todo;
  final VoidCallback onToggleDone;
  final VoidCallback onToggleFavorite;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const TodoItemWidget({
    super.key,
    required this.todo,
    required this.onToggleDone,
    required this.onToggleFavorite,
    required this.onTap,
    required this.onDelete,
  });

  @override
  State<TodoItemWidget> createState() => _TodoItemWidgetState();
}

class _TodoItemWidgetState extends State<TodoItemWidget> {
  double _scale = 1.0;

  double get checklistProgress {
    final list = widget.todo.checklist ?? [];
    if (list.isEmpty) return 0;
    final done = list.where((e) => e['isChecked'] == true).length;
    return done / list.length;
  }

  void _tapDown(TapDownDetails d) => setState(() => _scale = 0.97);
  void _tapUp(TapUpDetails d) => setState(() => _scale = 1.0);
  void _cancel() => setState(() => _scale = 1.0);

  @override
  Widget build(BuildContext context) {
    final todo = widget.todo;
    final progress = checklistProgress;

    return Dismissible(
      key: ValueKey(todo.key),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => widget.onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.redAccent.withOpacity(0.8),
          borderRadius: BorderRadius.circular(22),
        ),
        child: const Icon(Icons.delete, color: Colors.white, size: 28),
      ),
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: _tapDown,
        onTapUp: _tapUp,
        onTapCancel: _cancel,
        child: AnimatedScale(
          scale: _scale,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(todo.color ?? 0xFF4FACFE).withOpacity(0.88),
                  Color(todo.color ?? 0xFF4FACFE).withOpacity(0.55),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 18,
                  offset: const Offset(3, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: widget.onToggleDone,
                  child: Icon(
                    todo.isDone ? Icons.check_circle_rounded : Icons.circle_outlined,
                    size: 28,
                    color: todo.isDone ? Colors.lightBlueAccent : Colors.white60,
                  ),
                ),
                const SizedBox(width: 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        todo.title,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          decoration: todo.isDone ? TextDecoration.lineThrough : null,
                        ),
                      ),

                      if (todo.tags != null && todo.tags!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          children: todo.tags!.map((t) {
                            return Chip(
                              label: Text('#$t'),
                              labelStyle: const TextStyle(color: Colors.white, fontSize: 11),
                              backgroundColor: Colors.white.withOpacity(0.15),
                              padding: EdgeInsets.zero,
                            );
                          }).toList(),
                        )
                      ],

                      if (todo.checklist != null && todo.checklist!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 6,
                            color: Colors.lightBlueAccent,
                            backgroundColor: Colors.white24,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          "체크리스트 ${(progress * 100).toStringAsFixed(0)}%",
                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ]
                    ],
                  ),
                ),

                IconButton(
                  onPressed: widget.onToggleFavorite,
                  icon: Icon(
                    todo.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: todo.isFavorite ? Colors.pinkAccent : Colors.white38,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
