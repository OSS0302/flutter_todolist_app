import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:todolist/model/todo.dart';

enum FilterStatus { all, done, notDone }

class ListViewModel extends ChangeNotifier {
  final Box<Todo> _todoBox;

  ListViewModel(this._todoBox) {
    fetchTodos();
  }

  bool _isLoading = false;
  String _searchKeyword = '';
  bool _showOnlyFavorites = false;
  FilterStatus _filterStatus = FilterStatus.all;

  List<Todo> _todos = [];

  bool get isLoading => _isLoading;
  List<Todo> get todos => _todos;
  String get searchKeyword => _searchKeyword;
  bool get showOnlyFavorites => _showOnlyFavorites;
  FilterStatus get filterStatus => _filterStatus;

  // ✅ 필터링된 목록 반환
  List<Todo> get filteredTodos {
    final filtered = _todos.where((todo) {
      final matchKeyword = todo.title.contains(_searchKeyword);
      final matchFavorite = !_showOnlyFavorites || todo.isFavorite;
      final matchStatus = _filterStatus == FilterStatus.all ||
          (_filterStatus == FilterStatus.done && todo.isDone) ||
          (_filterStatus == FilterStatus.notDone && !todo.isDone);
      return matchKeyword && matchFavorite && matchStatus;
    }).toList();

    // 정렬 기준: 즐겨찾기 → 미완료 → 마감일순
    filtered.sort((a, b) {
      if (a.isFavorite != b.isFavorite) {
        return b.isFavorite ? 1 : -1;
      }
      if (a.isDone != b.isDone) {
        return a.isDone ? 1 : -1;
      }
      return (a.dueDate ?? DateTime.now())
          .compareTo(b.dueDate ?? DateTime.now());
    });

    return filtered;
  }

  double get progress {
    final total = filteredTodos.length;
    if (total == 0) return 0;
    final completed = filteredTodos.where((t) => t.isDone).length;
    return completed / total;
  }

  // ✅ Hive에서 할 일 불러오기
  Future<void> fetchTodos() async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 200));
    _todos = _todoBox.values.toList();

    _isLoading = false;
    notifyListeners();
  }

  void setSearchKeyword(String keyword) {
    _searchKeyword = keyword;
    notifyListeners();
  }

  void toggleFavoriteFilter() {
    _showOnlyFavorites = !_showOnlyFavorites;
    notifyListeners();
  }

  void setFilterStatus(FilterStatus status) {
    _filterStatus = status;
    notifyListeners();
  }

  // ✅ 완료 토글
  Future<void> toggleDone(Todo todo) async {
    todo.isDone = !todo.isDone;
    await todo.save();
    notifyListeners();
  }

  // ✅ 즐겨찾기 토글
  Future<void> toggleFavorite(Todo todo) async {
    todo.isFavorite = !todo.isFavorite;
    await todo.save();
    notifyListeners();
  }

  // ✅ 삭제
  Future<void> deleteTodo(Todo todo) async {
    await todo.delete();
    _todos.removeWhere((t) => t.key == todo.key);
    notifyListeners();
  }

  Future<void> refresh() async {
    await fetchTodos();
  }

  Future<void> loadTodos() async {
    await fetchTodos();
  }

  // ✅ 전체 삭제
  Future<void> clearAllTodos() async {
    await _todoBox.clear();  // Hive Box 전체 삭제
    _todos.clear();          // 메모리에서도 삭제
    notifyListeners();       // UI 갱신
  }

  // ✅ 새 할 일 추가 기능 (🔥 AddScreen과 연동됨)
  Future<void> addTodo(Todo todo) async {
    // Hive에 추가
    await _todoBox.add(todo);

    // 메모리에도 반영
    _todos = _todoBox.values.toList();

    notifyListeners();
  }

  // ✅ 기존 할 일 수정 (optional)
  Future<void> updateTodo(Todo todo) async {
    await todo.save();
    notifyListeners();
  }
}
