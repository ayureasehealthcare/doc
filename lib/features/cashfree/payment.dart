import 'dart:async';
import 'package:doctro/core/constants/app_icons.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:doctro/widgets/glass_surface.dart';
import 'package:doctro/widgets/osler_hero.dart';
import 'package:doctro/core/constants/app_string.dart';
import 'package:doctro/theme/ayureze_theme.dart';
import 'package:doctro/core/constants/common_function.dart';
import 'package:doctro/core/constants/prefConstatnt.dart';
import 'package:doctro/core/constants/preferences.dart';
import 'package:doctro/core/localization/localization_constant.dart';
import 'package:doctro/models/payment.dart';
import 'package:doctro/network/base_model.dart';
import 'package:doctro/features/authentication/SignIn.dart';
import 'package:doctro/widgets/modern_drawer.dart';
import 'package:flutter/material.dart';
import 'package:doctro/services/astra_api_service.dart';
import 'package:doctro/widgets/osler_button.dart';
import 'package:doctro/widgets/osler_toast.dart';
import 'package:flutter_svg/svg.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  _PaymentScreen createState() => _PaymentScreen();
}

class _PaymentScreen extends State<PaymentScreen> {
  late double width;
  late double height;

  final _scaffoldKey = GlobalKey<ScaffoldState>();
  Future? payments;

  static double sum = 0;
  double availableBalance = 0.0;
  double withdrawnAmount = 0.0;
  bool isWithdrawing = false;

  String? dName;
  String? dFullImage;
  String? phone;
  int? subscription;

  final TextEditingController _search = TextEditingController();
  final List<Payments> _searchResult = [];
  final List<Payments> _userPayment = [];

  @override
  void initState() {
    super.initState();

    Future.delayed(Duration.zero, () {
      payments = paymentsFunction();
      dName = SharedPreferenceHelper.getString(Preferences.name);
      dFullImage = SharedPreferenceHelper.getString(Preferences.image);
      phone = SharedPreferenceHelper.getString(Preferences.phone_no);
      subscription =
          SharedPreferenceHelper.getInt(Preferences.subscription_status);
      loadWalletStats();
    });
  }

  bool _paymentRequest = false;
  final List<Payments> paymentsRequest = [];

