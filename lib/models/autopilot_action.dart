/// What kind of proactive item Astra raised.
enum AutopilotActionKind {
  /// Something expected in the patient's care hasn't happened (missed
  /// check-ins, a lapsed prescription, ...).
  careGap,

  /// Astra suggests booking or nudging a follow-up.
  followUp,

  /// Anything else; shown generically rather than dropped.
  other;

  String get label => switch (this) {
        AutopilotActionKind.careGap => 'Care gap',
        AutopilotActionKind.followUp => 'Suggested follow-up',
        AutopilotActionKind.other => 'Astra flag',
      };
}

/// A pending autopilot action Astra has raised for a doctor's awareness or
/// sign-off.
///
/// UI-side model only. The backend endpoint does not exist yet and its
/// response shape has not been agreed, so there is deliberately no
/// `fromJson` here - add one against the real astra contract rather than
/// guessing keys now. TODO(astra-backend).
class AutopilotAction {
  final String id;
  final AutopilotActionKind kind;
  final String title;
  final String? detail;
  final String? patientName;
  final DateTime? createdAt;

  /// True when the doctor must sign off before Astra acts, as opposed to an
  /// FYI the doctor only needs to see.
  final bool requiresSignOff;

  const AutopilotAction({
    required this.id,
    required this.kind,
    required this.title,
    this.detail,
    this.patientName,
    this.createdAt,
    this.requiresSignOff = false,
  });
}
