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
  bool hideCompleted = false;

  List<String> _groups = ['기본'];
  String _selectedGroup = '기본';

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

  // ======================================================
  // ✅ 템플릿 저장 (카테고리 + 중복 시 덮어쓰기 확인)
  // ======================================================
  Future<void> _saveTemplate() async {
    final prefs = await SharedPreferences.getInstance();
    final nameC = TextEditingController();
    final categoryC = TextEditingController();

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('템플릿 저장'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameC,
                decoration: const InputDecoration(labelText: '템플릿 이름'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: categoryC,
                decoration:
                const InputDecoration(labelText: '카테고리 (기본값: 기본)'),
              ),
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
                categoryC.text.trim().isEmpty ? '기본' : categoryC.text.trim();

                if (name.isEmpty) return;

                final key = 'template/$cat/$name';

                if (prefs.containsKey(key)) {
                  final overwrite = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('덮어쓰기 확인'),
                      content:
                      Text("'$cat > $name' 템플릿이 이미 존재합니다."),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('취소')),
                        ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('덮어쓰기')),
                      ],
                    ),
                  );
                  if (overwrite != true) return;
                }

                await prefs.setString(
                  key,
                  jsonEncode(widget.todo.checklist),
                );

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("'$cat > $name' 저장됨")),
                );
              },
            ),
          ],
        );
      },
    );
  }

  // ======================================================
  // ✅ 템플릿 불러오기 (카테고리 + 미리보기 + 적용 방식)
  // ======================================================
  Future<void> _loadTemplate() async {
    final prefs = await SharedPreferences.getInstance();
    final keys =
    prefs.getKeys().where((k) => k.startsWith('template/')).toList();

    if (keys.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('저장된 템플릿이 없습니다')),
      );
      return;
    }

    final Map<String, List<String>> categories = {};
    for (var k in keys) {
      final parts = k.split('/');
      categories.putIfAbsent(parts[1], () => []);
      categories[parts[1]]!.add(k);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: categories.entries.map((entry) {
              return ExpansionTile(
                title: Text(entry.key,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                children: entry.value.map((fullKey) {
                  final name = fullKey.split('/').last;
                  return ListTile(
                    title: Text(name),
                    leading: const Icon(Icons.list_alt),
                    onTap: () async {
                      final data = prefs.getString(fullKey);
                      if (data == null) return;

                      final items = (jsonDecode(data) as List)
                          .map((e) => Map<String, dynamic>.from(e))
                          .toList();

                      // 🔍 미리보기
                      final proceed = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: Text('미리보기 · $name'),
                          content: SizedBox(
                            height: 250,
                            width: double.maxFinite,
                            child: ListView.builder(
                              itemCount: items.length,
                              itemBuilder: (_, i) => ListTile(
                                leading: Icon(
                                  items[i]['isChecked'] == true
                                      ? Icons.check_circle
                                      : Icons.radio_button_unchecked,
                                ),
                                title: Text(items[i]['title'] ?? ''),
                                subtitle: items[i]['group'] != null
                                    ? Text('그룹: ${items[i]['group']}')
                                    : null,
                              ),
                            ),
                          ),
                          actions: [
                            TextButton(
                                onPressed: () =>
                                    Navigator.pop(context, false),
                                child: const Text('취소')),
                            ElevatedButton(
                                onPressed: () =>
                                    Navigator.pop(context, true),
                                child: const Text('적용')),
                          ],
                        ),
                      );

                      if (proceed != true) return;

                      // ➕ 덮어쓰기 / 추가 선택
                      final mode = await showDialog<String>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('적용 방식'),
                          content:
                          const Text('기존 체크리스트에 어떻게 적용할까요?'),
                          actions: [
                            TextButton(
                                onPressed: () =>
                                    Navigator.pop(context, 'add'),
                                child: const Text('추가')),
                            ElevatedButton(
                                onPressed: () =>
                                    Navigator.pop(context, 'overwrite'),
                                child: const Text('덮어쓰기')),
                          ],
                        ),
                      );

                      if (mode == null) return;

                      setState(() {
                        if (mode == 'overwrite') {
                          widget.todo.checklist!.clear();
                        }
                        widget.todo.checklist!.addAll(items);
                      });

                      _saveAndRefresh();
                      Navigator.pop(context);

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content:
                            Text("'${entry.key} > $name' 적용 완료")),
                      );
                    },
                  );
                }).toList(),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  // ======================================================
  // UI
  // ======================================================
  @override
  Widget build(BuildContext context) {
    final checklist = widget.todo.checklist!;
    final done =
        checklist.where((e) => e['isChecked'] == true).length;

    return Scaffold(
      appBar: AppBar(
        title: Text('체크리스트 ($done/${checklist.length})'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'saveTemplate') _saveTemplate();
              if (v == 'loadTemplate') _loadTemplate();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                  value: 'saveTemplate', child: Text('템플릿 저장')),
              PopupMenuItem(
                  value: 'loadTemplate', child: Text('템플릿 불러오기')),
            ],
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: checklist.length,
        itemBuilder: (_, i) {
          final item = checklist[i];
          return CheckboxListTile(
            value: item['isChecked'] == true,
            title: Text(item['title'] ?? ''),
            onChanged: (v) {
              setState(() => item['isChecked'] = v);
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
                const InputDecoration(labelText: '체크리스트 추가'),
                onSubmitted: (_) => _addItem(),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(onPressed: _addItem, child: const Text('추가'))
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
        'group': _selectedGroup,
      });
      controller.clear();
    });
    _saveAndRefresh();
  }
}
