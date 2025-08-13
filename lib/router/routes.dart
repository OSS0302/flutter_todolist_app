import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:todolist/presentation/add_screen.dart';
import 'package:todolist/presentation/list_screen.dart';
import 'package:todolist/presentation/note/note_view_model.dart';

import '../model/note.dart';
import '../presentation/note/note_screen.dart';
import '../presentation/stats_screen.dart';

final router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const ListScreen(),
    ),
    GoRoute(
      path: '/addScreen',
      builder: (context, state) => const AddScreen(),
    ),
    GoRoute(
      path: '/statsScreen',
      builder: (context, state) => const StatsScreen(),
    ),
    GoRoute(
      path: '/noteScreen/:todoId/:todoTitle',
      builder: (context, state) {
        final todoId = state.pathParameters['todoId']!;
        final todoTitle = Uri.decodeComponent(state.pathParameters['todoTitle']!);
        Box<Note> noteBox = Hive.box<Note>('noteList.db');
        return ChangeNotifierProvider(

          create: (_) => NoteViewModel(todoId: todoId, todoTitle: todoTitle, noteBox: noteBox)..loadNotes(),
          child: NoteScreen(todoId: todoId, todoTitle: todoTitle),  // const 제거
        );
      },
    ),
  ],
);
