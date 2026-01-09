/// Application-wide constants
class AppConstants {
  AppConstants._();

  // App information
  static const String appName = "What's My Share";
  static const String appTagline = 'Split bills with friends';

  // Date formats
  static const String dateFormatShort = 'dd/MM/yyyy';
  static const String dateFormatLong = 'dd MMMM yyyy';
  static const String dateFormatWithTime = 'dd/MM/yyyy HH:mm';
  static const String timeFormat = 'HH:mm';

  // Animation durations
  static const Duration animationDurationShort = Duration(milliseconds: 200);
  static const Duration animationDurationMedium = Duration(milliseconds: 300);
  static const Duration animationDurationLong = Duration(milliseconds: 500);

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 50;

  // Validation
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 128;
  static const int minNameLength = 2;
  static const int maxNameLength = 50;
  static const int maxDescriptionLength = 500;
  static const int maxNoteLength = 1000;

  // Image constraints
  static const int maxImageSizeBytes = 5 * 1024 * 1024; // 5 MB
  static const int maxImageWidth = 1920;
  static const int maxImageHeight = 1920;
  static const int thumbnailSize = 200;

  // Voice note constraints
  static const int maxVoiceNoteDurationSeconds = 120; // 2 minutes

  // Local storage keys
  static const String keyUserId = 'user_id';
  static const String keyAuthToken = 'auth_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyUserPreferences = 'user_preferences';
  static const String keyOnboardingComplete = 'onboarding_complete';
  static const String keyLastSyncTime = 'last_sync_time';
  static const String keyThemeMode = 'theme_mode';
  static const String keyLocale = 'locale';

  // Hive box names
  static const String boxSettings = 'settings';
  static const String boxOfflineQueue = 'offline_queue';
  static const String boxCache = 'cache';

  // Currency - India only app, INR is the only supported currency
  static const String currency = 'INR';
  static const String currencySymbol = '₹';
  static const String locale = 'en_IN';
  static const String timezone = 'Asia/Kolkata';
  static const String countryCode = '+91';

  // Region
  static const String defaultLocale = 'en-IN';
  static const String defaultTimezone = 'Asia/Kolkata';
  static const String defaultCountryCode = 'IN';

  // Thresholds
  static const int biometricThresholdPaisa = 500000; // ₹5,000
  static const int maxExpenseAmountPaisa = 10000000; // ₹1,00,000
  static const int maxGroupMembers = 50;

  // Firestore collections
  static const String usersCollection = 'users';
  static const String groupsCollection = 'groups';
  static const String expensesCollection = 'expenses';
  static const String settlementsCollection = 'settlements';
  static const String activityCollection = 'activity';
  static const String notificationsCollection = 'notifications';
  static const String invitationsCollection = 'invitations';
  static const String metadataCollection = 'metadata';
  static const String friendsCollection = 'friends';
  static const String chatCollection = 'chat';
}

/// Expense category definitions
class ExpenseCategories {
  ExpenseCategories._();

  static const String food = 'food';
  static const String transport = 'transport';
  static const String accommodation = 'accommodation';
  static const String shopping = 'shopping';
  static const String entertainment = 'entertainment';
  static const String utilities = 'utilities';
  static const String groceries = 'groceries';
  static const String health = 'health';
  static const String education = 'education';
  static const String other = 'other';

  static const List<String> all = [
    food,
    transport,
    accommodation,
    shopping,
    entertainment,
    utilities,
    groceries,
    health,
    education,
    other,
  ];

  static String getDisplayName(String category) {
    switch (category) {
      case food:
        return 'Food & Drinks';
      case transport:
        return 'Transport';
      case accommodation:
        return 'Accommodation';
      case shopping:
        return 'Shopping';
      case entertainment:
        return 'Entertainment';
      case utilities:
        return 'Utilities';
      case groceries:
        return 'Groceries';
      case health:
        return 'Health';
      case education:
        return 'Education';
      case other:
      default:
        return 'Other';
    }
  }

  static String getIcon(String category) {
    switch (category) {
      case food:
        return '🍕';
      case transport:
        return '🚗';
      case accommodation:
        return '🏨';
      case shopping:
        return '🛍️';
      case entertainment:
        return '🎬';
      case utilities:
        return '💡';
      case groceries:
        return '🛒';
      case health:
        return '💊';
      case education:
        return '📚';
      case other:
      default:
        return '📝';
    }
  }
}

/// Group type definitions
class GroupTypes {
  GroupTypes._();

  static const String trip = 'trip';
  static const String home = 'home';
  static const String couple = 'couple';
  static const String other = 'other';

  static const List<String> all = [trip, home, couple, other];

  static String getDisplayName(String type) {
    switch (type) {
      case trip:
        return 'Trip';
      case home:
        return 'Home';
      case couple:
        return 'Couple';
      case other:
      default:
        return 'Other';
    }
  }

  static String getIcon(String type) {
    switch (type) {
      case trip:
        return '✈️';
      case home:
        return '🏠';
      case couple:
        return '💑';
      case other:
      default:
        return '👥';
    }
  }
}

/// Split type definitions
class SplitTypes {
  SplitTypes._();

  static const String equal = 'equal';
  static const String exact = 'exact';
  static const String percentage = 'percentage';
  static const String shares = 'shares';

  static const List<String> all = [equal, exact, percentage, shares];

  static String getDisplayName(String type) {
    switch (type) {
      case equal:
        return 'Equal';
      case exact:
        return 'Exact amounts';
      case percentage:
        return 'By percentage';
      case shares:
        return 'By shares';
      default:
        return 'Equal';
    }
  }
}

/// Payment method definitions
class PaymentMethods {
  PaymentMethods._();

  static const String cash = 'cash';
  static const String upi = 'upi';
  static const String bankTransfer = 'bank_transfer';
  static const String other = 'other';

  static const List<String> all = [cash, upi, bankTransfer, other];

  static String getDisplayName(String method) {
    switch (method) {
      case cash:
        return 'Cash';
      case upi:
        return 'UPI';
      case bankTransfer:
        return 'Bank Transfer';
      case other:
      default:
        return 'Other';
    }
  }
}
