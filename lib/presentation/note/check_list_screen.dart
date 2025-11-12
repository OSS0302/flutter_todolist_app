import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import 'package:todolist/model/todo.dart';
import 'package:todolist/presentation/list_view_model.dart';

class ChecklistScreen extends StatefulWidget {
  final Todo todo;
  const ChecklistScreen({super.key, required this.todo});

  @override
  State<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends State<ChecklistScreen> {
  final controller = TextEditingController();
  bool hideCompleted = false;

  /// ✅ 완료 항목 정렬 (완료 → 아래)
  void _sortChecklist() {
    final list = widget.todo.checklist!;
    list.sort((a, b) {
      final aChecked = a['isChecked'] == true;
      final bChecked = b['isChecked'] == true;
      if (aChecked == bChecked) return 0;
      return aChecked ? 1 : -1;
    });
  }

  /// ✅ 전체 완료
  void _checkAll() {
    setState(() {
      for (var item in widget.todo.checklist!) {
        item['isChecked'] = true;
      }
      _sortChecklist();
    });
    widget.todo.save();
    context.read<ListViewModel>().refresh();
  }

  /// ✅ 전체 해제
  void _uncheckAll() {
    setState(() {
      for (var item in widget.todo.checklist!) {
        item['isChecked'] = false;
      }
    });
    widget.todo.save();
    context.read<ListViewModel>().refresh();
  }

  @override
  Widget build(BuildContext context) {
    final todo = widget.todo;
    final checklist = todo.checklist ?? [];

    final total = checklist.length;
    final done = checklist.where((e) => e['isChecked'] == true).length;
    final progress = total == 0 ? 0 : done / total;

    final visibleItems = hideCompleted
        ? checklist.where((e) => e['isChecked'] == false).toList()
        : checklist;

    return Scaffold(
      appBar: AppBar(
        title: Text("체크리스트 (${done}/${total})"),
        actions: [
          IconButton(
            tooltip: hideCompleted ? "완료 항목 보기" : "완료 항목 숨기기",
            icon: Icon(
              hideCompleted ? Icons.visibility_off : Icons.visibility,
            ),
            onPressed: () => setState(() => hideCompleted = !hideCompleted),
          ),
          PopupMenuButton(
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'checkAll', child: Text("전체 완료")),
              const PopupMenuItem(value: 'uncheckAll', child: Text("전체 해제")),
            ],
            onSelected: (value) {
              if (value == 'checkAll') _checkAll();
              if (value == 'uncheckAll') _uncheckAll();
            },
          )
        ],
      ),

      body: Column(
        children: [
          /// ✅ Progress Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              borderRadius: BorderRadius.circular(8),
              backgroundColor: Colors.grey[300],
            ),
          ),

          Expanded(
            child: visibleItems.isEmpty
                ? const Center(
              child: Text("체크리스트가 비어있어요",
                  style: TextStyle(color: Colors.grey)),
            )
                : ReorderableListView(
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex--;
                  final item = todo.checklist!.removeAt(oldIndex);
                  todo.checklist!.insert(newIndex, item);
                });
                todo.save();
                context.read<ListViewModel>().refresh();
              },
              children: [
                for (int i = 0; i < visibleItems.length; i++)
                  Slidable(
                    key: ValueKey("item_$i"),
                    endActionPane: ActionPane(
                      motion: const DrawerMotion(),
                      children: [
                        SlidableAction(
                          backgroundColor: Colors.red,
                          label: "삭제",
                          icon: Icons.delete,
                          onPressed: (_) {
                            setState(() => checklist.removeAt(i));
                            todo.save();
                            context.read<ListViewModel>().refresh();
                          },
                        ),
                      ],
                    ),
                    child: ListTile(
                      title: Row(
                        children: [
                          /// ✅ 애니메이션 체크 효과
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                visibleItems[i]['isChecked'] =
                                !visibleItems[i]['isChecked'];
                                _sortChecklist();
                              });
                              todo.save();
                              context.read<ListViewModel>().refresh();
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Colors.blue, width: 2),
                                color: visibleItems[i]['isChecked']
                                    ? Colors.blue
                                    : Colors.white,
                              ),
                              child: visibleItems[i]['isChecked']
                                  ? const Icon(Icons.check,
                                  size: 18, color: Colors.white)
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 12),

                          /// ✅ 취소선 애니메이션
                          Expanded(
                            child: AnimatedDefaultTextStyle(
                              duration:
                              const Duration(milliseconds: 300),
                              style: TextStyle(
                                decoration: visibleItems[i]['isChecked']
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                                color: visibleItems[i]['isChecked']
                                    ? Colors.grey
                                    : Colors.black,
                                fontSize: 16,
                              ),
                              child: Text(visibleItems[i]['title']),
                            ),
                          ),

                          /// ✅ 우선순위 버튼
                          IconButton(
                            icon: const Icon(Icons.arrow_upward),
                            onPressed: i == 0
                                ? null
                                : () {
                              setState(() {
                                final item =
                                visibleItems.removeAt(i);
                                visibleItems.insert(i - 1, item);
                              });
                              todo.save();
                              context
                                  .read<ListViewModel>()
                                  .refresh();
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.arrow_downward),
                            onPressed:
                            i == visibleItems.length - 1 ? null : () {
                              setState(() {
                                final item =
                                visibleItems.removeAt(i);
                                visibleItems.insert(i + 1, item);
                              });
                              todo.save();
                              context
                                  .read<ListViewModel>()
                                  .refresh();
                            },
                          ),
                        ],
                      ),
                    ),
                  )
              ],
            ),
          ),

          /// ✅ 추가 입력창
          Padding(
            padding:
            const EdgeInsets.only(bottom: 20, left: 20, right: 20, top: 5),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      labelText: "체크리스트 추가",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    if (controller.text.trim().isEmpty) return;

                    setState(() {
                      checklist.add({
                        "title": controller.text.trim(),
                        "isChecked": false,
                      });
                      controller.clear();
                      _sortChecklist();
                    });

                    todo.save();
                    context.read<ListViewModel>().refresh();
                  },
                  child: const Text("추가"),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
