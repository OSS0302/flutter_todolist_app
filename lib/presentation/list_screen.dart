import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
      appBar: AppBar(
        title: const Text('ToDo List'),
        backgroundColor: Colors.blue,
      ),
      body: Stack(
        children: [
          Container(
            child: Center(
              child: Image.asset(
                'assets/main.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          ListView(
            children: todos.values
                .map(
                  (todoE) => TodoItem(
                    todo: todoE,
                    onTapCallBack: (todo) async {
                      todo.isDone = !todo.isDone;
                      await todo.save();

                      // 저장하고  화면갱신
                      setState(() {});
                    },
                    onDelete: (Todo) async {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('삭제할까요?'),
                          content: const Text('삭제 이후엔 복구할 수 없습니다.'),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: Text(
                                '취소',
                              ),
                            ),
                            TextButton(
                              onPressed: () async {
                                 todoE.delete();
                                 Navigator.of(context).pop();
                                //지우고 화면갱신
                                setState(() {});
                              },
                              child: Text(
                                '예',
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                )
                .toList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddScreen()),
          );
          // 화면 갱신
          setState(() {});
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
