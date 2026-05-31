class Habit {
  final int? id;
  final String title;
  final int streak;
  final String? lastCompletedDate; // Stores "2025-12-04"
  Habit({
    this.id,
    required this.title,
    this.streak = 0,
    this.lastCompletedDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'streak': streak,
      'lastCompletedDate': lastCompletedDate,
    };
  }

  factory Habit.fromMap(Map<String, dynamic> map) {
    return Habit(
      id: map['id'],
      title: map['title'],
      streak: map['streak'] ?? 0,
      lastCompletedDate: map['lastCompletedDate'],
    );
  }
}