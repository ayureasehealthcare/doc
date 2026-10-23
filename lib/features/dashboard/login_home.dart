import 'dart:ui' show ImageFilter;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:doctro/core/astra/widgets/astra_floating_button.dart';
import 'package:doctro/core/constants/app_string.dart';
import 'package:doctro/core/constants/prefConstatnt.dart';
import 'package:doctro/core/constants/preferences.dart';
import 'package:doctro/core/localization/localization_constant.dart';
import 'package:doctro/theme/ayureze_theme.dart';
import 'package:doctro/widgets/glass_surface.dart';
import 'package:doctro/widgets/modern_drawer.dart';
import 'package:doctro/widgets/osler_skeleton.dart';
import 'package:doctro/widgets/osler_state_view.dart';
import 'package:doctro/features/dashboard/patient_information.dart';
import 'package:doctro/features/dashboard/view_models/login_home_view_model.dart';
import 'package:doctro/theme/app_motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:provider/provider.dart';

class LoginHomeScreen extends StatelessWidget {
  final String? chat;

  const LoginHomeScreen({super.key, this.chat});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LoginHomeViewModel()..initializeData(context),
      child: const _LoginHomeView(),
    );
  }
}

class _LoginHomeView extends StatefulWidget {
  const _LoginHomeView();

  @override
  State<_LoginHomeView> createState() => _LoginHomeViewState();
}

