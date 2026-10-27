import 'package:doctro/core/constants/app_icons.dart';
import 'package:doctro/core/constants/app_string.dart';
import 'package:doctro/core/constants/date_util.dart';
import 'package:doctro/core/localization/localization_constant.dart';
import 'package:doctro/models/Notification.dart';
import 'package:doctro/network/api_header.dart';
import 'package:doctro/network/base_model.dart';
import 'package:doctro/network/network_api.dart';
import 'package:doctro/network/server_error.dart';
import 'package:doctro/theme/ayureze_theme.dart';
import 'package:doctro/widgets/glass_surface.dart';
import 'package:flutter/material.dart';
import 'package:doctro/widgets/osler_state_view.dart';
import 'package:hugeicons/hugeicons.dart';

class ViewAllNotification extends StatefulWidget {
  const ViewAllNotification({super.key});

  @override
  State<ViewAllNotification> createState() => _ViewAllAppointmentState();
}

class _ViewAllAppointmentState extends State<ViewAllNotification> {
  late double width;
  late double height;

  Future? loadData;
  List<NotificationData> patientNotification = [];

  @override
  void initState() {
    super.initState();
    loadData = bookNotifications();
  }

  @override
  Widget build(BuildContext context) {
    width = MediaQuery.of(context).size.width;
    height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AyurezeTheme.canvas,
      appBar: AppBar(
        backgroundColor: AyurezeTheme.canvas,
        leading: IconButton(
          icon: HugeIcon(
            icon: AppIcons.back,
            color: AyurezeTheme.iconPrimary,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          getTranslated(context, AppString.notification_heading).toString(),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: AyurezeTheme.textPrimary,
              ),
        ),
      ),
      body: FutureBuilder(
        future: loadData,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const OslerLoadingView();
          }

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: AyurezeTheme.screenPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AyurezeTheme.space2xl),
                  decoration: AyurezeTheme.heroDecoration(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AyurezeTheme.spaceSm,
                          vertical: AyurezeTheme.spaceSm,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          borderRadius:
                              BorderRadius.circular(AyurezeTheme.radiusPill),
                        ),
                        child: Text(
                          "Full inbox",
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        "Every patient notification, in one scroll.",
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              color: Colors.white,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                if (patientNotification.isEmpty)
                  GlassSurface(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        vertical: AyurezeTheme.space3xl + AyurezeTheme.spaceXs),
                    child: Column(
                      children: [
                        Image.asset("assets/images/no-data.png", height: 88),
                        const SizedBox(height: 10),
                        Text(
                          "No notifications yet.",
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AyurezeTheme.textSecondary,
                                  ),
                        ),
                      ],
                    ),
                  )
                else
                  ...patientNotification
                      .map((item) => _buildNotificationCard(item)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(NotificationData item) {
    final date = DateUtil().formattedDate(DateTime.parse(item.createdAt!));
    return InkWell(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AyurezeTheme.radiusXl),
            ),
            content: Text(item.message!),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text(
                  getTranslated(context, AppString.schedule_ok_button)
                      .toString(),
                ),
              ),
            ],
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: AyurezeTheme.spaceMd),
        padding: const EdgeInsets.all(AyurezeTheme.spaceLg),
        decoration: AyurezeTheme.panelDecoration(),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AyurezeTheme.radiusMd),
              child: Image.network(
                item.user?.fullImage ?? "",
                width: 58,
                height: 58,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 58,
                    height: 58,
                    color: AyurezeTheme.surfaceMuted,
                    child: HugeIcon(
                      icon: AppIcons.profile,
                      color: AyurezeTheme.textSecondary,
                    ),
                  );
                },
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
                          item.user?.name ?? "",
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: AyurezeTheme.textPrimary,
                                  ),
                        ),
                      ),
                      Text(
                        date,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AyurezeTheme.textSecondary,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.message ?? "",
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AyurezeTheme.textSecondary,
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

  Future<BaseModel<Notifications>> bookNotifications() async {
    Notifications response;
    try {
      patientNotification.clear();
      response =
          await RestClient(await RetroApi().dioData(context)).notifications();
      if (!mounted) return BaseModel()..data = response;
      setState(() {
        patientNotification.addAll(response.data!);
      });
    } catch (error) {
      return BaseModel()..setException(ServerError.withError(error: error));
    }
    return BaseModel()..data = response;
  }
}
