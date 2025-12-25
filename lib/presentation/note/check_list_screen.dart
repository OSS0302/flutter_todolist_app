import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  final TextEditingController controller = TextEditingController();
  final FlutterLocalNotificationsPlugin _noti =
  FlutterLocalNotificationsPlugin();

  String _templateSearch = '';
  int _templateTab = 0;
  bool _hideCompleted = false;

  @override
  void initState() {
    super.initState();
    widget.todo.checklist ??= [];
    tz.initializeTimeZones();
    _initNoti();
  }

  Future<void> _initNoti() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _noti.initialize(const InitializationSettings(android: android));
  }

  void _saveAndRefresh() {
    widget.todo.save();
    try {
      context.read<ListViewModel>().refresh();
    } catch (_) {}
  }

  double get _progress {
    final list = widget.todo.checklist!;
    if (list.isEmpty) return 0;
    final done = list.where((e) => e['isChecked'] == true).length;
    return done / list.length;
  }

  List<Map<String, dynamic>> get _visibleList {
    final list = widget.todo.checklist!;
    if (!_hideCompleted) return list;
    return list.where((e) => e['isChecked'] != true).toList();
  }

  Future<void> _scheduleAlarm(Map item) async {
    if (item['due'] == null) return;
    final id = item.hashCode;
    final due = DateTime.fromMillisecondsSinceEpoch(item['due']);
    final time = DateTime(due.year, due.month, due.day, 9);
    await _noti.zonedSchedule(
      id,
      '체크리스트 알림',
      item['title'],
      tz.TZDateTime.from(time, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'todo',
          'todo',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> _cancelAlarm(Map item) async {
    await _noti.cancel(item.hashCode);
  }

  Future<void> _duplicateChecklist() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;

    final copy = widget.todo.checklist!
        .map((e) => {
      'title': e['title'],
      'isChecked': false,
      'due': null,
      'createdAt': picked.millisecondsSinceEpoch,
    })
        .toList();

    setState(() {
      widget.todo.checklist!.addAll(copy);
    });

    _saveAndRefresh();
  }

  @override
  Widget build(BuildContext context) {
    final list = _visibleList;

    return Scaffold(
      appBar: AppBar(
        title: const Text('체크리스트'),
        actions: [
          IconButton(
            icon:
            Icon(_hideCompleted ? Icons.visibility_off : Icons.visibility),
            onPressed: () => setState(() => _hideCompleted = !_hideCompleted),
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'duplicate') _duplicateChecklist();
              if (v == 'checkAll') {
                setState(() {
                  for (var e in widget.todo.checklist!) {
                    e['isChecked'] = true;
                    _cancelAlarm(e);
                  }
                });
                _saveAndRefresh();
              }
              if (v == 'uncheckAll') {
                setState(() {
                  for (var e in widget.todo.checklist!) {
                    e['isChecked'] = false;
                  }
                });
                _saveAndRefresh();
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'duplicate', child: Text('날짜로 복제')),
              PopupMenuItem(value: 'checkAll', child: Text('전체 완료')),
              PopupMenuItem(value: 'uncheckAll', child: Text('전체 해제')),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(36),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                LinearProgressIndicator(value: _progress),
                const SizedBox(height: 4),
                Text('${(_progress * 100).round()}% 완료'),
              ],
            ),
          ),
        ),
      ),
      body: ReorderableListView.builder(
        itemCount: list.length,
        onReorder: (o, n) {
          if (n > o) n--;
          final item = list.removeAt(o);
          widget.todo.checklist!.remove(item);
          widget.todo.checklist!.insert(n, item);
          setState(() {});
          _saveAndRefresh();
        },
        itemBuilder: (_, i) {
          final item = list[i];
          final due = item['due'] != null
              ? DateTime.fromMillisecondsSinceEpoch(item['due'])
              : null;
          final overdue = due != null && due.isBefore(DateTime.now());

          return ListTile(
            key: ValueKey(item),
            leading: const Icon(Icons.drag_handle),
            title: CheckboxListTile(
              value: item['isChecked'] == true,
              title: Text(
                item['title'],
                style: TextStyle(color: overdue ? Colors.red : null),
              ),
              subtitle:
              due != null ? Text('마감: ${due.toLocal()}'.split(' ')[0]) : null,
              onChanged: (v) {
                setState(() {
                  item['isChecked'] = v;
                  if (v == true) {
                    _cancelAlarm(item);
                  }
                });
                _saveAndRefresh();
              },
            ),
            trailing: IconButton(
              icon: const Icon(Icons.date_range),
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: due ?? DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (picked == null) return;
                setState(() {
                  item['due'] = picked.millisecondsSinceEpoch;
                });
                await _scheduleAlarm(item);
                _saveAndRefresh();
              },
            ),
          );
        },
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
            const SizedBox(width: 8),
            ElevatedButton(onPressed: _addItem, child: const Text('추가')),
          ],
        ),
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
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      });
      controller.clear();
    });
    _saveAndRefresh();
  }
}
