import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart'; // ✅ SpeedDial 라이브러리
import 'package:provider/provider.dart';
import 'package:todolist/presentation/add_screen.dart';
import 'package:todolist/presentation/note/note_screen.dart';
import 'package:todolist/presentation/todo_item.dart';
import 'package:todolist/presentation/list_view_model.dart';

class ListScreen extends StatefulWidget {
  const ListScreen({Key? key}) : super(key: key);

  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  final ScrollController _scrollController = ScrollController();
  bool isDarkMode = true; // ✅ 다크모드 상태

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ListViewModel>().loadTodos();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<bool> _showDeleteConfirmDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('삭제 확인'),
        content: const Text('정말 이 항목을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('삭제'),
          ),
        ],
      ),
    ) ??
        false;
  }

  Future<bool> _showDeleteAllConfirmDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('전체 삭제'),
        content: const Text('모든 할 일을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('삭제'),
          ),
        ],
      ),
    ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ListViewModel>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      appBar: AppBar(
        title: const Hero(
          tag: 'app_title',
          child: Material(
            color: Colors.transparent,
            child: Text(
              'TodoList',
              style: TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDarkMode
                    ? [const Color(0xFF0F2027), const Color(0xFF2C5364)]
                    : [Colors.blue.shade100, Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
            child: Container(
              color: isDarkMode
                  ? Colors.blue.withOpacity(0.2)
                  : Colors.white.withOpacity(0.1),
            ),
          ),
          SafeArea(
            child: viewModel.isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  child: TextField(
                    onChanged: (value) =>
                        viewModel.setSearchKeyword(value),
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                    decoration: InputDecoration(
                      hintText: '할 일을 검색하세요...',
                      hintStyle: TextStyle(
                        color:
                        isDarkMode ? Colors.white54 : Colors.black45,
                      ),
                      filled: true,
                      fillColor: isDarkMode
                          ? Colors.white10
                          : Colors.black.withOpacity(0.05),
                      prefixIcon: Icon(Icons.search,
                          color:
                          isDarkMode ? Colors.white54 : Colors.black54),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ChoiceChip(
                        label: const Text('전체'),
                        selected:
                        viewModel.filterStatus == FilterStatus.all,
                        selectedColor: Colors.blue,
                        onSelected: (_) => viewModel
                            .setFilterStatus(FilterStatus.all),
                      ),
                      ChoiceChip(
                        label: const Text('완료'),
                        selected:
                        viewModel.filterStatus == FilterStatus.done,
                        selectedColor: Colors.green,
                        onSelected: (_) => viewModel
                            .setFilterStatus(FilterStatus.done),
                      ),
                      ChoiceChip(
                        label: const Text('미완료'),
                        selected: viewModel.filterStatus ==
                            FilterStatus.notDone,
                        selectedColor: Colors.redAccent,
                        onSelected: (_) => viewModel
                            .setFilterStatus(FilterStatus.notDone),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: LinearProgressIndicator(
                    value: viewModel.progress,
                    backgroundColor: Colors.black12,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.lightGreenAccent),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: viewModel.filteredTodos.isEmpty
                      ? const Center(
                    child: Text(
                      '할 일이 없습니다.',
                      style: TextStyle(
                          color: Colors.blue, fontSize: 18),
                    ),
                  )
                      : ListView.builder(
                    controller: _scrollController,
                    itemCount: viewModel.filteredTodos.length,
                    itemBuilder: (context, index) {
                      final todo = viewModel.filteredTodos[index];
                      final date =
                      DateTime.fromMillisecondsSinceEpoch(
                          todo.dateTime);
                      final formattedDate =
                          '${date.year}년 ${date.month}월 ${date.day}일';

                      return Dismissible(
                        key: Key(todo.key.toString()),
                        direction: DismissDirection.endToStart,
                        confirmDismiss: (_) async {
                          return await _showDeleteConfirmDialog(
                              context);
                        },
                        onDismissed: (_) =>
                            viewModel.deleteTodo(todo),
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20),
                          color: Colors.redAccent,
                          child: const Icon(Icons.delete,
                              color: Colors.white),
                        ),
                        child: TodoItem(
                          todo: todo,
                          formattedDate: formattedDate,
                          trailing: todo.isDone
                              ? GestureDetector(
                            onTap: () async {
                              final shouldDelete =
                              await _showDeleteConfirmDialog(
                                  context);
                              if (shouldDelete) {
                                await viewModel
                                    .deleteTodo(todo);
                              }
                            },
                            child: const Icon(Icons.delete,
                                color: Colors.redAccent),
                          )
                              : const Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.white54),
                          onTapCallBack: (todo) =>
                              viewModel.toggleDone(todo),
                          onDelete: (todo) async {
                            final shouldDelete =
                            await _showDeleteConfirmDialog(
                                context);
                            if (shouldDelete) {
                              await viewModel.deleteTodo(todo);
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: SpeedDial(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.black87,
        icon: Icons.add,
        activeIcon: Icons.close,
        spacing: 10,
        children: [
          SpeedDialChild(
            child: const Icon(Icons.playlist_add),
            backgroundColor: Colors.lightBlue,
            label: '할 일 추가',
            onTap: () async {
              await Navigator.push(
                context,
                PageRouteBuilder(
                  transitionDuration: const Duration(milliseconds: 500),
                  pageBuilder: (context, animation, secondaryAnimation) =>
                  const AddScreen(),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                    final curvedAnimation = CurvedAnimation(
                        parent: animation, curve: Curves.easeInOut);
                    return FadeTransition(
                        opacity: curvedAnimation, child: child);
                  },
                ),
              );
              viewModel.refresh();
            },
          ),
          SpeedDialChild(
            child: const Icon(Icons.note),
            backgroundColor: Colors.orange,
            label: '메모장',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const NoteScreen(
                    todoId: '',
                    todoTitle: '',
                  ),
                ),
              );
            },
          ),
          SpeedDialChild(
            child: Icon(
                viewModel.showOnlyFavorites
                    ? Icons.star
                    : Icons.star_border,
                color: Colors.yellow),
            backgroundColor: Colors.amber,
            label: '즐겨찾기 필터',
            onTap: () => viewModel.toggleFavoriteFilter(),
          ),
          SpeedDialChild(
            child: const Icon(Icons.delete_forever),
            backgroundColor: Colors.redAccent,
            label: '전체 삭제',
            onTap: () async {
              final shouldDeleteAll =
              await _showDeleteAllConfirmDialog(context);
              if (shouldDeleteAll) {
                viewModel.clearAllTodos();
              }
            },
          ),
          SpeedDialChild(
            child: Icon(
              isDarkMode ? Icons.light_mode : Icons.dark_mode,
              color: Colors.white,
            ),
            backgroundColor: Colors.purple,
            label: '다크모드 전환',
            onTap: () {
              setState(() {
                isDarkMode = !isDarkMode;
              });
            },
          ),
        ],
      ),
    );
  }
}
