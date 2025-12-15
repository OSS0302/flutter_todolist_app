// UPDATED checklist_screen.dart
// Added:
// 1) Template search & favorite
// 2) Persistent category color/icon settings (separate from templates)

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todolist/model/todo.dart';
import 'package:todolist/presentation/list_view_model.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';

// ================= CATEGORY SETTINGS MODEL =================
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

class _ChecklistScreenState extends State<ChecklistScreen>
    with SingleTickerProviderStateMixin {
  final controller = TextEditingController();
  final searchController = TextEditingController();

  bool hideCompleted = false;
  String searchQuery = '';

  late AnimationController _animationController;

  final FlutterLocalNotificationsPlugin _notifications =
  FlutterLocalNotificationsPlugin();

  // ===== TEMPLATE SEARCH / FAVORITE =====
  String templateSearch = '';
  Set<String> favoriteTemplates = {};

  // ===== CATEGORY SETTINGS =====
  Map<String, TemplateCategorySetting> categorySettings = {};

  final List<Color> palette = const [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.brown,
    Colors.pink,
    Colors.indigo,
    Colors.grey,
  ];

  final List<IconData> icons = const [
    Icons.folder,
    Icons.work,
    Icons.home,
    Icons.shopping_cart,
    Icons.school,
    Icons.favorite,
    Icons.star,
    Icons.flag,
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 250));
    _loadCategorySettings();
    _loadFavorites();
  }

  // ================= PERSISTENCE =================
  Future<void> _loadCategorySettings() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('template_category_settings');
    if (raw == null) return;

    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    setState(() {
      categorySettings = decoded.map((k, v) =>
          MapEntry(k, TemplateCategorySetting.fromJson(v)));
    });
  }

  Future<void> _saveCategorySettings() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = categorySettings.map((k, v) => MapEntry(k, v.toJson()));
    await prefs.setString('template_category_settings', jsonEncode(encoded));
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      favoriteTemplates = prefs.getStringList('template_favorites')?.toSet() ?? {};
    });
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('template_favorites', favoriteTemplates.toList());
  }

  // ================= CATEGORY EDIT UI =================
  void _editCategory(String category) {
    final current = categorySettings[category] ??
        TemplateCategorySetting(color: Colors.blue, icon: Icons.folder);

    Color selColor = current.color;
    IconData selIcon = current.icon;

    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setInner) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('카테고리 설정: $category',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: palette
                    .map((c) => GestureDetector(
                  onTap: () => setInner(() => selColor = c),
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
                      color: i == selIcon ? selColor : Colors.grey),
                  onPressed: () => setInner(() => selIcon = i),
                ))
                    .toList(),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    categorySettings[category] =
                        TemplateCategorySetting(color: selColor, icon: selIcon);
                  });
                  _saveCategorySettings();
                  Navigator.pop(ctx);
                },
                child: const Text('저장'),
              )
            ]),
          );
        });
      },
    );
  }

  // ================= TEMPLATE LOADER UI =================
  Future<void> _loadTemplate() async {
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
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(12),
          child: Column(children: [
            TextField(
              decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search), hintText: '템플릿 검색'),
              onChanged: (v) => setState(() => templateSearch = v.toLowerCase()),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                children: categories.entries.map((entry) {
                  final cat = entry.key;
                  final setting = categorySettings[cat] ??
                      TemplateCategorySetting(color: Colors.grey, icon: Icons.folder);

                  final filtered = entry.value.where((k) {
                    final name = k.split('/').last.toLowerCase();
                    return name.contains(templateSearch);
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
                      children: filtered.map((k) {
                        final name = k.split('/').last;
                        final fav = favoriteTemplates.contains(k);
                        return ListTile(
                          title: Text(name),
                          leading: IconButton(
                            icon: Icon(fav ? Icons.star : Icons.star_border),
                            onPressed: () {
                              setState(() {
                                fav
                                    ? favoriteTemplates.remove(k)
                                    : favoriteTemplates.add(k);
                              });
                              _saveFavorites();
                            },
                          ),
                          onTap: () async {
                            final data = prefs.getString(k);
                            if (data == null) return;
                            final list = jsonDecode(data) as List;
                            setState(() {
                              widget.todo.checklist =
                                  list.map((e) => Map<String, dynamic>.from(e)).toList();
                            });
                            widget.todo.save();
                            context.read<ListViewModel>().refresh();
                            Navigator.pop(ctx);
                          },
                        );
                      }).toList(),
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

  // ================= BUILD =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('체크리스트'),
        actions: [
          IconButton(
              icon: const Icon(Icons.folder_open), onPressed: _loadTemplate),
        ],
      ),
      body: const Center(
        child: Text('기존 체크리스트 UI 유지'),
      ),
    );
  }
}