class _LoginHomeViewState extends State<_LoginHomeView>
    with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );

    _animController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AyurezeTheme.canvas,
      drawer: const ModernDrawer(),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AyurezeTheme.healingGreenFill,
        tooltip: 'Ask Astra AI',
        onPressed: () => AstraFloatingButton.openAstraChat(),
        child: HugeIcon(
          icon: HugeIcons.strokeRoundedBrain01,
          color: Colors.white,
        ),
      ),
      body: Consumer<LoginHomeViewModel>(
        builder: (context, viewModel, _) {
          return RefreshIndicator(
            color: AyurezeTheme.healingGreen50,
            backgroundColor: AyurezeTheme.surface,
            onRefresh: () => viewModel.fetchAppointments(context),
            child: Stack(
              children: [
                // Soft gradient blobs for the glass panels below to refract.
                Positioned(
                  top: -60,
                  right: -70,
                  child:
                      GlassBlob(size: 220, color: AyurezeTheme.healingGreen50),
                ),
                Positioned(
                  top: 380,
                  left: -90,
                  child: GlassBlob(
                      size: 240, color: AyurezeTheme.sunshineYellow50),
                ),
                Positioned(
                  bottom: -80,
                  right: -60,
                  child: GlassBlob(
                      size: 220, color: AyurezeTheme.connectivityBlue50),
                ),
                SafeArea(
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      // App Bar / Header
                      SliverToBoxAdapter(
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: SlideTransition(
                            position: _slideAnimation,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                  AyurezeTheme.spaceXl,
                                  AyurezeTheme.spaceLg,
                                  AyurezeTheme.spaceXl,
                                  AyurezeTheme.spaceSm),
                              child: Row(
                                children: [
                                  GestureDetector(
                                    onTap: () =>
                                        _scaffoldKey.currentState?.openDrawer(),
                                    child: ClipOval(
                                      child: BackdropFilter(
                                        filter: ImageFilter.blur(
                                            sigmaX: 12, sigmaY: 12),
                                        child: Container(
                                          width: 48,
                                          height: 48,
                                          decoration: BoxDecoration(
                                            color: (AyurezeTheme.surface)
                                                .withValues(alpha: 0.5),
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.white
                                                  .withValues(alpha: 0.35),
                                            ),
                                          ),
                                          child: (viewModel.dFullImage !=
                                                      null &&
                                                  viewModel
                                                      .dFullImage!.isNotEmpty)
                                              ? ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                    AyurezeTheme.radiusXl,
                                                  ),
                                                  child: CachedNetworkImage(
                                                    imageUrl:
                                                        viewModel.dFullImage!,
                                                    fit: BoxFit.cover,
                                                    placeholder: (_, __) =>
                                                        HugeIcon(
                                                      icon: HugeIcons
                                                          .strokeRoundedUserCircle,
                                                      color: AyurezeTheme
                                                          .forestDeep,
                                                    ),
                                                    errorWidget: (_, __, ___) =>
                                                        HugeIcon(
                                                      icon: HugeIcons
                                                          .strokeRoundedUserCircle,
                                                      color: AyurezeTheme
                                                          .forestDeep,
                                                    ),
                                                  ),
                                                )
                                              : HugeIcon(
                                                  icon: HugeIcons
                                                      .strokeRoundedMenu01,
                                                  color:
                                                      AyurezeTheme.iconPrimary,
                                                ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          getTranslated(
                                            context,
                                            AppString.dashboard_welcome,
                                          ).toString(),
                                          style: textTheme.bodyMedium?.copyWith(
                                            color: AyurezeTheme.textSecondary,
                                          ),
                                        ),
                                        Text(
                                          "Dr. ${viewModel.dName ?? 'Doctor'}",
                                          style: textTheme.titleLarge?.copyWith(
                                            color: AyurezeTheme.textPrimary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  IconButton(
                                    onPressed: () {
                                      Navigator.pushNamed(
                                          context, 'notifications');
                                    },
                                    icon: ClipOval(
                                      child: BackdropFilter(
                                        filter: ImageFilter.blur(
                                            sigmaX: 12, sigmaY: 12),
                                        child: Container(
                                          padding: const EdgeInsets.all(
                                              AyurezeTheme.spaceMd),
                                          decoration: BoxDecoration(
                                            color: (AyurezeTheme.surface)
                                                .withValues(alpha: 0.5),
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.white
                                                  .withValues(alpha: 0.35),
                                            ),
                                          ),
                                          child: HugeIcon(
                                            icon: HugeIcons
                                                .strokeRoundedNotification02,
                                            color: AyurezeTheme.textPrimary,
                                            size: 22,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Hero Banner Card
                      SliverToBoxAdapter(
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: ScaleTransition(
                            scale: _scaleAnimation,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                  AyurezeTheme.spaceXl,
                                  AyurezeTheme.spaceMd,
                                  AyurezeTheme.spaceXl,
                                  AyurezeTheme.spaceLg),
                              child: Container(
                                width: double.infinity,
                                padding:
                                    const EdgeInsets.all(AyurezeTheme.spaceXl),
                                decoration: AyurezeTheme.heroDecoration(),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: AyurezeTheme.spaceSm,
                                            vertical: AyurezeTheme.spaceXs,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(
                                              alpha: 0.18,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              AyurezeTheme.radiusPill,
                                            ),
                                          ),
                                          child: Text(
                                            "Clinical Dashboard",
                                            style:
                                                textTheme.bodySmall?.copyWith(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                        const Spacer(),
                                        HugeIcon(
                                          icon: HugeIcons.strokeRoundedHealth,
                                          color: Colors.white.withValues(
                                            alpha: 0.9,
                                          ),
                                          size: 24,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 14),
                                    Text(
                                      getTranslated(
                                        context,
                                        AppString.today_appointment_heading,
                                      ).toString(),
                                      style: textTheme.headlineMedium?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      "Manage your consultations & patient health records seamlessly.",
                                      style: textTheme.bodyMedium?.copyWith(
                                        color: Colors.white
                                            .withValues(alpha: 0.85),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Quick Stats Row (Responsive)
                      SliverToBoxAdapter(
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: AyurezeTheme.spaceXl),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final isWide = constraints.maxWidth > 500;
                                // getString falls back to the literal 'N_A'
                                // sentinel when the key was never written (e.g.
                                // the settings fetch that populates it failed),
                                // which rendered as "N_A0" here. Fall back to
                                // nothing rather than propagate the sentinel.
                                final currencySymbol =
                                    SharedPreferenceHelper.getStringOrNull(
                                          Preferences.currency_symbol,
                                        ) ??
                                        '';

                                // A fixed tile height, not an aspect ratio: the card
                                // stacks an icon, a value and a label, so its content
                                // height is constant while a ratio-derived height
                                // shrank below that on narrow phones and in the
                                // 4-column branch, overflowing every card.
                                return GridView(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: isWide ? 4 : 2,
                                    mainAxisSpacing: 12,
                                    crossAxisSpacing: 12,
                                    mainAxisExtent: 120,
                                  ),
                                  children: [
                                    _buildStatCard(
                                      context,
                                      index: 0,
                                      title: getTranslated(
                                        context,
                                        AppString.information_amount,
                                      ).toString(),
                                      value:
                                          "$currencySymbol${viewModel.totalEarnings.toStringAsFixed(0)}",
                                      icon: HugeIcons.strokeRoundedWallet02,
                                      color: AyurezeTheme.healingGreen50,
                                    ),
                                    _buildStatCard(
                                      context,
                                      index: 1,
                                      title: "Patients",
                                      value: "${viewModel.patientCount}",
                                      icon: HugeIcons.strokeRoundedUserGroup,
                                      color: AyurezeTheme.connectivityBlue50,
                                    ),
                                    _buildStatCard(
                                      context,
                                      index: 2,
                                      title: "Today",
                                      value:
                                          "${viewModel.todayAppointments.length}",
                                      icon: HugeIcons.strokeRoundedCalendar01,
                                      color: AyurezeTheme.sunshineYellow50,
                                    ),
                                    _buildStatCard(
                                      context,
                                      index: 3,
                                      title: "Reviews",
                                      value: "${viewModel.reviewCount}",
                                      icon: HugeIcons.strokeRoundedStar,
                                      color: AyurezeTheme.caringViolet50,
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                      ),

                      // Search Bar
                      SliverToBoxAdapter(
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(
                                AyurezeTheme.spaceXl,
                                AyurezeTheme.spaceXl,
                                AyurezeTheme.spaceXl,
                                AyurezeTheme.spaceLg),
                            child: GlassSurface(
                              radius: AyurezeTheme.radiusXl,
                              child: TextField(
                                controller: _searchController,
                                onChanged: (text) =>
                                    viewModel.onSearchTextChanged(text),
                                style: textTheme.bodyLarge?.copyWith(
                                  color: AyurezeTheme.textPrimary,
                                ),
                                decoration: InputDecoration(
                                  hintText: "Search patient by name...",
                                  hintStyle: textTheme.bodyMedium?.copyWith(
                                    color: AyurezeTheme.textSecondary,
                                  ),
                                  prefixIcon: HugeIcon(
                                    icon: HugeIcons.strokeRoundedSearch01,
                                    color: AyurezeTheme.iconPrimary,
                                  ),
                                  suffixIcon: _searchController.text.isNotEmpty
                                      ? IconButton(
                                          icon: HugeIcon(
                                            icon:
                                                HugeIcons.strokeRoundedCancel01,
                                            color: AyurezeTheme.textSecondary,
                                          ),
                                          onPressed: () {
                                            _searchController.clear();
                                            viewModel.onSearchTextChanged('');
                                            setState(() {});
                                          },
                                        )
                                      : null,
                                  filled: false,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Custom Segmented Tab Bar
                      SliverToBoxAdapter(
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: AyurezeTheme.spaceXl),
                            child: GlassSurface(
                              radius: 18,
                              padding:
                                  const EdgeInsets.all(AyurezeTheme.spaceXs),
                              child: Row(
                                children: [
                                  _buildTabItem(
                                    context,
                                    index: 0,
                                    label:
                                        "Today (${_getTabListCount(viewModel, 0)})",
                                  ),
                                  _buildTabItem(
                                    context,
                                    index: 1,
                                    label:
                                        "Tomorrow (${_getTabListCount(viewModel, 1)})",
                                  ),
                                  _buildTabItem(
                                    context,
                                    index: 2,
                                    label:
                                        "Upcoming (${_getTabListCount(viewModel, 2)})",
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SliverToBoxAdapter(child: SizedBox(height: 16)),

                      // Appointments List Section
                      if (viewModel.isLoading)
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AyurezeTheme.spaceXl),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) => const OslerCardSkeleton(),
                              childCount: 4,
                            ),
                          ),
                        )
                      else
                        _buildAppointmentSliverList(context, viewModel),

                      const SliverToBoxAdapter(child: SizedBox(height: 32)),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required int index,
    required String title,
    required String value,
    required List<List<dynamic>> icon,
    required Color color,
  }) {
    final textTheme = Theme.of(context).textTheme;

    final card = GlassSurface(
      padding: const EdgeInsets.all(AyurezeTheme.spaceLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AyurezeTheme.spaceSm),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AyurezeTheme.radiusMd),
                ),
                child: HugeIcon(icon: icon, size: 18, color: color),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: textTheme.titleLarge?.copyWith(
              color: AyurezeTheme.textPrimary,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            title,
            style: textTheme.bodySmall?.copyWith(
              color: AyurezeTheme.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );

    return ScreenEntrance(index: index, child: card);
  }

  Widget _buildTabItem(
    BuildContext context, {
    required int index,
    required String label,
  }) {
    final isSelected = _selectedTabIndex == index;
    final textTheme = Theme.of(context).textTheme;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTabIndex = index;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: AyurezeTheme.spaceMd),
          decoration: BoxDecoration(
            color: isSelected ? AyurezeTheme.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(AyurezeTheme.radiusLg),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AyurezeTheme.shadow,
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(
              color: isSelected
                  ? AyurezeTheme.textPrimary
                  : AyurezeTheme.textSecondary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  int _getTabListCount(LoginHomeViewModel vm, int tabIndex) {
    final isSearching = _searchController.text.isNotEmpty;
    if (tabIndex == 0) {
      return isSearching ? vm.searchResult.length : vm.todayAppointments.length;
    } else if (tabIndex == 1) {
      return isSearching
          ? vm.tomorrowSearchResult.length
          : vm.tomorrowAppointments.length;
    } else {
      return isSearching
          ? vm.upcomingSearchResult.length
          : vm.upcomingAppointments.length;
    }
  }

  Widget _buildAppointmentSliverList(
    BuildContext context,
    LoginHomeViewModel vm,
  ) {
    final isSearching = _searchController.text.isNotEmpty;
    dynamic items;

    if (_selectedTabIndex == 0) {
      items = isSearching ? vm.searchResult : vm.todayAppointments;
    } else if (_selectedTabIndex == 1) {
      items = isSearching ? vm.tomorrowSearchResult : vm.tomorrowAppointments;
    } else {
      items = isSearching ? vm.upcomingSearchResult : vm.upcomingAppointments;
    }

    if (items == null || items.isEmpty) {
      final showError = vm.hasError && !isSearching;
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AyurezeTheme.spaceXl,
              vertical: AyurezeTheme.space3xl),
          child: GlassSurface(
            padding: const EdgeInsets.all(AyurezeTheme.space2xl),
            child: OslerStateView(
              icon: showError
                  ? HugeIcons.strokeRoundedCloudOff
                  : HugeIcons.strokeRoundedCalendarCheck01,
              tone: showError ? OslerStateTone.error : OslerStateTone.neutral,
              title: showError
                  ? "Couldn't Load Appointments"
                  : "No Appointments Found",
              message: showError
                  ? vm.errorMessage
                  : isSearching
                      ? "No patient matching '${_searchController.text}'"
                      : "There are no appointments scheduled for this section.",
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AyurezeTheme.spaceXl),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final item = items[index];
          // Cap the stagger so a long list doesn't push later cards'
          // entrance animation minutes into the future.
          return _buildAppointmentCard(context, item, index % 8);
        }, childCount: items.length),
      ),
    );
  }

  Widget _buildAppointmentCard(BuildContext context, dynamic item, int index) {
    final textTheme = Theme.of(context).textTheme;
    final String? imageUrl = item.user?.fullImage;
    final String patientName = item.patientName ?? "Patient";
    final String appointmentTime = item.time ?? "--:--";
    final String appointmentDate = item.date ?? "";
    final String address = item.patientAddress ?? "In-Clinic Consultation";

    final card = Padding(
      padding: const EdgeInsets.only(bottom: AyurezeTheme.spaceMd),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => patientDetailsScreen(id: item.id),
              ),
            );
          },
          borderRadius: BorderRadius.circular(AyurezeTheme.radiusXl),
          child: Container(
            padding: const EdgeInsets.all(AyurezeTheme.spaceLg),
            decoration: AyurezeTheme.panelDecoration(),
            child: Row(
              children: [
                // Patient Image
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AyurezeTheme.healingGreen50,
                      width: 1.5,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AyurezeTheme.radius2xl),
                    child: (imageUrl != null && imageUrl.isNotEmpty)
                        ? CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AyurezeTheme.healingGreen50,
                                ),
                              ),
                            ),
                            errorWidget: (_, __, ___) => Image.asset(
                              "assets/images/no_image.jpg",
                              fit: BoxFit.cover,
                            ),
                          )
                        : Image.asset(
                            "assets/images/no_image.jpg",
                            fit: BoxFit.cover,
                          ),
                  ),
                ),
                const SizedBox(width: 14),
                // Patient Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patientName,
                        style: textTheme.titleMedium?.copyWith(
                          color: AyurezeTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          HugeIcon(
                            icon: HugeIcons.strokeRoundedTime01,
                            size: 14,
                            color: AyurezeTheme.forestDeep,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            appointmentTime,
                            style: textTheme.bodyMedium?.copyWith(
                              color: AyurezeTheme.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (appointmentDate.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Text(
                              "• $appointmentDate",
                              style: textTheme.bodyMedium?.copyWith(
                                color: AyurezeTheme.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        address,
                        style: textTheme.bodySmall?.copyWith(
                          color: AyurezeTheme.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Action Arrow
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AyurezeTheme.surfaceMuted,
                    shape: BoxShape.circle,
                    border: Border.all(color: AyurezeTheme.border),
                  ),
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedArrowRight01,
                    color: AyurezeTheme.iconPrimary,
                    size: 22,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return ScreenEntrance(index: index, child: card);
  }
}
