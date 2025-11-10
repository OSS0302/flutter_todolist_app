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

  void _sortChecklist() {
    final list = widget.todo.checklist!;
    list.sort((a, b) {
      final aChecked = a['isChecked'] == true;
      final bChecked = b['isChecked'] == true;
      if (aChecked == bChecked) return 0;
      return aChecked ? 1 : -1; // 체크된 항목을 뒤로
    });
  }

  @override
  Widget build(BuildContext context) {
    final todo = widget.todo;

    return Scaffold(
      appBar: AppBar(title: const Text("체크리스트 편집")),
      body: Column(
        children: [
          Expanded(
            child: todo.checklist == null || todo.checklist!.isEmpty
                ? const Center(
              child: Text(
                "체크리스트를 추가해주세요",
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            )
                : ReorderableListView(
              padding: const EdgeInsets.all(10),
              onReorder: (oldIndex, newIndex) async {
                setState(() {
                  if (newIndex > oldIndex) newIndex--;
                  final item = todo.checklist!.removeAt(oldIndex);
                  todo.checklist!.insert(newIndex, item);
                });
                await todo.save();
                context.read<ListViewModel>().refresh();
              },
              children: [
                for (int i = 0; i < todo.checklist!.length; i++)
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
                            setState(() {
                              todo.checklist!.removeAt(i);
                            });
                            todo.save();
                            context.read<ListViewModel>().refresh();
                          },
                        ),
                      ],
                    ),
                    child: ListTile(
                      title: Row(
                        children: [
                          Checkbox(
                            value: todo.checklist![i]['isChecked'],
                            onChanged: (v) {
                              setState(() {
                                todo.checklist![i]['isChecked'] = v;
                                _sortChecklist();
                              });
                              todo.save();
                              context.read<ListViewModel>().refresh();
                            },
                          ),
                          Expanded(
                            child: AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 200),
                              style: TextStyle(
                                color: todo.checklist![i]['isChecked']
                                    ? Colors.grey
                                    : Colors.black,
                                decoration: todo.checklist![i]['isChecked']
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                                fontSize: 16,
                              ),
                              child:
                              Text(todo.checklist![i]['title']),
                            ),
                          ),

                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_upward),
                                onPressed: i == 0
                                    ? null
                                    : () {
                                  setState(() {
                                    final item = todo.checklist!.removeAt(i);
                                    todo.checklist!.insert(i - 1, item);
                                  });
                                  todo.save();
                                  context.read<ListViewModel>().refresh();
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.arrow_downward),
                                onPressed: i == todo.checklist!.length - 1
                                    ? null
                                    : () {
                                  setState(() {
                                    final item = todo.checklist!.removeAt(i);
                                    todo.checklist!.insert(i + 1, item);
                                  });
                                  todo.save();
                                  context.read<ListViewModel>().refresh();
                                },
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  )
              ],
            ),
          ),

          const Divider(),

          Padding(
            padding: const EdgeInsets.all(10),
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
                      todo.checklist ??= [];
                      todo.checklist!.add({
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
