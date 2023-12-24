import 'package:flutter/material.dart';
import 'package:todolist/model/todo.dart';
import 'package:todolist/presentation/add_screen.dart';

class ListScreen extends StatefulWidget {
  const ListScreen({super.key});

  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  final todos = [
    Todo(
      title: '제목1',
      dateTime: 0923,
    ),
    Todo(
      title: '제목2',
      dateTime: 0924,
    ),
    Todo(
      title: '제목3',
      dateTime: 0925,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ToDo List'),
      ),
      body: ListView(
        children: todos
            .map((todo) => ListTile(
                  title: Text(todo.title),
                  subtitle: Text('${todo.dateTime}'),
                ))
            .toList(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
