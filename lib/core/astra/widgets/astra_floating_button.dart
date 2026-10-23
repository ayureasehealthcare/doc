import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:doctro/core/astra/context/context_builder.dart';
import 'package:doctro/core/astra/context/patient_context.dart';
import 'package:doctro/core/astra/navigation/app_router.dart';
import 'package:doctro/theme/ayureze_theme.dart';

/// Floating Astra AI Button
///
/// A floating action button that provides quick access to Astra AI
/// from any screen in the app. Automatically includes current context.
class AstraFloatingButton extends StatelessWidget {
  /// Custom position override (uses default bottom-right if null)
  final Offset? position;

  /// Whether to show a pulse animation
  final bool showPulse;

  /// Custom size
  final double size;

  const AstraFloatingButton({
    super.key,
    this.position,
    this.showPulse = true,
    this.size = 56,
  });

  /// Show the Astra chat with current context
  static void openAstraChat({
    String? patientId,
    String? patientName,
    String? appointmentId,
  }) {
    // Set context before opening
    if (patientId != null) {
      // Patient context should already be set via PatientContextProvider
      // Just update screen context
      astraContext.setScreenContext('patient_details');
    }

    // Navigate to Astra chat
    AppRouter.instance.openChat(
      patientId: patientId,
      patientName: patientName,
      appointmentId: appointmentId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Pulse animation
        if (showPulse) _buildPulseAnimation(),

        // Main button
        Positioned(
          right: position?.dx ?? 16,
          bottom: position?.dy ?? 100,
          child: _buildButton(context),
        ),
      ],
    );
  }

  Widget _buildPulseAnimation() {
    return Positioned(
      right: position?.dx ?? 16,
      bottom: position?.dy ?? 100,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 1.0, end: 1.5),
        duration: const Duration(milliseconds: 1500),
        builder: (context, value, child) {
          return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AyurezeTheme.healingGreen50.withValues(
                alpha: 0.3 * (1.5 - value) / 0.5,
              ),
            ),
          );
        },
        onEnd: () {},
      ),
    );
  }

  Widget _buildButton(BuildContext context) {
    return Semantics(
      label: 'Open Astra AI Assistant',
      hint: 'Double tap to chat with Astra AI',
      button: true,
      child: Material(
        elevation: 4,
        shape: const CircleBorder(),
        color: AyurezeTheme.healingGreenFill,
        child: InkWell(
          onTap: () => _onTap(context),
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: size,
            height: size,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                HugeIcon(
                  icon: HugeIcons.strokeRoundedBrain01,
                  color: Colors.white,
                  size: size * 0.45,
                ),
                SizedBox(height: size * 0.05),
                Text(
                  'AI',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: size * 0.18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onTap(BuildContext context) {
    // Get current context
    final patient = PatientContextProvider.current;
    final consultation = astraContext.currentConsultation;

    // Open Astra chat with current context
    openAstraChat(
      patientId: patient?.id,
      patientName: patient?.name,
      appointmentId: consultation?.id,
    );
  }
}

/// Astra Floating Button Overlay
///
/// Wraps any screen with the floating Astra button.
/// Use this on screens where the button should appear.
class AstraFloatingButtonOverlay extends StatelessWidget {
  /// The screen content
  final Widget child;

  /// Whether to show the floating button
  final bool showButton;

  /// Screen context for Astra
  final String screenContext;

  /// Current patient (if any)
  final dynamic patient;

  const AstraFloatingButtonOverlay({
    super.key,
    required this.child,
    this.showButton = true,
    required this.screenContext,
    this.patient,
  });

  @override
  Widget build(BuildContext context) {
    // Set screen context on build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      astraContext.setScreenContext(screenContext);
      if (patient != null) {
        PatientContextProvider.setFromPatient(patient);
      }
    });

    return Stack(
      children: [
        child,
        if (showButton)
          AstraFloatingButton(
            position: const Offset(16, 100),
          ),
      ],
    );
  }
}

/// Mini Astra button for inline use
class AstraMiniButton extends StatelessWidget {
  /// Label text
  final String label;

  /// On tap callback
  final VoidCallback? onTap;

  /// Icon (optional)
  final List<List<dynamic>>? icon;

  const AstraMiniButton({
    super.key,
    this.label = 'Ask AI',
    this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Ask Astra AI',
      hint: 'Double tap to chat with Astra AI',
      button: true,
      child: Material(
        color: AyurezeTheme.healingGreen50.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AyurezeTheme.radiusXl),
        child: InkWell(
          onTap: onTap ?? () => AstraFloatingButton.openAstraChat(),
          borderRadius: BorderRadius.circular(AyurezeTheme.radiusXl),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AyurezeTheme.spaceMd,
                vertical: AyurezeTheme.spaceSm),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                HugeIcon(
                  icon: icon ?? HugeIcons.strokeRoundedBrain01,
                  size: 16,
                  color: AyurezeTheme.healingGreen50,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: AyurezeTheme.healingGreen50,
                    fontWeight: FontWeight.w500,
                    fontSize: AyurezeTheme.textMd,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
