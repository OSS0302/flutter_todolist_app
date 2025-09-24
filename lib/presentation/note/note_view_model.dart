import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../../model/note.dart';

enum SortType { latest, oldest, title }

class NoteViewModel extends ChangeNotifier {
  final String todoId;
  final String todoTitle;
  final Box<Note> _noteBox;

  List<Note> _allNotes = []; // 원본 전체
  List<Note> _notes = []; // 필터/정렬된 목록
  bool _isLoading = false;
  String _searchQuery = '';
  SortType _sortType = SortType.latest;

  String _selectedTag = "all";

  // 추가된 필터 상태
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

  // 로딩 상태 헬퍼
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
      _allNotes =
          _noteBox.values.where((note) => note.todoId == todoId).toList();
      _applyFilters();
    });
  }

  Future<void> addNote(
      String content, {
        String title = '',
        int? color,
        List<String>? tags,
        List<String>? checklist, // ✅ 체크리스트 지원
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
        checklist: checklist ?? [],
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
        List<String>? checklist, // ✅ 체크리스트 지원
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
        checklist: checklist ?? note.checklist,
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

  // 🆕 체크리스트 관련 메서드
  void addChecklistItem(Note note, String item) {
    final newList = [...(note.checklist ?? []), item];
    updateNote(note, note.content, checklist: newList);
  }

  void updateChecklistItem(Note note, int index, String newItem) {
    if (note.checklist == null || index < 0 || index >= note.checklist!.length)
      return;
    final newList = [...note.checklist!];
    newList[index] = newItem;
    updateNote(note, note.content, checklist: newList);
  }

  void removeChecklistItem(Note note, int index) {
    if (note.checklist == null || index < 0 || index >= note.checklist!.length)
      return;
    final newList = [...note.checklist!]..removeAt(index);
    updateNote(note, note.content, checklist: newList);
  }

  void toggleChecklistItem(Note note, int index) {
    // ✅ 단순히 체크/해제는 문자열 앞에 [x] / [ ] 같은 표기로 관리 가능
    if (note.checklist == null || index < 0 || index >= note.checklist!.length)
      return;
    final newList = [...note.checklist!];
    final item = newList[index];
    if (item.startsWith("[x] ")) {
      newList[index] = item.replaceFirst("[x] ", "[ ] ");
    } else if (item.startsWith("[ ] ")) {
      newList[index] = item.replaceFirst("[ ] ", "[x] ");
    } else {
      newList[index] = "[ ] $item";
    }
    updateNote(note, note.content, checklist: newList);
  }

  // 핀 / 아카이브 토글
  void togglePin(Note note) {
    updateNote(note, note.content, isPinned: !(note.isPinned));
  }

  void toggleArchive(Note note) {
    updateNote(note, note.content, isArchived: !(note.isArchived));
  }

  // 정렬 / 검색 / 태그
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

  // 필터/정렬 적용
  void _applyFilters() {
    _notes = _allNotes.where((note) {
      final matchesQuery = _searchQuery.isEmpty ||
          note.title.contains(_searchQuery) ||
          note.content.contains(_searchQuery);

      final matchesTag = (_selectedTag == "all") ||
          (note.tags?.contains(_selectedTag) ?? false);

      if (_showOnlyPinned && !note.isPinned) return false;
      if (!_showArchived && note.isArchived) return false;

      return matchesQuery && matchesTag;
    }).toList();

    _notes.sort((a, b) {
      if (a.isPinned != b.isPinned) {
        return b.isPinned ? 1 : -1;
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
