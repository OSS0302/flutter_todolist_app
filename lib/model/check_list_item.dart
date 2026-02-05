class ChecklistItem {
  int id;
  String title;

  bool isChecked;
  bool pinned;

  String repeat;
  String category;

  int createdAt;

  int streak;
  int? lastCompletedDate;

  ChecklistItem({
    required this.id,
    required this.title,
    this.isChecked = false,
    this.pinned = false,
    this.repeat = 'none',
    this.category = '전체',
    this.streak = 0,
    this.lastCompletedDate,
    int? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().millisecondsSinceEpoch;

  factory ChecklistItem.fromMap(Map<String, dynamic> m) => ChecklistItem(
    id: m['id'],
    title: m['title'],
    isChecked: m['isChecked'] ?? false,
    pinned: m['pinned'] ?? false,
    repeat: m['repeat'] ?? 'none',
    category: m['category'] ?? '전체',
    createdAt: m['createdAt'],
    streak: m['streak'] ?? 0,
    lastCompletedDate: m['lastCompletedDate'],
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'isChecked': isChecked,
    'pinned': pinned,
    'repeat': repeat,
    'category': category,
    'createdAt': createdAt,
    'streak': streak,
    'lastCompletedDate': lastCompletedDate,
  };
}
