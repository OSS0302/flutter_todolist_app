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
  final FlutterLocalNotificationsPlugin notifications =
  FlutterLocalNotificationsPlugin();

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

  /* ───────── Notification ───────── */

  Future<void> _initNotification() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await notifications.initialize(settings);
  }

  Future<void> _scheduleNotification(Map item) async {
    if (item['due'] == null) return;
    final offset = item['notifyOffset'] ?? 0;
    final due = DateTime.fromMillisecondsSinceEpoch(item['due'])
        .subtract(Duration(minutes: offset));
    if (due.isBefore(DateTime.now())) return;

    await notifications.zonedSchedule(
      item.hashCode,
      '할 일 알림',
      item['title'],
      tz.TZDateTime.from(due, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'todo',
          'todo',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /* ───────── Firebase ───────── */

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
    widget.todo.save();
    db.collection('checklists').doc(docId).set({
      'items': widget.todo.checklist,
    }, SetOptions(merge: true));
    context.read<ListViewModel>().refresh();
  }

  /* ───────── Filter ───────── */

  List<Map<String, dynamic>> get visibleItems {
    return widget.todo.checklist!.where((e) {
      if (hideCompleted && e['isChecked'] == true) return false;
      return true;
    }).toList();
  }

  /* ───────── UI ───────── */

  @override
  Widget build(BuildContext context) {
    final pinned =
    visibleItems.where((e) => e['pinned'] == true).toList();
    final normal =
    visibleItems.where((e) => e['pinned'] != true).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('체크리스트'),
        actions: [
          IconButton(
            icon:
            Icon(hideCompleted ? Icons.visibility_off : Icons.visibility),
            onPressed: () => setState(() => hideCompleted = !hideCompleted),
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => StatsScreen(widget.todo)),
              );
            },
          ),
        ],
      ),
      body: ListView(
        children: [
          if (pinned.isNotEmpty) _section('📌 고정됨', pinned),
          if (normal.isNotEmpty) _section('일반', normal),
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
              style: Theme.of(context).textTheme.titleMedium),
        ),
        ...items.map(_item),
      ],
    );
  }

  Widget _item(Map item) {
    return Dismissible(
      key: ValueKey(item),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        final removed = item;
        setState(() => widget.todo.checklist!.remove(item));
        _save();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('삭제됨'),
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
        trailing: IconButton(
          icon: Icon(
              item['pinned'] == true ? Icons.push_pin : Icons.push_pin_outlined),
          onPressed: () {
            setState(() => item['pinned'] = !(item['pinned'] == true));
            _save();
          },
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
    setState(() {
      widget.todo.checklist!.add({
        'title': text,
        'isChecked': false,
        'pinned': false,
        'completedAt': null,
      });
      controller.clear();
    });
    _save();
  }
}

/* ───────── Stats Screen ───────── */

class StatsScreen extends StatelessWidget {
  final Todo todo;
  const StatsScreen(this.todo, {super.key});

  @override
  Widget build(BuildContext context) {
    final weekly = _weekly();
    final monthly = _monthly();
    final total = todo.checklist!
        .where((e) => e['completedAt'] != null)
        .length;

    return Scaffold(
      appBar: AppBar(title: const Text('통계')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('🔥 연속 ${_streak()}일 / ✅ 누적 $total',
                style:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            const Text('주간 완료'),
            SizedBox(height: 150, child: BarChart(_chart(weekly))),
            const SizedBox(height: 20),
            const Text('월간 완료'),
            SizedBox(height: 150, child: BarChart(_chart(monthly))),
          ],
        ),
      ),
    );
  }

  BarChartData _chart(Map<int, int> data) {
    return BarChartData(
      barGroups: data.entries
          .map(
            (e) => BarChartGroupData(
          x: e.key,
          barRods: [BarChartRodData(toY: e.value.toDouble(), width: 14)],
        ),
      )
          .toList(),
    );
  }

  Map<int, int> _weekly() => _range(6);
  Map<int, int> _monthly() => _range(29);

  Map<int, int> _range(int days) {
    final now = DateTime.now();
    final start = now.subtract(Duration(days: days));
    final map = {for (int i = 0; i <= days; i++) i: 0};

    for (final e in todo.checklist!) {
      if (e['completedAt'] == null) continue;
      final d = DateTime.fromMillisecondsSinceEpoch(e['completedAt']);
      final idx = d.difference(start).inDays;
      if (idx >= 0 && idx <= days) map[idx] = map[idx]! + 1;
    }
    return map;
  }

  int _streak() {
    final days = todo.checklist!
        .where((e) => e['completedAt'] != null)
        .map((e) =>
        DateTime.fromMillisecondsSinceEpoch(e['completedAt']))
        .map((d) => DateTime(d.year, d.month, d.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    int streak = 0;
    DateTime? last;
    for (final d in days) {
      if (last == null || last.difference(d).inDays == 1) {
        streak++;
        last = d;
      } else {
        break;
      }
    }
    return streak;
  }
}
