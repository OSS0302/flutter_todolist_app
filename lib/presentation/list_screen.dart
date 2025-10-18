import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:provider/provider.dart';
import 'package:todolist/presentation/add_screen.dart';
import 'package:todolist/presentation/note/note_screen.dart';
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

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut);
    _fadeController.forward();

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _shimmerController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// 🎨 3D 반사 + 깊이감 FAB
  Widget _build3DPremiumFAB() {
    const double size = 68;

    Widget shimmerEffect(Widget child) {
      return AnimatedBuilder(
        animation: _shimmerController,
        builder: (context, _) {
          final shimmerValue = (_shimmerController.value * 2) - 1;
          return ShaderMask(
            shaderCallback: (rect) {
              return LinearGradient(
                begin: Alignment(-1 + shimmerValue, -1),
                end: Alignment(1 + shimmerValue, 1),
                colors: [
                  Colors.white.withOpacity(0.0),
                  Colors.white.withOpacity(0.25),
                  Colors.white.withOpacity(0.0),
                ],
                stops: const [0.3, 0.5, 0.7],
              ).createShader(rect);
            },
            blendMode: BlendMode.lighten,
            child: child,
          );
        },
      );
    }

    return GestureDetector(
      onTapDown: (_) => setState(() => isPressed = true),
      onTapUp: (_) => setState(() => isPressed = false),
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
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: Colors.white.withOpacity(0.1),
                blurRadius: 6,
                offset: const Offset(-3, -3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(50),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Glass blur background
                BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.35),
                          Colors.white.withOpacity(0.05)
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),

                // Core gradient glow
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(50),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF4FACFE),
                        Color(0xFF00F2FE),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),

                // Reflection highlight (top-left)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(40),
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.35),
                          Colors.white.withOpacity(0.05)
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                ),

                // Shimmer reflection
                Positioned.fill(
                  child: shimmerEffect(Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(50),
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.2),
                          Colors.white.withOpacity(0.05),
                          Colors.transparent,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  )),
                ),

                // Icon
                const Icon(Icons.menu_rounded,
                    color: Colors.white, size: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// SpeedDial 본체


  /// 🌟 iOS 스타일 정렬 옵션 BottomSheet (Glass Blur)
  void _showSortOptions(ListViewModel viewModel) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.3),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
              ),
              child: Wrap(
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: Colors.white54,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  _sortOptionTile(
                    Icons.star,
                    '⭐ 즐겨찾기 우선',
                        () {
                      HapticFeedback.lightImpact();
                      viewModel.todos.sort((a, b) => b.isFavorite ? 1 : -1);
                      viewModel.notifyListeners();
                    },
                  ),
                  _sortOptionTile(
                    Icons.access_time,
                    '⏰ 마감일순',
                        () {
                      HapticFeedback.lightImpact();
                      viewModel.todos.sort((a, b) {
                        return (a.dueDate ?? DateTime.now())
                            .compareTo(b.dueDate ?? DateTime.now());
                      });
                      viewModel.notifyListeners();
                    },
                  ),
                  _sortOptionTile(
                    Icons.done_all,
                    '✅ 완료 항목 우선',
                        () {
                      HapticFeedback.lightImpact();
                      viewModel.todos.sort((a, b) => b.isDone ? 1 : -1);
                      viewModel.notifyListeners();
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  ListTile _sortOptionTile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.blueAccent),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }

  /// ℹ️ iOS 스타일 앱 정보 다이얼로그
  void _showAboutDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (_, __, ___) {
        return Center(
          child: ScaleTransition(
            scale: CurvedAnimation(
              parent: _fadeController,
              curve: Curves.easeInOutBack,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                child: Container(
                  width: 320,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    border: Border.all(color: Colors.white30, width: 1.5),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 25,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle, color: Colors.lightBlueAccent, size: 48),
                      const SizedBox(height: 16),
                      const Text(
                        "TodoList Pro",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        "v3.1.0",
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "세련된 Flutter Todo 앱입니다.\n3D FAB + Shimmer + iOS Blur 효과 적용.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, height: 1.4),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                          child: Text("확인", style: TextStyle(fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
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

  /// 🔽 정렬 옵션 BottomSheet
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
      leading: Icon(icon, color: Colors.blueAccent),
      title: Text(title),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }

  /// ℹ️ 앱 정보 다이얼로그
  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: "TodoList Pro",
      applicationVersion: "v3.0.0",
      applicationIcon: const Icon(Icons.check_circle, color: Colors.blueAccent),
      children: [
        const Text("세련된 프리미엄 TodoList 앱입니다.\nFlutter 3D FAB & Shimmer 효과 적용."),
      ],
    );
  }


  SpeedDialChild _buildDialChild({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SpeedDialChild(
      backgroundColor: Colors.white.withOpacity(0.1),
      labelBackgroundColor: Colors.black.withOpacity(0.6),
      labelStyle: const TextStyle(color: Colors.white),
      child: Icon(icon, color: color),
      label: label,
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
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

