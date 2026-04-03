import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/ad_model.dart';
import '../controllers/admin_controller.dart';
import '../providers/app_provider.dart';

class AdManagementPage extends StatelessWidget {
  const AdManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalization.of(context)!;
    final adminController = Provider.of<AdminController>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(locale.translate('ads')),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: () => _showAddAdDialog(context)),
        ],
      ),
      body: StreamBuilder<List<AdModel>>(
        stream: adminController.getAds(), // All ads for management
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text('No ads found'));
          final ads = snapshot.data!;
          return ListView.builder(
            itemCount: ads.length,
            itemBuilder: (context, index) {
              final ad = ads[index];
              return ListTile(
                leading: Image.network(ad.imageUrl, width: 50, height: 50, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.image)),
                title: Text(ad.title, style: const TextStyle(color: Colors.white)),
                subtitle: Text(ad.type, style: const TextStyle(color: Colors.grey)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Switch(value: ad.active, onChanged: (val) => adminController.updateAd(AdModel(id: ad.id, title: ad.title, imageUrl: ad.imageUrl, targetUrl: ad.targetUrl, active: val, type: ad.type))),
                    IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => adminController.deleteAd(ad.id)),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showAddAdDialog(BuildContext context) {
    final titleController = TextEditingController();
    final imageUrlController = TextEditingController();
    final targetUrlController = TextEditingController();
    String type = 'home';
    final adminController = Provider.of<AdminController>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Ad'),
        backgroundColor: const Color(0xFF16161A),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Title')),
            TextField(controller: imageUrlController, decoration: const InputDecoration(labelText: 'Image URL')),
            TextField(controller: targetUrlController, decoration: const InputDecoration(labelText: 'Target URL (optional)')),
            DropdownButton<String>(
              value: type,
              items: ['home', 'splash'].map((String val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
              onChanged: (val) => type = val ?? 'home',
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              adminController.addAd(AdModel(id: '', title: titleController.text, imageUrl: imageUrlController.text, targetUrl: targetUrlController.text, type: type));
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
