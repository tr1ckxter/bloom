import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'user_prefs.dart';
import 'screens/setup_screen.dart';
import 'screens/tasks_screen.dart';
import 'screens/habits_screen.dart';
import 'screens/mood_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/journal_list_screen.dart';
import 'background_manager.dart';

// 1. Create a global notifier so we can access it from ProfileScreen
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  bool isFirstTime = await UserPrefs.isFirstTime();

  // 2. Load saved theme preference
  bool isDark = await UserPrefs.getCheckTheme();
  themeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;

  runApp(BloomApp(isFirstTime: isFirstTime));
}

class BloomApp extends StatelessWidget {
  final bool isFirstTime;
  const BloomApp({super.key, required this.isFirstTime});

  @override
  Widget build(BuildContext context) {
    // 3. Wrap MaterialApp in ValueListenableBuilder
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentMode, child) {
        return MaterialApp(
          title: 'Bloom',
          debugShowCheckedModeBanner: false,

          // Current Theme Mode (Light, Dark, or System)
          themeMode: currentMode,

          // LIGHT THEME
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.teal, brightness: Brightness.light),
            textTheme: GoogleFonts.latoTextTheme(),
          ),

          // DARK THEME
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.teal,
                brightness: Brightness.dark // Key change here
                ),
            textTheme: GoogleFonts.latoTextTheme(ThemeData.dark().textTheme),
            // Optional: Customize dark app bar specifically if needed
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.black26,
            ),
          ),

          home: isFirstTime ? const SetupScreen() : const HomeScreen(),
        );
      },
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _pages = <Widget>[
    HabitsScreen(),
    TasksScreen(),
    MoodScreen(),
    JournalListScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Check if the app is currently in Dark Mode
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    // Get the correct image path based on Season + Theme
    final String backgroundImage = BackgroundManager.getBackgroundAsset(isDark);

    return Stack(
      children: [
        // 1. Dynamic Background Image
        Positioned.fill(
          child: Image.asset(
            backgroundImage,
            fit: BoxFit.cover,
            // distinct key ensures the image widgets swap cleanly when theme changes
            key: ValueKey(backgroundImage),
          ),
        ),

        // 2. App Content
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: const Text('Bloom'),
            centerTitle: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            foregroundColor: Theme.of(context).colorScheme.onSurface,
          ),
          body: _pages[_selectedIndex],
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: _onItemTapped,
            // Adjust opacity for readability
            backgroundColor:
                Theme.of(context).colorScheme.surface.withOpacity(0.85),
            elevation: 0,
            destinations: const <NavigationDestination>[
              NavigationDestination(icon: Icon(Icons.eco), label: 'Habits'),
              NavigationDestination(
                  icon: Icon(Icons.check_circle_outline), label: 'Tasks'),
              NavigationDestination(icon: Icon(Icons.face), label: 'Mood'),
              NavigationDestination(icon: Icon(Icons.book), label: 'Journal'),
              NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
            ],
          ),
        ),
      ],
    );
  }
}

// For Git Push SS
