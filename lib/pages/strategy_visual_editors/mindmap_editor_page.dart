import 'dart:math';

import 'package:flutter/material.dart';
import 'package:sign_education/data/db/db_helper_lesson_strategies.dart';
import 'package:sign_education/data/models/lesson_strategy_model.dart';
import 'package:uuid/uuid.dart';

class MindMapEditorPage extends StatefulWidget {
  final LessonStrategyModel strategy;
  const MindMapEditorPage({super.key, required this.strategy});

  @override
  State<MindMapEditorPage> createState() => _MindMapEditorPageState();
}

class _MindMapEditorPageState extends State<MindMapEditorPage> {
  static const _nodeSize = Size(220, 92);
  static const _baseCanvasSize = Size(1600, 1200);
  static const _horizontalGap = 56.0;
  static const _verticalGap = 165.0;
  static const _topMargin = 110.0;
  static const _sideMargin = 80.0;
  final _transform = TransformationController();
  final _canvasKey = GlobalKey();
  final _viewerKey = GlobalKey();

  late Map<String, dynamic> _root;
  Size _canvasSize = _baseCanvasSize;
  bool _saving = false;

  String? _linkFromId;
  Offset? _linkToScene;
  bool _centeredOnce = false;

  @override
  void initState() {
    super.initState();
    _root = _ensureMindMapDefaults(
      Map<String, dynamic>.from(widget.strategy.contentJson),
    );
    _autoLayoutTree();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fitTreeInViewport();
    });
  }

  Map<String, dynamic> _ensureMindMapDefaults(Map<String, dynamic> root) {
    root['id'] ??= 'root';
    root['content'] ??= '';
    root['nodes'] ??= <dynamic>[];
    root['pos'] ??= {'x': _baseCanvasSize.width / 2, 'y': _topMargin};

    void walk(Map<String, dynamic> node, int depth) {
      node['id'] ??= const Uuid().v4();
      node['content'] ??= '';
      node['nodes'] ??= <dynamic>[];
      node['pos'] ??= {
        'x': (root['pos']?['x'] ?? (_baseCanvasSize.width / 2)) +
            (depth + 1) * 220.0,
        'y': (root['pos']?['y'] ?? _topMargin) + Random().nextInt(180) - 90,
      };
      for (final child in _children(node)) {
        walk(child, depth + 1);
      }
    }

    for (final n in _children(root)) {
      walk(n, 0);
    }
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

  Offset _nodePos(Map<String, dynamic> node) {
    final p = Map<String, dynamic>.from(node['pos'] ?? const {});
    final x = (p['x'] is num) ? (p['x'] as num).toDouble() : 0.0;
    final y = (p['y'] is num) ? (p['y'] as num).toDouble() : 0.0;
    return Offset(x, y);
  }

  void _setNodePos(Map<String, dynamic> node, Offset pos) {
    node['pos'] = {'x': pos.dx, 'y': pos.dy};
  }

  Iterable<Map<String, dynamic>> _walk(Map<String, dynamic> node) sync* {
    yield node;
    for (final child in _children(node)) {
      yield* _walk(child);
    }
  }

  Map<String, dynamic>? _findNode(String id, Map<String, dynamic> node) {
    if (node['id'] == id) return node;
    for (final child in _children(node)) {
      final found = _findNode(id, child);
      if (found != null) return found;
    }
    return null;
  }

  bool _removeNode(String id, Map<String, dynamic> node) {
    final children = _children(node);
    final idx = children.indexWhere(
      (e) => e['id']?.toString() == id,
    );
    if (idx != -1) {
      children.removeAt(idx);
      return true;
    }
    for (final child in children) {
      if (_removeNode(id, child)) return true;
    }
    return false;
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
      final child = children[i];
      total += _subtreeWidth(child);
      if (i < children.length - 1) total += _horizontalGap;
    }
    return max(total, minWidth);
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

  void _autoLayoutTree() {
    final treeWidth = _subtreeWidth(_root);
    final depth = _maxDepth(_root);
    final width = max(
      _baseCanvasSize.width,
      treeWidth + (_sideMargin * 2),
    );
    final height = max(
      _baseCanvasSize.height,
      _topMargin + (depth * _verticalGap) + 220,
    );
    _canvasSize = Size(width, height);

    final left = (width - treeWidth) / 2;
    _layoutNode(_root, left, 0);
  }

  Rect _treeBounds() {
    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = -double.infinity;
    double maxY = -double.infinity;

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

  void _fitTreeInViewport() {
    if (!mounted) return;
    final viewerBox = _viewerKey.currentContext?.findRenderObject() as RenderBox?;
    final viewport = viewerBox?.size ?? context.size;
    if (viewport == null || viewport.width <= 0 || viewport.height <= 0) return;

    final bounds = _treeBounds().inflate(40);
    const horizontalPadding = 28.0;
    const topPadding = 18.0;
    const bottomPadding = 110.0;
    final availableWidth = max(1.0, viewport.width - (horizontalPadding * 2));
    final availableHeight = max(1.0, viewport.height - topPadding - bottomPadding);

    final scaleX = availableWidth / bounds.width;
    final scaleY = availableHeight / bounds.height;
    final fitted = min(scaleX, scaleY);
    final scale = min(1.15, max(0.40, fitted * 1.08));

    final tx =
        ((horizontalPadding + (availableWidth / 2)) -
            ((bounds.left + bounds.width / 2) * scale));
    final ty =
        ((topPadding + (availableHeight / 2)) -
            ((bounds.top + bounds.height / 2) * scale));

    _transform.value = Matrix4.identity()
      ..translate(tx, ty)
      ..scale(scale);
    _centeredOnce = true;
  }

  void _addChild(String parentId) {
    final parent = _findNode(parentId, _root);
    if (parent == null) return;

    final newId = const Uuid().v4();
    final parentPos = _nodePos(parent);
    final newNode = <String, dynamic>{
      'id': newId,
      'content': 'عنصر جديد',
      'pos': {'x': parentPos.dx + 220, 'y': parentPos.dy + 100},
      'nodes': <dynamic>[],
    };
    (parent['nodes'] as List).add(newNode);
    _autoLayoutTree();
    setState(() {});
  }

  Future<void> _editText(Map<String, dynamic> node) async {
    final controller = TextEditingController(text: node['content']?.toString() ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('تعديل النص'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            minLines: 1,
            maxLines: 4,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('حفظ'),
            ),
          ],
        );
      },
    );
    if (result == null) return;
    node['content'] = result;
    setState(() {});
  }

  void _deleteNode(String id) {
    if (id == (_root['id']?.toString() ?? 'root')) return;
    _removeNode(id, _root);
    _autoLayoutTree();
    setState(() {});
  }

  String? _hitTestNode(Offset scenePoint) {
    for (final node in _walk(_root)) {
      final pos = _nodePos(node);
      final rect = Rect.fromCenter(
        center: pos,
        width: _nodeSize.width,
        height: _nodeSize.height,
      );
      if (rect.contains(scenePoint)) return node['id']?.toString();
    }
    return null;
  }

  Offset _globalToScene(Offset global) {
    final box = _canvasKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return Offset.zero;
    final local = box.globalToLocal(global);
    return _transform.toScene(local);
  }

  void _reparent({required String childId, required String newParentId}) {
    if (childId == newParentId) return;
    if (childId == (_root['id']?.toString() ?? 'root')) return;

    final child = _findNode(childId, _root);
    final newParent = _findNode(newParentId, _root);
    if (child == null || newParent == null) return;

    // Prevent cycles: new parent cannot be inside child's subtree.
    for (final n in _walk(child)) {
      if (n['id']?.toString() == newParentId) return;
    }

    _removeNode(childId, _root);
    (newParent['nodes'] as List).add(child);
    _autoLayoutTree();
    setState(() {});
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await DbHelperLessonStrategies.updateStrategy(
        lessonStrategyId: widget.strategy.lessonStrategyId,
        contentJson: _root,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر الحفظ: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('محرّر الخريطة الذهنية'),
          centerTitle: true,
          actions: [
            IconButton(
              tooltip: 'ترتيب تلقائي',
              onPressed: () {
                _autoLayoutTree();
                setState(() {});
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _fitTreeInViewport();
                });
              },
              icon: const Icon(Icons.auto_fix_high_outlined),
            ),
            IconButton(
              tooltip: 'حفظ',
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
            ),
          ],
        ),
        body: Stack(
          children: [
            InteractiveViewer(
              key: _viewerKey,
              transformationController: _transform,
              boundaryMargin: const EdgeInsets.all(600),
              constrained: false,
              clipBehavior: Clip.none,
              minScale: 0.3,
              maxScale: 2.8,
              child: SizedBox(
                key: _canvasKey,
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
                          linkFromId: _linkFromId,
                          linkToScene: _linkToScene,
                          color: Colors.black.withOpacity(0.62),
                        ),
                      ),
                    ),
                    for (final node in _walk(_root))
                      _MindMapNode(
                        key: ValueKey(node['id']?.toString()),
                        node: node,
                        size: _nodeSize,
                        pos: _nodePos(node),
                        isRoot: node['id']?.toString() ==
                            (_root['id']?.toString() ?? 'root'),
                        onMove: (deltaScene) {
                          final pos = _nodePos(node);
                          _setNodePos(node, pos + deltaScene);
                          setState(() {});
                        },
                        onEdit: () => _editText(node),
                        onAddChild: () => _addChild(node['id']?.toString() ?? ''),
                        onDelete: () => _deleteNode(node['id']?.toString() ?? ''),
                        onStartLink: (sceneStart) {
                          _linkFromId = node['id']?.toString();
                          _linkToScene = _globalToScene(sceneStart);
                          setState(() {});
                        },
                        onUpdateLink: (scenePoint) {
                          _linkToScene = _globalToScene(scenePoint);
                          setState(() {});
                        },
                        onEndLink: (scenePoint) {
                          final fromId = _linkFromId;
                          final targetId = _hitTestNode(_globalToScene(scenePoint));
                          _linkFromId = null;
                          _linkToScene = null;
                          setState(() {});
                          if (fromId != null && targetId != null) {
                            _reparent(childId: targetId, newParentId: fromId);
                          }
                        },
                        scale: () => _transform.value.getMaxScaleOnAxis(),
                      ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 12,
              left: 12,
              child: FloatingActionButton.small(
                heroTag: 'mindmap_center_btn',
                onPressed: _fitTreeInViewport,
                child: const Icon(Icons.center_focus_strong),
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
                  'الخريطة تُرتَّب تلقائياً من الأعلى إلى الأسفل. اضغط مرتين لتعديل النص، (+) لإضافة طفل، واسحب "ربط" لإعادة ربط الفرع.',
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

class _MindMapNode extends StatefulWidget {
  final Map<String, dynamic> node;
  final Size size;
  final Offset pos;
  final bool isRoot;
  final void Function(Offset deltaScene) onMove;
  final VoidCallback onEdit;
  final VoidCallback onAddChild;
  final VoidCallback onDelete;
  final void Function(Offset globalStart) onStartLink;
  final void Function(Offset globalPoint) onUpdateLink;
  final void Function(Offset globalPoint) onEndLink;
  final double Function() scale;

  const _MindMapNode({
    super.key,
    required this.node,
    required this.size,
    required this.pos,
    required this.isRoot,
    required this.onMove,
    required this.onEdit,
    required this.onAddChild,
    required this.onDelete,
    required this.onStartLink,
    required this.onUpdateLink,
    required this.onEndLink,
    required this.scale,
  });

  @override
  State<_MindMapNode> createState() => _MindMapNodeState();
}

class _MindMapNodeState extends State<_MindMapNode> {
  Offset? _lastGlobal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final title = widget.node['content']?.toString() ?? '';
    final scale = widget.scale();

    return Positioned(
      left: widget.pos.dx - widget.size.width / 2,
      top: widget.pos.dy - widget.size.height / 2,
      width: widget.size.width,
      height: widget.size.height,
      child: GestureDetector(
        onDoubleTap: widget.onEdit,
        onPanUpdate: (d) {
          widget.onMove(Offset(d.delta.dx / scale, d.delta.dy / scale));
        },
        child: Material(
          color: widget.isRoot ? cs.primary : cs.surface,
          borderRadius: BorderRadius.circular(14),
          elevation: 2,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(52, 14, 52, 34),
                  child: Center(
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: widget.isRoot ? cs.onPrimary : cs.onSurface,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 4,
                left: 4,
                child: IconButton.filledTonal(
                  onPressed: widget.onAddChild,
                  icon: const Icon(Icons.add_rounded),
                  visualDensity: VisualDensity.compact,
                ),
              ),
              if (!widget.isRoot)
                Positioned(
                  top: 4,
                  right: 4,
                  child: IconButton.filledTonal(
                    onPressed: widget.onDelete,
                    icon: const Icon(Icons.delete_outline_rounded),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              Positioned(
                bottom: 4,
                left: (widget.size.width / 2) - 22,
                child: GestureDetector(
                  onPanStart: (d) {
                    _lastGlobal = d.globalPosition;
                    widget.onStartLink(d.globalPosition);
                  },
                  onPanUpdate: (d) {
                    _lastGlobal = d.globalPosition;
                    widget.onUpdateLink(d.globalPosition);
                  },
                  onPanEnd: (_) {
                    widget.onEndLink(_lastGlobal ?? Offset.zero);
                    _lastGlobal = null;
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: cs.secondaryContainer,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: cs.outlineVariant),
                    ),
                    child: Text(
                      'ربط',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: cs.onSecondaryContainer,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MindMapEdgesPainter extends CustomPainter {
  final Map<String, dynamic> root;
  final Offset Function(Map<String, dynamic> node) nodePos;
  final String? linkFromId;
  final Offset? linkToScene;
  final Color color;

  _MindMapEdgesPainter({
    required this.root,
    required this.nodePos,
    required this.linkFromId,
    required this.linkToScene,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;

    void walk(Map<String, dynamic> parent) {
      final parentPos = nodePos(parent);
      for (final child in (parent['nodes'] as List).cast<dynamic>()) {
        final c = Map<String, dynamic>.from(child);
        final childPos = nodePos(c);
        canvas.drawLine(parentPos, childPos, p);
        walk(c);
      }
    }

    walk(root);

    if (linkFromId != null && linkToScene != null) {
      Map<String, dynamic>? find(Map<String, dynamic> node) {
        if (node['id']?.toString() == linkFromId) return node;
        for (final child in (node['nodes'] as List).cast<dynamic>()) {
          final found = find(Map<String, dynamic>.from(child));
          if (found != null) return found;
        }
        return null;
      }

      final fromNode = find(root);
      if (fromNode != null) {
        canvas.drawLine(nodePos(fromNode), linkToScene!, p);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MindMapEdgesPainter oldDelegate) {
    return oldDelegate.root != root ||
        oldDelegate.linkFromId != linkFromId ||
        oldDelegate.linkToScene != linkToScene ||
        oldDelegate.color != color;
  }
}
