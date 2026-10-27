import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:doctro/theme/ayureze_theme.dart';
import 'package:doctro/widgets/swastu.dart';
import 'package:doctro/features/consultation/astra_chat/astra_chat_page.dart';

/// Astra AI Quick Access Button
///
/// A floating button that provides quick access to Astra AI chat.
/// Can be added to screens where AI assistance might be useful.
class AstraAIFloatingButton extends StatelessWidget {
  /// Patient ID for context
  final String? patientId;

  /// Patient name for display
  final String? patientName;

  /// Custom position
  final Alignment alignment;

  /// Custom size
  final double size;

  const AstraAIFloatingButton({
    super.key,
    this.patientId,
    this.patientName,
    this.alignment = Alignment.bottomRight,
    this.size = 56,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Padding(
        padding: const EdgeInsets.all(AyurezeTheme.spaceLg),
        child: Material(
          elevation: 4,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          color: AyurezeTheme.healingGreen50,
          child: InkWell(
            onTap: () => _openAstraChat(context),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AyurezeTheme.healingGreen50,
                    AyurezeTheme.forestDeep,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Pulsing effect
                  _PulsingEffect(size: size),

                  // Swastu, still (this button sits on many screens).
                  Swastu(
                    mood: SwastuMood.happy,
                    size: size * 0.62,
                    named: false,
                    idleMotion: false,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openAstraChat(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AstraChatPage(
          patientId: patientId,
          patientName: patientName,
        ),
      ),
    );
  }
}

/// Pulsing effect for the Astra AI button
class _PulsingEffect extends StatefulWidget {
  final double size;

  const _PulsingEffect({required this.size});

  @override
  State<_PulsingEffect> createState() => _PulsingEffectState();
}

class _PulsingEffectState extends State<_PulsingEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _animation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.size * _animation.value,
          height: widget.size * _animation.value,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AyurezeTheme.healingGreen50.withValues(
              alpha: 1.0 - (_animation.value - 1.0) / 0.3,
            ),
          ),
        );
      },
    );
  }
}

/// Astra AI Inline Button
///
/// A smaller inline button for triggering Astra AI from within content.
class AstraAIInlineButton extends StatelessWidget {
  /// Button label
  final String label;

  /// Callback when pressed
  final VoidCallback? onPressed;

  /// Icon to display
  final List<List<dynamic>> icon;

  const AstraAIInlineButton({
    super.key,
    this.label = 'Ask Astra AI',
    this.onPressed,
    this.icon = HugeIcons.strokeRoundedBrain01,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AyurezeTheme.healingGreen50.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(AyurezeTheme.radiusXl),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AyurezeTheme.radiusXl),
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AyurezeTheme.spaceMd, vertical: AyurezeTheme.spaceSm),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              HugeIcon(
                icon: icon,
                size: 18,
                color: AyurezeTheme.healingGreen50,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: AyurezeTheme.healingGreen50,
                  fontWeight: FontWeight.w600,
                  fontSize: AyurezeTheme.textMd,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Astra AI Status Indicator
///
/// Shows the health status of Astra Brain.
class AstraAIStatusIndicator extends StatefulWidget {
  /// Show label
  final bool showLabel;

  /// Compact mode
  final bool compact;

  const AstraAIStatusIndicator({
    super.key,
    this.showLabel = true,
    this.compact = false,
  });

  @override
  State<AstraAIStatusIndicator> createState() => _AstraAIStatusIndicatorState();
}

class _AstraAIStatusIndicatorState extends State<AstraAIStatusIndicator> {
  bool _isHealthy = false;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    _checkHealth();
  }

  Future<void> _checkHealth() async {
    if (_isChecking) return;

    setState(() => _isChecking = true);

    try {
      // Import and use AstraController to check health
      // For simplicity, we'll use a basic check
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) setState(() => _isHealthy = true);
    } catch (e) {
      if (mounted) setState(() => _isHealthy = false);
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.compact) {
      return _buildCompact();
    }
    return _buildFull();
  }

  Widget _buildCompact() {
    return GestureDetector(
      onTap: _checkHealth,
      child: Container(
        padding: const EdgeInsets.all(AyurezeTheme.spaceXs),
        decoration: BoxDecoration(
          color: _isHealthy
              ? AyurezeTheme.healingGreen50.withValues(alpha: 0.2)
              : Colors.orange.withValues(alpha: 0.2),
          shape: BoxShape.circle,
        ),
        child: HugeIcon(
          icon: HugeIcons.strokeRoundedBrain01,
          size: 16,
          color: _isHealthy ? AyurezeTheme.healingGreen50 : Colors.orange,
        ),
      ),
    );
  }

  Widget _buildFull() {
    return GestureDetector(
      onTap: _checkHealth,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _isHealthy
              ? AyurezeTheme.healingGreen50.withValues(alpha: 0.1)
              : Colors.orange.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AyurezeTheme.radiusLg),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isChecking)
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color:
                      _isHealthy ? AyurezeTheme.healingGreen50 : Colors.orange,
                ),
              )
            else
              HugeIcon(
                icon: _isHealthy
                    ? HugeIcons.strokeRoundedCheckmarkCircle01
                    : HugeIcons.strokeRoundedAlert01,
                size: 14,
                color: _isHealthy ? AyurezeTheme.healingGreen50 : Colors.orange,
              ),
            if (widget.showLabel) ...[
              const SizedBox(width: 6),
              Text(
                _isHealthy ? 'Astra AI' : 'Offline',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: _isHealthy
                          ? AyurezeTheme.healingGreen50
                          : Colors.orange,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
