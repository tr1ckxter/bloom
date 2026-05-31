import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Add intl package to pubspec.yaml for easier formatting
import '../database_helper.dart';
import '../models/journal.dart';

class JournalEditorScreen extends StatefulWidget {
  final Journal? journal;

  const JournalEditorScreen({super.key, this.journal});

  @override
  State<JournalEditorScreen> createState() => _JournalEditorScreenState();
}

class _JournalEditorScreenState extends State<JournalEditorScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  late String _displayDate; // This handles the visual date

  @override
  void initState() {
    super.initState();
    _initializeEditor();
  }

  void _initializeEditor() {
    // 1. Load existing data
    if (widget.journal != null) {
      _titleController.text = widget.journal!.title;
      _contentController.text = widget.journal!.content;

      // Use the saved date if editing, otherwise use Now
      DateTime parsedDate = DateTime.parse(widget.journal!.date);
      _displayDate = DateFormat('dd • MMM • yyyy').format(parsedDate);
    } else {
      // New Entry: Set today's date
      _displayDate = DateFormat('dd • MMM • yyyy').format(DateTime.now());
    }
  }

  Future<void> _saveJournal() async {
    // Basic validation
    if (_titleController.text.isEmpty && _contentController.text.isEmpty) {
      if (mounted) Navigator.pop(context);
      return;
    }

    final title = _titleController.text.isEmpty ? 'Untitled' : _titleController.text;
    final date = DateTime.now().toIso8601String();

    final journalEntry = Journal(
      id: widget.journal?.id,
      title: title,
      content: _contentController.text, // Content is JUST the user text now
      date: date,
    );

    if (widget.journal == null) {
      await DatabaseHelper.instance.insert('journals', journalEntry.toMap());
    } else {
      await DatabaseHelper.instance.update('journals', journalEntry.toMap());
    }

    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Make background slightly off-white/dark for contrast
      backgroundColor: const Color(0xFF1a1a1a),
      appBar: AppBar(
        backgroundColor: Colors.transparent, // Glass effect
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          TextButton(
            onPressed: _saveJournal,
            child: const Text("DONE", style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title Input
            TextField(
              controller: _titleController,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Title...',
                hintStyle: TextStyle(color: Colors.white24),
                border: InputBorder.none,
              ),
            ),

            const SizedBox(height: 10),

            // Content Input (Grows automatically)
            TextField(
              controller: _contentController,
              style: const TextStyle(fontSize: 18, color: Colors.white70, height: 1.5),
              maxLines: null, // Allows infinite scrolling
              keyboardType: TextInputType.multiline,
              decoration: const InputDecoration(
                hintText: 'How was your day?',
                hintStyle: TextStyle(color: Colors.white24),
                border: InputBorder.none,
              ),
            ),

            const SizedBox(height: 40), // Spacing before the stamp

            // --- THE UN-EDITABLE DATE STAMP ---
            Align(
              alignment: Alignment.bottomRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.orangeAccent.withOpacity(0.5), width: 1.5),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _displayDate, // e.g. 2025 • 12 • 06
                  style: const TextStyle(
                    fontFamily: 'Courier', // Monospace font looks like a timestamp
                    fontSize: 14,
                    color: Colors.orangeAccent,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.0,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20), // Bottom padding
          ],
        ),
      ),
    );
  }
}