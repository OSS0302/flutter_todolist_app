import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:provider/provider.dart';
import 'package:todolist/presentation/add_screen.dart';
import 'package:todolist/presentation/list_view_model.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/percent_indicator.dart';

class ListScreen extends StatefulWidget {
  const ListScreen({Key? key}) : super(key: key);

  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  bool isDarkMode = true;
  bool isPressed = false;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ListViewModel>().loadTodos();
    });

    _fadeController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut);
    _fadeController.forward();

    _shimmerController =
    AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))
      ..repeat();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _shimmerController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ✅ 프리미엄 스타일 확인 다이얼로그
  Future<bool> _showConfirmDialog({
    required String title,
    required String message,
  }) async {
    bool? result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("취소", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text("확인"),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  // ✅ 3D FAB (기존 유지)
  Widget _build3DPremiumFAB() {
    const double size = 68;

    return GestureDetector(
      onTapDown: (_) => setState(() => isPressed = true),
      onTapUp: (_) => setState(() => isPressed = false),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AddScreen(
              todoId: null,
              todoTitle: '',
            ),
          ),
        );
      },
      child: AnimatedScale(
        scale: isPressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                  color: Colors.blueAccent.withOpacity(0.4),
                  blurRadius: 25,
                  offset: const Offset(0, 12))
            ],
            gradient: const LinearGradient(
              colors: [Color(0xFF4FACFE), Color(0xFF00F2FE)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Icon(Icons.add, color: Colors.white, size: 30),
        ),
      ),
    );
  }

  // ✅ SpeedDial
  Widget _buildSpeedDial(ListViewModel viewModel) {
    return SpeedDial(
      backgroundColor: Colors.transparent,
      elevation: 0,
      icon: Icons.menu,
      activeIcon: Icons.close,
      overlayColor: Colors.black,
      overlayOpacity: 0.4,
      children: [
        SpeedDialChild(
          child: const Icon(Icons.sort, color: Colors.white),
          backgroundColor: Colors.blueAccent,
          label: "정렬",
          onTap: () => _showSortOptions(viewModel),
        ),
        SpeedDialChild(
          child: const Icon(Icons.info_outline, color: Colors.white),
          backgroundColor: Colors.blueAccent,
          label: "앱 정보",
          onTap: _showAboutDialog,
        ),
        SpeedDialChild(
          child: const Icon(Icons.add, color: Colors.white),
          backgroundColor: Colors.blueAccent,
          label: "할 일 추가",
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AddScreen(
                  todoId: null,
                  todoTitle: '',
                ),
              ),
            );
          },
        ),
      ],
      child: _build3DPremiumFAB(),
    );
  }

  // ✅ 정렬 옵션 BottomSheet
  void _showSortOptions(ListViewModel viewModel) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape:
      const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
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
      leading: Icon(icon, color: Colors.blueAccent),
      title: Text(title),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: "TodoList Pro",
      applicationVersion: "v3.2.0",
      applicationIcon:
      const Icon(Icons.check_circle, color: Colors.blueAccent),
      children: const [
        Text("세련된 프리미엄 TodoList 앱입니다.\n3D FAB + Blur + Shimmer 효과 적용."),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ListViewModel>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      appBar: AppBar(
        title: Text('TodoList',
            style: GoogleFonts.montserrat(
                color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 24)),
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

  Widget _buildBackground() {
    return Container(
      decoration: isDarkMode
          ? const BoxDecoration(
          gradient: LinearGradient(
              colors: [Colors.black, Colors.black87, Colors.black54],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight))
          : const BoxDecoration(color: Colors.white),
    );
  }

  Widget _buildSearchBar(ListViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: TextField(
        onChanged: viewModel.setSearchKeyword,
        style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
        decoration: InputDecoration(
          hintText: '할 일을 검색하세요...',
          hintStyle:
          TextStyle(color: isDarkMode ? Colors.white54 : Colors.black45),
          filled: true,
          fillColor: isDarkMode ? Colors.white10 : Colors.black.withOpacity(0.05),
          prefixIcon: Icon(Icons.search,
              color: isDarkMode ? Colors.white54 : Colors.black54),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none),
        ),
      ),
    );
  }

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

  Widget _buildProgressBar(ListViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: LinearPercentIndicator(
        lineHeight: 12,
        percent: viewModel.progress,
        backgroundColor: Colors.grey.shade300,
        progressColor: Colors.lightGreenAccent,
        barRadius: const Radius.circular(12),
        animation: true,
        animationDuration: 600,
        center: Text(
          "${(viewModel.progress * 100).toStringAsFixed(0)}%",
          style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.black,
              fontSize: 12,
              fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildTodoList(ListViewModel viewModel) {
    if (viewModel.filteredTodos.isEmpty) {
      return const Expanded(
        child: Center(
          child: Text('할 일이 없습니다.',
              style: TextStyle(color: Colors.red, fontSize: 18)),
        ),
      );
    }

    return Expanded(
      child: AnimationLimiter(
        child: ListView.builder(
          controller: _scrollController,
          itemCount: viewModel.filteredTodos.length,
          itemBuilder: (context, index) {
            final todo = viewModel.filteredTodos[index];
            final date = DateTime.fromMillisecondsSinceEpoch(todo.dateTime);
            final formattedDate = '${date.year}년 ${date.month}월 ${date.day}일';

            final textColor =
            todo.isDone ? Colors.red : (isDarkMode ? Colors.white : Colors.black);

            final textStyle = GoogleFonts.notoSans(
              color: textColor,
              decoration:
              todo.isDone ? TextDecoration.lineThrough : TextDecoration.none,
              fontSize: 16,
            );

            return AnimationConfiguration.staggeredList(
              position: index,
              duration: const Duration(milliseconds: 400),
              child: SlideAnimation(
                verticalOffset: 50.0,
                child: FadeInAnimation(
                  child: Slidable(
                    key: Key(todo.key.toString()),
                    endActionPane: ActionPane(
                      motion: const StretchMotion(),
                      children: [
                        SlidableAction(
                          onPressed: (_) async {
                            final shouldDelete = await _showConfirmDialog(
                              title: "삭제 확인",
                              message: "정말 이 항목을 삭제하시겠습니까?",
                            );
                            if (shouldDelete) viewModel.deleteTodo(todo);
                          },
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          icon: Icons.delete,
                          label: '삭제',
                        ),
                        SlidableAction(
                          onPressed: (_) => viewModel.toggleFavorite(todo),
                          backgroundColor: Colors.amber,
                          foregroundColor: Colors.white,
                          icon: todo.isFavorite
                              ? Icons.star
                              : Icons.star_border,
                          label: '즐겨찾기',
                        ),
                      ],
                    ),
                    child: ListTile(
                      onTap: () => viewModel.toggleDone(todo),
                      leading: todo.isDone
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : const Icon(Icons.check_circle_outline),
                      title: Text(todo.title, style: textStyle),
                      subtitle:
                      Text(formattedDate, style: textStyle.copyWith(fontSize: 12)),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
