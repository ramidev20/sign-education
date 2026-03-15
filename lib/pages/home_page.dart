import 'package:flutter/material.dart';
import 'package:sign_education/data/models/user_model.dart';
import 'package:sign_education/pages/assignments_page.dart';
import 'package:sign_education/pages/dictionary_page.dart';
import 'package:sign_education/pages/groups_page.dart';
import 'package:sign_education/pages/lessons_page.dart';
import 'package:sign_education/pages/about_page.dart';
import 'package:sign_education/pages/profile_page.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class HomePage extends StatefulWidget {
  final UserModel user;
  const HomePage({super.key, required this.user});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController searchController = TextEditingController();
  final PageController _controller = PageController(viewportFraction: 0.85);

  final List<String> backgroundImages = [
    'assets/images/home_1.jpg',
    'assets/images/home_1.jpg',
    'assets/images/home_1.jpg',
  ];

  final List<String> _cardContents = [
    'معلومات عنا',
    'الدليل المؤسسي',
    'الخطط والأسعار',
  ];

  List<Map<String, dynamic>> get learningTypes => [
    {
      'title': 'الدروس',
      'image': "assets/images/lessons.jpg",
      'action': () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => LessonsPage(user: widget.user)),
      ),
    },

    {
      'title': 'الواجبات',
      'image': "assets/images/assigments.jpeg",
      'action': () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AssignmentsPage(user: widget.user),
        ),
      ),
    },
    {
      'title': 'قاموس لغة الإشارة',
      'image': "assets/images/dictionary.jpg",
      'action': () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DictionaryPage(user: widget.user),
        ),
      ),
    },
    {
      'title': 'محادثات',
      'image': "assets/images/chat.jpg",
      'action': () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => GroupsPage(user: widget.user)),
      ),
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = widget.user;
    final firstLetter = user.email.isNotEmpty
        ? user.email[0].toUpperCase()
        : '?';
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 1,
        titleSpacing: 0,
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // --- Role + Name (on the left of avatar in RTL) ---
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // User name (bottom line)
                Text(
                  widget.user.role == "teacher"
                      ? "معلم"
                      : widget.user.role == "student"
                      ? "طالب"
                      : "مستخدم",
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // Role in Arabic (top line)
                Text(
                  widget.user.name,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
              ],
            ),

            const SizedBox(width: 12),

            // --- Avatar (on the right) ---
            Hero(
              tag: 'userAvatar',
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProfilePage(user: widget.user),
                    ),
                  );
                },
                child: CircleAvatar(
                  radius: 22,
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primaryContainer,
                  child: Text(
                    widget.user.name.isNotEmpty
                        ? widget.user.name[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 16),
          ],
        ),
      ),

      body: Column(
        children: [
          // 🔍 Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'بحث ..',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),

          // Main content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // 🎴 Carousel
                  SizedBox(
                    height: 200,
                    child: PageView.builder(
                      controller: _controller,
                      itemCount: _cardContents.length,
                      itemBuilder: (context, index) {
                        return AnimatedBuilder(
                          animation: _controller,
                          builder: (context, child) {
                            double value = 1.0;
                            if (_controller.position.haveDimensions) {
                              value = (_controller.page ?? 0) - index;
                              value = (1 - (value.abs() * 0.2)).clamp(0.8, 1.0);
                            }
                            return Transform.scale(scale: value, child: child);
                          },
                          child: Card(
                            color: theme.colorScheme.surface,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 5,
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              onTap: () {
                                Widget targetPage;
                                switch (index) {
                                  case 0:
                                    targetPage = const AboutUsPage();
                                    break;
                                  case 1:
                                    targetPage = DictionaryPage(
                                      user: widget.user,
                                    );
                                    break;
                                  default:
                                    targetPage = const AboutUsPage();
                                }
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => targetPage,
                                  ),
                                );
                              },
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.asset(
                                    backgroundImages[index],
                                    fit: BoxFit.cover,
                                    color: Colors.black.withOpacity(0.1),
                                    colorBlendMode: BlendMode.lighten,
                                  ),
                                  Center(
                                    child: Text(
                                      _cardContents[index],
                                      style: theme.textTheme.headlineSmall!
                                          .copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Indicator
                  SmoothPageIndicator(
                    controller: _controller,
                    count: _cardContents.length,
                    effect: WormEffect(
                      dotHeight: 10,
                      dotWidth: 10,
                      activeDotColor: theme.colorScheme.primary,
                      dotColor: theme.brightness == Brightness.dark
                          ? Colors
                                .grey
                                .shade700 // subtle gray in dark mode
                          : Colors.grey.shade400, // lighter gray in light mode
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 📚 Section title
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        "أنواع التعلم",
                        style: theme.textTheme.titleLarge!.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 🧩 Grid items
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
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
                              color: isDark
                                  ? Colors.black.withOpacity(0.3)
                                  : Colors.grey.withOpacity(0.2),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => item['action'](),
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
                                    item['image'],
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Center(
                                  child: Text(
                                    item['title'],
                                    style: theme.textTheme.titleMedium!
                                        .copyWith(fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
