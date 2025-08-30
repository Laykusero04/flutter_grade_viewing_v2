class Grade {
  final String uid;
  final String enrollmentId;
  final String subjectId;
  final String studentId;
  final String teacherId;
  final String assignmentName;
  final double score;
  final double maxScore;
  final String gradeType;
  final DateTime dateRecorded;
  final String? comments;
  final double? weight;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Grade({
    required this.uid,
    required this.enrollmentId,
    required this.subjectId,
    required this.studentId,
    required this.teacherId,
    required this.assignmentName,
    required this.score,
    required this.maxScore,
    required this.gradeType,
    required this.dateRecorded,
    this.comments,
    this.weight,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  double get percentage => (score / maxScore) * 100;
  String get letterGrade {
    if (percentage >= 90) return 'A';
    if (percentage >= 80) return 'B';
    if (percentage >= 70) return 'C';
    if (percentage >= 60) return 'D';
    return 'F';
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'enrollmentId': enrollmentId,
      'subjectId': subjectId,
      'studentId': studentId,
      'teacherId': teacherId,
      'assignmentName': assignmentName,
      'score': score,
      'maxScore': maxScore,
      'gradeType': gradeType,
      'dateRecorded': dateRecorded.millisecondsSinceEpoch,
      'comments': comments,
      'weight': weight,
      'isActive': isActive,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  Map<String, dynamic> toFirestoreMap() {
    return {
      'enrollmentId': enrollmentId,
      'subjectId': subjectId,
      'studentId': studentId,
      'teacherId': teacherId,
      'assignmentName': assignmentName,
      'score': score,
      'maxScore': maxScore,
      'gradeType': gradeType,
      'dateRecorded': dateRecorded.millisecondsSinceEpoch,
      'comments': comments,
      'weight': weight,
      'isActive': isActive,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory Grade.fromMap(Map<String, dynamic> map) {
    return Grade(
      uid: map['uid'] ?? '',
      enrollmentId: map['enrollmentId'] ?? '',
      subjectId: map['subjectId'] ?? '',
      studentId: map['studentId'] ?? '',
      teacherId: map['teacherId'] ?? '',
      assignmentName: map['assignmentName'] ?? '',
      score: (map['score'] ?? 0).toDouble(),
      maxScore: (map['maxScore'] ?? 0).toDouble(),
      gradeType: map['gradeType'] ?? '',
      dateRecorded: map['dateRecorded'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['dateRecorded']) 
          : DateTime.now(),
      comments: map['comments'],
      weight: map['weight']?.toDouble(),
      isActive: map['isActive'] ?? true,
      createdAt: map['createdAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt']) 
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt']) 
          : DateTime.now(),
    );
  }

  Grade copyWith({
    String? uid,
    String? enrollmentId,
    String? subjectId,
    String? studentId,
    String? teacherId,
    String? assignmentName,
    double? score,
    double? maxScore,
    String? gradeType,
    DateTime? dateRecorded,
    String? comments,
    double? weight,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Grade(
      uid: uid ?? this.uid,
      enrollmentId: enrollmentId ?? this.enrollmentId,
      subjectId: subjectId ?? this.subjectId,
      studentId: studentId ?? this.studentId,
      teacherId: teacherId ?? this.teacherId,
      assignmentName: assignmentName ?? this.assignmentName,
      score: score ?? this.score,
      maxScore: maxScore ?? this.maxScore,
      gradeType: gradeType ?? this.gradeType,
      dateRecorded: dateRecorded ?? this.dateRecorded,
      comments: comments ?? this.comments,
      weight: weight ?? this.weight,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
