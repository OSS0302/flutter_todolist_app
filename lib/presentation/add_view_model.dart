import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:todolist/main.dart';
import 'package:todolist/model/todo.dart';

class AddViewModel extends ChangeNotifier {
  final textController = TextEditingController();
  DateTime? selectedDueDate;
  String? selectedPriority;
  bool isLoading = false;

  bool get isInputValid => textController.text.trim().isNotEmpty;

  String get formattedDueDate {
    if (selectedDueDate == null) return '선택 안 함';
    return DateFormat('yyyy-MM-dd').format(selectedDueDate!);
  }

  void setDueDate(DateTime date) {
    selectedDueDate = date;
    notifyListeners();
  }

  void setPriority(String? priority) {
    selectedPriority = priority;
    notifyListeners();
  }

  bool isDueToday() {
    if (selectedDueDate == null) return false;
    return DateUtils.isSameDay(selectedDueDate, DateTime.now());
  }

  bool isOverdue() {
    if (selectedDueDate == null) return false;
    final now = DateTime.now();
    return selectedDueDate!.isBefore(DateTime(now.year, now.month, now.day));
  }

  Future<void> saveTodo() async {
    final trimmed = textController.text.trim();
    if (trimmed.isEmpty) return;

    isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1)); // 서버 연동 대기 시뮬레이션

    todos.add(Todo(
      title: trimmed,
      dateTime: DateTime.now().millisecondsSinceEpoch,
      dueDate: selectedDueDate,
      priority: selectedPriority,
    ));

    isLoading = false;
    notifyListeners();
  }

  void disposeViewModel() {
    textController.dispose();
  }
}
