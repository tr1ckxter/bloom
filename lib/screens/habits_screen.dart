import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Import this for DateFormat
import '../database_helper.dart';
import '../models/habit.dart';

class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
  List<Habit> _habits = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _refreshHabits();
  }

  // Helper to get today's date (e.g., "2025-12-04")
  String get _todayDate => DateFormat('yyyy-MM-dd').format(DateTime.now());

  // Helper to get yesterday's date
  String get _yesterdayDate => DateFormat('yyyy-MM-dd').format(
    DateTime.now().subtract(const Duration(days: 1)),
  );

  Future<void> _refreshHabits() async {
    setState(() => _isLoading = true);
    try {
      final data = await DatabaseHelper.instance.queryAllRows('habits');
      List<Habit> loadedHabits = data.map((row) => Habit.fromMap(row)).toList();

      // --- LOGIC TO BREAK STREAKS ---
      // We loop through habits. If a habit wasn't done today AND wasn't done yesterday,
      // it means the user skipped a day. We reset streak to 0.

      for (var habit in loadedHabits) {
        if (habit.lastCompletedDate != null) {
          bool isDoneToday = habit.lastCompletedDate == _todayDate;
          bool isDoneYesterday = habit.lastCompletedDate == _yesterdayDate;

          // If not done today AND not done yesterday, the streak is broken.
          if (!isDoneToday && !isDoneYesterday && habit.streak > 0) {
            final resetHabit = Habit(
              id: habit.id,
              title: habit.title,
              streak: 0,
              lastCompletedDate: habit.lastCompletedDate, // Keep date history
            );
            await DatabaseHelper.instance.update('habits', resetHabit.toMap());
          }
        }
      }

      // Reload data after potential resets
      final refreshedData = await DatabaseHelper.instance.queryAllRows('habits');
      setState(() {
        _habits = refreshedData.map((row) => Habit.fromMap(row)).toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading habits: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addHabit(String title) async {
    // New habits start with 0 streak and no date
    final newHabit = Habit(title: title, streak: 0, lastCompletedDate: null);
    await DatabaseHelper.instance.insert('habits', newHabit.toMap());
    _refreshHabits();
  }

  Future<void> _markHabitDone(Habit habit) async {
    // If already done today, do nothing (or you could implement "undo" logic)
    if (habit.lastCompletedDate == _todayDate) return;

    int newStreak = 1; // Default if starting fresh

    // If done yesterday, increment streak
    if (habit.lastCompletedDate == _yesterdayDate) {
      newStreak = habit.streak + 1;
    }
    // If done today (edge case), keep current streak
    else if (habit.lastCompletedDate == _todayDate) {
      newStreak = habit.streak;
    }

    final updatedHabit = Habit(
      id: habit.id,
      title: habit.title,
      streak: newStreak,
      lastCompletedDate: _todayDate, // Mark as done today
    );

    await DatabaseHelper.instance.update(
      'habits',
      updatedHabit.toMap(),
    );
    _refreshHabits();
  }

  Future<void> _deleteHabit(int id) async {
    await DatabaseHelper.instance.delete('habits', id);
    _refreshHabits();
  }

  void _showAddDialog() {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Habit'),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(hintText: 'E.g., Morning Yoga'),
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (textController.text.isNotEmpty) {
                _addHabit(textController.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 1. Check current theme brightness to adjust card colors dynamically
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      // 2. THIS IS THE FIX: Make background transparent to show the image behind it
      backgroundColor: Colors.transparent,

      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        label: const Text('New Habit'),
        icon: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _habits.isEmpty
          ? const Center(child: Text('Start a new streak today!'))
          : Padding(
        padding: const EdgeInsets.all(12.0),
        child: GridView.builder(
          gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1,
          ),
          itemCount: _habits.length,
          itemBuilder: (context, index) {
            final habit = _habits[index];
            final isDoneToday = habit.lastCompletedDate == _todayDate;

            return Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              // 3. UPDATED COLOR LOGIC:
              // Use semi-transparent colors so they look good on both Dark & Light backgrounds
              color: isDoneToday
                  ? Colors.teal.withOpacity(isDark ? 0.5 : 0.2)
                  : (isDark ? Colors.black54 : Colors.white.withOpacity(0.9)),

              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      habit.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    // --- STREAK DISPLAY ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("🔥",
                            style: TextStyle(fontSize: 24)),
                        const SizedBox(width: 5),
                        Text(
                          '${habit.streak}',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: isDoneToday
                                ? Colors.orange
                                : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const Text('Streak Days',
                        style: TextStyle(
                            fontSize: 10, color: Colors.grey)),
                    const Spacer(),

                    // --- ACTION BUTTONS ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Mark Done Button
                        Container(
                          decoration: BoxDecoration(
                            color: isDoneToday
                                ? Colors.grey.withOpacity(0.5)
                                : Colors.teal.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: Icon(
                              isDoneToday ? Icons.check : Icons.add,
                              color: isDoneToday
                                  ? Colors.white70
                                  : Colors.teal,
                            ),
                            onPressed: () => _markHabitDone(habit),
                          ),
                        ),
                        const SizedBox(width: 15),
                        // Delete Button
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.redAccent),
                          onPressed: () => _deleteHabit(habit.id!),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}