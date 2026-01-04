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

  void _sortItems() {
    widget.todo.checklist!.sort((a, b) {
      if ((a['pinned'] ?? false) != (b['pinned'] ?? false)) {
        return a['pinned'] == true ? -1 : 1;
      }
      final ad = a['due'];
      final bd = b['due'];
      if (ad != null && bd != null) return ad.compareTo(bd);
      if (ad != null) return -1;
      if (bd != null) return 1;
      return (a['createdAt'] ?? 0).compareTo(b['createdAt'] ?? 0);
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

  double get progress {
    final list = widget.todo.checklist!;
    if (list.isEmpty) return 0;
    return list.where((e) => e['isChecked'] == true).length / list.length;
  }

  @override
  Widget build(BuildContext context) {
    final list = visibleItems;

    return Scaffold(
      appBar: AppBar(
        title: searchMode
            ? TextField(
          controller: searchController,
          autofocus: true,
          decoration: const InputDecoration(hintText: '검색'),
          onChanged: (v) => setState(() => query = v.toLowerCase()),
        )
            : const Text('체크리스트'),
        actions: [
          IconButton(
            icon: Icon(widget.todo.isFavorite
                ? Icons.star
                : Icons.star_border),
            onPressed: () {
              setState(() =>
              widget.todo.isFavorite = !widget.todo.isFavorite);
              _save();
            },
          ),
          IconButton(
            icon: Icon(searchMode ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                searchMode = !searchMode;
                query = '';
                searchController.clear();
              });
            },
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenu,
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'allDone', child: Text('전체 완료')),
              PopupMenuItem(value: 'allClear', child: Text('전체 해제')),
              PopupMenuItem(value: 'clearDone', child: Text('완료 삭제')),
              PopupMenuItem(value: 'hide', child: Text('완료 숨기기')),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(40),
          child: Column(
            children: [
              LinearProgressIndicator(value: progress),
              if (lastUpdated != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '마지막 수정: ${lastUpdated!.toLocal()}',
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
            ],
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
          _save();
        },
        itemBuilder: (_, i) {
          final item = list[i];
          return Dismissible(
            key: ValueKey(item),
            background: Container(
              color: Colors.red,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(left: 20),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            onDismissed: (_) {
              final idx = widget.todo.checklist!.indexOf(item);
              setState(() => widget.todo.checklist!.remove(item));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('삭제됨'),
                  action: SnackBarAction(
                    label: '되돌리기',
                    onPressed: () {
                      setState(() =>
                          widget.todo.checklist!.insert(idx, item));
                      _save();
                    },
                  ),
                ),
              );
              _save();
            },
            child: ListTile(
              leading: IconButton(
                icon: Icon(item['pinned'] == true
                    ? Icons.push_pin
                    : Icons.push_pin_outlined),
                onPressed: () {
                  setState(() =>
                  item['pinned'] = !(item['pinned'] == true));
                  _save();
                },
              ),
              title: CheckboxListTile(
                value: item['isChecked'] == true,
                title: Text(
                  item['title'],
                  style: TextStyle(
                    decoration: item['isChecked'] == true
                        ? TextDecoration.lineThrough
                        : null,
                    color: _dueColor(item),
                  ),
                ),
                onChanged: (v) {
                  setState(() => item['isChecked'] = v);
                  _save();
                },
              ),
              subtitle: item['due'] != null
                  ? Text(
                '마감: ${DateTime.fromMillisecondsSinceEpoch(item['due']).toLocal().toString().split(' ').first}',
                style: TextStyle(color: _dueColor(item)),
              )
                  : null,
              trailing: IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: () => _pickDueDate(item),
              ),
              onLongPress: () => _editMemo(item),
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
        'memo': '',
        'pinned': false,
        'due': null,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      });
      controller.clear();
    });
    _save();
  }

  void _editMemo(Map<String, dynamic> item) async {
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

  void _pickDueDate(Map<String, dynamic> item) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: item['due'] != null
          ? DateTime.fromMillisecondsSinceEpoch(item['due'])
          : DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => item['due'] = picked.millisecondsSinceEpoch);
      _save();
    }
  }

  Color? _dueColor(Map item) {
    if (item['due'] == null) return null;
    final d = DateTime.fromMillisecondsSinceEpoch(item['due']);
    if (d.isBefore(DateTime.now())) return Colors.red;
    return Colors.orange;
  }

  void _handleMenu(String v) {
    setState(() {
      if (v == 'allDone') {
        for (var e in widget.todo.checklist!) {
          e['isChecked'] = true;
        }
      }
      if (v == 'allClear') {
        for (var e in widget.todo.checklist!) {
          e['isChecked'] = false;
        }
      }
      if (v == 'clearDone') {
        widget.todo.checklist!.removeWhere((e) => e['isChecked'] == true);
      }
      if (v == 'hide') {
        hideCompleted = !hideCompleted;
      }
    });
    _save();
  }
}
