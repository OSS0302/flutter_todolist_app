import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/checklist_item.dart';
import '../services/auth_service.dart';
import 'stats_screen.dart';

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

  List<ChecklistItem> _parseItems(Map<String, dynamic>? data) {
    final list = List<Map<String, dynamic>>.from(data?['items'] ?? []);
    final items = list.map(ChecklistItem.fromMap).toList();
    _handleRepeats(items);
    return _sort(items);
  }

  void _handleRepeats(List<ChecklistItem> items) {
    final now = DateTime.now();

    for (final item in items) {
      if (item.completedAt == null || item.repeat == 'none') continue;

      final last = DateTime.fromMillisecondsSinceEpoch(item.completedAt!);

      bool reset = false;

      if (item.repeat == 'daily') {
        reset = last.day != now.day;
      } else if (item.repeat == 'weekly') {
        reset = now.difference(last).inDays >= 7;
      } else if (item.repeat == 'monthly') {
        reset = last.month != now.month;
      }

      if (reset) {
        item.isChecked = false;
        item.completedAt = null;
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
        .set({
      'items': items.map((e) => e.toMap()).toList(),
    }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('체크리스트'),
        actions: [
          IconButton(
            icon: Icon(hideCompleted ? Icons.visibility_off : Icons.visibility),
            onPressed: () =>
                setState(() => hideCompleted = !hideCompleted),
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () {},
          ),
          PopupMenuButton<String>(
            onSelected: _menuAction,
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'sort', child: Text('정렬 변경')),
              PopupMenuItem(value: 'clear', child: Text('완료 항목 삭제')),
            ],
          )
        ],
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _stream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var items = _parseItems(snapshot.data!.data());

          if (hideCompleted) {
            items = items.where((e) => !e.isChecked).toList();
          }

          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (_, i) => _item(items[i], items),
          );
        },
      ),
      bottomNavigationBar: _input(),
    );
  }

  Widget _item(ChecklistItem item, List<ChecklistItem> allItems) {
    return Dismissible(
      key: ValueKey(item.createdAt),
      background: Container(color: Colors.red),
      onDismissed: (_) {
        allItems.remove(item);
        _save(allItems);
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: ListTile(
          onLongPress: () => _editDialog(item, allItems),
          leading: Checkbox(
            value: item.isChecked,
            onChanged: (v) {
              item.isChecked = v!;
              item.completedAt =
              v ? DateTime.now().millisecondsSinceEpoch : null;
              _save(allItems);
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
          trailing: IconButton(
            icon: Icon(
              item.pinned ? Icons.star : Icons.star_border,
              color: item.pinned ? Colors.amber : null,
            ),
            onPressed: () {
              item.pinned = !item.pinned;
              _save(allItems);
            },
          ),
        ),
      ),
    );
  }

  Widget _input() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(hintText: '항목 추가'),
              onSubmitted: (_) => _add(),
            ),
          ),
          IconButton(icon: const Icon(Icons.add), onPressed: _add),
        ],
      ),
    );
  }

  void _add() async {
    if (controller.text.trim().isEmpty) return;

    final snap = await _stream.first;
    final items = _parseItems(snap.data());

    items.add(
      ChecklistItem(
        title: controller.text.trim(),
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );

    controller.clear();

    _save(items);
  }

  void _editDialog(ChecklistItem item, List<ChecklistItem> items) {
    final edit = TextEditingController(text: item.title);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('항목 수정'),
        content: TextField(controller: edit),
        actions: [
          TextButton(
            child: const Text('취소'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text('저장'),
            onPressed: () {
              item.title = edit.text;
              _save(items);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _menuAction(String v) {
    if (v == 'sort') {
      setState(() {
        sortType =
        SortType.values[(sortType.index + 1) % SortType.values.length];
      });
    } else if (v == 'clear') {
      _stream.first.then((snap) {
        final items = _parseItems(snap.data());
        items.removeWhere((e) => e.isChecked);
        _save(items);
      });
    }
  }
}
