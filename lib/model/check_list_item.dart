class ChecklistItem {
  String title;
  bool isChecked;
  String repeat;
  String category;
  bool pinned;
  int createdAt;
  int? completedAt;

  ChecklistItem({
    required this.title,
    this.repeat = 'none',
    this.category = '전체',
    this.pinned = false,
    this.isChecked = false,
    this.completedAt,
    int? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().millisecondsSinceEpoch;

  factory ChecklistItem.fromMap(Map<String, dynamic> m) => ChecklistItem(
    title: m['title'],
    repeat: m['repeat'] ?? 'none',
    category: m['category'] ?? '전체',
    pinned: m['pinned'] ?? false,
    isChecked: m['isChecked'] ?? false,
    completedAt: m['completedAt'],
    createdAt: m['createdAt'],
  );

  Map<String, dynamic> toMap() => {
    'title': title,
    'repeat': repeat,
    'category': category,
    'pinned': pinned,
    'isChecked': isChecked,
    'completedAt': completedAt,
    'createdAt': createdAt,
  };
}
