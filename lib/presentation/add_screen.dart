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
              primary: Colors.deepPurpleAccent,
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: Colors.black87,
          ),
          child: child!,
        );
      },
    );
    if (picked != null) vm.setDueDate(picked);
  }

  void _showSuccessDialog(BuildContext context) {
    final confettiController = ConfettiController(duration: const Duration(seconds: 2));
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
            Container(
              width: 300,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: Colors.deepPurpleAccent.withOpacity(0.7),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.deepPurpleAccent.withOpacity(0.6),
                    blurRadius: 20,
                    spreadRadius: 2,
                  )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.celebration, size: 72, color: Colors.amberAccent),
                  SizedBox(height: 16),
                  Text("저장 성공 🎉",
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                  SizedBox(height: 10),
                  Text("할 일이 정상적으로 저장되었습니다.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 15)),
                ],
              ),
            ),
            ConfettiWidget(
              confettiController: confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              colors: [Colors.deepPurple, Colors.amber, Colors.cyanAccent, Colors.pinkAccent],
              numberOfParticles: 30,
            ),
          ],
        ),
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      confettiController.stop();
      if (Navigator.of(context).canPop()) Navigator.of(context).pop();
    });
  }

  void _save(BuildContext context) async {
    final vm = context.read<AddViewModel>();

    if (!vm.isInputValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          content: AwesomeSnackbarContent(
            title: '⚠️ 입력 오류',
            message: '할 일을 입력해주세요!',
            contentType: ContentType.failure,
          ),
        ),
      );
      return;
    }

    await vm.saveTodo();
    _showSuccessDialog(context);

    await Future.delayed(const Duration(milliseconds: 2000));
    final snackBar = SnackBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      content: AwesomeSnackbarContent(
        title: vm.isDueToday() ? '📅 오늘 마감!' : '✅ 저장 완료',
        message: vm.isDueToday() ? "오늘까지 해야 할 일이 추가되었어요!" : "할 일이 정상적으로 저장되었습니다.",
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
                  '✨ 새로운 할 일 추가',
                  textStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                  speed: const Duration(milliseconds: 70),
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
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF141E30), Color(0xFF243B55)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
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
                            const Icon(Icons.edit, color: Colors.deepPurpleAccent, size: 26),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: vm.textController,
                                style: const TextStyle(color: Colors.white, fontSize: 16),
                                maxLength: 100,
                                decoration: InputDecoration(
                                  counterText: "",
                                  hintText: '할 일을 입력하세요...',
                                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2),

                      // 📌 우선순위 선택 (더 고급스럽게 pill 버튼 느낌)
                      GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("우선순위",
                                style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 15,
                              children: [
                                _PriorityChip(
                                  label: "🔥 높음",
                                  isSelected: vm.selectedPriority == "high",
                                  color: Colors.redAccent,
                                  onTap: () => vm.setPriority("high"),
                                ),
                                _PriorityChip(
                                  label: "🌟 보통",
                                  isSelected: vm.selectedPriority == "medium",
                                  color: Colors.amber,
                                  onTap: () => vm.setPriority("medium"),
                                ),
                                _PriorityChip(
                                  label: "🍃 낮음",
                                  isSelected: vm.selectedPriority == "low",
                                  color: Colors.lightGreenAccent,
                                  onTap: () => vm.setPriority("low"),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ).animate().fadeIn(duration: 400.ms, delay: 200.ms).slideX(begin: -0.2),

                      // 📌 마감일 선택
                      GlassCard(
                        child: InkWell(
                          onTap: () => _pickDueDate(context),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, color: Colors.amberAccent, size: 22),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  vm.formattedDueDate,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: vm.isOverdue() ? Colors.redAccent : Colors.white,
                                  ),
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white54),
                            ],
                          ),
                        ),
                      ).animate().fadeIn(duration: 400.ms, delay: 400.ms).slideX(begin: 0.2),

                      const Spacer(),

                      // 📌 저장 버튼 (네온 글로우 효과)
                      Hero(
                        tag: 'save-hero',
                        child: ElevatedButton(
                          onPressed: vm.isInputValid && !vm.isLoading ? () => _save(context) : null,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                          ),
                          child: Ink(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(25),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.deepPurpleAccent.withOpacity(0.7),
                                  blurRadius: 15,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Container(
                              alignment: Alignment.center,
                              child: const Text(
                                "저장하기",
                                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                      ).animate().scale(duration: 400.ms, delay: 600.ms),
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

// 📌 GlassCard (업그레이드된 디자인)
class GlassCard extends StatelessWidget {
  final Widget child;
  const GlassCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 12, offset: const Offset(4, 6)),
        ],
      ),
      child: child,
    );
  }
}

// 📌 Custom PriorityChip (더 세련되게)
class _PriorityChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _PriorityChip({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.black : Colors.white70)),
      selected: isSelected,
      selectedColor: color.withOpacity(0.9),
      backgroundColor: Colors.white.withOpacity(0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      onSelected: (_) => onTap(),
    );
  }
}
