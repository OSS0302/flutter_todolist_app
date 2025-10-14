import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:todolist/main.dart';
import 'package:todolist/model/todo.dart';

class AddViewModel extends ChangeNotifier {
  /// 입력 컨트롤러
  final textController = TextEditingController();
  final detailController = TextEditingController();
  final tagController = TextEditingController();
  final checklistController = TextEditingController(); // ✅ 체크리스트 입력용

  /// 상태
  DateTime? selectedDueDate;
  String? selectedPriority;
  TimeOfDay? reminderTime;
  bool isLoading = false;
  bool isPressed = false;

  /// 태그 리스트
  final List<String> _tags = [];
  List<String> get tags => List.unmodifiable(_tags);

  /// 체크리스트
  final List<Map<String, dynamic>> _checklist = [];
  List<Map<String, dynamic>> get checklist => List.unmodifiable(_checklist);

  /// 색상 선택
  int selectedColor = Colors.blue.value;

  /// ✅ 유효성 검사
  bool get isInputValid => textController.text.trim().isNotEmpty;

  /// ✅ 마감일 포맷
  String get formattedDueDate {
    if (selectedDueDate == null) return '선택 안 함';
    return DateFormat('yyyy-MM-dd').format(selectedDueDate!);
  }

  /// ✅ 알림 시간 포맷
  String get formattedReminderTime {
    if (reminderTime == null) return '선택 안 함';
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, reminderTime!.hour, reminderTime!.minute);
    return DateFormat('HH:mm').format(dt);
  }

  /// 📌 마감일 설정
  void setDueDate(DateTime date) {
    selectedDueDate = date;
    notifyListeners();
  }

  /// 📌 알림 시간 설정
  void setReminderTime(TimeOfDay time) {
    reminderTime = time;
    notifyListeners();
  }

  /// 📌 우선순위 설정
  void setPriority(String? priority) {
    selectedPriority = priority;
    notifyListeners();
  }

  /// 📌 색상 설정
  void setColor(int color) {
    selectedColor = color;
    notifyListeners();
  }

  /// 📌 체크리스트 추가
  void addChecklist() {
    final text = checklistController.text.trim();
    if (text.isEmpty) return;
    _checklist.add({
      "id": DateTime.now().millisecondsSinceEpoch,
      "text": text,
      "done": false,
    });
    checklistController.clear();
    notifyListeners();
  }

  /// 📌 체크리스트 토글
  void toggleChecklist(int id, bool done) {
    final idx = _checklist.indexWhere((e) => e["id"] == id);
    if (idx != -1) {
      _checklist[idx]["done"] = done;
      notifyListeners();
    }
  }

  /// 📌 오늘 마감 여부
  bool isDueToday() {
    if (selectedDueDate == null) return false;
    return DateUtils.isSameDay(selectedDueDate, DateTime.now());
  }

  /// 📌 마감일 초과 여부
  bool isOverdue() {
    if (selectedDueDate == null) return false;
    final now = DateTime.now();
    return selectedDueDate!.isBefore(DateTime(now.year, now.month, now.day));
  }

  /// 📌 버튼 눌림 상태 업데이트
  void setPressed(bool pressed) {
    isPressed = pressed;
    notifyListeners();
  }

  /// 📌 태그 추가
  void addTag() {
    final tag = tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      _tags.add(tag);
      tagController.clear();
      notifyListeners();
    }
  }

  /// 📌 태그 삭제
  void removeTag(String tag) {
    _tags.remove(tag);
    notifyListeners();
  }

  /// 📌 할 일 저장
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
      // 필요하다면 색상, 태그, 체크리스트도 Todo 모델에 추가 가능
    ));

    isLoading = false;
    notifyListeners();
  }

  /// 📌 dispose
  void disposeViewModel() {
    textController.dispose();
    detailController.dispose();
    tagController.dispose();
    checklistController.dispose();
  }
}
