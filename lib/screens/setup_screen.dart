import 'package:flutter/material.dart';
import '../user_prefs.dart';
import '../main.dart'; // Import main to access HomeScreen

class SetupScreen extends StatelessWidget {
  const SetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final nameController = TextEditingController();

    return Scaffold(
      backgroundColor: Colors.teal.shade50,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.spa, size: 80, color: Colors.teal),
            const SizedBox(height: 20),
            const Text(
              'Welcome to Bloom',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.teal),
            ),
            const SizedBox(height: 10),
            const Text(
              'Let\'s get to know you. What should we call you?',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: nameController,
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                hintText: 'Your Name',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                if (nameController.text.isNotEmpty) {
                  // 1. Save the name & mark first time as false
                  await UserPrefs.saveUser(nameController.text);

                  // 2. Navigate to Home and remove this screen from history
                  // (So pressing "Back" doesn't take them back to registration)
                  if (context.mounted) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const HomeScreen()),
                    );
                  }
                }
              },
              child: const Text('Start Blooming'),
            ),
          ],
        ),
      ),
    );
  }
}