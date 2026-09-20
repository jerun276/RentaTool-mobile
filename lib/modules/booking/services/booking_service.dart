import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../models/booking_model.dart';
import '../models/handover_token_model.dart';

final bookingServiceProvider = Provider<BookingService>((ref) {
  final dio = ref.watch(apiClientProvider);
  return BookingService(dio);
});

class BookingService {
  final Dio _dio;

  BookingService(this._dio);

  Future<List<BookingModel>> getActiveBookings() async {
    final response = await _dio.get(ApiConstants.activeBookings);
    final List<dynamic> items = response.data is List ? response.data : [];
    return items.map((e) => BookingModel.fromJson(e)).toList();
  }

  Future<BookingModel> getBookingById(String id) async {
    final response = await _dio.get(ApiConstants.bookingById(id));
    return BookingModel.fromJson(response.data);
  }

  Future<BookingModel> createBooking({
    required String equipmentId,
    required String ownerId,
    required DateTime startDate,
    required DateTime endDate,
    required double dailyRate,
  }) async {
    final response = await _dio.post(
      ApiConstants.bookings,
      data: {
        'equipmentId': equipmentId,
        'ownerId': ownerId,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'dailyRate': dailyRate,
      },
    );
    return BookingModel.fromJson(response.data);
  }

  Future<HandoverTokenModel> generateHandoverToken({
    required String bookingId,
    required String eventType, // 'Pickup' or 'Return'
  }) async {
    final response = await _dio.post(
      ApiConstants.generateHandoverToken(bookingId),
      data: {
        'eventType': eventType,
      },
    );
    return HandoverTokenModel.fromJson(response.data);
  }

  Future<bool> verifyHandover({
    required String bookingId,
    required String token,
    required String eventType,
  }) async {
    final response = await _dio.post(
      ApiConstants.verifyHandover(bookingId),
      data: {
        'token': token,
        'eventType': eventType,
      },
    );
    return response.statusCode == 200;
  }

  Future<bool> extendSchedule({
    required String bookingId,
    required DateTime newEndDate,
    String? reason,
  }) async {
    final response = await _dio.post(
      ApiConstants.extendSchedule(bookingId),
      data: {
        'newEndDate': newEndDate.toIso8601String(),
        'reason': reason ?? 'Extension request',
      },
    );
    return response.statusCode == 200;
  }
}
