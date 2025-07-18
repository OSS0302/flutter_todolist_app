import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:todolist/main.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final total = todos.length;
    final completed = todos.values.where((t) => t.isDone).length;
    final percent = total == 0 ? 0.0 : completed / total;

    final priorityCount = {1: 0, 2: 0, 3: 0};
    for (final t in todos.values) {
      final int p = (t.priority ?? 3) as int;
      priorityCount[p] = (priorityCount[p] ?? 0) + 1;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('📊 통계'),
        centerTitle: true,
        backgroundColor: Colors.blueGrey[900],
      ),
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CircularPercentIndicator(
              radius: 100,
              lineWidth: 16,
              animation: true,
              percent: percent,
              center: Text(
                '${(percent * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                    color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
              ),
              circularStrokeCap: CircularStrokeCap.round,
              progressColor: Colors.lightGreenAccent,
              backgroundColor: Colors.white10,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatBox('전체', total, Colors.white),
                _buildStatBox('완료', completed, Colors.greenAccent),
                _buildStatBox('미완료', total - completed, Colors.redAccent),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(color: Colors.white24),
            const SizedBox(height: 16),
            const Text('우선순위 분포',
                style: TextStyle(color: Colors.white70, fontSize: 18)),
            const SizedBox(height: 12),
            _buildPriorityRow('🔴 높은', priorityCount[1] ?? 0, Colors.red),
            _buildPriorityRow('🟠 보통', priorityCount[2] ?? 0, Colors.orange),
            _buildPriorityRow('🔵 낮음', priorityCount[3] ?? 0, Colors.blue),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBox(String label, int count, Color color) {
    return Column(
      children: [
        Text('$count',
            style: TextStyle(fontSize: 28, color: color, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white70)),
      ],
    );
  }

  Widget _buildPriorityRow(String label, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(label, style: TextStyle(color: color, fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: LinearProgressIndicator(
              value: count == 0 ? 0 : count / (todos.length == 0 ? 1 : todos.length),
              color: color,
              backgroundColor: Colors.white10,
              minHeight: 8,
            ),
          ),
          const SizedBox(width: 8),
          Text('$count개', style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}
