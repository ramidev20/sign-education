import 'dart:math';

import 'package:flutter/material.dart';
import 'package:sign_education/data/models/user_model.dart';

class SixHatPage extends StatefulWidget {
  final UserModel user;
  final Map<String, dynamic> jsonInput;

  const SixHatPage({
    super.key,
    required this.user,
    required this.jsonInput,
  });

  @override
  State<SixHatPage> createState() => _SixHatPageState();
}

class _SixHatPageState extends State<SixHatPage> {
  static const _sceneSize = Size(1120, 860);
  final _transform = TransformationController();
  final _viewerKey = GlobalKey();
  bool _didInitTransform = false;

  static const _hats = <_HatDef>[
    _HatDef('white_hat', 'القبعة البيضاء', Color(0xFFF8FAFC), Color(0xFF0F172A)),
    _HatDef('red_hat', 'القبعة الحمراء', Color(0xFFEF4444), Colors.white),
    _HatDef('black_hat', 'القبعة السوداء', Color(0xFF111827), Colors.white),
    _HatDef('yellow_hat', 'القبعة الصفراء', Color(0xFFFACC15), Color(0xFF111827)),
    _HatDef('green_hat', 'القبعة الخضراء', Color(0xFF22C55E), Color(0xFF052E16)),
    _HatDef('blue_hat', 'القبعة الزرقاء', Color(0xFF2563EB), Colors.white),
  ];

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
    final scale = min(1.0, max(0.74, fittedScale * 0.92));
    final tx = (viewport.width / 2) - ((_sceneSize.width / 2) * scale);
    final ty = (viewport.height / 2) - ((_sceneSize.height / 2) * scale);

    _transform.value = Matrix4.identity()
      ..translate(tx, ty)
      ..scale(scale);
    _didInitTransform = true;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('القبعات الست'),
          centerTitle: true,
        ),
        body: InteractiveViewer(
          key: _viewerKey,
          transformationController: _transform,
          minScale: 0.55,
          maxScale: 2.5,
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
                          Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest
                              .withOpacity(0.22),
                        ],
                      ),
                    ),
                  ),
                ),
                for (var i = 0; i < _hats.length; i++)
                  _PositionedHatCard(
                    index: i,
                    hat: _hats[i],
                    content: (widget.jsonInput[_hats[i].key] ?? '').toString(),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HatDef {
  final String key;
  final String label;
  final Color color;
  final Color textColor;

  const _HatDef(this.key, this.label, this.color, this.textColor);
}

class _PositionedHatCard extends StatelessWidget {
  final int index;
  final _HatDef hat;
  final String content;

  const _PositionedHatCard({
    required this.index,
    required this.hat,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    const centerX = 560.0;
    const centerY = 420.0;
    const radiusX = 320.0;
    const radiusY = 250.0;
    const cardW = 320.0;
    const cardH = 210.0;

    final angle = (-pi / 2) + ((2 * pi) * index / 6);
    final left = centerX + (radiusX * cos(angle)) - (cardW / 2);
    final top = centerY + (radiusY * sin(angle)) - (cardH / 2);

    return Positioned(
      left: left,
      top: top,
      width: cardW,
      height: cardH,
      child: _HatCard(
        hat: hat,
        content: content,
      ),
    );
  }
}

class _HatCard extends StatelessWidget {
  final _HatDef hat;
  final String content;

  const _HatCard({
    required this.hat,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: hat.color,
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
            hat.label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: hat.textColor,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: SingleChildScrollView(
              child: Text(
                content.trim().isEmpty ? '-' : content,
                style: TextStyle(
                  color: hat.textColor.withOpacity(0.95),
                  height: 1.38,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

