import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:provider/provider.dart';
import 'package:todolist/presentation/add_screen.dart';
import 'package:todolist/presentation/list_view_model.dart';

class ListScreen extends StatefulWidget {
  const ListScreen({Key? key}) : super(key: key);

  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  bool isPressed = false;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ListViewModel>().loadTodos();
    });

    _fadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
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

  // ✅ 삭제 확인 다이얼로그
  Future<bool> _showConfirmDialog(String title, String message) async {
    bool? result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: AlertDialog(
            backgroundColor: Colors.white.withOpacity(0.9),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: Text(title,
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            content: Text(message,
                style: GoogleFonts.notoSans(color: Colors.black87)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("취소"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10))),
                child: const Text("확인"),
              )
            ],
          ),
        );
      },
    );
    return result ?? false;
  }

  // ✅ 세련된 3D Floating Button
  Widget _build3DFAB() {
    const double size = 70;

    return GestureDetector(
      onTapDown: (_) => setState(() => isPressed = true),
      onTapUp: (_) => setState(() => isPressed = false),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const AddScreen(),
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
            gradient: const LinearGradient(
              colors: [Color(0xFF4FACFE), Color(0xFF00F2FE)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.blueAccent.withOpacity(0.6),
                blurRadius: 25,
                offset: const Offset(0, 8),
              )
            ],
          ),
          child: const Icon(Icons.add, color: Colors.white, size: 30),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ListViewModel>();
    final date = DateTime.now();
    final greeting = date.hour < 12
        ? "좋은 아침이에요 ☀️"
        : (date.hour < 18 ? "좋은 오후예요 🌤️" : "좋은 저녁이에요 🌙");

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('TodoList Pro',
            style: GoogleFonts.montserrat(
                fontWeight: FontWeight.bold, fontSize: 24, color: Colors.white)),
        centerTitle: true,
      ),
      floatingActionButton: _build3DFAB(),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Stack(
          children: [
            _buildBlurredBackground(),
            SafeArea(
              child: vm.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    Text(greeting,
                        style: GoogleFonts.poppins(
                            color: Colors.white70, fontSize: 16)),
                    Text(
                      "${date.year}.${date.month}.${date.day}",
                      style: GoogleFonts.poppins(
                          color: Colors.white54, fontSize: 14),
                    ),
                    const SizedBox(height: 10),
                    _buildProgressBar(vm),
                    const SizedBox(height: 10),
                    Expanded(child: _buildTodoList(vm)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlurredBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF000428), Color(0xFF004e92)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }

  Widget _buildProgressBar(ListViewModel vm) {
    return LinearPercentIndicator(
      lineHeight: 10,
      percent: vm.progress,
      animation: true,
      barRadius: const Radius.circular(12),
      backgroundColor: Colors.white24,
      progressColor: Colors.lightGreenAccent,
      center: Text(
        "${(vm.progress * 100).toStringAsFixed(0)}%",
        style: GoogleFonts.roboto(color: Colors.white, fontSize: 12),
      ),
    );
  }

  Widget _buildTodoList(ListViewModel vm) {
    if (vm.filteredTodos.isEmpty) {
      return const Center(
          child: Text("할 일이 없습니다.",
              style: TextStyle(color: Colors.white54, fontSize: 16)));
    }

    return AnimationLimiter(
      child: ListView.builder(
        controller: _scrollController,
        itemCount: vm.filteredTodos.length,
        itemBuilder: (context, index) {
          final todo = vm.filteredTodos[index];
          final date = DateTime.fromMillisecondsSinceEpoch(todo.dateTime);
          final formattedDate = "${date.month}월 ${date.day}일";
          final baseColor = Color(todo.color ?? 0xFF4FACFE);

          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 400),
            child: SlideAnimation(
              verticalOffset: 40,
              child: FadeInAnimation(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16),
                      border:
                      Border.all(color: baseColor.withOpacity(0.4), width: 1),
                      boxShadow: [
                        BoxShadow(
                            color: baseColor.withOpacity(0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 4))
                      ],
                    ),
                    child: Slidable(
                      key: Key(todo.key.toString()),
                      endActionPane: ActionPane(
                        motion: const StretchMotion(),
                        children: [
                          SlidableAction(
                            onPressed: (_) async {
                              final confirm = await _showConfirmDialog(
                                  "삭제 확인", "이 항목을 삭제하시겠습니까?");
                              if (confirm) vm.deleteTodo(todo);
                            },
                            backgroundColor: Colors.redAccent,
                            foregroundColor: Colors.white,
                            icon: Icons.delete,
                            label: '삭제',
                          ),
                          SlidableAction(
                            onPressed: (_) => vm.toggleFavorite(todo),
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
                        leading: Icon(
                          todo.isDone
                              ? Icons.check_circle
                              : Icons.circle_outlined,
                          color:
                          todo.isDone ? Colors.greenAccent : baseColor,
                        ),
                        title: Text(
                          todo.title,
                          style: GoogleFonts.notoSans(
                              color: Colors.white,
                              decoration: todo.isDone
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                              fontWeight: FontWeight.w600,
                              fontSize: 16),
                        ),
                        subtitle: Row(
                          children: [
                            Text(
                              formattedDate,
                              style: GoogleFonts.roboto(
                                  color: Colors.white54, fontSize: 12),
                            ),
                            if (todo.tags != null && todo.tags!.isNotEmpty)
                              ...todo.tags!.map((tag) => Padding(
                                padding:
                                const EdgeInsets.only(left: 6, top: 2),
                                child: Text(
                                  "#$tag",
                                  style: TextStyle(
                                      color: baseColor.withOpacity(0.8),
                                      fontSize: 12),
                                ),
                              ))
                          ],
                        ),
                        onTap: () => vm.toggleDone(todo),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
