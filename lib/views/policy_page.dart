import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/app_provider.dart';

class PolicyPage extends StatelessWidget {
  final String title;
  final String contentKey;

  const PolicyPage({
    required this.title,
    required this.contentKey,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalization.of(context)!;
    
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D0D),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF00E5FF)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          title,
          style: AppLocalization.digitalFont(context, 
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF161616),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Text(
                locale.translate(contentKey),
                style: AppLocalization.digitalFont(context, 
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                  height: 1.8,
                ),
              ),
            ),
            const SizedBox(height: 40),
            Center(
              child: Text(
                'END OF PROTOCOL',
                style: AppLocalization.digitalFont(context, 
                  color: Colors.white.withOpacity(0.1),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
