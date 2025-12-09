import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todolist/model/todo.dart';
import 'package:todolist/presentation/list_view_model.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

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

      _groupSettings.putIfAbsent(
        g,
            () => GroupSettings(
          color: _palette[_groups.length % _palette.length],
          icon: _icons[_groups.length % _icons.length],
        ),
      );
      _groupExpanded.putIfAbsent(g, () => true);
    }

    if (!_groups.contains('기본')) {
      _groups.insert(0, '기본');
    }
    _groupSettings.putIfAbsent(
        '기본', () => GroupSettings(color: Colors.blue, icon: Icons.label));

    _selectedGroup = _groups.first;

    _initNotifications();
  }

  Future<void> _initNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _notifications.initialize(settings);
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

  //---------------------- 템플릿 저장 ------------------------
  Future<void> _saveTemplate() async {
    final prefs = await SharedPreferences.getInstance();
    widget.todo.checklist ??= [];
    final list = widget.todo.checklist!;
    final c = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("템플릿 이름 입력"),
          content: TextField(
              controller: c,
              decoration: const InputDecoration(hintText: "예: 주간 체크리스트")),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("취소")),
            ElevatedButton(
              onPressed: () async {
                final name = c.text.trim();
                if (name.isEmpty) return;
                await prefs.setString("template_$name", jsonEncode(list));
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("템플릿 '$name' 저장됨")));
              },
              child: const Text("저장"),
            ),
          ],
        );
      },
    );
  }

  //---------------------- 템플릿 불러오기 ------------------------
  Future<void> _loadTemplate() async {
    final prefs = await SharedPreferences.getInstance();
    final keys =
    prefs.getKeys().where((k) => k.startsWith("template_")).toList();

    if (keys.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("저장된 템플릿이 없습니다")));
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text("템플릿 불러오기",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: keys.map((k) {
                  final name = k.replaceFirst("template_", "");
                  return Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      title: Text(name),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          await prefs.remove(k);
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("'$name' 템플릿 삭제됨")));
                        },
                      ),
                      onTap: () async {
                        final data = prefs.getString(k);
                        if (data == null) return;

                        final decoded = jsonDecode(data) as List;
                        setState(() {
                          widget.todo.checklist ??= [];
                          for (var it in decoded) {
                            widget.todo.checklist!
                                .add(Map<String, dynamic>.from(it));
                          }
                        });
                        _saveAndRefresh();
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("'$name' 템플릿 불러오기 완료")));
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),
          ]),
        );
      },
    );
  }

  //-------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    widget.todo.checklist ??= [];
    final checklist = widget.todo.checklist!;
    final total = checklist.length;
    final done = checklist.where((e) => e['isChecked'] == true).length;
    final progress = total == 0 ? 0.0 : done / total;

    return Scaffold(
      appBar: AppBar(
        title: Text('체크리스트 ($done/$total)'),
        actions: [
          IconButton(
              icon: Icon(hideCompleted ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => hideCompleted = !hideCompleted)),
          PopupMenuButton<String>(
            itemBuilder: (_) => [
              const PopupMenuItem(
                  value: 'saveTemplate', child: Text("템플릿 저장")),
              const PopupMenuItem(
                  value: 'loadTemplate', child: Text("템플릿 불러오기")),
            ],
            onSelected: (v) {
              if (v == 'saveTemplate') {
                _saveTemplate();
              } else if (v == 'loadTemplate') {
                _loadTemplate();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
              padding: const EdgeInsets.all(16),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: Colors.grey[300],
                color: Colors.blueAccent,
              )),
          Expanded(
            child: checklist.isEmpty
                ? const Center(child: Text("체크리스트가 비어있어요"))
                : ListView.builder(
                padding: const EdgeInsets.only(bottom: 16),
                itemCount: checklist.length,
                itemBuilder: (_, i) {
                  final item = checklist[i];
                  final isChecked = item['isChecked'] == true;
                  return Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: GestureDetector(
                        onTap: () {
                          setState(() {
                            item['isChecked'] = !isChecked;
                          });
                          _saveAndRefresh();
                        },
                        child: CircleAvatar(
                            backgroundColor:
                            isChecked ? Colors.green : Colors.grey[300],
                            child: isChecked
                                ? const Icon(Icons.check,
                                color: Colors.white)
                                : const Icon(Icons.circle_outlined,
                                color: Colors.grey)),
                      ),
                      title: Text(item['title'] ?? "",
                          style: TextStyle(
                              decoration: isChecked
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                              color:
                              isChecked ? Colors.grey : Colors.black)),
                    ),
                  );
                }),
          ),
          Padding(
            padding:
            const EdgeInsets.only(bottom: 20, left: 16, right: 16, top: 8),
            child: Row(children: [
              Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                        labelText: "체크리스트 추가", border: OutlineInputBorder()),
                    onSubmitted: (_) => _addNew(),
                  )),
              const SizedBox(width: 8),
              ElevatedButton(onPressed: _addNew, child: const Text("추가")),
            ]),
          ),
        ],
      ),
    );
  }

  void _addNew() {
    final t = controller.text.trim();
    if (t.isEmpty) return;
    setState(() {
      widget.todo.checklist!.add(
          {"title": t, "isChecked": false, "priority": 1, "pinned": false});
      controller.clear();
    });
    _saveAndRefresh();
  }
}

class GroupSettings {
  Color color;
  IconData icon;
  GroupSettings({required this.color, required this.icon});
}