  @override
  Widget build(BuildContext context) {
    width = MediaQuery.of(context).size.width;
    height = MediaQuery.of(context).size.height;

    return PopScope(
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
        onRefresh: paymentsFunction,
        color: AyurezeTheme.forestDeep,
        child: Scaffold(
          key: _scaffoldKey,
          backgroundColor: AyurezeTheme.canvas,
          drawer: const ModernDrawer(),
          appBar: AppBar(
            backgroundColor: AyurezeTheme.canvas,
            title: Text(
              getTranslated(context, AppString.payment_title).toString(),
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
                  colorFilter: ColorFilter.mode(
                      AyurezeTheme.forestDeep, BlendMode.srcIn),
                ),
              ),
            ],
          ),
          body: FutureBuilder(
            future: payments,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return Center(
                  child: CircularProgressIndicator(
                    color: AyurezeTheme.forestDeep,
                  ),
                );
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
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      FocusScope.of(context).requestFocus(FocusNode());
                    },
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: AyurezeTheme.screenPadding,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHero(),
                          const SizedBox(height: 18),
                          _buildWalletCard(),
                          const SizedBox(height: 18),
                          _buildSearchCard(),
                          const SizedBox(height: 18),
                          if (paymentsRequest.isEmpty)
                            _buildEmptyState()
                          else ...[
                            _buildHeaderSummary(),
                            const SizedBox(height: 12),
                            ..._buildPaymentItems(),
                            if (!_searching() &&
                                !_paymentRequest &&
                                paymentsRequest.length > 5) ...[
                              const SizedBox(height: 10),
                              _buildViewAllCard(),
                            ],
                            const SizedBox(height: 14),
                            _buildTotalBar(),
                          ],
                        ],
                      ),
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
      eyebrow: 'Billing overview',
      title: 'Track patient payments in one calm ledger.',
      subtitle:
          'Search the ledger, review incoming totals, and keep the financial side of the clinic tidy.',
    );
  }

  Widget _buildSearchCard() {
    return GlassSurface(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _search,
              decoration: InputDecoration(
                border: InputBorder.none,
                filled: false,
                hintText:
                    getTranslated(context, AppString.payment_search).toString(),
                hintStyle: TextStyle(color: AyurezeTheme.textSecondary),
              ),
              onChanged: onSearchTextChanged,
            ),
          ),
          SvgPicture.asset(
            'assets/icons/dSearch.svg',
            height: 20,
            colorFilter:
                ColorFilter.mode(AyurezeTheme.forestDeep, BlendMode.srcIn),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSummary() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          getTranslated(context, AppString.payment_patient_list).toString(),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: AyurezeTheme.textPrimary,
              ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AyurezeTheme.spaceSm, vertical: AyurezeTheme.spaceXs),
          decoration: BoxDecoration(
            color: AyurezeTheme.lightGreenSoft,
            borderRadius: BorderRadius.circular(AyurezeTheme.radiusPill),
          ),
          child: Text(
            "${getTranslated(context, AppString.payment_total).toString()} ${paymentsRequest.length}",
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AyurezeTheme.forestDeep,
                ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildPaymentItems() {
    final List<Payments> source = _searching()
        ? _searchResult
        : paymentsRequest
            .take(_paymentRequest ? paymentsRequest.length : 5)
            .toList();

    if (_searching() && source.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.only(top: 18),
          child: Center(
            child: Text(
              getTranslated(context, AppString.result_not_found).toString(),
            ),
          ),
        ),
      ];
    }

    return source.map((payment) => _buildPaymentRow(payment)).toList();
  }

  Widget _buildPaymentRow(Payments payment) {
    return Container(
      margin: const EdgeInsets.only(bottom: AyurezeTheme.spaceMd),
      padding: const EdgeInsets.all(AyurezeTheme.spaceLg),
      decoration: AyurezeTheme.panelDecoration(),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AyurezeTheme.surfaceMuted,
              borderRadius: BorderRadius.circular(AyurezeTheme.radiusMd),
            ),
            child: HugeIcon(
              icon: HugeIcons.strokeRoundedMoney03,
              color: AyurezeTheme.forestDeep,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payment.user?.name ?? "",
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AyurezeTheme.textPrimary,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Completed payment",
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AyurezeTheme.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          Text(
            "${SharedPreferenceHelper.getString(Preferences.currency_symbol)}${payment.amount}",
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AyurezeTheme.forestDeep,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewAllCard() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _paymentRequest = true;
        });
      },
      child: GlassSurface(
        padding: const EdgeInsets.all(AyurezeTheme.spaceLg),
        child: Row(
          children: [
            Expanded(
              child: Text(
                getTranslated(context, AppString.view_all_payment).toString(),
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
                  ColorFilter.mode(AyurezeTheme.forestDeep, BlendMode.srcIn),
            ),
            const SizedBox(width: 10),
            Text(
              "${paymentsRequest.length}",
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AyurezeTheme.forestDeep,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
          horizontal: AyurezeTheme.spaceXl, vertical: AyurezeTheme.spaceXl),
      decoration: BoxDecoration(
        color: AyurezeTheme.forestDeep,
        borderRadius: BorderRadius.circular(AyurezeTheme.radiusXl),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            getTranslated(context, AppString.payment_rs_total).toString(),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
          ),
          Text(
            "${SharedPreferenceHelper.getString(Preferences.currency_symbol)}$sum",
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return GlassSurface(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36),
      child: Column(
        children: [
          Image.asset("assets/images/no-data.png", height: 88),
          const SizedBox(height: 10),
          Text(
            getTranslated(context, AppString.no_user).toString(),
            style: TextStyle(color: AyurezeTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  bool _searching() => _search.text.isNotEmpty;

  Future<void> logoutUser() async {
    await SharedPreferenceHelper.clearPref();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (BuildContext context) => SignIn()),
      ModalRoute.withName('SignIn'),
    );
  }

  // The legacy itemized-payments endpoint (Apis.payment) is permanently
  // dead - confirmed 404 on the real backend - and there is no replacement:
  // the real backend's doctor-facing finance route
  // (/api/v1/finance/wallet/summary, used by loadWalletStats() for the
  // wallet card above) only returns scalar totals, not a per-consultation
  // transaction list. Rather than keep attempting a network call that can
  // never succeed, this stays an empty list until the backend exposes a
  // real per-transaction endpoint for doctors.
  Future<BaseModel<Payment>> paymentsFunction() async {
    paymentsRequest.clear();
    _userPayment.clear();
    if (mounted) {
      setState(() {
        sum = 0;
      });
    }
    return BaseModel()..data = Payment();
  }

  showAlertDialog(BuildContext context) {
    Widget cancel = TextButton(
      child: Text(
        getTranslated(context, AppString.cancel_button).toString(),
        style: TextStyle(color: AyurezeTheme.textSecondary),
      ),
      onPressed: () {
        Navigator.pop(context);
      },
    );
    Widget okButton = TextButton(
      child: Text(
        getTranslated(context, AppString.logout_button).toString(),
        style: TextStyle(color: AyurezeTheme.textSecondary),
      ),
      onPressed: () {
        CommonFunction.checkNetwork().then((value) {
          if (value == true) {
            logoutUser();
          }
        });
      },
    );

    AlertDialog alert = AlertDialog(
      content: Text(
        getTranslated(context, AppString.are_you_sure_logout).toString(),
      ),
      actions: [cancel, okButton],
    );
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  onSearchTextChanged(String text) async {
    _searchResult.clear();
    if (text.isEmpty) {
      setState(() {});
      return;
    }

    for (var payment in _userPayment) {
      if ((payment.user?.name ?? "")
          .toLowerCase()
          .contains(text.toLowerCase())) {
        _searchResult.add(payment);
      }
    }
    setState(() {});
  }

  Future<void> loadWalletStats() async {
    try {
      final String doctorId =
          SharedPreferenceHelper.getString(Preferences.doctorId);
      if (doctorId.isNotEmpty) {
        final stats = await AstraApiService().getDashboardStats(doctorId);
        if (!mounted) return;
        setState(() {
          availableBalance =
              double.tryParse(stats['available_balance'].toString()) ?? 0.0;
          withdrawnAmount =
              double.tryParse(stats['withdrawn_amount'].toString()) ?? 0.0;
        });
      }
    } catch (_) {
      // Stats are supplementary; a parse failure must not block the payout screen.
    }
  }

  Widget _buildWalletCard() {
    return GlassSurface(
      width: double.infinity,
      radius: 22,
      padding: const EdgeInsets.all(AyurezeTheme.spaceXl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Ayurease Wallet",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AyurezeTheme.textPrimary,
                    ),
              ),
              HugeIcon(
                  icon: AppIcons.wallet,
                  color: AyurezeTheme.forestDeep,
                  size: 24),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "Available Balance",
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AyurezeTheme.textSecondary,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            "${SharedPreferenceHelper.getString(Preferences.currency_symbol)}${availableBalance.toStringAsFixed(2)}",
            style:
                AyurezeTheme.font(28, FontWeight.w800, AyurezeTheme.forestDeep),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OslerButton(
                  text: "Request Payout",
                  onPressed: availableBalance <= 0
                      ? null
                      : () => _showWithdrawDialog(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool isValidUpi(String input) {
    final reg = RegExp(r'^[a-zA-Z0-9.\-_]{2,256}@[a-zA-Z]{2,64}$');
    return reg.hasMatch(input);
  }

  void _showWithdrawDialog() {
    // The builders below shadow `context` with the dialog's own, and the modal
    // is popped before the request returns. Toasts must therefore target the
    // screen's context: the dialog's is already unmounted by then, so guarding
    // on it would silently swallow every message.
    final BuildContext parentContext = context;
    final TextEditingController amountController =
        TextEditingController(text: availableBalance.toInt().toString());
    final TextEditingController upiController = TextEditingController();
    final TextEditingController accController = TextEditingController();
    final TextEditingController ifscController = TextEditingController();
    String payoutMode = "UPI"; // UPI or Bank

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final int amount = int.tryParse(amountController.text) ?? 0;
            final bool isAmountValid =
                amount >= 100 && amount <= availableBalance;

            bool isFormValid = false;
            if (payoutMode == "UPI") {
              isFormValid =
                  isAmountValid && isValidUpi(upiController.text.trim());
            } else {
              isFormValid = isAmountValid &&
                  accController.text.trim().isNotEmpty &&
                  ifscController.text.trim().isNotEmpty;
            }

            return AlertDialog(
              backgroundColor: AyurezeTheme.surface,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AyurezeTheme.radiusXl)),
              title: Text(
                "Request Payout",
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AyurezeTheme.textPrimary),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Submit a withdrawal request for your earnings. An admin reviews and pays it out to your UPI ID or bank account - this isn't instant.",
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AyurezeTheme.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      onChanged: (val) => setDialogState(() {}),
                      decoration: InputDecoration(
                        labelText: "Amount to Withdraw (Min ₹100)",
                        prefixText: SharedPreferenceHelper.getString(
                            Preferences.currency_symbol),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<String>(
                            title: Text("UPI",
                                style: Theme.of(context).textTheme.bodySmall),
                            value: "UPI",
                            groupValue: payoutMode,
                            contentPadding: EdgeInsets.zero,
                            onChanged: (val) {
                              setDialogState(() => payoutMode = val!);
                            },
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<String>(
                            title: Text("Bank",
                                style: Theme.of(context).textTheme.bodySmall),
                            value: "Bank",
                            groupValue: payoutMode,
                            contentPadding: EdgeInsets.zero,
                            onChanged: (val) {
                              setDialogState(() => payoutMode = val!);
                            },
                          ),
                        ),
                      ],
                    ),
                    if (payoutMode == "UPI") ...[
                      TextField(
                        controller: upiController,
                        onChanged: (val) => setDialogState(() {}),
                        decoration: const InputDecoration(
                          labelText: "UPI ID (VPA)",
                          hintText: "username@upi",
                        ),
                      ),
                    ] else ...[
                      TextField(
                        controller: accController,
                        keyboardType: TextInputType.number,
                        onChanged: (val) => setDialogState(() {}),
                        decoration:
                            const InputDecoration(labelText: "Account Number"),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: ifscController,
                        onChanged: (val) => setDialogState(() {}),
                        decoration:
                            const InputDecoration(labelText: "IFSC Code"),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Cancel",
                      style: TextStyle(color: AyurezeTheme.textSecondary)),
                ),
                TextButton(
                  onPressed: (!isFormValid || isWithdrawing)
                      ? null
                      : () async {
                          Map<String, dynamic> payoutDetails = {
                            "name": dName ?? "Doctor",
                            "mode": payoutMode == "UPI" ? "UPI" : "IMPS",
                          };

                          if (payoutMode == "UPI") {
                            payoutDetails["vpa"] = upiController.text.trim();
                          } else {
                            payoutDetails["account_number"] =
                                accController.text.trim();
                            payoutDetails["ifsc"] = ifscController.text.trim();
                          }

                          setDialogState(() => isWithdrawing = true);
                          Navigator.pop(context); // close modal

                          try {
                            final String doctorId =
                                SharedPreferenceHelper.getString(
                                    Preferences.doctorId);
                            final response = await AstraApiService()
                                .requestWithdraw(
                                    doctorId, amount, payoutDetails);

                            if (response["success"] == true) {
                              if (parentContext.mounted) {
                                OslerToast.success(
                                    parentContext,
                                    response["message"] ??
                                        "Withdrawal request submitted for admin review.");
                              }
                            } else {
                              if (parentContext.mounted) {
                                OslerToast.error(parentContext,
                                    response["error"] ?? "Withdrawal failed.");
                              }
                            }
                          } catch (e) {
                            if (parentContext.mounted) {
                              OslerToast.error(
                                  parentContext, "Failed to connect to API.");
                            }
                          } finally {
                            setState(() => isWithdrawing = false);
                            loadWalletStats();
                          }
                        },
                  child: Text(
                    "Submit Request",
                    style: TextStyle(
                        color: isFormValid && !isWithdrawing
                            ? AyurezeTheme.forestDeep
                            : AyurezeTheme.textSecondary,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
