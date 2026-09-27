import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Global API constants and backend endpoints for RentaTool LK.
class ApiConstants {
  ApiConstants._();

  static String? _getEnv(String key) {
    try {
      if (dotenv.isInitialized) {
        return dotenv.maybeGet(key);
      }
    } catch (_) {}
    return null;
  }

  /// Automatically configures the base URL using `.env` settings
  /// with intelligent fallback defaults based on the target platform.
  static String get baseUrl {
    // 1. Direct Base URL Override from .env
    final explicitUrl = _getEnv('API_BASE_URL')?.trim();
    if (explicitUrl != null && explicitUrl.isNotEmpty) {
      return explicitUrl.endsWith('/')
          ? explicitUrl.substring(0, explicitUrl.length - 1)
          : explicitUrl;
    }

    // 2. Read Protocol, Port and API Prefix
    final scheme = _getEnv('API_SCHEME')?.trim() ?? 'http';
    final port = _getEnv('API_PORT')?.trim() ?? '5000';
    final prefix = _getEnv('API_PREFIX')?.trim() ?? 'api/v1';

    // 3. Resolve Host based on platform
    String host;
    if (kIsWeb) {
      host = _getEnv('API_HOST_WEB')?.trim() ??
          _getEnv('API_HOST')?.trim() ??
          'localhost';
    } else if (Platform.isAndroid) {
      host = _getEnv('API_HOST_ANDROID')?.trim() ??
          _getEnv('API_HOST')?.trim() ??
          '10.0.2.2';
    } else if (Platform.isIOS) {
      host = _getEnv('API_HOST_IOS')?.trim() ??
          _getEnv('API_HOST')?.trim() ??
          'localhost';
    } else {
      host = _getEnv('API_HOST')?.trim() ?? 'localhost';
    }

    // 4. Construct complete URL
    final portSuffix = port.isNotEmpty ? ':$port' : '';
    final cleanedPrefix = prefix.startsWith('/') ? prefix.substring(1) : prefix;
    return '$scheme://$host$portSuffix/$cleanedPrefix';
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
  static Duration get connectTimeout {
    final seconds = int.tryParse(_getEnv('CONNECT_TIMEOUT_SECONDS') ?? '15') ?? 15;
    return Duration(seconds: seconds);
  }

  static Duration get receiveTimeout {
    final seconds = int.tryParse(_getEnv('RECEIVE_TIMEOUT_SECONDS') ?? '15') ?? 15;
    return Duration(seconds: seconds);
  }
}
