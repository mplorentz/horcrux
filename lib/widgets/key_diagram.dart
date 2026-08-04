import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// A single steward in the KeyDiagram.
class KeyDiagramSteward {
  final String id;
  final String label;

  const KeyDiagramSteward({
    required this.id,
    required this.label,
  });
}

/// Animation phase for the recovery demo.
enum RecoveryPhase { dialRotate, spokesPulse, pause, idle }

/// Interactive hub-and-spoke key diagram rendered via CustomPainter.
///
/// Two contexts:
/// 1. HowItWorksScreen — demo stewards, interactive controls
/// 2. BackupConfigScreen — real steward data (future integration)
class KeyDiagram extends StatefulWidget {
  final List<KeyDiagramSteward> stewards;
  final int threshold;
  final int changeCounter;
  final bool showRecoveryDemo;

  const KeyDiagram({
    super.key,
    required this.stewards,
    required this.threshold,
    this.changeCounter = 0,
    this.showRecoveryDemo = false,
  });

  @override
  State<KeyDiagram> createState() => _KeyDiagramState();
}

class _KeyDiagramState extends State<KeyDiagram> with TickerProviderStateMixin {
  // Animation controller for add/remove/threshold transitions (200ms)
  late AnimationController _transitionController;
  late Animation<double> _transitionAnimation;

  // Animation controller for recovery demo
  late AnimationController _recoveryController;
  late Animation<double> _recoveryAnimation;

  RecoveryPhase _recoveryPhase = RecoveryPhase.idle;
  int _recoveryStep = 0;

  // Track previous values to detect changes
  int _prevStewardCount = 0;
  int _prevThreshold = 0;
  int _prevChangeCounter = 0;

