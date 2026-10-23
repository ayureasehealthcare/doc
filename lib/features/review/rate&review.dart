import 'dart:async';

import 'package:doctro/core/constants/app_icons.dart';
import 'package:doctro/core/constants/app_string.dart';
import 'package:doctro/theme/ayureze_theme.dart';
import 'package:doctro/widgets/glass_surface.dart';
import 'package:doctro/core/constants/prefConstatnt.dart';
import 'package:doctro/core/constants/preferences.dart';
import 'package:doctro/core/localization/localization_constant.dart';
import 'package:doctro/models/review.dart';
import 'package:doctro/network/api_header.dart';
import 'package:doctro/network/base_model.dart';
import 'package:doctro/network/network_api.dart';
import 'package:doctro/network/server_error.dart';
import 'package:doctro/widgets/modern_drawer.dart';
import 'package:doctro/widgets/osler_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';

class RateAndReviewRoutesScreen extends StatefulWidget {
  const RateAndReviewRoutesScreen({super.key});

  @override
  _RateAndReviewRoutesScreenState createState() =>
      _RateAndReviewRoutesScreenState();
}

class _RateAndReviewRoutesScreenState extends State<RateAndReviewRoutesScreen>
    with SingleTickerProviderStateMixin {
  Future? reviewDatas;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  late double width;
  late double height;

  List<ReviewData> reviewData = [];

  String? dName;
  String? dFullImage;
  String? phone;
  int? subscription;

  final TextEditingController _search = TextEditingController();
  final List<ReviewData> _searchResult = [];
  final List<ReviewData> _userReview = [];

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _animController.forward();

    Future.delayed(Duration.zero, () {
      dName = SharedPreferenceHelper.getString(Preferences.name);
      dFullImage = SharedPreferenceHelper.getString(Preferences.image);
      phone = SharedPreferenceHelper.getString(Preferences.phone_no);
      subscription =
          SharedPreferenceHelper.getInt(Preferences.subscription_status);
      reviewDatas = reviewRequest();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    width = MediaQuery.of(context).size.width;
    height = MediaQuery.of(context).size.height;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AyurezeTheme.canvas,
      drawer: const ModernDrawer(),
      appBar: AppBar(
        backgroundColor: AyurezeTheme.canvas,
        elevation: 0,
        leading: IconButton(
          icon: HugeIcon(
            icon: AppIcons.menu,
            color: AyurezeTheme.iconPrimary,
          ),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: Text(
          getTranslated(context, AppString.review_heading).toString(),
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: AyurezeTheme.textPrimary,
          ),
        ),
      ),
      body: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          Navigator.pushNamedAndRemoveUntil(
              context, 'loginHome', (route) => false);
        },
        child: FutureBuilder(
          future: reviewDatas,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return Center(
                child:
                    CircularProgressIndicator(color: AyurezeTheme.iconPrimary),
              );
            }

            final activeSource =
                _search.text.isNotEmpty ? _searchResult : reviewData;

            return RefreshIndicator(
              color: AyurezeTheme.iconPrimary,
              onRefresh: reviewRequest,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  FocusScope.of(context).unfocus();
                },
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: AyurezeTheme.screenPadding,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHero(context),
                            const SizedBox(height: 18),
                            _buildSearchCard(context),
                            const SizedBox(height: 18),
                            if (activeSource.isEmpty)
                              _buildEmptyState(context)
                            else
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: activeSource.length,
                                itemBuilder: (context, index) {
                                  return _buildReviewTile(
                                      context, activeSource[index]);
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHero(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
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
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AyurezeTheme.radiusPill),
            ),
            child: Text(
              "Patient Feedback",
              style: textTheme.labelSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            "Ratings & Reviews",
            style: textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              height: 1.05,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Read patient reviews, ratings and consultation feedback.",
            style: textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.85),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchCard(BuildContext context) {
    return GlassSurface(
      padding: const EdgeInsets.symmetric(
          horizontal: AyurezeTheme.spaceXl, vertical: AyurezeTheme.spaceSm),
      child: TextField(
        controller: _search,
        decoration: InputDecoration(
          border: InputBorder.none,
          filled: false,
          hintText: getTranslated(context, AppString.review_search).toString(),
          hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AyurezeTheme.textSecondary,
              ),
          suffixIcon: HugeIcon(
            icon: AppIcons.search,
            color: AyurezeTheme.iconPrimary,
          ),
        ),
        onChanged: onSearchTextChanged,
      ),
    );
  }

  Widget _buildReviewTile(BuildContext context, ReviewData item) {
    final textTheme = Theme.of(context).textTheme;
    String createDate = item.createdAt != null
        ? DateUtil().formattedDate(DateTime.parse(item.createdAt!))
        : "--";

    return OslerCard(
      margin: const EdgeInsets.only(bottom: AyurezeTheme.spaceMd),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AyurezeTheme.radiusMd),
            child:
                item.user?.fullImage != null && item.user!.fullImage!.isNotEmpty
                    ? Image.network(
                        item.user!.fullImage!,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 56,
                          height: 56,
                          color: AyurezeTheme.surfaceMuted,
                          child: HugeIcon(
                              icon: AppIcons.profile,
                              color: AyurezeTheme.textSecondary),
                        ),
                      )
                    : Container(
                        width: 56,
                        height: 56,
                        color: AyurezeTheme.surfaceMuted,
                        child: HugeIcon(
                            icon: AppIcons.profile,
                            color: AyurezeTheme.textSecondary),
                      ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item.user?.name ?? "",
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AyurezeTheme.textPrimary,
                        ),
                      ),
                    ),
                    RatingBarIndicator(
                      rating: (item.rate ?? 0).toDouble(),
                      itemBuilder: (context, index) => HugeIcon(
                        icon: HugeIcons.strokeRoundedStar,
                        color: AyurezeTheme.sunshineYellow50,
                      ),
                      itemCount: 5,
                      itemSize: 18.0,
                      direction: Axis.horizontal,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  item.review ?? "",
                  style: textTheme.bodyMedium?.copyWith(
                    color: AyurezeTheme.textSecondary,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  createDate,
                  style: textTheme.bodySmall?.copyWith(
                    color: AyurezeTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return GlassSurface(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
          vertical: AyurezeTheme.space3xl + AyurezeTheme.spaceSm),
      child: Column(
        children: [
          Image.asset("assets/images/no-data.png", height: 96),
          const SizedBox(height: 12),
          Text(
            _search.text.isNotEmpty
                ? getTranslated(context, AppString.result_not_found).toString()
                : "No reviews yet.",
            style: textTheme.bodyMedium?.copyWith(
              color: AyurezeTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Future<BaseModel<Review>> reviewRequest() async {
    Review response;
    try {
      reviewData.clear();
      _userReview.clear();
      response =
          await RestClient(await RetroApi().dioData(context)).reviewRequest();
      if (!mounted) return BaseModel()..data = response;
      setState(() {
        reviewData.addAll(response.data!);
        _userReview.addAll(response.data!);
      });
    } catch (error) {
      return BaseModel()..setException(ServerError.withError(error: error));
    }
    return BaseModel()..data = response;
  }

  onSearchTextChanged(String text) async {
    _searchResult.clear();
    if (text.isEmpty) {
      setState(() {});
      return;
    }

    for (var userName in _userReview) {
      if ((userName.user?.name ?? "")
          .toLowerCase()
          .contains(text.toLowerCase())) {
        _searchResult.add(userName);
      }
    }

    setState(() {});
  }
}

class DateUtil {
  static const DATE_FORMAT = 'dd-MM-yyyy';

  String formattedDate(DateTime dateTime) {
    return DateFormat(DATE_FORMAT).format(dateTime);
  }
}
