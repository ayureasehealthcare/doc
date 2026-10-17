import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';

import 'package:doctro/core/constants/prefConstatnt.dart';
import 'package:doctro/core/constants/preferences.dart';
import 'package:doctro/models/autopilot_action.dart';
import 'package:doctro/services/astra_api_service.dart';
import 'package:doctro/theme/ayureze_theme.dart';
import 'package:doctro/widgets/content_origin_badge.dart';
import 'package:doctro/widgets/osler_button.dart';
import 'package:doctro/widgets/osler_card.dart';
import 'package:doctro/widgets/osler_state_view.dart';
import 'package:doctro/widgets/osler_tag.dart';
import 'package:doctro/widgets/osler_toast.dart';

typedef PendingActionsLoader = Future<List<AutopilotAction>> Function(
    String doctorId);
typedef AutopilotActionResolver = Future<bool> Function(String actionId);

/// Proactive items Astra has raised for this doctor - flagged care gaps,
/// suggested follow-ups - each to acknowledge or dismiss.
///
/// Every item is Astra's, and labelled as such. Until the astra endpoints
/// exist the service returns an empty list, so this shows the empty state
/// and needs no change to light up once they do.
class ReviewQueueScreen extends StatefulWidget {
  static const routeName = 'reviewQueue';

  /// Defaults to the signed-in doctor ([Preferences.doctorId]).
  final String? doctorId;

  /// Default to [AstraApiService]; injectable for tests.
  final PendingActionsLoader? loader;
  final AutopilotActionResolver? onAcknowledge;
  final AutopilotActionResolver? onDismiss;

  const ReviewQueueScreen({
    super.key,
    this.doctorId,
    this.loader,
    this.onAcknowledge,
    this.onDismiss,
  });

  @override
  State<ReviewQueueScreen> createState() => _ReviewQueueScreenState();
}

class _ReviewQueueScreenState extends State<ReviewQueueScreen> {
  List<AutopilotAction>? _actions;
  bool _failed = false;

  /// Ids with an acknowledge/dismiss request in flight.
  final Set<String> _busy = {};

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  /// Back to the full-screen loader, then fetch (error-state Retry).
  Future<void> _retry() {
    setState(() {
      _actions = null;
      _failed = false;
    });
    return _fetch();
  }

  /// Fetches without clearing what's shown, so pull-to-refresh keeps the
  /// list on screen under its own indicator.
  Future<void> _fetch() async {
    final doctorId = widget.doctorId ??
        SharedPreferenceHelper.getStringOrNull(Preferences.doctorId);
    List<AutopilotAction>? result;
    if (doctorId != null && doctorId.isNotEmpty) {
      try {
        final loader =
            widget.loader ?? AstraApiService().getPendingAutopilotActions;
        result = await loader(doctorId);
      } catch (_) {
        result = null;
      }
    }

    if (!mounted) return;
    setState(() {
      _actions = result ?? const [];
      _failed = result == null;
    });
  }

  Future<void> _resolve(AutopilotAction action, {required bool acknowledge}) {
    final resolver = acknowledge
        ? (widget.onAcknowledge ?? AstraApiService().acknowledgeAutopilotAction)
        : (widget.onDismiss ?? AstraApiService().dismissAutopilotAction);
    return _run(action, resolver, acknowledge ? 'Acknowledged' : 'Dismissed');
  }

