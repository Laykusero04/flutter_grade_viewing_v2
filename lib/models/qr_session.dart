class QRSession {
  final String subjectTeacherId; // This is the document ID from subject_teachers
  final String teacherId;
  final String subjectId;
  final DateTime assignedAt;
  final bool isActive;
  final int maxEnrollments;
  final int currentEnrollments;

  QRSession({
    required this.subjectTeacherId,
    required this.teacherId,
    required this.subjectId,
    required this.assignedAt,
    this.isActive = true,
    this.maxEnrollments = 50,
    this.currentEnrollments = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'subjectTeacherId': subjectTeacherId,
      'teacherId': teacherId,
      'subjectId': subjectId,
      'assignedAt': assignedAt.millisecondsSinceEpoch,
      'isActive': isActive,
      'maxEnrollments': maxEnrollments,
      'currentEnrollments': currentEnrollments,
    };
  }

  factory QRSession.fromMap(Map<String, dynamic> map) {
    return QRSession(
      subjectTeacherId: map['subjectTeacherId'] ?? '',
      teacherId: map['teacherId'] ?? '',
      subjectId: map['subjectId'] ?? '',
      assignedAt: map['assignedAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['assignedAt']) 
          : DateTime.now(),
      isActive: map['isActive'] ?? true,
      maxEnrollments: map['maxEnrollments'] ?? 50,
      currentEnrollments: map['currentEnrollments'] ?? 0,
    );
  }

  QRSession copyWith({
    String? subjectTeacherId,
    String? teacherId,
    String? subjectId,
    DateTime? assignedAt,
    bool? isActive,
    int? maxEnrollments,
    int? currentEnrollments,
  }) {
    return QRSession(
      subjectTeacherId: subjectTeacherId ?? this.subjectTeacherId,
      teacherId: teacherId ?? this.teacherId,
      subjectId: subjectId ?? this.subjectId,
      assignedAt: assignedAt ?? this.assignedAt,
      isActive: isActive ?? this.isActive,
      maxEnrollments: maxEnrollments ?? this.maxEnrollments,
      currentEnrollments: currentEnrollments ?? this.currentEnrollments,
    );
  }

  bool get canEnroll => isActive && currentEnrollments < maxEnrollments;
}
