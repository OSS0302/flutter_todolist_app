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
      'favorite': widget.todo.isFavorite ?? false,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  void _save() {
    widget.todo.save();
    _syncFirebase();
    try {
      context.read<ListViewModel>().refresh();
    } catch (_) {}
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
            icon: Icon(widget.todo.isFavorite == true
                ? Icons.star
                : Icons.star_border),
            onPressed: () {
              setState(() =>
              widget.todo.isFavorite = !(widget.todo.isFavorite ?? false));
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
          return ListTile(
            key: ValueKey(item),
            leading: Checkbox(
              value: item['isChecked'] == true,
              onChanged: (v) {
                setState(() => item['isChecked'] = v);
                _save();
              },
            ),
            title: Text(item['title']),
            subtitle:
            item['memo'] != null && item['memo'].toString().isNotEmpty
                ? Text(item['memo'])
                : null,
            onLongPress: () => _editMemo(item),
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
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('저장')),
        ],
      ),
    );
    if (ok == true) {
      setState(() => item['memo'] = c.text.trim());
      _save();
    }
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
        widget.todo.checklist!
            .removeWhere((e) => e['isChecked'] == true);
      }
    });
    _save();
  }
}
