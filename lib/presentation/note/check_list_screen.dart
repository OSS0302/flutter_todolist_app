import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todolist/model/todo.dart';
import 'package:todolist/presentation/list_view_model.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzdata;

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

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  final ImagePicker _picker = ImagePicker();

  Timer? _autoArchiveTimer;
  // auto-archive threshold in hours
  static const int _autoArchiveHours = 24;

  @override
  void initState() {
    super.initState();
    tzdata.initializeTimeZones();
    _animationController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 250));

    final checklist = widget.todo.checklist ?? [];

    for (var item in checklist) {
      item['group'] = item['group'] ?? '기본';
      item['priority'] = item['priority'] ?? 1;
      item['isChecked'] = item['isChecked'] == true;
      item['pinned'] = item['pinned'] == true;
      item['subtasks'] = (item['subtasks'] is List) ? item['subtasks'] : <Map<String, dynamic>>[];
      // attach fields possibly missing
      item['memo'] = item['memo'] ?? '';
      item['due'] = item['due'];
      item['reminder'] = item['reminder'];
      item['reminderRepeat'] = item['reminderRepeat'] ?? 'none';
      item['imagePath'] = item['imagePath'];
      item['completedAt'] = item['completedAt'];
      final g = item['group'] as String;
      if (!_groups.contains(g)) _groups.add(g);
      if (!_groupSettings.containsKey(g)) {
        final colorVal = item['groupColor'] as int?;
        final iconVal = item['groupIcon'] as int?;
        _groupSettings[g] = GroupSettings(
          color: colorVal != null ? Color(colorVal) : _palette[_groups.length % _palette.length],
          icon: iconVal != null ? IconData(iconVal, fontFamily: 'MaterialIcons') : _icons[_groups.length % _icons.length],
        );
      }
    }

    if (!_groups.contains('기본')) {
      _groups.insert(0, '기본');
      _groupSettings.putIfAbsent('기본', () => GroupSettings(color: Colors.blue, icon: Icons.label));
    }

    for (var g in _groups) {
      _groupExpanded.putIfAbsent(g, () => true);
      _groupSettings.putIfAbsent(g, () => GroupSettings(color: _palette[_groups.indexOf(g) % _palette.length], icon: _icons[_groups.indexOf(g) % _icons.length]));
    }

    _selectedGroup = _groups.isNotEmpty ? _groups.first : '기본';
    _initNotifications();
    _startAutoArchiveTimer();
    // ensure archive field
    widget.todo.archive ??= <Map<String, dynamic>>[];
  }

  Future<void> _initNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _notifications.initialize(settings);
  }

  void _startAutoArchiveTimer() {
    // Run every 15 minutes to check for completed items that exceed threshold
    _autoArchiveTimer?.cancel();
    _autoArchiveTimer = Timer.periodic(const Duration(minutes: 15), (_) => _autoArchiveDueItems());
    // also run once immediately
    WidgetsBinding.instance.addPostFrameCallback((_) => _autoArchiveDueItems());
  }

  void _stopAutoArchiveTimer() {
    _autoArchiveTimer?.cancel();
    _autoArchiveTimer = null;
  }

  void _autoArchiveDueItems() {
    final list = widget.todo.checklist ?? [];
    final now = DateTime.now();
    final threshold = Duration(hours: _autoArchiveHours);
    final toArchive = <Map<String, dynamic>>[];
    for (var item in list.toList()) {
      if (item['isChecked'] == true) {
        final completedAtMillis = item['completedAt'] as int?;
        if (completedAtMillis != null) {
          final completedAt = DateTime.fromMillisecondsSinceEpoch(completedAtMillis);
          if (now.difference(completedAt) >= threshold) {
            toArchive.add(item);
          }
        } else {
          // If no completedAt present, set it now and skip archiving until threshold passed
          item['completedAt'] = now.millisecondsSinceEpoch;
        }
      }
    }

    if (toArchive.isNotEmpty) {
      for (var it in toArchive) {
        _moveToArchive(it);
      }
      _saveAndRefresh();
    } else {
      // save any completedAt updates
      widget.todo.save();
    }
  }

  @override
  void dispose() {
    _stopAutoArchiveTimer();
    _animationController.dispose();
    searchController.dispose();
    controller.dispose();
    super.dispose();
  }

  void _saveAndRefresh() {
    final checklist = widget.todo.checklist ?? [];
    for (var item in checklist) {
      final g = (item['group'] as String?) ?? '기본';
      final gs = _groupSettings[g];
      if (gs != null) {
        item['groupColor'] = gs.color.value;
        item['groupIcon'] = gs.icon.codePoint;
      }
    }
    widget.todo.save();
    context.read<ListViewModel>().refresh();
  }

  void _addGroup(String name) {
    final n = name.trim();
    if (n.isEmpty) return;
    if (!_groups.contains(n)) {
      setState(() {
        _groups.add(n);
        _groupSettings[n] = GroupSettings(color: _palette[_groups.length % _palette.length], icon: _icons[_groups.length % _icons.length]);
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
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 16, right: 16, top: 16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('그룹 설정', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text('색상 선택'),
            const SizedBox(height: 8),
            Wrap(spacing: 8, children: _palette.map((c) {
              final sel = c.value == selectedColor.value;
              return GestureDetector(
                onTap: () => setState(() => selectedColor = c),
                child: Container(
                  margin: const EdgeInsets.all(4),
                  width: sel ? 44 : 36,
                  height: sel ? 44 : 36,
                  decoration: BoxDecoration(color: c, shape: BoxShape.circle, border: sel ? Border.all(color: Colors.black, width: 2) : null),
                ),
              );
            }).toList()),
            const SizedBox(height: 12),
            const Text('아이콘 선택'),
            const SizedBox(height: 8),
            Wrap(spacing: 8, children: _icons.map((ic) {
              final sel = ic.codePoint == selectedIcon.codePoint;
              return GestureDetector(
                onTap: () => setState(() => selectedIcon = ic),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: sel ? Colors.black12 : Colors.transparent, borderRadius: BorderRadius.circular(8)),
                  child: Icon(ic, size: 28, color: sel ? Colors.black : Colors.grey[700]),
                ),
              );
            }).toList()),
            const SizedBox(height: 14),
            ElevatedButton(onPressed: () {
              setState(() {
                _groupSettings[groupName] = GroupSettings(color: selectedColor, icon: selectedIcon);
              });
              _saveAndRefresh();
              Navigator.pop(ctx);
            }, child: const Text('저장')),
            const SizedBox(height: 12),
          ]),
        );
      },
    );
  }

  Map<String, List<Map<String, dynamic>>> _groupedItems(List<Map<String, dynamic>> input) {
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
      await _notifications.cancel(id);
      setState(() {
        item['reminder'] = null;
        item['reminderRepeat'] = 'none';
      });
      _saveAndRefresh();
      return;
    }

    final date = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100));
    if (date == null) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (time == null) return;

    String repeat = 'none';
    await showModalBottomSheet(context: context, builder: (ctx) {
      String sel = 'none';
      return StatefulBuilder(builder: (c, s) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(c).viewInsets.bottom, left: 16, right: 16, top: 16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('반복 옵션 선택', style: TextStyle(fontWeight: FontWeight.bold)),
            RadioListTile<String>(value: 'none', groupValue: sel, title: const Text('반복 없음'), onChanged: (v) => s(() => sel = v ?? 'none')),
            RadioListTile<String>(value: 'daily', groupValue: sel, title: const Text('매일'), onChanged: (v) => s(() => sel = v ?? 'daily')),
            RadioListTile<String>(value: 'weekly', groupValue: sel, title: const Text('매주'), onChanged: (v) => s(() => sel = v ?? 'weekly')),
            const SizedBox(height: 8),
            ElevatedButton(onPressed: () { repeat = sel; Navigator.pop(c); }, child: const Text('확인')),
            const SizedBox(height: 8),
          ]),
        );
      });
    });

    final scheduled = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    item['reminder'] = id;
    item['reminderRepeat'] = repeat;

    tz.TZDateTime tzSched = tz.TZDateTime.from(scheduled, tz.local);

    final matchComponents = (repeat == 'daily')
        ? DateTimeComponents.time
        : (repeat == 'weekly')
        ? DateTimeComponents.dayOfWeekAndTime
        : null;

    await _notifications.zonedSchedule(
      id,
      '할 일 알림',
      item['title'] ?? '할 일',
      tzSched,
      NotificationDetails(
        android: AndroidNotificationDetails('reminder', 'Todo Reminder', importance: Importance.high, priority: Priority.high),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: matchComponents,
    );

    _saveAndRefresh();
    setState(() {});
  }

  void _addSubtask(Map<String, dynamic> item) {
    final c = TextEditingController();
    showModalBottomSheet(context: context, isScrollControlled: true, builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 16, right: 16, top: 16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: c, decoration: const InputDecoration(labelText: '서브태스크 제목')),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: () {
            final t = c.text.trim();
            if (t.isEmpty) return;
            setState(() {
              item['subtasks'] ??= <Map<String, dynamic>>[];
              (item['subtasks'] as List).add({'title': t, 'isChecked': false});
            });
            _saveAndRefresh();
            Navigator.pop(ctx);
          }, child: const Text('추가'))
        ]),
      );
    });
  }

  String _formatDueText(int? dueMillis) {
    if (dueMillis == null) return '마감일 없음';
    final dueDt = DateTime.fromMillisecondsSinceEpoch(dueMillis).toLocal();
    final today = DateTime.now();
    final dueDate = DateTime(dueDt.year, dueDt.month, dueDt.day);
    final nowDate = DateTime(today.year, today.month, today.day);
    final diff = dueDate.difference(nowDate).inDays;
    if (diff == 0) return 'D-DAY (${DateFormat('yyyy-MM-dd').format(dueDt)})';
    if (diff > 0) return 'D-$diff (${DateFormat('yyyy-MM-dd').format(dueDt)})';
    return 'D+${-diff} (${DateFormat('yyyy-MM-dd').format(dueDt)})';
  }

  void _moveItemToGroup(Map<String, dynamic> item, String destGroup) {
    setState(() {
      item['group'] = destGroup;
    });
    _saveAndRefresh();
  }

  // image picking (camera or gallery)
  Future<void> _pickImageForItem(Map<String, dynamic> item, ImageSource source) async {
    try {
      final picked = await _picker.pickImage(source: source, maxWidth: 1600, maxHeight: 1600, imageQuality: 85);
      if (picked == null) return;
      // store file path
      setState(() {
        item['imagePath'] = picked.path;
      });
      _saveAndRefresh();
    } catch (e) {
      // ignore or show error
    }
  }

  // move item to archive list
  void _moveToArchive(Map<String, dynamic> item) {
    widget.todo.archive ??= <Map<String, dynamic>>[];
    // remove from checklist
    final list = widget.todo.checklist ?? [];
    list.remove(item);
    // clear certain transient fields
    item['archivedAt'] = DateTime.now().millisecondsSinceEpoch;
    item['isChecked'] = false; // archived items considered stored
    // keep imagePath, memo, due, subtasks, group etc.
    widget.todo.archive!.insert(0, item);
  }

  // restore from archive back to checklist (keeps imagePath and fields)
  void _restoreFromArchive(int index) {
    final archive = widget.todo.archive ?? [];
    if (index < 0 || index >= archive.length) return;
    final item = archive.removeAt(index);
    widget.todo.checklist ??= [];
    widget.todo.checklist!.insert(0, item);
  }

  // permanently delete from archive
  void _deleteFromArchive(int index) {
    final archive = widget.todo.archive ?? [];
    if (index < 0 || index >= archive.length) return;
    final item = archive.removeAt(index);
    // optionally delete attached image file? we will not delete file from storage automatically.
  }

  // manual archive action (user can archive immediately)
  void _archiveItemManually(Map<String, dynamic> item) {
    setState(() {
      _moveToArchive(item);
      _saveAndRefresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final todo = widget.todo;
    final checklist = todo.checklist ?? [];

    for (var item in checklist) {
      item['group'] = item['group'] ?? '기본';
      item['priority'] = item['priority'] ?? 1;
      item['isChecked'] = item['isChecked'] == true;
      item['pinned'] = item['pinned'] == true;
      item['subtasks'] = (item['subtasks'] is List) ? item['subtasks'] : <Map<String, dynamic>>[];
      item['memo'] = item['memo'] ?? '';
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
      final items = grouped[g]!..removeWhere((e) => hideCompleted && e['isChecked'] == true);
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
          IconButton(
            icon: const Icon(Icons.archive_outlined),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => ArchiveScreen(todo: widget.todo, onRestore: (idx) {
                setState(() {});
                _saveAndRefresh();
              }, onDelete: (idx) {
                setState(() {});
                _saveAndRefresh();
              })));
            },
            tooltip: '보관함',
          ),
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
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          TextField(controller: addCtrl, decoration: const InputDecoration(hintText: '새 그룹명')),
                          const SizedBox(height: 8),
                          ElevatedButton(onPressed: () { _addGroup(addCtrl.text); Navigator.of(ctx).pop(); }, child: const Text('추가')),
                          const Divider(),
                          Flexible(child: ListView.builder(shrinkWrap: true, itemCount: _groups.length, itemBuilder: (c, i) {
                            final g = _groups[i];
                            return ListTile(
                              leading: Icon(_groupSettings[g]?.icon, color: _groupSettings[g]?.color),
                              title: Text(g),
                              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                                IconButton(icon: const Icon(Icons.edit), onPressed: () { Navigator.of(ctx).pop(); _editGroupSettings(g); }),
                                if (g != '기본') IconButton(icon: const Icon(Icons.delete_outline), onPressed: () { _deleteGroup(g); Navigator.of(ctx).pop(); }),
                              ]),
                            );
                          })),
                        ]),
                      ),
                    );
                  },
                );
              } else if (v == 'checkAll') {
                setState(() { for (var it in checklist) {
                  if (it['isChecked'] != true) {
                    it['isChecked'] = true;
                    it['completedAt'] = DateTime.now().millisecondsSinceEpoch;
                  }
                }});
                _saveAndRefresh();
              } else if (v == 'uncheckAll') {
                setState(() { for (var it in checklist) {
                  it['isChecked'] = false;
                  it['completedAt'] = null;
                }});
                _saveAndRefresh();
              }
            },
          ),
        ],
      ),
      body: Column(children: [
        Padding(padding: const EdgeInsets.all(16), child: LinearProgressIndicator(value: progress, minHeight: 8, backgroundColor: Colors.grey[300], color: Colors.blueAccent)),
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
              final gs = _groupSettings[groupName] ?? GroupSettings(color: Colors.blue, icon: Icons.label);
              final items = visibleItemsByGroup[groupName] ?? [];
              final filteredItems = items.where((it) {
                final title = (it['title'] ?? '') as String;
                if (searchQuery.isNotEmpty && !title.toLowerCase().contains(searchQuery.toLowerCase())) return false;
                return true;
              }).toList();

              return DragTarget<Map<String, dynamic>>(
                onWillAccept: (data) => data != null && (data['group'] as String?) != groupName,
                onAccept: (data) {
                  _moveItemToGroup(data, groupName);
                },
                builder: (context, candidate, rejected) {
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
                          Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Row(children: [
                            TextButton.icon(onPressed: () => _editGroupSettings(groupName), icon: const Icon(Icons.settings), label: const Text('그룹 설정')),
                            const Spacer(),
                            IconButton(icon: const Icon(Icons.add), onPressed: () { _showAddItemToGroup(groupName); }),
                          ])),
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
                              final imagePath = item['imagePath'] as String?;
                              final subtasks = (item['subtasks'] is List) ? (item['subtasks'] as List) : [];

                              Color priorityColor = pr == 2 ? Colors.red : pr == 1 ? Colors.blue : Colors.grey;

                              return LongPressDraggable<Map<String, dynamic>>(
                                data: item,
                                feedback: Material(
                                  color: Colors.transparent,
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width - 80),
                                    child: Card(
                                      elevation: 6,
                                      child: Padding(padding: const EdgeInsets.all(8), child: Text(item['title'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis)),
                                    ),
                                  ),
                                ),
                                child: Dismissible(
                                  key: ValueKey(item.hashCode ^ idx),
                                  background: Container(color: Colors.green, alignment: Alignment.centerLeft, padding: const EdgeInsets.only(left: 20), child: const Icon(Icons.check, color: Colors.white)),
                                  secondaryBackground: Container(color: Colors.red, alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 16), child: const Icon(Icons.delete, color: Colors.white)),
                                  confirmDismiss: (direction) async {
                                    if (direction == DismissDirection.startToEnd) {
                                      setState(() {
                                        item['isChecked'] = !(item['isChecked'] == true);
                                        if (item['isChecked'] == true) item['completedAt'] = DateTime.now().millisecondsSinceEpoch;
                                        else item['completedAt'] = null;
                                      });
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
                                      onTap: () {
                                        setState(() {
                                          final prev = item['isChecked'] == true;
                                          item['isChecked'] = !prev;
                                          if (item['isChecked'] == true) item['completedAt'] = DateTime.now().millisecondsSinceEpoch;
                                          else item['completedAt'] = null;
                                        });
                                        _saveAndRefresh();
                                      },
                                      child: ScaleTransition(
                                        scale: Tween<double>(begin: 1.0, end: 1.15).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut)),
                                        child: CircleAvatar(backgroundColor: isChecked ? Colors.green : Colors.transparent, child: isChecked ? const Icon(Icons.check, color: Colors.white) : const Icon(Icons.circle_outlined, color: Colors.grey)),
                                      ),
                                    ),
                                    title: Text(item['title'] ?? '', style: TextStyle(decoration: isChecked ? TextDecoration.lineThrough : TextDecoration.none, color: isChecked ? Colors.grey : Colors.black)),
                                    subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      if (due != null) Text(_formatDueText(due), style: TextStyle(color: DateTime.fromMillisecondsSinceEpoch(due).isBefore(DateTime.now()) ? Colors.red : Colors.grey[700])),
                                      if (imagePath != null)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 6),
                                          child: GestureDetector(
                                            onTap: () {
                                              if (imagePath != null) {
                                                showDialog(context: context, builder: (_) {
                                                  return Dialog(child: Image.file(File(imagePath)));
                                                });
                                              }
                                            },
                                            child: ConstrainedBox(
                                              constraints: const BoxConstraints(maxHeight: 120, maxWidth: 120),
                                              child: Image.file(File(imagePath), fit: BoxFit.cover),
                                            ),
                                          ),
                                        ),
                                      if (subtasks.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 6),
                                          child: Wrap(
                                            spacing: 6,
                                            runSpacing: 6,
                                            children: subtasks.map<Widget>((st) {
                                              final checked = st['isChecked'] == true;
                                              return InkWell(
                                                onTap: () { setState(() => st['isChecked'] = !(st['isChecked'] == true)); _saveAndRefresh(); },
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                                  decoration: BoxDecoration(color: checked ? Colors.black12 : Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                                                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                                                    Icon(checked ? Icons.check_box : Icons.check_box_outline_blank, size: 16, color: checked ? Colors.green : Colors.grey),
                                                    const SizedBox(width: 6),
                                                    Text(st['title'] ?? '', style: TextStyle(decoration: checked ? TextDecoration.lineThrough : TextDecoration.none)),
                                                  ]),
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                        ),
                                    ]),
                                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                                      IconButton(icon: Icon(Icons.camera_alt, color: Colors.grey), onPressed: () => _pickImageForItem(item, ImageSource.camera)),
                                      IconButton(icon: Icon(Icons.photo, color: Colors.grey), onPressed: () => _pickImageForItem(item, ImageSource.gallery)),
                                      IconButton(icon: Icon(Icons.flag, color: priorityColor), onPressed: () => _showPrioritySelector(item)),
                                      IconButton(icon: Icon(reminder != null ? Icons.notifications_active : Icons.notifications_none, color: reminder != null ? Colors.orange : Colors.grey), onPressed: () => _toggleReminder(item)),
                                      PopupMenuButton<String>(
                                        onSelected: (val) {
                                          if (val == 'archive') {
                                            _archiveItemManually(item);
                                          } else if (val == 'attach_camera') {
                                            _pickImageForItem(item, ImageSource.camera);
                                          } else if (val == 'attach_gallery') {
                                            _pickImageForItem(item, ImageSource.gallery);
                                          }
                                        },
                                        itemBuilder: (_) => [
                                          const PopupMenuItem(value: 'archive', child: Text('보관')),
                                          const PopupMenuItem(value: 'attach_camera', child: Text('카메라로 사진첨부')),
                                          const PopupMenuItem(value: 'attach_gallery', child: Text('갤러리에서 첨부')),
                                        ],
                                      ),
                                    ]),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
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
            widget.todo.checklist!.add({'title': t, 'isChecked': false, 'memo': '', 'due': null, 'reminder': null, 'reminderRepeat': 'none', 'group': groupName, 'priority': 1, 'pinned': false, 'subtasks': [], 'imagePath': null, 'completedAt': null});
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
      widget.todo.checklist!.add({'title': text, 'isChecked': false, 'memo': '', 'due': null, 'reminder': null, 'reminderRepeat': 'none', 'group': _selectedGroup, 'priority': 1, 'pinned': false, 'subtasks': [], 'imagePath': null, 'completedAt': null});
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
          Expanded(child: Text(due == null ? '마감일 없음' : '마감일: ${DateFormat('yyyy-MM-dd').format(due!)}')),
          TextButton(child: const Text('날짜 선택'), onPressed: () async {
            final picked = await showDatePicker(context: context, initialDate: due ?? DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100));
            if (picked != null) setState(() => due = picked);
          }),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          ElevatedButton.icon(onPressed: () => _pickImageForItem(item, ImageSource.camera), icon: const Icon(Icons.camera_alt), label: const Text('카메라')),
          const SizedBox(width: 8),
          ElevatedButton.icon(onPressed: () => _pickImageForItem(item, ImageSource.gallery), icon: const Icon(Icons.photo), label: const Text('갤러리')),
          const Spacer(),
          TextButton(onPressed: () {
            setState(() {
              item['imagePath'] = null;
            });
            _saveAndRefresh();
          }, child: const Text('이미지 제거')),
        ]),
        const SizedBox(height: 12),
        ElevatedButton(child: const Text('저장'), onPressed: () { setState(() { item['title'] = title.text.trim(); item['memo'] = memo.text.trim(); item['due'] = due?.millisecondsSinceEpoch; }); _saveAndRefresh(); Navigator.pop(context); }),
        const SizedBox(height: 12),
      ]));
    });
  }
}

