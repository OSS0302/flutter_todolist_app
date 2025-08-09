import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:todolist/model/note.dart';
import 'package:todolist/presentation/note/note_view_model.dart';

class NoteScreen extends StatelessWidget {
  const NoteScreen({Key? key, required String todoId, required String todoTitle}) : super(key: key);

  void _showNoteDialog(BuildContext context, {Note? note}) {
    final vm = context.read<NoteViewModel>();
    final controller = TextEditingController(text: note?.content ?? '');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(note == null ? "새 메모" : "메모 수정"),
        content: TextField(
          controller: controller,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: "메모 내용을 입력하세요",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("취소"),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isEmpty) return;
              if (note == null) {
                vm.addNote(controller.text.trim());
              } else {
                vm.updateNote(note, controller.text.trim());
              }
              Navigator.pop(context);
            },
            child: const Text("저장"),
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
            actions: [
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => _showNoteDialog(context),
              ),
            ],
          ),
          body: vm.isLoading
              ? const Center(child: CircularProgressIndicator())
              : vm.notes.isEmpty
              ? const Center(
            child: Text(
              "메모가 없습니다.\n+ 버튼을 눌러 추가하세요.",
              textAlign: TextAlign.center,
            ),
          )
              : ListView.builder(
            itemCount: vm.notes.length,
            itemBuilder: (context, index) {
              final note = vm.notes[index];
              final dateText = DateFormat('yyyy년 MM월 dd일 HH:mm')
                  .format(DateTime.fromMillisecondsSinceEpoch(
                  note.updatedAt ?? note.createdAt));

              return Card(
                margin: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text(note.content),
                  subtitle: Text("작성/수정: $dateText"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit,
                            color: Colors.blue),
                        onPressed: () =>
                            _showNoteDialog(context, note: note),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete,
                            color: Colors.red),
                        onPressed: () => vm.deleteNote(note),
                      ),
                    ],
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
