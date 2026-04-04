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
  final bool isApproved;
  final List<String> blockedUsers;
  final List<String> followers; // uids who follow this user
  final List<String> following; // uids this user follows
  final String? fcmToken;
  final bool pushNotifications;
  final bool emailUpdates;
  final bool collabsNotifications;
  final List<String> mutedChats;   // chat IDs muted by this user
  final List<String> hiddenChats;  // chat IDs hidden/deleted by this user
  final DateTime? lastSeen;
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
    this.followers = const [],
    this.following = const [],
    this.fcmToken,
    this.pushNotifications = true,
    this.emailUpdates = true,
    this.collabsNotifications = true,
    this.mutedChats = const [],
    this.hiddenChats = const [],
    this.lastSeen,
    this.createdAt,
  });

  int get age {
    if (birthDate == null) return 0;
    final now = DateTime.now();
    int age = now.year - birthDate!.year;
    if (now.month < birthDate!.month ||
        (now.month == birthDate!.month && now.day < birthDate!.day)) {
      age--;
    }
    return age;
  }

  String get joinedAgo {
    if (createdAt == null) return 'Recently joined';
    final now = DateTime.now();
    final diff = now.difference(createdAt!);
    if (diff.inDays < 1) return 'Joined today';
    if (diff.inDays == 1) return 'Joined yesterday';
    if (diff.inDays < 7) return 'Joined ${diff.inDays} days ago';
    if (diff.inDays < 30) return 'Joined ${(diff.inDays / 7).floor()} week${(diff.inDays / 7).floor() > 1 ? 's' : ''} ago';
    if (diff.inDays < 365) return 'Joined ${(diff.inDays / 30).floor()} month${(diff.inDays / 30).floor() > 1 ? 's' : ''} ago';
    return 'Joined ${(diff.inDays / 365).floor()} year${(diff.inDays / 365).floor() > 1 ? 's' : ''} ago';
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
      followers: data['followers'] != null ? List<String>.from(data['followers']) : [],
      following: data['following'] != null ? List<String>.from(data['following']) : [],
      fcmToken: data['fcmToken'],
      pushNotifications: data['pushNotifications'] ?? true,
      emailUpdates: data['emailUpdates'] ?? true,
      collabsNotifications: data['collabsNotifications'] ?? true,
      mutedChats: data['mutedChats'] != null ? List<String>.from(data['mutedChats']) : [],
      hiddenChats: data['hiddenChats'] != null ? List<String>.from(data['hiddenChats']) : [],
      lastSeen: (data['lastSeen'] as Timestamp?)?.toDate(),
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
      'followers': followers,
      'following': following,
      'fcmToken': fcmToken,
      'pushNotifications': pushNotifications,
      'emailUpdates': emailUpdates,
      'collabsNotifications': collabsNotifications,
      'mutedChats': mutedChats,
      'hiddenChats': hiddenChats,
      'lastSeen': lastSeen != null ? Timestamp.fromDate(lastSeen!) : null,
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
    List<String>? followers,
    List<String>? following,
    String? fcmToken,
    bool? pushNotifications,
    bool? emailUpdates,
    bool? collabsNotifications,
    List<String>? mutedChats,
    List<String>? hiddenChats,
    DateTime? lastSeen,
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
      followers: followers ?? this.followers,
      following: following ?? this.following,
      fcmToken: fcmToken ?? this.fcmToken,
      pushNotifications: pushNotifications ?? this.pushNotifications,
      emailUpdates: emailUpdates ?? this.emailUpdates,
      collabsNotifications: collabsNotifications ?? this.collabsNotifications,
      mutedChats: mutedChats ?? this.mutedChats,
      hiddenChats: hiddenChats ?? this.hiddenChats,
      lastSeen: lastSeen ?? this.lastSeen,
      createdAt: createdAt,
    );
  }
}
