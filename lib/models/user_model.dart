class UserModel {
  final String name;
  final String mobile;
  final String email;
  final String gender;
  final String? profileImagePath;

  UserModel({
    required this.name,
    required this.mobile,
    required this.email,
    required this.gender,
    this.profileImagePath,
  });

  // Convert UserModel to Map (for storage)
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'mobile': mobile,
      'email': email,
      'gender': gender,
      'profileImagePath': profileImagePath,
    };
  }

  // Create UserModel from Map (from storage)
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      name: json['name'] as String,
      mobile: json['mobile'] as String,
      email: json['email'] as String,
      gender: json['gender'] as String,
      profileImagePath: json['profileImagePath'] as String?,
    );
  }

  // Create a copy with updated values
  UserModel copyWith({
    String? name,
    String? mobile,
    String? email,
    String? gender,
    String? profileImagePath,
  }) {
    return UserModel(
      name: name ?? this.name,
      mobile: mobile ?? this.mobile,
      email: email ?? this.email,
      gender: gender ?? this.gender,
      profileImagePath: profileImagePath ?? this.profileImagePath,
    );
  }
}