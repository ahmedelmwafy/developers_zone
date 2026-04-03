import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String profileImage;
  final String position;
  final String bio;
  final String city;
  final String country;
  final DateTime? birthDate;
  final String? gender;
  final Map<String, String>? socialLinks;
  final bool isAdmin;
  final bool isBanned;
  final bool isVerified;
  final bool isApproved; // Added for approval system
  final List<String> blockedUsers;
  final String? fcmToken; // To send notifications
  final DateTime? createdAt;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.profileImage = '',
    this.position = '',
    this.bio = '',
    this.city = '',
    this.country = '',
    this.birthDate,
    this.gender,
    this.socialLinks,
    this.isAdmin = false,
    this.isBanned = false,
    this.isVerified = false,
    this.isApproved = false,
    this.blockedUsers = const [],
    this.fcmToken,
    this.createdAt,
  });

  int get age {
    if (birthDate == null) return 0;
    final now = DateTime.now();
    int age = now.year - birthDate!.year;
    if (now.month < birthDate!.month || (now.month == birthDate!.month && now.day < birthDate!.day)) {
      age--;
    }
    return age;
  }

  factory UserModel.fromMap(Map<String, dynamic> data) {
    return UserModel(
      uid: data['uid'] ?? '',
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      profileImage: data['profileImage'] ?? '',
      position: data['position'] ?? '',
      bio: data['bio'] ?? '',
      city: data['city'] ?? '',
      country: data['country'] ?? '',
      birthDate: (data['birthDate'] as Timestamp?)?.toDate(),
      gender: data['gender'],
      socialLinks: data['socialLinks'] != null ? Map<String, String>.from(data['socialLinks']) : null,
      isAdmin: data['isAdmin'] ?? false,
      isBanned: data['isBanned'] ?? false,
      isVerified: data['isVerified'] ?? false,
      isApproved: data['isApproved'] ?? false,
      blockedUsers: data['blockedUsers'] != null ? List<String>.from(data['blockedUsers']) : [],
      fcmToken: data['fcmToken'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'profileImage': profileImage,
      'position': position,
      'bio': bio,
      'city': city,
      'country': country,
      'birthDate': birthDate != null ? Timestamp.fromDate(birthDate!) : null,
      'gender': gender,
      'socialLinks': socialLinks,
      'isAdmin': isAdmin,
      'isBanned': isBanned,
      'isVerified': isVerified,
      'isApproved': isApproved,
      'blockedUsers': blockedUsers,
      'fcmToken': fcmToken,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }

  UserModel copyWith({
    String? name,
    String? profileImage,
    String? position,
    String? bio,
    String? city,
    String? country,
    DateTime? birthDate,
    String? gender,
    Map<String, String>? socialLinks,
    bool? isBanned,
    bool? isVerified,
    bool? isApproved,
    bool? isAdmin,
    List<String>? blockedUsers,
    String? fcmToken,
  }) {
    return UserModel(
      uid: uid,
      name: name ?? this.name,
      email: email,
      profileImage: profileImage ?? this.profileImage,
      position: position ?? this.position,
      bio: bio ?? this.bio,
      city: city ?? this.city,
      country: country ?? this.country,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      socialLinks: socialLinks ?? this.socialLinks,
      isAdmin: isAdmin ?? this.isAdmin,
      isBanned: isBanned ?? this.isBanned,
      isVerified: isVerified ?? this.isVerified,
      isApproved: isApproved ?? this.isApproved,
      blockedUsers: blockedUsers ?? this.blockedUsers,
      fcmToken: fcmToken ?? this.fcmToken,
      createdAt: createdAt,
    );
  }
}
