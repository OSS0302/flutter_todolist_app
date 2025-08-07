import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

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

  void _save(BuildContext context) async {
    final vm = context.read<AddViewModel>();

    if (!vm.isInputValid) {
      showDialog(
        context: context,
        builder: (_) => const AlertDialog(
          title: Text('입력 오류'),
          content: Text('할 일을 입력해주세요!'),
          actions: [TextButton(onPressed: null, child: Text('확인'))],
        ),
      );
      return;
    }

    await vm.saveTodo();

    if (vm.isDueToday()) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('⚠️ 오늘 마감!'),
          content: const Text('오늘 마감인 할 일을 추가했어요!'),
          actions: [
            TextButton(
              onPressed: () {
                context.pop(context);
                context.pop(context);
              },
              child: const Text('확인'),
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('저장 완료'),
          content: const Text('할 일이 저장되었습니다!'),
          actions: [
            TextButton(
              onPressed: () => context.push('/'),
              child: const Text('확인'),
            ),
          ],
        ),
      );
    }
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
            title: const Text('📝 할 일 추가하기',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                    colors: [Color(0xFF1A2980), Color(0xFF26D0CE)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(color: Colors.black.withOpacity(0.2)),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // 입력
                      GlassCard(
                        child: TextFormField(
                          controller: vm.textController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: '할 일을 입력하세요',
                            labelStyle: const TextStyle(color: Colors.white70),
                            hintText: '예: 운동하기, 장보기...',
                            hintStyle: const TextStyle(color: Colors.white38),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.05),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      // 우선순위
                      GlassCard(
                        child: DropdownButtonFormField<String>(
                          value: vm.selectedPriority,
                          dropdownColor: Colors.black87,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: '우선순위 선택',
                            labelStyle: TextStyle(color: Colors.white70),
                            border: InputBorder.none,
                          ),
                          items: const [
                            DropdownMenuItem(value: 'high', child: Text('🔥 높음')),
                            DropdownMenuItem(value: 'medium', child: Text('🌟 보통')),
                            DropdownMenuItem(value: 'low', child: Text('🍃 낮음')),
                          ],
                          onChanged: vm.setPriority,
                        ),
                      ),
                      // 마감일
                      GlassCard(
                        child: ListTile(
                          title: const Text('마감일 선택', style: TextStyle(color: Colors.white70)),
                          subtitle: Text(vm.formattedDueDate, style: const TextStyle(color: Colors.white)),
                          trailing: const Icon(Icons.calendar_today, color: Colors.white70),
                          onTap: () => _pickDueDate(context),
                        ),
                      ),
                      const Spacer(),

                      /// ⬇️ Hero 애니메이션이 적용된 저장 버튼과 로딩 인디케이터
                      Hero(
                        tag: 'save-hero',
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: vm.isLoading
                              ? Container(
                            key: const ValueKey('loading'),
                            height: 56,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.lightGreenAccent.withOpacity(0.85),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            alignment: Alignment.center,
                            child: const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                              strokeWidth: 3,
                            ),
                          )
                              : SizedBox(
                            key: const ValueKey('button'),
                            width: double.infinity,
                            height: 56,
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

// 재사용 카드 위젯
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
