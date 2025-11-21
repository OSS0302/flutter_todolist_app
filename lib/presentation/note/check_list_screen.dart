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
  final searchController = TextEditingController();
  bool hideCompleted = false;
  String searchQuery = "";
  late AnimationController _animationController;

  Map<String, dynamic>? _lastRemovedItem;
  int? _lastRemovedIndex;
  String? _lastRemovedGroup;

  List<String> _groups = [];
  String _selectedGroup = '기본';

  Map<String, bool> _groupExpanded = {};

  @override
  void initState() {
    super.initState();
    _animationController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 300));

    final checklist = widget.todo.checklist ?? [];
    for (var item in checklist) {
      item['group'] = item['group'] ?? '기본';
      item['priority'] = item['priority'] ?? 1;
      item['isChecked'] = item['isChecked'] == true;
      item['pinned'] = item['pinned'] == true;
      if (!_groups.contains(item['group'])) _groups.add(item['group']);
    }

    if (!_groups.contains('기본')) _groups.insert(0, '기본');

    // NOTE: Removed meta-reading block here to avoid accessing widget.todo.meta
    for (var g in _groups) {
      _groupExpanded.putIfAbsent(g, () => true);
    }

    _selectedGroup = _groups.isNotEmpty ? _groups.first : '기본';
  }

  @override
  void dispose() {
    _animationController.dispose();
    searchController.dispose();
    controller.dispose();
    super.dispose();
  }

  // No-op persistence: avoid touching widget.todo.meta (which may not exist)
  void _persistGroupExpandedStates() {
    // intentionally left empty to avoid errors when Todo model has no `meta` field
  }

  void _addGroup(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    if (!_groups.contains(trimmed)) {
      setState(() {
        _groups.add(trimmed);
        _groupExpanded.putIfAbsent(trimmed, () => true);
        _selectedGroup = trimmed;
      });
      _saveAndRefresh();
    }
  }

  void _deleteGroup(String name) {
    if (name == '기본') return;

    setState(() {
      _groups.remove(name);
      _groupExpanded.remove(name);

      widget.todo.checklist ??= [];
      for (var item in widget.todo.checklist!) {
        if ((item['group'] ?? '기본') == name) item['group'] = '기본';
      }

      if (!_groups.contains('기본')) _groups.insert(0, '기본');
      _selectedGroup = _groups.first;
    });
    _saveAndRefresh();
  }

  void _sortChecklist() {
    final list = widget.todo.checklist!;
    list.sort((a, b) {
      final aPinned = a['pinned'] == true;
      final bPinned = b['pinned'] == true;
      if (aPinned != bPinned) return aPinned ? -1 : 1;

      final aPr = (a['priority'] ?? 1) as int;
      final bPr = (b['priority'] ?? 1) as int;
      if (aPr != bPr) return bPr - aPr;

      final aChecked = a['isChecked'] == true;
      final bChecked = b['isChecked'] == true;
      if (aChecked != bChecked) return aChecked ? 1 : -1;

      return 0;
    });
  }

  void _saveAndRefresh() {
    _persistGroupExpandedStates();

    widget.todo.save();
    context.read<ListViewModel>().refresh();
  }

  void _checkAll() {
    setState(() {
      for (var item in widget.todo.checklist!) item['isChecked'] = true;
      _sortChecklist();
    });
    _saveAndRefresh();
  }

  void _uncheckAll() {
    setState(() {
      for (var item in widget.todo.checklist!) item['isChecked'] = false;
      _sortChecklist();
    });
    _saveAndRefresh();
  }

  void _editItem(Map<String, dynamic> item) {
    final editController = TextEditingController(text: item['title'] ?? '');
    int priority = item['priority'] ?? 1;
    String group = item['group'] ?? '기본';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: editController,
                decoration: const InputDecoration(labelText: "항목 수정"),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text("우선순위: "),
                  const SizedBox(width: 8),
                  DropdownButton<int>(
                    value: priority,
                    items: const [
                      DropdownMenuItem(value: 2, child: Text("🔥 중요")),
                      DropdownMenuItem(value: 1, child: Text("⭐ 보통")),
                      DropdownMenuItem(value: 0, child: Text("⬇️ 낮음")),
                    ],
                    onChanged: (v) => setState(() => priority = v ?? 1),
                  ),
                  const SizedBox(width: 24),
                  const Text("그룹: "),
                  const SizedBox(width: 8),
                  Flexible(
                    child: TextField(
                      controller: TextEditingController(text: group),
                      onChanged: (v) => group = v,
                      decoration: const InputDecoration(hintText: "그룹명"),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final newTitle = editController.text.trim();
                        if (newTitle.isEmpty) return;
                        setState(() {
                          item['title'] = newTitle;
                          item['priority'] = priority;
                          item['group'] = group.isEmpty ? '기본' : group;

                          if (!_groups.contains(item['group'])) {
                            _groups.add(item['group']);
                            _groupExpanded.putIfAbsent(item['group'], () => true);
                          }

                          _sortChecklist();
                        });
                        _saveAndRefresh();
                        Navigator.pop(ctx);
                      },
                      child: const Text("저장"),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  void _addNewItem() {
    final text = controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      widget.todo.checklist ??= [];
      widget.todo.checklist!.add({
        "title": text,
        "isChecked": false,
        "priority": 1,
        "pinned": false,
        "group": _selectedGroup,
      });

      if (!_groups.contains(_selectedGroup)) _groups.add(_selectedGroup);

      controller.clear();
      _sortChecklist();
    });
    _saveAndRefresh();
  }

  Map<String, List<Map<String, dynamic>>> _groupedItems(List<Map<String, dynamic>> input) {
    final Map<String, List<Map<String, dynamic>>> map = {};
    for (var g in _groups) map[g] = [];
    for (var item in input) {
      final g = (item['group'] ?? '기본') as String;
      map.putIfAbsent(g, () => []);
      map[g]!.add(item);
    }
    return map;
  }

  void _removeItem(Map<String, dynamic> item, String groupName) {
    final checklist = widget.todo.checklist!;
    final index = checklist.indexOf(item);
    if (index == -1) return;

    setState(() {
      _lastRemovedItem = Map<String, dynamic>.from(item);
      _lastRemovedIndex = index;
      _lastRemovedGroup = groupName;
      checklist.removeAt(index);
    });

    _saveAndRefresh();

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: const Text("항목이 삭제되었습니다"),
        action: SnackBarAction(
          label: '취소',
          onPressed: () {
            if (_lastRemovedItem != null && _lastRemovedIndex != null) {
              setState(() {
                final list = widget.todo.checklist!;
                final insertIndex = (_lastRemovedIndex!.clamp(0, list.length));
                list.insert(insertIndex, _lastRemovedItem!);
                _lastRemovedItem = null;
                _lastRemovedIndex = null;
                _lastRemovedGroup = null;
              });
              _saveAndRefresh();
            }
          },
        ),
        duration: const Duration(seconds: 4),
      ),
    )
        .closed
        .then((_) {
      _lastRemovedItem = null;
      _lastRemovedIndex = null;
      _lastRemovedGroup = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final todo = widget.todo;
    final checklist = todo.checklist ?? [];

    final filtered = checklist.where((e) {
      final title = (e['title'] ?? '') as String;
      if (hideCompleted && (e['isChecked'] == true)) return false;
      if (searchQuery.isNotEmpty && !title.toLowerCase().contains(searchQuery.toLowerCase())) {
        return false;
      }
      return true;
    }).toList();

    for (var it in filtered) {
      it['group'] = it['group'] ?? '기본';
      if (!_groups.contains(it['group'])) _groups.add(it['group']);
    }

    final pinnedItems = filtered.where((e) => e['pinned'] == true).toList();

    final total = checklist.length;
    final done = checklist.where((e) => e['isChecked'] == true).length;
    final progress = total == 0 ? 0 : done / total;

    final grouped = _groupedItems(filtered);

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
              const PopupMenuItem(value: 'manageGroups', child: Text("그룹 관리")),
            ],
            onSelected: (value) {
              if (value == 'checkAll') _checkAll();
              if (value == 'uncheckAll') _uncheckAll();
              if (value == 'manageGroups') {
                showDialog(
                  context: context,
                  builder: (ctx) {
                    final addController = TextEditingController();
                    return AlertDialog(
                      title: const Text('그룹 관리'),
                      content: SizedBox(
                        width: double.maxFinite,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextField(
                              controller: addController,
                              decoration: const InputDecoration(hintText: '새 그룹명'),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: () {
                                _addGroup(addController.text);
                                Navigator.of(ctx).pop();
                              },
                              child: const Text('추가'),
                            ),
                            const Divider(),
                            const SizedBox(height: 8),
                            Text('기존 그룹', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Flexible(
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: _groups.length,
                                itemBuilder: (c, i) {
                                  final g = _groups[i];
                                  return ListTile(
                                    title: Text(g),
                                    trailing: g == '기본'
                                        ? null
                                        : IconButton(
                                      icon: const Icon(Icons.delete_outline),
                                      onPressed: () {
                                        _deleteGroup(g);
                                        Navigator.of(ctx).pop();
                                      },
                                    ),
                                  );
                                },
                              ),
                            )
                          ],
                        ),
                      ),
                    );
                  },
                );
              }
            },
          )
        ],
      ),
      body: Column(
        children: [
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

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: searchController,
              onChanged: (v) => setState(() => searchQuery = v),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: "검색 (제목으로 검색)",
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      searchController.clear();
                      searchQuery = "";
                    });
                  },
                )
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              ),
            ),
          ),

          const SizedBox(height: 12),

          if (pinnedItems.isNotEmpty)
            SizedBox(
              height: 110,
              child: Padding(
                padding: const EdgeInsets.only(left: 12),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: pinnedItems.length,
                  itemBuilder: (context, idx) {
                    final item = pinnedItems[idx];
                    final isChecked = item['isChecked'] == true;
                    final priority = item['priority'] ?? 1;
                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: GestureDetector(
                        onTap: () => _editItem(item),
                        child: Container(
                          width: 220,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
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
                                      child: Text(
                                        item['title'] ?? '',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          decoration: isChecked
                                              ? TextDecoration.lineThrough
                                              : TextDecoration.none,
                                          color: isChecked ? Colors.grey : Colors.black,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        item['pinned'] == true ? Icons.push_pin : Icons.push_pin_outlined,
                                        color: item['pinned'] == true ? Colors.orange : Colors.grey,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          item['pinned'] = !(item['pinned'] == true);
                                        });
                                        _saveAndRefresh();
                                      },
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                Row(
                                  children: [
                                    IconButton(
                                      visualDensity: VisualDensity.compact,
                                      padding: EdgeInsets.zero,
                                      icon: Icon(isChecked ? Icons.check_box : Icons.check_box_outline_blank),
                                      onPressed: () {
                                        setState(() {
                                          item['isChecked'] = !isChecked;
                                        });
                                        _animationController.forward(from: 0);
                                        Future.delayed(const Duration(milliseconds: 250), () {
                                          setState(() => _sortChecklist());
                                          _saveAndRefresh();
                                        });
                                      },
                                    ),
                                    const Spacer(),
                                    Text(item['group'] ?? '기본', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

          const SizedBox(height: 8),

          Expanded(
            child: grouped.isEmpty
                ? const Center(child: Text("체크리스트가 비어있어요", style: TextStyle(color: Colors.grey)))
                : SingleChildScrollView(
              child: Column(
                children: grouped.entries.map((entry) {
                  final groupName = entry.key;
                  final items = entry.value;

                  return Padding(
                    key: ValueKey("group_$groupName"),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ExpansionTile(
                        title: Row(
                          children: [
                            Text(groupName, style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(width: 8),
                            Chip(label: Text("${items.length}")),
                          ],
                        ),
                        initiallyExpanded: _groupExpanded[groupName] ?? true,
                        onExpansionChanged: (v) {
                          setState(() => _groupExpanded[groupName] = v);
                          _persistGroupExpandedStates();
                        },
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Row(
                              children: [
                                const SizedBox(width: 8),
                                const Spacer(),
                                PopupMenuButton(
                                  itemBuilder: (_) => [
                                    const PopupMenuItem(value: 'addToGroup', child: Text('이 그룹에 새 항목 추가')),
                                    const PopupMenuItem(value: 'deleteGroup', child: Text('그룹 삭제')),
                                  ],
                                  onSelected: (v) {
                                    if (v == 'addToGroup') {
                                      showModalBottomSheet(
                                        context: context,
                                        isScrollControlled: true,
                                        builder: (ctx) {
                                          final addCtrl = TextEditingController();
                                          return Padding(
                                            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 16, right: 16, top: 16),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                TextField(controller: addCtrl, decoration: const InputDecoration(labelText: '새 항목')),
                                                const SizedBox(height: 12),
                                                ElevatedButton(
                                                  onPressed: () {
                                                    final t = addCtrl.text.trim();
                                                    if (t.isEmpty) return;
                                                    setState(() {
                                                      widget.todo.checklist ??= [];
                                                      widget.todo.checklist!.add({
                                                        'title': t,
                                                        'isChecked': false,
                                                        'priority': 1,
                                                        'pinned': false,
                                                        'group': groupName,
                                                      });
                                                      if (!_groups.contains(groupName)) _groups.add(groupName);
                                                      _sortChecklist();
                                                    });
                                                    _saveAndRefresh();
                                                    Navigator.pop(ctx);
                                                  },
                                                  child: const Text('추가'),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      );
                                    } else if (v == 'deleteGroup') {
                                      _deleteGroup(groupName);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),

                          ReorderableListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: items.length,
                            onReorder: (oldIndex, newIndex) {
                              setState(() {
                                if (newIndex > oldIndex) newIndex--;
                                final item = items.removeAt(oldIndex);
                                items.insert(newIndex, item);

                                final all = widget.todo.checklist!;
                                all.removeWhere((it) => (it['group'] ?? '기본') == groupName);
                                all.addAll(items);
                                _sortChecklist();
                              });
                              _saveAndRefresh();
                            },
                            itemBuilder: (context, idx) {
                              final item = items[idx];
                              final isChecked = item['isChecked'] == true;
                              final priority = item['priority'] ?? 1;

                              return Dismissible(
                                key: ValueKey(item.hashCode ^ idx),
                                background: Container(
                                  color: Colors.green,
                                  alignment: Alignment.centerLeft,
                                  padding: const EdgeInsets.only(left: 20),
                                  child: const Icon(Icons.check, color: Colors.white),
                                ),
                                secondaryBackground: Container(
                                  color: Colors.red,
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 16),
                                  child: const Icon(Icons.delete, color: Colors.white),
                                ),
                                confirmDismiss: (direction) async {
                                  if (direction == DismissDirection.startToEnd) {
                                    setState(() {
                                      item['isChecked'] = !(item['isChecked'] == true);
                                    });
                                    _animationController.forward(from: 0);
                                    Future.delayed(const Duration(milliseconds: 250), () {
                                      setState(() => _sortChecklist());
                                      _saveAndRefresh();
                                    });
                                    return false; // don't remove from list
                                  } else {
                                    _removeItem(item, groupName);
                                    return true;
                                  }
                                },
                                child: ListTile(
                                  onLongPress: () => _editItem(item),
                                  title: Row(
                                    children: [
                                      GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            item['isChecked'] = !isChecked;
                                          });
                                          _animationController.forward(from: 0);
                                          Future.delayed(const Duration(milliseconds: 250), () {
                                            setState(() => _sortChecklist());
                                            _saveAndRefresh();
                                          });
                                        },
                                        child: ScaleTransition(
                                          scale: Tween<double>(begin: 1.0, end: 1.3).animate(
                                            CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
                                          ),
                                          child: AnimatedContainer(
                                            duration: const Duration(milliseconds: 250),
                                            width: 26,
                                            height: 26,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(color: Colors.blueAccent, width: 2),
                                              color: isChecked ? Colors.blueAccent : Colors.white,
                                              boxShadow: isChecked
                                                  ? [
                                                BoxShadow(color: Colors.blueAccent.withOpacity(0.5), blurRadius: 8, spreadRadius: 1)
                                              ]
                                                  : [],
                                            ),
                                            child: isChecked ? const Icon(Icons.check, size: 18, color: Colors.white) : null,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: priority == 2 ? Colors.red : priority == 1 ? Colors.blue : Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: AnimatedDefaultTextStyle(
                                          duration: const Duration(milliseconds: 300),
                                          style: TextStyle(
                                            decoration: isChecked ? TextDecoration.lineThrough : TextDecoration.none,
                                            color: isChecked ? Colors.grey : Colors.black,
                                            fontSize: 16,
                                          ),
                                          child: Text(item['title'] ?? ''),
                                        ),
                                      ),
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      PopupMenuButton(
                                        icon: const Icon(Icons.flag),
                                        onSelected: (value) {
                                          setState(() {
                                            item['priority'] = value;
                                            _sortChecklist();
                                          });
                                          _saveAndRefresh();
                                        },
                                        itemBuilder: (_) => [
                                          const PopupMenuItem(value: 2, child: Text("🔥 중요")),
                                          const PopupMenuItem(value: 1, child: Text("⭐ 보통")),
                                          const PopupMenuItem(value: 0, child: Text("⬇️ 낮음")),
                                        ],
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          item['pinned'] == true ? Icons.push_pin : Icons.push_pin_outlined,
                                          color: item['pinned'] == true ? Colors.orange : Colors.grey,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            item['pinned'] = !(item['pinned'] == true);
                                            _sortChecklist();
                                          });
                                          _saveAndRefresh();
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.only(bottom: 20, left: 16, right: 16, top: 8),
            child: Row(
              children: [
                DropdownButton<String>(
                  value: _selectedGroup,
                  items: _groups.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                  onChanged: (v) => setState(() => _selectedGroup = v ?? '기본'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      labelText: "체크리스트 추가",
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _addNewItem(),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _addNewItem,
                  child: const Text("추가"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
