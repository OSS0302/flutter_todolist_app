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

  @override
  void initState() {
    super.initState();
    widget.todo.checklist ??= [];
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
            TextField(controller: catC, decoration: const InputDecoration(labelText: '카테고리 (기본)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
          ElevatedButton(
            onPressed: () async {
              final name = nameC.text.trim();
              final cat = catC.text.trim().isEmpty ? '기본' : catC.text.trim();
              if (name.isEmpty) return;
              final key = 'template/$cat/$name';
              await prefs.setString(key, jsonEncode(widget.todo.checklist));
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
      builder: (_) {
        return StatefulBuilder(
          builder: (ctx, setModal) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: '템플릿 검색'),
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
                        final list = entry.value.where((k) {
                          final name = k.split('/').last.toLowerCase();
                          final fav = prefs.getBool('fav_$k') == true;
                          if (_templateTab == 1 && !fav) return false;
                          return _templateSearch.isEmpty || name.contains(_templateSearch);
                        }).toList();

                        if (list.isEmpty) return const SizedBox.shrink();

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

                                setState(() {
                                  widget.todo.checklist!.clear();
                                  widget.todo.checklist!.addAll(items);
                                });

                                await prefs.setInt('recent_$fullKey',
                                    DateTime.now().millisecondsSinceEpoch);

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
    final list = widget.todo.checklist!;
    return Scaffold(
      appBar: AppBar(
        title: const Text('체크리스트'),
        actions: [
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
        onReorder: (oldIndex, newIndex) {
          if (newIndex > oldIndex) newIndex--;
          final item = list.removeAt(oldIndex);
          list.insert(newIndex, item);
          setState(() {});
          _saveAndRefresh();
        },
        itemBuilder: (_, i) {
          return ListTile(
            key: ValueKey('$i'),
            leading: const Icon(Icons.drag_handle),
            title: CheckboxListTile(
              value: list[i]['isChecked'] == true,
              title: Text(list[i]['title'] ?? ''),
              onChanged: (v) {
                setState(() => list[i]['isChecked'] = v);
                _saveAndRefresh();
              },
            ),
            onLongPress: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('삭제'),
                  content: const Text('이 항목을 삭제할까요?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
                    ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('삭제')),
                  ],
                ),
              );
              if (ok == true) {
                setState(() => list.removeAt(i));
                _saveAndRefresh();
              }
            },
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
      widget.todo.checklist!.add({'title': text, 'isChecked': false});
      controller.clear();
    });
    _saveAndRefresh();
  }
}
