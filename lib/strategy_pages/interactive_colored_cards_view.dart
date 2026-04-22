import 'dart:math';

import 'package:flutter/material.dart';
import 'package:sign_education/data/models/user_model.dart';

class InteractiveColoredCardsView extends StatefulWidget {
  final Map<String, dynamic> cardsJson;
  final UserModel user;

  const InteractiveColoredCardsView({
    super.key,
    required this.cardsJson,
    required this.user,
  });

  @override
  State<InteractiveColoredCardsView> createState() =>
      _InteractiveColoredCardsViewState();
}

class _InteractiveColoredCardsViewState extends State<InteractiveColoredCardsView> {
  static const _sceneSize = Size(1120, 840);
  final _transform = TransformationController();
  final _viewerKey = GlobalKey();
  bool _didInitTransform = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initDefaultZoomOut());
  }

  void _initDefaultZoomOut() {
    if (!mounted || _didInitTransform) return;
    final viewerBox = _viewerKey.currentContext?.findRenderObject() as RenderBox?;
    final viewport = viewerBox?.size;
    if (viewport == null || viewport.width <= 0 || viewport.height <= 0) return;

    final fittedScale = min(
      viewport.width / _sceneSize.width,
      viewport.height / _sceneSize.height,
    );
    final scale = min(1.0, max(0.76, fittedScale * 0.93));
    final tx = (viewport.width / 2) - ((_sceneSize.width / 2) * scale);
    final ty = (viewport.height / 2) - ((_sceneSize.height / 2) * scale);

    _transform.value = Matrix4.identity()
      ..translate(tx, ty)
      ..scale(scale);
    _didInitTransform = true;
  }

  @override
  Widget build(BuildContext context) {
    final title = (widget.cardsJson['title'] ?? 'البطاقات الملونة').toString();
    final cards = _normalizeCards(widget.cardsJson);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
          centerTitle: true,
        ),
        body: cards.isEmpty
            ? const Center(child: Text('لا توجد بطاقات للعرض'))
            : InteractiveViewer(
                key: _viewerKey,
                transformationController: _transform,
                minScale: 0.55,
                maxScale: 2.6,
                panEnabled: true,
                scaleEnabled: true,
                constrained: false,
                boundaryMargin: const EdgeInsets.all(1000),
                child: SizedBox(
                  width: _sceneSize.width,
                  height: _sceneSize.height,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Theme.of(context).colorScheme.surface,
                                Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.25),
                              ],
                            ),
                          ),
                        ),
                      ),
                      for (var index = 0; index < cards.length; index++)
                        _PositionedConceptCard(
                          data: cards[index],
                          index: index,
                        ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  List<_ConceptCardData> _normalizeCards(Map<String, dynamic> json) {
    final raw = json['conceptCards'];
    if (raw is! List) return const [];
    return raw.whereType<Map>().map((item) {
      final map = Map<String, dynamic>.from(item);
      return _ConceptCardData(
        title: (map['title'] ?? '').toString(),
        type: (map['type'] ?? '').toString(),
        content: (map['content'] ?? '').toString(),
        color: _parseHexColor(map['color']?.toString() ?? '#3b82f6'),
      );
    }).toList();
  }

  Color _parseHexColor(String input) {
    var hex = input.replaceAll('#', '').trim();
    if (hex.length == 6) hex = 'FF$hex';
    try {
      return Color(int.parse('0x$hex'));
    } catch (_) {
      return const Color(0xFF3B82F6);
    }
  }
}

class _PositionedConceptCard extends StatelessWidget {
  final _ConceptCardData data;
  final int index;

  const _PositionedConceptCard({
    required this.data,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    const columns = 3;
    final row = index ~/ columns;
    final col = index % columns;
    const cardW = 300.0;
    const cardH = 210.0;
    const startX = 70.0;
    const startY = 60.0;
    const gapX = 350.0;
    const gapY = 240.0;

    final left = startX + (col * gapX) + (row.isOdd ? 28 : 0);
    final top = startY + (row * gapY);

    return Positioned(
      left: left,
      top: top,
      width: cardW,
      height: cardH,
      child: _ConceptCardTile(data: data),
    );
  }
}

class _ConceptCardData {
  final String title;
  final String type;
  final String content;
  final Color color;

  const _ConceptCardData({
    required this.title,
    required this.type,
    required this.content,
    required this.color,
  });
}

class _ConceptCardTile extends StatelessWidget {
  final _ConceptCardData data;

  const _ConceptCardTile({
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final onColor = ThemeData.estimateBrightnessForColor(data.color) == Brightness.dark
        ? Colors.white
        : Colors.black;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: data.color,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 9,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            data.title.trim().isEmpty ? 'بطاقة' : data.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: onColor,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (data.type.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              data.type,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: onColor.withOpacity(0.94),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Expanded(
            child: SingleChildScrollView(
              child: Text(
                data.content.trim().isEmpty ? '-' : data.content,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: onColor.withOpacity(0.95),
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

