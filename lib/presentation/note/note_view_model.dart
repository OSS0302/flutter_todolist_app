import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../../model/note.dart';

enum SortType { latest, oldest, title }

class NoteViewModel extends ChangeNotifier {
  final String todoId;
  final String todoTitle;
  final Box<Note> _noteBox;

  List<Note> _allNotes = [];
  List<Note> _notes = [];
  bool _isLoading = false;
  String _searchQuery = '';
  SortType _sortType = SortType.latest;

  String _selectedTag = "all";
  int? _selectedColor;

  bool _showOnlyPinned = false;
  bool _showArchived = false;
  bool _showStarred = false;
  bool _showTrash = false;

  List<Note> get notes => _notes;
  bool get isLoading => _isLoading;
  SortType get sortType => _sortType;
  String get selectedTag => _selectedTag;
  int? get selectedColor => _selectedColor;

  bool get showOnlyPinned => _showOnlyPinned;
  bool get showArchived => _showArchived;
  bool get showStarred => _showStarred;
  bool get showTrash => _showTrash;

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

    _allNotes = _noteBox.values.where((note) => note.todoId == todoId).toList();

    _applyFilters();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addNote(
      String content, {
        String title = '',
        int? color,
        List<String>? tags,
        DateTime? reminder, required List<String> checklist, // 🆕 리마인더
      }) async {
    final newNote = Note(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      todoId: todoId,
      title: title,
      content: content,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      isPinned: false,
      isArchived: false,
      isStarred: false, // 🆕 즐겨찾기
      isDeleted: false, // 🆕 휴지통
      color: color ?? Colors.orange[50]!.value,
      tags: tags ?? [],
      reminder: reminder?.millisecondsSinceEpoch,
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
        bool? isArchived,
        bool? isStarred,
        bool? isDeleted,
        List<String>? tags,
        DateTime? reminder, required List<String> checklist,
      }) async {
    final updatedNote = note.copyWith(
      title: title ?? note.title,
      content: content,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
      color: color ?? note.color,
      isPinned: isPinned ?? note.isPinned,
      isArchived: isArchived ?? note.isArchived,
      isStarred: isStarred ?? note.isStarred,
      isDeleted: isDeleted ?? note.isDeleted,
      tags: tags ?? note.tags,
      reminder: reminder?.millisecondsSinceEpoch ?? note.reminder,
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
    final updatedNote = note.copyWith(
      isDeleted: true,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );

    await _noteBox.put(updatedNote.id, updatedNote);

    final index = _allNotes.indexWhere((n) => n.id == note.id);
    if (index != -1) {
      _allNotes[index] = updatedNote;
      _applyFilters();
      notifyListeners();
    }
  }

// 휴지통에서 영구 삭제 (하드 삭제)
  Future<void> permanentlyDelete(Note note) async {
    await _noteBox.delete(note.id);
    _allNotes.removeWhere((n) => n.id == note.id);
    _applyFilters();
    notifyListeners();
  }

// 휴지통에서 복구
  Future<void> restoreNote(Note note) async {
    final updatedNote = note.copyWith(
      isDeleted: false,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );

    await _noteBox.put(updatedNote.id, updatedNote);

    final index = _allNotes.indexWhere((n) => n.id == note.id);
    if (index != -1) {
      _allNotes[index] = updatedNote;
      _applyFilters();
      notifyListeners();
    }
  }

  void togglePin(Note note) {
    updateNote(note, note.content, isPinned: !(note.isPinned ?? false), checklist: []);
  }

  void toggleArchive(Note note) {
    updateNote(note, note.content, isArchived: !(note.isArchived ?? false), checklist: []);
  }

  void toggleStar(Note note) {
    updateNote(note, note.content, isStarred: !(note.isStarred ?? false), checklist: []);
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

  void setColorFilter(int? color) {
    _selectedColor = color;
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

  // 🆕 필터 토글
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

  void toggleStarredFilter() {
    _showStarred = !_showStarred;
    _applyFilters();
    notifyListeners();
  }

  void toggleTrashFilter() {
    _showTrash = !_showTrash;
    _applyFilters();
    notifyListeners();
  }

  // 🆕 통계 기능
  Map<String, int> getTagStats() {
    final Map<String, int> stats = {};
    for (final n in _allNotes) {
      if (n.tags != null) {
        for (final t in n.tags!) {
          stats[t] = (stats[t] ?? 0) + 1;
        }
      }
    }
    return stats;
  }

  Map<int, int> getColorStats() {
    final Map<int, int> stats = {};
    for (final n in _allNotes) {
      stats[n.color] = (stats[n.color] ?? 0) + 1;
    }
    return stats;
  }

  void _applyFilters() {
    _notes = _allNotes.where((note) {
      if (!_showTrash && (note.isDeleted ?? false)) return false;
      if (!_showArchived && (note.isArchived ?? false)) return false;
      if (_showOnlyPinned && !(note.isPinned ?? false)) return false;
      if (_showStarred && !(note.isStarred ?? false)) return false;

      final matchesQuery = _searchQuery.isEmpty ||
          note.title.contains(_searchQuery) ||
          note.content.contains(_searchQuery);

      final matchesTag =
          (_selectedTag == "all") || (note.tags?.contains(_selectedTag) ?? false);

      final matchesColor =
          (_selectedColor == null) || note.color == _selectedColor;

      return matchesQuery && matchesTag && matchesColor;
    }).toList();

    _notes.sort((a, b) {
      if ((a.isPinned ?? false) != (b.isPinned ?? false)) {
        return (b.isPinned ?? false) ? 1 : -1;
      }
      if ((a.isStarred ?? false) != (b.isStarred ?? false)) {
        return (b.isStarred ?? false) ? 1 : -1;
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
