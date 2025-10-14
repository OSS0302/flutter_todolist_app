import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:provider/provider.dart';
import 'package:todolist/presentation/add_screen.dart';
import 'package:todolist/presentation/note/note_screen.dart';
import 'package:todolist/presentation/list_view_model.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';

class ListScreen extends StatefulWidget {
  const ListScreen({Key? key}) : super(key: key);

  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> with TickerProviderStateMixin {
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

  /// SpeedDial 버튼 (고급스럽고 세련된 버전)
  Widget _buildSpeedDial(ListViewModel viewModel) {
    return ScaleTransition(
      scale: _fadeAnimation,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: SpeedDial(
            animatedIcon: AnimatedIcons.menu_close,
            curve: Curves.easeInOutBack,
            overlayColor: Colors.black,
            overlayOpacity: 0.45,
            spaceBetweenChildren: 10,
            childrenButtonSize: const Size(60, 60),
            elevation: 0,
            backgroundColor: Colors.transparent,
            iconTheme: const IconThemeData(color: Colors.white, size: 28),
            gradient: const LinearGradient(
              colors: [Color(0xFF4FACFE), Color(0xFF00F2FE)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),

            children: [
              // 🩵 할 일 추가
              SpeedDialChild(
                backgroundColor: Colors.white.withOpacity(0.15),
                labelBackgroundColor: Colors.black.withOpacity(0.6),
                labelStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
                elevation: 8,
                child: const Icon(Icons.playlist_add, color: Colors.white),
                label: '할 일 추가',
                onTap: () async {
                  HapticFeedback.lightImpact();
                  await Navigator.push(
                    context,
                    PageRouteBuilder(
                      transitionDuration: const Duration(milliseconds: 500),
                      pageBuilder: (_, __, ___) => const AddScreen(),
                      transitionsBuilder: (_, animation, __, child) =>
                          FadeTransition(opacity: animation, child: child),
                    ),
                  );
                  viewModel.refresh();
                },
              ),

              // 🔷 정렬 옵션
              SpeedDialChild(
                backgroundColor: Colors.white.withOpacity(0.15),
                labelBackgroundColor: Colors.black.withOpacity(0.6),
                labelStyle: const TextStyle(color: Colors.white),
                child: const Icon(Icons.sort, color: Colors.white),
                label: '정렬 옵션',
                onTap: () {
                  HapticFeedback.lightImpact();
                  _showSortOptions(viewModel);
                },
              ),

              // 🧡 메모장
              SpeedDialChild(
                backgroundColor: Colors.white.withOpacity(0.15),
                labelBackgroundColor: Colors.black.withOpacity(0.6),
                labelStyle: const TextStyle(color: Colors.white),
                child: const Icon(Icons.note_alt_outlined, color: Colors.white),
                label: '메모장',
                onTap: () {
                  HapticFeedback.lightImpact();
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

              // ⭐ 즐겨찾기 필터
              SpeedDialChild(
                backgroundColor: Colors.white.withOpacity(0.15),
                labelBackgroundColor: Colors.black.withOpacity(0.6),
                labelStyle: const TextStyle(color: Colors.white),
                child: Icon(
                  viewModel.showOnlyFavorites ? Icons.star : Icons.star_border,
                  color: Colors.yellowAccent,
                ),
                label: '즐겨찾기 필터',
                onTap: () {
                  HapticFeedback.lightImpact();
                  viewModel.toggleFavoriteFilter();
                },
              ),

              // ❌ 전체 삭제
              SpeedDialChild(
                backgroundColor: Colors.redAccent.withOpacity(0.25),
                labelBackgroundColor: Colors.black.withOpacity(0.6),
                labelStyle: const TextStyle(color: Colors.white),
                child: const Icon(Icons.delete_forever, color: Colors.redAccent),
                label: '전체 삭제',
                onTap: () async {
                  HapticFeedback.mediumImpact();
                  final shouldDeleteAll = await _showConfirmDialog(
                    title: '전체 삭제',
                    content: '모든 할 일을 삭제하시겠습니까?',
                  );
                  if (shouldDeleteAll) viewModel.clearAllTodos();
                },
              ),

              // 🌙 다크모드 전환
              SpeedDialChild(
                backgroundColor: Colors.deepPurple.withOpacity(0.3),
                labelBackgroundColor: Colors.black.withOpacity(0.6),
                labelStyle: const TextStyle(color: Colors.white),
                child: Icon(
                  isDarkMode ? Icons.light_mode : Icons.dark_mode,
                  color: Colors.white,
                ),
                label: '다크모드 전환',
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => isDarkMode = !isDarkMode);
                },
              ),

              // ℹ️ 앱 정보
              SpeedDialChild(
                backgroundColor: Colors.indigo.withOpacity(0.3),
                labelBackgroundColor: Colors.black.withOpacity(0.6),
                labelStyle: const TextStyle(color: Colors.white),
                child: const Icon(Icons.info_outline, color: Colors.white),
                label: '앱 정보',
                onTap: () {
                  HapticFeedback.lightImpact();
                  _showAboutDialog();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ListViewModel>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      appBar: AppBar(
        title: Hero(
          tag: 'app_title',
          child: Material(
            color: Colors.transparent,
            child: Text(
              'TodoList',
              style: GoogleFonts.montserrat(
                color: Colors.blue,
                fontWeight: FontWeight.bold,
                fontSize: 24,
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

  /// 진행률 바 (percent_indicator)
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
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  /// 할 일 리스트 (Slidable + Animation)
  Widget _buildTodoList(ListViewModel viewModel) {
    if (viewModel.filteredTodos.isEmpty) {
      return const Expanded(
        child: Center(
          child: Text(
            '할 일이 없습니다.',
            style: TextStyle(color: Colors.red, fontSize: 18),
          ),
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

            final textColor = todo.isDone
                ? Colors.red
                : (isDarkMode ? Colors.white : Colors.black);

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
                              content: "정말 이 항목을 삭제하시겠습니까?",
                            );
                            if (shouldDelete) viewModel.deleteTodo(todo);
                          },
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          icon: Icons.delete,
                          label: '삭제',
                        ),
                        SlidableAction(
                          onPressed: (_) {
                            viewModel.toggleFavorite(todo);
                          },
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
                      subtitle: Text(
                        formattedDate,
                        style: textStyle.copyWith(fontSize: 12),
                      ),
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
