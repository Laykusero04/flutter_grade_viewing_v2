class Student {
  final String uid;
  final String email;
  final String firstName;
  final String lastName;
  final String schoolId;
  final int userRole;
  
  // Optional fields for future use
  final String? phoneNumber;
  final String? grade;
  final String? section;
  final String? academicYear;
  final String? parentName;
  final String? parentPhone;
  final String? address;
  final DateTime? dateOfBirth;
  final DateTime? enrollmentDate;
  final bool? isActive;
  final String? profileImageUrl;
  final Map<String, dynamic> additionalInfo;

  Student({
    required this.uid,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.schoolId,
    required this.userRole,
    this.phoneNumber,
    this.grade,
    this.section,
    this.academicYear,
    this.parentName,
    this.parentPhone,
    this.address,
    this.dateOfBirth,
    this.enrollmentDate,
    this.isActive = true,
    this.profileImageUrl,
    this.additionalInfo = const {},
  });

  String get fullName => '$firstName $lastName';
  String get displayName => '$firstName $lastName ($schoolId)';

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'schoolId': schoolId,
      'userRole': userRole,
      'phoneNumber': phoneNumber,
      'grade': grade,
      'section': section,
      'academicYear': academicYear,
      'parentName': parentName,
      'parentPhone': parentPhone,
      'address': address,
      'dateOfBirth': dateOfBirth?.millisecondsSinceEpoch,
      'enrollmentDate': enrollmentDate?.millisecondsSinceEpoch,
      'isActive': isActive,
      'profileImageUrl': profileImageUrl,
      'additionalInfo': additionalInfo,
    };
  }

  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      firstName: map['firstName'] ?? '',
      lastName: map['lastName'] ?? '',
      schoolId: map['schoolId'] ?? '',
      userRole: map['userRole'] ?? 3,
      phoneNumber: map['phoneNumber'],
      grade: map['grade'],
      section: map['section'],
      academicYear: map['academicYear'],
      parentName: map['parentName'],
      parentPhone: map['parentPhone'],
      address: map['address'],
      dateOfBirth: map['dateOfBirth'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['dateOfBirth']) 
          : null,
      enrollmentDate: map['enrollmentDate'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['enrollmentDate']) 
          : null,
      isActive: map['isActive'] ?? true,
      profileImageUrl: map['profileImageUrl'],
      additionalInfo: map['additionalInfo'] ?? {},
    );
  }

  Student copyWith({
    String? uid,
    String? email,
    String? firstName,
    String? lastName,
    String? schoolId,
    int? userRole,
    String? phoneNumber,
    String? grade,
    String? section,
    String? academicYear,
    String? parentName,
    String? parentPhone,
    String? address,
    DateTime? dateOfBirth,
    DateTime? enrollmentDate,
    bool? isActive,
    String? profileImageUrl,
    Map<String, dynamic>? additionalInfo,
  }) {
    return Student(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      schoolId: schoolId ?? this.schoolId,
      userRole: userRole ?? this.userRole,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      grade: grade ?? this.grade,
      section: section ?? this.section,
      academicYear: academicYear ?? this.academicYear,
      parentName: parentName ?? this.parentName,
      parentPhone: parentPhone ?? this.parentPhone,
      address: address ?? this.address,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      enrollmentDate: enrollmentDate ?? this.enrollmentDate,
      isActive: isActive ?? this.isActive,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      additionalInfo: additionalInfo ?? this.additionalInfo,
    );
  }
}
