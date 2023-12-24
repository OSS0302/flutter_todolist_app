import 'package:flutter/material.dart';

class AddScreen extends StatelessWidget {
  const AddScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      appBar: AppBar(
        title: Text('Todo 작성'),
        actions: [
          IconButton(onPressed: () {} , icon: Icon(Icons.done)),
        ],
      ),
      body: Form(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextFormField(
             decoration: InputDecoration(
               border: OutlineInputBorder(
                 borderRadius: BorderRadius.circular(16),
               ),
               hintText: '할일 입력하세요',
               hintStyle: TextStyle(color: Colors.grey , fontSize: 16, fontWeight: FontWeight.bold),
               filled: true,
               fillColor: Colors.white70 ,
             ),
          ),
        ),
      ),
    );
  }
}
