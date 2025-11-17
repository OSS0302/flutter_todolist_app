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

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }


  void _sortChecklist() {
    widget.todo.checklist!.sort((a, b) {
      // 1) 고정(Pinned) 우선
      final aPinned = a['pinned'] == true;
      final bPinned = b['pinned'] == true;
      if (aPinned != bPinned) return aPinned ? -1 : 1;

      // 2) 중요도 우선 (2 > 1 > 0)
      final aPr = a['priority'] ?? 1;
      final bPr = b['priority'] ?? 1;
      if (aPr != bPr) return bPr - aPr;

      final aChecked = a['isChecked'] == true;
      final bChecked = b['isChecked'] == true;
      if (aChecked != bChecked) return aChecked ? 1 : -1;

      return 0;
    });
  }

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

  void _uncheckAll() {
    setState(() {
      for (var item in widget.todo.checklist!) {
        item['isChecked'] = false;
      }
      _sortChecklist();
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
            icon: Icon(hideCompleted ? Icons.visibility_off : Icons.visibility),
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
          // 진행률 ProgressBar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: progress.toDouble()),
              duration: const Duration(milliseconds: 400),
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: 7,
                borderRadius: BorderRadius.circular(8),
                backgroundColor: Colors.grey[300],
                color: Colors.blueAccent,
              ),
            ),
          ),

          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: visibleItems.isEmpty
                  ? const Center(
                key: ValueKey("empty"),
                child: Text("체크리스트가 비어있어요",
                    style: TextStyle(color: Colors.grey)),
              )
                  : ListView.builder(
                key: ValueKey("list"),
                itemCount: visibleItems.length,
                itemBuilder: (context, i) {
                  final item = visibleItems[i];
                  final isChecked = item['isChecked'] == true;
                  final priority = item['priority'] ?? 1;

                  return AnimatedOpacity(
                    key: ValueKey(item),
                    opacity: isChecked && hideCompleted ? 0.0 : 1.0,
                    duration: const Duration(milliseconds: 300),
                    child: Dismissible(
                      key: UniqueKey(),
                      direction: DismissDirection.endToStart,
                      onDismissed: (_) {
                        setState(() => checklist.remove(item));
                        todo.save();
                        context.read<ListViewModel>().refresh();
                      },
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 16),
                        child:
                        const Icon(Icons.delete, color: Colors.white),
                      ),


                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        child: Card(
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ListTile(
                            title: Row(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      item['isChecked'] = !isChecked;
                                      _sortChecklist();
                                    });
                                    _animationController.forward(from: 0);
                                    todo.save();
                                    context.read<ListViewModel>().refresh();
                                  },
                                  child: ScaleTransition(
                                    scale: Tween<double>(
                                      begin: 1.0,
                                      end: 1.3,
                                    ).animate(CurvedAnimation(
                                      parent: _animationController,
                                      curve: Curves.easeOut,
                                    )),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 250),
                                      width: 26,
                                      height: 26,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.blueAccent,
                                          width: 2,
                                        ),
                                        color: isChecked
                                            ? Colors.blueAccent
                                            : Colors.white,
                                        boxShadow: isChecked
                                            ? [
                                          BoxShadow(
                                            color: Colors.blueAccent
                                                .withOpacity(0.5),
                                            blurRadius: 8,
                                            spreadRadius: 1,
                                          )
                                        ]
                                            : [],
                                      ),
                                      child: isChecked
                                          ? const Icon(Icons.check,
                                          size: 18,
                                          color: Colors.white)
                                          : null,
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 12),

                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: priority == 2
                                        ? Colors.red
                                        : priority == 1
                                        ? Colors.blue
                                        : Colors.grey,
                                  ),
                                ),

                                const SizedBox(width: 8),

                                Expanded(
                                  child: AnimatedDefaultTextStyle(
                                    duration:
                                    const Duration(milliseconds: 300),
                                    style: TextStyle(
                                      decoration: isChecked
                                          ? TextDecoration.lineThrough
                                          : TextDecoration.none,
                                      color: isChecked
                                          ? Colors.grey
                                          : Colors.black,
                                      fontSize: 16,
                                    ),
                                    child: Text(item['title']),
                                  ),
                                ),
                              ],
                            ),

                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                /// 중요도 선택
                                PopupMenuButton(
                                  icon: const Icon(Icons.flag),
                                  onSelected: (value) {
                                    setState(() {
                                      item['priority'] = value;
                                      _sortChecklist();
                                    });
                                    todo.save();
                                    context.read<ListViewModel>().refresh();
                                  },
                                  itemBuilder: (_) => [
                                    const PopupMenuItem(
                                        value: 2, child: Text("🔥 중요")),
                                    const PopupMenuItem(
                                        value: 1, child: Text("⭐ 보통")),
                                    const PopupMenuItem(
                                        value: 0, child: Text("⬇️ 낮음")),
                                  ],
                                ),

                                /// 고정 버튼
                                IconButton(
                                  icon: Icon(
                                    item['pinned'] == true
                                        ? Icons.push_pin
                                        : Icons.push_pin_outlined,
                                    color: item['pinned'] == true
                                        ? Colors.orange
                                        : Colors.grey,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      item['pinned'] =
                                      !(item['pinned'] == true);
                                      _sortChecklist();
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
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),


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
                        "priority": 1,
                        "pinned": false,
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
