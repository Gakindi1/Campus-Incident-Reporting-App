import 'package:campus_fix/core/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Validators.email', () {
    test('accepts ALU student and staff domains', () {
      expect(Validators.email('a.hassan@alustudent.com'), isNull);
      expect(Validators.email('G.Uwase@ALUEDUCATION.com'), isNull);
    });

    test('rejects non-ALU domains', () {
      expect(Validators.email('someone@gmail.com'), contains('ALU email'));
    });

    test('rejects malformed and empty input', () {
      expect(Validators.email(''), 'Email is required');
      expect(Validators.email('not-an-email'), 'Enter a valid email address');
    });
  });

  group('Validators.password', () {
    test('requires length, a letter and a number', () {
      expect(Validators.password('short1'), 'Use at least 8 characters');
      expect(Validators.password('onlyletters'), contains('one number'));
      expect(Validators.password('12345678'), contains('one letter'));
      expect(Validators.password('campus2026'), isNull);
    });

    test('confirmPassword compares with the original value', () {
      final validator = Validators.confirmPassword(() => 'campus2026');
      expect(validator('campus2026'), isNull);
      expect(validator('different1'), 'Passwords do not match');
    });
  });

  group('Incident fields', () {
    test('title length bounds', () {
      expect(Validators.incidentTitle('Leak'), isNotNull);
      expect(Validators.incidentTitle('Broken projector'), isNull);
      expect(Validators.incidentTitle('x' * 81), isNotNull);
    });

    test('description needs enough detail', () {
      expect(Validators.incidentDescription('Too short'), isNotNull);
      expect(
        Validators.incidentDescription(
          'The projector in B204 will not turn on.',
        ),
        isNull,
      );
    });
  });
}
