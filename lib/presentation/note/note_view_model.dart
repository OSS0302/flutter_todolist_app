import 'package:flutter/material.dart';
import '../../model/note.dart';

class NoteViewModel extends ChangeNotifier {
  final String todoId;
  final String todoTitle;

  List<Note> _notes = [];
  bool _isLoading = false;

  List<Note> get notes => _notes;
  bool get isLoading => _isLoading;

  NoteViewModel({
    required this.todoId,
    required this.todoTitle,
  });

  Future<void> loadNotes() async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 300));
    _notes = [];
    _isLoading = false;
    notifyListeners();
  }

  void addNote(String content, {String title = ''}) {
    final newNote = Note(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      todoId: todoId,
      title: title,
      content: content,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    _notes.add(newNote);
    notifyListeners();
  }

  void updateNote(Note note, String content) {
    final index = _notes.indexWhere((n) => n.id == note.id);
    if (index != -1) {
      _notes[index] = note.copyWith(
        content: content,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      );
      notifyListeners();
    }
  }

  void deleteNote(Note note) {
    _notes.removeWhere((n) => n.id == note.id);
    notifyListeners();
  }
}
