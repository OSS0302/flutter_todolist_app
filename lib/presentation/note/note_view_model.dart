import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../../model/note.dart';

class NoteViewModel extends ChangeNotifier {
  final String todoId;
  final String todoTitle;
  final Box<Note> _noteBox;

  List<Note> _notes = [];
  bool _isLoading = false;

  List<Note> get notes => _notes;
  bool get isLoading => _isLoading;

  NoteViewModel({
    required this.todoId,
    required this.todoTitle,
    required Box<Note> noteBox,
  }) : _noteBox = noteBox;

  Future<void> loadNotes() async {
    _isLoading = true;
    notifyListeners();

    _notes = _noteBox.values
        .where((note) => note.todoId == todoId)
        .toList();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addNote(String content, {String title = ''}) async {
    final newNote = Note(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      todoId: todoId,
      title: title,
      content: content,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );

    await _noteBox.put(newNote.id, newNote); // Hive 저장
    _notes.add(newNote);
    notifyListeners();
  }

  Future<void> updateNote(Note note, String content) async {
    final updatedNote = note.copyWith(
      content: content,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );

    await _noteBox.put(updatedNote.id, updatedNote); // Hive 갱신
    final index = _notes.indexWhere((n) => n.id == note.id);
    if (index != -1) {
      _notes[index] = updatedNote;
      notifyListeners();
    }
  }

  Future<void> deleteNote(Note note) async {
    await _noteBox.delete(note.id); // Hive 삭제
    _notes.removeWhere((n) => n.id == note.id);
    notifyListeners();
  }
}
