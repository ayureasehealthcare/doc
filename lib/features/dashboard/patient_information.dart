import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctro/core/constants/app_icons.dart';
import 'package:doctro/core/constants/app_string.dart';
import 'package:doctro/core/constants/prefConstatnt.dart';
import 'package:doctro/core/constants/preferences.dart';
import 'package:doctro/core/localization/localization_constant.dart';

import 'package:doctro/theme/ayureze_theme.dart';
import 'package:doctro/widgets/astra_case_progress_card.dart';
import 'package:doctro/widgets/astra_fill_display.dart';
import 'package:doctro/widgets/glass_surface.dart';
import 'package:doctro/widgets/osler_button.dart';
import 'package:doctro/widgets/osler_loader.dart';
import 'package:doctro/widgets/osler_toast.dart';
import 'package:doctro/widgets/patient_wellness_section.dart';
import 'package:doctro/widgets/sharing_consent_guard.dart';

import 'package:doctro/features/prescription/astra/prescription_screen.dart';
import 'package:doctro/features/consultation/chat/constants/firestore_constants.dart';
import 'package:doctro/features/consultation/chat/models/user_chat.dart';
import 'package:doctro/features/consultation/chat/pages/chat_page.dart';
import 'package:doctro/features/consultation/chat/providers/home_provider.dart';
import 'package:doctro/features/consultation/videoCall/video_Call.dart';
import 'package:doctro/features/dashboard/view_models/patient_information_view_model.dart';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:full_screen_image_null_safe/full_screen_image_null_safe.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class patientDetailsScreen extends StatelessWidget {
  final int? id;

  const patientDetailsScreen({super.key, this.id});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PatientInformationViewModel(id, context),
      child: const _PatientDetailsScreenBody(),
    );
  }
}

class _PatientDetailsScreenBody extends StatefulWidget {
  const _PatientDetailsScreenBody();

  @override
  _PatientDetailsScreenBodyState createState() =>
      _PatientDetailsScreenBodyState();
}

