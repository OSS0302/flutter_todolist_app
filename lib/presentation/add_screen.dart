import 'package:flutter/material.dart';
import 'package:todolist/main.dart';
import 'package:todolist/model/todo.dart';

class AddScreen extends StatefulWidget {
  const AddScreen({super.key});

  @override
  State<AddScreen> createState() => _AddScreenState();
}

class _AddScreenState extends State<AddScreen> {
  final _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Text('Todo 작성'),
        actions: [
          IconButton(
              onPressed: () async {
                // db에 저장
                todos.add(Todo(
                  title: _textController.text,
                  dateTime: DateTime.now().millisecondsSinceEpoch,
                ));

                // 목록 보이기
                if (mounted) {
                  Navigator.pop(context);
                }
              },
              icon: Icon(Icons.done)),
        ],
      ),
      body:
          Column(
            children: [
              Form(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextFormField(
                    controller: _textController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      hintText: '할일 입력하세요',
                      hintStyle: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                      filled: true,
                      fillColor: Colors.white70,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 5,),
              Divider(thickness: 3,color: Colors.blue,),
              ClipRRect(
                borderRadius: BorderRadius.circular(20.0),
                child: Container(
                  
                  width: MediaQuery.of(context).size.width * 0.8 ,
                  height: MediaQuery.of(context).size.width * 0.8,
                  child: Image.asset('assets/Todo.png'),
                ),
              ),

              SizedBox(height: 5,),
              Divider(thickness: 3,color: Colors.blue,),
              Text('할일 적어두고 잊어버지말자!!!!!',style: TextStyle(fontWeight: FontWeight.bold),)


            ],
          ),



    );
  }
}
