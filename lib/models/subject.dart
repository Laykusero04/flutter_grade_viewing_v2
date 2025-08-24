class Subject {
  final String uid;
  final String name;
  final String code;
  final String? description;
  final String? department;
  final int? credits;
  final String? academicYear;
  final bool? isActive;
  final Map<String, dynamic> additionalInfo;

  Subject({
    required this.uid,
    required this.name,
    required this.code,
    this.description,
    this.department,
    this.credits,
    this.academicYear,
    this.isActive = true,
    this.additionalInfo = const {},
  });

  String get displayName => '$name ($code)';

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'code': code,
      'description': description,
      'department': department,
      'credits': credits,
      'academicYear': academicYear,
      'isActive': isActive,
      'additionalInfo': additionalInfo,
    };
  }

  /// Creates a map without the uid field for Firestore operations
  /// Use this when saving to Firestore to avoid conflicts with document ID
  Map<String, dynamic> toFirestoreMap() {
    return {
      'name': name,
      'code': code,
      'description': description,
      'department': department,
      'credits': credits,
      'academicYear': academicYear,
      'isActive': isActive,
      'additionalInfo': additionalInfo,
    };
  }

  factory Subject.fromMap(Map<String, dynamic> map) {
    return Subject(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      code: map['code'] ?? '',
      description: map['description'],
      department: map['department'],
      credits: map['credits'],
      academicYear: map['academicYear'],
      isActive: map['isActive'] ?? true,
      additionalInfo: map['additionalInfo'] ?? {},
    );
  }

  Subject copyWith({
    String? uid,
    String? name,
    String? code,
    String? description,
    String? department,
    int? credits,
    String? academicYear,
    bool? isActive,
    Map<String, dynamic>? additionalInfo,
  }) {
    return Subject(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      code: code ?? this.code,
      description: description ?? this.description,
      department: department ?? this.department,
      credits: credits ?? this.credits,
      academicYear: academicYear ?? this.academicYear,
      isActive: isActive ?? this.isActive,
      additionalInfo: additionalInfo ?? this.additionalInfo,
    );
  }
}
