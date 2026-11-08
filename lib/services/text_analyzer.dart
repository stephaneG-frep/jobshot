import '../models/models.dart';

class AnalyzedData {
  String entreprise;
  String poste;
  AppStatus statutProbable;
  Source source;
  String? recruteur;
  String? email;
  String? telephone;
  String? dateStr;
  String? referenceOffre;
  String? localisation;
  String? url;
  DateTime? dateEntretien;
  DateTime? dateRelance;

  AnalyzedData({
    this.entreprise = '',
    this.poste = '',
    this.statutProbable = AppStatus.aPreparer,
    this.source = Source.autre,
    this.recruteur,
    this.email,
    this.telephone,
    this.dateStr,
    this.referenceOffre,
    this.localisation,
    this.url,
    this.dateEntretien,
    this.dateRelance,
  });
}

class TextAnalyzer {
  static final TextAnalyzer instance = TextAnalyzer._();
  factory TextAnalyzer() => instance;
  TextAnalyzer._();

  final _emailRegex = RegExp(
    r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}',
  );

  final _phoneRegex = RegExp(
    r'(?:\+33|0033|0)[\s.-]?[1-9](?:[\s.-]?\d{2}){4}',
  );

  final _urlRegex = RegExp(
    r'https?://[^\s<>"]+|www\.[^\s<>"]+',
  );

  final _dateRegex = RegExp(
    r'\b(\d{1,2})[/\-.](\d{1,2})[/\-.](\d{2,4})\b',
  );

  final _dateWordsRegex = RegExp(
    r'(\d{1,2})\s+(janvier|février|mars|avril|mai|juin|juillet|août|septembre|octobre|novembre|décembre)\s+(\d{4})',
    caseSensitive: false,
  );

  final _refRegex = RegExp(
    r'(?:réf\.?|référence|ref\.?|reference)\s*[:#]?\s*([A-Za-z0-9\-]+)',
    caseSensitive: false,
  );

  AnalyzedData analyze(String text) {
    final data = AnalyzedData();

    data.email = _extractEmail(text);
    data.telephone = _extractPhone(text);
    data.url = _extractUrl(text);
    data.referenceOffre = _extractReference(text);
    data.recruteur = _extractRecruteur(text);
    data.entreprise = _extractEntreprise(text);
    data.poste = _extractPoste(text);
    data.source = _detectSource(text);
    data.statutProbable = _detectStatus(text);
    data.dateEntretien = _extractEntretienDate(text);
    data.dateRelance = _extractRelance(text);
    data.localisation = _extractLocalisation(text);

    final dateStr = _extractDateStr(text);
    data.dateStr = dateStr;

    return data;
  }

  String? _extractEmail(String text) {
    final match = _emailRegex.firstMatch(text);
    return match?.group(0);
  }

  String? _extractPhone(String text) {
    final match = _phoneRegex.firstMatch(text);
    if (match != null) {
      return match.group(0)?.replaceAll(RegExp(r'[\s.\-]'), '');
    }
    return null;
  }

  String? _extractUrl(String text) {
    final match = _urlRegex.firstMatch(text);
    return match?.group(0);
  }

  String? _extractReference(String text) {
    final match = _refRegex.firstMatch(text);
    return match?.group(1);
  }

  String? _extractRecruteur(String text) {
    final lines = text.split('\n');
    final lowerLines = lines.map((l) => l.toLowerCase()).toList();

    for (int i = 0; i < lowerLines.length; i++) {
      if (lowerLines[i].contains('recruteur') ||
          lowerLines[i].contains('contact') ||
          lowerLines[i].contains('responsable') ||
          lowerLines[i].contains('chargé de recrutement') ||
          lowerLines[i].contains('rh') ||
          lowerLines[i].contains('manager')) {
        final line = lines[i];
        final afterColon = line.split(RegExp(r'[:;]'));
        if (afterColon.length > 1 && afterColon[1].trim().isNotEmpty) {
          return afterColon[1].trim();
        }
        if (i + 1 < lines.length && lines[i + 1].trim().isNotEmpty) {
          return lines[i + 1].trim();
        }
      }
    }

    for (int i = 0; i < lowerLines.length; i++) {
      if (lowerLines[i].contains('objet') || lowerLines[i].contains('subject')) {
        final line = lines[i];
        final afterColon = line.split(RegExp(r'[:;]'));
        if (afterColon.length > 1) {
          return afterColon[1].trim();
        }
      }
    }

    return null;
  }

  String _extractEntreprise(String text) {
    final lines = text.split('\n');

    final entreprisePatterns = [
      RegExp(r'(?:chez|société|entreprise|sas|sa|sarl|eurl|company)\s+([A-Z][A-Za-z\s&\-]+)', caseSensitive: false),
      RegExp(r'(?:de\s+la\s+)?(?:part\s+de\s+)?([A-Z][A-Za-z\s&\-]{2,30})'),
    ];

    for (final pattern in entreprisePatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final name = match.group(1)?.trim();
        if (name != null && name.length >= 2 && !name.toLowerCase().contains('candidature') && !name.toLowerCase().contains('offre')) {
          return name;
        }
      }
    }

    final entrepriseKeywords = ['sas', 'sarl', 'sa', 'eurl', 'inc', 'ltd', 'corp', 'gmbh'];
    for (final line in lines) {
      for (final keyword in entrepriseKeywords) {
        if (line.toLowerCase().contains(keyword)) {
          return line.trim();
        }
      }
    }

    return '';
  }

  String _extractPoste(String text) {
    final lines = text.split('\n');

    final postPatterns = [
      RegExp(r'(?:poste|position|intitulé|titre|offre)\s*[:;]?\s*(.{5,60})', caseSensitive: false),
      RegExp(r'(?:candidature|postulation|candidat)\s+(?:au|pour|en)\s+(?:poste\s+de\s+)?(.{5,60})', caseSensitive: false),
      RegExp(r'(?:(développeur|ingénieur|consultant|technicien|chargé|responsable|directeur|manager|analyste|chef|coordinateur|formateur|architecte|expert|conseiller|assistant|employé|technicien)\s+(?:de\s+)?(?:[a-zé]+\s*){0,5})', caseSensitive: false),
    ];

    for (final pattern in postPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final name = match.group(1)?.trim();
        if (name != null && name.length >= 3) {
          return name;
        }
      }
    }

    for (final line in lines) {
      final lowerLine = line.toLowerCase().trim();
      if (lowerLine.contains('offre d\'emploi') || lowerLine.contains('offre de') || lowerLine.contains('intitulé du poste')) {
        final afterColon = line.split(RegExp(r'[:;]'));
        if (afterColon.length > 1 && afterColon[1].trim().isNotEmpty) {
          return afterColon[1].trim();
        }
      }
    }

    return '';
  }

  Source _detectSource(String text) {
    final lowerText = text.toLowerCase();
    if (lowerText.contains('linkedin') || lowerText.contains('linked in')) return Source.linkedin;
    if (lowerText.contains('indeed') || lowerText.contains('indeed.com')) return Source.indeed;
    if (lowerText.contains('france travail') || lowerText.contains('pole emploi') || lowerText.contains('pôle emploi')) return Source.franceTravail;
    if (lowerText.contains('hellowork') || lowerText.contains('hello work')) return Source.hellowork;
    if (lowerText.contains('@') || lowerText.contains('objet') || lowerText.contains('mail') || lowerText.contains('email')) return Source.email;
    return Source.autre;
  }

  AppStatus _detectStatus(String text) {
    final lowerText = text.toLowerCase();

    if (lowerText.contains('refus') || lowerText.contains('pas de suite') ||
        lowerText.contains('ne pas donner suite') || lowerText.contains('malheureusement')) {
      return AppStatus.refusee;
    }
    if (lowerText.contains('entretien') || lowerText.contains('réunion') ||
        lowerText.contains('entretien à') || lowerText.contains('meeting')) {
      return AppStatus.entretien;
    }
    if (lowerText.contains('accusé de réception') || lowerText.contains('accuse de reception') ||
        lowerText.contains('bien reçu') || lowerText.contains('bien recu')) {
      return AppStatus.accuseReception;
    }
    if (lowerText.contains('candidature envoyée') || lowerText.contains('candidature envoye') ||
        lowerText.contains('merci de votre candidature') || lowerText.contains('nous avons bien')) {
      return AppStatus.envoyee;
    }
    if (lowerText.contains('relance') || lowerText.contains('nous revenons vers vous') ||
        lowerText.contains('délai')) {
      return AppStatus.relanceNecessaire;
    }
    if (lowerText.contains('accepté') || lowerText.contains('retenue') ||
        lowerText.contains('félicitations') || lowerText.contains('vous avez été sélectionné')) {
      return AppStatus.acceptee;
    }
    if (lowerText.contains('en attente') || lowerText.contains('délai de traitement') ||
        lowerText.contains('nous étudions')) {
      return AppStatus.enAttente;
    }

    return AppStatus.envoyee;
  }

  DateTime? _extractEntretienDate(String text) {
    final lowerText = text.toLowerCase();
    final dateKeywords = ['entretien', 'réunion', 'meeting', 'rdv', 'rendez-vous'];

    for (final keyword in dateKeywords) {
      if (lowerText.contains(keyword)) {
        return _extractAnyDate(text);
      }
    }
    return null;
  }

  DateTime? _extractRelance(String text) {
    final lowerText = text.toLowerCase();
    if (lowerText.contains('relance')) {
      return _extractAnyDate(text);
    }
    return null;
  }

  DateTime? _extractAnyDate(String text) {
    final match = _dateRegex.firstMatch(text);
    if (match != null) {
      try {
        final day = int.parse(match.group(1)!);
        final month = int.parse(match.group(2)!);
        var year = int.parse(match.group(3)!);
        if (year < 100) year += 2000;
        return DateTime(year, month, day);
      } catch (_) {}
    }

    final wordMatch = _dateWordsRegex.firstMatch(text);
    if (wordMatch != null) {
      try {
        final day = int.parse(wordMatch.group(1)!);
        final monthStr = wordMatch.group(2)!.toLowerCase();
        final year = int.parse(wordMatch.group(3)!);
        final months = {
          'janvier': 1, 'février': 2, 'mars': 3, 'avril': 4,
          'mai': 5, 'juin': 6, 'juillet': 7, 'août': 8,
          'septembre': 9, 'octobre': 10, 'novembre': 11, 'décembre': 12,
        };
        final month = months[monthStr];
        if (month != null) return DateTime(year, month, day);
      } catch (_) {}
    }

    return null;
  }

  String? _extractDateStr(String text) {
    final match = _dateRegex.firstMatch(text);
    if (match != null) return match.group(0);
    final wordMatch = _dateWordsRegex.firstMatch(text);
    if (wordMatch != null) return wordMatch.group(0);
    return null;
  }

  String? _extractLocalisation(String text) {
    final locRegex = RegExp(
      r'(?:lieu|localisation|ville|adresse|location)\s*[:;]?\s*(.{3,50})',
      caseSensitive: false,
    );
    final match = locRegex.firstMatch(text);
    if (match != null) return match.group(1)?.trim();

    final cityRegex = RegExp(r'\b(\d{5})\s+([A-Z][a-zé]+(?:-[a-zé]+)*)\b');
    final cityMatch = cityRegex.firstMatch(text);
    if (cityMatch != null) return cityMatch.group(0);

    return null;
  }
}
