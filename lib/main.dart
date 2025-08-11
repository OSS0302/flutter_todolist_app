import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:todolist/model/todo.dart';
import 'package:todolist/model/note.dart';
import 'package:todolist/presentation/list_view_model.dart';
import 'package:todolist/presentation/note/note_view_model.dart';
import 'package:todolist/router/routes.dart';

late final Box<Todo> todos;
late final Box<Note> notes;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  Hive.registerAdapter(TodoAdapter());
  Hive.registerAdapter(NoteAdapter()); // Note 어댑터 등록

  todos = await Hive.openBox<Todo>('todoList.db');
  notes = await Hive.openBox<Note>('noteList.db'); // notes 박스 열기

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
          ChangeNotifierProvider(
            create: (_) => NoteViewModel(todoId: '', todoTitle: '', noteBox: notes),
          ),
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
