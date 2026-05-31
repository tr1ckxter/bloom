import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database_helper.dart';
import '../models/journal.dart';
import 'journal_editor_screen.dart';

class JournalListScreen extends StatefulWidget {
  const JournalListScreen({super.key});

  @override
  State<JournalListScreen> createState() => _JournalListScreenState();
}

class _JournalListScreenState extends State<JournalListScreen> {
  List<Journal> _journals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _refreshJournals();
  }

  Future<void> _refreshJournals() async {
    setState(() => _isLoading = true);
    final data = await DatabaseHelper.instance.queryAllRows('journals');
    setState(() {
      _journals = data.map((row) => Journal.fromMap(row)).toList();
      _journals = _journals.reversed.toList(); // Newest first
      _isLoading = false;
    });
  }

  Future<void> _deleteJournal(int id) async {
    await DatabaseHelper.instance.delete('journals', id);
    _refreshJournals();
  }

  // Navigate to Editor
  void _openEditor({Journal? journal}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => JournalEditorScreen(journal: journal),
      ),
    );

    // If we saved something, refresh the list
    if (result == true) {
      _refreshJournals();
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Check Theme Brightness
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      // 2. Transparent Background
      backgroundColor: Colors.transparent,

      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEditor(), // Open empty editor
        child: const Icon(Icons.create),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _journals.isEmpty
          ? Center(
        child: Text(
          'No journals yet. Start writing!',
          // Ensure text is visible on the background
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
        ),
      )
          : ListView.builder(
        itemCount: _journals.length,
        itemBuilder: (context, index) {
          final journal = _journals[index];
          final dateString = DateFormat('MMM d, yyyy')
              .format(DateTime.parse(journal.date));

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            // 3. Adaptive Card Color (Semi-transparent)
            color: isDark
                ? Colors.black54
                : Colors.white.withOpacity(0.9),
            child: ListTile(
              title: Text(
                journal.title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  // 4. Adaptive Text Color
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              subtitle: Text(
                journal.content,
                maxLines: 1,
                overflow: TextOverflow.ellipsis, // Show preview of text
                style: TextStyle(
                  // Make subtitle slightly softer
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
              trailing: Text(
                dateString,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              onTap: () => _openEditor(journal: journal), // Open for editing
              onLongPress: () =>
                  _deleteJournal(journal.id!), // Long press to delete
            ),
          );
        },
      ),
    );
  }
}