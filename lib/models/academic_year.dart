class AcademicYear {
  final String id;
  final int startYear;
  final int endYear;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  AcademicYear({
    required this.id,
    required this.startYear,
    required this.endYear,
    this.isActive = false,
    required this.createdAt,
    this.updatedAt,
  });

  String get displayName => '$startYear-$endYear';
  String get fullDisplayName => 'Academic Year $startYear-$endYear';
  String get yearRange => '$startYear - $endYear';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'startYear': startYear,
      'endYear': endYear,
      'isActive': isActive,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
    };
  }

  factory AcademicYear.fromMap(Map<String, dynamic> map) {
    return AcademicYear(
      id: map['id'] ?? '',
      startYear: map['startYear'] ?? DateTime.now().year,
      endYear: map['endYear'] ?? DateTime.now().year + 1,
      isActive: map['isActive'] ?? false,
      createdAt: map['createdAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt']) 
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt']) 
          : null,
    );
  }

  AcademicYear copyWith({
    String? id,
    int? startYear,
    int? endYear,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AcademicYear(
      id: id ?? this.id,
      startYear: startYear ?? this.startYear,
      endYear: endYear ?? this.endYear,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'AcademicYear(id: $id, startYear: $startYear, endYear: $endYear, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AcademicYear && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
