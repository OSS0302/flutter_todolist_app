import 'package:flutter/material.dart';
import 'package:todolist/main.dart';
import 'package:todolist/model/todo.dart';

class AddScreen extends StatefulWidget {
  const AddScreen({super.key});

  @override
  State<AddScreen> createState() => _AddScreenState();
}

class _AddScreenState extends State<AddScreen> {
  final _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _saveTodo() {
    if (_textController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('할 일을 입력해주세요!')),
      );
      return;
    }

    todos.add(Todo(
      title: _textController.text,
      dateTime: DateTime.now().millisecondsSinceEpoch,
    ));

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('할 일이 저장되었습니다!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('할 일 추가하기'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 텍스트 입력 필드
            TextFormField(
              controller: _textController,
              decoration: InputDecoration(
                labelText: '할 일을 입력하세요',
                labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                hintText: '예: 운동하기, 장보기...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
            const SizedBox(height: 20),
            // 미리보기 카드
            if (_textController.text.trim().isNotEmpty)
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: const Icon(Icons.note_add, color: Colors.blue),
                  title: Text(_textController.text),
                  subtitle: Text(
                    '작성 시간: ${DateTime.now().toLocal()}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
            const Spacer(),
            // 저장 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saveTodo,
                icon: const Icon(Icons.save),
                label: const Text('저장하기'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16),
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
