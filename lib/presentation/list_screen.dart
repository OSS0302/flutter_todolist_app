import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todolist/presentation/add_screen.dart';
import 'package:todolist/presentation/todo_item.dart';
import 'package:todolist/presentation/list_view_model.dart';

class ListScreen extends StatefulWidget {
  const ListScreen({super.key});

  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ListViewModel>().loadTodos();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ListViewModel>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Hero(
          tag: 'app_title',
          child: Material(
            color: Colors.transparent,
            child: Text(
              '🪄 Elegant ToDo',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              viewModel.showOnlyFavorites ? Icons.star : Icons.star_border,
              color: viewModel.showOnlyFavorites ? Colors.amber : Colors.white38,
            ),
            onPressed: () => viewModel.toggleFavoriteFilter(),
          ),
        ],
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
            child: viewModel.isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: TextField(
                    onChanged: (value) => viewModel.setSearchKeyword(value),
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ChoiceChip(
                        label: const Text('전체', style: TextStyle(color: Colors.white)),
                        selected: viewModel.filterStatus == FilterStatus.all,
                        selectedColor: Colors.lightBlue,
                        onSelected: (_) => viewModel.setFilterStatus(FilterStatus.all),
                      ),
                      ChoiceChip(
                        label: const Text('완료', style: TextStyle(color: Colors.white)),
                        selected: viewModel.filterStatus == FilterStatus.done,
                        selectedColor: Colors.green,
                        onSelected: (_) => viewModel.setFilterStatus(FilterStatus.done),
                      ),
                      ChoiceChip(
                        label: const Text('미완료', style: TextStyle(color: Colors.white)),
                        selected: viewModel.filterStatus == FilterStatus.notDone,
                        selectedColor: Colors.redAccent,
                        onSelected: (_) => viewModel.setFilterStatus(FilterStatus.notDone),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: LinearProgressIndicator(
                    value: viewModel.progress,
                    backgroundColor: Colors.white12,
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.lightGreenAccent),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: viewModel.filteredTodos.isEmpty
                      ? const Center(
                    child: Text(
                      '할 일이 없습니다.',
                      style: TextStyle(color: Colors.white70, fontSize: 18),
                    ),
                  )
                      : ListView.builder(
                    controller: _scrollController,
                    itemCount: viewModel.filteredTodos.length,
                    itemBuilder: (context, index) {
                      final todo = viewModel.filteredTodos[index];
                      return TodoItem(
                        todo: todo,
                        onTapCallBack: (todo) => viewModel.toggleDone(todo),
                        onDelete: (todo) => viewModel.deleteTodo(todo),
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
            PageRouteBuilder(
              transitionDuration: const Duration(milliseconds: 600),
              pageBuilder: (context, animation, secondaryAnimation) => FadeTransition(
                opacity: animation,
                child: const AddScreen(),
              ),
            ),
          );
          await viewModel.loadTodos();
        },
        child: const Icon(Icons.add, color: Colors.blueAccent, size: 28),
      ),
    );
  }
}
