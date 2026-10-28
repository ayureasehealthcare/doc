import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';

import 'package:doctro/core/constants/prefConstatnt.dart';
import 'package:doctro/core/constants/preferences.dart';
import 'package:doctro/models/pending_prescription.dart';
import 'package:doctro/services/astra_api_service.dart';
import 'package:doctro/theme/ayureze_theme.dart';
import 'package:doctro/widgets/osler_button.dart';
import 'package:doctro/widgets/osler_card.dart';
import 'package:doctro/widgets/osler_state_view.dart';
import 'package:doctro/widgets/osler_tag.dart';
import 'package:doctro/widgets/osler_toast.dart';
import 'package:doctro/widgets/swastu.dart';

typedef PendingPrescriptionsLoader = Future<List<PendingPrescription>>
    Function();
typedef PrescriptionApprover = Future<void> Function(PendingPrescription rx);
typedef PrescriptionRejecter = Future<void> Function(
    PendingPrescription rx, String? reason);

/// Prescriptions saved for the doctor's approval. Approving one runs its
/// automation on the server (Shopify cart, medicine reminders, patient
/// notification); rejecting removes it from the queue.
class PendingPrescriptionsScreen extends StatefulWidget {
  static const routeName = 'pendingPrescriptions';

  /// Default to [AstraApiService]; injectable for tests and the mock flow.
  final PendingPrescriptionsLoader? loader;
  final PrescriptionApprover? onApprove;
  final PrescriptionRejecter? onReject;

  const PendingPrescriptionsScreen({
    super.key,
    this.loader,
    this.onApprove,
    this.onReject,
  });

  @override
  State<PendingPrescriptionsScreen> createState() =>
      _PendingPrescriptionsScreenState();
}

class _PendingPrescriptionsScreenState
    extends State<PendingPrescriptionsScreen> {
  List<PendingPrescription>? _items;
  String? _error;

  /// Ids with an approve/reject request in flight.
  final Set<String> _busy = {};

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _retry() {
    setState(() {
      _items = null;
      _error = null;
    });
    return _fetch();
  }

  Future<void> _fetch() async {
    List<PendingPrescription>? result;
    String? error;
    try {
      final loader = widget.loader ??
          () => AstraApiService().getPendingPrescriptionQueue();
      result = await loader();
      // The queue route takes no doctor filter. Hide records that name
      // another doctor; keep ones that name none.
      final me = SharedPreferenceHelper.getStringOrNull(Preferences.doctorId);
      if (me != null) {
        result = result
            .where((rx) => rx.doctorId == null || rx.doctorId == me)
            .toList();
      }
    } on AstraApiException catch (e) {
      error = e.message;
    } catch (_) {
      error = 'Check your connection and try again.';
    }
    if (!mounted) return;
    setState(() {
      _items = result ?? const [];
      _error = error;
    });
  }

  Future<void> _approve(PendingPrescription rx) => _run(
        rx,
        () => (widget.onApprove ??
            (rx) => AstraApiService().approvePrescription(
                  rx.id,
                  patientName: rx.patientName,
                  patientPhone: rx.patientPhone,
                ))(rx),
        'Approved and sent for processing.',
      );

  Future<void> _reject(PendingPrescription rx) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => const _RejectDialog(),
    );
    if (reason == null || !mounted) return; // cancelled
    await _run(
      rx,
      () => (widget.onReject ??
          (rx, reason) => AstraApiService()
              .rejectPrescription(rx.id, reason: reason))(rx, reason),
      'Prescription rejected.',
    );
  }

  Future<void> _run(PendingPrescription rx, Future<void> Function() call,
      String doneMessage) async {
    setState(() => _busy.add(rx.id));
    String? failure;
    try {
      await call();
    } on AstraApiException catch (e) {
      failure = e.message;
    } catch (_) {
      failure = "Couldn't update this prescription. Try again.";
    }
    if (!mounted) return;
    setState(() {
      _busy.remove(rx.id);
      // Only remove it once the server confirms; on failure it stays.
      if (failure == null) {
        _items = _items?.where((i) => i.id != rx.id).toList();
      }
    });
    if (failure == null) {
      OslerToast.success(context, doneMessage);
    } else {
      OslerToast.error(context, failure);
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
          'Prescriptions to approve',
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
    final items = _items;
    if (items == null) {
      return const OslerLoadingView(message: 'Loading prescriptions…');
    }
    if (_error != null) {
      return OslerStateView.error(
        title: "Couldn't load prescriptions",
        message: _error!,
        onRetry: _retry,
      );
    }
    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: _fetch,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.6,
              child: const OslerStateView(
                icon: HugeIcons.strokeRoundedMedicineBottle01,
                mood: SwastuMood.happy,
                title: 'Nothing to approve',
                message: 'Prescriptions you save from a patient appear here '
                    'until you approve or reject them.',
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
        itemCount: items.length,
        itemBuilder: (context, i) => _PrescriptionCard(
          rx: items[i],
          busy: _busy.contains(items[i].id),
          onApprove: () => _approve(items[i]),
          onReject: () => _reject(items[i]),
        ),
      ),
    );
  }
}

