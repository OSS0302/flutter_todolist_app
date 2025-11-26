import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todolist/model/todo.dart';
import 'package:todolist/presentation/list_view_model.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';

class ChecklistScreen extends StatefulWidget {
  final Todo todo;
  const ChecklistScreen({super.key, required this.todo});

  @override
  State<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends State<ChecklistScreen> {
  final controller = TextEditingController();
  bool hideCompleted = false;

  @override
  Widget build(BuildContext context) {
    final todo = widget.todo;
    final checklist = todo.checklist ?? [];

    // 정렬 적용
    checklist.sort((a, b) {
      final dueA = a['due'] as int?;
      final dueB = b['due'] as int?;
      if (dueA != null && dueB != null) return dueA.compareTo(dueB);
      if (dueA != null) return -1;
      if (dueB != null) return 1;

      final checkedA = a['isChecked'] == true;
      final checkedB = b['isChecked'] == true;
      return checkedA ? 1 : -1;
    });

    final total = checklist.length;
    final done = checklist.where((e) => e['isChecked'] == true).length;
    final progress = total == 0 ? 0 : done / total;

    final visibleItems = hideCompleted
        ? checklist.where((e) => e['isChecked'] != true).toList()
        : checklist;

    return Scaffold(
      appBar: AppBar(
        title: Text("체크리스트 ($done/$total)"),
        actions: [
          IconButton(
            icon: Icon(hideCompleted ? Icons.visibility_off : Icons.visibility),
            onPressed: () => setState(() => hideCompleted = !hideCompleted),
          ),
        ],
      ),

      body: Column(
        children: [
          // 진행률
          Padding(
            padding: const EdgeInsets.all(16),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              borderRadius: BorderRadius.circular(10),
              backgroundColor: Colors.grey[300],
              color: Colors.blueAccent,
            ),
          ),

          Expanded(
            child: visibleItems.isEmpty
                ? const Center(child: Text("체크리스트가 비어있어요"))
                : ListView.builder(
              itemCount: visibleItems.length,
              itemBuilder: (context, index) {
                final item = visibleItems[index];
                final isChecked = item['isChecked'] == true;
                final memo = item['memo'];
                final due = item['due'] as int?;
                final reminder = item['reminder'] as int?;

                Color dueColor = Colors.transparent;
                if (due != null) {
                  final d = DateTime.fromMillisecondsSinceEpoch(due);
                  final now = DateTime.now();
                  if (d.isBefore(now)) {
                    dueColor = Colors.red;
                  } else if (d.difference(now).inDays <= 1) {
                    dueColor = Colors.orange;
                  } else {
                    dueColor = Colors.blue;
                  }
                }

                return Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Column(
                    children: [
                      ListTile(
                        onLongPress: () => _editItem(item), // 수정 BottomSheet
                        leading: GestureDetector(
                          onTap: () {
                            setState(() => item['isChecked'] = !isChecked);
                            todo.save();
                            context.read<ListViewModel>().refresh();
                          },
                          child: Icon(
                            isChecked
                                ? Icons.check_circle
                                : Icons.circle_outlined,
                            size: 28,
                            color: Colors.blueAccent,
                          ),
                        ),
                        title: Text(
                          item['title'],
                          style: TextStyle(
                            decoration: isChecked
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                            color: isChecked ? Colors.grey : Colors.black,
                            fontSize: 17,
                          ),
                        ),
                        subtitle: due != null
                            ? Text(
                          "마감: ${DateFormat('yyyy-MM-dd').format(DateTime.fromMillisecondsSinceEpoch(due))}",
                          style: TextStyle(color: dueColor),
                        )
                            : null,
                        trailing: IconButton(
                          icon: Icon(
                            reminder != null ? Icons.notifications_active : Icons.notifications_none,
                            color: reminder != null ? Colors.orange : Colors.grey,
                          ),
                          onPressed: () => _toggleReminder(item),
                        ),
                      ),

                      // 메모 표시 (있을 때만)
                      if (memo != null && memo.toString().trim().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
                          child: Text(
                            memo,
                            style: const TextStyle(fontSize: 14, color: Colors.black87),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      labelText: "체크리스트 추가",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    if (controller.text.trim().isEmpty) return;
                    setState(() {
                      checklist.add({
                        "title": controller.text.trim(),
                        "isChecked": false,
                        "memo": "",
                        "due": null,
                        "reminder": null,
                      });
                      controller.clear();
                    });
                    todo.save();
                    context.read<ListViewModel>().refresh();
                  },
                  child: const Text("추가"),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= 수정 BottomSheet ==================
  void _editItem(Map item) {
    final title = TextEditingController(text: item['title']);
    final memo = TextEditingController(text: item['memo']);
    DateTime? due = item['due'] != null
        ? DateTime.fromMillisecondsSinceEpoch(item['due'])
        : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: title, decoration: const InputDecoration(labelText: "제목")),
            const SizedBox(height: 12),
            TextField(controller: memo, maxLines: 4, decoration: const InputDecoration(labelText: "메모")),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: Text(
                    due == null ? "마감일 없음" : "마감일: ${DateFormat('yyyy-MM-dd').format(due)}",
                  ),
                ),
                TextButton(
                  child: const Text("날짜 선택"),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: due ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) setState(() => due = picked);
                  },
                ),
              ],
            ),

            const SizedBox(height: 16),
            ElevatedButton(
              child: const Text("저장"),
              onPressed: () {
                setState(() {
                  item['title'] = title.text.trim();
                  item['memo'] = memo.text.trim();
                  item['due'] = due?.millisecondsSinceEpoch;
                });
                widget.todo.save();
                context.read<ListViewModel>().refresh();
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  // =================== 알림 설정 ===================
  Future<void> _toggleReminder(Map item) async {
    final notifications = FlutterLocalNotificationsPlugin();

    if (item['reminder'] != null) {
      await notifications.cancel(item['reminder']);
      setState(() => item['reminder'] = null);
      widget.todo.save();
      return;
    }

    final dateTime = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    ),
        time = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.now(),
        );

    if (dateTime == null || time == null) return;

    final scheduled =
    DateTime(dateTime.year, dateTime.month, dateTime.day, time.hour, time.minute);

    final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    item['reminder'] = id;

    await notifications.zonedSchedule(
      id,
      "할 일 알림",
      item['title'],
      scheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails("reminder", "Todo Reminder"),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
    );

    widget.todo.save();
    setState(() {});
  }
}
