import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:todolist/model/todo.dart';
import 'package:todolist/presentation/list_screen.dart';
import 'package:todolist/router/routes.dart';


// 탑레벨
late final Box<Todo> todos;

void main() async {

  await Hive.initFlutter();
  Hive.registerAdapter(TodoAdapter());
  // 로드 하고
  todos = await Hive.openBox<Todo>('todoList.db');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {

    return GestureDetector(
      onTap: (){
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: MaterialApp.router(
        routerConfig: router,
        debugShowCheckedModeBanner: false,
        title: 'Flutter Demo',

        theme: ThemeData(

          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
          useMaterial3: true,
        ),
      ),
    );
  }
}
