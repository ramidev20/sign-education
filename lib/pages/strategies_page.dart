import 'package:flutter/material.dart';
import 'package:sign_education/strategy_pages/interactive_triangle_view.dart';
import 'package:sign_education/utils/app_theme.dart';
import 'package:sign_education/data/models/user_model.dart';

// Strategy imports
import 'package:sign_education/strategy_pages/interactive_mindmap_view.dart';
import 'package:sign_education/strategy_pages/interactive_timeline_view.dart';
import 'package:sign_education/strategy_pages/interactive_hierarchy_view.dart';
import 'package:sign_education/strategy_pages/interactive_colored_cards_view.dart';
import 'package:sign_education/strategy_pages/interactive_comparison_view.dart';
import 'package:sign_education/utils/strategy_functions.dart';

class StrategiesPage extends StatefulWidget {
  final UserModel user;
  final String title;
  final String subject;

  const StrategiesPage({
    super.key,
    required this.user,
    required this.title,
    required this.subject,
  });

  @override
  State<StrategiesPage> createState() => _StrategiesPageState();
}

class _StrategiesPageState extends State<StrategiesPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  String? selectedStrategy;
  bool _isLoading = false;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final List<Map<String, dynamic>> strategies = [
    {"id": "type_0", "label": "الخرائط الذهنية", "icon": Icons.account_tree},
    {"id": "type_1", "label": "العصف الذهني", "icon": Icons.bubble_chart},
    {"id": "type_2", "label": "القصة التعليمية", "icon": Icons.auto_stories},
    {"id": "type_3", "label": "حوار شخصيات", "icon": Icons.chat},
    {"id": "type_4", "label": "مخطط الزهرة", "icon": Icons.local_florist},
    {"id": "type_5", "label": "المخطط الزمني", "icon": Icons.timeline},
    {"id": "type_6", "label": "التدرج الهرمي", "icon": Icons.device_hub},
    {"id": "type_7", "label": "القبعات الست", "icon": Icons.psychology_alt},
    {"id": "type_8", "label": "الأسئلة الصحفية", "icon": Icons.question_answer},
    {
      "id": "type_9",
      "label": "البطاقات الملونة",
      "icon": Icons.crop_landscape_outlined,
    },
    {"id": "type_10", "label": "جدول المقارنة", "icon": Icons.table_chart},
    {"id": "type_11", "label": "المثلث التعليمي", "icon": Icons.change_history},
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _startStrategy() async {
    if (selectedStrategy == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء اختيار الاستراتيجية')),
      );
      return;
    }

    final text = _textController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('الرجاء إدخال نص الدرس')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      switch (selectedStrategy) {
        case 'type_0':
          final json = await generateMindMapFromText(text);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => InteractiveMindMapView(
                username: widget.user.name,
                mindMapJson: json,
              ),
            ),
          );
          break;
        case 'type_5':
          final json = await generateTimeLineFromText(text);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  TimeLineMapView(user: widget.user, mindMapJson: json),
            ),
          );
          break;
        case 'type_6':
          final json = await generateHierarchyFromText(text);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => InteractiveHierarchyView(
                user: widget.user,
                hierarchyJson: json,
              ),
            ),
          );
          break;
        case 'type_9':
          final json = await generateColoredCardsFromText(text);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => InteractiveColoredCardsView(
                user: widget.user,
                cardsJson: json,
              ),
            ),
          );
          break;
        case 'type_10':
          final json = await generateComparisonTableFromText(text);
          print(json);

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => InteractiveComparisonView(
                username: widget.user.name,
                comparisonJson: json,
              ),
            ),
          );
          break;

        case 'type_11':
          final json = await generateTriangleFromText(text);
          print(json);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => InteractiveTriangleView(
                user: widget.user,
                triangleJson: json,
              ),
            ),
          );
          break;
        default:
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("هذه الاستراتيجية غير مفعّلة بعد")),
          );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("حدث خطأ: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildStrategyCard(Map<String, dynamic> strategy, bool isSelected) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: () => setState(() => selectedStrategy = strategy["id"]),
      child: AnimatedContainer(
        duration: AppTheme.animationDuration,
        curve: AppTheme.animationCurve,
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [colorScheme.primary, colorScheme.secondary],
                )
              : LinearGradient(
                  colors: [colorScheme.surfaceVariant, colorScheme.surface],
                ),
          borderRadius: AppTheme.globalRadius,
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? colorScheme.primary.withOpacity(0.35)
                  : Colors.black26,
              blurRadius: isSelected ? 12 : 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              strategy["icon"],
              size: 44,
              color: isSelected ? colorScheme.onPrimary : colorScheme.primary,
            ),
            const SizedBox(height: 10),
            Text(
              strategy["label"],
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? colorScheme.onPrimary
                    : colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScrollableInput() {
    final theme = Theme.of(context);
    return Container(
      height: 250,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppTheme.globalRadius,
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            child: Scrollbar(
              thumbVisibility: true,
              radius: const Radius.circular(10),
              child: TextField(
                controller: _textController,
                expands: true,
                maxLines: null,
                minLines: null,
                textAlignVertical: TextAlignVertical.top,
                decoration: InputDecoration(
                  hintText: "اكتب نص الدرس هنا...",
                  filled: true,
                  fillColor: theme.inputDecorationTheme.fillColor,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isLoading ? null : _startStrategy,
              icon: _isLoading
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.colorScheme.onPrimary,
                      ),
                    )
                  : const Icon(Icons.play_arrow_rounded),
              label: Text(_isLoading ? "جارٍ التنفيذ..." : "ابدأ"),
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: AppTheme.globalRadius,
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Stack(
      children: [
        Scaffold(
          backgroundColor: colorScheme.background,
          appBar: AppBar(
            title: Text(
              "إستراتيجيات التعلم",
              style: theme.textTheme.titleLarge,
            ),
            elevation: 0.5,
          ),
          body: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 1.0,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                        ),
                    itemCount: strategies.length,
                    itemBuilder: (context, index) {
                      final s = strategies[index];
                      final isSelected = selectedStrategy == s['id'];
                      return _buildStrategyCard(s, isSelected);
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: _buildScrollableInput(),
                ),
              ],
            ),
          ),
        ),
        if (_isLoading)
          Container(
            color: Colors.black54,
            child: const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          ),
      ],
    );
  }
}
