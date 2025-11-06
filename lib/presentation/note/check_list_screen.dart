import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todolist/model/todo.dart';
import 'package:todolist/presentation/list_view_model.dart';

class ChecklistScreen extends StatefulWidget {
  final Todo todo;
  const ChecklistScreen({super.key, required this.todo});

  @override
  State<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends State<ChecklistScreen> {
  final controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final todo = widget.todo;

    return Scaffold(
      appBar: AppBar(title: const Text("체크리스트 편집")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: todo.checklist!.map((item) {
                  return CheckboxListTile(
                    value: item['isChecked'],
                    title: Text(item['title']),
                    onChanged: (v) {
                      setState(() => item['isChecked'] = v);
                      todo.save();
                      context.read<ListViewModel>().refresh();
                    },
                  );
                }).toList(),
              ),
            ),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: const InputDecoration(labelText: "체크리스트 추가"),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    if (controller.text.trim().isEmpty) return;

                    setState(() {
                      todo.checklist!.add({
                        "title": controller.text.trim(),
                        "isChecked": false,
                      });
                      controller.clear();
                    });

                    todo.save();
                    context.read<ListViewModel>().refresh();
                  },
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
