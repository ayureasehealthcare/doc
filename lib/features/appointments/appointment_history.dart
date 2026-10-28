import 'package:doctro/core/constants/app_icons.dart';
import 'package:doctro/core/constants/app_string.dart';
import 'package:doctro/core/localization/localization_constant.dart';
import 'package:doctro/theme/ayureze_theme.dart';
import 'package:doctro/widgets/modern_drawer.dart';
import 'package:doctro/widgets/osler_skeleton.dart';
import 'package:doctro/features/appointments/view_models/appointment_history_view_model.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';

class AppointmentHistory extends StatelessWidget {
  const AppointmentHistory({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppointmentHistoryViewModel()..fetchAppointments(context),
      child: const _AppointmentHistoryView(),
    );
  }
}

class _AppointmentHistoryView extends StatefulWidget {
  const _AppointmentHistoryView();

  @override
  State<_AppointmentHistoryView> createState() =>
      _AppointmentHistoryViewState();
}

class _AppointmentHistoryViewState extends State<_AppointmentHistoryView>
    with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late AnimationController _headerAnimController;
  late Animation<double> _headerFade;
  late Animation<Offset> _headerSlide;

  @override
  void initState() {
    super.initState();
    _headerAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _headerFade =
        CurvedAnimation(parent: _headerAnimController, curve: Curves.easeOut);
    _headerSlide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _headerAnimController, curve: Curves.easeOutCubic));
    _headerAnimController.forward();
  }

  @override
  void dispose() {
    _headerAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: const ModernDrawer(),
      backgroundColor: AyurezeTheme.canvas,
      appBar: AppBar(
        backgroundColor: AyurezeTheme.canvas,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: HugeIcon(
              icon: HugeIcons.strokeRoundedArrowLeft01,
              color: AyurezeTheme.textPrimary,
              size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          getTranslated(context, AppString.appointment_history_heading)
              .toString(),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        actions: [
          IconButton(
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            icon: HugeIcon(
                icon: HugeIcons.strokeRoundedMenu01,
                color: AyurezeTheme.iconPrimary,
                size: 22),
          ),
        ],
      ),
      body: Consumer<AppointmentHistoryViewModel>(
        builder: (context, viewModel, _) {
          return RefreshIndicator(
            color: AyurezeTheme.iconPrimary,
            onRefresh: () => viewModel.fetchAppointments(context),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: FadeTransition(
                    opacity: _headerFade,
                    child: SlideTransition(
                      position: _headerSlide,
                      child: Padding(
                        padding: AyurezeTheme.screenPadding,
                        child: Column(
                          children: [
                            _buildHeroCard(context),
                            const SizedBox(height: 18),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                if (viewModel.isLoading)
                  SliverPadding(
                    padding: AyurezeTheme.screenPadding,
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) => Padding(
                          padding: const EdgeInsets.only(
                              bottom: AyurezeTheme.spaceMd),
                          child: OslerSkeleton(
                              width: double.infinity,
                              height: 100,
                              borderRadius: 20),
                        ),
                        childCount: 5,
                      ),
                    ),
                  )
                else if (viewModel.appointments.isEmpty)
                  SliverFillRemaining(
                    child: _buildEmptyState(context),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(AyurezeTheme.spaceXl, 0,
                        AyurezeTheme.spaceXl, AyurezeTheme.space2xl),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) => _AppointmentCard(
                          appointment: viewModel.appointments[i],
                          index: i,
                        ),
                        childCount: viewModel.appointments.length,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AyurezeTheme.space2xl),
      decoration: AyurezeTheme.heroDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AyurezeTheme.spaceMd,
                vertical: AyurezeTheme.spaceSm),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AyurezeTheme.radiusPill),
            ),
            child: Text(
              "Patient Visits",
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                  ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            getTranslated(context, AppString.appointment_history_heading)
                .toString(),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            "Track all your scheduled and completed appointments at a glance.",
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.78),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              // Dark-aware surface, and a matching icon weight: the previous
              // pale-mint circle with a healingGreen50 icon was 2.36:1.
              color: AyurezeTheme.surfaceMuted,
              shape: BoxShape.circle,
            ),
            child: HugeIcon(
              icon: HugeIcons.strokeRoundedCalendar01,
              size: 36,
              color: AyurezeTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "No Appointments Yet",
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            "Your appointment history will appear here\nonce patients start booking.",
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _AppointmentCard extends StatefulWidget {
  final dynamic appointment;
  final int index;

  const _AppointmentCard({required this.appointment, required this.index});

  @override
  State<_AppointmentCard> createState() => _AppointmentCardState();
}

class _AppointmentCardState extends State<_AppointmentCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _animController, curve: Curves.easeOutCubic));

    Future.delayed(Duration(milliseconds: widget.index * 60), () {
      if (mounted) _animController.forward();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appt = widget.appointment;
    Color statusColor = AyurezeTheme.healingGreen50;
    Color statusBg = AyurezeTheme.healingGreen10;

    final status = (appt.status ?? '').toString().toLowerCase();
    if (status == 'pending') {
      statusColor = AyurezeTheme.sunshineYellow50;
      statusBg = AyurezeTheme.sunshineYellow10;
    } else if (status == 'cancelled') {
      statusColor = AyurezeTheme.remoteRed50;
      statusBg = AyurezeTheme.remoteRed10;
    }

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: GestureDetector(
          onTap: () {
            // TODO: Navigate to appointment detail
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            margin: const EdgeInsets.only(bottom: AyurezeTheme.spaceMd),
            padding: const EdgeInsets.all(AyurezeTheme.spaceLg),
            decoration: AyurezeTheme.panelDecoration(),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AyurezeTheme.radiusLg),
                  child: Image.network(
                    appt.user?.fullImage ?? '',
                    width: 58,
                    height: 58,
                    fit: BoxFit.cover,
                    errorBuilder: (context, _, __) => Container(
                      width: 58,
                      height: 58,
                      color: AyurezeTheme.surfaceMuted,
                      child: HugeIcon(
                          icon: AppIcons.profile,
                          color: AyurezeTheme.textSecondary),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              appt.user?.name ?? 'Patient',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(fontWeight: FontWeight.w700),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: AyurezeTheme.spaceSm, vertical: 3),
                            decoration: BoxDecoration(
                              color: statusBg,
                              borderRadius: BorderRadius.circular(
                                  AyurezeTheme.radiusPill),
                            ),
                            child: Text(
                              appt.status ?? 'Pending',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: statusColor,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          HugeIcon(
                              icon: HugeIcons.strokeRoundedClock01,
                              size: 14,
                              color: AyurezeTheme.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            '${appt.appointmentDate ?? ''} • ${appt.slotTime ?? ''}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                      if (appt.appointmentType != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            HugeIcon(
                                icon: HugeIcons.strokeRoundedStethoscope,
                                size: 14,
                                color: AyurezeTheme.textSecondary),
                            const SizedBox(width: 4),
                            Text(
                              appt.appointmentType.toString(),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                HugeIcon(
                  icon: HugeIcons.strokeRoundedArrowRight01,
                  size: 14,
                  color: AyurezeTheme.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
