import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../models/booking_model.dart';
import '../models/create_booking_request.dart';
import '../models/handover_token_model.dart';
import '../models/handover_verification_model.dart';
import '../models/schedule_extension_model.dart';

final bookingServiceProvider = Provider<BookingService>((ref) {
  final dio = ref.watch(apiClientProvider);
  return BookingService(dio);
});

/// Dedicated HTTP client service for Component 3 Booking operations.
class BookingService {
  final Dio _dio;

  BookingService(this._dio);

  /// 1. Initiates a new equipment rental booking request with conflict validation.
  Future<BookingModel> createBooking(CreateBookingRequestModel request) async {
    try {
      final response = await _dio.post(
        ApiConstants.bookings,
        data: request.toJson(),
      );
      return BookingModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _parseDioError(e, defaultMessage: 'Failed to create rental reservation.');
    }
  }

  /// Retrieves a single booking by unique ID.
  Future<BookingModel> getBookingById(String id) async {
    try {
      final response = await _dio.get(ApiConstants.bookingById(id));
      return BookingModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _parseDioError(e, defaultMessage: 'Booking not found or unavailable.');
    }
  }

  /// 2. Returns all active and confirmed bookings for the authenticated user.
  Future<List<BookingModel>> getActiveBookings() async {
    try {
      final response = await _dio.get(ApiConstants.activeBookings);
      final List<dynamic> items = response.data is List ? response.data : [];
      return items.map((e) => BookingModel.fromJson(e)).toList();
    } on DioException catch (e) {
      throw _parseDioError(e, defaultMessage: 'Failed to fetch active bookings.');
    }
  }

  /// 3. Issues a single-use cryptographically hashed handover token for pickup or return.
  Future<HandoverTokenModel> generateHandoverToken({
    required String bookingId,
    required String eventType, // 'Pickup' or 'Return'
  }) async {
    try {
      final eventTypeInt = eventType.toLowerCase() == 'return' ? 2 : 1;
      final response = await _dio.post(
        ApiConstants.generateHandoverToken(bookingId),
        data: {
          'eventType': eventTypeInt,
        },
      );
      return HandoverTokenModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _parseDioError(e, defaultMessage: 'Failed to generate single-use handover token.');
    }
  }

  /// 4. Confirms equipment pickup or return via QR token scan with GPS location logging.
  Future<HandoverVerificationResponseModel> verifyHandover({
    required String bookingId,
    required VerifyHandoverRequestModel request,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.verifyHandover(bookingId),
        data: request.toJson(),
      );
      return HandoverVerificationResponseModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _parseDioError(e, defaultMessage: 'Handover verification failed. Invalid or expired token.');
    }
  }

  /// 5. (Business-Specific) Validates schedule conflicts & applies extension with dynamic surge pricing.
  Future<ExtendScheduleResponseModel> extendSchedule({
    required String bookingId,
    required DateTime newEndDate,
  }) async {
    try {
      final request = ExtendScheduleRequestModel(newEndDate: newEndDate);
      final response = await _dio.post(
        ApiConstants.extendSchedule(bookingId),
        data: request.toJson(),
      );
      return ExtendScheduleResponseModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _parseDioError(e, defaultMessage: 'Failed to apply schedule extension.');
    }
  }

  /// Parses RFC 7807 ProblemDetails and standard error JSON payloads.
  Exception _parseDioError(DioException e, {required String defaultMessage}) {
    if (e.response != null && e.response?.data is Map) {
      final data = e.response!.data as Map<String, dynamic>;
      
      // Handle ASP.NET Core RFC 7807 ProblemDetails
      if (data.containsKey('detail') && data['detail'] != null) {
        return Exception(data['detail'].toString());
      }
      if (data.containsKey('message') && data['message'] != null) {
        return Exception(data['message'].toString());
      }
      if (data.containsKey('title') && data['title'] != null) {
        return Exception(data['title'].toString());
      }
    }

    if (e.response?.statusCode == 409) {
      return Exception('Schedule conflict: Equipment is already reserved for the requested dates.');
    }
    if (e.response?.statusCode == 403) {
      return Exception('Access denied: You are not authorized to perform this operation.');
    }
    if (e.response?.statusCode == 404) {
      return Exception('Booking not found.');
    }

    return Exception(defaultMessage);
  }
}