class _PatientDetailsScreenBodyState extends State<_PatientDetailsScreenBody>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late HomeProvider homeProvider;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));

    _animController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    homeProvider = Provider.of<HomeProvider>(context, listen: false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: AyurezeTheme.canvas,
      appBar: AppBar(
        backgroundColor: AyurezeTheme.canvas,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: HugeIcon(
            icon: HugeIcons.strokeRoundedArrowLeft01,
            color: AyurezeTheme.iconPrimary,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          getTranslated(context, AppString.patient_information).toString(),
          style: textTheme.titleLarge?.copyWith(
            color: AyurezeTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: Consumer<PatientInformationViewModel>(
        builder: (context, vm, child) {
          if (vm.isLoading) {
            return const Center(child: OslerLoader());
          }

          final name = vm.name;
          final age = vm.age;
          final amount = vm.amount;
          final date = vm.date;
          final phoneNo = vm.phoneNo;
          final patientAddress = vm.patientAddress;
          final illness = vm.illness;
          final note = vm.note;
          final appointmentId = vm.appointmentId;
          final drugEffect = vm.drugEffect;
          final time = vm.time;
          final fullImage = vm.fullImage;
          final appointment = vm.appointment;
          final appointmentType = vm.appointmentType;
          final appointmentStatus = vm.appointmentStatus;
          final userId = vm.userId;
          final reportImages = vm.reportImages;
          final isInsured = vm.isInsured;
          final policyInsurerName = vm.policyInsurerName;
          final policyNumber = vm.policyNumber;
          final hideButton = vm.hideButton;
          final astraFillData = vm.astraFillData;
          final astraCaseId = vm.astraCaseId;

          final content = FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: Column(
                children: [
                  Expanded(
                    child: NestedScrollView(
                      headerSliverBuilder: (context, innerBoxIsScrolled) {
                        return [
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AyurezeTheme.spaceXl,
                                vertical: AyurezeTheme.spaceMd,
                              ),
                              child: Column(
                                children: [
                                  // Profile Card
                                  GlassSurface(
                                    padding: const EdgeInsets.all(
                                        AyurezeTheme.spaceXl),
                                    child: Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            // Call dialler button
                                            IconButton(
                                              onPressed: () => _showCallOptions(
                                                  context,
                                                  phoneNo,
                                                  appointmentType,
                                                  userId),
                                              icon: Container(
                                                padding: const EdgeInsets.all(
                                                    AyurezeTheme.spaceMd),
                                                decoration: BoxDecoration(
                                                  color:
                                                      AyurezeTheme.surfaceMuted,
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: AyurezeTheme.border,
                                                  ),
                                                ),
                                                child: SvgPicture.asset(
                                                  'assets/icons/call_dialler.svg',
                                                  width: 20,
                                                  height: 20,
                                                  colorFilter: ColorFilter.mode(
                                                    AyurezeTheme.iconPrimary,
                                                    BlendMode.srcIn,
                                                  ),
                                                ),
                                              ),
                                            ),

                                            // Patient Avatar
                                            Container(
                                              width: 100,
                                              height: 100,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: AyurezeTheme
                                                      .healingGreen50,
                                                  width: 3,
                                                ),
                                              ),
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        AyurezeTheme
                                                            .radiusPill),
                                                child: (fullImage != null &&
                                                        fullImage.isNotEmpty)
                                                    ? CachedNetworkImage(
                                                        imageUrl: fullImage,
                                                        fit: BoxFit.cover,
                                                        placeholder: (_, __) =>
                                                            Center(
                                                          child:
                                                              CircularProgressIndicator(
                                                            color: AyurezeTheme
                                                                .healingGreen50,
                                                          ),
                                                        ),
                                                        errorWidget:
                                                            (_, __, ___) =>
                                                                Image.asset(
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

                                            // Message dialler button
                                            IconButton(
                                              onPressed: () =>
                                                  _openChat(context, userId),
                                              icon: Container(
                                                padding: const EdgeInsets.all(
                                                    AyurezeTheme.spaceMd),
                                                decoration: BoxDecoration(
                                                  color:
                                                      AyurezeTheme.surfaceMuted,
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: AyurezeTheme.border,
                                                  ),
                                                ),
                                                child: SvgPicture.asset(
                                                  'assets/icons/message_dialler.svg',
                                                  width: 20,
                                                  height: 20,
                                                  colorFilter: ColorFilter.mode(
                                                    AyurezeTheme.iconPrimary,
                                                    BlendMode.srcIn,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),

                                        // Patient Name
                                        Text(
                                          name ?? '',
                                          style: textTheme.titleLarge?.copyWith(
                                            color: AyurezeTheme.textPrimary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 4),

                                        // Booking ID
                                        Text(
                                          "${getTranslated(context, AppString.information_booking_id)}: ${appointmentId ?? ''}",
                                          style: textTheme.bodyMedium?.copyWith(
                                            color: AyurezeTheme.textSecondary,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 14),

                                  // Appointment Overview Stats Panel
                                  GlassSurface(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: AyurezeTheme.spaceLg,
                                      horizontal: AyurezeTheme.spaceMd,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceAround,
                                      children: [
                                        _buildInfoColumn(
                                          context,
                                          label: getTranslated(
                                            context,
                                            AppString.information_amount,
                                          ).toString(),
                                          value:
                                              "${SharedPreferenceHelper.getString(Preferences.currency_symbol)}${amount ?? 0}",
                                        ),
                                        Container(
                                          width: 1,
                                          height: 36,
                                          color: AyurezeTheme.border,
                                        ),
                                        _buildInfoColumn(
                                          context,
                                          label: getTranslated(
                                            context,
                                            AppString.information_date,
                                          ).toString(),
                                          value: date,
                                        ),
                                        Container(
                                          width: 1,
                                          height: 36,
                                          color: AyurezeTheme.border,
                                        ),
                                        _buildInfoColumn(
                                          context,
                                          label: getTranslated(
                                            context,
                                            AppString.information_appointment,
                                          ).toString(),
                                          value:
                                              "${appointmentType ?? '-'} ${appointmentType != null ? 'appointment' : ''}\n${appointment ?? ''}",
                                        ),
                                      ],
                                    ),
                                  ),

                                  if (astraCaseId != null &&
                                      astraCaseId.isNotEmpty)
                                    AstraCaseProgressCard(caseId: astraCaseId),

                                  // Firestore stream for Chat User details
                                  // (resolved lazily on chat-button tap to
                                  // avoid mutating state during build)
                                ],
                              ),
                            ),
                          ),
                        ];
                      },
                      body: Column(
                        children: [
                          // Tab Bar
                          Container(
                            margin: const EdgeInsets.symmetric(
                                horizontal: AyurezeTheme.spaceXl),
                            decoration: BoxDecoration(
                              color: AyurezeTheme.surfaceMuted,
                              borderRadius:
                                  BorderRadius.circular(AyurezeTheme.radiusLg),
                              border: Border.all(color: AyurezeTheme.border),
                            ),
                            child: TabBar(
                              controller: _tabController,
                              indicator: BoxDecoration(
                                color: AyurezeTheme.surface,
                                borderRadius: BorderRadius.circular(
                                    AyurezeTheme.radiusLg),
                                boxShadow: [
                                  BoxShadow(
                                    color: AyurezeTheme.shadow,
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              labelColor: AyurezeTheme.textPrimary,
                              unselectedLabelColor: AyurezeTheme.textSecondary,
                              labelStyle: AyurezeTheme.font(AyurezeTheme.textMd,
                                  FontWeight.w700, AyurezeTheme.textPrimary),
                              unselectedLabelStyle: AyurezeTheme.font(
                                  AyurezeTheme.textMd,
                                  FontWeight.w500,
                                  AyurezeTheme.textSecondary),
                              tabs: [
                                Tab(
                                  text: getTranslated(
                                    context,
                                    AppString.patient_information,
                                  ).toString(),
                                ),
                                Tab(
                                  text: getTranslated(
                                    context,
                                    AppString.patient_illness,
                                  ).toString(),
                                ),
                                Tab(
                                  text: getTranslated(
                                    context,
                                    AppString.doctor_prescription,
                                  ).toString(),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Tab Content
                          Expanded(
                            child: TabBarView(
                              controller: _tabController,
                              children: [
                                // Tab 1: Patient Information
                                SingleChildScrollView(
                                  padding: const EdgeInsets.all(
                                      AyurezeTheme.spaceXl),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Status Buttons / Status Bar
                                      if (!hideButton)
                                        GlassSurface(
                                          padding: const EdgeInsets.all(
                                              AyurezeTheme.spaceLg),
                                          margin: const EdgeInsets.only(
                                              bottom: AyurezeTheme.spaceLg),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    getTranslated(
                                                      context,
                                                      AppString
                                                          .information_appointment_status,
                                                    ).toString(),
                                                    style: textTheme.titleMedium
                                                        ?.copyWith(
                                                      color: AyurezeTheme
                                                          .textPrimary,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    appointmentStatus
                                                            ?.toUpperCase() ??
                                                        "",
                                                    style: textTheme.bodyMedium
                                                        ?.copyWith(
                                                      color: AyurezeTheme
                                                          .healingGreen50,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              if (appointmentStatus ==
                                                  'approve')
                                                OslerButton(
                                                  text: getTranslated(
                                                    context,
                                                    AppString
                                                        .information_complete_status,
                                                  ).toString(),
                                                  onPressed: () {
                                                    vm.statusChangeRequest(
                                                      "complete",
                                                    );
                                                  },
                                                ),
                                            ],
                                          ),
                                        )
                                      else
                                        Container(
                                          margin: const EdgeInsets.only(
                                              bottom: AyurezeTheme.spaceLg),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: OslerButton(
                                                  text: getTranslated(
                                                    context,
                                                    AppString
                                                        .information_approve_status,
                                                  ).toString(),
                                                  onPressed: () {
                                                    vm.statusChangeRequest(
                                                      "approve",
                                                    );
                                                  },
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: OslerButton(
                                                  text: getTranslated(
                                                    context,
                                                    AppString
                                                        .information_cancel_status,
                                                  ).toString(),
                                                  customColor: AyurezeTheme
                                                      .remoteRedFill,
                                                  onPressed: () {
                                                    vm.statusChangeRequest(
                                                      "cancel",
                                                    );
                                                  },
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                      // Details List Cards
                                      _buildDetailTile(
                                        context,
                                        label: getTranslated(
                                          context,
                                          AppString.information_patient_name,
                                        ).toString(),
                                        value: name ?? "-",
                                        icon:
                                            HugeIcons.strokeRoundedUserCircle02,
                                      ),
                                      _buildDetailTile(
                                        context,
                                        label: getTranslated(
                                          context,
                                          AppString.information_patient_age,
                                        ).toString(),
                                        value: age != null ? "$age yrs" : "-",
                                        icon:
                                            HugeIcons.strokeRoundedBirthdayCake,
                                      ),
                                      _buildDetailTile(
                                        context,
                                        label: getTranslated(
                                          context,
                                          AppString
                                              .information_patient_phone_number,
                                        ).toString(),
                                        value: phoneNo ?? "-",
                                        icon: HugeIcons.strokeRoundedCall02,
                                      ),
                                      _buildDetailTile(
                                        context,
                                        label: getTranslated(
                                          context,
                                          AppString.information_patient_time,
                                        ).toString(),
                                        value: time ?? "-",
                                        icon: HugeIcons.strokeRoundedTime01,
                                      ),
                                      _buildDetailTile(
                                        context,
                                        label: getTranslated(
                                          context,
                                          AppString.information_patient_address,
                                        ).toString(),
                                        value: patientAddress ?? "-",
                                        icon: HugeIcons.strokeRoundedLocation01,
                                      ),

                                      // Insurance Details
                                      if (isInsured == 1) ...[
                                        _buildDetailTile(
                                          context,
                                          label: getTranslated(
                                            context,
                                            AppString.policy_provider,
                                          ).toString(),
                                          value: policyInsurerName,
                                          icon:
                                              HugeIcons.strokeRoundedShieldUser,
                                        ),
                                        _buildDetailTile(
                                          context,
                                          label: getTranslated(
                                            context,
                                            AppString.policy_number,
                                          ).toString(),
                                          value: policyNumber,
                                          icon: HugeIcons.strokeRoundedTicket01,
                                        ),
                                      ] else ...[
                                        _buildDetailTile(
                                          context,
                                          label: getTranslated(
                                            context,
                                            AppString.patientInsured,
                                          ).toString(),
                                          value: getTranslated(
                                            context,
                                            AppString.patientIsNotInsured,
                                          ).toString(),
                                          icon: HugeIcons.strokeRoundedShield01,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),

                                // Tab 2: Illness Information & Astra Fill
                                SingleChildScrollView(
                                  padding: const EdgeInsets.all(
                                      AyurezeTheme.spaceXl),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Astra Fill Display Widget
                                      if (userId != null)
                                        AstraFillDisplayWidget(
                                          patientId: userId.toString(),
                                          preloadedData: astraFillData,
                                        ),

                                      const SizedBox(height: 16),

                                      // TODO(astra-backend): keyed on the
                                      // Laravel user id, same as Astra Fill
                                      // above; confirm the wellness endpoint
                                      // uses that id and not an Astra uid.
                                      if (userId != null)
                                        PatientWellnessSection(
                                          patientId: userId.toString(),
                                        ),

                                      _buildInfoCard(
                                        context,
                                        title: getTranslated(
                                          context,
                                          AppString
                                              .information_patient_illness_information,
                                        ).toString(),
                                        content: illness ?? "None reported",
                                        icon: HugeIcons.strokeRoundedBandage,
                                      ),
                                      const SizedBox(height: 12),
                                      _buildInfoCard(
                                        context,
                                        title: getTranslated(
                                          context,
                                          AppString
                                              .information_side_effect_drug,
                                        ).toString(),
                                        content: drugEffect ?? "None reported",
                                        icon: HugeIcons.strokeRoundedMedicine01,
                                      ),
                                      const SizedBox(height: 12),
                                      _buildInfoCard(
                                        context,
                                        title: getTranslated(
                                          context,
                                          AppString.information_note,
                                        ).toString(),
                                        content: note ?? "No notes added",
                                        icon: HugeIcons.strokeRoundedNote01,
                                      ),

                                      // Report Images
                                      if (reportImages.isNotEmpty) ...[
                                        const SizedBox(height: 20),
                                        Text(
                                          getTranslated(
                                            context,
                                            AppString
                                                .information_report_image_title,
                                          ).toString(),
                                          style:
                                              textTheme.titleMedium?.copyWith(
                                            color: AyurezeTheme.textPrimary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        GridView.builder(
                                          shrinkWrap: true,
                                          physics:
                                              const NeverScrollableScrollPhysics(),
                                          itemCount: reportImages.length,
                                          gridDelegate:
                                              const SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: 3,
                                            crossAxisSpacing: 10,
                                            mainAxisSpacing: 10,
                                          ),
                                          itemBuilder: (context, index) {
                                            return FullScreenWidget(
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        AyurezeTheme.radiusMd),
                                                child: Image.network(
                                                  reportImages[index],
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ],
                                  ),
                                ),

                                // Tab 3: Prescription
                                SingleChildScrollView(
                                  padding: const EdgeInsets.all(
                                      AyurezeTheme.spaceXl),
                                  child: Column(
                                    children: [
                                      GlassSurface(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(
                                            AyurezeTheme.spaceXl),
                                        child: Column(
                                          children: [
                                            HugeIcon(
                                              icon: HugeIcons
                                                  .strokeRoundedSparkles,
                                              size: 40,
                                              color: AyurezeTheme.iconPrimary,
                                            ),
                                            const SizedBox(height: 12),
                                            Text(
                                              "Smart Prescribe (Astra AI)",
                                              style: textTheme.titleMedium
                                                  ?.copyWith(
                                                color: AyurezeTheme.textPrimary,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              "AI-assisted prescription generator tailored for clinical practice.",
                                              textAlign: TextAlign.center,
                                              style: textTheme.bodyMedium
                                                  ?.copyWith(
                                                color:
                                                    AyurezeTheme.textSecondary,
                                              ),
                                            ),
                                            const SizedBox(height: 18),
                                            ElevatedButton.icon(
                                              icon: const HugeIcon(
                                                icon: HugeIcons
                                                    .strokeRoundedSparkles,
                                                color: Colors.white,
                                              ),
                                              label: const Text(
                                                "Launch Smart Prescribe",
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    AyurezeTheme.forestDeep,
                                                minimumSize:
                                                    const Size.fromHeight(50),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          AyurezeTheme
                                                              .radiusLg),
                                                ),
                                              ),
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        PrescriptionScreen(
                                                      patientId:
                                                          userId.toString(),
                                                      patientName:
                                                          name ?? "Patient",
                                                      patientPhone: phoneNo,
                                                      astraFillData:
                                                          astraFillData,
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );

          // Companion case/journey data (the Astra case card, wellness) is
          // shown under a consent check - never assuming full access.
          return SharingConsentGuard(
            patientId: userId?.toString(),
            child: content,
          );
        },
      ),
    );
  }

  void _showCallOptions(
    BuildContext context,
    String? phoneNo,
    String? appointmentType,
    int? userId,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AyurezeTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AyurezeTheme.radiusXl)),
      ),
      builder: (BuildContext bc) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AyurezeTheme.spaceMd),
            child: Wrap(
              children: <Widget>[
                ListTile(
                  leading: HugeIcon(
                      icon: AppIcons.call, color: AyurezeTheme.iconPrimary),
                  title: Text(
                    getTranslated(context, "call_text").toString(),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AyurezeTheme.textPrimary,
                        ),
                  ),
                  onTap: () {
                    if (SharedPreferenceHelper.getBoolean(
                          Preferences.is_logged_in,
                        ) ==
                        true) {
                      Navigator.of(context).pop();
                      launchUrl(Uri.parse("tel:$phoneNo"));
                    } else {
                      Navigator.of(context).pop();
                    }
                  },
                ),
                if (appointmentType == 'video')
                  ListTile(
                    leading: HugeIcon(
                      icon: HugeIcons.strokeRoundedVideo01,
                      color: AyurezeTheme.iconPrimary,
                    ),
                    title: Text(
                      getTranslated(context, "video_call").toString(),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AyurezeTheme.textPrimary,
                          ),
                    ),
                    onTap: () {
                      if (SharedPreferenceHelper.getBoolean(
                            Preferences.is_logged_in,
                          ) ==
                          true) {
                        Navigator.of(context).pop();
                        _addVideoOverlay(context, userId);
                      } else {
                        Navigator.of(context).pop();
                      }
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoColumn(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: textTheme.bodySmall?.copyWith(
            color: AyurezeTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          textAlign: TextAlign.center,
          style: textTheme.bodyLarge?.copyWith(
            color: AyurezeTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailTile(
    BuildContext context, {
    required String label,
    required String value,
    required List<List<dynamic>> icon,
  }) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AyurezeTheme.spaceMd),
      child: GlassSurface(
        padding: const EdgeInsets.all(AyurezeTheme.spaceMd),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AyurezeTheme.spaceSm),
              decoration: BoxDecoration(
                color: AyurezeTheme.surfaceMuted,
                borderRadius: BorderRadius.circular(AyurezeTheme.radiusMd),
              ),
              child: HugeIcon(
                  icon: icon, size: 20, color: AyurezeTheme.iconPrimary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: textTheme.bodySmall?.copyWith(
                      color: AyurezeTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: textTheme.titleMedium?.copyWith(
                      color: AyurezeTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required String title,
    required String content,
    required List<List<dynamic>> icon,
  }) {
    final textTheme = Theme.of(context).textTheme;

    return GlassSurface(
      width: double.infinity,
      padding: const EdgeInsets.all(AyurezeTheme.spaceLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              HugeIcon(icon: icon, size: 20, color: AyurezeTheme.iconPrimary),
              const SizedBox(width: 8),
              Text(
                title,
                style: textTheme.titleMedium?.copyWith(
                  color: AyurezeTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: textTheme.bodyLarge?.copyWith(
              color: AyurezeTheme.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  void _addVideoOverlay(BuildContext context, int? userId) {
    if (userId == null) {
      OslerToast.info(context, "Patient details are still loading...");
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoCall(
          id: userId,
          callEnd: false,
          flag: "OutGoing",
        ),
      ),
    );
  }

  /// Resolve the patient's Firestore chat user lazily and open the chat.
  /// Avoids mutating widget state during build.
  Future<void> _openChat(BuildContext context, int? userId) async {
    if (userId == null) {
      OslerToast.info(context, "Chat is loading...");
      return;
    }
    OslerToast.info(context, "Opening chat...");
    try {
      final doc = await homeProvider.getFirestoreUserOnce(
        FirestoreConstants.pathUserCollection,
        userId.toString(),
      );
      if (!context.mounted) return;
      if (doc == null || !doc.exists) {
        OslerToast.info(context, "Chat is loading...");
        return;
      }
      final userChat = UserChat.fromDocument(doc);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatPage(
            peerId: userChat.id.toString(),
            peerAvatar: userChat.photoUrl.toString(),
            peerNickname: userChat.nickname.toString(),
            token: userChat.token.toString(),
            isNavigate: 'chatHome',
          ),
        ),
      );
    } catch (e) {
      if (context.mounted) {
        OslerToast.info(context, "Chat is loading...");
      }
    }
  }
}
