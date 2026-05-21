import 'package:flutter/material.dart';
import 'package:sign_education/data/models/user_model.dart';
import 'package:sign_education/pages/about_page.dart';
import 'package:sign_education/pages/assignments_page.dart';
import 'package:sign_education/pages/dictionary_page.dart';
import 'package:sign_education/pages/groups_page.dart';
import 'package:sign_education/pages/lessons_page.dart';
import 'package:sign_education/pages/pricing_page.dart';
import 'package:sign_education/pages/profile_page.dart';
import 'package:sign_education/pages/quizzes_page.dart';
import 'package:sign_education/pages/updates_page.dart';
import 'package:sign_education/utils/app_strings.dart';
import 'package:sign_education/utils/imageAvatar.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class HomePage extends StatefulWidget {
  final UserModel user;
  final ValueChanged<UserModel>? onUserChanged;

  const HomePage({super.key, required this.user, this.onUserChanged});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomeSlide {
  final String image;
  final VoidCallback onTap;

  const _HomeSlide({required this.image, required this.onTap});
}

class _HomePageState extends State<HomePage> {
  final PageController _controller = PageController(viewportFraction: 0.85);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _roleLabel(AppStrings strings) {
    if (widget.user.role == 'teacher') return strings.teacher;
    if (widget.user.role == 'student') return strings.student;
    return strings.user;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = AppStrings.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final slides = [
      _HomeSlide(
        image: 'assets/images/slides/slide_1.jpg',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AboutUsPage()),
        ),
      ),
      _HomeSlide(
        image: 'assets/images/slides/slide_2.jpg',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const UpdatesPage()),
        ),
      ),
      _HomeSlide(
        image: 'assets/images/slides/slide_3.jpg',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PricingPage()),
        ),
      ),
    ];

    final learningTypes = [
      {
        'title': strings.lessons,
        'image': 'assets/images/lessons.jpg',
        'action': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => LessonsPage(user: widget.user)),
        ),
      },
      {
        'title': strings.liveQuiz,
        'image': 'assets/images/quiz.jpg',
        'action': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => QuizzesPage(user: widget.user)),
        ),
      },
      {
        'title': strings.assignments,
        'image': 'assets/images/assigments.jpeg',
        'action': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AssignmentsPage(user: widget.user)),
        ),
      },
      {
        'title': strings.signDictionary,
        'image': 'assets/images/dictionary.jpg',
        'action': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => DictionaryPage(user: widget.user)),
        ),
      },
      {
        'title': strings.chats,
        'image': 'assets/images/chat.jpg',
        'action': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => GroupsPage(user: widget.user)),
        ),
      },
    ];

    final adPromotions = [
      {
        'title': strings.educationalAd,
        'description': strings.educationalAdDesc,
        'icon': Icons.ads_click_outlined,
        'color': const Color(0xFF8B5CF6),
      },
      {
        'title': strings.sponsoredContent,
        'description': strings.sponsoredContentDesc,
        'icon': Icons.verified_outlined,
        'color': const Color(0xFF06B6D4),
      },
    ];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        titleSpacing: 0,
        automaticallyImplyLeading: false,
        title: Directionality(
          textDirection: TextDirection.ltr,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _roleLabel(strings),
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    widget.user.name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                ],
              ),
              const SizedBox(width: 12),
              Hero(
                tag: 'userAvatar',
                child: GestureDetector(
                  onTap: () async {
                    final updatedUser = await Navigator.push<UserModel>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProfilePage(user: widget.user),
                      ),
                    );
                    if (updatedUser != null) {
                      widget.onUserChanged?.call(updatedUser);
                    }
                  },
                  child: DefaultAvatar(
                    radius: 22,
                    avatarColor: widget.user.avatarColor,
                    name: widget.user.name,
                  ),
                ),
              ),
              const SizedBox(width: 16),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              height: 200,
              child: PageView.builder(
                controller: _controller,
                itemCount: slides.length,
                itemBuilder: (context, index) {
                  return AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      var value = 1.0;
                      if (_controller.position.hasContentDimensions) {
                        value = (_controller.page ?? 0) - index;
                        value = (1 - (value.abs() * 0.2)).clamp(0.8, 1.0);
                      }
                      return Transform.scale(scale: value, child: child);
                    },
                    child: Card(
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: slides[index].onTap,
                        child: Image.asset(slides[index].image, fit: BoxFit.cover),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            SmoothPageIndicator(
              controller: _controller,
              count: slides.length,
              effect: WormEffect(
                dotHeight: 10,
                dotWidth: 10,
                activeDotColor: theme.colorScheme.primary,
                dotColor: theme.colorScheme.onSurfaceVariant.withOpacity(
                  theme.brightness == Brightness.dark ? 0.35 : 0.25,
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildSectionTitle(context, strings.learningTypes),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1,
              ),
              itemCount: learningTypes.length,
              itemBuilder: (context, index) {
                final item = learningTypes[index];
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.shadow.withOpacity(
                          isDark ? 0.28 : 0.10,
                        ),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: item['action']! as VoidCallback,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          flex: 2,
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16),
                            ),
                            child: Image.asset(
                              item['image']! as String,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Center(
                            child: Text(
                              item['title']! as String,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildSectionTitle(context, strings.adSpace),
            const SizedBox(height: 10),
            SizedBox(
              height: 152,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: adPromotions.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final ad = adPromotions[index];
                  return _buildAdPromoCard(context, ad, strings);
                },
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String text) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Align(
        alignment: Alignment.centerRight,
        child: Text(
          text,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildAdPromoCard(
    BuildContext context,
    Map<String, Object> ad,
    AppStrings strings,
  ) {
    final theme = Theme.of(context);
    final color = ad['color']! as Color;
    return Container(
      width: 270,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(ad['icon']! as IconData, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  ad['title']! as String,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            ad['description']! as String,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          Align(
            alignment: Alignment.bottomLeft,
            child: TextButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(strings.adsSoon)));
              },
              icon: const Icon(Icons.open_in_new_rounded, size: 16),
              label: Text(strings.adDetails),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                minimumSize: const Size(0, 32),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
