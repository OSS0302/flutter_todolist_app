import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
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

  /// 메모 추가/수정 다이얼로그
  void _showNoteDialog(BuildContext context, {Note? note}) {
    final vm = context.read<NoteViewModel>();
    final titleController = TextEditingController(text: note?.title ?? '');
    final contentController = TextEditingController(text: note?.content ?? '');
    Color selectedColor =
    note != null ? Color(note.color) : Colors.orange[50]!;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text("색상 선택:"),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text("색상 선택"),
                              content: BlockPicker(
                                pickerColor: selectedColor,
                                onColorChanged: (color) {
                                  setState(() => selectedColor = color);
                                  Navigator.pop(context);
                                },
                              ),
                            ),
                          );
                        },
                        child: CircleAvatar(
                          backgroundColor: selectedColor,
                          radius: 14,
                        ),
                      ),
                    ],
                  )
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
                      color: selectedColor.value,
                    );
                  } else {
                    vm.updateNote(
                      note,
                      contentController.text.trim(),
                      title: titleController.text.trim(),
                      color: selectedColor.value,
                    );
                  }
                  Navigator.pop(context);
                },
                child: const Text("저장"),
              ),
            ],
          );
        },
      ),
    );
  }

  /// 삭제 확인
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
            actions: [
              // 검색 아이콘
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () async {
                  final query = await showSearch<String?>(
                    context: context,
                    delegate: _NoteSearchDelegate(),
                  );
                  if (query != null) vm.setSearchQuery(query);
                },
              ),
              // 정렬 메뉴
              PopupMenuButton<SortType>(
                icon: const Icon(Icons.sort),
                onSelected: (type) => vm.setSortType(type),
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: SortType.latest,
                    child: Text("최신순"),
                  ),
                  PopupMenuItem(
                    value: SortType.oldest,
                    child: Text("오래된순"),
                  ),
                  PopupMenuItem(
                    value: SortType.title,
                    child: Text("제목순"),
                  ),
                ],
              ),
            ],
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
              final dateText =
              DateFormat('yyyy년 MM월 dd일 HH:mm').format(
                DateTime.fromMillisecondsSinceEpoch(
                    note.updatedAt ?? note.createdAt),
              );

              return Dismissible(
                key: Key(note.id),
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.only(left: 20),
                  child:
                  const Icon(Icons.delete, color: Colors.white),
                ),
                secondaryBackground: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child:
                  const Icon(Icons.delete, color: Colors.white),
                ),
                confirmDismiss: (_) async {
                  _confirmDelete(context, note);
                  return false;
                },
                child: Card(
                  color: Color(note.color),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            note.title.isNotEmpty
                                ? note.title
                                : "(제목 없음)",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            note.isPinned
                                ? Icons.push_pin
                                : Icons.push_pin_outlined,
                            color: note.isPinned
                                ? Colors.deepOrange
                                : Colors.grey,
                          ),
                          onPressed: () => vm.togglePin(note),
                        ),
                      ],
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
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey),
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

/// 🔎 검색 Delegate
class _NoteSearchDelegate extends SearchDelegate<String?> {
  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () => query = '',
        )
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return BackButton(onPressed: () => close(context, null));
  }

  @override
  Widget buildResults(BuildContext context) {
    close(context, query);
    return Container();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Text("검색어 입력: $query"),
    );
  }
}
