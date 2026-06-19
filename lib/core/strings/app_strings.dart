class AppStrings {
  static const String home = 'home';
  static const String schedule = 'schedule';
  static const String news = 'news';
  static const String profile = 'profile';
  static const String appTitle = 'appTitle';

  static const Map<String, String> _en = {
    appTitle: 'Bhitte Patro',
    home: 'Home',
    schedule: 'Schedule',
    news: 'News',
    profile: 'Profile',
  };

  static const Map<String, String> _ne = {
    appTitle: 'भित्ते पात्रो',
    home: 'गृहपृष्ठ',
    schedule: 'कार्यतालिका',
    news: 'समाचार',
    profile: 'प्रोफाइल',
  };

  static String get(String key, String languageCode) {
    if (languageCode == 'ne') {
      return _ne[key] ?? _en[key] ?? '';
    }
    return _en[key] ?? '';
  }
}
