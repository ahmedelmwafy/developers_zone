import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _LegalScreen(
      title: 'Privacy Policy',
      icon: Icons.privacy_tip_outlined,
      sections: const [
        _LegalSection(
          title: 'Data We Collect',
          body:
              'We collect minimal personal information needed to provide our services, including your name, email address, and profile content you choose to share within Developers Zone.',
        ),
        _LegalSection(
          title: 'How We Use Your Data',
          body:
              'Your information is used exclusively to facilitate communication and social interaction within the app. We do not sell, rent, or share your personal data with third parties for marketing purposes.',
        ),
        _LegalSection(
          title: 'Data Security',
          body:
              'We use Firebase—a Google-backed infrastructure—to store and protect your data. All communications are encrypted in transit using industry-standard TLS protocols.',
        ),
        _LegalSection(
          title: 'Your Rights',
          body:
              'You have the right to access, update, or delete your account and its associated data at any time from within the app settings. Contact us if you need further assistance.',
        ),
        _LegalSection(
          title: 'Contact',
          body:
              'If you have questions about this Privacy Policy, please reach out through the app or at ahmedelmwafy@gmail.com.',
        ),
      ],
    );
  }
}

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _LegalScreen(
      title: 'Terms & Conditions',
      icon: Icons.gavel_outlined,
      sections: const [
        _LegalSection(
          title: 'Community Standards',
          body:
              'By using Developers Zone, you agree to treat all community members with respect. Harassment, bullying, discrimination, spam, or any form of abusive behavior is strictly prohibited.',
        ),
        _LegalSection(
          title: 'Content Responsibility',
          body:
              'You are solely responsible for the content you post. Do not share illegal content, copyrighted material without permission, or content that violates the rights of others.',
        ),
        _LegalSection(
          title: 'Account Suspension',
          body:
              'Violations of these terms will result in warnings, temporary suspension, or permanent banning of your account, at the sole discretion of our admin team.',
        ),
        _LegalSection(
          title: 'Service Availability',
          body:
              'We strive to keep Developers Zone available at all times, but we do not guarantee uninterrupted access. We reserve the right to modify or discontinue features without prior notice.',
        ),
        _LegalSection(
          title: 'Changes to Terms',
          body:
              'These terms may be updated periodically. Continued use of the app after changes are posted constitutes your acceptance of the new terms.',
        ),
      ],
    );
  }
}

// ─── Shared Internal Widgets ────────────────────────────────────────────────

class _LegalScreen extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<_LegalSection> sections;

  const _LegalScreen(
      {required this.title, required this.icon, required this.sections});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.background,
            expandedHeight: 130,
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF0E0E20), AppColors.background],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    left: 20,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(icon, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Text(title,
                            style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(
                  color: Colors.white.withValues(alpha: 0.06), height: 1),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final section = sections[index];
                  return _SectionCard(
                      number: index + 1,
                      title: section.title,
                      body: section.body);
                },
                childCount: sections.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegalSection {
  final String title;
  final String body;
  const _LegalSection({required this.title, required this.body});
}

class _SectionCard extends StatelessWidget {
  final int number;
  final String title;
  final String body;

  const _SectionCard(
      {required this.number, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Number badge
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                number.toString(),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 15)),
                const SizedBox(height: 8),
                Text(body,
                    style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.6)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
