import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:fl_chart/fl_chart.dart';

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

  Future<void> _initNotification() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await notifications.initialize(settings);
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
    widget.todo.save();
    db.collection('checklists').doc(docId).set({
      'items': widget.todo.checklist,
    }, SetOptions(merge: true));
    context.read<ListViewModel>().refresh();
  }

  List<Map<String, dynamic>> get visibleItems {
    return widget.todo.checklist!.where((e) {
      if (hideCompleted && e['isChecked'] == true) return false;
      return true;
    }).toList();
  }

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
                  builder: (_) => StatsScreen(widget.todo),
                ),
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
          child:
          Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
        ...items.map(_item),
      ],
    );
  }

  Widget _item(Map item) {
    return Dismissible(
      key: ValueKey(item),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
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
            item['pinned'] == true
                ? Icons.push_pin
                : Icons.push_pin_outlined,
          ),
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

/* ───────────────── 📊 Stats Screen ───────────────── */

class StatsScreen extends StatelessWidget {
  final Todo todo;
  const StatsScreen(this.todo, {super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('통계'),
          bottom: const TabBar(
            tabs: [
              Tab(text: '주간'),
              Tab(text: '월간'),
              Tab(text: '누적'),
              Tab(text: '📆'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _BarChartView(todo, days: 6),
            _BarChartView(todo, days: 29),
            _TotalView(todo),
            _CalendarHeatmap(todo),
          ],
        ),
      ),
    );
  }
}

/* ───────── Bar Chart ───────── */

class _BarChartView extends StatelessWidget {
  final Todo todo;
  final int days;
  const _BarChartView(this.todo, {required this.days});

  @override
  Widget build(BuildContext context) {
    final data = _range();
    return Padding(
      padding: const EdgeInsets.all(16),
      child: BarChart(
        BarChartData(
          barGroups: data.entries
              .map(
                (e) => BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(toY: e.value.toDouble(), width: 14),
              ],
            ),
          )
              .toList(),
        ),
      ),
    );
  }

  Map<int, int> _range() {
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
}

/* ───────── Calendar Heatmap ───────── */

class _CalendarHeatmap extends StatelessWidget {
  final Todo todo;
  const _CalendarHeatmap(this.todo);

  @override
  Widget build(BuildContext context) {
    final data = _groupByDate();

    return Padding(
      padding: const EdgeInsets.all(12),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
        ),
        itemCount: 30,
        itemBuilder: (_, i) {
          final day = DateTime.now().subtract(Duration(days: 29 - i));
          final key = _key(day);
          final count = data[key] ?? 0;

          return Container(
            decoration: BoxDecoration(
              color: count == 0
                  ? Colors.grey.shade300
                  : Colors.green.withOpacity(
                (count / 5).clamp(0.3, 1.0),
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: Text(
                '${day.day}',
                style: const TextStyle(fontSize: 10),
              ),
            ),
          );
        },
      ),
    );
  }

  Map<String, int> _groupByDate() {
    final map = <String, int>{};
    for (final e in todo.checklist!) {
      if (e['completedAt'] == null) continue;
      final d =
      DateTime.fromMillisecondsSinceEpoch(e['completedAt']);
      final key = _key(d);
      map[key] = (map[key] ?? 0) + 1;
    }
    return map;
  }

  String _key(DateTime d) => '${d.year}-${d.month}-${d.day}';
}

/* ───────── Total ───────── */

class _TotalView extends StatelessWidget {
  final Todo todo;
  const _TotalView(this.todo);

  @override
  Widget build(BuildContext context) {
    final total =
        todo.checklist!.where((e) => e['completedAt'] != null).length;
    return Center(
      child: Text(
        '✅ 누적 완료\n$total개',
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
      ),
    );
  }
}
