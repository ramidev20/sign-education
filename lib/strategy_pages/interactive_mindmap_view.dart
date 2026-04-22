import 'dart:math';

import 'package:flutter/material.dart';

class InteractiveMindMapView extends StatefulWidget {
  final Map<String, dynamic> mindMapJson;
  final String username;

  const InteractiveMindMapView({
    super.key,
    required this.mindMapJson,
    required this.username,
  });

  @override
  State<InteractiveMindMapView> createState() => _InteractiveMindMapViewState();
}

class _InteractiveMindMapViewState extends State<InteractiveMindMapView> {
  static const _nodeSize = Size(230, 108);
  static const _baseCanvasSize = Size(1600, 1200);
  static const _horizontalGap = 56.0;
  static const _verticalGap = 165.0;
  static const _topMargin = 110.0;
  static const _sideMargin = 80.0;

  final _transform = TransformationController();
  final _viewerKey = GlobalKey();

  late Map<String, dynamic> _root;
  late Size _canvasSize;
  late Map<String, int> _depthById;

  @override
  void initState() {
    super.initState();
    _root = _normalizeMindMap(Map<String, dynamic>.from(widget.mindMapJson));
    _layoutTree();
    _depthById = _buildDepthMap(_root);
    WidgetsBinding.instance.addPostFrameCallback((_) => _fitInView());
  }

  Map<String, dynamic> _normalizeMindMap(Map<String, dynamic> root) {
    root['id'] ??= 'root';
    root['content'] ??= 'الخريطة الذهنية';
    root['nodes'] ??= <dynamic>[];

    void walk(Map<String, dynamic> node) {
      node['content'] ??= '';
      node['nodes'] ??= <dynamic>[];
      for (final child in _children(node)) {
        walk(child);
      }
    }

    walk(root);
    return root;
  }

  List<Map<String, dynamic>> _children(Map<String, dynamic> node) {
    final raw = node['nodes'];
    if (raw is! List) {
      node['nodes'] = <dynamic>[];
      return <Map<String, dynamic>>[];
    }
    final result = <Map<String, dynamic>>[];
    for (final item in raw) {
      if (item is Map<String, dynamic>) {
        result.add(item);
      } else if (item is Map) {
        result.add(Map<String, dynamic>.from(item));
      }
    }
    node['nodes'] = result;
    return result;
  }

  Iterable<Map<String, dynamic>> _walk(Map<String, dynamic> node) sync* {
    yield node;
    for (final child in _children(node)) {
      yield* _walk(child);
    }
  }

  Map<String, int> _buildDepthMap(Map<String, dynamic> root) {
    final map = <String, int>{};
    void walk(Map<String, dynamic> node, int depth) {
      map[node['id']?.toString() ?? ''] = depth;
      for (final c in _children(node)) {
        walk(c, depth + 1);
      }
    }

    walk(root, 0);
    return map;
  }

  int _maxDepth(Map<String, dynamic> node, [int depth = 0]) {
    final children = _children(node);
    if (children.isEmpty) return depth;
    var d = depth;
    for (final child in children) {
      d = max(d, _maxDepth(child, depth + 1));
    }
    return d;
  }

  double _subtreeWidth(Map<String, dynamic> node) {
    final children = _children(node);
    final minWidth = _nodeSize.width + 24;
    if (children.isEmpty) return minWidth;

    var total = 0.0;
    for (var i = 0; i < children.length; i++) {
      total += _subtreeWidth(children[i]);
      if (i < children.length - 1) total += _horizontalGap;
    }
    return max(total, minWidth);
  }

  void _setNodePos(Map<String, dynamic> node, Offset pos) {
    node['pos'] = {'x': pos.dx, 'y': pos.dy};
  }

  Offset _nodePos(Map<String, dynamic> node) {
    final p = Map<String, dynamic>.from(node['pos'] ?? const {});
    final x = (p['x'] is num) ? (p['x'] as num).toDouble() : 0.0;
    final y = (p['y'] is num) ? (p['y'] as num).toDouble() : 0.0;
    return Offset(x, y);
  }

  void _layoutNode(Map<String, dynamic> node, double left, int depth) {
    final width = _subtreeWidth(node);
    final centerX = left + (width / 2);
    final y = _topMargin + (depth * _verticalGap);
    _setNodePos(node, Offset(centerX, y));

    final children = _children(node);
    var childLeft = left;
    for (final child in children) {
      final childWidth = _subtreeWidth(child);
      _layoutNode(child, childLeft, depth + 1);
      childLeft += childWidth + _horizontalGap;
    }
  }

  void _layoutTree() {
    final treeWidth = _subtreeWidth(_root);
    final depth = _maxDepth(_root);

    final width = max(_baseCanvasSize.width, treeWidth + (_sideMargin * 2));
    final height = max(
      _baseCanvasSize.height,
      _topMargin + (depth * _verticalGap) + 220,
    );
    _canvasSize = Size(width, height);

    final left = (width - treeWidth) / 2;
    _layoutNode(_root, left, 0);
  }

