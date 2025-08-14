import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:todolist/model/note.dart';
import 'package:todolist/presentation/note/note_view_model.dart';

class NoteScreen extends StatelessWidget {
  final String todoId;
  final String todoTitle;

  const NoteScreen({
    Key? key,
    required this.todoId,
    required this.todoTitle,
  }) : super(key: key);

  void _showNoteDialog(BuildContext context, {Note? note}) {
    final vm = context.read<NoteViewModel>();
    final titleController = TextEditingController(text: note?.title ?? '');
    final contentController = TextEditingController(text: note?.content ?? '');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(note == null ? "새 메모" : "메모 수정"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  hintText: "제목을 입력하세요",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: contentController,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: "메모 내용을 입력하세요",
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("취소"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepOrange,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              if (contentController.text.trim().isEmpty) return;
              if (note == null) {
                vm.addNote(
                  contentController.text.trim(),
                  title: titleController.text.trim(),
                );
              } else {
                vm.updateNote(
                  note.copyWith(title: titleController.text.trim()),
                  contentController.text.trim(),
                );
              }
              Navigator.pop(context);
            },
            child: const Text("저장"),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, Note note) {
    final vm = context.read<NoteViewModel>();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("메모 삭제"),
        content: const Text("정말 이 메모를 삭제하시겠습니까?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("취소"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              vm.deleteNote(note);
              Navigator.pop(context);
            },
            child: const Text("삭제"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NoteViewModel>(
      builder: (context, vm, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text("${vm.todoTitle}의 메모"),
            backgroundColor: Colors.deepOrange,
            foregroundColor: Colors.white,
          ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: Colors.deepOrange,
            onPressed: () => _showNoteDialog(context),
            child: const Icon(Icons.add),
          ),
          body: vm.isLoading
              ? const Center(child: CircularProgressIndicator())
              : vm.notes.isEmpty
              ? const Center(
            child: Text(
              "메모가 없습니다.\n+ 버튼을 눌러 추가하세요.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          )
              : ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: vm.notes.length,
            itemBuilder: (context, index) {
              final note = vm.notes[index];
              final dateText = DateFormat('yyyy년 MM월 dd일 HH:mm')
                  .format(DateTime.fromMillisecondsSinceEpoch(
                  note.updatedAt ?? note.createdAt));

              return Dismissible(
                key: Key(note.id),
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.only(left: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                secondaryBackground: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                confirmDismiss: (_) async {
                  _confirmDelete(context, note);
                  return false;
                },
                child: Card(
                  color: Colors.orange[50],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    title: Text(
                      note.title.isNotEmpty
                          ? note.title
                          : "(제목 없음)",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          note.content,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "작성/수정: $dateText",
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                    onTap: () =>
                        _showNoteDialog(context, note: note),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
