import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  bool _searchMode = false;
  String _query = '';
  bool _hideCompleted = false;

  @override
  void initState() {
    super.initState();
    widget.todo.checklist ??= [];
    _syncFromFirebase();
  }

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  String get _docId => widget.todo.id.toString();

  void _syncToFirebase() {
    _db.collection('checklists').doc(_docId).set({
      'items': widget.todo.checklist,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  void _syncFromFirebase() {
    _db.collection('checklists').doc(_docId).snapshots().listen((doc) {
      if (!doc.exists) return;
      final data = doc.data();
      if (data == null) return;
      final list = List<Map<String, dynamic>>.from(
        (data['items'] ?? []).map((e) => Map<String, dynamic>.from(e)),
      );
      setState(() => widget.todo.checklist = list);
    });
  }

  void _saveAndRefresh() {
    _sortItems();
    widget.todo.save();
    _syncToFirebase();
    try {
      context.read<ListViewModel>().refresh();
    } catch (_) {}
  }

  void _sortItems() {
    widget.todo.checklist!.sort((a, b) {
      if ((a['pinned'] ?? false) != (b['pinned'] ?? false)) {
        return (b['pinned'] == true) ? 1 : -1;
      }
      final p = (b['priority'] ?? 1).compareTo(a['priority'] ?? 1);
      if (p != 0) return p;
      return (a['createdAt'] ?? 0).compareTo(b['createdAt'] ?? 0);
    });
  }

  List<Map<String, dynamic>> get _visibleList {
    Iterable<Map<String, dynamic>> list = widget.todo.checklist!;
    if (_hideCompleted) {
      list = list.where((e) => e['isChecked'] != true);
    }
    if (_query.isNotEmpty) {
      list = list.where((e) {
        final t = (e['title'] ?? '').toString().toLowerCase();
        final m = (e['memo'] ?? '').toString().toLowerCase();
        return t.contains(_query) || m.contains(_query);
      });
    }
    return list.toList();
  }

  double get _progress {
    final list = widget.todo.checklist!;
    if (list.isEmpty) return 0;
    return list.where((e) => e['isChecked'] == true).length / list.length;
  }

  @override
  Widget build(BuildContext context) {
    final list = _visibleList;

    return Scaffold(
      appBar: AppBar(
        title: _searchMode
            ? TextField(
          controller: searchController,
          autofocus: true,
          decoration: const InputDecoration(hintText: '전체 검색'),
          onChanged: (v) => setState(() => _query = v.toLowerCase()),
        )
            : const Text('체크리스트'),
        actions: [
          IconButton(
            icon: Icon(_searchMode ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _searchMode = !_searchMode;
                _query = '';
                searchController.clear();
              });
            },
          ),
          IconButton(
            icon:
            Icon(_hideCompleted ? Icons.visibility_off : Icons.visibility),
            onPressed: () =>
                setState(() => _hideCompleted = !_hideCompleted),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(28),
          child: LinearProgressIndicator(value: _progress),
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
          Color? color;
          if (item['priority'] == 2) color = Colors.red;
          if (item['priority'] == 0) color = Colors.grey;

          return Dismissible(
            key: ValueKey(item),
            background: Container(color: Colors.red),
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
                      _saveAndRefresh();
                    },
                  ),
                ),
              );
              _saveAndRefresh();
            },
            child: ListTile(
              leading: IconButton(
                icon: Icon(
                  item['pinned'] == true
                      ? Icons.push_pin
                      : Icons.push_pin_outlined,
                ),
                onPressed: () {
                  setState(() => item['pinned'] = !(item['pinned'] == true));
                  _saveAndRefresh();
                },
              ),
              title: CheckboxListTile(
                value: item['isChecked'] == true,
                title:
                Text(item['title'], style: TextStyle(color: color)),
                onChanged: (v) {
                  setState(() => item['isChecked'] = v);
                  _saveAndRefresh();
                },
              ),
              trailing: IconButton(
                icon: const Icon(Icons.flag),
                onPressed: () async {
                  final p = await showDialog<int>(
                    context: context,
                    builder: (_) => SimpleDialog(
                      title: const Text('우선순위'),
                      children: [
                        SimpleDialogOption(
                            onPressed: () =>
                                Navigator.pop(context, 2),
                            child: const Text('높음')),
                        SimpleDialogOption(
                            onPressed: () =>
                                Navigator.pop(context, 1),
                            child: const Text('보통')),
                        SimpleDialogOption(
                            onPressed: () =>
                                Navigator.pop(context, 0),
                            child: const Text('낮음')),
                      ],
                    ),
                  );
                  if (p != null) {
                    setState(() => item['priority'] = p);
                    _saveAndRefresh();
                  }
                },
              ),
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
        'priority': 1,
        'pinned': false,
        'memo': '',
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      });
      controller.clear();
    });
    _saveAndRefresh();
  }
}
