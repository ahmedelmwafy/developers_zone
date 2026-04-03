import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/admin_controller.dart';
import '../models/user_model.dart';
import '../providers/app_provider.dart';
import 'ad_management_page.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalization.of(context)!;
    final adminController = Provider.of<AdminController>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(locale.translate('admin')),
        actions: [
          IconButton(
            icon: const Icon(Icons.ads_click),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdManagementPage())),
          ),
        ],
      ),
      body: StreamBuilder<List<UserModel>>(
        stream: adminController.getAllUsers(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text('No users found'));
          final users = snapshot.data!;
          
          return ListView.separated(
            itemCount: users.length,
            separatorBuilder: (context, index) => const Divider(color: Colors.grey, thickness: 0.1),
            itemBuilder: (context, index) {
              final user = users[index];
              return ListTile(
                leading: CircleAvatar(backgroundImage: NetworkImage(user.profileImage)),
                title: Row(
                  children: [
                    Text(user.name, style: const TextStyle(color: Colors.white)),
                    if (user.isVerified) const Icon(Icons.verified, color: Colors.blue, size: 16),
                  ],
                ),
                subtitle: Text(user.email, style: const TextStyle(color: Colors.grey)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Verification Toggle
                    IconButton(
                      icon: Icon(user.isVerified ? Icons.verified : Icons.verified_outlined, 
                        color: user.isVerified ? Colors.blue : Colors.grey),
                      tooltip: locale.translate(user.isVerified ? 'unverify_user' : 'verify_user'),
                      onPressed: () => adminController.verifyUser(user.uid, !user.isVerified),
                    ),
                    // Approval Toggle
                    IconButton(
                      icon: Icon(user.isApproved ? Icons.check_circle : Icons.check_circle_outline, 
                        color: user.isApproved ? Colors.green : Colors.grey),
                      tooltip: locale.translate(user.isApproved ? 'unapprove_user' : 'approve_user'),
                      onPressed: () => adminController.approveUser(user.uid, !user.isApproved),
                    ),
                    // Admin Toggle
                    IconButton(
                      icon: Icon(user.isAdmin ? Icons.admin_panel_settings : Icons.admin_panel_settings_outlined, 
                        color: user.isAdmin ? Colors.orange : Colors.grey),
                      tooltip: locale.translate(user.isAdmin ? 'revoke_admin' : 'make_admin'),
                      onPressed: () => adminController.toggleAdmin(user.uid, !user.isAdmin),
                    ),
                    // Ban Toggle
                    Switch(
                      value: !user.isBanned,
                      onChanged: (active) => adminController.banUser(user.uid, !active),
                      activeThumbColor: Colors.green,
                      inactiveThumbColor: Colors.red,
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
