class AppConstants {
  static const String appName = 'Pocket HQ';
  static const String methodChannel = 'com.abik.vaidhya.pocket_hq/native';
  static const String eventChannel = 'com.abik.vaidhya.pocket_hq/events';

  // Default dashboard card order
  static const List<String> defaultCardOrder = [
    'summary',
    'habits',
    'calendar',
    'focus',
    'notes',
    'trips',
  ];

  // Permissions
  static const List<String> requiredPermissions = [
    'android.permission.PACKAGE_USAGE_STATS',
    'android.permission.READ_CALENDAR',
    'android.permission.POST_NOTIFICATIONS',
    'android.permission.SCHEDULE_EXACT_ALARM',
    'android.permission.USE_BIOMETRIC',
    'android.permission.ACCESS_FINE_LOCATION',
  ];
}
