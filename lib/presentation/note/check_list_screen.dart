import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'package:todolist/model/todo.dart';
import 'package:todolist/presentation/list_view_model.dart';

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

  /// 🔔 알림 초기화
  void _initNotification() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await notifications.initialize(settings);
  }

  /// 🔔 알림 예약
  Future<void> _scheduleNotification(Map item) async {
    if (item['due'] == null) return;

    final due =
    DateTime.fromMillisecondsSinceEpoch(item['due']);
    final id = item.hashCode;

    await notifications.zonedSchedule(
      id,
      '할 일 마감 알림',
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

  /// 🔕 알림 취소
  Future<void> _cancelNotification(Map item) async {
    await notifications.cancel(item.hashCode);
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

  /// 🔄 자동 정렬
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

  String _dueText(int due) {
    final d = DateTime.fromMillisecondsSinceEpoch(due);
    final now = DateTime.now();
    final diff = d.difference(DateTime(now.year, now.month, now.day)).inDays;
    final dday =
    diff == 0 ? 'D-Day' : diff > 0 ? 'D-$diff' : 'D+${diff.abs()}';
    return '$dday · ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  Color? _dueColor(Map item) {
    if (item['due'] == null) return null;
    final d = DateTime.fromMillisecondsSinceEpoch(item['due']);
    if (d.isBefore(DateTime.now())) return Colors.red;
    return Colors.orange;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('체크리스트'),
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
      bottomNavigationBar: Padding(
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
      ),
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
            item['pinned'] = title.contains('📌');
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
      key: ValueKey(item),
      leading: Checkbox(
        value: item['isChecked'] == true,
        onChanged: (v) {
          setState(() => item['isChecked'] = v);
          if (v == true) {
            _cancelNotification(item);
          }
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
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if ((item['memo'] ?? '').toString().isNotEmpty)
            Text(item['memo'],
                maxLines: 1, overflow: TextOverflow.ellipsis),
          if (item['due'] != null)
            Text('마감 ${_dueText(item['due'])}',
                style: TextStyle(color: _dueColor(item))),
        ],
      ),
      trailing: IconButton(
        icon: const Icon(Icons.calendar_today),
        onPressed: () => _pickDueDateTime(item),
      ),
      onTap: () => _editTitle(item),
      onLongPress: () => _editMemo(item),
    );
  }

  void _addItem() {
    final text = controller.text.trim();
    if (text.isEmpty) return;
    final item = {
      'title': text,
      'memo': '',
      'isChecked': false,
      'pinned': false,
      'due': null,
      'order': widget.todo.checklist!.length,
    };
    setState(() {
      widget.todo.checklist!.add(item);
      controller.clear();
    });
    _save();
  }

  void _editTitle(Map item) async {
    final c = TextEditingController(text: item['title']);
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('제목 수정'),
        content: TextField(controller: c),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('저장')),
        ],
      ),
    );
    if (ok == true) {
      setState(() => item['title'] = c.text.trim());
      _save();
    }
  }

  void _editMemo(Map item) async {
    final c = TextEditingController(text: item['memo']);
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('메모 수정'),
        content: TextField(controller: c, maxLines: 3),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('저장')),
        ],
      ),
    );
    if (ok == true) {
      setState(() => item['memo'] = c.text.trim());
      _save();
    }
  }

  void _pickDueDateTime(Map item) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null) return;

    final dt =
    DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() => item['due'] = dt.millisecondsSinceEpoch);
    await _scheduleNotification(item);
    _save();
  }
}
