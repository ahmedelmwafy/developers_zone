import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/auth_controller.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import 'profile_page.dart';
import '../providers/app_provider.dart';
import 'components/shimmer_loading.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  List<UserModel> _searchResults = [];
  bool _isLoading = false;
  String _query = '';
  // Filtering logic
  bool _isVerifiedOnly = false;
  String _selectedRole = 'ALL';

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _query = query;
        });
        if (query.isNotEmpty) {
          _performSearch(query);
        } else {
          setState(() {
            _searchResults = [];
          });
        }
      }
    });
  }

  Future<void> _performSearch(String query) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authController =
          Provider.of<AuthController>(context, listen: false);
      final results = await authController.searchUsers(query);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalization.of(context)!;
    final auth = Provider.of<AuthController>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            _buildSearchBar(locale),
            const SizedBox(height: 32),
            _SectionHeader(
              title: _query.isEmpty
                  ? locale.translate('VERIFIED_CONTRIBUTORS')
                  : '${locale.translate('SEARCH_RESULTS')} (${_searchResults.length})',
              trailing: GestureDetector(
                onTap: _showFilterDialog,
                child: Row(
                  children: [
                    Text(_selectedRole == 'ALL' ? locale.translate('SORT_BY_RELEVANCE') : _selectedRole.toUpperCase(),
                        style: GoogleFonts.spaceGrotesk(
                            color: const Color(0xFF00E5FF),
                            fontSize: 10,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(width: 4),
                    const Icon(Icons.filter_list_rounded,
                        color: Color(0xFF00E5FF), size: 16),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (_isLoading)
              ...List.generate(
                  3,
                  (index) => const Padding(
                        padding: EdgeInsets.only(bottom: 16),
                        child: UserTileShimmer(),
                      ))
            else if (_query.isEmpty)
              _buildLiveContributors(locale, auth)
            else
              _buildSearchResults(locale),
            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(AppLocalization locale) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        style: GoogleFonts.inter(color: Colors.white, fontSize: 15),
        decoration: InputDecoration(
          hintText: locale.translate('search_hint'),
          hintStyle: GoogleFonts.inter(color: Colors.white.withOpacity(0.15)),
          prefixIcon: Icon(Icons.search_rounded,
              color: Colors.white.withOpacity(0.3), size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 20),
        ),
      ),
    );
  }

  Widget _buildLiveContributors(AppLocalization locale, AuthController auth) {
    return StreamBuilder<List<UserModel>>(
      stream: FirestoreService().streamAllUsers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Column(
            children: List.generate(
              3,
              (index) => const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: UserTileShimmer(),
              ),
            ),
          );
        }
        
        var users = snapshot.data
                ?.where((u) =>
                    !u.uid.startsWith('dummy_') &&
                    u.uid != auth.currentUser?.uid &&
                    !(auth.currentUser?.blockedUsers.contains(u.uid) ?? false))
                .toList() ??
            [];

        // APPLY FILTERS TO LIVE LIST
        if (_isVerifiedOnly) {
          users = users.where((u) => u.isVerified).toList();
        }
        if (_selectedRole != 'ALL') {
          users = users.where((u) => 
            u.position.toUpperCase().contains(_selectedRole.toUpperCase())).toList();
        }

        if (users.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 60),
              child: Column(
                children: [
                  Icon(Icons.query_stats_rounded, color: Colors.white.withOpacity(0.1), size: 48),
                  const SizedBox(height: 16),
                  Text(
                    locale.translate('no_developers_found').replaceAll('\"{}\"', ''),
                    style: GoogleFonts.inter(color: Colors.white30),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          children: users
              .map((user) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _ContributorCard(
                      name: user.name,
                      title: user.position.isNotEmpty
                          ? user.position
                          : locale
                              .translate('kernel_contributor')
                              .toUpperCase(),
                      followers: user.followers.length.toString(),
                      tags: user.position.isNotEmpty
                          ? [user.position.toUpperCase()]
                          : [],
                      isVerified: user.isVerified,
                      imageUrl: user.profileImage,
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => ProfilePage(userId: user.uid))),
                    ),
                  ))
              .toList(),
        );
      },
    );
  }

  Widget _buildSearchResults(AppLocalization locale) {
    final auth = Provider.of<AuthController>(context, listen: false);
    
    var filteredResults = _searchResults
        .where((u) =>
            !u.uid.startsWith('dummy_') &&
            u.uid != auth.currentUser?.uid &&
            !(auth.currentUser?.blockedUsers.contains(u.uid) ?? false))
        .toList();

    // Apply verification filter
    if (_isVerifiedOnly) {
      filteredResults = filteredResults.where((u) => u.isVerified).toList();
    }

    // Apply role filter
    if (_selectedRole != 'ALL') {
      filteredResults = filteredResults.where((u) => 
        u.position.toUpperCase().contains(_selectedRole.toUpperCase())).toList();
    }

    if (filteredResults.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 60),
          child: Column(
            children: [
              Icon(Icons.search_off_rounded, color: Colors.white.withOpacity(0.1), size: 48),
              const SizedBox(height: 16),
              Text(
                  locale.translate('no_developers_found').replaceAll('\"{}\"', ''),
                  style: GoogleFonts.inter(color: Colors.white.withOpacity(0.3))),
            ],
          ),
        ),
      );
    }
    return Column(
      children: filteredResults
          .map((user) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _ContributorCard(
                  name: user.name,
                  title: user.position.isNotEmpty
                      ? user.position
                      : locale.translate('kernel_contributor').toUpperCase(),
                  followers: user.followers.length.toString(),
                  tags: user.position.isNotEmpty
                      ? [user.position.toUpperCase()]
                      : [],
                  isVerified: user.isVerified,
                  imageUrl: user.profileImage,
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => ProfilePage(userId: user.uid))),
                ),
              ))
          .toList(),
    );
  }

  void _showFilterDialog() {
    final locale = AppLocalization.of(context)!;
    final roles = ['ALL', 'Frontend', 'Backend', 'Fullstack', 'Mobile', 'DevOps', 'Designer'];

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0D0D0D),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(locale.translate('FILTER_TRANSCRIPT'), style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(locale.translate('verified_only'), style: GoogleFonts.inter(color: Colors.white.withOpacity(0.7))),
                      Switch(
                        value: _isVerifiedOnly,
                        activeColor: const Color(0xFF00E5FF),
                        onChanged: (val) {
                          setModalState(() => _isVerifiedOnly = val);
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(locale.translate('ROLE_FILTER'), style: GoogleFonts.spaceGrotesk(color: Colors.white.withOpacity(0.4), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: roles.map((role) {
                      final isSelected = _selectedRole == role;
                      return GestureDetector(
                        onTap: () {
                          setModalState(() => _selectedRole = role);
                          setState(() {});
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF00E5FF).withOpacity(0.1) : const Color(0xFF161616),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: isSelected ? const Color(0xFF00E5FF) : Colors.white.withOpacity(0.05)),
                          ),
                          child: Text(
                            role.toUpperCase(),
                            style: GoogleFonts.spaceGrotesk(color: isSelected ? const Color(0xFF00E5FF) : Colors.white.withOpacity(0.3), fontSize: 10, fontWeight: FontWeight.w800),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  const _SectionHeader({required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          title,
          style: GoogleFonts.spaceGrotesk(
            color: Colors.white.withOpacity(0.5),
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
            height: 1.2,
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _ContributorCard extends StatelessWidget {
  final String name;
  final String title;
  final String followers;
  final List<String> tags;
  final bool isVerified;
  final String imageUrl;
  final VoidCallback? onTap;

  const _ContributorCard({
    required this.name,
    required this.title,
    required this.followers,
    required this.tags,
    required this.isVerified,
    required this.imageUrl,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalization.of(context)!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: imageUrl.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(imageUrl), fit: BoxFit.cover)
                          : null,
                      color: Colors.white10,
                    ),
                  ),
                  if (isVerified)
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                          color: Color(0xFF00E5FF), shape: BoxShape.circle),
                      child: const Icon(Icons.check,
                          color: Color(0xFF0D0D0D), size: 10),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.spaceGrotesk(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                    Text(
                      title,
                      style: GoogleFonts.inter(
                          color: Colors.white.withOpacity(0.4), fontSize: 12),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(locale.translate('followers').toUpperCase(),
                      style: GoogleFonts.spaceGrotesk(
                          color: Colors.white.withOpacity(0.3),
                          fontSize: 8,
                          fontWeight: FontWeight.w700)),
                  Text(followers,
                      style: GoogleFonts.spaceGrotesk(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          if (tags.isNotEmpty) ...[
            const SizedBox(height: 20),
            Row(
              children: tags
                  .map((tag) => Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(tag.toUpperCase(),
                            style: GoogleFonts.spaceGrotesk(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 9,
                                fontWeight: FontWeight.w700)),
                      ))
                  .toList(),
            ),
          ],
          const SizedBox(height: 20),
          GestureDetector(
            onTap: onTap ?? () {},
            child: Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF00E5FF),
                borderRadius: BorderRadius.circular(4),
                gradient: const LinearGradient(
                    colors: [Color(0xFFB2FEFA), Color(0xFF0ED2F7)]),
              ),
              child: Center(
                child: Text(
                  locale.translate('VIEW_PROFILE_CAPS'),
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.black,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
