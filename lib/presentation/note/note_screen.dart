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

  /// 📌 메모 추가/수정 BottomSheet
  void _showNoteBottomSheet(BuildContext context, {Note? note}) {
    final vm = context.read<NoteViewModel>();
    final titleController = TextEditingController(text: note?.title ?? '');
    final contentController = TextEditingController(text: note?.content ?? '');
    Color selectedColor = note != null ? Color(note.color) : Colors.orange[100]!;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, controller) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 15,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                controller: controller,
                child: StatefulBuilder(
                  builder: (context, setState) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 50,
                            height: 5,
                            margin: const EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        Text(
                          note == null ? "새 메모 추가" : "메모 수정",
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: titleController,
                          decoration: const InputDecoration(
                            hintText: "제목 입력",
                            border: InputBorder.none,
                          ),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: contentController,
                          maxLines: null,
                          decoration: const InputDecoration(
                            hintText: "메모를 입력하세요...",
                            border: InputBorder.none,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            const Text("색상", style: TextStyle(fontWeight: FontWeight.w500)),
                            const SizedBox(width: 12),
                            GestureDetector(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20)),
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
                                radius: 16,
                              ),
                            ),
                            const Spacer(),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepOrange,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
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
                              icon: const Icon(Icons.check),
                              label: const Text("저장"),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, Note note) {
    final vm = context.read<NoteViewModel>();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("메모 삭제"),
        content: const Text("이 메모를 삭제하시겠습니까?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("취소"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
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
        final tags = ["all", ...vm.getAllTags()];

        return Scaffold(
          extendBody: true,
          backgroundColor: Colors.grey[100],
          appBar: AppBar(
            title: Text(todoTitle),
            centerTitle: true,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
            elevation: 1,
            actions: [
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
              IconButton(
                icon: Icon(vm.showOnlyPinned ? Icons.push_pin : Icons.push_pin_outlined),
                onPressed: () => vm.togglePinnedFilter(),
              ),
              IconButton(
                icon: Icon(vm.showArchived ? Icons.archive : Icons.archive_outlined),
                onPressed: () => vm.toggleArchiveFilter(),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: Colors.deepOrange,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            onPressed: () => _showNoteBottomSheet(context),
            child: const Icon(Icons.add, size: 28),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
          bottomNavigationBar: BottomAppBar(
            shape: const CircularNotchedRectangle(),
            notchMargin: 10,
            color: Colors.white,
            elevation: 10,
            child: SizedBox(height: 60),
          ),
          body: vm.isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
            children: [
              /// 🔖 태그 필터
              if (tags.isNotEmpty)
                SizedBox(
                  height: 48,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (context, i) {
                      final tag = tags[i];
                      final selected = vm.selectedTag == tag;
                      return ChoiceChip(
                        label: Text(tag == "all" ? "전체" : tag),
                        selected: selected,
                        onSelected: (_) => vm.setTagFilter(tag),
                        selectedColor: Colors.deepOrange.shade200,
                      );
                    },
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemCount: tags.length,
                  ),
                ),
              Expanded(
                child: vm.notes.isEmpty
                    ? const Center(
                  child: Text(
                    "메모가 없습니다.\n+ 버튼으로 추가하세요.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
                    : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 0.9,
                  ),
                  itemCount: vm.notes.length,
                  itemBuilder: (context, index) {
                    final note = vm.notes[index];
                    final dateText = DateFormat('MM/dd HH:mm').format(
                      DateTime.fromMillisecondsSinceEpoch(
                          note.updatedAt ?? note.createdAt),
                    );

                    return GestureDetector(
                      onLongPress: () => _confirmDelete(context, note),
                      onTap: () => _showNoteBottomSheet(context, note: note),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Color(note.color).withOpacity(0.9),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    note.title.isNotEmpty
                                        ? note.title
                                        : "(제목 없음)",
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Icon(
                                  note.isPinned
                                      ? Icons.push_pin
                                      : Icons.push_pin_outlined,
                                  size: 18,
                                  color: note.isPinned ? Colors.deepOrange : Colors.grey,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: Text(
                                note.content,
                                maxLines: 6,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  dateText,
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                                Icon(
                                  note.isArchived
                                      ? Icons.archive
                                      : Icons.archive_outlined,
                                  size: 18,
                                  color: note.isArchived ? Colors.blue : Colors.grey,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 🔍 검색 Delegate
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
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text("검색어 입력: $query"),
    );
  }
}
