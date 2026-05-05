import 'dart:math';

import 'package:flutter/material.dart';
import 'package:sign_education/data/models/user_model.dart';

class TimeLineMapView extends StatefulWidget {
  final Map<String, dynamic> mindMapJson;
  final UserModel user;

  const TimeLineMapView({
    super.key,
    required this.mindMapJson,
    required this.user,
  });

  @override
  State<TimeLineMapView> createState() => _TimeLineMapViewState();
}

class _TimeLineMapViewState extends State<TimeLineMapView> {
  final _transform = TransformationController();
  final _viewerKey = GlobalKey();

  late final List<_TimelineEvent> _events;
  late final Size _sceneSize;
  bool _didInitTransform = false;

  static const _cardWidth = 240.0;
  static const _cardHeight = 140.0;
  static const _topCardY = 190.0;
  static const _bottomCardY = 530.0;
  static const _axisY = 420.0;
  static const _leftPad = 140.0;
  static const _rightPad = 140.0;

  @override
  void initState() {
    super.initState();
    _events = _normalizeTimelineEvents(widget.mindMapJson);
    _sceneSize = _computeSceneSize(_events.length);
    WidgetsBinding.instance.addPostFrameCallback((_) => _fitInView());
  }

  @override
  Widget build(BuildContext context) {
    final title = (widget.mindMapJson['content'] ?? 'الخط الزمني').toString();
    final cs = Theme.of(context).colorScheme;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
          centerTitle: true,
        ),
        body: _events.isEmpty
            ? const Center(child: Text('لا توجد أحداث زمنية للعرض'))
            : Stack(
                children: [
                  Positioned.fill(
                    key: _viewerKey,
                    child: InteractiveViewer(
                      transformationController: _transform,
                      constrained: false,
                      boundaryMargin: const EdgeInsets.all(1200),
                      clipBehavior: Clip.none,
                      panEnabled: true,
                      scaleEnabled: true,
                      minScale: 0.35,
                      maxScale: 3,
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
                                      cs.surface,
                                      cs.surfaceContainerHighest.withOpacity(0.2),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            _TimelineAxis(
                              y: _axisY,
                              startX: _leftPad,
                              endX: _sceneSize.width - _rightPad,
                            ),
                            for (var i = 0; i < _events.length; i++)
                              _PositionedTimelineEvent(
                                index: i,
                                total: _events.length,
                                sceneWidth: _sceneSize.width,
                                event: _events[i],
                                axisY: _axisY,
                                cardWidth: _cardWidth,
                                cardHeight: _cardHeight,
                                topCardY: _topCardY,
                                bottomCardY: _bottomCardY,
                                leftPad: _leftPad,
                                rightPad: _rightPad,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 12,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cs.surface.withOpacity(0.92),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: cs.outlineVariant),
                      ),
                      child: const Text(
                        'يمكنك التكبير والتصغير والسحب لاستكشاف الخط الزمني.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  void _fitInView() {
    if (!mounted || _didInitTransform) return;
    final viewerBox = _viewerKey.currentContext?.findRenderObject() as RenderBox?;
    final viewport = viewerBox?.size;
    if (viewport == null || viewport.width <= 0 || viewport.height <= 0) return;

    final fittedScale = min(
      viewport.width / _sceneSize.width,
      viewport.height / _sceneSize.height,
    );
    final scale = min(1.0, max(0.72, fittedScale * 0.94));

    final tx = (viewport.width / 2) - ((_sceneSize.width / 2) * scale);
    final ty = (viewport.height / 2) - ((_sceneSize.height / 2) * scale);

    _transform.value = Matrix4.identity()
      ..translate(tx, ty)
      ..scale(scale);
    _didInitTransform = true;
  }

  Size _computeSceneSize(int eventCount) {
    final width = max(1400.0, 460 + (eventCount * 280.0));
    return Size(width, 860);
  }

  List<_TimelineEvent> _normalizeTimelineEvents(Map<String, dynamic> json) {
    final flattened = <Map<String, dynamic>>[];

    void walk(dynamic raw) {
      if (raw is! Map) return;
      final node = Map<String, dynamic>.from(raw);
      final date = (node['date'] ?? '').toString().trim();
      final content = (node['content'] ?? '').toString().trim();
      if (date.isNotEmpty || content.isNotEmpty) {
        flattened.add(node);
      }
      final children = (node['nodes'] as List? ?? const []);
      for (final child in children) {
        walk(child);
      }
    }

    for (final raw in (json['nodes'] as List? ?? const [])) {
      walk(raw);
    }

    final events = flattened
        .map(
          (e) => _TimelineEvent(
            id: (e['id'] ?? '').toString(),
            title: (e['content'] ?? 'حدث').toString(),
            dateText: (e['date'] ?? '').toString(),
          ),
        )
        .toList();

    events.sort((a, b) => _parseDateRank(a.dateText).compareTo(_parseDateRank(b.dateText)));
    return events;
  }

  int _parseDateRank(String value) {
    final text = value.trim();
    if (text.isEmpty) return 1 << 30;

    final parsed = DateTime.tryParse(text.replaceAll('/', '-'));
    if (parsed != null) {
      return parsed.millisecondsSinceEpoch;
    }

    final numbers = RegExp(r'\d+').allMatches(text).map((m) => int.tryParse(m.group(0) ?? '') ?? 0).toList();
    if (numbers.isEmpty) return 1 << 30;

    if (numbers.length == 1) {
      return DateTime(numbers[0], 1, 1).millisecondsSinceEpoch;
    }

    final year = numbers[0];
    final month = numbers.length > 1 ? numbers[1].clamp(1, 12).toInt() : 1;
    final day = numbers.length > 2 ? numbers[2].clamp(1, 28).toInt() : 1;
    return DateTime(year, month, day).millisecondsSinceEpoch;
  }
}

class _TimelineAxis extends StatelessWidget {
  final double y;
  final double startX;
  final double endX;

  const _TimelineAxis({
    required this.y,
    required this.startX,
    required this.endX,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: startX,
      top: y,
      width: endX - startX,
      height: 4,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6), Color(0xFFEC4899)],
          ),
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

class _PositionedTimelineEvent extends StatelessWidget {
  final int index;
  final int total;
  final double sceneWidth;
  final _TimelineEvent event;
  final double axisY;
  final double cardWidth;
  final double cardHeight;
  final double topCardY;
  final double bottomCardY;
  final double leftPad;
  final double rightPad;

  const _PositionedTimelineEvent({
    required this.index,
    required this.total,
    required this.sceneWidth,
    required this.event,
    required this.axisY,
    required this.cardWidth,
    required this.cardHeight,
    required this.topCardY,
    required this.bottomCardY,
    required this.leftPad,
    required this.rightPad,
  });

  @override
  Widget build(BuildContext context) {
    final factor = total == 1 ? 0.5 : index / (total - 1);
    final markerX = leftPad + ((sceneWidth - leftPad - rightPad) * factor);
    final isTop = index.isEven;
    final cardTop = isTop ? topCardY : bottomCardY;

    return Stack(
      children: [
        Positioned(
          left: markerX - 1,
          top: min(axisY, cardTop + (cardHeight / 2)),
          width: 2,
          height: (axisY - (cardTop + (cardHeight / 2))).abs(),
          child: Container(color: const Color(0xFF64748B).withOpacity(0.65)),
        ),
        Positioned(
          left: markerX - 7,
          top: axisY - 7,
          width: 14,
          height: 14,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ),
        Positioned(
          left: markerX - (cardWidth / 2),
          top: cardTop,
          width: cardWidth,
          height: cardHeight,
          child: _TimelineEventCard(event: event),
        ),
      ],
    );
  }
}

class _TimelineEventCard extends StatelessWidget {
  final _TimelineEvent event;

  const _TimelineEventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withOpacity(0.85),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.primary.withOpacity(0.35)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            event.title.trim().isEmpty ? 'حدث' : event.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: cs.onPrimaryContainer,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: Text(
              event.dateText.trim().isEmpty ? '-' : event.dateText,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

class _TimelineEvent {
  final String id;
  final String title;
  final String dateText;

  const _TimelineEvent({
    required this.id,
    required this.title,
    required this.dateText,
  });
}
