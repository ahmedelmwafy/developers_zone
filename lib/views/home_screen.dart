import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../controllers/admin_controller.dart';
import '../providers/app_provider.dart';
import '../models/ad_model.dart';
import 'feed_page.dart';
import 'chat_list_page.dart';
import 'profile_page.dart';
import 'admin_dashboard_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const FeedPage(),
    const ChatListPage(),
    const ProfilePage(),
    const AdminDashboardPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalization.of(context)!;
    final currentUser = Provider.of<AuthController>(context).currentUser;
    final isAdmin = currentUser?.isAdmin ?? false;

    return Scaffold(
      body: Column(
        children: [
          Expanded(child: _pages[_currentIndex]),
          if (_currentIndex == 0) // Only on Feed Page
            const HomeAdsSection(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == 3 && !isAdmin) return; // Only for admin
          setState(() => _currentIndex = index);
        },
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.feed), label: locale.translate('feed')),
          BottomNavigationBarItem(icon: const Icon(Icons.chat), label: locale.translate('chat')),
          BottomNavigationBarItem(icon: const Icon(Icons.person), label: locale.translate('profile')),
          if (isAdmin)
             BottomNavigationBarItem(icon: const Icon(Icons.admin_panel_settings), label: locale.translate('admin')),
        ],
        selectedItemColor: const Color(0xFF673AB7),
        unselectedItemColor: Colors.grey,
        backgroundColor: const Color(0xFF0F0E17),
      ),
    );
  }
}

class HomeAdsSection extends StatelessWidget {
  const HomeAdsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final adminController = Provider.of<AdminController>(context);
    
    return StreamBuilder<List<AdModel>>(
      stream: adminController.getAds(type: 'home'),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox.shrink();
        final ads = snapshot.data!;
        
        return Container(
          height: 100,
          margin: const EdgeInsets.symmetric(vertical: 10),
          child: PageView.builder(
            itemCount: ads.length,
            itemBuilder: (context, index) {
              final ad = ads[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  image: DecorationImage(image: NetworkImage(ad.imageUrl), fit: BoxFit.cover),
                ),
                child: Center(
                  child: Text(
                    ad.title,
                    style: const TextStyle(color: Colors.white, backgroundColor: Colors.black26),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
