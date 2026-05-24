import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole {
  superAdmin,
  admin,
  volunteer,
  user,
}

enum ApprovalStatus {
  pending,
  approved,
  rejected,
}

class MembershipInfo {
  final DateTime paymentDate;
  final DateTime renewalDate;
  final double amount;
  final String status;

  MembershipInfo({
    required this.paymentDate,
    required this.renewalDate,
    required this.amount,
    required this.status,
  });

  factory MembershipInfo.fromMap(Map<String, dynamic> map) {
    return MembershipInfo(
      paymentDate: (map['paymentDate'] as Timestamp).toDate(),
      renewalDate: (map['renewalDate'] as Timestamp).toDate(),
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      status: map['status'] ?? 'expired',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'paymentDate': Timestamp.fromDate(paymentDate),
      'renewalDate': Timestamp.fromDate(renewalDate),
      'amount': amount,
      'status': status,
    };
  }

  MembershipInfo copyWith({
    DateTime? paymentDate,
    DateTime? renewalDate,
    double? amount,
    String? status,
  }) {
    return MembershipInfo(
      paymentDate: paymentDate ?? this.paymentDate,
      renewalDate: renewalDate ?? this.renewalDate,
      amount: amount ?? this.amount,
      status: status ?? this.status,
    );
  }
}

class UserModel {
  final String uid;
  final String? email;
  final String? phoneNumber;
  final String? displayName;
  final String? photoUrl;
  final String? bloodGroup;
  final String? legacyUserId;
  final String? fcmToken;
  final MembershipInfo? membership;
  final UserRole role;
  final ApprovalStatus approvalStatus;

  UserModel({
    required this.uid,
    this.email,
    this.phoneNumber,
    this.displayName,
    this.photoUrl,
    this.bloodGroup,
    this.legacyUserId,
    this.fcmToken,
    this.membership,
    this.role = UserRole.user,
    this.approvalStatus = ApprovalStatus.approved, // Default to approved for backwards compatibility
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String documentId) {
    return UserModel(
      uid: documentId,
      email: map['email'],
      phoneNumber: map['phoneNumber'],
      displayName: map['displayName'],
      photoUrl: map['photoUrl'],
      bloodGroup: map['bloodGroup'],
      legacyUserId: map['legacyUserId'],
      fcmToken: map['fcmToken'],
      membership: map['membership'] != null ? MembershipInfo.fromMap(map['membership']) : null,
      role: _parseRole(map['role']),
      approvalStatus: _parseApprovalStatus(map['approvalStatus']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'phoneNumber': phoneNumber,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'bloodGroup': bloodGroup,
      'legacyUserId': legacyUserId,
      'fcmToken': fcmToken,
      if (membership != null) 'membership': membership!.toMap(),
      'role': role.name,
      'approvalStatus': approvalStatus.name,
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

  static ApprovalStatus _parseApprovalStatus(String? statusString) {
    if (statusString == null) return ApprovalStatus.approved; // Existing users are automatically approved
    switch (statusString.toLowerCase()) {
      case 'pending':
        return ApprovalStatus.pending;
      case 'rejected':
        return ApprovalStatus.rejected;
      default:
        return ApprovalStatus.approved;
    }
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? phoneNumber,
    String? displayName,
    String? photoUrl,
    String? bloodGroup,
    String? legacyUserId,
    String? fcmToken,
    MembershipInfo? membership,
    UserRole? role,
    ApprovalStatus? approvalStatus,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      legacyUserId: legacyUserId ?? this.legacyUserId,
      fcmToken: fcmToken ?? this.fcmToken,
      membership: membership ?? this.membership,
      role: role ?? this.role,
      approvalStatus: approvalStatus ?? this.approvalStatus,
    );
  }
}

