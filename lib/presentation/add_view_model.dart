import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:todolist/model/todo.dart';
import 'package:todolist/main.dart';

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

  void saveTodo() {
    final trimmed = textController.text.trim();
    if (trimmed.isEmpty) return;

    todos.add(Todo(
      title: trimmed,
      dateTime: DateTime.now().millisecondsSinceEpoch,
      dueDate: selectedDueDate,
      priority: selectedPriority,
    ));
  }

  void disposeViewModel() {
    textController.dispose();
  }
}
