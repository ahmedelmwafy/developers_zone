import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/auth_controller.dart';
import '../models/user_model.dart';
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
  String _selectedSkill = 'ALL SKILLS';

  final List<String> _skills = [
    'ALL SKILLS', 'RUST', 'GO', 'AI/ML', 'KUBERNETES', 'WEB3'
  ];

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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              _buildHeader(),
              const SizedBox(height: 32),
              _buildSearchBar(),
              const SizedBox(height: 24),
              _buildSkillFilters(),
              const SizedBox(height: 40),
              
              _SectionHeader(
                title: 'VERIFIED\nCONTRIBUTORS',
                trailing: Row(
                  children: [
                    Text('SORT BY:\nRELEVANCE', style: GoogleFonts.spaceGrotesk(color: const Color(0xFF00E5FF), fontSize: 10, fontWeight: FontWeight.w700)),
                    const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF00E5FF), size: 16),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              if (_isLoading)
                ...List.generate(3, (index) => const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: UserTileShimmer(),
                ))
              else if (_query.isEmpty)
                _buildDefaultContributors()
              else
                _buildSearchResults(),
                
              const SizedBox(height: 48),
              _SectionHeader(title: 'COLLABORATION\nFINDER'),
              const SizedBox(height: 24),
              _buildProjectMatchingCard(),
              
              const SizedBox(height: 48),
              _SectionHeader(title: 'TRENDING\nSTACK'),
              const SizedBox(height: 24),
              _buildTrendingStack(),
              
              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'GLOBAL REPOSITORY',
          style: GoogleFonts.spaceGrotesk(
            color: const Color(0xFF00E5FF),
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Explore Talent',
          style: GoogleFonts.spaceGrotesk(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Container(
              width: 8, height: 8,
              decoration: const BoxDecoration(color: Color(0xFF00E5FF), shape: BoxShape.circle),
            ),
            const SizedBox(width: 10),
            Text(
              '12,408 DEVELOPERS ONLINE',
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white.withOpacity(0.5),
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
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
          hintText: 'Search by name, position or skill...',
          hintStyle: GoogleFonts.inter(color: Colors.white.withOpacity(0.15)),
          prefixIcon: Icon(Icons.search_rounded, color: Colors.white.withOpacity(0.3), size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 20),
        ),
      ),
    );
  }

  Widget _buildSkillFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _skills.map((skill) {
          final isActive = _selectedSkill == skill;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => setState(() => _selectedSkill = skill),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isActive ? const Color(0xFF004D40).withOpacity(0.4) : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: isActive ? const Color(0xFF00E5FF).withOpacity(0.5) : Colors.white.withOpacity(0.1)),
                ),
                child: Text(
                  skill,
                  style: GoogleFonts.spaceGrotesk(
                    color: isActive ? const Color(0xFF00E5FF) : Colors.white.withOpacity(0.5),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDefaultContributors() {
    return Column(
      children: [
        _ContributorCard(
          name: 'Marcus Drago',
          title: 'Lead Systems Architect @ NeuralLink',
          commits: '2.4k',
          tags: const ['RUST', 'WEBASSEMBLY'],
          isVerified: true,
          imageUrl: 'https://i.pravatar.cc/150?u=marcus',
        ),
        const SizedBox(height: 16),
        _ContributorCard(
          name: 'Elena Vance',
          title: 'Senior AI Engineer • Zurich',
          commits: '842',
          tags: const ['PYTHON', 'PYTORCH'],
          isVerified: true,
          imageUrl: 'https://i.pravatar.cc/150?u=elena',
          accentColor: const Color(0xFF161616),
          buttonColor: Colors.white.withOpacity(0.05),
        ),
      ],
    );
  }

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Text('No agents found in repository.', style: GoogleFonts.inter(color: Colors.white.withOpacity(0.3))),
        ),
      );
    }
    return Column(
      children: _searchResults.map((user) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: _ContributorCard(
          name: user.name,
          title: user.position.isNotEmpty ? user.position : 'Elite Operator',
          commits: '0', 
          tags: const ['DART', 'FLUTTER'],
          isVerified: user.isVerified,
          imageUrl: user.profileImage,
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProfilePage(userId: user.uid))),
        ),
      )).toList(),
    );
  }

  Widget _buildProjectMatchingCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1F21),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.people_outline_rounded, color: Color(0xFF00E5FF), size: 20),
              const SizedBox(width: 12),
              Text(
                'Project Matching',
                style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Our AI-driven engine matches your skill profile with active open-source repositories needing contributors.',
            style: GoogleFonts.inter(color: Colors.white.withOpacity(0.5), fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 24),
          _ProjectMatchItem(title: 'KERNEL DEV', tag: 'URGENT', tagColor: const Color(0xFFFF1744)),
          const SizedBox(height: 12),
          _ProjectMatchItem(title: 'QUANT AI', tag: 'NEW', tagColor: const Color(0xFF2979FF)),
          const SizedBox(height: 32),
          Container(
            width: double.infinity,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                'FIND MY MATCH',
                style: GoogleFonts.spaceGrotesk(color: Colors.black, fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: 1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendingStack() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          _TrendingItem(rank: '01', title: 'Zig Programming', subtitle: '+42% GROWTH THIS WEEK'),
          const SizedBox(height: 20),
          _TrendingItem(rank: '02', title: 'Vector DBs', subtitle: '+28% ADOPTION'),
        ],
      ),
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
  final String commits;
  final List<String> tags;
  final bool isVerified;
  final String imageUrl;
  final Color? accentColor;
  final Color? buttonColor;
  final VoidCallback? onTap;

  const _ContributorCard({
    required this.name,
    required this.title,
    required this.commits,
    required this.tags,
    required this.isVerified,
    required this.imageUrl,
    this.accentColor,
    this.buttonColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: accentColor ?? const Color(0xFF161616),
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
                    width: 56, height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: imageUrl.isNotEmpty ? DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover) : null,
                      color: Colors.white10,
                    ),
                  ),
                  if (isVerified)
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(color: Color(0xFF00E5FF), shape: BoxShape.circle),
                      child: const Icon(Icons.check, color: Color(0xFF0D0D0D), size: 10),
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
                      style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      title,
                      style: GoogleFonts.inter(color: Colors.white.withOpacity(0.4), fontSize: 12),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('COMMITS', style: GoogleFonts.spaceGrotesk(color: Colors.white.withOpacity(0.3), fontSize: 8, fontWeight: FontWeight.w700)),
                  Text(commits, style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: tags.map((tag) => Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(tag, style: GoogleFonts.spaceGrotesk(color: Colors.white.withOpacity(0.5), fontSize: 9, fontWeight: FontWeight.w700)),
            )).toList(),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: onTap ?? () {},
            child: Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                color: buttonColor ?? const Color(0xFF00E5FF),
                borderRadius: BorderRadius.circular(4),
                gradient: buttonColor == null ? const LinearGradient(colors: [Color(0xFFB2FEFA), Color(0xFF0ED2F7)]) : null,
              ),
              child: Center(
                child: Text(
                  'VIEW PROFILE',
                  style: GoogleFonts.spaceGrotesk(
                    color: buttonColor == null ? Colors.black : Colors.white.withOpacity(0.8),
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

class _ProjectMatchItem extends StatelessWidget {
  final String title;
  final String tag;
  final Color tagColor;
  const _ProjectMatchItem({required this.title, required this.tag, required this.tagColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.terminal_rounded, color: Colors.white70, size: 16),
              const SizedBox(width: 12),
              Text(title, style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: tagColor.withOpacity(0.2), borderRadius: BorderRadius.circular(2)),
            child: Text(tag, style: GoogleFonts.spaceGrotesk(color: tagColor, fontSize: 8, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}

class _TrendingItem extends StatelessWidget {
  final String rank;
  final String title;
  final String subtitle;
  const _TrendingItem({required this.rank, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(rank, style: GoogleFonts.spaceGrotesk(color: const Color(0xFF00E5FF), fontSize: 24, fontWeight: FontWeight.w800)),
        const SizedBox(width: 24),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
              Text(subtitle, style: GoogleFonts.spaceGrotesk(color: Colors.white.withOpacity(0.3), fontSize: 9, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ],
    );
  }
}
