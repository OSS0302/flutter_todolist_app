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

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(widget.todo.color).withOpacity(0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white24,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// --- 메인 상단 줄 ---
          Row(
            children: [
              Checkbox(
                value: widget.todo.isDone,
                onChanged: (_) async {
                  context.read<ListViewModel>().toggleDone(widget.todo);
                },
              ),

              // 제목
              Expanded(
                child: Text(
                  widget.todo.title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    decoration:
                    widget.todo.isDone ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),

              // 체크리스트 아이콘 → 편집 화면 이동 (2번 기능)
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChecklistScreen(todo: widget.todo),
                    ),
                  );
                },
                icon: const Icon(Icons.checklist, color: Colors.white70),
              ),

              // 펼치기 버튼
              IconButton(
                onPressed: () => setState(() => _isExpanded = !_isExpanded),
                icon: Icon(
                  _isExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: Colors.white60,
                ),
              ),
            ],
          ),

          /// --- 펼쳐졌을 때 체크리스트 표시 (1번 기능) ---
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: !_isExpanded
                ? const SizedBox.shrink()
                : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                ...widget.todo.checklist!.map((c) {
                  return Row(
                    children: [
                      Icon(
                        c['isChecked'] ? Icons.check_circle : Icons.circle,
                        size: 18,
                        color: Colors.white70,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          c['title'],
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 14),
                        ),
                      ),
                    ],
                  );
                }).toList(),
                if (widget.todo.checklist!.isEmpty)
                  const Text("체크리스트 없음",
                      style:
                      TextStyle(color: Colors.white38, fontSize: 12)),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
