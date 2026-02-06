import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../model/check_list_item.dart';

class ChecklistScreen extends StatefulWidget {
  final String todoId;

  const ChecklistScreen({
    super.key,
    required this.todoId,
  });

  @override
  State<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends State<ChecklistScreen> {
  final controller = TextEditingController();
  final noti = FlutterLocalNotificationsPlugin();

  bool hideCompleted = false;
  String category = '전체';

  final String uid = 'localUser';

  FirebaseFirestore get db => FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> get _doc => db
      .collection('users')
      .doc(uid)
      .collection('todos')
      .doc(widget.todoId);

  int streak = 0;

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

  Stream<List<ChecklistItem>> get _itemsStream => _doc.snapshots().map((snap) {
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
    await _updateStreak(items);
  }

  Future<void> _updateStreak(List<ChecklistItem> items) async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final doneToday = items.any((e) =>
    e.isChecked &&
        DateFormat('yyyy-MM-dd').format(e.createdAt) == today);

    final snap = await _doc.get();

    int current = snap.data()?['streak'] ?? 0;
    String lastDate = snap.data()?['lastDoneDate'] ?? '';

    if (doneToday && lastDate != today) {
      current += 1;
      await _doc.set({
        'streak': current,
        'lastDoneDate': today,
      }, SetOptions(merge: true));
    }

    setState(() => streak = current);
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

  Future<void> _schedule(ChecklistItem item) async {
    if (item.repeat == 'none') return;

    final details = const NotificationDetails(
      android: AndroidNotificationDetails(
        'checklist',
        'Checklist',
        importance: Importance.max,
        priority: Priority.high,
      ),
    );

    final time = tz.TZDateTime.now(tz.local).add(const Duration(seconds: 3));

    await noti.zonedSchedule(
      item.id,
      '체크리스트',
      item.title,
      time,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> _cancel(int id) async {
    await noti.cancel(id);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return StreamBuilder<List<ChecklistItem>>(
      stream: _itemsStream,
      builder: (_, snap) {
        if (!snap.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        var items = [...snap.data!];

        if (category != '전체') {
          items = items.where((e) => e.category == category).toList();
        }

        if (hideCompleted) {
          items = items.where((e) => !e.isChecked).toList();
        }

        items.sort((a, b) {
          if (a.pinned != b.pinned) return b.pinned ? 1 : -1;
          return b.createdAt.compareTo(a.createdAt);
        });

        final done = items.where((e) => e.isChecked).length;
        final percent =
        items.isEmpty ? 0 : ((done / items.length) * 100).round();

        return Scaffold(
          backgroundColor: theme.colorScheme.background,
          appBar: AppBar(
            title: Text('체크리스트 $percent%  🔥$streak'),
            actions: [
              IconButton(
                icon: const Icon(Icons.calendar_month),
                onPressed: () => _openCalendar(items),
              ),
              IconButton(
                icon: Icon(
                    hideCompleted ? Icons.visibility_off : Icons.visibility),
                onPressed: () =>
                    setState(() => hideCompleted = !hideCompleted),
              ),
            ],
          ),
          body: ReorderableListView.builder(
            padding: const EdgeInsets.only(bottom: 80),
            itemCount: items.length,
            onReorder: (o, n) async {
              if (n > o) n--;
              final moved = items.removeAt(o);
              items.insert(n, moved);
              await _save(items);
            },
            itemBuilder: (_, i) => _tile(items[i], items),
          ),
          bottomNavigationBar: _input(items),
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
              await _cancel(item.id);
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

    final item = ChecklistItem(
      id: DateTime.now().millisecondsSinceEpoch,
      title: controller.text.trim(),
      category: category,
    );

    items.add(item);
    controller.clear();

    await _save(items);
    await _schedule(item);
  }

  void _openCalendar(List<ChecklistItem> items) {
    final map = <String, int>{};

    for (var e in items) {
      if (e.isChecked) {
        final d = DateFormat('yyyy-MM-dd').format(e.createdAt);
        map[d] = (map[d] ?? 0) + 1;
      }
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('완료 기록')),
          body: ListView(
            children: map.entries
                .map((e) => ListTile(
              title: Text(e.key),
              trailing: Text('${e.value}개'),
            ))
                .toList(),
          ),
        ),
      ),
    );
  }
}
