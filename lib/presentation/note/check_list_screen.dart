import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/checklist_item.dart';
import '../services/auth_service.dart';

enum SortType { newest, oldest, important }

class ChecklistScreen extends StatefulWidget {
  final String todoId;
  const ChecklistScreen({super.key, required this.todoId});

  @override
  State<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends State<ChecklistScreen> {
  final controller = TextEditingController();

  bool hideCompleted = false;
  SortType sortType = SortType.newest;

  FirebaseFirestore get db => FirebaseFirestore.instance;

  Stream<DocumentSnapshot<Map<String, dynamic>>> get _stream => db
      .collection('users')
      .doc(AuthService.uid)
      .collection('todos')
      .doc(widget.todoId)
      .snapshots();

  List<ChecklistItem> _parse(Map<String, dynamic>? data) {
    final list = List<Map<String, dynamic>>.from(data?['items'] ?? []);
    final items = list.map(ChecklistItem.fromMap).toList();
    _handleRepeats(items);
    return _sort(items);
  }

  void _handleRepeats(List<ChecklistItem> items) {
    final now = DateTime.now();

    for (final i in items) {
      if (i.completedAt == null || i.repeat == 'none') continue;

      final last = DateTime.fromMillisecondsSinceEpoch(i.completedAt!);

      bool reset = false;

      if (i.repeat == 'daily') reset = last.day != now.day;
      if (i.repeat == 'weekly') reset = now.difference(last).inDays >= 7;
      if (i.repeat == 'monthly') reset = last.month != now.month;

      if (reset) {
        i.isChecked = false;
        i.completedAt = null;
      }
    }
  }

  List<ChecklistItem> _sort(List<ChecklistItem> items) {
    switch (sortType) {
      case SortType.newest:
        items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case SortType.oldest:
        items.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case SortType.important:
        items.sort((a, b) => (b.pinned ? 1 : 0) - (a.pinned ? 1 : 0));
        break;
    }
    return items;
  }

  Future<void> _save(List<ChecklistItem> items) async {
    await db
        .collection('users')
        .doc(AuthService.uid)
        .collection('todos')
        .doc(widget.todoId)
        .set({'items': items.map((e) => e.toMap()).toList()},
        SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _stream,
      builder: (_, snap) {
        if (!snap.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        var items = _parse(snap.data!.data());

        if (hideCompleted) {
          items = items.where((e) => !e.isChecked).toList();
        }

        final done = items.where((e) => e.isChecked).length;
        final percent =
        items.isEmpty ? 0 : ((done / items.length) * 100).round();

        return Scaffold(
          appBar: AppBar(
            title: Text('체크리스트  $percent%'),
            actions: [
              IconButton(
                icon: Icon(
                    hideCompleted ? Icons.visibility_off : Icons.visibility),
                onPressed: () =>
                    setState(() => hideCompleted = !hideCompleted),
              ),
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'sort') {
                    setState(() {
                      sortType = SortType
                          .values[(sortType.index + 1) % SortType.values.length];
                    });
                  } else if (v == 'clear') {
                    items.removeWhere((e) => e.isChecked);
                    _save(items);
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'sort', child: Text('정렬 변경')),
                  PopupMenuItem(value: 'clear', child: Text('완료 삭제')),
                ],
              )
            ],
          ),
          body: ReorderableListView.builder(
            padding: const EdgeInsets.only(bottom: 80),
            itemCount: items.length,
            onReorder: (oldIndex, newIndex) {
              if (newIndex > oldIndex) newIndex--;
              final item = items.removeAt(oldIndex);
              items.insert(newIndex, item);
              _save(items);
            },
            itemBuilder: (_, i) => _tile(items[i], items, i),
          ),
          bottomNavigationBar: _input(items),
        );
      },
    );
  }

  Widget _tile(ChecklistItem item, List<ChecklistItem> items, int index) {
    return AnimatedContainer(
      key: ValueKey(item.createdAt),
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Card(
        child: ListTile(
          onLongPress: () => _edit(item, items),
          leading: Checkbox(
            value: item.isChecked,
            onChanged: (v) {
              item.isChecked = v!;
              item.completedAt =
              v ? DateTime.now().millisecondsSinceEpoch : null;
              _save(items);
              setState(() {});
            },
          ),
          title: Text(
            item.title,
            style: TextStyle(
              decoration:
              item.isChecked ? TextDecoration.lineThrough : null,
            ),
          ),
          subtitle: Text('반복: ${item.repeat}'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(
                  item.pinned ? Icons.star : Icons.star_border,
                  color: item.pinned ? Colors.amber : null,
                ),
                onPressed: () {
                  item.pinned = !item.pinned;
                  _save(items);
                },
              ),
              const Icon(Icons.drag_handle),
            ],
          ),
        ),
      ),
    );
  }

  Widget _input(List<ChecklistItem> items) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(hintText: '항목 추가'),
              onSubmitted: (_) => _add(items),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _add(items),
          ),
        ],
      ),
    );
  }

  void _add(List<ChecklistItem> items) {
    if (controller.text.trim().isEmpty) return;

    items.add(ChecklistItem(title: controller.text.trim()));
    controller.clear();
    _save(items);
  }

  void _edit(ChecklistItem item, List<ChecklistItem> items) {
    final c = TextEditingController(text: item.title);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        content: TextField(controller: c),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소')),
          TextButton(
              onPressed: () {
                item.title = c.text;
                _save(items);
                Navigator.pop(context);
              },
              child: const Text('저장')),
        ],
      ),
    );
  }
}
