import 'package:equatable/equatable.dart';

class Teacher extends Equatable {
  final String uid;
  final String email;
  final String firstName;
  final String lastName;
  final String employeeId;
  final int userRole;
  final String? phoneNumber;
  final String? department;
  final String? subject;
  final String? qualification;
  final DateTime? dateOfBirth;
  final DateTime? hireDate;
  final String? address;
  final bool? isActive;
  final String? profileImageUrl;
  final Map<String, dynamic> additionalInfo;

  const Teacher({
    required this.uid,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.employeeId,
    required this.userRole,
    this.phoneNumber,
    this.department,
    this.subject,
    this.qualification,
    this.dateOfBirth,
    this.hireDate,
    this.address,
    this.isActive = true,
    this.profileImageUrl,
    this.additionalInfo = const {},
  });

  String get fullName => '$firstName $lastName';
  String get displayName => '$firstName $lastName ($employeeId)';

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'employeeId': employeeId,
      'userRole': userRole,
      'phoneNumber': phoneNumber,
      'department': department,
      'subject': subject,
      'qualification': qualification,
      'dateOfBirth': dateOfBirth?.millisecondsSinceEpoch,
      'hireDate': hireDate?.millisecondsSinceEpoch,
      'address': address,
      'isActive': isActive,
      'profileImageUrl': profileImageUrl,
      'additionalInfo': additionalInfo,
    };
  }

  factory Teacher.fromMap(Map<String, dynamic> map) {
    return Teacher(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      firstName: map['firstName'] ?? '',
      lastName: map['lastName'] ?? '',
      // Handle both employeeId and schoolId fields for compatibility
      employeeId: map['employeeId'] ?? map['schoolId'] ?? '',
      userRole: map['userRole'] ?? 2, // Teacher role
      phoneNumber: map['phoneNumber'],
      department: map['department'],
      subject: map['subject'],
      qualification: map['qualification'],
      dateOfBirth: map['dateOfBirth'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['dateOfBirth'])
          : null,
      hireDate: map['hireDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['hireDate'])
          : null,
      address: map['address'],
      isActive: map['isActive'] ?? true,
      profileImageUrl: map['profileImageUrl'],
      additionalInfo: Map<String, dynamic>.from(map['additionalInfo'] ?? {}),
    );
  }

  Teacher copyWith({
    String? uid,
    String? email,
    String? firstName,
    String? lastName,
    String? employeeId,
    int? userRole,
    String? phoneNumber,
    String? department,
    String? subject,
    String? qualification,
    DateTime? dateOfBirth,
    DateTime? hireDate,
    String? address,
    bool? isActive,
    String? profileImageUrl,
    Map<String, dynamic>? additionalInfo,
  }) {
    return Teacher(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      employeeId: employeeId ?? this.employeeId,
      userRole: userRole ?? this.userRole,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      department: department ?? this.department,
      subject: subject ?? this.subject,
      qualification: qualification ?? this.qualification,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      hireDate: hireDate ?? this.hireDate,
      address: address ?? this.address,
      isActive: isActive ?? this.isActive,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      additionalInfo: additionalInfo ?? this.additionalInfo,
    );
  }

  @override
  List<Object?> get props => [
        uid,
        email,
        firstName,
        lastName,
        employeeId,
        userRole,
        phoneNumber,
        department,
        subject,
        qualification,
        dateOfBirth,
        hireDate,
        address,
        isActive,
        profileImageUrl,
        additionalInfo,
      ];
}
