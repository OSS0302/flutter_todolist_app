import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:fl_chart/fl_chart.dart';

import 'package:todolist/model/todo.dart';
import 'package:todolist/presentation/list_view_model.dart';

const notifyOptions = {
  '정시': 0,
  '10분 전': 10,
  '1시간 전': 60,
};

/* ───────────────── Checklist Screen ───────────────── */

class ChecklistScreen extends StatefulWidget {
  final Todo todo;
  const ChecklistScreen({super.key, required this.todo});

  @override
  State<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends State<ChecklistScreen> {
  final controller = TextEditingController();
  final notifications = FlutterLocalNotificationsPlugin();
  bool hideCompleted = false;

  FirebaseFirestore get db => FirebaseFirestore.instance;
  String get docId => widget.todo.id.toString();

  @override
  void initState() {
    super.initState();
    widget.todo.checklist ??= [];
    tz.initializeTimeZones();
    _initNotification();
    _listenFirebase();
  }

  Future<void> _initNotification() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await notifications.initialize(
      const InitializationSettings(android: android),
    );
  }

  void _listenFirebase() {
    db.collection('checklists').doc(docId).snapshots().listen((doc) {
      if (!doc.exists) return;
      setState(() {
        widget.todo.checklist =
        List<Map<String, dynamic>>.from(doc.data()?['items'] ?? []);
      });
    });
  }

  void _save() {
    _sortItems();
    widget.todo.save();
    db.collection('checklists').doc(docId).set({
      'items': widget.todo.checklist,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    context.read<ListViewModel>().refresh();
  }

  void _sortItems() {
    widget.todo.checklist!.sort((a, b) {
      if ((a['pinned'] ?? false) != (b['pinned'] ?? false)) {
        return a['pinned'] == true ? -1 : 1;
      }
      if ((a['isChecked'] ?? false) != (b['isChecked'] ?? false)) {
        return a['isChecked'] == true ? 1 : -1;
      }
      return (a['order'] ?? 0).compareTo(b['order'] ?? 0);
    });
  }

  List<Map<String, dynamic>> get visibleItems {
    return widget.todo.checklist!.where((e) {
      if (hideCompleted && e['isChecked'] == true) return false;
      return true;
    }).toList();
  }

  double get progress {
    final list = widget.todo.checklist!;
    if (list.isEmpty) return 0;
    return list.where((e) => e['isChecked'] == true).length / list.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('체크리스트'),
        actions: [
          IconButton(
            icon: Icon(
              hideCompleted ? Icons.visibility_off : Icons.visibility,
            ),
            onPressed: () => setState(() => hideCompleted = !hideCompleted),
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StatsScreen(todo: widget.todo),
                ),
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(value: progress),
        ),
      ),
      body: ReorderableListView.builder(
        itemCount: visibleItems.length,
        onReorder: (o, n) {
          if (n > o) n--;
          final item = visibleItems.removeAt(o);
          visibleItems.insert(n, item);
          for (int i = 0; i < visibleItems.length; i++) {
            visibleItems[i]['order'] = i;
          }
          _save();
        },
        itemBuilder: (_, i) => _dismissibleItem(visibleItems[i]),
      ),
      bottomNavigationBar: _inputBar(),
    );
  }

  Widget _dismissibleItem(Map item) {
    return Dismissible(
      key: ValueKey(item['order']),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) {
        final removed = Map<String, dynamic>.from(item);
        setState(() => widget.todo.checklist!.remove(item));
        _save();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('항목이 삭제되었습니다'),
            action: SnackBarAction(
              label: '되돌리기',
              onPressed: () {
                setState(() => widget.todo.checklist!.add(removed));
                _save();
              },
            ),
          ),
        );
      },
      child: ListTile(
        leading: Checkbox(
          value: item['isChecked'] == true,
          onChanged: (v) {
            setState(() {
              item['isChecked'] = v;
              item['completedAt'] =
              v == true ? DateTime.now().millisecondsSinceEpoch : null;
            });
            _save();
          },
        ),
        title: Text(
          item['title'],
          style: TextStyle(
            decoration:
            item['isChecked'] == true ? TextDecoration.lineThrough : null,
          ),
        ),
      ),
    );
  }

  Widget _inputBar() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(labelText: '항목 추가'),
              onSubmitted: (_) => _addItem(),
            ),
          ),
          ElevatedButton(onPressed: _addItem, child: const Text('추가')),
        ],
      ),
    );
  }

  void _addItem() {
    final text = controller.text.trim();
    if (text.isEmpty) return;

    widget.todo.checklist!.add({
      'title': text,
      'isChecked': false,
      'order': widget.todo.checklist!.length,
      'completedAt': null,
    });
    controller.clear();
    _save();
  }
}

/* ───────────────── Stats Screen ───────────────── */

class StatsScreen extends StatefulWidget {
  final Todo todo;
  const StatsScreen({super.key, required this.todo});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  bool monthly = false;

  @override
  Widget build(BuildContext context) {
    final stats = monthly ? _monthlyStats() : _weeklyStats();

    return Scaffold(
      appBar: AppBar(
        title: const Text('통계'),
        actions: [
          TextButton(
            onPressed: () => setState(() => monthly = !monthly),
            child: Text(
              monthly ? '주간' : '월간',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: stats.isEmpty
            ? const Center(child: Text('완료된 항목이 없습니다'))
            : BarChart(
          BarChartData(
            barGroups: stats.entries.map((e) {
              return BarChartGroupData(
                x: e.key,
                barRods: [
                  BarChartRodData(
                    toY: e.value.toDouble(),
                    width: 18,
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Map<int, int> _weeklyStats() {
    final now = DateTime.now();
    final start =
    DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));
    final map = {for (int i = 0; i < 7; i++) i: 0};

    for (final e in widget.todo.checklist!) {
      if (e['completedAt'] == null) continue;
      final d = DateTime.fromMillisecondsSinceEpoch(e['completedAt']);
      final idx = d.difference(start).inDays;
      if (idx >= 0 && idx < 7) map[idx] = map[idx]! + 1;
    }
    return map;
  }

  Map<int, int> _monthlyStats() {
    final now = DateTime.now();
    final map = <int, int>{};

    for (final e in widget.todo.checklist!) {
      if (e['completedAt'] == null) continue;
      final d = DateTime.fromMillisecondsSinceEpoch(e['completedAt']);
      if (d.year == now.year && d.month == now.month) {
        map[d.day] = (map[d.day] ?? 0) + 1;
      }
    }
    return map;
  }
}
