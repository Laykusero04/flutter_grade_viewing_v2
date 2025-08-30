class Assignment {
  final String uid;
  final String subjectId;
  final String teacherId;
  final String name;
  final String description;
  final double maxScore;
  final String gradeType;
  final double weight;
  final DateTime dueDate;
  final DateTime dateCreated;
  final bool isActive;

  Assignment({
    required this.uid,
    required this.subjectId,
    required this.teacherId,
    required this.name,
    required this.description,
    required this.maxScore,
    required this.gradeType,
    required this.weight,
    required this.dueDate,
    required this.dateCreated,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'subjectId': subjectId,
      'teacherId': teacherId,
      'name': name,
      'description': description,
      'maxScore': maxScore,
      'gradeType': gradeType,
      'weight': weight,
      'dueDate': dueDate.millisecondsSinceEpoch,
      'dateCreated': dateCreated.millisecondsSinceEpoch,
      'isActive': isActive,
    };
  }

  Map<String, dynamic> toFirestoreMap() {
    return {
      'subjectId': subjectId,
      'teacherId': teacherId,
      'name': name,
      'description': description,
      'maxScore': maxScore,
      'gradeType': gradeType,
      'weight': weight,
      'dueDate': dueDate.millisecondsSinceEpoch,
      'dateCreated': dateCreated.millisecondsSinceEpoch,
      'isActive': isActive,
    };
  }

  factory Assignment.fromMap(Map<String, dynamic> map) {
    return Assignment(
      uid: map['uid'] ?? '',
      subjectId: map['subjectId'] ?? '',
      teacherId: map['teacherId'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      maxScore: (map['maxScore'] ?? 0).toDouble(),
      gradeType: map['gradeType'] ?? '',
      weight: (map['weight'] ?? 0).toDouble(),
      dueDate: map['dueDate'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['dueDate']) 
          : DateTime.now(),
      dateCreated: map['dateCreated'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['dateCreated']) 
          : DateTime.now(),
      isActive: map['isActive'] ?? true,
    );
  }

  Assignment copyWith({
    String? uid,
    String? subjectId,
    String? teacherId,
    String? name,
    String? description,
    double? maxScore,
    String? gradeType,
    double? weight,
    DateTime? dueDate,
    DateTime? dateCreated,
    bool? isActive,
  }) {
    return Assignment(
      uid: uid ?? this.uid,
      subjectId: subjectId ?? this.subjectId,
      teacherId: teacherId ?? this.teacherId,
      name: name ?? this.name,
      description: description ?? this.description,
      maxScore: maxScore ?? this.maxScore,
      gradeType: gradeType ?? this.gradeType,
      weight: weight ?? this.weight,
      dueDate: dueDate ?? this.dueDate,
      dateCreated: dateCreated ?? this.dateCreated,
      isActive: isActive ?? this.isActive,
    );
  }
}
