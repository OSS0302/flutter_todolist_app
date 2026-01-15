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

class ChecklistScreen extends StatefulWidget {
  final Todo todo;
  const ChecklistScreen({super.key, required this.todo});

  @override
  State<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends State<ChecklistScreen> {
  final controller = TextEditingController();
  final notifications = FlutterLocalNotificationsPlugin();

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

  /* ───────────────── 🔔 Notification ───────────────── */

  Future<void> _initNotification() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await notifications.initialize(
      const InitializationSettings(android: android),
    );
  }

  Future<void> _scheduleNotification(Map item) async {
    if (item['due'] == null) return;

    final offset = item['notifyOffset'] ?? 0;
    final due = DateTime.fromMillisecondsSinceEpoch(item['due'])
        .subtract(Duration(minutes: offset));

    if (due.isBefore(DateTime.now())) return;

    await notifications.zonedSchedule(
      item['order'] ?? item.hashCode,
      '할 일 알림',
      item['title'],
      tz.TZDateTime.from(due, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'todo',
          '할 일 알림',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> _cancelNotification(Map item) async {
    await notifications.cancel(item['order'] ?? item.hashCode);
  }

  /* ───────────────── ☁️ Firebase ───────────────── */

  void _listenFirebase() {
    db.collection('checklists').doc(docId).snapshots().listen((doc) {
      if (!doc.exists) return;
      final data = doc.data();
      if (data == null) return;

      setState(() {
        widget.todo.checklist =
        List<Map<String, dynamic>>.from(data['items'] ?? []);
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

  /* ───────────────── 🔄 Sort & Data ───────────────── */

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

  List<Map<String, dynamic>> get pinnedItems =>
      widget.todo.checklist!.where((e) => e['pinned'] == true).toList();

  List<Map<String, dynamic>> get normalItems =>
      widget.todo.checklist!.where((e) => e['pinned'] != true).toList();

  double get progress {
    final list = widget.todo.checklist!;
    if (list.isEmpty) return 0;
    return list.where((e) => e['isChecked'] == true).length / list.length;
  }

  /* ───────────────── UI ───────────────── */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('체크리스트'),
        actions: [
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
      body: ListView(
        children: [
          if (pinnedItems.isNotEmpty) _section('📌 고정됨', pinnedItems),
          if (normalItems.isNotEmpty) _section('일반', normalItems),
        ],
      ),
      bottomNavigationBar: _inputBar(),
    );
  }

  Widget _section(String title, List<Map<String, dynamic>> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(title,
              style: Theme.of(context).textTheme.labelLarge),
        ),
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          onReorder: (o, n) {
            if (n > o) n--;
            final item = items.removeAt(o);
            items.insert(n, item);
            for (int i = 0; i < items.length; i++) {
              items[i]['order'] = i;
            }
            _save();
          },
          itemBuilder: (_, i) => _item(items[i]),
        ),
      ],
    );
  }

  Widget _item(Map item) {
    return ListTile(
      key: ValueKey(item['order']),
      leading: Checkbox(
        value: item['isChecked'] == true,
        onChanged: (v) {
          setState(() {
            item['isChecked'] = v;
            item['completedAt'] =
            v == true ? DateTime.now().millisecondsSinceEpoch : null;
          });
          if (v == true) _cancelNotification(item);
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
      'pinned': false,
      'order': widget.todo.checklist!.length,
      'completedAt': null,
    });
    controller.clear();
    _save();
  }
}

/* ───────────────── 📊 Stats Screen ───────────────── */

class StatsScreen extends StatelessWidget {
  final Todo todo;
  const StatsScreen({super.key, required this.todo});

  @override
  Widget build(BuildContext context) {
    final stats = _weeklyStats();

    return Scaffold(
      appBar: AppBar(title: const Text('주간 완료 통계')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: BarChart(
          BarChartData(
            barGroups: stats.entries.map((e) {
              return BarChartGroupData(
                x: e.key,
                barRods: [
                  BarChartRodData(
                    toY: e.value.toDouble(),
                    width: 18,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ],
              );
            }).toList(),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (v, _) =>
                      Text(['월', '화', '수', '목', '금', '토', '일'][v.toInt()]),
                ),
              ),
              topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
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

    for (final e in todo.checklist ?? []) {
      if (e['completedAt'] == null) continue;
      final d = DateTime.fromMillisecondsSinceEpoch(e['completedAt']);
      final idx = d.difference(start).inDays;
      if (idx >= 0 && idx < 7) map[idx] = map[idx]! + 1;
    }
    return map;
  }
}
