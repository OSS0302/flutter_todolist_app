import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todolist/model/todo.dart';
import 'package:todolist/presentation/note/check_list_screen.dart';

import '../list_view_model.dart';

class TodoCard extends StatefulWidget {
  final Todo todo;
  const TodoCard({super.key, required this.todo});

  @override
  State<TodoCard> createState() => _TodoCardState();
}

class _TodoCardState extends State<TodoCard> {
  bool _isExpanded = false;

  double get progress {
    if (widget.todo.checklist == null || widget.todo.checklist!.isEmpty) {
      return 0;
    }
    final checked = widget.todo.checklist!.where((c) => c['isChecked']).length;
    return checked / widget.todo.checklist!.length;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(widget.todo.color ?? 0xFF4FACFE).withOpacity(0.15), // ✅ 오류 해결
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white30, width: 1),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Checkbox(
                value: widget.todo.isDone,
                onChanged: (_) => context.read<ListViewModel>().toggleDone(widget.todo),
              ),

              Expanded(
                child: Text(
                  widget.todo.title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    decoration: widget.todo.isDone ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),

              SizedBox(
                width: 32,
                height: 32,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 3,
                      backgroundColor: Colors.white24,
                    ),
                    Center(
                      child: Text(
                        "${(progress * 100).toInt()}%",
                        style: const TextStyle(fontSize: 9, color: Colors.white),
                      ),
                    )
                  ],
                ),
              ),

              IconButton(
                icon: const Icon(Icons.checklist, color: Colors.white70),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChecklistScreen(todo: widget.todo),
                    ),
                  );
                },
              ),

              IconButton(
                icon: Icon(
                  _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: Colors.white70,
                ),
                onPressed: () => setState(() => _isExpanded = !_isExpanded),
              ),
            ],
          ),

          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: !_isExpanded
                ? const SizedBox.shrink()
                : Column(
              children: [
                const SizedBox(height: 8),
                ...(widget.todo.checklist ?? []).map((item) {
                  return GestureDetector(
                    onTap: () {
                      setState(() => item['isChecked'] = !item['isChecked']);
                      widget.todo.save();
                      context.read<ListViewModel>().refresh();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Icon(
                            item['isChecked']
                                ? Icons.check_circle
                                : Icons.circle_outlined,
                            color: item['isChecked']
                                ? Colors.lightBlueAccent
                                : Colors.white54,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              item['title'],
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                                decoration: item['isChecked']
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),

                if (widget.todo.checklist == null || widget.todo.checklist!.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text(
                      "체크리스트 없음",
                      style: TextStyle(color: Colors.white38, fontSize: 13),
                    ),
                  ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
