import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database_helper.dart';
import '../models/task.dart';
import '../models/journal.dart'; // <--- 1. Import Journal Model

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  List<Task> _tasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _refreshTasks();
  }

  Future<void> _refreshTasks() async {
    setState(() => _isLoading = true);
    final data = await DatabaseHelper.instance.queryAllRows('tasks');
    setState(() {
      _tasks = data.map((row) => Task.fromMap(row)).toList();
      _isLoading = false;
    });
  }

  Future<void> _addTask(String title, DateTime? deadline) async {
    final newTask = Task(title: title, deadline: deadline);
    await DatabaseHelper.instance.insert('tasks', newTask.toMap());
    _refreshTasks();
  }

  Future<void> _deleteTask(int id) async {
    await DatabaseHelper.instance.delete('tasks', id);
    _refreshTasks();
  }

  Future<void> _toggleTask(Task task) async {
    // Calculate new state
    final bool isNowCompleted = !task.isCompleted;

    final updatedTask = Task(
      id: task.id,
      title: task.title,
      isCompleted: isNowCompleted,
      deadline: task.deadline,
    );

    // Update DB
    await DatabaseHelper.instance.update('tasks', updatedTask.toMap());
    _refreshTasks();

    // <--- 2. Trigger Journal Log Flow if completed --->
    if (isNowCompleted) {
      if (mounted) _askToLogToJournal(task);
    }
  }

  // --- NEW FEATURE LOGIC START ---

  // Step 1: Ask User "Do you want to log this?"
  Future<void> _askToLogToJournal(Task task) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Task Completed!"),
        content: const Text("Would you like to add this achievement to a journal entry?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("No"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close confirmation
              _showJournalSelectionDialog(task); // Open selection
            },
            child: const Text("Yes"),
          ),
        ],
      ),
    );
  }

  // Step 2: Show List of Journals to Pick From
  Future<void> _showJournalSelectionDialog(Task task) async {
    // Fetch journals freshly
    final journalData = await DatabaseHelper.instance.queryAllRows('journals');
    List<Journal> journals = journalData.map((row) => Journal.fromMap(row)).toList();
    // Sort newest first
    journals = journals.reversed.toList();

    if (!mounted) return;

    if (journals.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No journals found to add to!")),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Select Entry"),
          content: SizedBox(
            width: double.maxFinite,
            height: 300, // Limit height
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: journals.length,
              itemBuilder: (context, index) {
                final journal = journals[index];
                final dateStr = DateFormat('MMM d').format(DateTime.parse(journal.date));

                return ListTile(
                  title: Text(journal.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(dateStr),
                  onTap: () {
                    Navigator.pop(context); // Close selection
                    _appendToJournal(journal, task); // Perform update
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  // Step 3: Append text and Update Database
  Future<void> _appendToJournal(Journal journal, Task task) async {
    // Format: Add a new line + the completion text
    // You can customize this string format
    final String appendText = "\n🔥 Completed task: ${task.title}\n";

    final updatedJournal = Journal(
      id: journal.id,
      title: journal.title,
      content: journal.content + appendText,
      date: journal.date,
    );

    await DatabaseHelper.instance.update('journals', updatedJournal.toMap());

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Logged to '${journal.title}'")),
      );
    }
  }
  // --- NEW FEATURE LOGIC END ---

  void _showAddDialog() {
    final textController = TextEditingController();
    DateTime? selectedDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('New Task'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: textController,
                  decoration: const InputDecoration(
                    hintText: 'What needs to be done?',
                    border: OutlineInputBorder(),
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(
                      selectedDate == null
                          ? 'No Deadline'
                          : 'Deadline: ${DateFormat('yyyy-MM-dd').format(selectedDate!)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: const Text('Pick Date'),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setDialogState(() {
                            selectedDate = picked;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (textController.text.isNotEmpty) {
                    _addTask(textController.text, selectedDate);
                    Navigator.pop(context);
                  }
                },
                child: const Text('Add'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _tasks.isEmpty
          ? const Center(child: Text('No tasks yet! Time to bloom.'))
          : ListView.builder(
        itemCount: _tasks.length,
        itemBuilder: (context, index) {
          final task = _tasks[index];

          String? dateText;
          if (task.deadline != null) {
            dateText = DateFormat('yyyy-MM-dd').format(task.deadline!);
          }

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            color: isDark ? Colors.black54 : Colors.white.withOpacity(0.9),
            child: ListTile(
              leading: Checkbox(
                value: task.isCompleted,
                // TRIGGER THE TOGGLE LOGIC HERE
                onChanged: (val) => _toggleTask(task),
                side: BorderSide(
                    color: isDark ? Colors.white70 : Colors.black54,
                    width: 2
                ),
              ),
              title: Text(
                task.title,
                style: TextStyle(
                  decoration: task.isCompleted
                      ? TextDecoration.lineThrough
                      : null,
                  color: task.isCompleted
                      ? Colors.grey
                      : (isDark ? Colors.white : Colors.black),
                ),
              ),
              subtitle: dateText != null
                  ? Row(
                children: [
                  const Icon(Icons.calendar_today, size: 12, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    "Due: $dateText",
                    style: TextStyle(
                      color: task.isCompleted ? Colors.grey : Colors.redAccent,
                      fontSize: 12,
                    ),
                  ),
                ],
              )
                  : null,
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.redAccent),
                onPressed: () => _deleteTask(task.id!),
              ),
            ),
          );
        },
      ),
    );
  }
}