import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
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

  @override
  void initState() {
    super.initState();
    _initNotification();
  }

  Future<void> _initNotification() async {
    tz.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');

    await noti.initialize(
      const InitializationSettings(android: android),
    );
  }

  Stream<List<ChecklistItem>> get _itemsStream => _doc.snapshots().map((snap) {
    final raw = List<Map<String, dynamic>>.from(snap.data()?['items'] ?? []);
    return raw.map(ChecklistItem.fromMap).toList();
  });

  Future<void> _save(List<ChecklistItem> items) async {
    await _doc.set(
      {'items': items.map((e) => e.toMap()).toList()},
      SetOptions(merge: true),
    );
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

    DateTimeComponents? repeat;

    if (item.repeat == 'daily') repeat = DateTimeComponents.time;
    if (item.repeat == 'weekly') repeat = DateTimeComponents.dayOfWeekAndTime;
    if (item.repeat == 'monthly') repeat = DateTimeComponents.dayOfMonthAndTime;

    await noti.zonedSchedule(
      item.id,
      '체크리스트',
      item.title,
      time,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: repeat,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> _cancel(int id) async {
    await noti.cancel(id);
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
          appBar: AppBar(
            title: Text('체크리스트 $percent%'),
            actions: [
              IconButton(
                icon: Icon(
                    hideCompleted ? Icons.visibility_off : Icons.visibility),
                onPressed: () =>
                    setState(() => hideCompleted = !hideCompleted),
              ),
              PopupMenuButton<String>(
                onSelected: (v) => setState(() => category = v),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: '전체', child: Text('전체')),
                  PopupMenuItem(value: '업무', child: Text('업무')),
                  PopupMenuItem(value: '개인', child: Text('개인')),
                ],
              )
            ],
          ),
          body: ReorderableListView.builder(
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
        title: Text(item.title),
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
}
