import 'package:flutter_test/flutter_test.dart';
import 'package:rentatool_mobile/modules/identity/models/user_model.dart';
import 'package:rentatool_mobile/modules/identity/models/kyc_submission_model.dart';

void main() {
  group('Identity Module - Component 1 Unit Tests', () {
    test('UserModel deserializes correctly from backend API JSON', () {
      final json = {
        'id': '11111111-1111-1111-1111-111111111101',
        'name': 'Duminda Bandara',
        'email': 'duminda@rentatool.lk',
        'phoneNumber': '0774210992',
        'role': 'Renter',
        'isVerified': true,
        'isActive': true,
        'trustScore': 88,
      };

      final user = UserModel.fromJson(json);

      expect(user.id, '11111111-1111-1111-1111-111111111101');
      expect(user.name, 'Duminda Bandara');
      expect(user.role, UserRole.renter);
      expect(user.isVerified, isTrue);
      expect(user.trustScore, 88);
    });

    test('KycSubmissionModel parses correctly', () {
      final json = {
        'userId': '11111111-1111-1111-1111-111111111105',
        'documentType': 'NIC',
        'documentNumber': '199310804422',
        'status': 'Pending',
      };

      final kyc = KycSubmissionModel.fromJson(json);

      expect(kyc.userId, '11111111-1111-1111-1111-111111111105');
      expect(kyc.documentNumber, '199310804422');
      expect(kyc.status, 'Pending');
    });
  });
}
