import 'package:flutter/material.dart';
import 'package:todolist/main.dart';
import 'package:todolist/model/todo.dart';
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
      ),
      body: ListView(
        children: todos.values
            .map((todoE) => TodoItem(
                  todo: todoE,
                  onTapCallBack: (todo) async {
                    todo.isDone = !todo.isDone;
                    await todo.save();

                    // 화면갱신
                    setState(() {});
                  },
                ))
            .toList(),
      ),
      floatingActionButton: FloatingActionButton(
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
