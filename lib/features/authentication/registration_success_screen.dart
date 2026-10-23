import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:doctro/features/dashboard/login_home.dart';
import 'package:doctro/theme/ayureze_theme.dart';
import 'package:doctro/widgets/osler_button.dart';

class RegistrationSuccessScreen extends StatefulWidget {
  final String doctorName;
  final String doctorId;
  final String email;
  final String? subtitle;
  final VoidCallback? onContinue;

  const RegistrationSuccessScreen({
    super.key,
    required this.doctorName,
    required this.doctorId,
    required this.email,
    this.subtitle,
    this.onContinue,
  });

  @override
  _RegistrationSuccessScreenState createState() =>
      _RegistrationSuccessScreenState();
}

class _RegistrationSuccessScreenState extends State<RegistrationSuccessScreen>
    with TickerProviderStateMixin {
  late AnimationController _iconController;
  late AnimationController _contentController;

  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Icon animation: Quick scale up with bounce effect
    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _iconController, curve: Curves.bounceOut),
    );

    // Content animations: Cascading fade and slide up
    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _contentController, curve: Curves.easeIn),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0.0, 0.15), end: Offset.zero).animate(
      CurvedAnimation(parent: _contentController, curve: Curves.easeOutCubic),
    );

    // Run animations sequentially
    _iconController.forward().then((_) {
      _contentController.forward();
    });
  }

  @override
  void dispose() {
    _iconController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AyurezeTheme.canvas,
      body: SafeArea(
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: AyurezeTheme.space3xl),
          child: Column(
            children: [
              const Spacer(flex: 2),
              ScaleTransition(
                scale: _scaleAnimation,
                child: _buildSuccessIcon(),
              ),
              const SizedBox(height: 40),
              FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    children: [
                      Text(
                        "Welcome, Dr. ${widget.doctorName}!",
                        style: AyurezeTheme.font(AyurezeTheme.text3xl,
                            FontWeight.w800, AyurezeTheme.textPrimary,
                            letterSpacing: -1),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.subtitle ??
                            "Your professional account has been successfully created and secured.",
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: AyurezeTheme.textSecondary,
                                  height: 1.5,
                                  fontWeight: FontWeight.normal,
                                ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),
                      _buildDetailCard(),
                    ],
                  ),
                ),
              ),
              const Spacer(flex: 3),
              FadeTransition(
                opacity: _fadeAnimation,
                child: _buildContinueButton(context),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessIcon() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: AyurezeTheme.healingGreen50.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: AyurezeTheme.healingGreenFill,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AyurezeTheme.healingGreen50.withValues(alpha: 0.3),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const HugeIcon(
            icon: HugeIcons.strokeRoundedTick01,
            color: Colors.white,
            size: 40,
          ),
        ),
      ),
    );
  }

  Widget _buildDetailCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AyurezeTheme.space2xl),
      decoration: BoxDecoration(
        color: AyurezeTheme.surface,
        borderRadius: BorderRadius.circular(AyurezeTheme.radiusXl),
        border: Border.all(color: AyurezeTheme.border),
      ),
      child: Column(
        children: [
          _buildDetailRow("YOUR DOCTOR ID", widget.doctorId, isPrimary: true),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AyurezeTheme.spaceLg),
            child: Divider(height: 1),
          ),
          _buildDetailRow("FULL NAME", widget.doctorName),
          const SizedBox(height: 12),
          _buildDetailRow("EMAIL ADDRESS", widget.email),
          const SizedBox(height: 12),
          _buildDetailRow("STATUS", "Verification Pending", isStatus: true),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value,
      {bool isPrimary = false, bool isStatus = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: AyurezeTheme.textSecondary,
                letterSpacing: 0.5,
              ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Text(
            value,
            style: AyurezeTheme.font(
              isPrimary ? AyurezeTheme.textXl : AyurezeTheme.textMd,
              isPrimary || isStatus ? FontWeight.w800 : FontWeight.w500,
              isStatus
                  ? AyurezeTheme.warning
                  : (isPrimary
                      ? AyurezeTheme.iconPrimary
                      : AyurezeTheme.textPrimary),
            ),
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildContinueButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: OslerButton(
        text: "Continue",
        customColor: AyurezeTheme.healingGreen100,
        onPressed: widget.onContinue ??
            () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => LoginHomeScreen()),
                (route) => false,
              );
            },
      ),
    );
  }
}
