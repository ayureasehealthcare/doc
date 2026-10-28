import 'dart:convert';

import 'package:doctro/core/constants/app_icons.dart';
import 'package:doctro/core/constants/app_string.dart';
import 'package:doctro/theme/ayureze_theme.dart';
import 'package:doctro/widgets/glass_surface.dart';
import 'package:doctro/core/localization/localization_constant.dart';
import 'package:doctro/models/working_hours.dart';
import 'package:doctro/models/update_timing.dart';
import 'package:doctro/network/api_header.dart';
import 'package:doctro/network/base_model.dart';
import 'package:doctro/widgets/osler_state_view.dart';
import 'package:doctro/widgets/osler_tag.dart';
import 'package:doctro/network/network_api.dart';
import 'package:doctro/network/server_error.dart';
import 'package:doctro/widgets/osler_button.dart';
import 'package:doctro/widgets/osler_toast.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';

class ScheduleTimings extends StatefulWidget {
  const ScheduleTimings({super.key});

  @override
  State<ScheduleTimings> createState() => _ScheduleTimingsState();
}

//Set Value in Switch
bool isSwitched = true;

//Check Status
int? checkStatus;

List<Data> workingReq = [];
int passIndex = 0;
List startsTime = [];
List endsTime = [];

class _ScheduleTimingsState extends State<ScheduleTimings>
    with SingleTickerProviderStateMixin {
  //Set Loader
  Future? workingHours;

  List<Map<String, dynamic>> listDynamic = [];

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    workingHours = doctorWorkingHoursFunction();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  //Show Start & End Time List
  String? startTime;
  String? endTime;

  //Set Height/Width using MediaQuery
  late double width;
  late double height;

  int? id;

  //Set Value edit Button on Click to addMore
  String? _startTime;
  String? _endTime;

  @override
  Widget build(BuildContext context) {
    width = MediaQuery.of(context).size.width;
    height = MediaQuery.of(context).size.height;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AyurezeTheme.canvas,
      appBar: AppBar(
        backgroundColor: AyurezeTheme.canvas,
        elevation: 0,
        leading: IconButton(
          icon: HugeIcon(
              icon: AppIcons.back, color: AyurezeTheme.iconPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          getTranslated(context, AppString.schedule_heading).toString(),
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: AyurezeTheme.textPrimary,
          ),
        ),
      ),
      body: FutureBuilder(
        future: workingHours,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const OslerLoadingView(message: 'Loading your schedule…');
          }
          // A failed fetch used to fall through and draw an empty week, as
          // if no hours were set. Say it failed, and offer a retry.
          final result = snapshot.data;
          if (result is BaseModel && result.data == null) {
            String? reason;
            try {
              reason = result.error.getErrorMessage()?.toString();
            } catch (_) {
              // `error` is late and may be unset; fall back to generic copy.
            }
            return OslerStateView.error(
              title: "Couldn't load your schedule",
              message: (reason == null || reason.isEmpty)
                  ? 'Check your connection and try again.'
                  : reason,
              onRetry: () =>
                  setState(() => workingHours = doctorWorkingHoursFunction()),
            );
          } else {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: AyurezeTheme.screenPadding,
                    child: Column(
                      children: [
                        _buildHero(context),
                        const SizedBox(height: 22),
                        GlassSurface(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AyurezeTheme.spaceLg,
                              vertical: AyurezeTheme.spaceMd),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                getTranslated(context,
                                        AppString.schedule_schedule_title)
                                    .toString(),
                                style: textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: AyurezeTheme.textSecondary,
                                ),
                              ),
                              Text(
                                getTranslated(
                                        context, AppString.schedule_time_slot)
                                    .toString(),
                                style: textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: AyurezeTheme.textSecondary,
                                ),
                              ),
                              Text(
                                getTranslated(
                                        context, AppString.schedule_status)
                                    .toString(),
                                style: textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: AyurezeTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        ListView.builder(
                          itemCount: workingReq.length,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemBuilder: (context, index) {
                            endsTime.clear();
                            startsTime.clear();
                            var parseData =
                                json.decode(workingReq[index].periodList!);
                            for (int i = 0; i < parseData.length; i++) {
                              startsTime.add(parseData[i]['start_time']);
                              endsTime.add(parseData[i]['end_time']);
                            }
                            final dayOff = workingReq[index].status == 0;
                            return Container(
                              margin: const EdgeInsets.only(
                                  bottom: AyurezeTheme.spaceMd),
                              decoration: AyurezeTheme.panelDecoration(),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: AyurezeTheme.spaceLg,
                                    vertical: AyurezeTheme.spaceSm),
                                title: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // One line, shrunk if needed: at flex 3
                                    // "Tuesday" broke mid-word on a phone.
                                    Expanded(
                                      flex: 4,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          FittedBox(
                                            fit: BoxFit.scaleDown,
                                            alignment: Alignment.centerLeft,
                                            child: Text(
                                              workingReq[index].dayIndex!,
                                              maxLines: 1,
                                              style: textTheme.titleMedium
                                                  ?.copyWith(
                                                fontWeight: FontWeight.w800,
                                                color: AyurezeTheme.textPrimary,
                                              ),
                                            ),
                                          ),
                                          if (dayOff) ...[
                                            const SizedBox(
                                                height: AyurezeTheme.spaceXs),
                                            OslerTag(
                                              label: getTranslated(context,
                                                  AppString.schedule_day_off),
                                              style: OslerTagStyle.secondary,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: AyurezeTheme.spaceSm),
                                    // An off day keeps its saved slots,
                                    // faded: they apply again when it is
                                    // switched back on.
                                    Expanded(
                                      flex: 8,
                                      child: Opacity(
                                          opacity: dayOff ? 0.45 : 1,
                                          child: ListView.builder(
                                            itemCount: startsTime.length,
                                            shrinkWrap: true,
                                            physics:
                                                const NeverScrollableScrollPhysics(),
                                            itemBuilder: (context, index) {
                                              return Padding(
                                                padding: const EdgeInsets.only(
                                                    bottom:
                                                        AyurezeTheme.spaceXs),
                                                child: Row(
                                                  children: [
                                                    Text(
                                                      startsTime[index],
                                                      style: textTheme.bodySmall
                                                          ?.copyWith(
                                                        color: AyurezeTheme
                                                            .textSecondary,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      getTranslated(context,
                                                              AppString.to)
                                                          .toString(),
                                                      style: textTheme
                                                          .labelSmall
                                                          ?.copyWith(
                                                        color: AyurezeTheme
                                                            .textSecondary,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      endsTime[index],
                                                      style: textTheme.bodySmall
                                                          ?.copyWith(
                                                        color: AyurezeTheme
                                                            .textSecondary,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                          )),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: IconButton(
                                        icon: HugeIcon(
                                          icon: HugeIcons
                                              .strokeRoundedCalendarSetting01,
                                          color: AyurezeTheme.iconPrimary,
                                          size: 22,
                                        ),
                                        onPressed: () async {
                                          passIndex = index;
                                          id = workingReq[index].id;
                                          checkStatus =
                                              workingReq[index].status;
                                          dynamic convertData;
                                          listDynamic.clear();
                                          convertData = json.decode(
                                              workingReq[index].periodList!);
                                          startTime =
                                              convertData[0]['start_time'];
                                          endTime = convertData[0]['end_time'];

                                          TextEditingController
                                              startController =
                                              TextEditingController();
                                          TextEditingController endController =
                                              TextEditingController();

                                          for (int k = 0;
                                              k < convertData.length;
                                              k++) {
                                            startController.text =
                                                convertData[k]['start_time'];
                                            endController.text =
                                                convertData[k]['end_time'];

                                            listDynamic.add({
                                              "start_time":
                                                  startController.text,
                                              "end_time": endController.text,
                                            });
                                          }

                                          showDialog(
                                            barrierDismissible: false,
                                            context: context,
                                            builder: (context) {
                                              return StatefulBuilder(
                                                builder: (context, myState) {
                                                  return AlertDialog(
                                                    shape:
                                                        RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        28)),
                                                    backgroundColor:
                                                        AyurezeTheme.surface,
                                                    title: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          getTranslated(
                                                                  context,
                                                                  AppString
                                                                      .schedule_heading)
                                                              .toString(),
                                                          style: textTheme
                                                              .titleMedium
                                                              ?.copyWith(
                                                            fontWeight:
                                                                FontWeight.w800,
                                                            color: AyurezeTheme
                                                                .textPrimary,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            height: 8),
                                                        SwitchScreen(
                                                            checkStatus)
                                                      ],
                                                    ),
                                                    content: SizedBox(
                                                      height: height * 0.4,
                                                      width: width * 0.9,
                                                      child: Column(
                                                        children: [
                                                          Flexible(
                                                            child: ListView
                                                                .builder(
                                                              itemCount:
                                                                  listDynamic
                                                                      .length,
                                                              itemBuilder:
                                                                  (context,
                                                                      index) {
                                                                return Container(
                                                                  margin:
                                                                      const EdgeInsets
                                                                          .only(
                                                                          bottom:
                                                                              12),
                                                                  padding:
                                                                      const EdgeInsets
                                                                          .all(
                                                                          12),
                                                                  decoration:
                                                                      BoxDecoration(
                                                                    color: AyurezeTheme
                                                                        .surfaceMuted,
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                            16),
                                                                    border: Border.all(
                                                                        color: AyurezeTheme
                                                                            .border),
                                                                  ),
                                                                  child: Column(
                                                                    children: [
                                                                      Row(
                                                                        mainAxisAlignment:
                                                                            MainAxisAlignment.spaceBetween,
                                                                        children: [
                                                                          Text(
                                                                            getTranslated(context, AppString.schedule_start_time).toString(),
                                                                            style:
                                                                                textTheme.bodySmall?.copyWith(
                                                                              fontWeight: FontWeight.w700,
                                                                              color: AyurezeTheme.textSecondary,
                                                                            ),
                                                                          ),
                                                                          Text(
                                                                            getTranslated(context, AppString.schedule_end_time).toString(),
                                                                            style:
                                                                                textTheme.bodySmall?.copyWith(
                                                                              fontWeight: FontWeight.w700,
                                                                              color: AyurezeTheme.textSecondary,
                                                                            ),
                                                                          ),
                                                                          const SizedBox(
                                                                              width: 24),
                                                                        ],
                                                                      ),
                                                                      const SizedBox(
                                                                          height:
                                                                              8),
                                                                      Row(
                                                                        mainAxisAlignment:
                                                                            MainAxisAlignment.spaceBetween,
                                                                        children: [
                                                                          InkWell(
                                                                            onTap:
                                                                                () async {
                                                                              List tempChange = [];
                                                                              final TimeOfDay? result = await showTimePicker(
                                                                                  context: context,
                                                                                  initialTime: TimeOfDay.now(),
                                                                                  builder: (context, child) {
                                                                                    return MediaQuery(data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false), child: child!);
                                                                                  });
                                                                              if (result != null) {
                                                                                myState(() {
                                                                                  DateTime tempDate = DateFormat("hh:mm").parse("${result.hour}:${result.minute}");
                                                                                  var dateFormat = DateFormat("hh:mm a");
                                                                                  String finalTime = dateFormat.format(tempDate);
                                                                                  _startTime = finalTime;

                                                                                  var decodeData = json.decode(workingReq[passIndex].periodList!);
                                                                                  for (int i = 0; i < listDynamic.length; i++) {
                                                                                    tempChange.add(decodeData[i]);
                                                                                  }
                                                                                  tempChange[index] = {
                                                                                    "start_time": _startTime,
                                                                                    "end_time": listDynamic[index]["end_time"]
                                                                                  };
                                                                                  listDynamic[index] = {
                                                                                    "start_time": _startTime,
                                                                                    "end_time": listDynamic[index]["end_time"]
                                                                                  };
                                                                                });
                                                                              }
                                                                              setState(() {
                                                                                workingReq[passIndex].periodList = const JsonEncoder().convert(tempChange);
                                                                              });
                                                                            },
                                                                            child:
                                                                                Container(
                                                                              padding: const EdgeInsets.symmetric(horizontal: AyurezeTheme.spaceMd, vertical: AyurezeTheme.spaceSm),
                                                                              decoration: BoxDecoration(
                                                                                color: AyurezeTheme.surface,
                                                                                borderRadius: BorderRadius.circular(AyurezeTheme.radiusMd),
                                                                                border: Border.all(color: AyurezeTheme.border),
                                                                              ),
                                                                              child: Text(
                                                                                listDynamic[index]['start_time'].toString(),
                                                                                style: textTheme.bodyMedium?.copyWith(
                                                                                  fontWeight: FontWeight.w700,
                                                                                  color: AyurezeTheme.textPrimary,
                                                                                ),
                                                                              ),
                                                                            ),
                                                                          ),
                                                                          HugeIcon(
                                                                              icon: HugeIcons.strokeRoundedArrowRight01,
                                                                              size: 16,
                                                                              color: AyurezeTheme.border),
                                                                          InkWell(
                                                                            onTap:
                                                                                () async {
                                                                              List tempChange = [];
                                                                              final TimeOfDay? result = await showTimePicker(
                                                                                  context: context,
                                                                                  initialTime: TimeOfDay.now(),
                                                                                  builder: (context, child) {
                                                                                    return MediaQuery(data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false), child: child!);
                                                                                  });
                                                                              if (result != null) {
                                                                                myState(() {
                                                                                  DateTime tempDate = DateFormat("hh:mm").parse("${result.hour}:${result.minute}");
                                                                                  var dateFormat = DateFormat("hh:mm a");
                                                                                  String finalTime = dateFormat.format(tempDate);
                                                                                  _endTime = finalTime;

                                                                                  var decodeData = json.decode(workingReq[passIndex].periodList!);
                                                                                  for (int i = 0; i < listDynamic.length; i++) {
                                                                                    tempChange.add(decodeData[i]);
                                                                                  }
                                                                                  tempChange[index] = {
                                                                                    "start_time": listDynamic[index]["start_time"],
                                                                                    "end_time": _endTime
                                                                                  };
                                                                                  listDynamic[index] = {
                                                                                    "start_time": listDynamic[index]["start_time"],
                                                                                    "end_time": _endTime
                                                                                  };
                                                                                });
                                                                              }
                                                                              setState(() {
                                                                                workingReq[passIndex].periodList = const JsonEncoder().convert(tempChange);
                                                                              });
                                                                            },
                                                                            child:
                                                                                Container(
                                                                              padding: const EdgeInsets.symmetric(horizontal: AyurezeTheme.spaceMd, vertical: AyurezeTheme.spaceSm),
                                                                              decoration: BoxDecoration(
                                                                                color: AyurezeTheme.surface,
                                                                                borderRadius: BorderRadius.circular(AyurezeTheme.radiusMd),
                                                                                border: Border.all(color: AyurezeTheme.border),
                                                                              ),
                                                                              child: Text(
                                                                                listDynamic[index]['end_time'].toString(),
                                                                                style: textTheme.bodyMedium?.copyWith(
                                                                                  fontWeight: FontWeight.w700,
                                                                                  color: AyurezeTheme.textPrimary,
                                                                                ),
                                                                              ),
                                                                            ),
                                                                          ),
                                                                          if (index !=
                                                                              0)
                                                                            IconButton(
                                                                              icon: HugeIcon(icon: HugeIcons.strokeRoundedMinusSignCircle, color: AyurezeTheme.remoteRed50, size: 20),
                                                                              onPressed: () {
                                                                                myState(() {
                                                                                  listDynamic.removeAt(index);
                                                                                });
                                                                              },
                                                                            )
                                                                          else
                                                                            const SizedBox(width: 48),
                                                                        ],
                                                                      ),
                                                                    ],
                                                                  ),
                                                                );
                                                              },
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                              height: 16),
                                                          OutlinedButton.icon(
                                                            onPressed: () {
                                                              myState(() {
                                                                listDynamic
                                                                    .add({
                                                                  "start_time": getTranslated(
                                                                          context,
                                                                          AppString
                                                                              .schedule_start_time)
                                                                      .toString(),
                                                                  "end_time": getTranslated(
                                                                          context,
                                                                          AppString
                                                                              .schedule_end_time)
                                                                      .toString(),
                                                                });

                                                                var decodeData =
                                                                    json.decode(
                                                                        workingReq[passIndex]
                                                                            .periodList!);
                                                                decodeData.add({
                                                                  "start_time": getTranslated(
                                                                          context,
                                                                          AppString
                                                                              .schedule_start_time)
                                                                      .toString(),
                                                                  "end_time": getTranslated(
                                                                          context,
                                                                          AppString
                                                                              .schedule_end_time)
                                                                      .toString(),
                                                                });
                                                                workingReq[passIndex]
                                                                        .periodList =
                                                                    const JsonEncoder()
                                                                        .convert(
                                                                            decodeData);
                                                              });
                                                            },
                                                            icon: const Icon(
                                                                Icons
                                                                    .add_rounded,
                                                                size: 18),
                                                            label: Text(getTranslated(
                                                                    context,
                                                                    AppString
                                                                        .schedule_add_more)
                                                                .toString()),
                                                            style:
                                                                OutlinedButton
                                                                    .styleFrom(
                                                              minimumSize:
                                                                  const Size
                                                                      .fromHeight(
                                                                      48),
                                                              foregroundColor:
                                                                  AyurezeTheme
                                                                      .healingGreen100,
                                                              side: BorderSide(
                                                                  color: AyurezeTheme
                                                                      .border),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    actions: <Widget>[
                                                      TextButton(
                                                        child: Text(
                                                          "Cancel",
                                                          style: textTheme
                                                              .labelLarge
                                                              ?.copyWith(
                                                                  color: AyurezeTheme
                                                                      .textSecondary),
                                                        ),
                                                        onPressed: () =>
                                                            Navigator.pop(
                                                                context),
                                                      ),
                                                      OslerButton(
                                                        text: getTranslated(
                                                                context,
                                                                AppString
                                                                    .schedule_ok_button)
                                                            .toString(),
                                                        onPressed: () {
                                                          bool isOk = true;
                                                          for (int i = 0;
                                                              i <
                                                                  listDynamic
                                                                      .length;
                                                              i++) {
                                                            if (listDynamic[i][
                                                                        'start_time'] ==
                                                                    getTranslated(
                                                                            context,
                                                                            AppString
                                                                                .schedule_start_time)
                                                                        .toString() ||
                                                                listDynamic[i][
                                                                        'end_time'] ==
                                                                    getTranslated(
                                                                            context,
                                                                            AppString.schedule_end_time)
                                                                        .toString()) {
                                                              isOk = false;
                                                            }
                                                          }

                                                          if (isOk == true) {
                                                            myState(() {
                                                              updateHours();
                                                              Navigator.pop(
                                                                  context);
                                                            });
                                                          } else {
                                                            OslerToast.warning(
                                                                context,
                                                                getTranslated(
                                                                        context,
                                                                        AppString
                                                                            .please_enter_start_end_time)
                                                                    .toString());
                                                          }
                                                        },
                                                      ),
                                                    ],
                                                  );
                                                },
                                              );
                                            },
                                          );
                                        },
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            );
                          },
                        )
                      ],
                    ),
                  ),
                ),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildHero(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AyurezeTheme.spaceXl),
      decoration: AyurezeTheme.heroDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AyurezeTheme.spaceSm,
                vertical: AyurezeTheme.spaceXs),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AyurezeTheme.radiusPill),
            ),
            child: Text(
              "Weekly availability",
              style: textTheme.labelSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            "Set your desk hours.",
            style: textTheme.headlineMedium?.copyWith(
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Define the time slots for each day of the week to let patients know when you're available.",
            style: textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.85),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Future<BaseModel<Workinghours>> doctorWorkingHoursFunction() async {
    Workinghours response;

    try {
      workingReq.clear();
      response =
          await RestClient(await RetroApi().dioData(context)).workinghours();
      if (!mounted) return BaseModel()..data = response;
      setState(() {
        workingReq.addAll(response.data!);
      });
    } catch (error) {
      return BaseModel()..setException(ServerError.withError(error: error));
    }
    return BaseModel()..data = response;
  }

  Future<BaseModel<UpdateTiming>> updateHours() async {
    List hours = [];

    for (int i = 0; i < listDynamic.length; i++) {
      Map<String, dynamic> mapEducationData = {
        "start_time": listDynamic[i]["start_time"].toString().toLowerCase(),
        "end_time": listDynamic[i]["end_time"].toString().toLowerCase(),
      };
      hours.add(mapEducationData);
    }

    Map<String, dynamic> body = {
      "id": id.toString(),
      "period_list": hours,
      "status": isSwitched == true ? 1 : 0
    };
    UpdateTiming response;
    try {
      response = await RestClient(await RetroApi().dioData(context))
          .updateTimingRequest(body);
      doctorWorkingHoursFunction();
      if (mounted) {
        OslerToast.success(context, response.msg!);
      }
    } catch (error) {
      return BaseModel()..setException(ServerError.withError(error: error));
    }
    return BaseModel()..data = response;
  }
}

class SwitchScreen extends StatefulWidget {
  final int? checkStatus;
  const SwitchScreen(this.checkStatus, {super.key});

  @override
  State<SwitchScreen> createState() => _SwitchScreenState();
}

class _SwitchScreenState extends State<SwitchScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.checkStatus == 1) {
      setState(() {
        isSwitched = true;
      });
    } else {
      setState(() {
        isSwitched = false;
      });
    }
  }

  void toggleSwitch(bool value) {
    setState(() {
      isSwitched = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Text(
          getTranslated(context, AppString.schedule_day_status).toString(),
          style: textTheme.bodyMedium?.copyWith(
            color: AyurezeTheme.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        Transform.scale(
          scale: 1.1,
          child: Switch(
            onChanged: toggleSwitch,
            value: isSwitched,
            activeThumbColor: Colors.white,
            activeTrackColor: AyurezeTheme.healingGreenFill,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: AyurezeTheme.remoteRed50,
          ),
        ),
      ],
    );
  }
}
