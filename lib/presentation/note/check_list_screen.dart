import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:todolist/model/todo.dart';
import 'package:todolist/presentation/list_view_model.dart';

class TemplateCategorySetting {
  final Color color;
  final IconData icon;

  TemplateCategorySetting({required this.color, required this.icon});

  Map<String, dynamic> toJson() => {
    'color': color.value,
    'icon': icon.codePoint,
  };

  factory TemplateCategorySetting.fromJson(Map<String, dynamic> json) {
    return TemplateCategorySetting(
      color: Color(json['color']),
      icon: IconData(json['icon'], fontFamily: 'MaterialIcons'),
    );
  }
}

// ================= MAIN SCREEN =================
class ChecklistScreen extends StatefulWidget {
  final Todo todo;
  const ChecklistScreen({super.key, required this.todo});

  @override
  State<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends State<ChecklistScreen> {
  // ===== TEMPLATE STATE =====
  String templateSearch = '';
  Set<String> favorites = {};
  Map<String, TemplateCategorySetting> categorySettings = {};

  final List<Color> palette = const [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.indigo,
    Colors.brown,
  ];

  final List<IconData> icons = const [
    Icons.folder,
    Icons.work,
    Icons.home,
    Icons.star,
    Icons.favorite,
    Icons.flag,
    Icons.school,
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // ================= LOAD / SAVE =================
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    favorites = prefs.getStringList('template_favorites')?.toSet() ?? {};

    final raw = prefs.getString('template_category_settings');
    if (raw != null) {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      categorySettings = decoded.map((k, v) =>
          MapEntry(k, TemplateCategorySetting.fromJson(v)));
    }
    setState(() {});
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('template_favorites', favorites.toList());

    final encoded =
    categorySettings.map((k, v) => MapEntry(k, v.toJson()));
    await prefs.setString(
        'template_category_settings', jsonEncode(encoded));
  }

  // ================= TEMPLATE UI =================
  Future<void> _openTemplateManager() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith('template/')).toList();
    if (keys.isEmpty) return;

    final Map<String, List<String>> categories = {};
    for (var k in keys) {
      final parts = k.split('/');
      categories.putIfAbsent(parts[1], () => []).add(k);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            // SEARCH
            TextField(
              decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search), hintText: '템플릿 검색'),
              onChanged: (v) => setState(() => templateSearch = v.toLowerCase()),
            ),
            const SizedBox(height: 12),

            // FAVORITES
            if (favorites.isNotEmpty) ...[
              const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('⭐ 즐겨찾기',
                      style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
              const SizedBox(height: 6),
              ...favorites.map((k) => _templateTile(k, prefs)).toList(),
              const Divider(),
            ],

            // CATEGORIES
            Expanded(
              child: ListView(
                children: categories.entries.map((entry) {
                  final cat = entry.key;
                  final setting = categorySettings[cat] ??
                      TemplateCategorySetting(
                          color: Colors.grey, icon: Icons.folder);

                  final filtered = entry.value.where((k) {
                    final name = k.split('/').last.toLowerCase();
                    return name.contains(templateSearch) &&
                        !favorites.contains(k);
                  }).toList();

                  if (filtered.isEmpty) return const SizedBox();

                  return Card(
                    child: ExpansionTile(
                      leading: CircleAvatar(
                        backgroundColor: setting.color,
                        child: Icon(setting.icon, color: Colors.white),
                      ),
                      title: Text(cat),
                      trailing: IconButton(
                        icon: const Icon(Icons.settings),
                        onPressed: () => _editCategory(cat),
                      ),
                      children:
                      filtered.map((k) => _templateTile(k, prefs)).toList(),
                    ),
                  );
                }).toList(),
              ),
            ),
          ]),
        );
      },
    );
  }

  Widget _templateTile(String key, SharedPreferences prefs) {
    final name = key.split('/').last;
    final fav = favorites.contains(key);

    return ListTile(
      title: Text(name),
      leading: IconButton(
        icon: Icon(fav ? Icons.star : Icons.star_border),
        onPressed: () {
          setState(() {
            fav ? favorites.remove(key) : favorites.add(key);
          });
          _saveSettings();
        },
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () async {
        final data = prefs.getString(key);
        if (data == null) return;
        final list = jsonDecode(data) as List;
        _previewTemplate(name, list);
      },
    );
  }

  // ================= PREVIEW + APPLY =================
  void _previewTemplate(String name, List list) {
    final items = list.cast<Map<String, dynamic>>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(name,
                style:
                const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('항목 ${items.length}개'),
            const SizedBox(height: 8),
            ...items.take(3).map((e) => ListTile(
              title: Text(e['title'] ?? ''),
              leading: const Icon(Icons.check_box_outline_blank),
            )),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                  child: OutlinedButton(
                      onPressed: () {
                        _applyTemplate(items, 'add');
                        Navigator.pop(ctx);
                      },
                      child: const Text('추가'))),
              const SizedBox(width: 8),
              Expanded(
                  child: OutlinedButton(
                      onPressed: () {
                        _applyTemplate(items, 'merge');
                        Navigator.pop(ctx);
                      },
                      child: const Text('스마트 병합'))),
              const SizedBox(width: 8),
              Expanded(
                  child: ElevatedButton(
                      onPressed: () {
                        _applyTemplate(items, 'overwrite');
                        Navigator.pop(ctx);
                      },
                      child: const Text('덮어쓰기'))),
            ])
          ]),
        );
      },
    );
  }

  void _applyTemplate(List<Map<String, dynamic>> items, String mode) {
    setState(() {
      widget.todo.checklist ??= [];

      if (mode == 'overwrite') {
        widget.todo.checklist!.clear();
      }

      if (mode == 'merge') {
        for (var it in items) {
          final exists = widget.todo.checklist!.any((e) =>
          e['title'] == it['title'] && e['group'] == it['group']);
          if (!exists) widget.todo.checklist!.add(Map.from(it));
        }
      } else {
        for (var it in items) {
          widget.todo.checklist!.add(Map.from(it));
        }
      }
    });

    widget.todo.save();
    context.read<ListViewModel>().refresh();
  }

  // ================= CATEGORY EDIT =================
  void _editCategory(String cat) {
    Color color = categorySettings[cat]?.color ?? Colors.blue;
    IconData icon = categorySettings[cat]?.icon ?? Icons.folder;

    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setInner) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('카테고리 설정: $cat',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: palette
                    .map((c) => GestureDetector(
                  onTap: () => setInner(() => color = c),
                  child: CircleAvatar(backgroundColor: c),
                ))
                    .toList(),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: icons
                    .map((i) => IconButton(
                  icon: Icon(i,
                      color: i == icon ? color : Colors.grey),
                  onPressed: () => setInner(() => icon = i),
                ))
                    .toList(),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                  onPressed: () {
                    setState(() {
                      categorySettings[cat] =
                          TemplateCategorySetting(color: color, icon: icon);
                    });
                    _saveSettings();
                    Navigator.pop(ctx);
                  },
                  child: const Text('저장'))
            ]),
          );
        });
      },
    );
  }

  // ================= BUILD =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('체크리스트'),
        actions: [
          IconButton(
              icon: const Icon(Icons.folder_open),
              onPressed: _openTemplateManager),
        ],
      ),
      body: const Center(
        child: Text('👉 기존 체크리스트 UI 그대로 유지'),
      ),
    );
  }
}