  Rect _treeBounds() {
    var minX = double.infinity;
    var minY = double.infinity;
    var maxX = -double.infinity;
    var maxY = -double.infinity;

    for (final node in _walk(_root)) {
      final p = _nodePos(node);
      minX = min(minX, p.dx - (_nodeSize.width / 2));
      maxX = max(maxX, p.dx + (_nodeSize.width / 2));
      minY = min(minY, p.dy - (_nodeSize.height / 2));
      maxY = max(maxY, p.dy + (_nodeSize.height / 2));
    }

    if (!minX.isFinite || !minY.isFinite || !maxX.isFinite || !maxY.isFinite) {
      return Rect.fromLTWH(0, 0, _canvasSize.width, _canvasSize.height);
    }
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  void _fitInView() {
    if (!mounted) return;
    final viewerBox = _viewerKey.currentContext?.findRenderObject() as RenderBox?;
    final viewport = viewerBox?.size ?? context.size ?? const Size(800, 600);
    final bounds = _treeBounds().inflate(20);

    final scaleX = viewport.width / bounds.width;
    final scaleY = viewport.height / bounds.height;
    final scale = min(1.0, min(scaleX, scaleY));
    final clamped = max(0.70, scale * 0.95);

    final dx = (viewport.width / 2) - (bounds.center.dx * clamped);
    final dy = (viewport.height / 2) - (bounds.center.dy * clamped);

    _transform.value = Matrix4.identity()
      ..translate(dx, dy)
      ..scale(clamped);
  }

  Color _accentForDepth(int depth, ColorScheme cs) {
    if (depth <= 0) return cs.primary;
    final base = HSLColor.fromColor(cs.primary);
    final hue = (base.hue + (depth * 34)) % 360;
    return base.withHue(hue).withSaturation(0.58).withLightness(0.48).toColor();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('الخريطة الذهنية'),
          centerTitle: true,
        ),
        body: Stack(
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
                minScale: 0.25,
                maxScale: 3.1,
                child: SizedBox(
                  width: _canvasSize.width,
                  height: _canvasSize.height,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _MindMapEdgesPainter(
                            root: _root,
                            nodePos: _nodePos,
                            childrenOf: _children,
                            nodeSize: _nodeSize,
                          ),
                        ),
                      ),
                      for (final node in _walk(_root))
                        Positioned(
                          left: _nodePos(node).dx - (_nodeSize.width / 2),
                          top: _nodePos(node).dy - (_nodeSize.height / 2),
                          width: _nodeSize.width,
                          height: _nodeSize.height,
                          child: Builder(
                            builder: (context) {
                              final id = node['id']?.toString() ?? '';
                              final depth = _depthById[id] ?? 0;
                              final accent = _accentForDepth(depth, cs);
                              return _MindMapNodeCard(
                                title: node['content']?.toString() ?? '',
                                isRoot: depth == 0,
                                accent: accent,
                              );
                            },
                          ),
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
                  'يمكنك التكبير والتصغير والسحب لاستكشاف الخريطة.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MindMapNodeCard extends StatelessWidget {
  final String title;
  final bool isRoot;
  final Color accent;

  const _MindMapNodeCard({
    required this.title,
    required this.isRoot,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final bg = isRoot
        ? accent
        : Color.alphaBlend(accent.withOpacity(0.48), cs.surface);
    final fg = isRoot ? cs.onPrimary : cs.onSurface;

    return Material(
      color: bg,
      elevation: 2,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isRoot ? Colors.transparent : accent.withOpacity(0.38),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Text(
                title,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MindMapEdgesPainter extends CustomPainter {
  final Map<String, dynamic> root;
  final Offset Function(Map<String, dynamic> node) nodePos;
  final List<Map<String, dynamic>> Function(Map<String, dynamic> node) childrenOf;
  final Size nodeSize;

  _MindMapEdgesPainter({
    required this.root,
    required this.nodePos,
    required this.childrenOf,
    required this.nodeSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    void walk(Map<String, dynamic> parent) {
      final parentPos = nodePos(parent);
      for (final child in childrenOf(parent)) {
        final childPos = nodePos(child);
        final paint = Paint()
          ..color = Colors.black.withOpacity(0.62)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.1;

        // Draw connectors outside card bounds so edges do not cut through text.
        final start = Offset(
          parentPos.dx,
          parentPos.dy + (nodeSize.height / 2) - 2,
        );
        final end = Offset(
          childPos.dx,
          childPos.dy - (nodeSize.height / 2) + 2,
        );
        final midY = (start.dy + end.dy) / 2;
        final path = Path()
          ..moveTo(start.dx, start.dy)
          ..cubicTo(start.dx, midY, end.dx, midY, end.dx, end.dy);
        canvas.drawPath(path, paint);
        walk(child);
      }
    }

    walk(root);
  }

  @override
  bool shouldRepaint(covariant _MindMapEdgesPainter oldDelegate) {
    return oldDelegate.root != root;
  }
}
