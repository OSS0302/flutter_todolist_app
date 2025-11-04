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
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final todo = widget.todo;

    return Scaffold(
      appBar: AppBar(title: const Text("체크리스트 편집")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            /// 체크리스트 목록
            Expanded(
              child: ListView(
                children: todo.checklist!.map((item) {
                  return CheckboxListTile(
                    value: item['isChecked'],
                    title: Text(item['title']),
                    onChanged: (value) {
                      setState(() => item['isChecked'] = value);
                      todo.save();
                      context.read<ListViewModel>().refresh();
                    },
                  );
                }).toList(),
              ),
            ),

            /// 새로운 항목 추가
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration:
                    const InputDecoration(labelText: "체크리스트 추가"),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    if (_controller.text.trim().isEmpty) return;

                    setState(() {
                      todo.checklist?.add({
                        "title": _controller.text.trim(),
                        "isChecked": false,
                      });
                      _controller.clear();
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
