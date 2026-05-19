enum UserRole {
  superAdmin,
  admin,
  volunteer,
  user,
}

class UserModel {
  final String uid;
  final String? email;
  final String? phoneNumber;
  final String? displayName;
  final String? photoUrl;
  final String? bloodGroup;
  final UserRole role;

  UserModel({
    required this.uid,
    this.email,
    this.phoneNumber,
    this.displayName,
    this.photoUrl,
    this.bloodGroup,
    this.role = UserRole.user,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String documentId) {
    return UserModel(
      uid: documentId,
      email: map['email'],
      phoneNumber: map['phoneNumber'],
      displayName: map['displayName'],
      photoUrl: map['photoUrl'],
      bloodGroup: map['bloodGroup'],
      role: _parseRole(map['role']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'phoneNumber': phoneNumber,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'bloodGroup': bloodGroup,
      'role': role.name,
    };
  }

  static UserRole _parseRole(String? roleString) {
    if (roleString == null) return UserRole.user;
    switch (roleString.toLowerCase()) {
      case 'superadmin':
        return UserRole.superAdmin;
      case 'admin':
        return UserRole.admin;
      case 'volunteer':
        return UserRole.volunteer;
      default:
        return UserRole.user;
    }
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? phoneNumber,
    String? displayName,
    String? photoUrl,
    String? bloodGroup,
    UserRole? role,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      role: role ?? this.role,
    );
  }
}
