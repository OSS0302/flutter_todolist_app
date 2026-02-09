import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
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

  bool hideCompleted = false;
  bool darkMode = false;

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
    await _updateHomeWidget(items);
  }

  Future<void> _updateHomeWidget(List<ChecklistItem> items) async {
    final done = items.where((e) => e.isChecked).length;
    final total = items.length;
    final percent = total == 0 ? 0 : ((done / total) * 100).round();

    await HomeWidget.saveWidgetData('done', done);
    await HomeWidget.saveWidgetData('total', total);
    await HomeWidget.saveWidgetData('percent', percent);

    await HomeWidget.updateWidget(androidName: 'ChecklistWidgetProvider');
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

        return Theme(
          data: darkMode ? ThemeData.dark() : ThemeData.light(),
          child: Scaffold(
            appBar: AppBar(
              title: Text('체크리스트 $percent%'),
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
                  icon: const Icon(Icons.bar_chart),
                  onPressed: () => _openGraph(items),
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
                    color: Colors.green.withOpacity((count / 5).clamp(0.2, 1)),
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

  void _openGraph(List<ChecklistItem> items) {
    final map = <String, int>{};

    for (var e in items) {
      if (e.isChecked) {
        final d = DateFormat('MM/dd').format(e.createdAt);
        map[d] = (map[d] ?? 0) + 1;
      }
    }

    final keys = map.keys.toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Streak Graph')),
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: BarChart(
              BarChartData(
                barGroups: List.generate(keys.length, (i) {
                  return BarChartGroupData(x: i, barRods: [
                    BarChartRodData(toY: map[keys[i]]!.toDouble())
                  ]);
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
