import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/post_model.dart';

class DataSeederService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final List<String> _names = [
    'Ahmed Ali', 'Sara Mohamed', 'John Doe', 'Jane Smith', 'Youssef Hassan',
    'Amira Mahmoud', 'Michael Brown', 'Emily Davis', 'Omar Khalid', 'Layla Ibrahim',
    'David Wilson', 'Sophia Martinez', 'Zaid Al-Fahd', 'Nour El-Din', 'Chris Evans',
    'Emma Watson', 'Robert Downey', 'Scarlett Johansson', 'Tom Hardy', 'Anne Hathaway',
    'Mustafa Kamal', 'Fatma Zahra', 'Hana Khalil', 'Karim Abdel Aziz', 'Mona Zaki',
    'Mohamed Ramadan', 'Hend Sabri', 'Bassem Youssef', 'Nadine Njeim', 'Tamer Hosny'
  ];

  final List<String> _positions = [
    'Flutter Developer', 'UI/UX Designer', 'Backend Engineer', 'Product Manager',
    'Frontend Developer', 'Data Scientist', 'DevOps Engineer', 'Mobile App Architect',
    'Quality Assurance', 'Project Coordinator', 'Full Stack Developer', 'Cybersecurity Expert'
  ];

  final List<String> _cities = ['Cairo', 'Dubai', 'Riyadh', 'New York', 'London', 'Paris', 'Berlin', 'Tokyo', 'Casablanca', 'Amman'];
  final List<String> _countries = ['Egypt', 'UAE', 'Saudi Arabia', 'USA', 'UK', 'France', 'Germany', 'Japan', 'Morocco', 'Jordan'];

  final List<String> _postTexts = [
    "Just finished a great coding session! #Flutter #CodingLife",
    "Does anyone have tips for optimizing Firestore queries?",
    "Looking for a UI/UX designer for a new project. DM me!",
    "The new Flutter update is amazing. The performance gains are real.",
    "Coffee and code, the perfect combination for a Sunday morning.",
    "Excited to announce that I've joined the Developers Zone team!",
    "What's your favorite state management library in Flutter? Bloc, Provider, or Riverpod?",
    "Just published my first package on pub.dev! Check it out.",
    "Working on a new feature for our app. Can't wait to share it with you all.",
    "Learning Go for backend development. It's surprisingly fast and efficient.",
    "Who's attending the Flutter Forward conference this year?",
    "A clean code is a Happy code. #CleanCode #SoftwareEngineering",
    "Debugging is like being the detective in a crime movie where you are also the murderer.",
    "The best way to predict the future is to invent it. - Alan Kay",
    "Don't worry if it doesn't work right. If everything did, you'd be out of a job.",
    "Responsive design is not about making things look good on mobile, but about making them work everywhere.",
    "Started a new project using Next.js and Tailwind. Loving the developer experience so far.",
    "Security is not an afterthought; it should be integrated into every step of development.",
    "Open source is the soul of the developer community. Contribute today!",
    "The biggest challenge in softare isn't the code, but the people behind it."
  ];

  final List<String> _demoImages = [
    'https://images.unsplash.com/photo-1542831371-29b0f74f9713?ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=60',
    'https://images.unsplash.com/photo-1517694712202-14dd9538aa97?ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=60',
    'https://images.unsplash.com/photo-1498050108023-c5249f4df085?ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=60',
    'https://images.unsplash.com/photo-1587620962725-abab7fe55159?ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=60',
    'https://images.unsplash.com/photo-1461749280684-dccba630e2f6?ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=60',
    'https://images.unsplash.com/photo-1555066931-4365d14bab8c?ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=60',
    'https://images.unsplash.com/photo-1498050108023-c5249f4df085?ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=60',
  ];

  Future<void> seedData() async {
    final Random random = Random();
    
    // Create 30 Dummy Users
    for (int i = 0; i < 30; i++) {
      String uid = 'dummy_user_${i + 1}';
      String name = _names[i % _names.length];
      String position = _positions[random.nextInt(_positions.length)];
      String city = _cities[random.nextInt(_cities.length)];
      String country = _countries[random.nextInt(_countries.length)];
      
      UserModel user = UserModel(
        uid: uid,
        name: name,
        email: 'user${i + 1}@example.com',
        profileImage: 'https://i.pravatar.cc/150?u=$uid',
        position: position,
        bio: 'Passionate $position based in $city. Love building amazing software and collaborating with other developers.',
        city: city,
        country: country,
        isVerified: random.nextInt(10) > 7, // 30% chance of being verified
        isApproved: true,
        isBanned: false,
        isAdmin: false,
        createdAt: DateTime.now().subtract(Duration(days: 30 + random.nextInt(335))),
        lastSeen: DateTime.now().subtract(Duration(minutes: random.nextInt(1440))),
      );

      // Save User
      await _db.collection('users').doc(uid).set(user.toMap());

      // Create 2-5 posts per user
      int postCount = 2 + random.nextInt(4);
      for (int j = 0; j < postCount; j++) {
        String postId = 'post_${uid}_$j';
        List<String> images = [];
        // 40% chance of having an image
        if (random.nextInt(10) > 6) {
          images.add(_demoImages[random.nextInt(_demoImages.length)]);
        }

        // Randomly add some likes from other dummy users
        List<String> likes = [];
        int likeCount = random.nextInt(15);
        for (int l = 0; l < likeCount; l++) {
          String likerId = 'dummy_user_${random.nextInt(30) + 1}';
          if (!likes.contains(likerId)) likes.add(likerId);
        }

        PostModel post = PostModel(
          id: postId,
          authorId: uid,
          authorName: name,
          authorProfileImage: user.profileImage,
          authorPosition: position,
          isAuthorVerified: user.isVerified,
          text: _postTexts[random.nextInt(_postTexts.length)],
          images: images,
          likes: likes,
          commentCount: random.nextInt(10),
          createdAt: DateTime.now().subtract(Duration(
            days: random.nextInt(20),
            hours: random.nextInt(23),
          )),
        );

        await _db.collection('posts').doc(postId).set(post.toMap());
      }
    }
  }

  Future<void> clearDummyData() async {
    // Helper to clean up
    final userDocs = await _db.collection('users').where(FieldPath.documentId, isGreaterThanOrEqualTo: 'dummy_user_').get();
    final batch = _db.batch();
    for (var doc in userDocs.docs) {
      if (doc.id.startsWith('dummy_user_')) {
        batch.delete(doc.reference);
      }
    }
    
    final postDocs = await _db.collection('posts').get();
    for (var doc in postDocs.docs) {
      if (doc.id.startsWith('post_dummy_user_')) {
        batch.delete(doc.reference);
      }
    }
    
    await batch.commit();
  }
}
