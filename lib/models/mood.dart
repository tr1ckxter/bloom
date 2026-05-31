class Mood {
  final int? id;
  final String content; // Optional: rename to 'note' if it's just a short mood note
  final int mood;       // 1-5 rating
  final String date;

  Mood({this.id, required this.content, required this.mood, required this.date});

  // Convert to Map (for Database)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content': content,
      'mood': mood,
      'date': date,
    };
  }

  // Create from Map (from Database)
  factory Mood.fromMap(Map<String, dynamic> map) {
    return Mood(
      id: map['id'],
      content: map['content'],
      mood: map['mood'],
      date: map['date'],
    );
  }
}