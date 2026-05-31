import 'package:flutter/material.dart';
import '../user_prefs.dart';
import '../main.dart'; // Import this to access 'themeNotifier'

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _userName = '';

  @override
  void initState() {
    super.initState();
    _loadName();
  }

  Future<void> _loadName() async {
    final name = await UserPrefs.getUserName();
    setState(() {
      _userName = name ?? 'User';
    });
  }

  @override
  Widget build(BuildContext context) {
    // Check if current mode is dark for the switch status
    final isDarkMode = themeNotifier.value == ThemeMode.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: const Icon(Icons.person, size: 50, color: Colors.white),
          ),
          const SizedBox(height: 20),
          Text(
            'Hello, $_userName!',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text('Keep blooming every day.', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 40),

          // APP SETTINGS LIST
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              children: [
                // Dark Mode Switch
                SwitchListTile(
                  secondary: const Icon(Icons.dark_mode),
                  title: const Text('Dark Mode'),
                  value: isDarkMode,
                  onChanged: (val) {
                    // 1. Update the Global Notifier (Updates UI instantly)
                    themeNotifier.value = val ? ThemeMode.dark : ThemeMode.light;
                    // 2. Save to Prefs (Persists on restart)
                    UserPrefs.setCheckTheme(val);
                  },
                ),
                const Divider(),
                // Placeholder for other settings
                ListTile(
                  leading: const Icon(Icons.settings),
                  title: const Text('More Settings'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    // Navigate to other settings
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}