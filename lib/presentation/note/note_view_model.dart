import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../../model/note.dart';

enum SortType { latest, oldest, title }

class NoteViewModel extends ChangeNotifier {
  final String todoId;
  final String todoTitle;
  final Box<Note> _noteBox;

  List<Note> _allNotes = []; // 원본 전체
  List<Note> _notes = [];    // 필터/정렬된 목록
  bool _isLoading = false;
  String _searchQuery = '';
  SortType _sortType = SortType.latest;

  List<Note> get notes => _notes;
  bool get isLoading => _isLoading;
  SortType get sortType => _sortType;

  NoteViewModel({
    required this.todoId,
    required this.todoTitle,
    required Box<Note> noteBox,
  }) : _noteBox = noteBox {
    loadNotes();
  }

  Future<void> loadNotes() async {
    _isLoading = true;
    notifyListeners();

    _allNotes = _noteBox.values
        .where((note) => note.todoId == todoId)
        .toList();

    _applyFilters();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addNote(
      String content, {
        String title = '',
        int? color,
      }) async {
    final newNote = Note(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      todoId: todoId,
      title: title,
      content: content,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      isPinned: false,
      color: color ?? Colors.orange[50]!.value,
    );

    await _noteBox.put(newNote.id, newNote);
    _allNotes.add(newNote);
    _applyFilters();
    notifyListeners();
  }

  Future<void> updateNote(
      Note note,
      String content, {
        String? title,
        int? color,
        bool? isPinned,
      }) async {
    final updatedNote = note.copyWith(
      title: title ?? note.title,
      content: content,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
      color: color ?? note.color,
      isPinned: isPinned ?? note.isPinned,
    );

    await _noteBox.put(updatedNote.id, updatedNote);
    final index = _allNotes.indexWhere((n) => n.id == note.id);
    if (index != -1) {
      _allNotes[index] = updatedNote;
      _applyFilters();
      notifyListeners();
    }
  }

  Future<void> deleteNote(Note note) async {
    await _noteBox.delete(note.id);
    _allNotes.removeWhere((n) => n.id == note.id);
    _applyFilters();
    notifyListeners();
  }

  void togglePin(Note note) {
    updateNote(note, note.content, isPinned: !note.isPinned);
  }

  void setSortType(SortType type) {
    _sortType = type;
    _applyFilters();
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  void _applyFilters() {
    _notes = _allNotes.where((note) {
      if (_searchQuery.isEmpty) return true;
      return note.title.contains(_searchQuery) ||
          note.content.contains(_searchQuery);
    }).toList();

    // 정렬: 고정 메모 먼저, 그 다음 sortType 적용
    _notes.sort((a, b) {
      if (a.isPinned != b.isPinned) {
        return b.isPinned ? 1 : -1; // true가 먼저 오도록
      }
      switch (_sortType) {
        case SortType.latest:
          return (b.updatedAt ?? b.createdAt)
              .compareTo(a.updatedAt ?? a.createdAt);
        case SortType.oldest:
          return (a.updatedAt ?? a.createdAt)
              .compareTo(b.updatedAt ?? b.createdAt);
        case SortType.title:
          return a.title.compareTo(b.title);
      }
    });
  }
}
