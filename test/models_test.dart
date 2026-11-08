import 'package:flutter_test/flutter_test.dart';
import 'package:jobshot/models/models.dart';

void main() {
  group('Application model', () {
    test('creates application with defaults', () {
      final app = Application(
        entreprise: 'Test Corp',
        poste: 'Développeur',
      );
      expect(app.entreprise, 'Test Corp');
      expect(app.poste, 'Développeur');
      expect(app.statut, AppStatus.aPreparer);
      expect(app.source, Source.autre);
    });

    test('toMap and fromMap roundtrip', () {
      final app = Application(
        id: 1,
        entreprise: 'ACME',
        poste: 'Ingénieur',
        statut: AppStatus.entretien,
        source: Source.linkedin,
        email: 'test@test.com',
      );
      final map = app.toMap();
      final restored = Application.fromMap(map);
      expect(restored.id, 1);
      expect(restored.entreprise, 'ACME');
      expect(restored.poste, 'Ingénieur');
      expect(restored.statut, AppStatus.entretien);
      expect(restored.source, Source.linkedin);
      expect(restored.email, 'test@test.com');
    });
  });

  group('AppStatus', () {
    test('fromString parses correct status', () {
      expect(AppStatus.fromString('envoyee'), AppStatus.envoyee);
      expect(AppStatus.fromString('entretien'), AppStatus.entretien);
      expect(AppStatus.fromString('invalide'), AppStatus.aPreparer);
    });

    test('labels are defined', () {
      for (final status in AppStatus.values) {
        expect(status.label.isNotEmpty, isTrue);
      }
    });
  });

  group('Capture model', () {
    test('fromMap handles null ocrText', () {
      final capture = Capture(
        applicationId: 1,
        imagePath: '/path/to/image.png',
      );
      final map = capture.toMap();
      final restored = Capture.fromMap(map);
      expect(restored.applicationId, 1);
      expect(restored.imagePath, '/path/to/image.png');
      expect(restored.ocrText, isNull);
    });
  });
}
