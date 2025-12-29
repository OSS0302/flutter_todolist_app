import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  String _templateSearch = '';
  int _templateTab = 0;
  bool _hideCompleted = false;

  @override
  void initState() {
    super.initState();
    widget.todo.checklist ??= [];
  }

  void _saveAndRefresh() {
    widget.todo.checklist!.sort((a, b) {
      final p = (b['priority'] ?? 1).compareTo(a['priority'] ?? 1);
      if (p != 0) return p;
      final ad = a['due'] ?? 0;
      final bd = b['due'] ?? 0;
      return ad.compareTo(bd);
    });

    widget.todo.save();
    try {
      context.read<ListViewModel>().refresh();
    } catch (_) {}
  }

  double get _progress {
    final list = widget.todo.checklist!;
    if (list.isEmpty) return 0;
    return list.where((e) => e['isChecked'] == true).length / list.length;
  }

  List<Map<String, dynamic>> get _visibleList {
    if (!_hideCompleted) return widget.todo.checklist!;
    return widget.todo.checklist!
        .where((e) => e['isChecked'] != true)
        .toList();
  }

  Future<void> _saveTemplate() async {
    final prefs = await SharedPreferences.getInstance();
    final nameC = TextEditingController();
    final catC = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('템플릿 저장'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameC, decoration: const InputDecoration(labelText: '이름')),
            TextField(controller: catC, decoration: const InputDecoration(labelText: '카테고리')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
          ElevatedButton(
            onPressed: () async {
              final name = nameC.text.trim();
              final cat = catC.text.trim().isEmpty ? '기본' : catC.text.trim();
              if (name.isEmpty) return;
              await prefs.setString(
                'template/$cat/$name',
                jsonEncode(widget.todo.checklist),
              );
              Navigator.pop(context);
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadTemplate() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith('template/')).toList();
    if (keys.isEmpty) return;

    final Map<String, List<String>> categories = {};
    for (var k in keys) {
      final cat = k.split('/')[1];
      categories.putIfAbsent(cat, () => []);
      categories[cat]!.add(k);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) {
        return StatefulBuilder(
          builder: (ctx, setModal) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: '템플릿 검색',
                      isDense: true,
                    ),
                    onChanged: (v) => setModal(() => _templateSearch = v.toLowerCase()),
                  ),
                  const SizedBox(height: 8),
                  ToggleButtons(
                    isSelected: [_templateTab == 0, _templateTab == 1],
                    onPressed: (i) => setModal(() => _templateTab = i),
                    children: const [
                      Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('전체')),
                      Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('⭐ 즐겨찾기')),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView(
                      children: categories.entries.map((entry) {
                        var list = entry.value.where((k) {
                          final name = k.split('/').last.toLowerCase();
                          final fav = prefs.getBool('fav_$k') == true;
                          if (_templateTab == 1 && !fav) return false;
                          return _templateSearch.isEmpty || name.contains(_templateSearch);
                        }).toList();

                        if (list.isEmpty) return const SizedBox.shrink();

                        list.sort((a, b) {
                          final af = prefs.getBool('fav_$a') == true;
                          final bf = prefs.getBool('fav_$b') == true;
                          if (af != bf) return af ? -1 : 1;
                          final ar = prefs.getInt('recent_$a') ?? 0;
                          final br = prefs.getInt('recent_$b') ?? 0;
                          return br.compareTo(ar);
                        });

                        return ExpansionTile(
                          title: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold)),
                          children: list.map((fullKey) {
                            final name = fullKey.split('/').last;
                            final isFav = prefs.getBool('fav_$fullKey') == true;

                            return ListTile(
                              title: Text(name),
                              trailing: IconButton(
                                icon: Icon(isFav ? Icons.star : Icons.star_border),
                                onPressed: () async {
                                  await prefs.setBool('fav_$fullKey', !isFav);
                                  setModal(() {});
                                },
                              ),
                              onTap: () async {
                                final raw = prefs.getString(fullKey);
                                if (raw == null) return;
                                final items = (jsonDecode(raw) as List)
                                    .map((e) => Map<String, dynamic>.from(e))
                                    .toList();

                                final mode = await showDialog<String>(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text('적용 방식'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(context, 'add'), child: const Text('추가')),
                                      ElevatedButton(onPressed: () => Navigator.pop(context, 'overwrite'), child: const Text('덮어쓰기')),
                                    ],
                                  ),
                                );
                                if (mode == null) return;

                                setState(() {
                                  if (mode == 'overwrite') widget.todo.checklist!.clear();
                                  widget.todo.checklist!.addAll(items);
                                });

                                await prefs.setInt('recent_$fullKey', DateTime.now().millisecondsSinceEpoch);
                                _saveAndRefresh();
                                Navigator.pop(context);
                              },
                            );
                          }).toList(),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = _visibleList;

    return Scaffold(
      appBar: AppBar(
        title: const Text('체크리스트'),
        actions: [
          IconButton(
            icon: Icon(_hideCompleted ? Icons.visibility_off : Icons.visibility),
            onPressed: () => setState(() => _hideCompleted = !_hideCompleted),
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'save') _saveTemplate();
              if (v == 'load') _loadTemplate();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'save', child: Text('템플릿 저장')),
              PopupMenuItem(value: 'load', child: Text('템플릿 불러오기')),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(30),
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
                      setState(() => widget.todo.checklist!.insert(idx, item));
                      _saveAndRefresh();
                    },
                  ),
                ),
              );
              _saveAndRefresh();
            },
            child: ListTile(
              leading: const Icon(Icons.drag_handle),
              title: CheckboxListTile(
                value: item['isChecked'] == true,
                title: Text(item['title'], style: TextStyle(color: color)),
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
                        SimpleDialogOption(onPressed: () => Navigator.pop(context, 2), child: const Text('높음')),
                        SimpleDialogOption(onPressed: () => Navigator.pop(context, 1), child: const Text('보통')),
                        SimpleDialogOption(onPressed: () => Navigator.pop(context, 0), child: const Text('낮음')),
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
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      });
      controller.clear();
    });
    _saveAndRefresh();
  }
}
