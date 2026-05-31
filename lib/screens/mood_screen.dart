import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For formatting dates
import '../database_helper.dart';
import '../models/mood.dart';

class MoodScreen extends StatefulWidget {
  const MoodScreen({super.key});

  @override
  State<MoodScreen> createState() => _MoodScreenState();
}

class _MoodScreenState extends State<MoodScreen> {
  List<Mood> _moods = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _refreshMoods();
  }

  // 1. Fetch data from the 'moods' table
  Future<void> _refreshMoods() async {
    setState(() => _isLoading = true);
    try {
      final data = await DatabaseHelper.instance.queryAllRows('moods');
      setState(() {
        _moods = data.map((row) => Mood.fromMap(row)).toList();
        // Sort by newest first (reverse order)
        _moods = _moods.reversed.toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading moods: $e");
      setState(() => _isLoading = false);
    }
  }

  // 2. Add Mood Entry
  Future<void> _addMood(String content, int moodRating) async {
    final newEntry = Mood(
      content: content,
      mood: moodRating,
      // Store current time as a String
      date: DateTime.now().toIso8601String(),
    );
    await DatabaseHelper.instance.insert('moods', newEntry.toMap());
    _refreshMoods();
  }

  // 3. Delete Mood Entry
  Future<void> _deleteMood(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('moods', where: 'id = ?', whereArgs: [id]);
    _refreshMoods();
  }

  // 4. Helper to get Emoji based on mood number
  String _getMoodEmoji(int mood) {
    switch (mood) {
      case 1:
        return '😢'; // Sad
      case 2:
        return '😕'; // Confused/Meh
      case 3:
        return '😐'; // Neutral
      case 4:
        return '🙂'; // Good
      case 5:
        return '🤩'; // Amazing
      default:
        return '😐';
    }
  }

  // 5. Show the "Add Mood" Sheet
  void _showAddSheet() {
    final textController = TextEditingController();
    int selectedMood = 3; // Default to Neutral

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allows the sheet to move up with keyboard
      builder: (context) {
        // StatefulBuilder allows the sheet to update itself (changing selected emoji color)
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom, // Adjust for keyboard
                top: 20,
                left: 20,
                right: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('How are you feeling?',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),

                  // Mood Selector Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(5, (index) {
                      int moodValue = index + 1;
                      return IconButton(
                        icon: Text(
                          _getMoodEmoji(moodValue),
                          style: const TextStyle(fontSize: 30),
                        ),
                        // Highlight the selected one with a colored circle
                        style: selectedMood == moodValue
                            ? IconButton.styleFrom(backgroundColor: Colors.teal.shade100)
                            : null,
                        onPressed: () {
                          setSheetState(() => selectedMood = moodValue);
                        },
                      );
                    }),
                  ),

                  const SizedBox(height: 20),
                  TextField(
                    controller: textController,
                    decoration: const InputDecoration(
                      hintText: 'Add a quick note (optional)...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      // Allow empty note, but require mood selection
                      _addMood(textController.text, selectedMood);
                      Navigator.pop(context);
                    },
                    child: const Text('Save Mood'),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Check current theme brightness
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      // 1. Make Scaffold background transparent
      backgroundColor: Colors.transparent,

      floatingActionButton: FloatingActionButton(
        onPressed: _showAddSheet,
        child: const Icon(Icons.add_reaction_outlined),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _moods.isEmpty
          ? const Center(child: Text('How are you feeling today?'))
          : ListView.builder(
        itemCount: _moods.length,
        itemBuilder: (context, index) {
          final moodItem = _moods[index];
          final dateObj = DateTime.parse(moodItem.date);
          // Format date like: "Mon, Oct 24"
          final dateString = DateFormat('EEE, MMM d').format(dateObj);
          // Format time like: "10:30 AM"
          final timeString = DateFormat('jm').format(dateObj);

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            // 2. Adjust Card color for transparency and dark mode compatibility
            color: isDark
                ? Colors.black54
                : Colors.white.withOpacity(0.9),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            _getMoodEmoji(moodItem.mood),
                            style: const TextStyle(fontSize: 28),
                          ),
                          const SizedBox(width: 15),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(dateString,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              Text(timeString,
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete,
                            size: 20, color: Colors.grey),
                        onPressed: () => _deleteMood(moodItem.id!),
                      )
                    ],
                  ),
                  if (moodItem.content.isNotEmpty) ...[
                    const Divider(),
                    Text(moodItem.content,
                        style: const TextStyle(fontSize: 16)),
                  ]
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}