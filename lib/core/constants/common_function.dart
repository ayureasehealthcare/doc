import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:doctro/core/constants/app_string.dart';
import 'package:doctro/core/localization/localization_constant.dart';
import 'package:doctro/core/navigator_key.dart';
import 'package:doctro/theme/ayureze_theme.dart';
import 'package:doctro/widgets/osler_loader.dart';
import 'package:doctro/widgets/osler_toast.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class CommonFunction {
  //Set Loader SignUp & Sign In
  static onLoading(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            padding: const EdgeInsets.all(AyurezeTheme.spaceXl),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                OslerLoader(),
                SizedBox(width: 20),
                Text(getTranslated(context, AppString.please_wait).toString()),
              ],
            ),
          ),
        );
      },
    );
  }

  static String? _lastToastMessage;
  static DateTime? _lastToastAt;

  /// Suppresses an identical message re-fired within [_toastDedupeWindow] of
  /// the last one. Several call sites construct a `ServerError` (which
  /// toasts as a side effect) from independent, near-simultaneous failed
  /// requests - e.g. two API calls timing out on the same screen load - so
  /// without this the same "Connection failed" text stacked one toast per
  /// failure instead of showing once.
  static const _toastDedupeWindow = Duration(seconds: 3);

  /// Clears the dedupe state between tests; each test otherwise inherits
  /// whatever the previous one last "toasted", since the state is static.
  @visibleForTesting
  static void resetToastDedupeForTesting() {
    _lastToastMessage = null;
    _lastToastAt = null;
  }

  static toastMessage(String msg) {
    final now = DateTime.now();
    if (_lastToastMessage == msg &&
        _lastToastAt != null &&
        now.difference(_lastToastAt!) < _toastDedupeWindow) {
      return;
    }
    _lastToastMessage = msg;
    _lastToastAt = now;

    if (_showInApp(msg)) return;
    Fluttertoast.showToast(
        msg: msg,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        //timeInSecForIosWeb: 1,
        backgroundColor: Colors.black54,
        textColor: Colors.white,
        fontSize: AyurezeTheme.textLg);
  }

  /// Shows [msg] as the app's own snackbar toast when the app's navigator
  /// is mounted. These toasts fire from API error handlers with no
  /// BuildContext; on web, Fluttertoast's fallback is an off-theme gradient
  /// banner. Returns false when there's no app to show it in.
  static bool _showInApp(String msg) {
    final context = navigatorKey.currentContext;
    if (context == null || ScaffoldMessenger.maybeOf(context) == null) {
      return false;
    }
    OslerToast.show(context: context, message: msg);
    return true;
  }

  static hideDialog(BuildContext context) {
    Navigator.pop(context);
  }

  //Check Internet Connection Data
  static Future<bool> checkNetwork() async {
    final connectivityResults = await Connectivity().checkConnectivity();
    // connectivity_plus 6.x returns a list (a device can be on Wi-Fi and VPN at
    // once), so treat any non-none transport as having a network path.
    final hasConnection = connectivityResults.any(
      (result) => result != ConnectivityResult.none,
    );
    if (hasConnection) {
      return true;
    }
    if (_showInApp("No Internet")) return false;
    Fluttertoast.showToast(
      msg: "No Internet",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
    return false;
  }
}
