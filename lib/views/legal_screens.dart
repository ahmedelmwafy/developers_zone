import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../providers/app_provider.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalization.of(context)!;
    return _LegalScreen(
      title: locale.translate('pp_title'),
      icon: Icons.privacy_tip_outlined,
      sections: [
        _LegalSection(
          title: locale.translate('pp_sec1_title'),
          body: locale.translate('pp_sec1_body'),
        ),
        _LegalSection(
          title: locale.translate('pp_sec2_title'),
          body: locale.translate('pp_sec2_body'),
        ),
        _LegalSection(
          title: locale.translate('pp_sec3_title'),
          body: locale.translate('pp_sec3_body'),
        ),
        _LegalSection(
          title: locale.translate('pp_sec4_title'),
          body: locale.translate('pp_sec4_body'),
        ),
        _LegalSection(
          title: locale.translate('pp_sec5_title'),
          body: locale.translate('pp_sec5_body'),
        ),
      ],
    );
  }
}

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalization.of(context)!;
    return _LegalScreen(
      title: locale.translate('tc_title'),
      icon: Icons.gavel_outlined,
      sections: [
        _LegalSection(
          title: locale.translate('tc_sec1_title'),
          body: locale.translate('tc_sec1_body'),
        ),
        _LegalSection(
          title: locale.translate('tc_sec2_title'),
          body: locale.translate('tc_sec2_body'),
        ),
        _LegalSection(
          title: locale.translate('tc_sec3_title'),
          body: locale.translate('tc_sec3_body'),
        ),
        _LegalSection(
          title: locale.translate('tc_sec4_title'),
          body: locale.translate('tc_sec4_body'),
        ),
        _LegalSection(
          title: locale.translate('tc_sec5_title'),
          body: locale.translate('tc_sec5_body'),
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
