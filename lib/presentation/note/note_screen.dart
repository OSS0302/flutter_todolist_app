// NoteScreen (UI-only 리디자인, 기능은 그대로)
import 'dart:ui';
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

  /// 메모 추가/수정 BottomSheet (UI: Glass + iOS 느낌)
  void _showNoteBottomSheet(BuildContext context, {Note? note}) {
    final vm = Provider.of<NoteViewModel>(context, listen: false);
    final titleController = TextEditingController(text: note?.title ?? '');
    final contentController = TextEditingController(text: note?.content ?? '');
    String tag = note?.tags != null && note!.tags!.isNotEmpty ? note.tags!.first : '';
    Color noteColor = note != null ? Color(note.color) : Colors.orange[100]!;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // 아래에 Glass 스타일 컨테이너
      builder: (context) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 12,
                left: 20,
                right: 20,
                top: 16,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.88),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: StatefulBuilder(
                builder: (context, setState) {
                  return SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                note == null ? "새 메모 추가" : "메모 수정",
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: titleController,
                          decoration: InputDecoration(
                            hintText: "제목 입력",
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: contentController,
                          maxLines: 6,
                          decoration: InputDecoration(
                            hintText: "메모 내용 입력",
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                onChanged: (v) => tag = v,
                                controller: TextEditingController(text: tag),
                                decoration: InputDecoration(
                                  hintText: "태그(선택)",
                                  prefixIcon: const Icon(Icons.tag),
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.color_lens),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text("색상 선택"),
                                    content: SingleChildScrollView(
                                      child: BlockPicker(
                                        pickerColor: noteColor,
                                        onColorChanged: (c) {
                                          setState(() => noteColor = c);
                                          Navigator.pop(context);
                                        },
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.deepOrange,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                onPressed: () async {
                                  final content = contentController.text.trim();
                                  final title = titleController.text.trim();
                                  if (content.isEmpty) return;

                                  // addNote/updateNote 호출 시 ViewModel 시그니처에 맞게 전달
                                  if (note == null) {
                                    await vm.addNote(
                                      content,
                                      title: title,
                                      color: noteColor.value,
                                      tags: tag.isNotEmpty ? [tag] : null,
                                    );
                                  } else {
                                    await vm.updateNote(
                                      note,
                                      content,
                                      title: title,
                                      color: noteColor.value,
                                      tags: tag.isNotEmpty ? [tag] : null,
                                    );
                                  }

                                  if (context.mounted) Navigator.pop(context);
                                },
                                child: Text(
                                  note == null ? "추가하기" : "수정하기",
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            if (note != null)
                              OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  side: BorderSide(color: Colors.red.shade400),
                                ),
                                onPressed: () {
                                  // 삭제 확인 창 호출
                                  Navigator.pop(context);
                                  _confirmDelete(context, note);
                                },
                                child: const Text("삭제", style: TextStyle(color: Colors.red)),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  /// 삭제 확인 다이얼로그
  void _confirmDelete(BuildContext context, Note note) {
    final vm = Provider.of<NoteViewModel>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("삭제 확인"),
        content: const Text("정말 이 메모를 삭제하시겠습니까?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("취소")),
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
        final tags = ["all", ...vm.getAllTags()];

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            title: Text("${vm.todoTitle}의 메모"),
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            elevation: 0,
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFB8C00), Color(0xFFFFB74D)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
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
              PopupMenuButton<SortType>(
                icon: const Icon(Icons.sort),
                onSelected: (type) => vm.setSortType(type),
                itemBuilder: (context) => const [
                  PopupMenuItem(value: SortType.latest, child: Text("최신순")),
                  PopupMenuItem(value: SortType.oldest, child: Text("오래된순")),
                  PopupMenuItem(value: SortType.title, child: Text("제목순")),
                ],
              ),
            ],
          ),

          floatingActionButton: SpeedDial(
            animatedIcon: AnimatedIcons.menu_close,
            backgroundColor: Colors.deepOrange,
            overlayColor: Colors.black,
            overlayOpacity: 0.45,
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
                child: Icon(vm.showOnlyPinned ? Icons.star : Icons.star_border, color: Colors.white),
                backgroundColor: Colors.blueGrey,
                label: vm.showOnlyPinned ? "전체 보기" : "즐겨찾기만",
                onTap: () => vm.togglePinnedFilter(),
              ),
            ],
          ),

          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFFF8E1), Color(0xFFFFF3E0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: vm.isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
              children: [
                if (tags.isNotEmpty)
                  SizedBox(
                    height: 48,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemCount: tags.length,
                    ),
                  ),
                Expanded(
                  child: vm.notes.isEmpty
                      ? const Center(
                    child: Text(
                      "메모가 없습니다.\n+ 버튼을 눌러 추가하세요.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                      : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.9,
                    ),
                    itemCount: vm.notes.length,
                    itemBuilder: (context, index) {
                      final note = vm.notes[index];
                      final dateText = DateFormat('MM/dd HH:mm').format(
                        DateTime.fromMillisecondsSinceEpoch(note.updatedAt ?? note.createdAt),
                      );

                      // Glass card: blur + translucent + soft shadow
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.72),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withOpacity(0.35), width: 1.0),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 6)),
                              ],
                            ),
                            padding: const EdgeInsets.all(14),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () => _showNoteBottomSheet(context, note: note),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          note.title.isNotEmpty ? note.title : "(제목 없음)",
                                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(note.isPinned ? Icons.push_pin : Icons.push_pin_outlined, color: note.isPinned ? Colors.deepOrange : Colors.grey, size: 20),
                                        onPressed: () => vm.togglePin(note),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Expanded(
                                    child: Text(
                                      note.content,
                                      maxLines: 5,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(color: Colors.black87),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(dateText, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                                      IconButton(
                                        icon: Icon(note.isArchived ? Icons.archive : Icons.archive_outlined, color: note.isArchived ? Colors.blue : Colors.grey, size: 20),
                                        onPressed: () => vm.toggleArchive(note),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 검색 Delegate (기본 동작 유지)
class _NoteSearchDelegate extends SearchDelegate<String?> {
  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
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
    return Container(padding: const EdgeInsets.all(16), child: Text("검색어 입력: $query"));
  }
}
