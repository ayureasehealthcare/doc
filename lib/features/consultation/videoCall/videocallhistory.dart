import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctro/core/constants/app_icons.dart';
import 'package:doctro/core/constants/app_string.dart';
import 'package:doctro/theme/app_motion.dart';
import 'package:doctro/theme/ayureze_theme.dart';
import 'package:doctro/widgets/osler_card.dart';
import 'package:doctro/widgets/osler_loader.dart';
import 'package:doctro/widgets/osler_state_view.dart';
import 'package:doctro/core/constants/date_util.dart';
import 'package:doctro/core/localization/localization_constant.dart';
import 'package:doctro/core/utils/safe_parse.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';

import 'view_models/videocallhistory_view_model.dart';

class VideoCallHistory extends StatefulWidget {
  const VideoCallHistory({super.key});

  @override
  State<VideoCallHistory> createState() => _VideoCallHistoryState();
}

class _VideoCallHistoryState extends State<VideoCallHistory> {
  /// Puts a state view in a scrollable so the surrounding RefreshIndicator
  /// can still be pulled - a bare Center gives it nothing to drag.
  Widget _pullable(Widget child) => LayoutBuilder(
        builder: (context, constraints) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: constraints.maxHeight, child: child),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;

    return ChangeNotifierProvider<VideoCallHistoryViewModel>(
      create: (context) =>
          VideoCallHistoryViewModel()..fetchVideoCallHistory(context),
      child: Builder(
        builder: (context) => Scaffold(
          backgroundColor: AyurezeTheme.canvas,
          appBar: AppBar(
            elevation: 0,
            leading: IconButton(
              icon: HugeIcon(
                icon: AppIcons.back,
                size: 20,
                color: AyurezeTheme.textSecondary,
              ),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            centerTitle: true,
            backgroundColor: AyurezeTheme.canvas,
            title: Text(
              getTranslated(context, AppString.drawer_callHistory).toString(),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AyurezeTheme.textSecondary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          body: Consumer<VideoCallHistoryViewModel>(
            builder: (context, viewModel, child) {
              return RefreshIndicator(
                onRefresh: () => viewModel.fetchVideoCallHistory(context),
                child: viewModel.isLoading
                    ? const OslerLoadingView()
                    : viewModel.hasError
                        ? _pullable(OslerStateView(
                            icon: HugeIcons.strokeRoundedAlert02,
                            tone: OslerStateTone.error,
                            title: "Couldn't load call history",
                            message: viewModel.errorMessage,
                            actionLabel: 'Retry',
                            onAction: () =>
                                viewModel.fetchVideoCallHistory(context),
                          ))
                        : viewModel.callHistory.isNotEmpty
                            ? ListView.builder(
                                itemCount: viewModel.callHistory.length,
                                scrollDirection: Axis.vertical,
                                itemBuilder: (context, index) {
                                  final callData = viewModel.callHistory[index];
                                  final now = Duration(
                                      seconds: safeInt(callData.duration));
                                  String printDuration(Duration duration) {
                                    String twoDigits(int n) =>
                                        n.toString().padLeft(2, "0");
                                    String twoDigitMinutes = twoDigits(
                                        duration.inMinutes.remainder(60));
                                    String twoDigitSeconds = twoDigits(
                                        duration.inSeconds.remainder(60));
                                    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
                                  }

                                  String duration = "";
                                  String str = printDuration(now);
                                  List<String> parts = str.split(":");
                                  String hourPart = parts[0].trim();
                                  String minuteType = parts[1].trim();
                                  String secondType = parts[2].trim();

                                  if (hourPart != "00" && minuteType != "00") {
                                    duration =
                                        "${hourPart}h ${minuteType}m ${secondType}s ";
                                  } else if (hourPart == "00" &&
                                      minuteType != "00") {
                                    duration = "${minuteType}m ${secondType}s ";
                                  } else {
                                    duration = "${secondType}s ";
                                  }

                                  final row = Column(
                                    children: [
                                      OslerCard(
                                        margin: const EdgeInsets.symmetric(
                                            horizontal: AyurezeTheme.spaceLg,
                                            vertical: AyurezeTheme.spaceXs),
                                        padding: const EdgeInsets.all(
                                            AyurezeTheme.spaceSm),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: width * 0.15,
                                              alignment:
                                                  AlignmentDirectional.center,
                                              margin: EdgeInsets.symmetric(
                                                  horizontal: width * 0.01,
                                                  vertical: width * 0.02),
                                              child: Column(
                                                children: [
                                                  SizedBox(
                                                    width: width * 0.15,
                                                    height: height * 0.065,
                                                    child: ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10),
                                                      child: CachedNetworkImage(
                                                        alignment:
                                                            Alignment.center,
                                                        imageUrl: callData.user
                                                                ?.fullImage ??
                                                            "",
                                                        fit: BoxFit.fitHeight,
                                                        placeholder:
                                                            (context, url) =>
                                                                const Center(
                                                          child: OslerLoader(
                                                              size: 16,
                                                              strokeWidth: 2),
                                                        ),
                                                        errorWidget: (context,
                                                                url, error) =>
                                                            ClipRRect(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(15),
                                                          child: Image.asset(
                                                              "assets/images/no_image.jpg"),
                                                        ),
                                                        width: width * 0.15,
                                                        height: height * 0.065,
                                                      ),
                                                    ),
                                                  )
                                                ],
                                              ),
                                            ),
                                            SizedBox(
                                              width: width * 0.8,
                                              child: Container(
                                                margin:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: AyurezeTheme
                                                            .spaceSm,
                                                        vertical: AyurezeTheme
                                                            .spaceXs),
                                                child: Column(
                                                  children: [
                                                    Container(
                                                      margin: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 0,
                                                          vertical: AyurezeTheme
                                                              .spaceXs),
                                                      child: Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceBetween,
                                                        children: [
                                                          Text(
                                                            callData.user
                                                                    ?.name ??
                                                                "",
                                                            style: Theme.of(
                                                                    context)
                                                                .textTheme
                                                                .titleMedium
                                                                ?.copyWith(
                                                                  color: AyurezeTheme
                                                                      .textSecondary,
                                                                ),
                                                          ),
                                                          Text(
                                                            (callData.startTime ??
                                                                    "")
                                                                .toLowerCase(),
                                                            style: Theme.of(
                                                                    context)
                                                                .textTheme
                                                                .bodySmall
                                                                ?.copyWith(
                                                                  color: AyurezeTheme
                                                                      .textSecondary,
                                                                ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    Container(
                                                      alignment:
                                                          AlignmentDirectional
                                                              .topStart,
                                                      child: Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceBetween,
                                                        children: [
                                                          Text(
                                                            duration,
                                                            style: Theme.of(
                                                                    context)
                                                                .textTheme
                                                                .bodySmall
                                                                ?.copyWith(
                                                                  color: AyurezeTheme
                                                                      .textSecondary,
                                                                ),
                                                          ),
                                                          Text(
                                                            DateUtil().formattedDate(
                                                                DateTime.parse(
                                                                    callData.date ??
                                                                        "")),
                                                            style: Theme.of(
                                                                    context)
                                                                .textTheme
                                                                .bodySmall
                                                                ?.copyWith(
                                                                  color: AyurezeTheme
                                                                      .textSecondary,
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
                                      Container(
                                        margin: const EdgeInsets.symmetric(
                                            vertical: AyurezeTheme.spaceXs,
                                            horizontal: AyurezeTheme.spaceSm),
                                        child: Column(
                                          children: [
                                            Divider(
                                              height: height * 0.005,
                                              thickness: width * 0.005,
                                              color: AyurezeTheme.border,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );

                                  return ScreenEntrance(
                                      index: index % 8, child: row);
                                },
                              )
                            : _pullable(const OslerStateView(
                                icon: HugeIcons.strokeRoundedVideo01,
                                title: 'No calls yet',
                                message: 'Video consultations you take will '
                                    'appear here.',
                              )),
              );
            },
          ),
        ),
      ),
    );
  }
}
