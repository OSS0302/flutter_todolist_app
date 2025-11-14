import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todolist/model/todo.dart';
import 'package:todolist/presentation/list_view_model.dart';

class ChecklistScreen extends StatefulWidget {
  final Todo todo;
  const ChecklistScreen({super.key, required this.todo});

  @override
  State<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends State<ChecklistScreen>
    with SingleTickerProviderStateMixin {
  final controller = TextEditingController();
  bool hideCompleted = false;

  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 250));
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _sortChecklist() {
    widget.todo.checklist!.sort((a, b) {
      final aCheck = a['isChecked'] == true;
      final bCheck = b['isChecked'] == true;
      return aCheck ? 1 : -1;
    });
  }

  void _saveReorder(int oldIndex, int newIndex) {
    final list = widget.todo.checklist!;
    if (newIndex > oldIndex) newIndex--;

    final movedItem = list.removeAt(oldIndex);
    list.insert(newIndex, movedItem);

    widget.todo.save();
    context.read<ListViewModel>().refresh();
  }

  @override
  Widget build(BuildContext context) {
    final todo = widget.todo;
    final allItems = todo.checklist ?? [];

    final activeItems = allItems.where((e) => e['isChecked'] == false).toList();
    final doneItems   = allItems.where((e) => e['isChecked'] == true).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text("체크리스트 (${doneItems.length}/${allItems.length})"),
        actions: [
          IconButton(
            tooltip: hideCompleted ? "완료 보기" : "완료 숨기기",
            icon: Icon(hideCompleted ? Icons.visibility_off : Icons.visibility),
            onPressed: () => setState(() => hideCompleted = !hideCompleted),
          )
        ],
      ),

      body: Column(
        children: [
          const SizedBox(height: 10),

          /// ================================
          /// 🌟 Drag & Drop 가능한 체크리스트
          /// ================================
          Expanded(
            child: ReorderableListView(
              padding: const EdgeInsets.all(12),
              onReorder: _saveReorder,
              children: [


                if (activeItems.isNotEmpty)
                  Padding(
                    key: const ValueKey("todo_header"),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: const Text("해야 할 일",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),

                for (var item in activeItems)
                  _buildChecklistTile(item, false),


                if (!hideCompleted && doneItems.isNotEmpty) ...[
                  Padding(
                    key: const ValueKey("done_header"),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: const Text("완료된 항목",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),

                  for (var item in doneItems)
                    _buildChecklistTile(item, true),
                ],
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                        labelText: "체크리스트 항목 추가",
                        border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    if (controller.text.trim().isEmpty) return;

                    setState(() {
                      todo.checklist!.add({
                        'title': controller.text.trim(),
                        'isChecked': false,
                      });
                      controller.clear();
                      _sortChecklist();
                    });

                    todo.save();
                    context.read<ListViewModel>().refresh();
                  },
                  child: const Text("추가"),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildChecklistTile(Map<String, dynamic> item, bool isDone) {
    return Card(
      key: ValueKey(item),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        title: Row(
          children: [
            GestureDetector(
              onTap: () {
                setState(() {
                  item['isChecked'] = !item['isChecked'];
                  _sortChecklist();
                });

                _animController.forward(from: 0);

                widget.todo.save();
                context.read<ListViewModel>().refresh();
              },
              child: ScaleTransition(
                scale: Tween(begin: 1.0, end: 1.3).animate(
                    CurvedAnimation(parent: _animController, curve: Curves.easeOut)),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.blueAccent, width: 2),
                    color: isDone ? Colors.blueAccent : Colors.white,
                    boxShadow: isDone
                        ? [
                      BoxShadow(
                        color: Colors.blueAccent.withOpacity(0.5),
                        blurRadius: 8,
                        spreadRadius: 1,
                      )
                    ]
                        : [],
                  ),
                  child: isDone
                      ? const Icon(Icons.check, size: 18, color: Colors.white)
                      : null,
                ),
              ),
            ),
            const SizedBox(width: 12),

            Expanded(
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                style: TextStyle(
                  decoration: isDone ? TextDecoration.lineThrough : null,
                  color: isDone ? Colors.grey : Colors.black,
                  fontSize: 16,
                ),
                child: Text(item['title']),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
