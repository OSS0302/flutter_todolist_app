import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:todolist/model/todo.dart';
import 'package:todolist/presentation/list_screen.dart';
import 'package:todolist/presentation/list_view_model.dart';
import 'package:todolist/router/routes.dart';

// 탑레벨
late final Box<Todo> todos;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(TodoAdapter());
  // 박스 열기
  todos = await Hive.openBox<Todo>('todoList.db');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => ListViewModel(todos),
          ),
          // 다른 프로바이더가 있으면 여기에 추가
        ],
        child: MaterialApp.router(
          routerConfig: router,
          debugShowCheckedModeBanner: false,
          title: 'Flutter Demo',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
            useMaterial3: true,
          ),
        ),
      ),
    );
  }
}
