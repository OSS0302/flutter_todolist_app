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

  // 📌 마감일 선택
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

  // 📌 알림 시간 선택
  Future<void> _pickReminderTime(BuildContext context) async {
    final vm = context.read<AddViewModel>();
    final picked = await showTimePicker(
      context: context,
      initialTime: vm.reminderTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            timePickerTheme: const TimePickerThemeData(
              backgroundColor: Colors.black87,
              dialHandColor: Colors.deepPurpleAccent,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) vm.setReminderTime(picked);
  }

  // 📌 저장 성공 다이얼로그
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
            Container(
              width: 340,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: Colors.deepPurpleAccent.withOpacity(0.8),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.deepPurpleAccent.withOpacity(0.8),
                    blurRadius: 25,
                    spreadRadius: 2,
                  )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.emoji_events,
                      size: 80, color: Colors.amberAccent),
                  SizedBox(height: 18),
                  Text("저장 성공 ✨",
                      style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  SizedBox(height: 12),
                  Text("할 일이 정상적으로 저장되었습니다.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 15)),
                ],
              ),
            ).animate().scale(duration: 400.ms).fadeIn(),
            ConfettiWidget(
              confettiController: confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              colors: [
                Colors.deepPurple,
                Colors.amber,
                Colors.cyanAccent,
                Colors.pinkAccent
              ],
              numberOfParticles: 35,
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

  // 📌 저장 로직
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
                  '✨ 새로운 할 일 추가',
                  textStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18),
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
                    colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(color: Colors.black.withOpacity(0.25)),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // 📌 할 일 입력
                      GlassCard(
                        child: TextFormField(
                          controller: vm.textController,
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                          maxLength: 100,
                          decoration: InputDecoration(
                            icon: const Icon(Icons.edit,
                                color: Colors.deepPurpleAccent),
                            counterText: "",
                            hintText: '할 일을 입력하세요...',
                            hintStyle:
                            TextStyle(color: Colors.white.withOpacity(0.4)),
                            border: InputBorder.none,
                          ),
                        ),
                      ),

                      // 📌 상세 설명
                      GlassCard(
                        child: TextFormField(
                          controller: vm.detailController,
                          style: const TextStyle(color: Colors.white70, fontSize: 14),
                          maxLines: 3,
                          decoration: const InputDecoration(
                            icon: Icon(Icons.notes, color: Colors.cyanAccent),
                            hintText: '상세 설명을 입력하세요...',
                            hintStyle:
                            TextStyle(color: Colors.white54, fontSize: 14),
                            border: InputBorder.none,
                          ),
                        ),
                      ),

                      // 📌 우선순위
                      GlassCard(
                        child: Wrap(
                          spacing: 15,
                          children: [
                            _PriorityChip(
                              label: "🔥 높음",
                              isSelected: vm.selectedPriority == "high",
                              gradient: const LinearGradient(
                                colors: [Colors.redAccent, Colors.deepOrange],
                              ),
                              onTap: () => vm.setPriority("high"),
                            ),
                            _PriorityChip(
                              label: "🌟 보통",
                              isSelected: vm.selectedPriority == "medium",
                              gradient: const LinearGradient(
                                colors: [Colors.amber, Colors.orangeAccent],
                              ),
                              onTap: () => vm.setPriority("medium"),
                            ),
                            _PriorityChip(
                              label: "🍃 낮음",
                              isSelected: vm.selectedPriority == "low",
                              gradient: const LinearGradient(
                                colors: [Colors.greenAccent, Colors.teal],
                              ),
                              onTap: () => vm.setPriority("low"),
                            ),
                          ],
                        ),
                      ),

                      // 📌 태그 입력
                      GlassCard(
                        child: Row(
                          children: [
                            const Icon(Icons.tag, color: Colors.amberAccent),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: vm.tagController,
                                style: const TextStyle(color: Colors.white),
                                decoration: const InputDecoration(
                                  hintText: '태그 입력 후 Enter',
                                  border: InputBorder.none,
                                  hintStyle:
                                  TextStyle(color: Colors.white54, fontSize: 14),
                                ),
                                onSubmitted: (value) => vm.addTag(),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Wrap(
                        spacing: 8,
                        children: vm.tags
                            .map((tag) => Chip(
                          label: Text(tag),
                          backgroundColor: Colors.white12,
                          labelStyle:
                          const TextStyle(color: Colors.white),
                          deleteIcon: const Icon(Icons.close,
                              color: Colors.white54, size: 16),
                          onDeleted: () => vm.removeTag(tag),
                        ))
                            .toList(),
                      ),

                      // 📌 마감일 + 알림
                      GlassCard(
                        child: Column(
                          children: [
                            ListTile(
                              onTap: () => _pickDueDate(context),
                              leading: const Icon(Icons.calendar_today,
                                  color: Colors.amberAccent),
                              title: Text(
                                vm.formattedDueDate,
                                style: TextStyle(
                                    color: vm.isOverdue()
                                        ? Colors.redAccent
                                        : Colors.white),
                              ),
                              trailing: const Icon(Icons.arrow_forward_ios,
                                  size: 16, color: Colors.white54),
                            ),
                            ListTile(
                              onTap: () => _pickReminderTime(context),
                              leading: const Icon(Icons.alarm,
                                  color: Colors.cyanAccent),
                              title: Text(
                                vm.formattedReminderTime,
                                style: const TextStyle(color: Colors.white),
                              ),
                              trailing: const Icon(Icons.arrow_forward_ios,
                                  size: 16, color: Colors.white54),
                            ),
                          ],
                        ),
                      ),

                      const Spacer(),

                      // 📌 저장 버튼
                      Hero(
                        tag: 'save-hero',
                        child: GestureDetector(
                          onTapDown: (_) => vm.setPressed(true),
                          onTapUp: (_) {
                            vm.setPressed(false);
                            if (vm.isInputValid && !vm.isLoading) _save(context);
                          },
                          child: AnimatedScale(
                            scale: vm.isPressed ? 0.92 : 1.0,
                            duration: const Duration(milliseconds: 150),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 16, horizontal: 32),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF4776E6), Color(0xFF8E54E9)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(25),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.purpleAccent.withOpacity(0.7),
                                    blurRadius: 20,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: const Text(
                                "저장하기",
                                style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                      ),
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

// 📌 GlassCard
class GlassCard extends StatelessWidget {
  final Widget child;
  const GlassCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
              color: Colors.deepPurple.withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(3, 5)),
        ],
      ),
      child: child,
    );
  }
}

// 📌 Custom PriorityChip
class _PriorityChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final LinearGradient gradient;
  final VoidCallback onTap;

  const _PriorityChip({
    required this.label,
    required this.isSelected,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => onTap(),
      child: AnimatedScale(
        scale: isSelected ? 1.08 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: ChoiceChip(
          label: Text(label,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.black : Colors.white70)),
          selected: isSelected,
          selectedColor: Colors.transparent,
          backgroundColor: Colors.white.withOpacity(0.08),
          avatar: isSelected
              ? const Icon(Icons.check, size: 18, color: Colors.black)
              : null,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
              side: isSelected
                  ? BorderSide(color: gradient.colors.first, width: 2)
                  : BorderSide.none),
          onSelected: (_) => onTap(),
          labelPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        )
            .animate(target: isSelected ? 1 : 0)
            .shimmer(duration: 1.seconds, colors: gradient.colors),
      ),
    );
  }
}
