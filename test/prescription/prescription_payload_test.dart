import 'package:doctro/features/prescription/astra/prescription_payload.dart';
import 'package:flutter_test/flutter_test.dart';

// A product exactly as astra's GET api/v1/shopify/products/available
// returned it (Oct 2026), trimmed.
const _liveProduct = {
  'name': 'Aadarisahacharadi Kashayam',
  'variant_id': '50789027905849',
  'product_id': '9880663785785',
  'title': 'Aadarisahacharadi Kashayam',
  'price': '₹180.00',
  'price_numeric': 180.0,
  'price_status': 'available',
};

void main() {
  test('uses the variant id, never the product id', () {
    expect(PrescriptionPayload.variantIdOf(_liveProduct), '50789027905849');
    // Raw Shopify shape: top-level id is the product.
    expect(
        PrescriptionPayload.variantIdOf({
          'id': 111,
          'variants': [
            {'id': 222}
          ],
        }),
        '222');
    expect(PrescriptionPayload.variantIdOf({'id': 111}), isNull);
  });

  test('price label has one rupee sign, or none when pending', () {
    expect(PrescriptionPayload.priceLabel('₹180.00'), '₹180.00');
    expect(PrescriptionPayload.priceLabel(180.0), '₹180.00');
    expect(PrescriptionPayload.priceLabel(null), isNull);
    // price_status: price_pending arrives as "₹0.00".
    expect(PrescriptionPayload.priceLabel('₹0.00'), isNull);
    expect(PrescriptionPayload.priceLabel(0.0), isNull);
  });

  test('builds a CreatePrescriptionRequest the server accepts', () {
    final payload = PrescriptionPayload.create(
      doctorId: 'd1',
      patientId: 'p1',
      patientName: 'Demo',
      diagnosis: 'Dry cough',
      medicines: [
        {
          'medicine_name': 'Aadarisahacharadi Kashayam',
          'shopify_variant_id': '50789027905849',
          'dosage': '1 tablet',
          'frequency': 'twice_daily',
          'timing': 'After Food',
          'duration_days': 5,
          'quantity': 2,
          'instructions': '',
        },
        {
          'medicine_name': 'Unlinked herb',
          'shopify_variant_id': null,
          'dosage': '5 ml',
          'frequency': 'once_daily',
          'duration_days': 7,
        },
      ],
    );

    // Required by the spec: patient_id, patient_name, diagnosis, medicines;
    // each medicine needs name, dosage, frequency.
    for (final key in ['patient_id', 'patient_name', 'diagnosis']) {
      expect(payload[key], isA<String>(), reason: key);
    }
    final meds = payload['medicines'] as List;
    for (final m in meds) {
      expect(m['name'], isA<String>());
      expect(m['dosage'], isA<String>());
      expect(m['frequency'], isA<String>());
      expect(m.containsKey('medicine_name'), isFalse);
    }
    expect(meds[0]['shopify_variant_id'], '50789027905849');
    expect(meds[1]['shopify_variant_id'], isNull);
    expect(payload['auto_process'], isTrue);
  });
}
