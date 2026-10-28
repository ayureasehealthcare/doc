/// Request building for the prescription screen's "Save for approval".
///
/// Shapes are taken from astra's live OpenAPI spec (checked Oct 2026):
/// `POST api/v1/api/prescriptions/draft` (and `/create`) take a
/// `CreatePrescriptionRequest` whose medicines are `MedicineItem`s keyed by `name`. Unknown keys are
/// ignored by the server, not rejected.
class PrescriptionPayload {
  PrescriptionPayload._();

  /// The variant id a store product is ordered by. The available-products
  /// route returns `variant_id`; a raw Shopify product nests it under
  /// `variants`, where the top-level `id` is the *product* id and must not be
  /// used.
  static String? variantIdOf(Map<String, dynamic> product) {
    final List variants =
        product['variants'] is List ? product['variants'] as List : const [];
    final firstVariant = variants.isNotEmpty && variants.first is Map
        ? variants.first as Map
        : null;
    final dynamic id = product['shopify_variant_id'] ??
        product['variant_id'] ??
        firstVariant?['id'];
    final text = id?.toString().trim();
    return (text == null || text.isEmpty) ? null : text;
  }

  /// The product's price for display, or null when the store has none yet.
  /// The text field already carries a rupee sign ("₹180.00"), and a product
  /// with `price_status: price_pending` comes back as "₹0.00".
  static String? priceLabel(dynamic price) {
    if (price == null) return null;
    final text =
        price.toString().replaceAll('₹', '').replaceAll(',', '').trim();
    final value = num.tryParse(text);
    if (value == null || value <= 0) return null;
    return '₹${value.toStringAsFixed(2)}';
  }

  /// Readable text from a suggest-dosage response, whose schema astra
  /// leaves open: the likely keys first, else every short value.
  static String dosageText(Map<String, dynamic> body) {
    for (final k in [
      'suggested_dosage',
      'recommended_dosage',
      'dosage',
      'recommendation',
      'suggestion',
      'message',
    ]) {
      final v = body[k];
      if (v is String && v.trim().isNotEmpty) return v.trim();
    }
    final parts = [
      for (final e in body.entries)
        if (e.value is String || e.value is num)
          '${e.key.replaceAll('_', ' ')}: ${e.value}',
    ];
    return parts.isEmpty ? 'No suggestion returned.' : parts.join('\n');
  }

  static bool isLinked(Map<String, dynamic> medicine) =>
      (medicine['shopify_variant_id']?.toString().trim() ?? '').isNotEmpty;

  static Map<String, dynamic> create({
    required String doctorId,
    required String patientId,
    required String patientName,
    String? patientPhone,
    required String diagnosis,
    required List<Map<String, dynamic>> medicines,
    String? signatureBase64,
    bool autoProcess = true,
  }) =>
      {
        "doctor_id": doctorId,
        "patient_id": patientId,
        "patient_name": patientName,
        "patient_phone": patientPhone,
        "diagnosis": diagnosis,
        "medicines": [
          for (final m in medicines)
            {
              "name": m['medicine_name'],
              "shopify_variant_id": isLinked(m)
                  ? m['shopify_variant_id'].toString().trim()
                  : null,
              "dosage": m['dosage'],
              "frequency": m['frequency'],
              "timing": m['timing'],
              "duration_days": m['duration_days'],
              "instructions": m['instructions'],
              // Not in MedicineItem today; sent so a cart can honour it
              // once the server reads it.
              "quantity": m['quantity'],
            },
        ],
        "lifestyle_advice": "Rest and hydration",
        "auto_process": autoProcess,
        // Not in CreatePrescriptionRequest today, so the server drops it.
        if (signatureBase64 != null) "signature_image": signatureBase64,
      };
}
