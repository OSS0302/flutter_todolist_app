import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  final TextEditingController searchController = TextEditingController();

  bool searchMode = false;
  bool hideCompleted = false;
  String query = '';
  DateTime? lastUpdated;

  FirebaseFirestore get db => FirebaseFirestore.instance;
  String get docId => widget.todo.id.toString();

  @override
  void initState() {
    super.initState();
    widget.todo.checklist ??= [];
    _listenFirebase();
  }

  void _listenFirebase() {
    db.collection('checklists').doc(docId).snapshots().listen((doc) {
      if (!doc.exists) return;
      final data = doc.data();
      if (data == null) return;
      setState(() {
        widget.todo.checklist =
        List<Map<String, dynamic>>.from(data['items'] ?? []);
        if (data['updatedAt'] != null) {
          lastUpdated = (data['updatedAt'] as Timestamp).toDate();
        }
      });
    });
  }

  void _syncFirebase() {
    db.collection('checklists').doc(docId).set({
      'items': widget.todo.checklist,
      'favorite': widget.todo.isFavorite,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  void _save() {
    _sortItems();
    widget.todo.save();
    _syncFirebase();
    try {
      context.read<ListViewModel>().refresh();
    } catch (_) {}
  }

  /// 🔄 정렬: 핀 → 미완료 → 완료 → order
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

  List<Map<String, dynamic>> get visibleItems {
    Iterable<Map<String, dynamic>> list = widget.todo.checklist!;
    if (hideCompleted) {
      list = list.where((e) => e['isChecked'] != true);
    }
    if (query.isNotEmpty) {
      list = list.where((e) =>
      (e['title'] ?? '').toLowerCase().contains(query) ||
          (e['memo'] ?? '').toLowerCase().contains(query));
    }
    return list.toList();
  }

  List<Map<String, dynamic>> get pinnedItems =>
      visibleItems.where((e) => e['pinned'] == true).toList();

  List<Map<String, dynamic>> get normalItems =>
      visibleItems.where((e) => e['pinned'] != true).toList();

  double get progress {
    final list = widget.todo.checklist!;
    if (list.isEmpty) return 0;
    return list.where((e) => e['isChecked'] == true).length / list.length;
  }

  /// 📅 D-Day + 시간
  String _dueText(int due) {
    final d = DateTime.fromMillisecondsSinceEpoch(due);
    final now = DateTime.now();
    final base = DateTime(now.year, now.month, now.day);
    final diff = d.difference(base).inDays;

    final dday =
    diff == 0 ? 'D-Day' : diff > 0 ? 'D-$diff' : 'D+${diff.abs()}';

    return '$dday · ${d.month}/${d.day} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('체크리스트'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(30),
          child: LinearProgressIndicator(value: progress),
        ),
      ),

      /// 🔄 섹션 유지 드래그
      body: ListView(
        children: [
          if (pinnedItems.isNotEmpty)
            _section('📌 고정됨', pinnedItems),
          if (normalItems.isNotEmpty)
            _section('일반', normalItems),
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

  Widget _section(String title, List<Map<String, dynamic>> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(title,
              style:
              const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
        ),
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          onReorder: (o, n) {
            if (n > o) n--;
            final item = items.removeAt(o);
            items.insert(n, item);
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

  Widget _item(Map<String, dynamic> item) {
    return ListTile(
      key: ValueKey(item),
      leading: Checkbox(
        value: item['isChecked'] == true,
        onChanged: (v) {
          setState(() => item['isChecked'] = v);
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

      /// 📝 메모 미리보기
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
              style: TextStyle(color: _dueColor(item), fontSize: 12),
            ),
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
    setState(() {
      widget.todo.checklist!.add({
        'title': text,
        'memo': '',
        'isChecked': false,
        'pinned': false,
        'due': null,
        'order': widget.todo.checklist!.length,
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

  /// 📅 날짜 + 시간 선택
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

    final dt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() => item['due'] = dt.millisecondsSinceEpoch);
    _save();
  }

  Color? _dueColor(Map item) {
    if (item['due'] == null) return null;
    final d = DateTime.fromMillisecondsSinceEpoch(item['due']);
    if (d.isBefore(DateTime.now())) return Colors.red;
    return Colors.orange;
  }
}
