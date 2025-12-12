// checklist_screen.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:todolist/model/todo.dart';
import 'package:todolist/presentation/list_view_model.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';

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
  String searchQuery = "";
  late AnimationController _animationController;

  Map<String, dynamic>? _lastRemovedItem;
  int? _lastRemovedIndex;
  String? _lastRemovedGroup;

  List<String> _groups = [];
  String _selectedGroup = '기본';

  Map<String, GroupSettings> _groupSettings = {};
  Map<String, bool> _groupExpanded = {};

  final List<Color> _palette = const [
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

  final List<IconData> _icons = const [
    Icons.label,
    Icons.work,
    Icons.home,
    Icons.shopping_cart,
    Icons.school,
    Icons.favorite,
    Icons.pets,
    Icons.schedule,
    Icons.star,
    Icons.flag,
  ];

  final FlutterLocalNotificationsPlugin _notifications =
  FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 250));

    widget.todo.checklist ??= [];
    final checklist = widget.todo.checklist!;

    for (var item in checklist) {
      item['group'] = item['group'] ?? '기본';
      item['priority'] = item['priority'] ?? 1;
      item['isChecked'] = item['isChecked'] == true;
      item['pinned'] = item['pinned'] == true;

      final g = item['group'] as String;
      if (!_groups.contains(g)) _groups.add(g);

      if (!_groupSettings.containsKey(g)) {
        final colorVal = item['groupColor'] as int?;
        final iconVal = item['groupIcon'] as int?;
        _groupSettings[g] = GroupSettings(
          color: colorVal != null
              ? Color(colorVal)
              : _palette[_groups.length % _palette.length],
          icon: iconVal != null
              ? IconData(iconVal, fontFamily: 'MaterialIcons')
              : _icons[_groups.length % _icons.length],
        );
      }
    }

    if (!_groups.contains('기본')) {
      _groups.insert(0, '기본');
    }
    _groupSettings.putIfAbsent(
        '기본', () => GroupSettings(color: Colors.blue, icon: Icons.label));

    for (var g in _groups) {
      _groupExpanded.putIfAbsent(g, () => true);
      _groupSettings.putIfAbsent(
          g,
              () => GroupSettings(
              color: _palette[_groups.indexOf(g) % _palette.length],
              icon: _icons[_groups.indexOf(g) % _icons.length]));
    }

    _selectedGroup = _groups.isNotEmpty ? _groups.first : '기본';

    _initNotifications();
  }

  Future<void> _initNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    try {
      await _notifications.initialize(settings);
    } catch (_) {}
  }

  @override
  void dispose() {
    _animationController.dispose();
    searchController.dispose();
    controller.dispose();
    super.dispose();
  }

  void _saveAndRefresh() {
    widget.todo.checklist ??= [];
    final checklist = widget.todo.checklist!;
    for (var item in checklist) {
      final g = item['group'] as String? ?? '기본';
      final gs = _groupSettings[g];
      if (gs != null) {
        item['groupColor'] = gs.color.value;
        item['groupIcon'] = gs.icon.codePoint;
      }
    }

    widget.todo.save();
    try {
      context.read<ListViewModel>().refresh();
    } catch (_) {}
  }

  void _addGroup(String name) {
    final n = name.trim();
    if (n.isEmpty) return;
    if (!_groups.contains(n)) {
      setState(() {
        _groups.add(n);
        _groupSettings[n] = GroupSettings(
            color: _palette[_groups.length % _palette.length],
            icon: _icons[_groups.length % _icons.length]);
        _groupExpanded[n] = true;
        _selectedGroup = n;
      });
      _saveAndRefresh();
    }
  }

  void _deleteGroup(String name) {
    if (name == '기본') return;
    setState(() {
      _groups.remove(name);
      _groupSettings.remove(name);
      _groupExpanded.remove(name);

      widget.todo.checklist ??= [];
      for (var item in widget.todo.checklist!) {
        if ((item['group'] ?? '기본') == name) item['group'] = '기본';
      }

      if (!_groups.contains('기본')) _groups.insert(0, '기본');
      _selectedGroup = _groups.first;
    });
    _saveAndRefresh();
  }

  void _editGroupSettings(String groupName) {
    final gs = _groupSettings[groupName]!;
    Color selectedColor = gs.color;
    IconData selectedIcon = gs.icon;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx2, setStateInner) {
          return Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('그룹 설정',
                    style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                const Text('색상 선택'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _palette.map((c) {
                    final sel = c.value == selectedColor.value;
                    return GestureDetector(
                      onTap: () => setStateInner(() => selectedColor = c),
                      child: Container(
                        margin: const EdgeInsets.all(4),
                        width: sel ? 44 : 36,
                        height: sel ? 44 : 36,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border:
                          sel ? Border.all(color: Colors.black, width: 2) : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                const Text('아이콘 선택'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _icons.map((ic) {
                    final sel = ic.codePoint == selectedIcon.codePoint;
                    return GestureDetector(
                      onTap: () => setStateInner(() => selectedIcon = ic),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: sel ? Colors.black12 : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(ic,
                            size: 28,
                            color: sel ? Colors.black : Colors.grey[700]),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _groupSettings[groupName] =
                          GroupSettings(color: selectedColor, icon: selectedIcon);
                    });
                    _saveAndRefresh();
                    Navigator.pop(ctx);
                  },
                  child: const Text('저장'),
                ),
                const SizedBox(height: 12),
              ],
            ),
          );
        });
      },
    );
  }

  Map<String, List<Map<String, dynamic>>> _groupedItems(
      List<Map<String, dynamic>> input) {
    final map = <String, List<Map<String, dynamic>>>{};
    for (var g in _groups) map[g] = [];
    for (var item in input) {
      final g = (item['group'] ?? '기본') as String;
      map.putIfAbsent(g, () => []);
      map[g]!.add(item);
    }
    return map;
  }

  Future<void> _toggleReminder(Map<String, dynamic> item) async {
    if (item['reminder'] != null) {
      final id = item['reminder'] as int;
      try {
        await _notifications.cancel(id);
      } catch (_) {}
      setState(() => item['reminder'] = null);
      _saveAndRefresh();
      return;
    }

    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (time == null) return;

    final scheduled = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    item['reminder'] = id;

    final tzSched = tz.TZDateTime.from(scheduled, tz.local);

    try {
      await _notifications.zonedSchedule(
        id,
        '할 일 알림',
        item['title'] ?? '할 일',
        tzSched,
        const NotificationDetails(
          android: AndroidNotificationDetails('reminder', 'Todo Reminder',
              importance: Importance.high, priority: Priority.high),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (_) {}

    _saveAndRefresh();
    setState(() {});
  }

  // ------------------ Template helpers --------------------

  String _prefsKeyFor(String category, String name) => 'template/$category/$name';

  Future<List<String>> _allTemplateKeys() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getKeys().where((k) => k.startsWith('template/')).toList();
  }

  Future<void> _saveTemplate() async {
    final prefs = await SharedPreferences.getInstance();
    widget.todo.checklist ??= [];
    final list = widget.todo.checklist!;
    final nameController = TextEditingController();
    final categoryController = TextEditingController();
    Color chosenColor = Colors.blue;
    IconData chosenIcon = Icons.label;

    // UI: name, category, color, icon. If key exists -> ask overwrite.
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx2, setStateInner) {
          return AlertDialog(
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: const Text("템플릿 저장"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: nameController, decoration: const InputDecoration(labelText: '템플릿 이름')),
                  const SizedBox(height: 8),
                  TextField(controller: categoryController, decoration: const InputDecoration(labelText: '카테고리 (비워두면 기본)')),
                  const SizedBox(height: 12),
                  Row(children: const [Text('카테고리 색'), SizedBox(width: 12)]),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _palette.map((c) {
                      final sel = c.value == chosenColor.value;
                      return GestureDetector(
                        onTap: () => setStateInner(() => chosenColor = c),
                        child: Container(
                          margin: const EdgeInsets.all(4),
                          width: sel ? 44 : 36,
                          height: sel ? 44 : 36,
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                            border: sel ? Border.all(color: Colors.black, width: 2) : null,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  Row(children: const [Text('카테고리 아이콘'), SizedBox(width: 12)]),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _icons.map((ic) {
                      final sel = ic.codePoint == chosenIcon.codePoint;
                      return GestureDetector(
                        onTap: () => setStateInner(() => chosenIcon = ic),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: sel ? Colors.black12 : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(ic, size: 28, color: sel ? Colors.black : Colors.grey[700]),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
              ElevatedButton(
                onPressed: () async {
                  final name = nameController.text.trim();
                  final catRaw = categoryController.text.trim();
                  final cat = catRaw.isEmpty ? '기본' : catRaw;
                  if (name.isEmpty) return;

                  final key = _prefsKeyFor(cat, name);
                  final exists = prefs.containsKey(key);

                  // If exists, confirm overwrite
                  if (exists) {
                    final overwrite = await showDialog<bool>(
                      context: context,
                      builder: (oc) {
                        return AlertDialog(
                          title: const Text('덮어쓰기 확인'),
                          content: Text("'$cat > $name' 템플릿이 이미 존재합니다. 덮어쓰시겠어요?"),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(oc, false), child: const Text('취소')),
                            ElevatedButton(onPressed: () => Navigator.pop(oc, true), child: const Text('덮어쓰기')),
                          ],
                        );
                      },
                    );
                    if (overwrite != true) return;
                  }

                  final payload = {
                    'meta': {'categoryColor': chosenColor.value, 'categoryIcon': chosenIcon.codePoint},
                    'items': list,
                  };
                  await prefs.setString(key, jsonEncode(payload));
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("'$cat > $name' 템플릿 저장됨")));
                },
                child: const Text('저장'),
              ),
            ],
          );
        });
      },
    );
  }

  Future<void> _exportTemplateAsJson(String fullKey) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(fullKey);
    if (data == null) return;
    await Clipboard.setData(ClipboardData(text: data));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('템플릿 JSON이 클립보드에 복사되었습니다')));
  }

  Future<void> _importTemplateFromJson() async {
    final prefs = await SharedPreferences.getInstance();
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('템플릿 가져오기 (JSON 붙여넣기)'),
          content: TextField(
            controller: controller,
            maxLines: 10,
            decoration: const InputDecoration(hintText: 'JSON 문자열을 붙여넣으세요'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
            ElevatedButton(
              onPressed: () async {
                final text = controller.text.trim();
                if (text.isEmpty) return;
                try {
                  final Map parsed = jsonDecode(text);
                  final meta = parsed['meta'] as Map? ?? {};
                  final items = parsed['items'] as List? ?? [];
                  final category = (meta['category'] != null && meta['category'] is String)
                      ? meta['category'] as String
                      : (parsed['category'] as String? ?? '기본');
                  final name = parsed['name'] as String? ?? 'imported_${DateTime.now().millisecondsSinceEpoch}';
                  final key = _prefsKeyFor(category, name);
                  final payload = {'meta': {'categoryColor': meta['categoryColor'] ?? Colors.blue.value, 'categoryIcon': meta['categoryIcon'] ?? Icons.label.codePoint}, 'items': items};
                  await prefs.setString(key, jsonEncode(payload));
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('템플릿 가져오기 완료')));
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('유효한 JSON이 아닙니다')));
                }
              },
              child: const Text('가져오기'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _loadTemplate() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith('template/')).toList();

    if (keys.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('저장된 템플릿이 없습니다')));
      return;
    }

    // categorize
    final Map<String, List<String>> categories = {};
    for (var k in keys) {
      final parts = k.split('/');
      if (parts.length >= 3) {
        final cat = parts[1];
        categories.putIfAbsent(cat, () => []);
        categories[cat]!.add(k);
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 12,
            right: 12,
            top: 8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 4,
                margin: const EdgeInsets.only(top: 8, bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const Text('템플릿 불러오기', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Row(children: [
                  ElevatedButton.icon(onPressed: _importTemplateFromJson, icon: const Icon(Icons.download), label: const Text('JSON 가져오기')),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(onPressed: () async {
                    // copy list of keys to clipboard as a quick backup
                    final data = keys.join('\n');
                    await Clipboard.setData(ClipboardData(text: data));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('템플릿 키 목록이 클립보드에 복사되었습니다')));
                  }, icon: const Icon(Icons.copy_all), label: const Text('키 복사')),
                ]),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: categories.entries.map((entry) {
                    final cat = entry.key;
                    final list = entry.value;
                    // get meta for avatar color/icon from first template if available
                    Color avatarColor = Colors.blue;
                    IconData avatarIcon = Icons.folder;
                    if (list.isNotEmpty) {
                      final sample = prefs.getString(list.first);
                      if (sample != null) {
                        try {
                          final dec = jsonDecode(sample) as Map;
                          final meta = dec['meta'] as Map? ?? {};
                          if (meta['categoryColor'] != null) avatarColor = Color(meta['categoryColor']);
                          if (meta['categoryIcon'] != null) avatarIcon = IconData(meta['categoryIcon'], fontFamily: 'MaterialIcons');
                        } catch (_) {}
                      }
                    }
                    return Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ExpansionTile(
                        leading: CircleAvatar(backgroundColor: avatarColor, child: Icon(avatarIcon, color: Colors.white)),
                        title: Text(cat, style: const TextStyle(fontWeight: FontWeight.bold)),
                        children: list.map((fullKey) {
                          final name = fullKey.split('/').last;
                          return FutureBuilder<String?>(
                            future: Future(() async => prefs.getString(fullKey)),
                            builder: (context, snap) {
                              if (!snap.hasData) return ListTile(title: Text(name));
                              final raw = snap.data!;
                              Map meta = {};
                              List items = [];
                              try {
                                final parsed = jsonDecode(raw) as Map;
                                meta = parsed['meta'] ?? {};
                                items = parsed['items'] ?? [];
                              } catch (_) {}
                              final catColor = meta['categoryColor'] != null ? Color(meta['categoryColor']) : Colors.blue;
                              final catIcon = meta['categoryIcon'] != null ? IconData(meta['categoryIcon'], fontFamily: 'MaterialIcons') : Icons.label;
                              return ListTile(
                                title: Text(name),
                                subtitle: Text('항목 ${items.length}개'),
                                leading: CircleAvatar(backgroundColor: catColor, child: Icon(catIcon, color: Colors.white)),
                                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                                  IconButton(icon: const Icon(Icons.visibility), tooltip: '미리보기', onPressed: () {
                                    // preview modal
                                    showModalBottomSheet(context: context, builder: (pvCtx) {
                                      return Padding(
                                        padding: EdgeInsets.only(bottom: MediaQuery.of(pvCtx).viewInsets.bottom, left: 12, right: 12, top: 12),
                                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                                          ListTile(leading: CircleAvatar(backgroundColor: catColor, child: Icon(catIcon, color: Colors.white)), title: Text(name), subtitle: Text(cat)),
                                          const Divider(),
                                          Flexible(
                                            child: ListView.builder(
                                              shrinkWrap: true,
                                              itemCount: items.length,
                                              itemBuilder: (c, i) {
                                                final it = Map<String,dynamic>.from(items[i]);
                                                return ListTile(
                                                  leading: it['isChecked'] == true ? const Icon(Icons.check_circle, color: Colors.green) : const Icon(Icons.radio_button_unchecked),
                                                  title: Text(it['title'] ?? ''),
                                                  subtitle: it['due'] != null ? Text('마감: ${DateFormat('yyyy-MM-dd').format(DateTime.fromMillisecondsSinceEpoch(it['due']).toLocal())}') : null,
                                                );
                                              },
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          Row(children: [
                                            ElevatedButton.icon(onPressed: () => Navigator.pop(pvCtx), icon: const Icon(Icons.close), label: const Text('닫기')),
                                            const SizedBox(width: 8),
                                            ElevatedButton.icon(onPressed: () { Navigator.pop(pvCtx); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('미리보기 닫음'))); }, icon: const Icon(Icons.playlist_add), label: const Text('적용 예시')),
                                          ]),
                                          const SizedBox(height: 12),
                                        ]),
                                      );
                                    }, isScrollControlled: true);
                                  }),
                                  IconButton(icon: const Icon(Icons.download), tooltip: '내보내기(JSON 복사)', onPressed: () => _exportTemplateAsJson(fullKey)),
                                  IconButton(icon: const Icon(Icons.delete_outline), tooltip: '삭제', onPressed: () async {
                                    final confirm = await showDialog<bool>(context: context, builder: (dctx) {
                                      return AlertDialog(
                                        title: const Text('템플릿 삭제'),
                                        content: Text("'$cat > $name' 템플릿을 삭제하시겠습니까?"),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(dctx, false), child: const Text('취소')),
                                          ElevatedButton(onPressed: () => Navigator.pop(dctx, true), child: const Text('삭제')),
                                        ],
                                      );
                                    });
                                    if (confirm == true) {
                                      await prefs.remove(fullKey);
                                      Navigator.pop(context); // close bottom sheet to refresh view
                                      await Future.delayed(const Duration(milliseconds: 300));
                                      _loadTemplate(); // reopen to refresh
                                    }
                                  }),
                                ]),
                                onTap: () async {
                                  // apply: add / overwrite / merge
                                  final action = await showDialog<String>(
                                    context: context,
                                    builder: (applyCtx) {
                                      return AlertDialog(
                                        title: const Text('템플릿 적용 방식 선택'),
                                        content: const Text('템플릿을 어떻게 적용할까요?'),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(applyCtx, 'add'), child: const Text('추가하기')),
                                          TextButton(onPressed: () => Navigator.pop(applyCtx, 'merge'), child: const Text('병합(중복제거)')),
                                          ElevatedButton(onPressed: () => Navigator.pop(applyCtx, 'overwrite'), child: const Text('덮어쓰기')),
                                        ],
                                      );
                                    },
                                  );
                                  if (action == null) return;

                                  setState(() {
                                    widget.todo.checklist ??= [];
                                    if (action == 'overwrite') {
                                      widget.todo.checklist!.clear();
                                      for (var it in items) widget.todo.checklist!.add(Map<String, dynamic>.from(it));
                                    } else if (action == 'add') {
                                      for (var it in items) widget.todo.checklist!.add(Map<String, dynamic>.from(it));
                                    } else if (action == 'merge') {
                                      // merge by title: keep existing, append new non-duplicates
                                      final existingTitles = widget.todo.checklist!.map((e) => (e['title'] ?? '').toString()).toSet();
                                      for (var it in items) {
                                        final title = (it['title'] ?? '').toString();
                                        if (!existingTitles.contains(title)) {
                                          widget.todo.checklist!.add(Map<String, dynamic>.from(it));
                                          existingTitles.add(title);
                                        }
                                      }
                                    }
                                  });

                                  _saveAndRefresh();
                                  Navigator.pop(context); // close bottom sheet
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("'$cat > $name' 템플릿 적용됨")));
                                },
                              );
                            },
                          );
                        }).toList(),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  // ------------------ End Template helpers --------------------

  @override
  Widget build(BuildContext context) {
    widget.todo.checklist ??= [];
    final checklist = widget.todo.checklist!;

    for (var item in checklist) {
      item['group'] = item['group'] ?? '기본';
      item['priority'] = item['priority'] ?? 1;
      item['isChecked'] = item['isChecked'] == true;
      item['pinned'] = item['pinned'] == true;
      final g = item['group'] as String;
      if (!_groups.contains(g)) {
        _groups.add(g);
        _groupSettings.putIfAbsent(g, () => GroupSettings(color: _palette[_groups.length % _palette.length], icon: _icons[_groups.length % _icons.length]));
        _groupExpanded.putIfAbsent(g, () => true);
      }
    }

    final grouped = _groupedItems(checklist);

    final total = checklist.length;
    final done = checklist.where((e) => e['isChecked'] == true).length;
    final progress = total == 0 ? 0.0 : done / total;

    final visibleItemsByGroup = <String, List<Map<String, dynamic>>>{};
    for (var g in grouped.keys) {
      final items = List<Map<String, dynamic>>.from(grouped[g]!);
      items.removeWhere((e) => hideCompleted && e['isChecked'] == true);
      items.sort((a, b) {
        final aPinned = a['pinned'] == true;
        final bPinned = b['pinned'] == true;
        if (aPinned != bPinned) return aPinned ? -1 : 1;

        final ap = (a['priority'] ?? 1) as int;
        final bp = (b['priority'] ?? 1) as int;
        if (ap != bp) return bp - ap;

        final aDue = a['due'] as int?;
        final bDue = b['due'] as int?;
        if (aDue != null && bDue != null) return aDue.compareTo(bDue);
        if (aDue != null) return -1;
        if (bDue != null) return 1;

        final aChecked = a['isChecked'] == true;
        final bChecked = b['isChecked'] == true;
        if (aChecked != bChecked) return aChecked ? 1 : -1;

        return 0;
      });
      visibleItemsByGroup[g] = items;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('체크리스트 ($done/$total)'),
        actions: [
          IconButton(
            icon: Icon(hideCompleted ? Icons.visibility_off : Icons.visibility),
            onPressed: () => setState(() => hideCompleted = !hideCompleted),
            tooltip: hideCompleted ? '완료 숨김 중' : '완료 보기',
          ),
          IconButton(icon: const Icon(Icons.save_alt), tooltip: '템플릿 저장', onPressed: _saveTemplate),
          IconButton(icon: const Icon(Icons.folder_open), tooltip: '템플릿 관리', onPressed: _loadTemplate),
          PopupMenuButton<String>(
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'manageGroups', child: Text('그룹 관리')),
              const PopupMenuItem(value: 'checkAll', child: Text('전체 완료')),
              const PopupMenuItem(value: 'uncheckAll', child: Text('전체 해제')),
            ],
            onSelected: (v) {
              if (v == 'manageGroups') {
                showDialog(
                  context: context,
                  builder: (ctx) {
                    final addCtrl = TextEditingController();
                    return AlertDialog(
                      title: const Text('그룹 관리'),
                      content: SizedBox(
                        width: double.maxFinite,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextField(controller: addCtrl, decoration: const InputDecoration(hintText: '새 그룹명')),
                            const SizedBox(height: 8),
                            ElevatedButton(onPressed: () { _addGroup(addCtrl.text); Navigator.of(ctx).pop(); }, child: const Text('추가')),
                            const Divider(),
                            Flexible(
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: _groups.length,
                                itemBuilder: (c, i) {
                                  final g = _groups[i];
                                  return ListTile(
                                    leading: Icon(_groupSettings[g]?.icon, color: _groupSettings[g]?.color),
                                    title: Text(g),
                                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                                      IconButton(icon: const Icon(Icons.edit), onPressed: () { Navigator.of(ctx).pop(); _editGroupSettings(g); }),
                                      if (g != '기본') IconButton(icon: const Icon(Icons.delete_outline), onPressed: () { _deleteGroup(g); Navigator.of(ctx).pop(); }),
                                    ]),
                                  );
                                },
                              ),
                            )
                          ],
                        ),
                      ),
                    );
                  },
                );
              } else if (v == 'checkAll') {
                setState(() { for (var it in checklist) it['isChecked'] = true; });
                _saveAndRefresh();
              } else if (v == 'uncheckAll') {
                setState(() { for (var it in checklist) it['isChecked'] = false; });
                _saveAndRefresh();
              }
            },
          ),
        ],
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: LinearProgressIndicator(value: progress, minHeight: 8, backgroundColor: Colors.grey[300], color: Colors.blueAccent),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: searchController,
            onChanged: (v) => setState(() => searchQuery = v),
            decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: '검색 (제목)', suffixIcon: searchQuery.isNotEmpty ? IconButton(icon: const Icon(Icons.clear), onPressed: () { searchController.clear(); setState(() => searchQuery = ''); }) : null, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), isDense: true, contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12)),
          ),
        ),

        const SizedBox(height: 8),

        Expanded(
          child: _groups.isEmpty ? const Center(child: Text('체크리스트가 비어있어요')) : ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: _groups.map((groupName) {
              final gs = _groupSettings[groupName]!;
              final items = visibleItemsByGroup[groupName] ?? [];

              final filteredItems = items.where((it) {
                final title = (it['title'] ?? '') as String;
                if (searchQuery.isNotEmpty && !title.toLowerCase().contains(searchQuery.toLowerCase())) return false;
                return true;
              }).toList();

              return Padding(
                key: ValueKey('group_$groupName'),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ExpansionTile(
                    leading: CircleAvatar(backgroundColor: gs.color, child: Icon(gs.icon, color: Colors.white)),
                    title: Row(children: [Text(groupName, style: const TextStyle(fontWeight: FontWeight.bold)), const SizedBox(width: 8), Chip(label: Text('${filteredItems.length}'))]),
                    initiallyExpanded: _groupExpanded[groupName] ?? true,
                    onExpansionChanged: (v) => setState(() => _groupExpanded[groupName] = v),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(children: [
                          TextButton.icon(onPressed: () => _editGroupSettings(groupName), icon: const Icon(Icons.settings), label: const Text('그룹 설정')),
                          const Spacer(),
                          IconButton(icon: const Icon(Icons.add), onPressed: () { _showAddItemToGroup(groupName); }),
                        ]),
                      ),

                      ReorderableListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredItems.length,
                        onReorder: (oldIndex, newIndex) {
                          setState(() {
                            if (newIndex > oldIndex) newIndex--;
                            final itm = filteredItems.removeAt(oldIndex);
                            filteredItems.insert(newIndex, itm);

                            final all = widget.todo.checklist!;
                            all.removeWhere((e) => (e['group'] ?? '기본') == groupName);
                            all.addAll(filteredItems);
                            all.sort((a, b) {
                              final aPinned = a['pinned'] == true;
                              final bPinned = b['pinned'] == true;
                              if (aPinned != bPinned) return aPinned ? -1 : 1;
                              final ap = (a['priority'] ?? 1) as int;
                              final bp = (b['priority'] ?? 1) as int;
                              if (ap != bp) return bp - ap;
                              final aChecked = a['isChecked'] == true;
                              final bChecked = b['isChecked'] == true;
                              if (aChecked != bChecked) return aChecked ? 1 : -1;
                              return 0;
                            });
                          });
                          _saveAndRefresh();
                        },
                        itemBuilder: (context, idx) {
                          final item = filteredItems[idx];
                          final isChecked = item['isChecked'] == true;
                          final pr = (item['priority'] ?? 1) as int;
                          final due = item['due'] as int?;
                          final reminder = item['reminder'] as int?;

                          Color priorityColor = pr == 2 ? Colors.red : pr == 1 ? Colors.blue : Colors.grey;

                          return Dismissible(
                            key: ValueKey(item.hashCode ^ idx),
                            background: Container(color: Colors.green, alignment: Alignment.centerLeft, padding: const EdgeInsets.only(left: 20), child: const Icon(Icons.check, color: Colors.white)),
                            secondaryBackground: Container(color: Colors.red, alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 16), child: const Icon(Icons.delete, color: Colors.white)),
                            confirmDismiss: (direction) async {
                              if (direction == DismissDirection.startToEnd) {
                                setState(() { item['isChecked'] = !(item['isChecked'] == true); });
                                _animationController.forward(from: 0);
                                Future.delayed(const Duration(milliseconds: 200), () => _saveAndRefresh());
                                return false;
                              } else {
                                _lastRemovedItem = Map<String, dynamic>.from(item);
                                _lastRemovedIndex = widget.todo.checklist!.indexOf(item);
                                _lastRemovedGroup = groupName;
                                setState(() { widget.todo.checklist!.removeAt(_lastRemovedIndex!); });
                                _saveAndRefresh();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('항목이 삭제되었습니다'),
                                    action: SnackBarAction(label: '취소', onPressed: () {
                                      if (_lastRemovedItem != null && _lastRemovedIndex != null) {
                                        setState(() { widget.todo.checklist!.insert(_lastRemovedIndex!, _lastRemovedItem!); _lastRemovedItem = null; _lastRemovedIndex = null; _lastRemovedGroup = null; });
                                        _saveAndRefresh();
                                      }
                                    }),
                                    duration: const Duration(seconds: 4),
                                  ),
                                );
                                return true;
                              }
                            },
                            child: ListTile(
                              onLongPress: () => _editItem(item),
                              leading: GestureDetector(
                                onTap: () { setState(() { item['isChecked'] = !isChecked; }); _saveAndRefresh(); },
                                child: ScaleTransition(
                                  scale: Tween<double>(begin: 1.0, end: 1.15).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut)),
                                  child: CircleAvatar(backgroundColor: isChecked ? Colors.green : Colors.transparent, child: isChecked ? const Icon(Icons.check, color: Colors.white) : const Icon(Icons.circle_outlined, color: Colors.grey)),
                                ),
                              ),
                              title: Text(item['title'] ?? '', style: TextStyle(decoration: isChecked ? TextDecoration.lineThrough : TextDecoration.none, color: isChecked ? Colors.grey : Colors.black)),
                              subtitle: due != null ? Text('마감: ${DateFormat('yyyy-MM-dd').format(DateTime.fromMillisecondsSinceEpoch(due).toLocal())}', style: TextStyle(color: due != null && DateTime.fromMillisecondsSinceEpoch(due).isBefore(DateTime.now()) ? Colors.red : Colors.grey[700])) : null,
                              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                                IconButton(icon: Icon(Icons.flag, color: priorityColor), onPressed: () => _showPrioritySelector(item)),
                                IconButton(icon: Icon(reminder != null ? Icons.notifications_active : Icons.notifications_none, color: reminder != null ? Colors.orange : Colors.grey), onPressed: () => _toggleReminder(item)),
                                IconButton(icon: Icon(item['pinned'] == true ? Icons.push_pin : Icons.push_pin_outlined, color: item['pinned'] == true ? Colors.orange : Colors.grey), onPressed: () { setState(() { item['pinned'] = !(item['pinned'] == true); }); _saveAndRefresh(); }),
                                const Icon(Icons.drag_handle)
                              ]),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        Padding(
          padding: const EdgeInsets.only(bottom: 20, left: 16, right: 16, top: 8),
          child: Row(children: [
            DropdownButton<String>(value: _selectedGroup, items: _groups.map((g) => DropdownMenuItem(value: g, child: Row(children: [Icon(_groupSettings[g]?.icon, color: _groupSettings[g]?.color), const SizedBox(width: 6), Text(g)]))).toList(), onChanged: (v) => setState(() => _selectedGroup = v ?? '기본')),
            const SizedBox(width: 8),
            Expanded(child: TextField(controller: controller, decoration: const InputDecoration(labelText: '체크리스트 추가', border: OutlineInputBorder()), onSubmitted: (_) => _addNewItem())),
            const SizedBox(width: 10),
            ElevatedButton(onPressed: _addNewItem, child: const Text('추가'))
          ]),
        )
      ]),
    );
  }

  void _showAddItemToGroup(String groupName) {
    final c = TextEditingController();
    showModalBottomSheet(context: context, isScrollControlled: true, builder: (ctx) {
      return Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 16, right: 16, top: 16), child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: c, decoration: const InputDecoration(labelText: '새 항목 제목')),
        const SizedBox(height: 12),
        ElevatedButton(onPressed: () {
          final t = c.text.trim(); if (t.isEmpty) return;
          setState(() {
            widget.todo.checklist ??= [];
            widget.todo.checklist!.add({'title': t, 'isChecked': false, 'memo': '', 'due': null, 'reminder': null, 'group': groupName, 'priority': 1, 'pinned': false});
          });
          _saveAndRefresh();
          Navigator.pop(ctx);
        }, child: const Text('추가'))
      ]));
    });
  }

  void _addNewItem() {
    final text = controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      widget.todo.checklist ??= [];
      widget.todo.checklist!.add({'title': text, 'isChecked': false, 'memo': '', 'due': null, 'reminder': null, 'group': _selectedGroup, 'priority': 1, 'pinned': false});
      if (!_groups.contains(_selectedGroup)) {
        _groups.add(_selectedGroup);
        _groupSettings.putIfAbsent(_selectedGroup, () => GroupSettings(color: _palette[_groups.length % _palette.length], icon: _icons[_groups.length % _icons.length]));
      }
      controller.clear();
    });
    _saveAndRefresh();
  }

  void _showPrioritySelector(Map<String, dynamic> item) {
    showModalBottomSheet(context: context, builder: (ctx) {
      return Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(leading: const Icon(Icons.arrow_upward), title: const Text('높음'), onTap: () { setState(() { item['priority'] = 2; }); _saveAndRefresh(); Navigator.pop(ctx); }),
        ListTile(leading: const Icon(Icons.check), title: const Text('보통'), onTap: () { setState(() { item['priority'] = 1; }); _saveAndRefresh(); Navigator.pop(ctx); }),
        ListTile(leading: const Icon(Icons.arrow_downward), title: const Text('낮음'), onTap: () { setState(() { item['priority'] = 0; }); _saveAndRefresh(); Navigator.pop(ctx); }),
      ]);
    });
  }

  void _editItem(Map item) {
    final title = TextEditingController(text: item['title']);
    final memo = TextEditingController(text: item['memo']);
    DateTime? due = item['due'] != null ? DateTime.fromMillisecondsSinceEpoch(item['due']) : null;

    showModalBottomSheet(context: context, isScrollControlled: true, builder: (_) {
      return Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 16), child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: title, decoration: const InputDecoration(labelText: '제목')),
        const SizedBox(height: 8),
        TextField(controller: memo, maxLines: 4, decoration: const InputDecoration(labelText: '메모')),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: Text(due == null ? '마감일 없음' : '마감일: ${DateFormat('yyyy-MM-dd').format(due!.toLocal())}')),
          TextButton(child: const Text('날짜 선택'), onPressed: () async {
            final picked = await showDatePicker(context: context, initialDate: due ?? DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100));
            if (picked != null) setState(() => due = picked);
          }),
        ]),
        const SizedBox(height: 12),
        ElevatedButton(child: const Text('저장'), onPressed: () { setState(() { item['title'] = title.text.trim(); item['memo'] = memo.text.trim(); item['due'] = due?.millisecondsSinceEpoch; }); _saveAndRefresh(); Navigator.pop(context); }),
        const SizedBox(height: 12),
      ]));
    });
  }
}

class GroupSettings {
  Color color;
  IconData icon;
  GroupSettings({required this.color, required this.icon});
}
