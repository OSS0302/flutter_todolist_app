import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../model/check_list_item.dart';

class ChecklistScreen extends StatefulWidget {
  final String todoId;

  const ChecklistScreen({super.key, required this.todoId});

  @override
  State<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends State<ChecklistScreen> {
  final controller = TextEditingController();
  final noti = FlutterLocalNotificationsPlugin();

  bool darkMode = false;
  bool hideCompleted = false;

  final String uid = 'localUser';

  FirebaseFirestore get db => FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> get _doc =>
      db.collection('users').doc(uid).collection('todos').doc(widget.todoId);

  @override
  void initState() {
    super.initState();
    _initNotification();
  }

  Future<void> _initNotification() async {
    tz.initializeTimeZones();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await noti.initialize(const InitializationSettings(android: android));
  }

  Stream<List<ChecklistItem>> get _itemsStream =>
      _doc.snapshots().map((snap) {
        final raw =
        List<Map<String, dynamic>>.from(snap.data()?['items'] ?? []);
        return raw.map(ChecklistItem.fromMap).toList();
      });

  Future<void> _save(List<ChecklistItem> items) async {
    await _doc.set(
      {'items': items.map((e) => e.toMap()).toList()},
      SetOptions(merge: true),
    );
  }

  int _calculateStreak(List<ChecklistItem> items) {
    final dates = items
        .where((e) => e.isChecked)
        .map((e) => DateTime(e.createdAt.year, e.createdAt.month, e.createdAt.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    int streak = 0;
    DateTime today = DateTime.now();
    DateTime checkDay =
    DateTime(today.year, today.month, today.day);

    for (var d in dates) {
      if (d == checkDay) {
        streak++;
        checkDay = checkDay.subtract(const Duration(days: 1));
      } else if (d.isBefore(checkDay)) {
        break;
      }
    }
    return streak;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ChecklistItem>>(
      stream: _itemsStream,
      builder: (_, snap) {
        if (!snap.hasData) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        var items = [...snap.data!];

        if (hideCompleted) {
          items = items.where((e) => !e.isChecked).toList();
        }

        final done = items.where((e) => e.isChecked).length;
        final percent =
        items.isEmpty ? 0 : ((done / items.length) * 100).round();
        final streak = _calculateStreak(items);

        return Theme(
          data: darkMode ? ThemeData.dark() : ThemeData.light(),
          child: Scaffold(
            appBar: AppBar(
              title: Text('체크리스트 $percent% 🔥$streak'),
              actions: [
                IconButton(
                  icon: Icon(darkMode ? Icons.dark_mode : Icons.light_mode),
                  onPressed: () =>
                      setState(() => darkMode = !darkMode),
                ),
                IconButton(
                  icon: const Icon(Icons.calendar_month),
                  onPressed: () => _openCalendar(items),
                ),
                IconButton(
                  icon: const Icon(Icons.pie_chart),
                  onPressed: () => _openPieChart(items),
                ),
                IconButton(
                  icon: Icon(hideCompleted
                      ? Icons.visibility_off
                      : Icons.visibility),
                  onPressed: () =>
                      setState(() => hideCompleted = !hideCompleted),
                ),
              ],
            ),
            body: ListView.builder(
              padding: const EdgeInsets.only(bottom: 80),
              itemCount: items.length,
              itemBuilder: (_, i) => _tile(items[i], items),
            ),
            bottomNavigationBar: _input(items),
          ),
        );
      },
    );
  }

  Widget _tile(ChecklistItem item, List<ChecklistItem> items) {
    return Slidable(
      key: ValueKey(item.id),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        children: [
          SlidableAction(
            icon: Icons.delete,
            backgroundColor: Colors.red,
            onPressed: (_) async {
              items.remove(item);
              await _save(items);
            },
          ),
        ],
      ),
      child: CheckboxListTile(
        value: item.isChecked,
        title: Text(
          item.title,
          style: TextStyle(
              decoration:
              item.isChecked ? TextDecoration.lineThrough : null),
        ),
        onChanged: (v) async {
          item.isChecked = v!;
          await _save(items);
        },
      ),
    );
  }

  Widget _input(List<ChecklistItem> items) {
    return SafeArea(
      child: Padding(
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
            )
          ],
        ),
      ),
    );
  }

  Future<void> _add(List<ChecklistItem> items) async {
    if (controller.text.trim().isEmpty) return;

    items.add(ChecklistItem(
      id: DateTime.now().millisecondsSinceEpoch,
      title: controller.text.trim(),
    ));

    controller.clear();
    await _save(items);
  }

  void _openCalendar(List<ChecklistItem> items) {
    final map = <DateTime, int>{};

    for (var e in items) {
      if (e.isChecked) {
        final d = DateTime(e.createdAt.year, e.createdAt.month, e.createdAt.day);
        map[d] = (map[d] ?? 0) + 1;
      }
    }

    Color heatColor(int count) {
      if (count == 0) return Colors.transparent;
      if (count == 1) return Colors.green.shade100;
      if (count == 2) return Colors.green.shade300;
      if (count == 3) return Colors.green.shade500;
      if (count >= 4) return Colors.green.shade800;
      return Colors.transparent;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Heatmap')),
          body: TableCalendar(
            firstDay: DateTime.utc(2020),
            lastDay: DateTime.utc(2030),
            focusedDay: DateTime.now(),
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, _) {
                final count = map[day] ?? 0;
                if (count == 0) return null;
                return Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: heatColor(count),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text('${day.day}'),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _openPieChart(List<ChecklistItem> items) {
    final done = items.where((e) => e.isChecked).length;
    final undone = items.length - done;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('통계')),
          body: Center(
            child: PieChart(
              PieChartData(
                sections: [
                  PieChartSectionData(
                    value: done.toDouble(),
                    title: '완료',
                    color: Colors.green,
                  ),
                  PieChartSectionData(
                    value: undone.toDouble(),
                    title: '미완료',
                    color: Colors.red,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
