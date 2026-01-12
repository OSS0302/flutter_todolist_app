import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:todolist/model/todo.dart';
import 'package:todolist/presentation/list_view_model.dart';

final FlutterLocalNotificationsPlugin notifications =
FlutterLocalNotificationsPlugin();

class ChecklistScreen extends StatefulWidget {
  final Todo todo;
  const ChecklistScreen({super.key, required this.todo});

  @override
  State<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends State<ChecklistScreen> {
  final TextEditingController controller = TextEditingController();

  FirebaseFirestore get db => FirebaseFirestore.instance;
  String get docId => widget.todo.id.toString();

  @override
  void initState() {
    super.initState();
    widget.todo.checklist ??= [];
    _initNotification();
    _listenFirebase();
  }

  Future<void> _initNotification() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await notifications.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
  }

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

  /// 🔔 알림 예약 (마감 1시간 전)
  Future<void> _scheduleAlarm(Map item) async {
    if (item['due'] == null) return;

    final id = item.hashCode;
    await notifications.cancel(id);

    final due =
    DateTime.fromMillisecondsSinceEpoch(item['due'])
        .subtract(const Duration(hours: 1));

    if (due.isBefore(DateTime.now())) return;

    await notifications.schedule(
      id,
      '할 일 마감 알림',
      item['title'],
      due,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'todo',
          '할 일 알림',
          importance: Importance.max,
        ),
      ),
    );
  }

  void _save([Map? item]) {
    _sortItems();
    widget.todo.save();
    db.collection('checklists').doc(docId).set({
      'items': widget.todo.checklist,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    if (item != null) _scheduleAlarm(item);
    try {
      context.read<ListViewModel>().refresh();
    } catch (_) {}
  }

  /// 🔄 정렬
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

  /// 📊 통계
  int get weekDone {
    final now = DateTime.now();
    final start = now.subtract(Duration(days: now.weekday - 1));
    return widget.todo.checklist!
        .where((e) =>
    e['isChecked'] == true &&
        DateTime.fromMillisecondsSinceEpoch(e['order'])
            .isAfter(start))
        .length;
  }

  int get monthDone {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month);
    return widget.todo.checklist!
        .where((e) =>
    e['isChecked'] == true &&
        DateTime.fromMillisecondsSinceEpoch(e['order'])
            .isAfter(start))
        .length;
  }

  /// 📅 D-Day + 시간
  String _dueText(int due) {
    final d = DateTime.fromMillisecondsSinceEpoch(due);
    final base = DateTime.now();
    final diff =
        d.difference(DateTime(base.year, base.month, base.day)).inDays;
    final dday =
    diff == 0 ? 'D-Day' : diff > 0 ? 'D-$diff' : 'D+${diff.abs()}';
    return '$dday · ${d.month}/${d.day} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  Color? _dueColor(Map item, bool dark) {
    if (item['due'] == null) return null;
    final d = DateTime.fromMillisecondsSinceEpoch(item['due']);
    if (d.isBefore(DateTime.now())) {
      return dark ? Colors.red[300] : Colors.red;
    }
    return dark ? Colors.orange[300] : Colors.orange;
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('체크리스트'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(46),
          child: Column(
            children: [
              LinearProgressIndicator(
                value: widget.todo.checklist!.isEmpty
                    ? 0
                    : widget.todo.checklist!
                    .where((e) => e['isChecked'] == true)
                    .length /
                    widget.todo.checklist!.length,
              ),
              Padding(
                padding: const EdgeInsets.all(4),
                child: Text(
                  '이번 주 완료 $weekDone · 이번 달 완료 $monthDone',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),

      /// 📌 핀 드래그 이동
      body: ReorderableListView(
        onReorder: (o, n) {
          if (n > o) n--;
          final item = widget.todo.checklist!.removeAt(o);
          widget.todo.checklist!.insert(n, item);

          final pinnedCount = widget.todo.checklist!
              .where((e) => e['pinned'] == true)
              .length;

          item['pinned'] = n < pinnedCount;
          _save(item);
        },
        children: [
          for (final item in widget.todo.checklist!)
            ListTile(
              key: ValueKey(item),
              tileColor: item['isChecked'] == true
                  ? (dark ? Colors.grey[800] : Colors.grey[200])
                  : null,
              leading: Icon(
                item['pinned'] == true
                    ? Icons.push_pin
                    : Icons.radio_button_unchecked,
              ),
              title: Text(
                item['title'],
                style: TextStyle(
                  decoration: item['isChecked'] == true
                      ? TextDecoration.lineThrough
                      : null,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if ((item['memo'] ?? '').toString().isNotEmpty)
                    Text(
                      item['memo'],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12),
                    ),
                  if (item['due'] != null)
                    Text(
                      '마감 ${_dueText(item['due'])}',
                      style: TextStyle(
                          fontSize: 12,
                          color: _dueColor(item, dark)),
                    ),
                ],
              ),
              trailing: Checkbox(
                value: item['isChecked'] == true,
                onChanged: (v) {
                  setState(() => item['isChecked'] = v);
                  _save(item);
                },
              ),
              onTap: () => _editTitle(item),
              onLongPress: () => _editMemo(item),
            ),
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
        'memo': '',
        'isChecked': false,
        'pinned': false,
        'due': null,
        'order': DateTime.now().millisecondsSinceEpoch,
      });
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
    if (ok == true && c.text.trim().isNotEmpty) {
      setState(() => item['title'] = c.text.trim());
      _save(item);
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
      _save(item);
    }
  }
}
