import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:todolist/model/todo.dart';
import 'package:todolist/presentation/list_view_model.dart';

class AddScreen extends StatefulWidget {
  final int? todoId;
  final String? todoTitle;

  const AddScreen({super.key, this.todoId, this.todoTitle});

  @override
  State<AddScreen> createState() => _AddScreenState();
}

class _AddScreenState extends State<AddScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _tagController = TextEditingController();

  DateTime? _selectedDate;
  String? _selectedPriority;
  Color _selectedColor = const Color(0xFF4FACFE);
  List<String> _tags = [];

  @override
  void initState() {
    super.initState();
    if (widget.todoTitle != null) {
      _titleController.text = widget.todoTitle!;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  /// 📅 날짜 선택 다이얼로그
  Future<void> _selectDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  /// 🏷️ 태그 추가
  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isEmpty) return;

    if (_tags.any((t) => t.toLowerCase() == tag.toLowerCase())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("이미 존재하는 태그입니다.")),
      );
      return;
    }

    setState(() {
      _tags.add(tag);
      _tagController.clear();
    });
  }

  /// 💾 할 일 저장
  Future<void> _saveTodo() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    final newTodo = Todo(
      title: title,
      dateTime: DateTime.now().millisecondsSinceEpoch,
      dueDate: _selectedDate,
      priority: _selectedPriority,
      color: _selectedColor.value,
      tags: _tags,
      checklist: [],
    );

    await context.read<ListViewModel>().addTodo(newTodo);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('할 일이 추가되었습니다!')),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("할 일 추가", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          _buildBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      border: Border.all(color: Colors.white24, width: 1),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTitleInput(),
                        const SizedBox(height: 20),
                        _buildPrioritySelector(),
                        const SizedBox(height: 20),
                        _buildDateSelector(),
                        const SizedBox(height: 20),
                        _buildColorPicker(),
                        const SizedBox(height: 20),
                        _buildTagInput(),
                        const SizedBox(height: 20),
                        _buildSaveButton(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 🌈 배경
  Widget _buildBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF141E30), Color(0xFF243B55)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }

  /// 📝 제목 입력
  Widget _buildTitleInput() {
    return TextField(
      controller: _titleController,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: '할 일 제목',
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none),
      ),
    );
  }

  /// ⚡ 우선순위 선택
  Widget _buildPrioritySelector() {
    final priorities = ['낮음', '보통', '높음'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("우선순위",
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14)),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: priorities.map((p) {
            final isSelected = _selectedPriority == p;
            return ChoiceChip(
              label: Text(p),
              selected: isSelected,
              selectedColor: Colors.blueAccent,
              backgroundColor: Colors.white12,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              onSelected: (_) => setState(() => _selectedPriority = p),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// 📆 마감일 선택
  Widget _buildDateSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          _selectedDate == null
              ? "마감일 미설정"
              : "마감일: ${_selectedDate!.year}.${_selectedDate!.month}.${_selectedDate!.day}",
          style: const TextStyle(color: Colors.white70),
        ),
        ElevatedButton.icon(
          onPressed: _selectDueDate,
          icon: const Icon(Icons.calendar_today, size: 18),
          label: const Text("선택"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        )
      ],
    );
  }

  /// 🎨 색상 선택
  Widget _buildColorPicker() {
    final colors = [
      Colors.blueAccent,
      Colors.pinkAccent,
      Colors.amber,
      Colors.greenAccent,
      Colors.purpleAccent
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("색상 선택",
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14)),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: colors.map((c) {
            final isSelected = _selectedColor == c;
            return GestureDetector(
              onTap: () => setState(() => _selectedColor = c),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: isSelected ? 40 : 34,
                height: isSelected ? 40 : 34,
                decoration: BoxDecoration(
                  color: c,
                  shape: BoxShape.circle,
                  border:
                  isSelected ? Border.all(color: Colors.white, width: 3) : null,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// 🏷️ 태그 추가
  Widget _buildTagInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("태그 추가",
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _tagController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "예: 업무, 공부",
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon:
              const Icon(Icons.add_circle, color: Colors.lightBlueAccent),
              onPressed: _addTag,
            ),
          ],
        ),
        Wrap(
          spacing: 6,
          children: _tags
              .map((t) => Chip(
            label: Text(t),
            backgroundColor: Colors.white10,
            labelStyle: const TextStyle(color: Colors.white70),
            deleteIcon:
            const Icon(Icons.close, color: Colors.white54),
            onDeleted: () =>
                setState(() => _tags.removeWhere((tag) => tag == t)),
          ))
              .toList(),
        ),
      ],
    );
  }

  /// ✅ 저장 버튼
  Widget _buildSaveButton() {
    return Center(
      child: ElevatedButton.icon(
        onPressed:
        _titleController.text.trim().isEmpty ? null : _saveTodo,
        icon: const Icon(Icons.check),
        label: const Text("저장하기"),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.lightBlueAccent,
          padding:
          const EdgeInsets.symmetric(horizontal: 60, vertical: 14),
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          textStyle:
          const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
