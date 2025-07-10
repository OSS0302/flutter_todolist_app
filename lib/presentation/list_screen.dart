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
      // AppBar 반투명하게 배경과 조화되도록 설정
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          '📋 ToDo List',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.black.withOpacity(0.4),
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // 배경 이미지
          SizedBox.expand(
            child: Image.asset(
              'assets/main.png',
              fit: BoxFit.cover,
            ),
          ),

          // 블러 효과 (약하게)
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 2.0, sigmaY: 2.0),
            child: Container(
              color: Colors.black.withOpacity(0.3),
            ),
          ),

          // 내용
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: todos.isEmpty
                  ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.inbox, size: 64, color: Colors.white70),
                    SizedBox(height: 12),
                    Text(
                      '할 일이 없습니다!',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '+ 버튼을 눌러 일정을 추가해보세요.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
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
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
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
                            content: const Text('삭제 이후엔 복구할 수 없습니다.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
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
                                      content: const Text('다음 일정을 추가해 주세요.'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.of(context).pop(),
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
        backgroundColor: Colors.blue.shade600,
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddScreen()),
          );
          setState(() {});
        },
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }
}