  Future<void> _run(AutopilotAction action, AutopilotActionResolver resolver,
      String doneMessage) async {
    setState(() => _busy.add(action.id));
    bool ok;
    try {
      ok = await resolver(action.id);
    } catch (_) {
      ok = false;
    }
    if (!mounted) return;
    setState(() {
      _busy.remove(action.id);
      // Only remove it once the server confirms; on failure it stays, so
      // nothing looks handled when it wasn't.
      if (ok) {
        _actions = _actions?.where((a) => a.id != action.id).toList();
      }
    });
    if (ok) {
      OslerToast.success(context, doneMessage);
    } else {
      OslerToast.error(context, 'Couldn\'t update this item. Try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: AyurezeTheme.canvas,
      appBar: AppBar(
        backgroundColor: AyurezeTheme.canvas,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: HugeIcon(
                  icon: HugeIcons.strokeRoundedArrowLeft01,
                  color: AyurezeTheme.iconPrimary,
                  size: 20,
                ),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: Text(
          'Review queue',
          style: textTheme.titleLarge?.copyWith(
            color: AyurezeTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    final actions = _actions;
    if (actions == null) {
      return const OslerLoadingView(message: 'Loading review queue…');
    }
    if (_failed) {
      return OslerStateView(
        icon: HugeIcons.strokeRoundedAlert02,
        tone: OslerStateTone.error,
        title: 'Couldn\'t load the review queue',
        message: 'Check your connection and try again.',
        actionLabel: 'Retry',
        onAction: _retry,
      );
    }
    if (actions.isEmpty) {
      return RefreshIndicator(
        onRefresh: _fetch,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.6,
              child: OslerStateView(
                icon: HugeIcons.strokeRoundedTaskDone01,
                title: 'Nothing to review',
                message: 'When Astra flags a care gap or suggests a '
                    'follow-up for one of your patients, it will appear '
                    'here for you to acknowledge or dismiss.',
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetch,
      child: ListView.builder(
        padding: const EdgeInsets.all(AyurezeTheme.spaceLg),
        itemCount: actions.length,
        itemBuilder: (context, i) => _ActionCard(
          action: actions[i],
          busy: _busy.contains(actions[i].id),
          onAcknowledge: () => _resolve(actions[i], acknowledge: true),
          onDismiss: () => _resolve(actions[i], acknowledge: false),
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final AutopilotAction action;
  final bool busy;
  final VoidCallback onAcknowledge;
  final VoidCallback onDismiss;

  const _ActionCard({
    required this.action,
    required this.busy,
    required this.onAcknowledge,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final meta = [
      if (action.patientName != null && action.patientName!.isNotEmpty)
        action.patientName!,
      if (action.createdAt != null)
        DateFormat('d MMM, h:mm a').format(action.createdAt!.toLocal()),
    ].join('  ·  ');

    return OslerCard(
      margin: const EdgeInsets.only(bottom: AyurezeTheme.spaceMd),
      padding: const EdgeInsets.all(AyurezeTheme.spaceLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AyurezeTheme.spaceSm,
            runSpacing: AyurezeTheme.spaceXs,
            children: [
              OslerTag(
                label: action.kind.label,
                style: action.kind == AutopilotActionKind.careGap
                    ? OslerTagStyle.danger
                    : OslerTagStyle.info,
              ),
              if (action.requiresSignOff)
                const OslerTag(
                  label: 'Needs sign-off',
                  style: OslerTagStyle.warning,
                ),
              const ContentOriginBadge(origin: ContentOrigin.astraSuggestion),
            ],
          ),
          const SizedBox(height: AyurezeTheme.spaceMd),
          Text(
            action.title,
            style: textTheme.titleMedium?.copyWith(
              color: AyurezeTheme.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (action.detail != null && action.detail!.isNotEmpty) ...[
            const SizedBox(height: AyurezeTheme.spaceXs),
            Text(
              action.detail!,
              style: textTheme.bodyMedium
                  ?.copyWith(color: AyurezeTheme.textSecondary),
            ),
          ],
          if (meta.isNotEmpty) ...[
            const SizedBox(height: AyurezeTheme.spaceSm),
            Text(
              meta,
              style: textTheme.bodySmall
                  ?.copyWith(color: AyurezeTheme.textSecondary),
            ),
          ],
          const SizedBox(height: AyurezeTheme.spaceMd),
          Row(
            children: [
              Expanded(
                child: OslerButton(
                  text: 'Dismiss',
                  style: OslerButtonStyle.outline,
                  onPressed: busy ? null : onDismiss,
                ),
              ),
              const SizedBox(width: AyurezeTheme.spaceMd),
              Expanded(
                child: OslerButton(
                  text: 'Acknowledge',
                  isLoading: busy,
                  onPressed: busy ? null : onAcknowledge,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
