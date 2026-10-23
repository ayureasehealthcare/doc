import 'package:doctro/widgets/osler_hero.dart';
import 'package:doctro/widgets/osler_state_view.dart';
import 'package:doctro/core/constants/app_icons.dart';
import 'package:doctro/core/constants/app_string.dart';
import 'package:doctro/core/constants/date_util.dart';
import 'package:doctro/core/constants/prefConstatnt.dart';
import 'package:doctro/core/constants/preferences.dart';
import 'package:doctro/core/localization/localization_constant.dart';
import 'package:doctro/models/Notification.dart';
import 'package:doctro/network/api_header.dart';
import 'package:doctro/network/base_model.dart';
import 'package:doctro/network/network_api.dart';
import 'package:doctro/network/server_error.dart';
import 'package:doctro/theme/app_motion.dart';
import 'package:doctro/theme/ayureze_theme.dart';
import 'package:doctro/widgets/glass_surface.dart';
import 'package:doctro/widgets/modern_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hugeicons/hugeicons.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  late double width;
  late double height;

  Future? loadData;

  List<NotificationData> patientNotification = [];

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      loadData = bookNotifications();
      SharedPreferenceHelper.getString(Preferences.name);
    });
  }

  @override
  Widget build(BuildContext context) {
    width = MediaQuery.of(context).size.width;
    height = MediaQuery.of(context).size.height;

    return Scaffold(
      key: _scaffoldKey,
      drawer: const ModernDrawer(),
      backgroundColor: AyurezeTheme.canvas,
      appBar: AppBar(
        backgroundColor: AyurezeTheme.canvas,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: HugeIcon(
            icon: AppIcons.back,
            color: AyurezeTheme.iconPrimary,
            size: 20,
          ),
        ),
        title: Text(
          getTranslated(context, AppString.notification_heading).toString(),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: AyurezeTheme.textPrimary,
              ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              _scaffoldKey.currentState!.openDrawer();
            },
            icon: SvgPicture.asset(
              "assets/icons/dMenuBar.svg",
              height: 16,
              colorFilter:
                  ColorFilter.mode(AyurezeTheme.iconPrimary, BlendMode.srcIn),
            ),
          ),
        ],
      ),
      body: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          Navigator.pushNamedAndRemoveUntil(
            context,
            'loginHome',
            (route) => false,
          );
        },
        child: RefreshIndicator(
          onRefresh: bookNotifications,
          color: AyurezeTheme.iconPrimary,
          child: FutureBuilder(
            future: loadData,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const OslerLoadingView();
              }

              return Stack(
                children: [
                  Positioned(
                    top: -60,
                    right: -80,
                    child: GlassBlob(
                        size: 220, color: AyurezeTheme.healingGreen50),
                  ),
                  Positioned(
                    bottom: 120,
                    left: -90,
                    child: GlassBlob(
                        size: 220, color: AyurezeTheme.sunshineYellow50),
                  ),
                  SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: AyurezeTheme.screenPadding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ScreenEntrance(index: 0, child: _buildHero()),
                        const SizedBox(height: 18),
                        if (patientNotification.isEmpty)
                          ScreenEntrance(index: 1, child: _buildEmptyState())
                        else ...[
                          ...patientNotification
                              .take(patientNotification.length > 6
                                  ? 6
                                  : patientNotification.length)
                              .toList()
                              .asMap()
                              .entries
                              .map((e) =>
                                  _buildNotificationCard(e.value, e.key % 8)),
                          if (patientNotification.length >= 6)
                            ScreenEntrance(
                                index: 6, child: _buildViewAllCard()),
                        ],
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHero() {
    return const OslerHero(
      eyebrow: 'Inbox',
      title: 'Keep patient alerts visible and calm.',
      subtitle:
          'Recent appointment and patient notifications stay grouped here in the same Ayureze desk language.',
    );
  }

  Widget _buildNotificationCard(NotificationData item, int index) {
    final date = DateUtil().formattedDate(DateTime.parse(item.createdAt!));
    final card = InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
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

    return ScreenEntrance(index: index, child: card);
  }

  Widget _buildViewAllCard() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.pushNamed(context, "ViewAllNotification");
      },
      child: GlassSurface(
        padding: const EdgeInsets.all(AyurezeTheme.spaceLg),
        child: Row(
          children: [
            Expanded(
              child: Text(
                getTranslated(context, AppString.notification_view_all)
                    .toString(),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AyurezeTheme.textPrimary,
                    ),
              ),
            ),
            SvgPicture.asset(
              'assets/icons/longArrow.svg',
              height: 12,
              colorFilter:
                  ColorFilter.mode(AyurezeTheme.iconPrimary, BlendMode.srcIn),
            ),
            const SizedBox(width: 10),
            Text(
              "${patientNotification.length}",
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AyurezeTheme.textPrimary,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return GlassSurface(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
          vertical: AyurezeTheme.space3xl + AyurezeTheme.spaceXs),
      child: Column(
        children: [
          Image.asset("assets/images/no-data.png", height: 88),
          const SizedBox(height: 10),
          Text(
            "No notifications yet.",
            style: TextStyle(color: AyurezeTheme.textSecondary),
          ),
        ],
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
