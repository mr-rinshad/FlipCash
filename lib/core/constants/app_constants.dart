class AppConstants {
  static const String appName = 'FlipCash';
  static const String appTagline = 'P2P Cash & Digital Currency Exchange';
  static const String appVersion = 'v1.0.0';

  // Currency
  static const String currencySymbol = '₹';
  static const String currencyCode = 'INR';

  // Default coordinates (Bengaluru tech corridor for realistic testing)
  static const double defaultLatitude = 12.9716;
  static const double defaultLongitude = 77.5946;
  static const String defaultCity = 'Bengaluru, Karnataka';

  // Payment Methods Available
  static const List<String> availablePaymentMethods = [
    'UPI (Any App)',
    'Google Pay',
    'PhonePe',
    'Paytm',
    'IMPS / NEFT',
    'Bank Transfer',
  ];

  // Quick Amount Suggestions
  static const List<double> quickAmounts = [
    500,
    1000,
    2000,
    3000,
    5000,
    10000,
  ];

  // Expiration Durations (in minutes)
  static const Map<String, int> expirationOptions = {
    '30 Minutes': 30,
    '1 Hour': 60,
    '2 Hours': 120,
    '4 Hours': 240,
    '8 Hours': 480,
  };

  // Meetup Safety Guidelines
  static const List<String> safetyGuidelines = [
    'Always meet in broad daylight and in busy public spaces (Cafes, Metro Concourse, Malls).',
    'Never share bank OTPs or UPI PINs. Only recipient shares the in-app Handshake Code.',
    'Confirm digital funds arrived directly in your banking app before handing over cash.',
    'Check paper notes for authenticity before concluding the meetup.',
    'Do not carry unusually large sums of physical cash without accompaniment.',
  ];

  // Demo User IDs
  static const String demoUserId = '11111111-1111-1111-1111-111111111111';
  static const String demoAdminId = '55555555-5555-5555-5555-555555555555';
}
