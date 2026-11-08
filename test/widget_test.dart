import 'package:flutter_test/flutter_test.dart';
import 'package:jobshot/models/models.dart';

void main() {
  test('Application model works', () {
    final app = Application(
      entreprise: 'ACME',
      poste: 'Developpeur',
    );
    expect(app.entreprise, 'ACME');
    expect(app.statut, AppStatus.aPreparer);
  });
}
