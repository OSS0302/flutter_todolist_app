import 'package:flutter/material.dart';

class ListScreen extends StatelessWidget {
  const ListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:  AppBar(
        title: const Text('ToDo List'),
      ),
      body: ListView(
        children: [
          const ListTile(
            title: Text('제목1'),
            subtitle: Text('부제목1'),
          ),
          const ListTile(
            title: Text('제목1'),
            subtitle: Text('부제목1'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {  },
        child: const Icon(Icons.add),

      ),
    );
  }
}
