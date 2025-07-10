import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:todolist/main.dart';
import 'package:todolist/presentation/add_screen.dart';
import 'package:todolist/presentation/todo_item.dart';

class ListScreen extends StatefulWidget {
  const ListScreen({super.key});

  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          '📝 ToDo List',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // 🔸 그라데이션 배경
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF2193b0), // 청록
                  Color(0xFF6dd5ed), // 연파랑
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // 🔸 내용 부분
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: todos.isEmpty
                  ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_outline,
                        size: 72, color: Colors.white70),
                    SizedBox(height: 16),
                    Text(
                      '할 일이 없습니다!',
                      style: TextStyle(
                        fontSize: 22,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '+ 버튼을 눌러 추가해보세요!',
                      style: TextStyle(fontSize: 16, color: Colors.white70),
                    ),
                  ],
                ),
              )
                  : ListView.separated(
                itemCount: todos.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final todoE = todos.values.elementAt(index);
                  return Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: TodoItem(
                      todo: todoE,
                      onTapCallBack: (todo) async {
                        todo.isDone = !todo.isDone;
                        await todo.save();
                        setState(() {});
                      },
                      onDelete: (todo) async {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('삭제할까요?'),
                            content:
                            const Text('삭제 이후엔 복구할 수 없습니다.'),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(),
                                child: const Text('취소'),
                              ),
                              TextButton(
                                onPressed: () async {
                                  await todo.delete();
                                  Navigator.of(context).pop();

                                  await showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('삭제되었습니다'),
                                      content:
                                      const Text('다음 일정을 추가해 주세요.'),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(),
                                          child: const Text('확인'),
                                        ),
                                      ],
                                    ),
                                  );

                                  setState(() {});
                                },
                                child: const Text('예'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddScreen()),
          );
          setState(() {});
        },
        child: const Icon(Icons.add, color: Colors.blue, size: 28),
      ),
    );
  }
}
