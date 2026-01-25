import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/checklist_item.dart';
import '../services/auth_service.dart';
import 'stats_screen.dart';

class ChecklistScreen extends StatefulWidget {
  final String todoId;
  const ChecklistScreen({super.key, required this.todoId});

  @override
  State<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends State<ChecklistScreen> {
  final controller = TextEditingController();
  List<ChecklistItem> items = [];
  bool hideCompleted = false;

  FirebaseFirestore get db => FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final doc = await db
        .collection('users')
        .doc(AuthService.uid)
        .collection('todos')
        .doc(widget.todoId)
        .get();

    final list = List<Map<String, dynamic>>.from(doc.data()?['items'] ?? []);
    items = list.map(ChecklistItem.fromMap).toList();
    _handleRepeats();
    setState(() {});
  }

  void _save() {
    db
        .collection('users')
        .doc(AuthService.uid)
        .collection('todos')
        .doc(widget.todoId)
        .set({
      'items': items.map((e) => e.toMap()).toList(),
    });
  }

  void _handleRepeats() {
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

  @override
  Widget build(BuildContext context) {
    final visible = hideCompleted
        ? items.where((e) => !e.isChecked).toList()
        : items;

    return Scaffold(
      appBar: AppBar(
        title: const Text('체크리스트'),
        actions: [
          IconButton(
            icon: Icon(hideCompleted ? Icons.visibility_off : Icons.visibility),
            onPressed: () => setState(() => hideCompleted = !hideCompleted),
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StatsScreen(items),
                ),
              );
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: visible.length,
        itemBuilder: (_, i) => _item(visible[i]),
      ),
      bottomNavigationBar: _input(),
    );
  }

  Widget _item(ChecklistItem item) {
    return Dismissible(
      key: ValueKey(item),
      background: Container(color: Colors.red),
      onDismissed: (_) {
        setState(() => items.remove(item));
        _save();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('삭제됨'),
            action: SnackBarAction(
              label: '되돌리기',
              onPressed: () {
                setState(() => items.add(item));
                _save();
              },
            ),
          ),
        );
      },
      child: ListTile(
        leading: Checkbox(
          value: item.isChecked,
          onChanged: (v) {
            setState(() {
              item.isChecked = v!;
              item.completedAt =
              v ? DateTime.now().millisecondsSinceEpoch : null;
            });
            _save();
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
        trailing: PopupMenuButton<String>(
          onSelected: (v) {
            setState(() => item.repeat = v);
            _save();
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'none', child: Text('반복 없음')),
            PopupMenuItem(value: 'daily', child: Text('매일')),
            PopupMenuItem(value: 'weekly', child: Text('매주')),
            PopupMenuItem(value: 'monthly', child: Text('매월')),
          ],
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

  void _add() {
    if (controller.text.trim().isEmpty) return;
    setState(() {
      items.add(ChecklistItem(title: controller.text.trim()));
      controller.clear();
    });
    _save();
  }
}
