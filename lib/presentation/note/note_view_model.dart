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

  String _selectedTag = "all";

  // 🆕 추가된 필터 상태
  bool _showOnlyPinned = false;
  bool _showArchived = false;

  List<Note> get notes => _notes;
  bool get isLoading => _isLoading;
  SortType get sortType => _sortType;
  String get selectedTag => _selectedTag;
  bool get showOnlyPinned => _showOnlyPinned;
  bool get showArchived => _showArchived;

  NoteViewModel({
    required this.todoId,
    required this.todoTitle,
    required Box<Note> noteBox,
  }) : _noteBox = noteBox {
    loadNotes();
  }

  // 📌 로딩 상태 헬퍼
  Future<void> _withLoading(Future<void> Function() action) async {
    _isLoading = true;
    notifyListeners();
    try {
      await action();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadNotes() async {
    await _withLoading(() async {
      _allNotes = _noteBox.values
          .where((note) => note.todoId == todoId)
          .toList();
      _applyFilters();
    });
  }

  Future<void> addNote(
      String content, {
        String title = '',
        int? color,
        List<String>? tags,
      }) async {
    await _withLoading(() async {
      final newNote = Note(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        todoId: todoId,
        title: title,
        content: content,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        isPinned: false,
        isArchived: false,
        color: color ?? Colors.orange[50]!.value,
        tags: tags ?? [],
      );

      await _noteBox.put(newNote.id, newNote);
      _allNotes.add(newNote);
      _applyFilters();
    });
  }

  Future<void> updateNote(
      Note note,
      String content, {
        String? title,
        int? color,
        bool? isPinned,
        bool? isArchived,
        List<String>? tags,
      }) async {
    await _withLoading(() async {
      final updatedNote = note.copyWith(
        title: title ?? note.title,
        content: content,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
        color: color ?? note.color,
        isPinned: isPinned ?? note.isPinned,
        isArchived: isArchived ?? note.isArchived,
        tags: tags ?? note.tags,
      );

      await _noteBox.put(updatedNote.id, updatedNote);
      final index = _allNotes.indexWhere((n) => n.id == note.id);
      if (index != -1) {
        _allNotes[index] = updatedNote;
        _applyFilters();
      }
    });
  }

  Future<void> deleteNote(Note note) async {
    await _withLoading(() async {
      await _noteBox.delete(note.id);
      _allNotes.removeWhere((n) => n.id == note.id);
      _applyFilters();
    });
  }

  void togglePin(Note note) {
    updateNote(note, note.content, isPinned: !(note.isPinned ?? false));
  }

  void toggleArchive(Note note) {
    updateNote(note, note.content, isArchived: !(note.isArchived ?? false));
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

  void setTagFilter(String tag) {
    _selectedTag = tag;
    _applyFilters();
    notifyListeners();
  }

  List<String> getAllTags() {
    final tags = <String>{};
    for (final n in _allNotes) {
      if (n.tags != null) tags.addAll(n.tags!);
    }
    return tags.toList();
  }

  void togglePinnedFilter() {
    _showOnlyPinned = !_showOnlyPinned;
    _applyFilters();
    notifyListeners();
  }

  void toggleArchiveFilter() {
    _showArchived = !_showArchived;
    _applyFilters();
    notifyListeners();
  }

  void _applyFilters() {
    _notes = _allNotes.where((note) {
      final matchesQuery = _searchQuery.isEmpty ||
          note.title.contains(_searchQuery) ||
          note.content.contains(_searchQuery);

      final matchesTag = (_selectedTag == "all") ||
          (note.tags?.contains(_selectedTag) ?? false);

      if (_showOnlyPinned && !(note.isPinned ?? false)) return false;
      if (!_showArchived && (note.isArchived ?? false)) return false;

      return matchesQuery && matchesTag;
    }).toList();

    _notes.sort((a, b) {
      if ((a.isPinned ?? false) != (b.isPinned ?? false)) {
        return (b.isPinned ?? false) ? 1 : -1;
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
