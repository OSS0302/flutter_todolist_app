import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:todolist/main.dart';
import 'package:todolist/model/todo.dart';

class AddScreen extends StatefulWidget {
  const AddScreen({super.key});

  @override
  State<AddScreen> createState() => _AddScreenState();
}

class _AddScreenState extends State<AddScreen> {
  final _textController = TextEditingController();
  DateTime? _selectedDueDate;
  String? _selectedPriority;

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
      title: _textController.text.trim(),
      dateTime: DateTime.now().millisecondsSinceEpoch,
      dueDate: _selectedDueDate,
      priority: _selectedPriority,
    ));

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('할 일이 저장되었습니다!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.tealAccent,
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: Colors.black87,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDueDate = picked);
    }
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
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1A2980), Color(0xFF26D0CE)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(color: Colors.black.withOpacity(0.2)),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // 할일 입력
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
                  // 우선순위 선택
                  GlassCard(
                    child: DropdownButtonFormField<String>(
                      value: _selectedPriority,
                      dropdownColor: Colors.black87,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: '우선순위 선택',
                        labelStyle: TextStyle(color: Colors.white70),
                        border: InputBorder.none,
                      ),
                      items: const [
                        DropdownMenuItem(value: 'high', child: Text('🔥 높음')),
                        DropdownMenuItem(value: 'medium', child: Text('🌟 보통')),
                        DropdownMenuItem(value: 'low', child: Text('🍃 낮음')),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedPriority = value);
                      },
                    ),
                  ),
                  // 마감일 선택
                  GlassCard(
                    child: ListTile(
                      title: const Text('마감일 선택', style: TextStyle(color: Colors.white70)),
                      subtitle: Text(
                        _selectedDueDate != null
                            ? DateFormat('yyyy-MM-dd').format(_selectedDueDate!)
                            : '선택 안 함',
                        style: const TextStyle(color: Colors.white),
                      ),
                      trailing: const Icon(Icons.calendar_today, color: Colors.white70),
                      onTap: _pickDueDate,
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

// 재사용 카드 위젯
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
        color: color ?? Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: child,
    );
  }
}