class ArchiveScreen extends StatefulWidget {
  final Todo todo;
  final void Function(int index)? onRestore;
  final void Function(int index)? onDelete;
  const ArchiveScreen({super.key, required this.todo, this.onRestore, this.onDelete});

  @override
  State<ArchiveScreen> createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends State<ArchiveScreen> {
  @override
  void initState() {
    super.initState();
    widget.todo.archive ??= <Map<String, dynamic>>[];
  }

  void _restore(int index) {
    final archive = widget.todo.archive ?? [];
    if (index < 0 || index >= archive.length) return;
    final item = archive.removeAt(index);
    widget.todo.checklist ??= [];
    widget.todo.checklist!.insert(0, item);
    widget.todo.save();
    context.read<ListViewModel>().refresh();
    widget.onRestore?.call(index);
    setState(() {});
  }

  void _delete(int index) {
    final archive = widget.todo.archive ?? [];
    if (index < 0 || index >= archive.length) return;
    final removed = archive.removeAt(index);
    widget.todo.save();
    context.read<ListViewModel>().refresh();
    widget.onDelete?.call(index);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final archive = widget.todo.archive ?? [];
    return Scaffold(
      appBar: AppBar(title: const Text('보관함')),
      body: archive.isEmpty
          ? const Center(child: Text('보관된 항목이 없습니다'))
          : ListView.builder(
        itemCount: archive.length,
        itemBuilder: (c, i) {
          final item = archive[i];
          final title = item['title'] ?? '';
          final memo = item['memo'] ?? '';
          final imagePath = item['imagePath'] as String?;
          final archivedAt = item['archivedAt'] != null ? DateTime.fromMillisecondsSinceEpoch(item['archivedAt']) : null;
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: ListTile(
              onTap: () {
                // show detail
                showModalBottomSheet(context: context, builder: (_) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      if (memo.isNotEmpty) Text(memo),
                      if (imagePath != null) ...[
                        const SizedBox(height: 12),
                        Image.file(File(imagePath)),
                      ],
                      const SizedBox(height: 12),
                      Text(archivedAt != null ? '보관됨: ${DateFormat('yyyy-MM-dd HH:mm').format(archivedAt)}' : ''),
                      const SizedBox(height: 12),
                      Row(children: [
                        ElevatedButton.icon(onPressed: () {
                          Navigator.pop(context);
                          _restore(i);
                        }, icon: const Icon(Icons.unarchive), label: const Text('복원')),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Colors.red), onPressed: () {
                          Navigator.pop(context);
                          _delete(i);
                        }, icon: const Icon(Icons.delete), label: const Text('삭제')),
                      ]),
                    ]),
                  );
                });
              },
              title: Text(title),
              subtitle: archivedAt != null ? Text('보관: ${DateFormat('yyyy-MM-dd').format(archivedAt)}') : null,
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(icon: const Icon(Icons.unarchive), onPressed: () => _restore(i)),
                IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _delete(i)),
              ]),
            ),
          );
        },
      ),
    );
  }
}

class GroupSettings {
  Color color;
  IconData icon;
  GroupSettings({required this.color, required this.icon});
}
