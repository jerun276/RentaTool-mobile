import 'package:flutter_test/flutter_test.dart';
import 'package:rentatool_mobile/core/services/cloudinary_service.dart';

void main() {
  group('Cloudinary Service Unit Tests', () {
    test('Detects placeholder/unconfigured state accurately', () {
      // By default with placeholder .env settings, isConfigured should be false
      expect(CloudinaryService.isConfigured, isFalse);
    });

    test('Passes through existing HTTP and HTTPS URLs without re-uploading', () async {
      final service = CloudinaryService();
      const existingHttpsUrl = 'https://res.cloudinary.com/rentatool/image/upload/sample.jpg';
      const existingHttpUrl = 'http://example.com/photo.png';

      final res1 = await service.uploadImage(existingHttpsUrl);
      final res2 = await service.uploadImage(existingHttpUrl);

      expect(res1, existingHttpsUrl);
      expect(res2, existingHttpUrl);
    });

    test('Generates graceful fallback CDN URL when credentials are not configured', () async {
      final service = CloudinaryService();
      const mockLocalPath = '/var/mobile/Containers/Data/image_front.jpg';

      final result = await service.uploadImage(mockLocalPath, folder: 'rentatool/kyc');

      expect(result, startsWith('https://res.cloudinary.com/'));
      expect(result, contains('image_front.jpg'));
      expect(result, contains('rentatool/kyc'));
    });

    test('uploadMultipleImages uploads list of files concurrently', () async {
      final service = CloudinaryService();
      final paths = ['/tmp/casing.jpg', '/tmp/cord.jpg', '/tmp/motor.jpg'];

      final results = await service.uploadMultipleImages(paths, folder: 'rentatool/inspections');

      expect(results.length, 3);
      expect(results[0], contains('casing.jpg'));
      expect(results[1], contains('cord.jpg'));
      expect(results[2], contains('motor.jpg'));
    });
  });
}
