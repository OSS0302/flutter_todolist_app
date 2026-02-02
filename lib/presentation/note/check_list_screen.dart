import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/checklist_item.dart';
import '../services/auth_service.dart';

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
  String selectedCategory = '전체';

  FirebaseFirestore get db => FirebaseFirestore.instance;

  Stream<DocumentSnapshot<Map<String, dynamic>>> get _stream => db
      .collection('users')
      .doc(AuthService.uid)
      .collection('todos')
      .doc(widget.todoId)
      .snapshots();

  @override
  void initState() {
    super.initState();
    _initNoti();
  }

  Future<void> _initNoti() async {
    tz.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');

    await noti.initialize(
      const InitializationSettings(android: android),
    );
  }

  List<ChecklistItem> _parse(Map<String, dynamic>? data) {
    final list = List<Map<String, dynamic>>.from(data?['items'] ?? []);
    final items = list.map(ChecklistItem.fromMap).toList();

    items.sort((a, b) {
      if (a.pinned != b.pinned) return b.pinned ? 1 : -1;
      return b.createdAt.compareTo(a.createdAt);
    });

    if (selectedCategory != '전체') {
      return items.where((e) => e.category == selectedCategory).toList();
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

    final now = tz.TZDateTime.now(tz.local).add(const Duration(seconds: 3));

    DateTimeComponents? repeat;

    if (item.repeat == 'daily') repeat = DateTimeComponents.time;
    if (item.repeat == 'weekly') repeat = DateTimeComponents.dayOfWeekAndTime;
    if (item.repeat == 'monthly') repeat = DateTimeComponents.dayOfMonthAndTime;

    await noti.zonedSchedule(
      item.createdAt,
      '체크리스트',
      item.title,
      now,
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
            title: Text('체크리스트 $percent%'),
            actions: [
              IconButton(
                icon: Icon(
                    hideCompleted ? Icons.visibility_off : Icons.visibility),
                onPressed: () =>
                    setState(() => hideCompleted = !hideCompleted),
              ),
              PopupMenuButton<String>(
                onSelected: (v) => setState(() => selectedCategory = v),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: '전체', child: Text('전체')),
                  PopupMenuItem(value: '업무', child: Text('업무')),
                  PopupMenuItem(value: '개인', child: Text('개인')),
                ],
              )
            ],
          ),
          body: ReorderableListView.builder(
            padding: const EdgeInsets.only(bottom: 80),
            itemCount: items.length,
            onReorder: (o, n) {
              if (n > o) n--;
              final item = items.removeAt(o);
              items.insert(n, item);
              _save(items);
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
      key: ValueKey(item.createdAt),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        children: [
          SlidableAction(
            icon: Icons.edit,
            backgroundColor: Colors.blue,
            onPressed: (_) => _edit(item, items),
          ),
          SlidableAction(
            icon: Icons.delete,
            backgroundColor: Colors.red,
            onPressed: (_) {
              items.remove(item);
              _cancel(item.createdAt);
              _save(items);
            },
          ),
        ],
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: ListTile(
          leading: Checkbox(
            value: item.isChecked,
            onChanged: (v) {
              item.isChecked = v!;
              item.completedAt =
              v ? DateTime.now().millisecondsSinceEpoch : null;
              _save(items);
            },
          ),
          title: Text(
            item.title,
            style: TextStyle(
              decoration:
              item.isChecked ? TextDecoration.lineThrough : null,
            ),
          ),
          subtitle: Text('${item.category} • ${item.repeat}'),
          trailing: IconButton(
            icon: Icon(
              item.pinned ? Icons.star : Icons.star_border,
              color: item.pinned ? Colors.amber : null,
            ),
            onPressed: () {
              item.pinned = !item.pinned;
              _save(items);
            },
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

  void _add(List<ChecklistItem> items) async {
    if (controller.text.trim().isEmpty) return;

    final item = ChecklistItem(
      title: controller.text.trim(),
      category: selectedCategory,
    );

    items.add(item);
    controller.clear();

    await _save(items);
    await _schedule(item);
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
