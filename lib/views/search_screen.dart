import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../models/user_model.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import 'profile_page.dart';
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

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.isNotEmpty) {
        _performSearch(query);
      } else {
        setState(() {
          _searchResults = [];
          _query = '';
        });
      }
    });
  }

  Future<void> _performSearch(String query) async {
    setState(() {
      _isLoading = true;
      _query = query;
    });

    try {
      final authController = Provider.of<AuthController>(context, listen: false);
      final results = await authController.searchUsers(query);
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      // ignore: avoid_print
      print('Search Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _isLoading
                  ? ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: 5,
                      itemBuilder: (context, index) => const UserTileShimmer(),
                    )
                  : _query.isEmpty
                      ? _buildEmptyState()
                      : _searchResults.isEmpty
                          ? _buildNoResults()
                          : _buildResultsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final locale = AppLocalization.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.background,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            locale.translate('search_developers'),
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          _buildSearchField(locale),
        ],
      ),
    );
  }

  Widget _buildSearchField(AppLocalization locale) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        style: const TextStyle(color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: locale.translate('search_hint'),
          hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
          prefixIcon: ShaderMask(
            shaderCallback: (b) => AppColors.primaryGradient.createShader(b),
            child: const Icon(Icons.search, color: Colors.white),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
          suffixIcon: _query.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close, size: 18, color: AppColors.textMuted),
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged('');
                  },
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final locale = AppLocalization.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.people_alt_outlined,
              size: 80,
              color: AppColors.primary.withValues(alpha: 0.2),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            locale.translate('find_collab'),
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            locale.translate('search_developers_sub'),
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults() {
    final locale = AppLocalization.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.sentiment_dissatisfied, size: 60, color: AppColors.textMuted),
          const SizedBox(height: 16),
          Text(
            locale.translate('no_developers_found').replaceFirst('{}', _query),
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final user = _searchResults[index];
        return _UserSearchCard(user: user);
      },
    );
  }
}

class _UserSearchCard extends StatelessWidget {
  final UserModel user;

  const _UserSearchCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ProfilePage(userId: user.uid)),
        ),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _buildAvatar(),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            user.name,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (user.isVerified) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.verified, color: AppColors.accent, size: 16),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.position.isNotEmpty ? user.position : 'Developer',
                      style: const TextStyle(
                        color: AppColors.primaryLight,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 14, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Text(
                          user.city.isNotEmpty ? user.city : 'Remote',
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.primaryGradient,
      ),
      child: CircleAvatar(
        radius: 30,
        backgroundColor: AppColors.cardLight,
        backgroundImage: user.profileImage.isNotEmpty ? NetworkImage(user.profileImage) : null,
        child: user.profileImage.isEmpty ? const Icon(Icons.person, size: 30, color: AppColors.textMuted) : null,
      ),
    );
  }
}
