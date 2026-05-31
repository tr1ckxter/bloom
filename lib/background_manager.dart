class BackgroundManager {
  static String getBackgroundAsset(bool isDark) {
    // 1. Get the current month
    final int month = DateTime.now().month;
    String season;

    // 2. Determine Season (Northern Hemisphere)
    if (month >= 3 && month <= 5) {
      season = 'spring';
    } else if (month >= 6 && month <= 8) {
      season = 'summer';
    } else if (month >= 9 && month <= 11) {
      season = 'fall';
    } else {
      // Months 12, 1, 2
      season = 'winter';
    }

    // 3. Determine Theme Suffix
    String suffix = isDark ? 'dark' : 'light';

    // 4. Return combined path
    // Example result: 'assets/winter_dark.png'
    return 'assets/${season}_$suffix.png';
  }
}