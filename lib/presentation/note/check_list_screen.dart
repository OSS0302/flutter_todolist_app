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

class _ChecklistScreenState extends State<ChecklistScreen>
    with SingleTickerProviderStateMixin {
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
            TextField(
                controller: nameC,
                decoration: const InputDecoration(labelText: '이름')),
            TextField(
                controller: catC,
                decoration:
                const InputDecoration(labelText: '카테고리 (기본)')),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소')),
          ElevatedButton(
            child: const Text('저장'),
            onPressed: () async {
              final name = nameC.text.trim();
              final cat =
              catC.text.trim().isEmpty ? '기본' : catC.text.trim();
              if (name.isEmpty) return;

              final key = 'template/$cat/$name';
              await prefs.setString(
                  key, jsonEncode(widget.todo.checklist));

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("'$cat > $name' 저장됨")),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _loadTemplate() async {
    final prefs = await SharedPreferences.getInstance();
    final keys =
    prefs.getKeys().where((k) => k.startsWith('template/')).toList();
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
                    onChanged: (v) =>
                        setModal(() => _templateSearch = v.toLowerCase()),
                  ),
                  const SizedBox(height: 8),
                  ToggleButtons(
                    isSelected: [_templateTab == 0, _templateTab == 1],
                    onPressed: (i) => setModal(() => _templateTab = i),
                    children: const [
                      Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text('전체')),
                      Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text('⭐ 즐겨찾기')),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView(
                      children: categories.entries.map((entry) {
                        var list = entry.value.where((k) {
                          final name =
                          k.split('/').last.toLowerCase();
                          final fav =
                              prefs.getBool('fav_$k') == true;
                          if (_templateTab == 1 && !fav) return false;
                          return _templateSearch.isEmpty ||
                              name.contains(_templateSearch);
                        }).toList();

                        if (list.isEmpty) return const SizedBox.shrink();

                        list.sort((a, b) {
                          final af =
                              prefs.getBool('fav_$a') == true;
                          final bf =
                              prefs.getBool('fav_$b') == true;
                          if (af != bf) return af ? -1 : 1;

                          final ar =
                              prefs.getInt('recent_$a') ?? 0;
                          final br =
                              prefs.getInt('recent_$b') ?? 0;
                          return br.compareTo(ar);
                        });

                        return ExpansionTile(
                          title: Text(entry.key,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold)),
                          children: list.map((fullKey) {
                            final name = fullKey.split('/').last;
                            final isFav =
                                prefs.getBool('fav_$fullKey') == true;

                            return ListTile(
                              title: Text(name),
                              leading: const Icon(Icons.list),
                              trailing: IconButton(
                                icon: Icon(
                                  isFav
                                      ? Icons.star
                                      : Icons.star_border,
                                  color: isFav
                                      ? Colors.orange
                                      : Colors.grey,
                                ),
                                onPressed: () async {
                                  await prefs.setBool(
                                      'fav_$fullKey', !isFav);
                                  setModal(() {});
                                },
                              ),
                              onTap: () async {
                                final raw =
                                prefs.getString(fullKey);
                                if (raw == null) return;
                                final items =
                                (jsonDecode(raw) as List)
                                    .map((e) => Map<String,
                                    dynamic>.from(e))
                                    .toList();

                                final ok = await showDialog<bool>(
                                  context: context,
                                  builder: (_) {
                                    return StatefulBuilder(
                                      builder: (c, setPreview) {
                                        return AlertDialog(
                                          title:
                                          Text('미리보기 · $name'),
                                          content: SizedBox(
                                            width:
                                            double.maxFinite,
                                            height: 300,
                                            child: ListView.builder(
                                              itemCount: items.length,
                                              itemBuilder: (_, i) {
                                                return CheckboxListTile(
                                                  value: items[i]
                                                  ['isChecked'] ==
                                                      true,
                                                  title: Text(
                                                      items[i]['title'] ??
                                                          ''),
                                                  onChanged: (v) {
                                                    setPreview(() =>
                                                    items[i]
                                                    ['isChecked'] =
                                                        v);
                                                  },
                                                );
                                              },
                                            ),
                                          ),
                                          actions: [
                                            TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(
                                                        c, false),
                                                child:
                                                const Text('취소')),
                                            ElevatedButton(
                                                onPressed: () =>
                                                    Navigator.pop(
                                                        c, true),
                                                child:
                                                const Text('적용')),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                );

                                if (ok != true) return;

                                final mode =
                                await showDialog<String>(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title:
                                    const Text('적용 방식'),
                                    actions: [
                                      TextButton(
                                          onPressed: () =>
                                              Navigator.pop(
                                                  context, 'add'),
                                          child:
                                          const Text('추가')),
                                      ElevatedButton(
                                          onPressed: () =>
                                              Navigator.pop(context,
                                                  'overwrite'),
                                          child:
                                          const Text('덮어쓰기')),
                                    ],
                                  ),
                                );
                                if (mode == null) return;

                                setState(() {
                                  if (mode == 'overwrite') {
                                    widget.todo.checklist!.clear();
                                  }
                                  widget.todo.checklist!
                                      .addAll(items);
                                });

                                await prefs.setInt(
                                    'recent_$fullKey',
                                    DateTime.now()
                                        .millisecondsSinceEpoch);

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
      ),
      body: ListView.builder(
        itemCount: list.length,
        itemBuilder: (_, i) {
          return CheckboxListTile(
            value: list[i]['isChecked'] == true,
            title: Text(list[i]['title'] ?? ''),
            onChanged: (v) {
              setState(() => list[i]['isChecked'] = v);
              _saveAndRefresh();
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
                decoration:
                const InputDecoration(labelText: '항목 추가'),
                onSubmitted: (_) => _addItem(),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
                onPressed: _addItem, child: const Text('추가')),
          ],
        ),
      ),
    );
  }

  void _addItem() {
    final text = controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      widget.todo.checklist!
          .add({'title': text, 'isChecked': false});
      controller.clear();
    });
    _saveAndRefresh();
  }
}
