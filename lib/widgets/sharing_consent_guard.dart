import 'package:flutter/material.dart';

import 'package:doctro/core/constants/pref_constant.dart';
import 'package:doctro/core/constants/preferences.dart';
import 'package:doctro/models/sharing_consent.dart';
import 'package:doctro/services/astra_api_service.dart';
import 'package:doctro/theme/ayureze_theme.dart';
import 'package:doctro/widgets/osler_alert.dart';

typedef SharingConsentLoader = Future<SharingConsent> Function(
    String doctorId, String patientId);

/// The one place this app checks doctor-sharing consent before showing
/// patient data from the companion case/journey endpoints.
///
/// Wrap a screen body in it. It fetches consent for the signed-in doctor
/// and [patientId], then:
/// - shows a "limited sharing" banner above [child] unless consent is
///   affirmatively [SharingConsent.full] - while loading, when it is
///   limited, and when it is unknown. The screen itself stays visible;
///   this app should never hide the record outright, nor silently assume
///   full access.
/// - publishes the result to descendants through [SharingConsentScope],
///   so a panel showing data beyond the consultation (e.g. the wellness
///   log) can withhold itself without a second request.
///
/// Lays out like a Scaffold body: give it bounded height.
class SharingConsentGuard extends StatefulWidget {
  final String? patientId;

  /// Defaults to the signed-in doctor ([Preferences.doctorId]).
  final String? doctorId;

  /// Defaults to [AstraApiService.getSharingConsent]; injectable for tests.
  final SharingConsentLoader? loader;

  final Widget child;

  const SharingConsentGuard({
    super.key,
    required this.patientId,
    required this.child,
    this.doctorId,
    this.loader,
  });

  @override
  State<SharingConsentGuard> createState() => _SharingConsentGuardState();
}

class _SharingConsentGuardState extends State<SharingConsentGuard> {
  /// null while the request is in flight.
  SharingConsent? _consent;
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(SharingConsentGuard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.patientId != widget.patientId ||
        oldWidget.doctorId != widget.doctorId) {
      _load();
    }
  }

  Future<void> _load() async {
    final requestId = ++_requestId;
    // No setState: called from initState/didUpdateWidget, which both
    // build next anyway.
    _consent = null;

    final doctorId = widget.doctorId ??
        SharedPreferenceHelper.getStringOrNull(Preferences.doctorId);
    final patientId = widget.patientId;

    SharingConsent result;
    if (doctorId == null ||
        doctorId.isEmpty ||
        patientId == null ||
        patientId.isEmpty) {
      // Can't even ask - that is a "don't know", not a "yes".
      result = SharingConsent.unknown;
    } else {
      try {
        final loader = widget.loader ?? AstraApiService().getSharingConsent;
        result = await loader(doctorId, patientId);
      } catch (_) {
        result = SharingConsent.unknown;
      }
    }

    // A newer request (patient changed) supersedes this one.
    if (!mounted || requestId != _requestId) return;
    setState(() => _consent = result);
  }

  @override
  Widget build(BuildContext context) {
    final consent = _consent;
    return SharingConsentScope(
      consent: consent ?? SharingConsent.unknown,
      child: Column(
        children: [
          if (consent == null || !consent.isFull)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AyurezeTheme.spaceLg,
                  AyurezeTheme.spaceSm,
                  AyurezeTheme.spaceLg,
                  AyurezeTheme.spaceXs),
              child: SharingConsentBanner(consent: consent),
            ),
          Expanded(child: widget.child),
        ],
      ),
    );
  }
}

/// The banner [SharingConsentGuard] shows. [consent] null means "still
/// checking".
class SharingConsentBanner extends StatelessWidget {
  final SharingConsent? consent;

  const SharingConsentBanner({super.key, required this.consent});

  static const limitedTitle = 'Patient has limited sharing for this record';

  @override
  Widget build(BuildContext context) {
    switch (consent) {
      case null:
        return const OslerAlert(
          title: 'Checking what the patient has shared…',
          type: OslerAlertType.info,
        );
      case SharingConsent.limited:
        return const OslerAlert(
          title: limitedTitle,
          message: 'They haven\'t turned on full-record sharing with you. '
              'Only what they sent for this consultation is shown.',
          type: OslerAlertType.warning,
        );
      case SharingConsent.unknown:
        return const OslerAlert(
          title: limitedTitle,
          message: 'Their sharing preference couldn\'t be confirmed, so '
              'this record is treated as limited.',
          type: OslerAlertType.warning,
        );
      case SharingConsent.full:
        return const SizedBox.shrink();
    }
  }
}

/// Exposes the nearest [SharingConsentGuard]'s answer to descendants.
class SharingConsentScope extends InheritedWidget {
  final SharingConsent consent;

  const SharingConsentScope({
    super.key,
    required this.consent,
    required super.child,
  });

  /// The consent in effect at [context]. With no guard above, this is
  /// [SharingConsent.unknown]: data gated on consent stays hidden rather
  /// than defaulting open.
  static SharingConsent of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<SharingConsentScope>()
          ?.consent ??
      SharingConsent.unknown;

  @override
  bool updateShouldNotify(SharingConsentScope oldWidget) =>
      consent != oldWidget.consent;
}
