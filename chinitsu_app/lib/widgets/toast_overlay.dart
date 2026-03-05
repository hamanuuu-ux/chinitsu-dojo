import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// バッジ獲得トースト
void showBadgeToast(BuildContext context, String icon, String name) {
  _showToast(
    context,
    icon: icon,
    title: '$name 獲得！',
    color: AppColors.gold,
    duration: const Duration(seconds: 2),
  );
}

/// 段位アップトースト
void showRankUpToast(BuildContext context, String rankName) {
  _showToast(
    context,
    icon: '🎊',
    title: '$rankName に昇段！',
    color: AppColors.gold,
    duration: const Duration(seconds: 3),
  );
}

/// 段位ダウントースト
void showRankDownToast(BuildContext context, String rankName) {
  _showToast(
    context,
    icon: '📉',
    title: '$rankName に降段',
    color: AppColors.rpMinus,
    duration: const Duration(seconds: 2),
  );
}

void _showToast(
  BuildContext context, {
  required String icon,
  required String title,
  required Color color,
  Duration duration = const Duration(seconds: 2),
}) {
  final overlay = Overlay.of(context);
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (ctx) => _ToastWidget(
      icon: icon,
      title: title,
      color: color,
      duration: duration,
      onDismiss: () { try { entry.remove(); } catch (_) {} }, // BUG-08
    ),
  );
  overlay.insert(entry);
}

class _ToastWidget extends StatefulWidget {
  final String icon;
  final String title;
  final Color color;
  final Duration duration;
  final VoidCallback onDismiss;

  const _ToastWidget({
    required this.icon,
    required this.title,
    required this.color,
    required this.duration,
    required this.onDismiss,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();

    Future.delayed(widget.duration, () {
      if (mounted) {
        _controller.reverse().then((_) {
          if (mounted) widget.onDismiss();
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 24,
      right: 24,
      child: SlideTransition(
        position: _slideAnim,
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            color: AppColors.paper,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: widget.color, width: 2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(widget.icon, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: AppTheme.bodyStyle(
                        fontSize: 15,
                        color: widget.color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
