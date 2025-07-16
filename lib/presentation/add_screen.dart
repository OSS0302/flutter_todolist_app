import 'dart:ui';
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
        const SnackBar(
          content: Text('할 일을 입력해주세요!'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    todos.add(Todo(
      title: _textController.text,
      dateTime: DateTime.now().millisecondsSinceEpoch,
    ));

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('할 일이 저장되었습니다!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('📝 할 일 추가하기',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          // 배경 그라디언트
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1A2980), Color(0xFF26D0CE)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          // 블러 효과
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(color: Colors.black.withOpacity(0.2)),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // 입력 필드
                  GlassCard(
                    child: TextFormField(
                      controller: _textController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: '할 일을 입력하세요',
                        labelStyle: const TextStyle(color: Colors.white70),
                        hintText: '예: 운동하기, 장보기...',
                        hintStyle: const TextStyle(color: Colors.white38),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // 미리보기 카드
                  if (_textController.text.trim().isNotEmpty)
                    GlassCard(
                      color: Colors.white.withOpacity(0.05),
                      child: ListTile(
                        leading: const Icon(Icons.note_alt, color: Colors.lightBlueAccent),
                        title: Text(
                          _textController.text,
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          '🕒 ${DateTime.now().toLocal().toString().substring(0, 16)}',
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
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
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        backgroundColor: Colors.lightGreenAccent.withOpacity(0.85),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 공통 글래스 카드 위젯
class GlassCard extends StatelessWidget {
  final Widget child;
  final Color? color;

  const GlassCard({super.key, required this.child, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color ?? Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: child,
    );
  }
}
