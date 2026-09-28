enum UserRole {
  renter,
  owner,
  admin;

  static UserRole fromString(String role) {
    switch (role.toLowerCase()) {
      case 'owner':
        return UserRole.owner;
      case 'admin':
        return UserRole.admin;
      case 'renter':
      default:
        return UserRole.renter;
    }
  }

  String get displayName {
    switch (this) {
      case UserRole.owner:
        return 'Equipment Owner';
      case UserRole.admin:
        return 'Administrator';
      case UserRole.renter:
        return 'Machinery Renter';
    }
  }
}

class UserModel {
  final String id;
  final String name;
  final String email;
  final String phoneNumber;
  final UserRole role;
  final bool isVerified;
  final bool isActive;
  final String? suspensionReason;
  final int trustScore;
  final String? profilePhotoPath;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.role,
    this.isVerified = false,
    this.isActive = true,
    this.suspensionReason,
    this.trustScore = 50,
    this.profilePhotoPath,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? json['userId'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      role: UserRole.fromString(json['role'] ?? 'Renter'),
      isVerified: json['isVerified'] ?? false,
      isActive: json['isActive'] ?? true,
      suspensionReason: json['suspensionReason'],
      trustScore: json['trustScore'] ?? 50,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'role': role.name,
      'isVerified': isVerified,
      'isActive': isActive,
      'suspensionReason': suspensionReason,
      'trustScore': trustScore,
    };
  }

  UserModel copyWith(
      {bool? isVerified,
      bool? isActive,
      int? trustScore,
      String? profilePhotoPath,
      String? name,
      String? phoneNumber}) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role,
      isVerified: isVerified ?? this.isVerified,
      isActive: isActive ?? this.isActive,
      suspensionReason: suspensionReason,
      trustScore: trustScore ?? this.trustScore,
      profilePhotoPath: profilePhotoPath ?? this.profilePhotoPath,
    );
  }
}

class AuthResponse {
  final String userId;
  final String name;
  final String role;
  final String accessToken;
  final String? refreshToken;
  final String? accessTokenExpiresAtUtc;

  const AuthResponse({
    required this.userId,
    required this.name,
    required this.role,
    required this.accessToken,
    this.refreshToken,
    this.accessTokenExpiresAtUtc,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      userId: json['userId'] ?? '',
      name: json['name'] ?? '',
      role: json['role'] ?? 'Renter',
      accessToken: json['accessToken'] ?? '',
      refreshToken: json['refreshToken'],
      accessTokenExpiresAtUtc: json['accessTokenExpiresAtUtc'],
    );
  }
}
