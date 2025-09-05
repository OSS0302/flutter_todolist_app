import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
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

class _ListScreenState extends State<ListScreen>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  bool isDarkMode = true;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ListViewModel>().loadTodos();
    });

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// 삭제 확인 다이얼로그
  Future<bool> _showConfirmDialog({
    required String title,
    required String content,
  }) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => ScaleTransition(
        scale: CurvedAnimation(
          parent: _fadeController,
          curve: Curves.easeInOutBack,
        ),
        child: AlertDialog(
          backgroundColor: Colors.white,
          title: Text(title),
          content: Text(content),
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
      ),
    ) ??
        false;
  }

  /// 정렬 옵션 BottomSheet
  void _showSortOptions(ListViewModel viewModel) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Wrap(
        children: [
          _sortOptionTile(Icons.star, '즐겨찾기 우선', () {
            viewModel.todos.sort((a, b) => b.isFavorite ? 1 : -1);
            viewModel.notifyListeners();
          }),
          _sortOptionTile(Icons.access_time, '마감일순', () {
            viewModel.todos.sort((a, b) {
              return (a.dueDate ?? DateTime.now())
                  .compareTo(b.dueDate ?? DateTime.now());
            });
            viewModel.notifyListeners();
          }),
          _sortOptionTile(Icons.done_all, '완료 항목 우선', () {
            viewModel.todos.sort((a, b) => b.isDone ? 1 : -1);
            viewModel.notifyListeners();
          }),
        ],
      ),
    );
  }

  ListTile _sortOptionTile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(title),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }

  /// 앱 정보 다이얼로그
  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: "TodoList Pro",
      applicationVersion: "v2.0.1",
      applicationIcon: const Icon(Icons.check_circle, color: Colors.blue),
      children: [
        const Text("세련된 Flutter Todo 앱입니다."),
      ],
    );
  }

  /// SpeedDial 버튼
  Widget _buildSpeedDial(ListViewModel viewModel) {
    return ScaleTransition(
      scale: _fadeAnimation,
      child: SpeedDial(
        animatedIcon: AnimatedIcons.menu_close,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        spacing: 10,
        spaceBetweenChildren: 8,
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
                  pageBuilder: (_, __, ___) => const AddScreen(),
                  transitionsBuilder: (_, animation, __, child) =>
                      FadeTransition(
                          opacity: CurvedAnimation(
                              parent: animation, curve: Curves.easeInOut),
                          child: child),
                ),
              );
              viewModel.refresh();
            },
          ),
          SpeedDialChild(
            child: const Icon(Icons.sort),
            backgroundColor: Colors.teal,
            label: '정렬 옵션',
            onTap: () => _showSortOptions(viewModel),
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
              viewModel.showOnlyFavorites ? Icons.star : Icons.star_border,
              color: Colors.yellow,
            ),
            backgroundColor: Colors.amber,
            label: '즐겨찾기 필터',
            onTap: () => viewModel.toggleFavoriteFilter(),
          ),
          SpeedDialChild(
            child: const Icon(Icons.delete_forever),
            backgroundColor: Colors.redAccent,
            label: '전체 삭제',
            onTap: () async {
              final shouldDeleteAll = await _showConfirmDialog(
                title: '전체 삭제',
                content: '모든 할 일을 삭제하시겠습니까?',
              );
              if (shouldDeleteAll) viewModel.clearAllTodos();
            },
          ),
          SpeedDialChild(
            child: Icon(
              isDarkMode ? Icons.light_mode : Icons.dark_mode,
              color: Colors.white,
            ),
            backgroundColor: Colors.purple,
            label: '다크모드 전환',
            onTap: () => setState(() => isDarkMode = !isDarkMode),
          ),
          SpeedDialChild(
            child: const Icon(Icons.info_outline),
            backgroundColor: Colors.indigo,
            label: '앱 정보',
            onTap: _showAboutDialog,
          ),
        ],
      ),
    );
  }

  /// ---------------- UI BUILD ----------------
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
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Stack(
          children: [
            _buildBackground(),
            SafeArea(
              child: viewModel.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                children: [
                  _buildSearchBar(viewModel),
                  _buildFilterChips(viewModel),
                  _buildProgressBar(viewModel),
                  const SizedBox(height: 12),
                  _buildTodoList(viewModel),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildSpeedDial(viewModel),
    );
  }

  /// 배경 위젯
  Widget _buildBackground() {
    return Container(
      decoration: isDarkMode
          ? const BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.black, Colors.black87, Colors.black54],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      )
          : const BoxDecoration(color: Colors.white),
    );
  }

  /// 검색창
  Widget _buildSearchBar(ListViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: TextField(
        onChanged: viewModel.setSearchKeyword,
        style: TextStyle(
          color: isDarkMode ? Colors.white : Colors.black,
        ),
        decoration: InputDecoration(
          hintText: '할 일을 검색하세요...',
          hintStyle: TextStyle(
            color: isDarkMode ? Colors.white54 : Colors.black45,
          ),
          filled: true,
          fillColor:
          isDarkMode ? Colors.white10 : Colors.black.withOpacity(0.05),
          prefixIcon: Icon(Icons.search,
              color: isDarkMode ? Colors.white54 : Colors.black54),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  /// 필터칩
  Widget _buildFilterChips(ListViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _filterChip('전체', FilterStatus.all, viewModel),
          _filterChip('완료', FilterStatus.done, viewModel),
          _filterChip('미완료', FilterStatus.notDone, viewModel),
        ],
      ),
    );
  }

  ChoiceChip _filterChip(String label, FilterStatus status, ListViewModel vm) {
    return ChoiceChip(
      label: Text(label),
      selected: vm.filterStatus == status,
      selectedColor: Colors.blue,
      onSelected: (_) => vm.setFilterStatus(status),
    );
  }

  /// 진행률 바
  Widget _buildProgressBar(ListViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: LinearProgressIndicator(
        value: viewModel.progress,
        backgroundColor: Colors.black12,
        valueColor: const AlwaysStoppedAnimation<Color>(
            Colors.lightGreenAccent),
        minHeight: 6,
      ),
    );
  }

  /// 할 일 리스트
  Widget _buildTodoList(ListViewModel viewModel) {
    if (viewModel.filteredTodos.isEmpty) {
      return const Expanded(
        child: Center(
          child: Text(
            '할 일이 없습니다.',
            style: TextStyle(color: Colors.blue, fontSize: 18),
          ),
        ),
      );
    }

    return Expanded(
      child: ListView.builder(
        controller: _scrollController,
        itemCount: viewModel.filteredTodos.length,
        itemBuilder: (context, index) {
          final todo = viewModel.filteredTodos[index];
          final date =
          DateTime.fromMillisecondsSinceEpoch(todo.dateTime);
          final formattedDate =
              '${date.year}년 ${date.month}월 ${date.day}일';

          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
            ),
            child: Dismissible(
              key: Key(todo.key.toString()),
              direction: DismissDirection.endToStart,
              confirmDismiss: (_) async {
                return await _showConfirmDialog(
                  title: "삭제 확인",
                  content: "정말 이 항목을 삭제하시겠습니까?",
                );
              },
              onDismissed: (_) => viewModel.deleteTodo(todo),
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                color: Colors.redAccent,
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              child: TodoItem(
                todo: todo,
                formattedDate: formattedDate,
                onTapCallBack: viewModel.toggleDone,
                onDelete: (todo) async {
                  final shouldDelete = await _showConfirmDialog(
                    title: "삭제 확인",
                    content: "정말 이 항목을 삭제하시겠습니까?",
                  );
                  if (shouldDelete) viewModel.deleteTodo(todo);
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