class _PrescriptionCard extends StatelessWidget {
  final PendingPrescription rx;
  final bool busy;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _PrescriptionCard({
    required this.rx,
    required this.busy,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final created = rx.createdAt == null
        ? null
        : DateFormat('d MMM, h:mm a').format(rx.createdAt!.toLocal());

    return OslerCard(
      margin: const EdgeInsets.only(bottom: AyurezeTheme.spaceMd),
      padding: const EdgeInsets.all(AyurezeTheme.spaceLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  rx.patientName,
                  style: textTheme.titleMedium?.copyWith(
                    color: AyurezeTheme.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const OslerTag(
                  label: 'Awaiting approval', style: OslerTagStyle.warning),
            ],
          ),
          if (rx.diagnosis.isNotEmpty) ...[
            const SizedBox(height: AyurezeTheme.spaceXs),
            Text(
              rx.diagnosis,
              style: textTheme.bodyMedium
                  ?.copyWith(color: AyurezeTheme.textSecondary),
            ),
          ],
          if (rx.medicines.isNotEmpty) ...[
            const SizedBox(height: AyurezeTheme.spaceMd),
            for (final m in rx.medicines)
              Padding(
                padding: const EdgeInsets.only(bottom: AyurezeTheme.spaceXs),
                child: Text.rich(
                  TextSpan(children: [
                    TextSpan(
                      text: m.name,
                      style: textTheme.bodyMedium?.copyWith(
                        color: AyurezeTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (m.summary.isNotEmpty)
                      TextSpan(
                        text: '  ${m.summary}',
                        style: textTheme.bodySmall
                            ?.copyWith(color: AyurezeTheme.textSecondary),
                      ),
                  ]),
                ),
              ),
          ],
          if (created != null) ...[
            const SizedBox(height: AyurezeTheme.spaceSm),
            Text(
              'Saved $created',
              style: textTheme.bodySmall
                  ?.copyWith(color: AyurezeTheme.textSecondary),
            ),
          ],
          const SizedBox(height: AyurezeTheme.spaceMd),
          Row(
            children: [
              Expanded(
                child: OslerButton(
                  text: 'Reject',
                  style: OslerButtonStyle.outline,
                  onPressed: busy ? null : onReject,
                ),
              ),
              const SizedBox(width: AyurezeTheme.spaceMd),
              Expanded(
                child: OslerButton(
                  text: 'Approve & send',
                  isLoading: busy,
                  onPressed: busy ? null : onApprove,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Asks for an optional rejection reason; pops with the text ('' when
/// left blank), or null when cancelled.
class _RejectDialog extends StatefulWidget {
  const _RejectDialog();

  @override
  State<_RejectDialog> createState() => _RejectDialogState();
}

class _RejectDialogState extends State<_RejectDialog> {
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Reject prescription?'),
      content: TextField(
        controller: _reason,
        autofocus: true,
        maxLines: 3,
        decoration: const InputDecoration(hintText: 'Reason (optional)'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _reason.text.trim()),
          child: const Text('Reject'),
        ),
      ],
    );
  }
}
