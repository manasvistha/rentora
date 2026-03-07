import 'package:flutter/foundation.dart';

class ApiEndpoints {
  ApiEndpoints._();

  // Override with:
  // flutter run --dart-define=API_BASE_URL=http://<host-or-ip>:5000
  static const String _baseUrlFromEnv = String.fromEnvironment('API_BASE_URL');

  // Android emulator cannot use localhost directly to reach host machine.
  static const String _androidEmulatorBase = 'http://10.0.2.2:5000';
  static const String _localMachineBase = 'http://127.0.0.1:5000';

  static String get baseUrl {
    if (_baseUrlFromEnv.isNotEmpty) {
      return _normalizeBaseUrl(_baseUrlFromEnv);
    }

    if (kIsWeb) {
      return _normalizeBaseUrl(_localMachineBase);
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      return _normalizeBaseUrl(_androidEmulatorBase);
    }

    return _normalizeBaseUrl(_localMachineBase);
  }

  static String _normalizeBaseUrl(String rawBaseUrl) {
    final withScheme =
        rawBaseUrl.startsWith('http://') || rawBaseUrl.startsWith('https://')
        ? rawBaseUrl
        : 'http://$rawBaseUrl';

    final withoutTrailingSlash = withScheme.endsWith('/')
        ? withScheme.substring(0, withScheme.length - 1)
        : withScheme;

    if (withoutTrailingSlash.endsWith('/api')) {
      return '$withoutTrailingSlash/';
    }

    return '$withoutTrailingSlash/api/';
  }

  static const Duration connectionTimeout = Duration(seconds: 12);
  static const Duration receiveTimeout = Duration(seconds: 12);

  // ============ Auth Endpoints ============
  // Since you used app.use('/api/auth', authRoutes) in Express:

  static const String login = 'auth/login'; // Becomes: .../api/auth/login
  static const String register =
      'auth/register'; // Becomes: .../api/auth/register
  static const String profile = 'auth/profile'; // Becomes: .../api/auth/profile

  // If you add a get user route in your auth.routes.ts later:
  static const String users = 'auth/';
  static String userById(String id) => 'auth/$id';

  // ============ Property Endpoints ============
  static const String propertyList = 'property'; // GET -> /api/property
  static const String propertyMy = 'property/my'; // GET -> /api/property/my
  static const String propertySearch =
      'property/search'; // GET -> /api/property/search
  static String propertyById(String id) =>
      'property/$id'; // GET -> /api/property/:id

  // ============ Booking Endpoints ============
  static const String bookingCreate = 'booking'; // POST -> /api/booking
  static const String bookingMy = 'booking/my'; // GET -> /api/booking/my
  static const String bookingOwnerRequests =
      'booking/owner/requests'; // GET -> /api/booking/owner/requests
  static String bookingByProperty(String propertyId) =>
      'booking/property/$propertyId'; // GET -> /api/booking/property/:id
  static String bookingGet(String id) =>
      'booking/$id'; // GET -> /api/booking/:id
  static String bookingUpdateStatus(String id) =>
      'booking/$id/status'; // PUT -> /api/booking/:id/status
  static String bookingCancel(String id) =>
      'booking/$id/cancel'; // PATCH -> /api/booking/:id/cancel

  // ============ Favorite Endpoints ============
  static const String favorites = 'favorite'; // GET -> /api/favorite
  static String favoriteByProperty(String propertyId) =>
      'favorite/$propertyId'; // POST/DELETE -> /api/favorite/:propertyId

  // ============ Notification Endpoints ============
  static const String notificationList = 'notification';
  static String notificationMarkRead(String id) => 'notification/$id/read';
  static const String notificationMarkAllRead = 'notification/read-all';

  // ============ Conversation Endpoints ============
  static const String conversationList = 'conversation';
  static String conversationGet(String id) => 'conversation/$id';
  static const String conversationCreate = 'conversation';
  static String conversationSendMessage(String id) =>
      'conversation/$id/message';
  static String conversationByBooking(String bookingId) =>
      'conversation/booking/$bookingId';
  static String conversationSendBookingMessage(String bookingId) =>
      'conversation/booking/$bookingId/message';
}
