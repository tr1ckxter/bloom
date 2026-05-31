class Task {
  final int? id;
  final String title;
  final bool isCompleted;
  final DateTime? deadline;

  Task({
    this.id,
    required this.title,
    this.isCompleted = false,
    this.deadline,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'isCompleted': isCompleted ? 1 : 0,
      'deadline': deadline?.toIso8601String(),
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      title: map['title'],
      isCompleted: map['isCompleted'] == 1,
      deadline: map['deadline'] != null ? DateTime.parse(map['deadline']) : null,
    );
  }
}