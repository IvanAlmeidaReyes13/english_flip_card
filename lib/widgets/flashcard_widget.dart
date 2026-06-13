import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../components/theme/app_colors.dart';
import '../components/theme/app_text_styles.dart';

class FlashcardWidget extends StatefulWidget {
  final String frontText;
  final String backText;
  final String? noteText;
  final Color cardColor;
  final int mastery;
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onSwipeRight;
  final VoidCallback? onTap;

  const FlashcardWidget({
    super.key,
    required this.frontText,
    required this.backText,
    this.noteText,
    required this.cardColor,
    required this.mastery,
    this.onSwipeLeft,
    this.onSwipeRight,
    this.onTap,
  });

  @override
  State<FlashcardWidget> createState() => _FlashcardWidgetState();
}

class _FlashcardWidgetState extends State<FlashcardWidget>
    with TickerProviderStateMixin {
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;
  late AnimationController _motionController;
  Animation<Offset>? _motionAnimation;
  bool _isFlipped = false;
  bool _isSwiping = false;
  Offset _dragOffset = Offset.zero;

  static const double _swipeThreshold = 120.0;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _flipAnimation = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    );
    _motionController = AnimationController(
      duration: const Duration(milliseconds: 260),
      vsync: this,
    )..addListener(() {
      final animation = _motionAnimation;
      if (animation == null) return;
      setState(() {
        _dragOffset = animation.value;
      });
    });
  }

  @override
  void dispose() {
    _flipController.dispose();
    _motionController.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (_isSwiping) return;
    if (_isFlipped) {
      _flipController.reverse();
    } else {
      _flipController.forward();
    }
    _isFlipped = !_isFlipped;
    widget.onTap?.call();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (_isSwiping) return;
    setState(() {
      _dragOffset += details.delta;
    });
  }

  Future<void> _handleDragEnd(DragEndDetails details) async {
    if (_isSwiping) return;

    final projectedDx =
        _dragOffset.dx + details.velocity.pixelsPerSecond.dx * 0.12;
    if (projectedDx.abs() > _swipeThreshold) {
      await _animateOut(projectedDx.sign);
      if (!mounted) return;
      projectedDx > 0
          ? widget.onSwipeRight?.call()
          : widget.onSwipeLeft?.call();
      return;
    }

    await _animateTo(Offset.zero, Curves.easeOutBack);
  }

  Future<void> _animateOut(double direction) async {
    _isSwiping = true;
    final size = MediaQuery.sizeOf(context);
    final endOffset = Offset(
      direction * size.width * 1.25,
      _dragOffset.dy + 80,
    );
    await _animateTo(endOffset, Curves.easeOutCubic);
  }

  Future<void> _animateTo(Offset endOffset, Curve curve) async {
    _motionController.stop();
    _motionController.reset();
    _motionAnimation = Tween<Offset>(
      begin: _dragOffset,
      end: endOffset,
    ).animate(CurvedAnimation(parent: _motionController, curve: curve));
    await _motionController.forward();
    if (mounted && endOffset == Offset.zero) {
      setState(() {
        _dragOffset = Offset.zero;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_dragOffset.dx.abs() / _swipeThreshold).clamp(0.0, 1.0);
    final rotation = (_dragOffset.dx / 420).clamp(-0.22, 0.22);

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          alignment: Alignment.center,
          children: [
            _buildStackCard(),
            GestureDetector(
              onTap: _handleTap,
              onPanUpdate: _handleDragUpdate,
              onPanEnd: _handleDragEnd,
              child: Transform.translate(
                offset: _dragOffset,
                child: Transform.rotate(
                  angle: rotation,
                  child: AnimatedBuilder(
                    animation: _flipAnimation,
                    builder: (context, child) {
                      final angle = _flipAnimation.value * math.pi;
                      final isFront = angle < math.pi / 2;

                      return Transform(
                        alignment: Alignment.center,
                        transform:
                            Matrix4.identity()
                              ..setEntry(3, 2, 0.001)
                              ..rotateY(angle),
                        child: Stack(
                          children: [
                            _buildCardSurface(
                              child:
                                  isFront
                                      ? _buildFrontContent()
                                      : Transform(
                                        alignment: Alignment.center,
                                        transform: Matrix4.rotationY(math.pi),
                                        child: _buildBackContent(),
                                      ),
                            ),
                            _buildSwipeBadge(
                              alignment: Alignment.topLeft,
                              opacity: _dragOffset.dx < 0 ? progress : 0.0,
                              color: AppColors.error,
                              icon: Icons.close,
                              label: 'Repasar',
                            ),
                            _buildSwipeBadge(
                              alignment: Alignment.topRight,
                              opacity: _dragOffset.dx > 0 ? progress : 0.0,
                              color: AppColors.success,
                              icon: Icons.check,
                              label: 'Lo sé',
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStackCard() {
    return Transform.translate(
      offset: const Offset(0, 16),
      child: Transform.scale(
        scale: 0.94,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant.withValues(alpha: 0.34),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
        ),
      ),
    );
  }

  Widget _buildCardSurface({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: widget.cardColor.withValues(alpha: 0.36)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(height: 4, color: widget.cardColor),
            ),
            Padding(padding: const EdgeInsets.all(24), child: child),
          ],
        ),
      ),
    );
  }

  Widget _buildFrontContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Spacer(),
        Flexible(
          flex: 4,
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 260),
                child: Text(
                  widget.frontText,
                  style: AppTextStyles.heading1.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 40,
                    letterSpacing: 0,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 4,
                ),
              ),
            ),
          ),
        ),
        const Spacer(),
      ],
    );
  }

  Widget _buildBackContent() {
    final note = widget.noteText?.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Spacer(),
        Text(
          widget.backText,
          style: AppTextStyles.heading1.copyWith(
            color: AppColors.textPrimary,
            fontSize: 36,
            letterSpacing: 0,
          ),
          textAlign: TextAlign.center,
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
        ),
        if (note != null && note.isNotEmpty) ...[
          const SizedBox(height: 18),
          Text(
            note,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        const Spacer(),
        _buildMasteryBar(),
      ],
    );
  }

  Widget _buildMasteryBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              'Dominio',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              '${widget.mastery}%',
              style: AppTextStyles.caption.copyWith(
                color: _masteryColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 4,
            value: widget.mastery / 100,
            backgroundColor: AppColors.surfaceVariant,
            valueColor: AlwaysStoppedAnimation<Color>(_masteryColor),
          ),
        ),
      ],
    );
  }

  Widget _buildSwipeBadge({
    required Alignment alignment,
    required double opacity,
    required Color color,
    required IconData icon,
    required String label,
  }) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Align(
          alignment: alignment,
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Opacity(
              opacity: opacity.clamp(0.0, 1.0),
              child: Transform.rotate(
                angle: alignment == Alignment.topLeft ? -0.20 : 0.20,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: color, width: 2),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, color: color, size: 20),
                      const SizedBox(width: 6),
                      Text(
                        label.toUpperCase(),
                        style: AppTextStyles.button.copyWith(
                          color: color,
                          letterSpacing: 0,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color get _masteryColor {
    if (widget.mastery < 30) return AppColors.error;
    if (widget.mastery < 70) return AppColors.warning;
    return AppColors.success;
  }
}
