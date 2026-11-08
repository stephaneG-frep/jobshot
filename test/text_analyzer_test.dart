import 'package:flutter_test/flutter_test.dart';
import 'package:jobshot/services/text_analyzer.dart';
import 'package:jobshot/models/models.dart';

void main() {
  group('TextAnalyzer', () {
    final analyzer = TextAnalyzer.instance;

    test('extracts email', () {
      final result = analyzer.analyze('Contactez john@example.com pour plus d\'info');
      expect(result.email, 'john@example.com');
    });

    test('detects LinkedIn source', () {
      final result = analyzer.analyze('Via LinkedIn, votre profil nous intéresse');
      expect(result.source, Source.linkedin);
    });

    test('detects France Travail source', () {
      final result = analyzer.analyze('Annonce France Travail n°12345');
      expect(result.source, Source.franceTravail);
    });

    test('detects refusal status', () {
      final result = analyzer.analyze('Nous vous informons d\'un refus à votre candidature');
      expect(result.statutProbable, AppStatus.refusee);
    });

    test('detects interview status', () {
      final result = analyzer.analyze('Vous êtes convoqué à un entretien le 15 mars');
      expect(result.statutProbable, AppStatus.entretien);
    });

    test('extracts date', () {
      final result = analyzer.analyze('Rendez-vous le 15/03/2026 à 14h');
      expect(result.dateEntretien, isNotNull);
    });

    test('handles empty text', () {
      final result = analyzer.analyze('');
      expect(result.entreprise, '');
      expect(result.statutProbable, AppStatus.envoyee);
    });
  });
}
