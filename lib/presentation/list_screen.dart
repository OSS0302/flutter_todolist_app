import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:todolist/main.dart';
import 'package:todolist/presentation/add_screen.dart';
import 'package:todolist/presentation/todo_item.dart';

class ListScreen extends StatefulWidget {
  const ListScreen({super.key});

  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  String _searchKeyword = '';

  Color _getPriorityColor(String? priority) {
    switch (priority) {
      case 'high':
        return Colors.red.withOpacity(0.15);
      case 'medium':
        return Colors.orange.withOpacity(0.15);
      case 'low':
        return Colors.green.withOpacity(0.15);
      default:
        return Colors.white10;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredTodos = todos.values
        .where((todo) => todo.title.contains(_searchKeyword))
        .toList()
      ..sort((a, b) {
        if (a.isDone == b.isDone) {
          return a.dueDate?.compareTo(b.dueDate ?? DateTime.now()) ?? 0;
        }
        return a.isDone ? 1 : -1;
      });

    final completedCount = filteredTodos.where((t) => t.isDone).length;
    final progress = filteredTodos.isEmpty
        ? 0.0
        : completedCount / filteredTodos.length;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('🪄 Elegant ToDo',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F2027), Color(0xFF2C5364)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
            child: Container(color: Colors.black.withOpacity(0.2)),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: TextField(
                    onChanged: (value) => setState(() => _searchKeyword = value),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: '할 일을 검색하세요...',
                      hintStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: Colors.white10,
                      prefixIcon: const Icon(Icons.search, color: Colors.white54),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.white12,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.lightGreenAccent),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: filteredTodos.isEmpty
                      ? const Center(
                    child: Text(
                      '할 일이 없습니다.',
                      style: TextStyle(color: Colors.white70, fontSize: 18),
                    ),
                  )
                      : ListView.builder(
                    itemCount: filteredTodos.length,
                    itemBuilder: (context, index) {
                      final todo = filteredTodos[index];
                      return Dismissible(
                        key: ValueKey(todo.id),
                        background: Container(
                          color: Colors.green,
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.only(left: 24),
                          child: const Icon(Icons.check, color: Colors.white),
                        ),
                        secondaryBackground: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 24),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (direction) async {
                          if (direction == DismissDirection.startToEnd) {
                            todo.isDone = !todo.isDone;
                            await todo.save();
                          } else {
                            await todo.delete();
                            await _showDeleteNotice();
                          }
                          setState(() {});
                        },
                        child: GlassCard(
                          color: _getPriorityColor(todo.priority),
                          child: ListTile(
                            title: Text(
                              todo.title,
                              style: TextStyle(
                                fontSize: 18,
                                color: todo.isDone ? Colors.grey : Colors.white,
                                decoration: todo.isDone
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                              ),
                            ),
                            subtitle: todo.dueDate != null
                                ? Text(
                              '📅 ${DateFormat('yyyy-MM-dd').format(todo.dueDate!)}',
                              style: const TextStyle(color: Colors.white60),
                            )
                                : null,
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                              onPressed: () => _showDeleteDialog(todo),
                            ),
                            onTap: () async {
                              todo.isDone = !todo.isDone;
                              await todo.save();
                              setState(() {});
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddScreen()),
          );
          setState(() {});
        },
        child: const Icon(Icons.add, color: Colors.blueAccent, size: 28),
      ),
    );
  }

  Future<void> _showDeleteDialog(var todo) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('정말 삭제하시겠어요?', style: TextStyle(color: Colors.white)),
        content: const Text('삭제 후 복구할 수 없습니다.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () async {
              await todo.delete();
              Navigator.of(context).pop();
              await _showDeleteNotice();
              setState(() {});
            },
            child: const Text('삭제', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteNotice() async {
    await showDialog(
      context: context,
      builder: (_) => const AlertDialog(
        backgroundColor: Colors.black87,
        title: Text('삭제 완료', style: TextStyle(color: Colors.white)),
        content: Text('할 일이 삭제되었습니다.', style: TextStyle(color: Colors.white70)),
      ),
    );
  }

}

// ✅ 카드 스타일
class GlassCard extends StatelessWidget {
  final Widget child;
  final Color? color;

  const GlassCard({required this.child, this.color, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color ?? Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: child,
    );
  }
}