  @override
  void initState() {
    super.initState();
    _prevStewardCount = widget.stewards.length;
    _prevThreshold = widget.threshold;
    _prevChangeCounter = widget.changeCounter;

    _transitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _transitionAnimation = CurvedAnimation(
      parent: _transitionController,
      curve: Curves.easeInOut,
    );
    _transitionController.value = 1.0; // fully transitioned initially

    _recoveryController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );
    _recoveryAnimation = CurvedAnimation(
      parent: _recoveryController,
      curve: Curves.linear,
    );
    _recoveryController.addListener(_onRecoveryTick);
    _recoveryController.addStatusListener(_onRecoveryStatus);
  }

  @override
  void didUpdateWidget(KeyDiagram oldWidget) {
    super.didUpdateWidget(oldWidget);
    final stewardChanged = oldWidget.stewards.length != widget.stewards.length;
    final thresholdChanged = oldWidget.threshold != widget.threshold;
    final counterChanged = oldWidget.changeCounter != widget.changeCounter;
    final recoveryChanged = oldWidget.showRecoveryDemo != widget.showRecoveryDemo;

    if (recoveryChanged && widget.showRecoveryDemo && _recoveryPhase == RecoveryPhase.idle) {
      _startRecoveryDemo();
      return;
    }

    if (stewardChanged || thresholdChanged || counterChanged) {
      _prevStewardCount = oldWidget.stewards.length;
      _prevThreshold = oldWidget.threshold;
      _prevChangeCounter = oldWidget.changeCounter;
      // No transition animation: the diagram updates instantly when the
      // steward count or threshold changes (bead horcrux_app-bpeo).
    }

    if (!widget.showRecoveryDemo) {
      _recoveryController.reset();
      _recoveryPhase = RecoveryPhase.idle;
      _recoveryStep = 0;
    }
  }

  void _startRecoveryDemo() {
    // Guard: recovery demo requires at least 1 steward and threshold >= 1.
    if (widget.stewards.isEmpty || widget.threshold < 1) {
      return;
    }
    _recoveryPhase = RecoveryPhase.dialRotate;
    _recoveryStep = 0;
    _recoveryController.duration = Duration(
      milliseconds: widget.threshold * 400 + 1200, // M*400 + dial 400 + pause 800
    );
    _recoveryController.forward(from: 0.0);
  }

  void _onRecoveryTick() {
    final progress = _recoveryAnimation.value;
    final m = widget.threshold;
    if (m < 1) return; // safety: recovery demo shouldn't start with 0 threshold
    final totalMs = _recoveryController.duration!.inMilliseconds.toDouble();
    final dialEnd = 400.0 / totalMs;
    final checkStart = 400.0 / totalMs;
    final checkDuration = (m * 400.0) / totalMs;
    final checkEnd = checkStart + checkDuration;
    final pauseStart = checkEnd;
    final pauseDuration = 800.0 / totalMs;

    if (progress < dialEnd) {
      _recoveryPhase = RecoveryPhase.dialRotate;
    } else if (progress < checkEnd) {
      _recoveryPhase = RecoveryPhase.spokesPulse;
      _recoveryStep = ((progress - checkStart) / checkDuration * m).floor().clamp(0, m - 1);
    } else if (progress < pauseStart + pauseDuration) {
      _recoveryPhase = RecoveryPhase.pause;
    } else {
      _recoveryPhase = RecoveryPhase.idle;
    }
    setState(() {});
  }

  void _onRecoveryStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _recoveryPhase = RecoveryPhase.idle;
      _recoveryStep = 0;
      setState(() {});
    }
  }

  @override
  void dispose() {
    _transitionController.dispose();
    _recoveryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final label = 'Diagram showing ${widget.stewards.length} stewards, '
        'any ${widget.threshold} can recover the vault.';

    return Semantics(
      label: label,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableWidth = constraints.maxWidth;
          // Height: 2 * stewardRadius + vaultSize + padding
          const stewardRadius = 120.0;
          const vaultSize = 40.0;
          final diagramSize = Size(availableWidth, stewardRadius * 2 + vaultSize + 32);
          return SizedBox(
            width: diagramSize.width,
            height: diagramSize.height,
            child: AnimatedBuilder(
              animation: Listenable.merge([_transitionAnimation, _recoveryAnimation]),
              builder: (context, child) {
                final dialRotation = _recoveryPhase == RecoveryPhase.dialRotate
                    ? _recoveryAnimation.value * 90.0 * (pi / 180)
                    : 0.0;

                return Opacity(
                  opacity: _transitionAnimation.value,
                  child: Transform.scale(
                    scale: 0.85 + _transitionAnimation.value * 0.15,
                    child: Stack(
                      children: [
                        CustomPaint(
                          painter: KeyDiagramPainter(
                            stewards: widget.stewards,
                            threshold: widget.threshold,
                            changeCounter: widget.changeCounter,
                            stewardsBeforeUpdate:
                                transitionIsRunning ? _buildPreviousStewards() : widget.stewards,
                            thresholdBeforeUpdate:
                                transitionIsRunning ? _prevThreshold : widget.threshold,
                            changeCounterBeforeUpdate:
                                transitionIsRunning ? _prevChangeCounter : widget.changeCounter,
                            animationValue: _transitionAnimation.value,
                            recoveryPhase: _recoveryPhase,
                            recoveryStep: _recoveryStep,
                            recoveryProgress: _recoveryAnimation.value,
                            isDark: isDark,
                            primaryText: theme.colorScheme.onSurface,
                            dividerColor: theme.colorScheme.outline,
                            secondaryText: theme.colorScheme.outline,
                          ),
                          size: diagramSize,
                        ),
                        Center(
                          child: Transform.rotate(
                            angle: dialRotation,
                            child: SvgPicture.asset(
                              'assets/icon/vault.svg',
                              width: 40,
                              colorFilter: ColorFilter.mode(
                                theme.colorScheme.onSurface,
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  bool get transitionIsRunning => _transitionController.isAnimating;

  List<KeyDiagramSteward> _buildPreviousStewards() {
    if (_prevStewardCount <= widget.stewards.length) {
      return _prevStewardCount > 0
          ? List.generate(
              _prevStewardCount,
              (i) => KeyDiagramSteward(
                id: 'prev_$i',
                label: 'Steward ${i + 1}',
              ),
            )
          : [];
    }
    // If previous had more stewards, use current as base
    return widget.stewards;
  }
}

/// CustomPainter for the KeyDiagram.
class KeyDiagramPainter extends CustomPainter {
  final List<KeyDiagramSteward> stewards;
  final int threshold;
  final int changeCounter;
  final List<KeyDiagramSteward> stewardsBeforeUpdate;
  final int thresholdBeforeUpdate;
  final int changeCounterBeforeUpdate;
  final double animationValue;
  final RecoveryPhase recoveryPhase;
  final int recoveryStep;
  final double recoveryProgress;
  final bool isDark;
  final Color primaryText;
  final Color dividerColor;
  final Color secondaryText;

  KeyDiagramPainter({
    required this.stewards,
    required this.threshold,
    required this.changeCounter,
    required this.stewardsBeforeUpdate,
    required this.thresholdBeforeUpdate,
    required this.changeCounterBeforeUpdate,
    required this.animationValue,
    required this.recoveryPhase,
    required this.recoveryStep,
    required this.recoveryProgress,
    required this.isDark,
    required this.primaryText,
    required this.dividerColor,
    required this.secondaryText,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final n = stewards.length;

    if (n == 0) return;

    // Compute steward positions
    final stewardRadius = min(120.0, size.width / 2 - 30);
    final effectiveRadius = n > 6 ? min(100.0, size.width / 2 - 24) : stewardRadius;
    final iconSize = n > 6 ? 18.0 : 24.0;
    final keySize = n > 6 ? 14.0 : 16.0;

    final positions = <Offset>[];
    for (int i = 0; i < n; i++) {
      final angle = (2 * pi * i / n) - pi / 2;
      positions.add(center + Offset(cos(angle) * effectiveRadius, sin(angle) * effectiveRadius));
    }

    // Determine which spokes are solid
    final solidSpokes = _computeSolidSpokes(n);

    // Draw spokes behind everything
    // Lines start 5px outside vault box and stop 5px short of key icons
    const vaultHalf = 20.0; // vaultSize / 2
    const spokeStartRadius = vaultHalf + 5;
    const spokeEndFraction = 0.62; // ~5px before key icon at 0.67
    for (int i = 0; i < n; i++) {
      final isSolid = solidSpokes.contains(i);
      final spokeStart = Offset.lerp(
        center,
        positions[i],
        spokeStartRadius / effectiveRadius,
      )!;
      final spokeEnd = Offset.lerp(
        center,
        positions[i],
        spokeEndFraction,
      )!;
      _drawSpoke(canvas, spokeStart, spokeEnd, isSolid, i);
    }

    // Draw key icons at spoke endpoints
    for (int i = 0; i < n; i++) {
      final keyPos = Offset.lerp(center, positions[i], 0.67)!;
      _drawIcon(canvas, keyPos, Icons.key, keySize, primaryText);
    }

    // Draw steward icons
    for (int i = 0; i < n; i++) {
      final showCheck =
          recoveryPhase == RecoveryPhase.spokesPulse && i < threshold && i <= recoveryStep;

      _drawStewardIcon(canvas, positions[i], iconSize, stewards[i].label, showCheck);
    }
  }

  Set<int> _computeSolidSpokes(int n) {
    if (n == 0) return {};
    final seed = n ^ threshold ^ changeCounter;
    final rng = Random(seed);
    final indices = List.generate(n, (i) => i)..shuffle(rng);
    return indices.take(threshold.clamp(0, n)).toSet();
  }

  void _drawSpoke(Canvas canvas, Offset from, Offset to, bool isSolid, int index) {
    if (isSolid) {
      final paint = Paint()
        ..color = primaryText
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;
      canvas.drawLine(from, to, paint);
    } else {
      final paint = Paint()
        ..color = primaryText
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;
      final path = Path()
        ..moveTo(from.dx, from.dy)
        ..lineTo(to.dx, to.dy);
      _drawDashedPath(canvas, path, paint, 4.0, 4.0);
    }
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint, double dash, double gap) {
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final end = min(distance + dash, metric.length);
        final segment = metric.extractPath(distance, end);
        canvas.drawPath(segment, paint);
        distance += dash + gap;
      }
    }
  }

  void _drawIcon(Canvas canvas, Offset center, IconData icon, double size, Color color) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontFamily: icon.fontFamily,
          fontSize: size,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    final offset = Offset(
      center.dx - textPainter.width / 2,
      center.dy - textPainter.height / 2,
    );
    textPainter.paint(canvas, offset);
  }

  void _drawStewardIcon(
    Canvas canvas,
    Offset center,
    double size,
    String label,
    bool showCheck,
  ) {
    // Draw person icon
    final textPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(Icons.person.codePoint),
        style: TextStyle(
          fontFamily: Icons.person.fontFamily,
          fontSize: size,
          color: primaryText,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    final iconOffset = Offset(
      center.dx - textPainter.width / 2,
      center.dy - textPainter.height / 2,
    );
    textPainter.paint(canvas, iconOffset);

    // Checkmark overlay for recovery demo
    if (showCheck) {
      final checkPainter = TextPainter(
        text: TextSpan(
          text: String.fromCharCode(Icons.check_circle.codePoint),
          style: TextStyle(
            fontFamily: Icons.check_circle.fontFamily,
            fontSize: size * 0.8,
            color: primaryText,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      checkPainter.layout();
      final checkOffset = Offset(
        center.dx + size / 3,
        center.dy - size / 2,
      );
      checkPainter.paint(canvas, checkOffset);
    }
  }

  @override
  bool shouldRepaint(KeyDiagramPainter oldDelegate) {
    return oldDelegate.stewards.length != stewards.length ||
        oldDelegate.threshold != threshold ||
        oldDelegate.changeCounter != changeCounter ||
        oldDelegate.animationValue != animationValue ||
        oldDelegate.recoveryPhase != recoveryPhase ||
        oldDelegate.recoveryStep != recoveryStep ||
        oldDelegate.recoveryProgress != recoveryProgress ||
        oldDelegate.isDark != isDark;
  }
}
