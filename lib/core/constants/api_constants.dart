import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

/// Global API constants and backend endpoints for RentaTool LK.
class ApiConstants {
  ApiConstants._();

  /// May be overridden for a physical device, for example:
  /// `--dart-define=API_BASE_URL=http://127.0.0.1:5000/api/v1`
  static const String _configuredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
  );

  /// Automatically configures the base URL depending on host platform.
  /// Android emulator maps `10.0.2.2` to host machine `localhost`.
  static String get baseUrl {
    if (_configuredBaseUrl.isNotEmpty) {
      return _configuredBaseUrl;
    }
    if (kIsWeb) {
      return 'http://localhost:5000/api/v1';
    }
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:5000/api/v1';
    }
    // iOS simulator / Desktop / Physical device over local network
    return 'http://10.20.15.190:5000/api/v1';
  }

  // --- Auth & Identity Endpoints (Component 1) ---
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String kycSubmission = '/users/kyc';
  static const String kycSubmissions = '/users/kyc-submissions';
  static String trustScore(String userId) => '/users/$userId/trust-score';
  static String kycVerificationStatus(String userId) => '/users/$userId/verification-status';
  static const String users = '/users';
  static String userById(String id) => '/users/$id';

  // --- Catalog & Equipment Endpoints (Component 2) ---
  static const String equipment = '/equipment';
  static String equipmentById(String id) => '/equipment/$id';
  static String equipmentInspectionLogs(String id) => '/equipment/$id/inspection-logs';
  static String equipmentHistory(String id) => '/equipment/$id/history';
  static const String batchAvailability = '/equipment/batch-availability';

  // --- Booking & Handover Endpoints (Component 3) ---
  static const String bookings = '/bookings';
  static const String activeBookings = '/bookings/active';
  static String bookingById(String id) => '/bookings/$id';
  static String generateHandoverToken(String id) => '/bookings/$id/generate-handover-token';
  static String verifyHandover(String id) => '/bookings/$id/verify-handover';
  static String extendSchedule(String id) => '/bookings/$id/extend-schedule';

  // --- Escrow & Damage Claims Endpoints (Component 4) ---
  static const String escrowPreAuthorize = '/escrow/pre-authorize';
  static String escrowByBooking(String bookingId) => '/escrow/booking/$bookingId';
  static const String claims = '/claims';
  static String claimById(String id) => '/claims/$id';
  static String claimPayout(String id) => '/claims/$id/payout';
  static String claimAdjudicate(String id) => '/claims/$id/adjudicate';

  // Request timeouts
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
}
