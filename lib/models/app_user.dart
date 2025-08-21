class AppUser {
  final String uid;
  final String email;
  final String firstName;
  final String lastName;
  final String schoolId;
  final int userRole; // 1=admin, 2=teacher, 3=student

  AppUser({
    required this.uid,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.schoolId,
    required this.userRole,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'schoolId': schoolId,
      'userRole': userRole,
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      uid: map['uid'],
      email: map['email'],
      firstName: map['firstName'],
      lastName: map['lastName'],
      schoolId: map['schoolId'],
      userRole: map['userRole'],
    );
  }
}
