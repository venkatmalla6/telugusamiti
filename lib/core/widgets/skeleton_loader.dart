import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// A shimmer-style skeleton placeholder widget for loading states.
class SkeletonBox extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SkeletonBox({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.borderRadius = 8,
  });

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;

    return AnimatedBuilder(
      animation: _animation,
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          color: Color.lerp(baseColor, highlightColor, _animation.value),
        ),
      ),
    );
  }
}

/// Skeleton for an announcement card
class AnnouncementSkeleton extends StatelessWidget {
  const AnnouncementSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            SkeletonBox(height: 18, width: 180),
            SizedBox(height: 8),
            SkeletonBox(height: 12, width: 100),
            SizedBox(height: 12),
            SkeletonBox(height: 14),
            SizedBox(height: 6),
            SkeletonBox(height: 14, width: 250),
          ],
        ),
      ),
    );
  }
}

/// Skeleton for an event card
class EventSkeleton extends StatelessWidget {
  const EventSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Theme.of(context).cardColor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonBox(height: 120, borderRadius: 16),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                SkeletonBox(height: 16, width: 140),
                SizedBox(height: 8),
                SkeletonBox(height: 12, width: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton for membership card
class MembershipSkeleton extends StatelessWidget {
  const MembershipSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppColors.primaryMaroon.withValues(alpha: 0.15),
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          const SkeletonBox(width: 64, height: 64, borderRadius: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                SkeletonBox(height: 18, width: 140),
                SizedBox(height: 8),
                SkeletonBox(height: 14, width: 100),
                SizedBox(height: 6),
                SkeletonBox(height: 14, width: 120),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
