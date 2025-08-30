import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
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

  void _showNoteBottomSheet(BuildContext context, {Note? note}) {
    final vm = context.read<NoteViewModel>();
    final titleController = TextEditingController(text: note?.title ?? '');
    final contentController = TextEditingController(text: note?.content ?? '');
    Color selectedColor = note != null ? Color(note.color) : Colors.orange[100]!;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "메모 작성 해주세요.",
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return Align(
          alignment: Alignment.bottomCenter,
          child: Material(
            color: Colors.transparent,
            child: StatefulBuilder(
              builder: (context, setState) {
                return AnimatedPadding(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                    left: 16,
                    right: 16,
                  ),
                  child: Container(
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height * 0.8,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            note == null ? "새 메모" : "메모 수정",
                            style: const TextStyle(
                                fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: titleController,
                            decoration: const InputDecoration(
                              hintText: "제목을 입력해 주세요",
                              border: InputBorder.none,
                              hintStyle: TextStyle(color: Colors.grey),
                            ),
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w600),
                          ),
                          TextField(
                            controller: contentController,
                            maxLines: null,
                            decoration: const InputDecoration(
                              hintText: "메모 작성 해주세요.",
                              border: InputBorder.none,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Text("색상: "),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                          BorderRadius.circular(20)),
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
                              const Spacer(),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.deepOrange,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: () {
                                  if (contentController.text.trim().isEmpty) {
                                    return;
                                  }
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
                                icon: const Icon(Icons.save),
                                label: const Text("저장"),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
      transitionBuilder: (context, anim, _, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: FadeTransition(
            opacity: anim,
            child: child,
          ),
        );
      },
    );
  }


  /// 삭제 확인
  void _confirmDelete(BuildContext context, Note note) {
    final vm = context.read<NoteViewModel>();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("메모 삭제"),
        content: const Text("정말 이 메모를 삭제하시겠습니까?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("취소"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
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
          appBar: AppBar(
            title: Text("${vm.todoTitle}의 메모"),
            backgroundColor: Colors.deepOrange,
            foregroundColor: Colors.white,
            elevation: 0,
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
                icon: Icon(
                  vm.showOnlyPinned ? Icons.push_pin : Icons.push_pin_outlined,
                ),
                onPressed: () => vm.togglePinnedFilter(),
              ),
              IconButton(
                icon: Icon(
                  vm.showArchived ? Icons.archive : Icons.archive_outlined,
                ),
                onPressed: () => vm.toggleArchiveFilter(),
              ),
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

          /// 🔥 FAB
          floatingActionButton: SpeedDial(
            animatedIcon: AnimatedIcons.menu_close,
            backgroundColor: Colors.deepOrange,
            overlayColor: Colors.black,
            overlayOpacity: 0.5,
            spacing: 12,
            spaceBetweenChildren: 12,
            children: [
              SpeedDialChild(
                child: const Icon(Icons.add, color: Colors.white),
                backgroundColor: Colors.green,
                label: "새 메모 추가",
                onTap: () => _showNoteBottomSheet(context),
              ),
              SpeedDialChild(
                child: Icon(
                  vm.showOnlyPinned ? Icons.star : Icons.star_border,
                  color: Colors.white,
                ),
                backgroundColor: Colors.blueGrey,
                label: vm.showOnlyPinned ? "전체 메모 보기" : "즐겨찾기만 보기",
                onTap: () => vm.togglePinnedFilter(),
              ),
              SpeedDialChild(
                child: const Icon(Icons.sort, color: Colors.white),
                backgroundColor: Colors.purple,
                label: "정렬 옵션",
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("상단 메뉴에서 정렬을 선택하세요.")),
                  );
                },
              ),
            ],
          ),

          body: vm.isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
            children: [
              if (tags.isNotEmpty)
                SizedBox(
                  height: 42,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (context, i) {
                      final tag = tags[i];
                      final selected = vm.selectedTag == tag;
                      return ChoiceChip(
                        label: Text(tag == "all" ? "전체" : tag),
                        selected: selected,
                        onSelected: (_) => vm.setTagFilter(tag),
                        selectedColor: Colors.deepOrange.shade100,
                      );
                    },
                    separatorBuilder: (_, __) =>
                    const SizedBox(width: 8),
                    itemCount: tags.length,
                  ),
                ),
              Expanded(
                child: vm.notes.isEmpty
                    ? const Center(
                  child: Text(
                    "메모가 없습니다.\n+ 버튼을 눌러 추가하세요.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 16, color: Colors.grey),
                  ),
                )
                    : GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.9,
                  ),
                  itemCount: vm.notes.length,
                  itemBuilder: (context, index) {
                    final note = vm.notes[index];
                    final dateText =
                    DateFormat('MM/dd HH:mm').format(
                      DateTime.fromMillisecondsSinceEpoch(
                          note.updatedAt ?? note.createdAt),
                    );

                    return Dismissible(
                      key: Key(note.id),
                      background: Container(
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.only(left: 20),
                        child: const Icon(Icons.delete,
                            color: Colors.white),
                      ),
                      secondaryBackground: Container(
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.delete,
                            color: Colors.white),
                      ),
                      confirmDismiss: (_) async {
                        _confirmDelete(context, note);
                        return false;
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Color(note.color),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            )
                          ],
                        ),
                        padding: const EdgeInsets.all(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => _showNoteBottomSheet(context,
                              note: note),
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
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
                                      overflow:
                                      TextOverflow.ellipsis,
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
                                      size: 20,
                                    ),
                                    onPressed: () =>
                                        vm.togglePin(note),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Expanded(
                                child: Text(
                                  note.content,
                                  maxLines: 5,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment:
                                MainAxisAlignment
                                    .spaceBetween,
                                children: [
                                  Text(
                                    dateText,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      note.isArchived
                                          ? Icons.archive
                                          : Icons.archive_outlined,
                                      color: note.isArchived
                                          ? Colors.blue
                                          : Colors.grey,
                                      size: 20,
                                    ),
                                    onPressed: () =>
                                        vm.toggleArchive(note),
                                  ),
                                ],
                              ),
                            ],
                          ),
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
