import 'package:doctro/core/constants/app_string.dart';
import 'package:doctro/theme/app_motion.dart';
import 'package:doctro/theme/ayureze_theme.dart';
import 'package:doctro/core/constants/prefConstatnt.dart';
import 'package:doctro/core/constants/preferences.dart';
import 'package:doctro/core/localization/localization_constant.dart';
import 'package:doctro/models/CancelAppointment.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:doctro/widgets/modern_drawer.dart';
import 'package:doctro/widgets/osler_card.dart';
import 'package:doctro/widgets/osler_state_view.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:doctro/features/appointments/view_models/cancel_appointment_view_model.dart';

class CancelAppointmentScreen extends StatefulWidget {
  const CancelAppointmentScreen({super.key});

  @override
  State<CancelAppointmentScreen> createState() => _CancelAppointmentScreen();
}

class _CancelAppointmentScreen extends State<CancelAppointmentScreen> {
  //Set Height/Width Using MediaQuery
  late double width;
  late double height;

  //Set Open Drawer
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    width = MediaQuery.of(context).size.width;
    height = MediaQuery.of(context).size.height;

    return ChangeNotifierProvider<CancelAppointmentViewModel>(
      create: (_) => CancelAppointmentViewModel(context),
      child: Consumer<CancelAppointmentViewModel>(
          builder: (context, viewModel, child) {
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            Navigator.pushNamedAndRemoveUntil(
                context, 'loginHome', (route) => false);
          },
          child: RefreshIndicator(
            onRefresh: () => viewModel.cancelAppointmentRequest(context),
            child: Scaffold(
              backgroundColor: AyurezeTheme.canvas,
              key: _scaffoldKey,
              drawer: const ModernDrawer(),
              appBar: PreferredSize(
                  preferredSize: Size(20, 150),
                  child: SafeArea(
                      top: true,
                      child: Column(children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              margin: EdgeInsets.only(
                                  left: width * 0.06,
                                  right: width * 0.06,
                                  top: height * 0.01),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
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
                                                    .cancel_appointment_heading)
                                            .toString(),
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineMedium
                                            ?.copyWith(
                                                color:
                                                    AyurezeTheme.textPrimary),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    margin: EdgeInsets.only(),
                                    child: IconButton(
                                      onPressed: () {
                                        _scaffoldKey.currentState!.openDrawer();
                                      },
                                      icon: SvgPicture.asset(
                                        "assets/icons/dMenuBar.svg",
                                        height: 16.0,
                                        fit: BoxFit.fill,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        Container(
                          margin: EdgeInsets.only(top: height * 0.01),
                          padding: const EdgeInsets.all(AyurezeTheme.spaceMd),
                          child: Card(
                            color: AyurezeTheme.surface,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AyurezeTheme.radius2xl),
                            ),
                            child: Container(
                                alignment: AlignmentDirectional.center,
                                margin: EdgeInsets.only(
                                    left: width * 0.05, right: width * 0.05),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      // height: height * 0.06,
                                      width: width * 0.7,
                                      child: TextField(
                                        controller: viewModel.searchController,
                                        decoration: InputDecoration(
                                          border: InputBorder.none,
                                          hintText: getTranslated(
                                                  context,
                                                  AppString
                                                      .search_cancel_appointment)
                                              .toString(),
                                          hintStyle: Theme.of(context)
                                              .textTheme
                                              .bodyLarge
                                              ?.copyWith(
                                                color: AyurezeTheme
                                                    .textSecondary
                                                    .withValues(alpha: 0.5),
                                              ),
                                        ),
                                        textAlign: TextAlign.left,
                                      ),
                                    ),
                                    SvgPicture.asset(
                                      'assets/icons/dSearch.svg',
                                      height: 20,
                                    ),
                                  ],
                                )),
                          ),
                        ),
                      ]))),
              body: viewModel.isLoading
                  ? const OslerLoadingView()
                  : GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        FocusScope.of(context).requestFocus(FocusNode());
                      },
                      child: SingleChildScrollView(
                        physics: AlwaysScrollableScrollPhysics(),
                        child: Center(
                          child: Column(
                            children: [
                              viewModel.cancelAppointmentReq.isEmpty
                                  ? Container(
                                      margin:
                                          EdgeInsets.only(top: height * 0.2),
                                      child: Image.asset(
                                          "assets/images/no-data.png"),
                                    )
                                  : Container(
                                      color: AyurezeTheme.surfaceMuted,
                                      width: width * 1.0,
                                      padding: const EdgeInsets.all(
                                          AyurezeTheme.spaceLg),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Container(
                                            margin: EdgeInsets.symmetric(
                                                horizontal: width * 0.04),
                                            child: Text(
                                              getTranslated(
                                                      context,
                                                      AppString
                                                          .cancel_appointment_heading)
                                                  .toString(),
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium
                                                  ?.copyWith(
                                                      color: AyurezeTheme
                                                          .textPrimary),
                                            ),
                                          ),
                                          Text(
                                            "${getTranslated(context, AppString.cancel_appointment_length)} ${viewModel.cancelAppointmentReq.length} ",
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                    color: AyurezeTheme
                                                        .forestDeep),
                                          ),
                                        ],
                                      ),
                                    ),
                              viewModel.searchController.text.isNotEmpty
                                  ? viewModel.searchResult.isNotEmpty
                                      ? ListView.builder(
                                          scrollDirection: Axis.vertical,
                                          shrinkWrap: true,
                                          physics:
                                              NeverScrollableScrollPhysics(),
                                          itemCount:
                                              viewModel.searchResult.length,
                                          itemBuilder: (context, i) {
                                            return _buildAppointmentCard(
                                                viewModel.searchResult[i],
                                                i % 8);
                                          },
                                        )
                                      : SizedBox(
                                          height: height / 1.5,
                                          child: Center(
                                              child: Container(
                                            margin: EdgeInsets.only(
                                                top: height * 0.02),
                                            child: Text(getTranslated(context,
                                                    AppString.result_not_found)
                                                .toString()),
                                          )))
                                  : ListView.builder(
                                      itemCount:
                                          viewModel.cancelAppointmentReq.length,
                                      physics: NeverScrollableScrollPhysics(),
                                      shrinkWrap: true,
                                      reverse: true,
                                      scrollDirection: Axis.vertical,
                                      itemBuilder: (context, index) {
                                        return _buildAppointmentCard(
                                            viewModel
                                                .cancelAppointmentReq[index],
                                            index % 8);
                                      }),
                            ],
                          ),
                        ),
                      ),
                    ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildAppointmentCard(AppointmentCancel appointment, int index) {
    final card = Column(
      children: [
        Row(
          children: [
            Column(
              children: [
                Container(
                  margin:
                      EdgeInsets.only(left: width * 0.06, right: width * 0.02),
                  child: Text(
                    DateUtil().formattedDate(DateTime.parse(appointment.date!)),
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: AyurezeTheme.textPrimary),
                  ),
                ),
                Container(
                  margin:
                      EdgeInsets.only(left: width * 0.06, right: width * 0.02),
                  child: Text(
                    appointment.time!,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: AyurezeTheme.textPrimary),
                  ),
                )
              ],
            ),
            Expanded(
              child: Container(
                  margin:
                      EdgeInsets.only(left: width * 0.02, right: width * 0.02),
                  height: 100,
                  child: OslerCard(
                      padding: EdgeInsets.zero,
                      child: Column(children: <Widget>[
                        ListTile(
                          isThreeLine: true,
                          leading: SizedBox(
                            height: 70,
                            width: 60,
                            child: ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(AyurezeTheme.radiusMd),
                              child: Container(
                                  decoration: BoxDecoration(
                                      image: DecorationImage(
                                          fit: BoxFit.fitHeight,
                                          image: NetworkImage(
                                              appointment.user!.fullImage!)))),
                            ),
                          ),
                          title: Container(
                            alignment: AlignmentDirectional.topStart,
                            margin: EdgeInsets.only(
                              top: height * 0.01,
                            ),
                            child: Text(
                              appointment.patientName!,
                              style: Theme.of(context).textTheme.titleMedium,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          trailing: Text(
                            (SharedPreferenceHelper.getStringOrNull(
                                        Preferences.currency_symbol) ??
                                    '') +
                                appointment.amount.toString(),
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(color: AyurezeTheme.textSecondary),
                          ),
                          subtitle: Column(
                            children: <Widget>[
                              Container(
                                  alignment: AlignmentDirectional.topStart,
                                  child: Text(
                                    "${getTranslated(context, AppString.home_age_data)}:${appointment.age}",
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                            color: AyurezeTheme.textSecondary),
                                  )),
                              Container(
                                width: width * 0.6,
                                alignment: AlignmentDirectional.topStart,
                                child: Text(
                                  appointment.patientAddress!,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                          color: AyurezeTheme.textSecondary),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                ),
                              ),
                            ],
                          ),
                        )
                      ]))),
            ),
          ],
        ),
      ],
    );

    return ScreenEntrance(index: index, child: card);
  }
}

class DateUtil {
  static const DATE_FORMAT = 'dd-MM-yyyy';

  String formattedDate(DateTime dateTime) {
    return DateFormat(DATE_FORMAT).format(dateTime);
  }
}
