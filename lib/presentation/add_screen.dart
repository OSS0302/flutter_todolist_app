import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:confetti/confetti.dart';

import 'add_view_model.dart';

class AddScreen extends StatelessWidget {
  const AddScreen({super.key});

  Future<void> _pickDueDate(BuildContext context) async {
    final vm = context.read<AddViewModel>();
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: vm.selectedDueDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.tealAccent,
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: Colors.black87,
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      vm.setDueDate(picked);
    }
  }

  /// ✅ 세련된 저장 성공 다이얼로그 + Confetti 효과
  void _showSuccessDialog(BuildContext context) {
    final confettiController =
    ConfettiController(duration: const Duration(seconds: 2));

    confettiController.play();

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (_, __, ___) => Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Glass Dialog
            Container(
              width: 260,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.check_circle,
                      size: 64, color: Colors.lightGreenAccent),
                  SizedBox(height: 16),
                  Text(
                    "저장 성공!",
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "할 일이 정상적으로 저장되었습니다.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),

            // 🎉 Confetti 애니메이션
            ConfettiWidget(
              confettiController: confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                Colors.greenAccent,
                Colors.pinkAccent,
                Colors.amber,
                Colors.cyan,
              ],
              numberOfParticles: 25,
            ),
          ],
        ),
      ),
    );

    // 자동 닫기
    Future.delayed(const Duration(seconds: 2), () {
      confettiController.stop();
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    });
  }

  void _save(BuildContext context) async {
    final vm = context.read<AddViewModel>();

    if (!vm.isInputValid) {
      final snackBar = SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        content: AwesomeSnackbarContent(
          title: '⚠️ 입력 오류',
          message: '할 일을 입력해주세요!',
          contentType: ContentType.failure,
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
      return;
    }

    await vm.saveTodo();

    // ✅ Confetti GlassDialog 실행
    _showSuccessDialog(context);

    await Future.delayed(const Duration(milliseconds: 2000));

    final snackBar = SnackBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      content: AwesomeSnackbarContent(
        title: vm.isDueToday() ? '📅 오늘 마감!' : '✅ 저장 완료',
        message: vm.isDueToday()
            ? "오늘까지 해야 할 일이 추가되었어요!"
            : "할 일이 정상적으로 저장되었습니다.",
        contentType: vm.isDueToday() ? ContentType.warning : ContentType.success,
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);

    await Future.delayed(const Duration(milliseconds: 400));
    if (context.mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AddViewModel(),
      builder: (context, _) {
        final vm = context.watch<AddViewModel>();

        return Scaffold(
          extendBodyBehindAppBar: true,
          backgroundColor: Colors.black,
          appBar: AppBar(
            title: AnimatedTextKit(
              animatedTexts: [
                TypewriterAnimatedText(
                  '📝 새로운 할 일 추가하기',
                  textStyle: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                  speed: const Duration(milliseconds: 80),
                ),
              ],
              totalRepeatCount: 1,
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Stack(
            children: [
              // 🔥 배경 그라데이션 + 블러
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1A2980), Color(0xFF26D0CE)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(color: Colors.black.withOpacity(0.25)),
              ),

              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // 📌 할 일 입력
                      GlassCard(
                        child: Row(
                          children: [
                            const Icon(Icons.edit_note,
                                color: Colors.tealAccent, size: 26),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: vm.textController,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 16),
                                maxLength: 100,
                                decoration: InputDecoration(
                                  counterText: "",
                                  hintText: '할 일을 입력하세요...',
                                  hintStyle: TextStyle(
                                      color: Colors.white.withOpacity(0.4)),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                          .animate()
                          .fadeIn(duration: 400.ms)
                          .slideY(begin: 0.2),

                      // 📌 우선순위 선택
                      GlassCard(
                        child: DropdownButtonFormField<String>(
                          value: vm.selectedPriority,
                          dropdownColor: Colors.black87,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            labelText: "우선순위",
                            labelStyle: TextStyle(color: Colors.white70),
                          ),
                          items: const [
                            DropdownMenuItem(
                                value: 'high', child: Text('🔥 높음')),
                            DropdownMenuItem(
                                value: 'medium', child: Text('🌟 보통')),
                            DropdownMenuItem(
                                value: 'low', child: Text('🍃 낮음')),
                          ],
                          onChanged: (val) => vm.setPriority(val),
                        ),
                      )
                          .animate()
                          .fadeIn(duration: 400.ms, delay: 200.ms)
                          .slideX(begin: -0.2),

                      // 📌 마감일 선택
                      GlassCard(
                        child: InkWell(
                          onTap: () => _pickDueDate(context),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today,
                                  color: Colors.pinkAccent, size: 22),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  vm.formattedDueDate,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: vm.isOverdue()
                                        ? Colors.redAccent
                                        : Colors.white,
                                  ),
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios,
                                  size: 16, color: Colors.white54),
                            ],
                          ),
                        ),
                      )
                          .animate()
                          .fadeIn(duration: 400.ms, delay: 400.ms)
                          .slideX(begin: 0.2),

                      // 📌 저장 버튼
                      const Spacer(),
                      Hero(
                        tag: 'save-hero',
                        child: ElevatedButton.icon(
                          onPressed: vm.isInputValid && !vm.isLoading
                              ? () => _save(context)
                              : null,
                          icon: const Icon(Icons.save),
                          label: const Text('저장하기'),
                          style: ElevatedButton.styleFrom(
                            textStyle: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                            backgroundColor: vm.isInputValid
                                ? Colors.lightGreenAccent.withOpacity(0.85)
                                : Colors.grey.shade700,
                            foregroundColor: Colors.black,
                            disabledBackgroundColor: Colors.grey.shade800,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      )
                          .animate()
                          .scale(duration: 400.ms, delay: 600.ms),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// 재사용 GlassCard 위젯
class GlassCard extends StatelessWidget {
  final Widget child;
  final Color? color;

  const GlassCard({super.key, required this.child, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color ?? Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: child,
    );
  }
}
