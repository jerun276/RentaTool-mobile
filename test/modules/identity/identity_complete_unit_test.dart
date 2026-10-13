import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rentatool_mobile/core/services/token_storage_service.dart';
import 'package:rentatool_mobile/modules/identity/models/kyc_submission_model.dart';
import 'package:rentatool_mobile/modules/identity/models/trust_score_model.dart';
import 'package:rentatool_mobile/modules/identity/models/user_model.dart';
import 'package:rentatool_mobile/modules/identity/providers/auth_provider.dart';
import 'package:rentatool_mobile/modules/identity/services/identity_service.dart';

class MockIdentityService extends Mock implements IdentityService {}
class MockTokenStorageService extends Mock implements TokenStorageService {}

void main() {
  group('[1] UserRole - fromString and displayName', () {
    test('TC-UR-01 [Normal]  fromString("renter") returns UserRole.renter', () {
      expect(UserRole.fromString('renter'), UserRole.renter);
    });
    test('TC-UR-02 [Normal]  fromString("owner") returns UserRole.owner', () {
      expect(UserRole.fromString('owner'), UserRole.owner);
    });
    test('TC-UR-03 [Normal]  fromString("admin") returns UserRole.admin', () {
      expect(UserRole.fromString('admin'), UserRole.admin);
    });
    test('TC-UR-04 [Invalid] fromString("unknown") defaults to renter', () {
      expect(UserRole.fromString('unknown'), UserRole.renter);
    });
    test('TC-UR-05 [Edge]    fromString is case-insensitive (OWNER)', () {
      expect(UserRole.fromString('OWNER'), UserRole.owner);
    });
    test('TC-UR-06 [Normal]  displayName for each role is correct', () {
      expect(UserRole.renter.displayName, 'Machinery Renter');
      expect(UserRole.owner.displayName, 'Equipment Owner');
      expect(UserRole.admin.displayName, 'Administrator');
    });
  });

  group('[2] UserModel - fromJson, toJson, copyWith, defaults', () {
    const sampleJson = {
      'id': 'user-001', 'name': 'Kasun Kalhara', 'email': 'kasun@example.com',
      'phoneNumber': '0771234567', 'role': 'Renter', 'isVerified': true,
      'isActive': true, 'trustScore': 80,
    };
    test('TC-UM-01 [Normal]  fromJson deserializes all fields correctly', () {
      final user = UserModel.fromJson(sampleJson);
      expect(user.id, 'user-001');
      expect(user.name, 'Kasun Kalhara');
      expect(user.role, UserRole.renter);
      expect(user.isVerified, isTrue);
      expect(user.trustScore, 80);
    });
    test('TC-UM-02 [Edge]    fromJson uses "userId" key as fallback for id', () {
      final user = UserModel.fromJson({'userId': 'u-999', 'role': 'Admin'});
      expect(user.id, 'u-999');
    });
    test('TC-UM-03 [Edge]    fromJson sets safe defaults for missing fields', () {
      final user = UserModel.fromJson({});
      expect(user.id, '');
      expect(user.trustScore, 50);
      expect(user.isVerified, isFalse);
    });
    test('TC-UM-04 [Normal]  toJson serializes all fields correctly', () {
      const user = UserModel(id: 'u-001', name: 'Test', email: 'test@example.com',
          phoneNumber: '0779999999', role: UserRole.owner, isVerified: true, trustScore: 90);
      final json = user.toJson();
      expect(json['id'], 'u-001');
      expect(json['role'], 'owner');
      expect(json['isVerified'], isTrue);
    });
    test('TC-UM-05 [Normal]  copyWith updates name and phoneNumber only', () {
      const original = UserModel(id: 'u-001', name: 'Old Name', email: 'test@example.com',
          phoneNumber: '0770000000', role: UserRole.renter);
      final updated = original.copyWith(name: 'New Name', phoneNumber: '0771111111');
      expect(updated.name, 'New Name');
      expect(updated.email, 'test@example.com');
    });
    test('TC-UM-06 [Normal]  copyWith updates isVerified', () {
      const user = UserModel(id: 'u-001', name: 'Test', email: 'a@b.com',
          phoneNumber: '0771234567', role: UserRole.renter, isVerified: false);
      expect(user.copyWith(isVerified: true).isVerified, isTrue);
    });
    test('TC-UM-07 [Edge]    copyWith with no args returns identical copy', () {
      const user = UserModel(id: 'u-002', name: 'Jane', email: 'jane@example.com',
          phoneNumber: '0770000000', role: UserRole.owner);
      final copy = user.copyWith();
      expect(copy.id, user.id);
      expect(copy.name, user.name);
    });
  });

  group('[3] AuthResponse - fromJson', () {
    test('TC-AR-01 [Normal]  fromJson parses all token fields correctly', () {
      final r = AuthResponse.fromJson({'userId': 'u-100', 'name': 'Admin User',
          'role': 'Admin', 'accessToken': 'tok.abc.xyz', 'refreshToken': 'ref.abc.xyz'});
      expect(r.userId, 'u-100');
      expect(r.role, 'Admin');
      expect(r.accessToken, 'tok.abc.xyz');
    });
    test('TC-AR-02 [Edge]    fromJson applies safe defaults for missing fields', () {
      final r = AuthResponse.fromJson({});
      expect(r.userId, '');
      expect(r.role, 'Renter');
      expect(r.refreshToken, isNull);
    });
    test('TC-AR-03 [Normal]  refreshToken is nullable and optional', () {
      const r = AuthResponse(userId: '1', name: 'X', role: 'Renter', accessToken: 'tok');
      expect(r.refreshToken, isNull);
    });
  });

  group('[4] KycSubmissionModel - fromJson, toJson, defaults', () {
    final fullJson = {'kycRecordId': 'kyc-001', 'userId': 'user-001', 'name': 'Kasun',
        'documentType': 'Passport', 'documentNumber': 'N1234567',
        'frontImageUrl': 'https://cdn.example.com/front.jpg', 'status': 'Approved'};
    test('TC-KYC-01 [Normal]  fromJson parses all fields correctly', () {
      final model = KycSubmissionModel.fromJson(fullJson);
      expect(model.kycRecordId, 'kyc-001');
      expect(model.documentType, 'Passport');
      expect(model.status, 'Approved');
    });
    test('TC-KYC-02 [Edge]    fromJson defaults documentType to NIC and status to Pending', () {
      final model = KycSubmissionModel.fromJson({'userId': 'u-1', 'documentNumber': '123'});
      expect(model.documentType, 'NIC');
      expect(model.status, 'Pending');
    });
    test('TC-KYC-03 [Normal]  toJson only exposes documentType and documentNumber', () {
      const model = KycSubmissionModel(userId: 'u-1', documentNumber: 'NIC123456', documentType: 'NIC');
      final json = model.toJson();
      expect(json.containsKey('documentType'), isTrue);
      expect(json.containsKey('userId'), isFalse);
    });
    test('TC-KYC-04 [Edge]    backImageUrl and rejectionReason are nullable', () {
      final model = KycSubmissionModel.fromJson({'userId': 'u-1', 'documentNumber': '123'});
      expect(model.backImageUrl, isNull);
      expect(model.rejectionReason, isNull);
    });
  });

  group('[5] TrustScoreModel - fromJson and ledger entries', () {
    final fullJson = {'userId': 'u-001', 'score': 75, 'tier': 'Tier A',
        'history': [{'id': 'led-1', 'changeAmount': 10, 'reason': 'On-time return',
            'reference': 'booking-xyz', 'resultingScore': 75}]};
    test('TC-TS-01 [Normal]  fromJson parses score, tier and userId correctly', () {
      final model = TrustScoreModel.fromJson(fullJson);
      expect(model.score, 75);
      expect(model.tier, 'Tier A');
    });
    test('TC-TS-02 [Normal]  fromJson parses nested ledger history entries', () {
      final model = TrustScoreModel.fromJson(fullJson);
      expect(model.ledgerHistory.length, 1);
      expect(model.ledgerHistory.first.reason, 'On-time return');
    });
    test('TC-TS-03 [Edge]    fromJson uses "trustScore" key as fallback for score', () {
      final model = TrustScoreModel.fromJson({'userId': 'u-1', 'trustScore': 42, 'tier': 'Tier C'});
      expect(model.score, 42);
    });
    test('TC-TS-04 [Edge]    fromJson returns empty ledger when history is null', () {
      final model = TrustScoreModel.fromJson({'userId': 'u-1', 'score': 50, 'tier': 'Tier B'});
      expect(model.ledgerHistory, isEmpty);
    });
    test('TC-TS-05 [Edge]    fromJson sets default tier "Tier B" when missing', () {
      final model = TrustScoreModel.fromJson({'userId': 'u-1', 'score': 50});
      expect(model.tier, 'Tier B');
    });
  });

  group('[6] AuthNotifier - session, login, register, logout', () {
    late MockIdentityService mockService;
    late MockTokenStorageService mockStorage;
    setUp(() { mockService = MockIdentityService(); mockStorage = MockTokenStorageService(); });

    void stubNoSession() => when(() => mockStorage.hasToken()).thenAnswer((_) async => false);
    void stubSaveTokens() {
      when(() => mockStorage.saveTokens(accessToken: any(named: 'accessToken'),
          refreshToken: any(named: 'refreshToken'))).thenAnswer((_) async {});
      when(() => mockStorage.saveUser(userId: any(named: 'userId'), role: any(named: 'role'),
          name: any(named: 'name'), email: any(named: 'email'))).thenAnswer((_) async {});
      when(() => mockStorage.getProfilePhoto(any())).thenAnswer((_) async => null);
    }

    test('TC-AN-01 [Normal]  initial state is unauthenticated, not loading', () async {
      stubNoSession();
      final n = AuthNotifier(mockService, mockStorage);
      await Future.delayed(Duration.zero);
      expect(n.state.isAuthenticated, isFalse);
      expect(n.state.isLoading, isFalse);
      expect(n.state.user, isNull);
    });
    test('TC-AN-02 [Normal]  login success sets authenticated state', () async {
      stubNoSession();
      final n = AuthNotifier(mockService, mockStorage);
      await Future.delayed(Duration.zero);
      const email = 'renter@rentatool.com';
      const password = 'Renter@123';
      const authResp = AuthResponse(userId: 'u-001', name: 'Renter', role: 'Renter', accessToken: 'tok');
      const userModel = UserModel(id: 'u-001', name: 'Renter', email: email, phoneNumber: '077', role: UserRole.renter);
      when(() => mockService.login(email: email, password: password)).thenAnswer((_) async => authResp);
      when(() => mockService.getUserProfile('u-001')).thenAnswer((_) async => userModel);
      stubSaveTokens();
      final result = await n.login(email: email, password: password);
      expect(result, isTrue);
      expect(n.state.isAuthenticated, isTrue);
    });
    test('TC-AN-03 [Failure] login failure sets errorMessage', () async {
      stubNoSession();
      final n = AuthNotifier(mockService, mockStorage);
      await Future.delayed(Duration.zero);
      when(() => mockService.login(email: any(named: 'email'), password: any(named: 'password')))
          .thenThrow(Exception('401 Unauthorized'));
      final result = await n.login(email: 'bad@test.com', password: 'wrong');
      expect(result, isFalse);
      expect(n.state.errorMessage, isNotNull);
    });
    test('TC-AN-04 [Normal]  logout clears session state', () async {
      stubNoSession();
      final n = AuthNotifier(mockService, mockStorage);
      when(() => mockStorage.clearAll()).thenAnswer((_) async {});
      await n.logout();
      expect(n.state.isAuthenticated, isFalse);
      expect(n.state.user, isNull);
    });
    test('TC-AN-05 [Normal]  register success sets authenticated state', () async {
      stubNoSession();
      final n = AuthNotifier(mockService, mockStorage);
      await Future.delayed(Duration.zero);
      const authResp = AuthResponse(userId: 'u-002', name: 'New User', role: 'Renter', accessToken: 'tok-xyz');
      stubSaveTokens();
      when(() => mockService.register(name: any(named: 'name'), email: any(named: 'email'),
          password: any(named: 'password'), phoneNumber: any(named: 'phoneNumber'),
          role: any(named: 'role'))).thenAnswer((_) async => authResp);
      final result = await n.register(name: 'New User', email: 'new@test.com',
          password: 'Password1', phoneNumber: '0771234567', role: 'Renter');
      expect(result, isTrue);
      expect(n.state.isAuthenticated, isTrue);
    });
    test('TC-AN-06 [Failure] register failure sets errorMessage', () async {
      stubNoSession();
      final n = AuthNotifier(mockService, mockStorage);
      await Future.delayed(Duration.zero);
      when(() => mockService.register(name: any(named: 'name'), email: any(named: 'email'),
          password: any(named: 'password'), phoneNumber: any(named: 'phoneNumber'),
          role: any(named: 'role'))).thenThrow(Exception('Conflict'));
      final result = await n.register(name: 'Dup', email: 'dup@test.com',
          password: 'Password1', phoneNumber: '0771234567', role: 'Renter');
      expect(result, isFalse);
      expect(n.state.errorMessage, isNotNull);
    });
    test('TC-AN-07 [Normal]  setVerified updates isVerified on current user', () async {
      stubNoSession();
      final n = AuthNotifier(mockService, mockStorage);
      await Future.delayed(Duration.zero);
      // ignore: invalid_use_of_protected_member
      n.state = n.state.copyWith(isAuthenticated: true,
          user: const UserModel(id: 'u-001', name: 'Test', email: 'a@b.com',
              phoneNumber: '077', role: UserRole.renter, isVerified: false));
      n.setVerified(true);
      expect(n.state.user?.isVerified, isTrue);
    });
  });
}

