import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:intl/intl.dart';
import 'package:todolist/main.dart'; // todos 사용을 위한 임포트

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final total = todos.length;
    final completed = todos.values.where((t) => t.isDone).length;
    final percent = total == 0 ? 0.0 : completed / total;

    final now = DateTime.now();
    final todayTodos = todos.values.where((t) {
      final d = t.dueDate;
      return d != null &&
          d.year == now.year &&
          d.month == now.month &&
          d.day == now.day;
    }).length;

    final priorityCount = {'high': 0, 'medium': 0, 'low': 0};
    for (final t in todos.values) {
      final p = t.priority ?? 'low';
      priorityCount[p] = (priorityCount[p] ?? 0) + 1;
    }

    final recentDone = todos.values
        .where((t) => t.isDone)
        .toList()
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
    final latestCompleted = recentDone.take(3).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('📊 통계'),
        centerTitle: true,
        backgroundColor: Colors.blueGrey[900],
      ),
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            children: [
              CircularPercentIndicator(
                radius: 100,
                lineWidth: 16,
                animation: true,
                percent: percent,
                center: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${(percent * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold),
                    ),
                    if (percent == 1.0)
                      const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Text('🎉 완벽해요!',
                            style: TextStyle(color: Colors.greenAccent)),
                      ),
                    if (percent >= 0.8 && percent < 1.0)
                      const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Text('🔥 목표치 도달! 계속 유지해요!',
                            style: TextStyle(color: Colors.orangeAccent)),
                      ),
                  ],
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
              _buildTodayBox(todayTodos),
              _buildWeeklyMonthlySummary(),
              _buildTextTrendAnalysis(),
              const Divider(color: Colors.white24),
              const SizedBox(height: 16),
              const Text('우선순위 분포',
                  style: TextStyle(color: Colors.white70, fontSize: 18)),
              const SizedBox(height: 12),
              if (priorityCount.values.every((c) => c == 0))
                const Text('우선순위가 설정된 할 일이 없습니다.',
                    style: TextStyle(color: Colors.white38)),
              if (priorityCount.values.any((c) => c > 0)) ...[
                _buildPriorityRow('🔴 높음', priorityCount['high']!, Colors.red),
                _buildPriorityRow('🟠 보통', priorityCount['medium']!, Colors.orange),
                _buildPriorityRow('🔵 낮음', priorityCount['low']!, Colors.blue),
              ],
              const SizedBox(height: 24),
              const Divider(color: Colors.white24),
              const SizedBox(height: 16),
              const Text('최근 완료한 항목',
                  style: TextStyle(color: Colors.white70, fontSize: 18)),
              const SizedBox(height: 12),
              if (latestCompleted.isEmpty)
                const Text('아직 완료한 항목이 없어요!',
                    style: TextStyle(color: Colors.white38)),
              ...latestCompleted.map((t) => ListTile(
                title: Text(
                  t.title,
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  '완료일: ${DateFormat('yyyy-MM-dd').format(DateTime.fromMillisecondsSinceEpoch(t.dateTime))}',
                  style: const TextStyle(color: Colors.white54),
                ),
                leading: const Icon(Icons.check_circle,
                    color: Colors.greenAccent),
              )),
              _buildMostProductiveDay(), // 🔥 추가된 부분
            ],
          ),
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

  Widget _buildTodayBox(int count) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          const Icon(Icons.today, color: Colors.cyanAccent),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '오늘 해야 할 일: $count개',
              style: const TextStyle(fontSize: 16, color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityRow(String label, int count, Color color) {
    final total = todos.length;
    final ratio = total == 0 ? 0.0 : count / total;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(label, style: TextStyle(color: color, fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: LinearProgressIndicator(
              value: ratio,
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

  Widget _buildWeeklyMonthlySummary() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startOfMonth = DateTime(now.year, now.month, 1);

    final weeklyCompleted = todos.values.where((t) {
      if (!t.isDone) return false;
      final doneDate = DateTime.fromMillisecondsSinceEpoch(t.dateTime);
      return doneDate.isAfter(startOfWeek.subtract(const Duration(days: 1)));
    }).length;

    final monthlyCompleted = todos.values.where((t) {
      if (!t.isDone) return false;
      final doneDate = DateTime.fromMillisecondsSinceEpoch(t.dateTime);
      return doneDate.isAfter(startOfMonth.subtract(const Duration(days: 1)));
    }).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Text('📅 주간 / 월간 요약',
            style: TextStyle(color: Colors.white70, fontSize: 18)),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildSummaryBox('이번 주', weeklyCompleted),
            _buildSummaryBox('이번 달', monthlyCompleted),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryBox(String label, int count) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          Text('$count개',
              style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.lightBlueAccent)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildTextTrendAnalysis() {
    final now = DateTime.now();
    final past7Days = List.generate(7, (i) => now.subtract(Duration(days: 6 - i)));

    final dailyStats = past7Days.map((date) {
      final count = todos.values.where((t) {
        if (!t.isDone) return false;
        final done = DateTime.fromMillisecondsSinceEpoch(t.dateTime);
        return done.year == date.year &&
            done.month == date.month &&
            done.day == date.day;
      }).length;

      return '${DateFormat('MM/dd (E)', 'ko_KR').format(date)}: $count개 완료';
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Text('📈 최근 7일 완료 트렌드',
            style: TextStyle(color: Colors.white70, fontSize: 18)),
        const SizedBox(height: 12),
        ...dailyStats.map((line) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(line, style: const TextStyle(color: Colors.white60)),
        )),
      ],
    );
  }

  Widget _buildMostProductiveDay() {
    final Map<int, int> weekdayDoneCount = {
      1: 0, // 월
      2: 0,
      3: 0,
      4: 0,
      5: 0,
      6: 0,
      7: 0, // 일
    };

    for (final t in todos.values) {
      if (t.isDone) {
        final doneDate = DateTime.fromMillisecondsSinceEpoch(t.dateTime);
        final weekday = doneDate.weekday;
        weekdayDoneCount[weekday] = (weekdayDoneCount[weekday] ?? 0) + 1;
      }
    }

    if (weekdayDoneCount.values.every((count) => count == 0)) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Text(
          '아직 완료한 항목이 없어 분석할 수 없습니다.',
          style: TextStyle(color: Colors.white38),
        ),
      );
    }

    final maxEntry = weekdayDoneCount.entries.reduce((a, b) => a.value > b.value ? a : b);
    final mostProductiveDay = DateFormat.EEEE('ko_KR')
        .format(DateTime(2024, 1, maxEntry.key + 1)); // 월요일이 1

    return Padding(
      padding: const EdgeInsets.only(top: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🧠 가장 생산적인 요일',
              style: TextStyle(color: Colors.white70, fontSize: 18)),
          const SizedBox(height: 8),
          Text('$mostProductiveDay에 가장 많이 완료했어요!',
              style: const TextStyle(color: Colors.lightGreenAccent, fontSize: 16)),
        ],
      ),
    );
  }
}
