import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:todolist/main.dart';
import 'package:todolist/model/todo.dart';

class AddViewModel extends ChangeNotifier {
  final textController = TextEditingController();
  DateTime? selectedDueDate;
  String? selectedPriority;
  bool isLoading = false;

  /// ✅ 3D Motion 버튼 눌림 상태
  bool isPressed = false;

  /// 할 일 입력 유효성
  bool get isInputValid => textController.text.trim().isNotEmpty;

  /// 마감일 포맷
  String get formattedDueDate {
    if (selectedDueDate == null) return '선택 안 함';
    return DateFormat('yyyy-MM-dd').format(selectedDueDate!);
  }

  /// 마감일 설정
  void setDueDate(DateTime date) {
    selectedDueDate = date;
    notifyListeners();
  }

  /// 우선순위 설정
  void setPriority(String? priority) {
    selectedPriority = priority;
    notifyListeners();
  }

  /// 오늘 마감 여부
  bool isDueToday() {
    if (selectedDueDate == null) return false;
    return DateUtils.isSameDay(selectedDueDate, DateTime.now());
  }

  /// 마감일 초과 여부
  bool isOverdue() {
    if (selectedDueDate == null) return false;
    final now = DateTime.now();
    return selectedDueDate!.isBefore(DateTime(now.year, now.month, now.day));
  }

  /// ✅ 버튼 눌림 상태 업데이트 (3D Motion 효과용)
  void setPressed(bool pressed) {
    isPressed = pressed;
    notifyListeners();
  }

  /// 할 일 저장
  Future<void> saveTodo() async {
    final trimmed = textController.text.trim();
    if (trimmed.isEmpty) return;

    isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1)); // 서버 연동 시뮬레이션

    todos.add(Todo(
      title: trimmed,
      dateTime: DateTime.now().millisecondsSinceEpoch,
      dueDate: selectedDueDate,
      priority: selectedPriority,
    ));

    isLoading = false;
    notifyListeners();
  }

  /// 뷰모델 dispose
  void disposeViewModel() {
    textController.dispose();
  }
}
