import 'package:doctro/models/astra_doctor_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AstraDoctorMapper.unwrap', () {
    test('reads the record at the top level', () {
      expect(AstraDoctorMapper.unwrap({'name': 'A'}), {'name': 'A'});
    });

    test('unwraps doctor, data and data.doctor wrappers', () {
      expect(
          AstraDoctorMapper.unwrap({
            'doctor': {'name': 'A'}
          }),
          {'name': 'A'});
      expect(
          AstraDoctorMapper.unwrap({
            'success': true,
            'data': {'name': 'B'}
          }),
          {'name': 'B'});
      expect(
          AstraDoctorMapper.unwrap({
            'data': {
              'doctor': {'name': 'C'}
            }
          }),
          {'name': 'C'});
    });

    test('gives an empty map for a non-map body', () {
      expect(AstraDoctorMapper.unwrap(null), isEmpty);
      expect(AstraDoctorMapper.unwrap('<html>404</html>'), isEmpty);
      expect(AstraDoctorMapper.unwrap([1, 2]), isEmpty);
    });
  });

  group('AstraDoctor.fromResponse', () {
    test('maps the documented register fields', () {
      final d = AstraDoctor.fromResponse({
        'doctor': {
          'doctor_id': 'doc-1',
          'name': 'Dr. Rajesh Kumar',
          'email': 'rajesh@ayureze.com',
          'phone': '+919876543210',
          'specialization': 'Ayurveda Specialist',
          'qualifications': ['BAMS', 'MD Ayurveda'],
          'experience_years': 10,
          'consultation_fee': 800,
          'languages': ['English', 'Hindi'],
          'bio': 'Panchakarma',
          'profile_image': 'https://x/y.jpg',
          'available_days': ['Monday'],
        }
      });
      expect(d.id, 'doc-1');
      expect(d.name, 'Dr. Rajesh Kumar');
      expect(d.email, 'rajesh@ayureze.com');
      expect(d.phone, '+919876543210');
      expect(d.specialization, 'Ayurveda Specialist');
      expect(d.qualifications, ['BAMS', 'MD Ayurveda']);
      expect(d.experienceYears, 10);
      expect(d.experienceText, '10');
      expect(d.consultationFee, 800);
      expect(d.feeText, '800');
      expect(d.languages, ['English', 'Hindi']);
      expect(d.bio, 'Panchakarma');
      expect(d.profileImage, 'https://x/y.jpg');
      expect(d.availableDays, ['Monday']);
    });

    test('falls back to alternative key names and string values', () {
      final d = AstraDoctor.fromResponse({
        'data': {
          'id': 42,
          'full_name': 'Dr. Asha',
          'phone_number': '999',
          'speciality': 'Kayachikitsa',
          'qualifications': 'BAMS, MD',
          'experience': '7 years',
          'fee': '₹650.00',
          'language': 'Tamil',
          'description': 'About me',
          'photo_url': 'p.jpg',
          'gender': 'female',
          'dob': '1990-02-03',
          'certificate_url': 'c.pdf',
          'patient_vcall': true,
        }
      });
      expect(d.id, '42');
      expect(d.name, 'Dr. Asha');
      expect(d.phone, '999');
      expect(d.specialization, 'Kayachikitsa');
      expect(d.qualifications, ['BAMS', 'MD']);
      expect(d.experienceYears, 7);
      expect(d.consultationFee, 650);
      expect(d.languages, ['Tamil']);
      expect(d.bio, 'About me');
      expect(d.profileImage, 'p.jpg');
      expect(d.gender, 'female');
      expect(d.dob, '1990-02-03');
      expect(d.certificateUrl, 'c.pdf');
      expect(d.patientVCall, 1);
    });

    test('leaves missing, blank and wrongly typed fields empty', () {
      final d = AstraDoctor.fromResponse({
        'name': '  ',
        'email': {'nested': true},
        'consultation_fee': 'n/a',
      });
      expect(d.name, isNull);
      expect(d.email, isNull);
      expect(d.consultationFee, isNull);
      expect(d.feeText, '');
      expect(d.experienceText, '');
      expect(d.qualifications, isEmpty);
      expect(d.patientVCall, isNull);
    });
  });

  group('AstraDoctorMapper.doctorIdFrom / sessionTokenFrom', () {
    test('prefers a top-level doctor_id, then the record id', () {
      expect(
          AstraDoctorMapper.doctorIdFrom({
            'doctor_id': 'top',
            'data': {'id': 'inner'}
          }),
          'top');
      expect(
          AstraDoctorMapper.doctorIdFrom({
            'data': {'id': 7}
          }),
          '7');
      expect(AstraDoctorMapper.doctorIdFrom({'message': 'ok'}), isNull);
      expect(AstraDoctorMapper.doctorIdFrom(null), isNull);
    });

    test('finds a session token only when one is present', () {
      expect(AstraDoctorMapper.sessionTokenFrom({'session_token': 't'}), 't');
      expect(
          AstraDoctorMapper.sessionTokenFrom({
            'data': {'access_token': 'a'}
          }),
          'a');
      expect(AstraDoctorMapper.sessionTokenFrom({'doctor_id': 'x'}), isNull);
    });
  });

  group('AstraDoctorMapper.registerBody', () {
    test('builds a RegisterDoctorRequest from form text', () {
      final body = AstraDoctorMapper.registerBody(
        name: ' Dr. A ',
        email: 'a@b.c',
        phone: '+911234',
        qualifications: 'BAMS, MD Ayurveda,',
        experience: '10 years',
        fee: '₹800',
        languages: 'English, Hindi',
        bio: 'Bio',
      );
      expect(body, {
        'name': 'Dr. A',
        'email': 'a@b.c',
        'phone': '+911234',
        'qualifications': ['BAMS', 'MD Ayurveda'],
        'experience_years': 10,
        'consultation_fee': 800,
        'languages': ['English', 'Hindi'],
        'bio': 'Bio',
      });
    });

    test('leaves out blank and unparseable values for server defaults', () {
      final body = AstraDoctorMapper.registerBody(
        name: 'Dr. A',
        email: '',
        experience: 'many',
        fee: '',
        languages: ' ',
      );
      expect(body, {'name': 'Dr. A'});
    });
  });

  group('AstraDoctorMapper.updateBody', () {
    test('only sends UpdateDoctorRequest fields', () {
      final body = AstraDoctorMapper.updateBody(
        name: 'Dr. A',
        phone: '123',
        specialization: 'Ayurveda',
        fee: '799.5',
        bio: ' Hi ',
      );
      expect(body, {
        'name': 'Dr. A',
        'phone': '123',
        'specialization': 'Ayurveda',
        'consultation_fee': 799.5,
        'bio': 'Hi',
      });
      const allowed = {
        'name',
        'phone',
        'specialization',
        'consultation_fee',
        'available_days',
        'available_times',
        'bio',
      };
      expect(allowed.containsAll(body.keys), isTrue);
    });

    test('never blanks name or phone, but lets bio be cleared', () {
      final body =
          AstraDoctorMapper.updateBody(name: ' ', phone: '', fee: '', bio: '');
      expect(body, {'bio': ''});
      expect(AstraDoctorMapper.updateBody(), isEmpty);
    });
  });

  group('AstraDoctorMapper.changedFields', () {
    test('lists labels whose value changed, ignoring whitespace', () {
      final changed = AstraDoctorMapper.changedFields(
        {'Gender': 'male', 'Time slot': '15', 'Hospitals': ''},
        {'Gender': 'male ', 'Time slot': '30', 'Hospitals': '1,2'},
      );
      expect(changed, ['Time slot', 'Hospitals']);
    });

    test('treats a label missing before as empty', () {
      expect(AstraDoctorMapper.changedFields({}, {'Experience': ''}), isEmpty);
      expect(AstraDoctorMapper.changedFields({}, {'Experience': '5'}),
          ['Experience']);
    });

    test('names the unsaved fields in the message', () {
      expect(AstraDoctorMapper.unsavedMessage(['Gender', 'Time slot']),
          contains('Gender, Time slot'));
    });
  });

  group('number and text helpers', () {
    test('parseFee', () {
      expect(AstraDoctorMapper.parseFee(500), 500);
      expect(AstraDoctorMapper.parseFee('₹180.00'), 180);
      expect(AstraDoctorMapper.parseFee('1,200'), 1200);
      expect(AstraDoctorMapper.parseFee('12.5'), 12.5);
      expect(AstraDoctorMapper.parseFee(''), isNull);
      expect(AstraDoctorMapper.parseFee(null), isNull);
    });

    test('parseYears', () {
      expect(AstraDoctorMapper.parseYears(3), 3);
      expect(AstraDoctorMapper.parseYears(3.6), 4);
      expect(AstraDoctorMapper.parseYears('12 yrs'), 12);
      expect(AstraDoctorMapper.parseYears('none'), isNull);
    });

    test('formatNumber', () {
      expect(AstraDoctorMapper.formatNumber(800.0), '800');
      expect(AstraDoctorMapper.formatNumber(799.5), '799.5');
      expect(AstraDoctorMapper.formatNumber(null), '');
    });

    test('withDialCode', () {
      expect(
          AstraDoctorMapper.withDialCode('+91', '9876543210'), '+919876543210');
      expect(AstraDoctorMapper.withDialCode('+91', '+14155550100'),
          '+14155550100');
      expect(AstraDoctorMapper.withDialCode(null, '123'), '123');
      expect(AstraDoctorMapper.withDialCode('+91', ' '), isNull);
    });
  });
}
