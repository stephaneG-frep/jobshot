enum AppStatus {
  aPreparer,
  envoyee,
  accuseReception,
  enAttente,
  relanceNecessaire,
  entretien,
  refusee,
  acceptee,
  archivee;

  String get label {
    switch (this) {
      case AppStatus.aPreparer:
        return 'À préparer';
      case AppStatus.envoyee:
        return 'Candidature envoyée';
      case AppStatus.accuseReception:
        return 'Accusé de réception';
      case AppStatus.enAttente:
        return 'En attente';
      case AppStatus.relanceNecessaire:
        return 'Relance nécessaire';
      case AppStatus.entretien:
        return 'Entretien';
      case AppStatus.refusee:
        return 'Refusée';
      case AppStatus.acceptee:
        return 'Acceptée';
      case AppStatus.archivee:
        return 'Archivée';
    }
  }

  static AppStatus fromString(String s) {
    for (final v in values) {
      if (v.name == s) return v;
    }
    return AppStatus.aPreparer;
  }
}

enum Source {
  email,
  franceTravail,
  indeed,
  linkedin,
  hellowork,
  autre;

  String get label {
    switch (this) {
      case Source.email:
        return 'Email';
      case Source.franceTravail:
        return 'France Travail';
      case Source.indeed:
        return 'Indeed';
      case Source.linkedin:
        return 'LinkedIn';
      case Source.hellowork:
        return 'HelloWork';
      case Source.autre:
        return 'Autre';
    }
  }

  static Source fromString(String s) {
    for (final v in values) {
      if (v.name == s) return v;
    }
    return Source.autre;
  }
}

class Application {
  final int? id;
  final String entreprise;
  final String poste;
  final AppStatus statut;
  final DateTime dateCandidature;
  final Source source;
  final String? url;
  final String? localisation;
  final String? recruteur;
  final String? email;
  final String? telephone;
  final String? referenceOffre;
  final String? notes;
  final String? prochainesActions;
  final DateTime? dateRelance;
  final DateTime? dateEntretien;
  final DateTime createdAt;
  final DateTime updatedAt;

  Application({
    this.id,
    required this.entreprise,
    required this.poste,
    this.statut = AppStatus.aPreparer,
    DateTime? dateCandidature,
    this.source = Source.autre,
    this.url,
    this.localisation,
    this.recruteur,
    this.email,
    this.telephone,
    this.referenceOffre,
    this.notes,
    this.prochainesActions,
    this.dateRelance,
    this.dateEntretien,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : dateCandidature = dateCandidature ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'entreprise': entreprise,
      'poste': poste,
      'statut': statut.name,
      'dateCandidature': dateCandidature.toIso8601String(),
      'source': source.name,
      'url': url,
      'localisation': localisation,
      'recruteur': recruteur,
      'email': email,
      'telephone': telephone,
      'referenceOffre': referenceOffre,
      'notes': notes,
      'prochainesActions': prochainesActions,
      'dateRelance': dateRelance?.toIso8601String(),
      'dateEntretien': dateEntretien?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Application.fromMap(Map<String, dynamic> map) {
    return Application(
      id: map['id'] as int?,
      entreprise: map['entreprise'] as String? ?? '',
      poste: map['poste'] as String? ?? '',
      statut: AppStatus.fromString(map['statut'] as String? ?? ''),
      dateCandidature: map['dateCandidature'] != null
          ? DateTime.parse(map['dateCandidature'] as String)
          : null,
      source: Source.fromString(map['source'] as String? ?? 'autre'),
      url: map['url'] as String?,
      localisation: map['localisation'] as String?,
      recruteur: map['recruteur'] as String?,
      email: map['email'] as String?,
      telephone: map['telephone'] as String?,
      referenceOffre: map['referenceOffre'] as String?,
      notes: map['notes'] as String?,
      prochainesActions: map['prochainesActions'] as String?,
      dateRelance: map['dateRelance'] != null
          ? DateTime.parse(map['dateRelance'] as String)
          : null,
      dateEntretien: map['dateEntretien'] != null
          ? DateTime.parse(map['dateEntretien'] as String)
          : null,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : DateTime.now(),
    );
  }

  Application copyWith({
    int? id,
    String? entreprise,
    String? poste,
    AppStatus? statut,
    DateTime? dateCandidature,
    Source? source,
    String? url,
    String? localisation,
    String? recruteur,
    String? email,
    String? telephone,
    String? referenceOffre,
    String? notes,
    String? prochainesActions,
    DateTime? dateRelance,
    DateTime? dateEntretien,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Application(
      id: id ?? this.id,
      entreprise: entreprise ?? this.entreprise,
      poste: poste ?? this.poste,
      statut: statut ?? this.statut,
      dateCandidature: dateCandidature ?? this.dateCandidature,
      source: source ?? this.source,
      url: url ?? this.url,
      localisation: localisation ?? this.localisation,
      recruteur: recruteur ?? this.recruteur,
      email: email ?? this.email,
      telephone: telephone ?? this.telephone,
      referenceOffre: referenceOffre ?? this.referenceOffre,
      notes: notes ?? this.notes,
      prochainesActions: prochainesActions ?? this.prochainesActions,
      dateRelance: dateRelance ?? this.dateRelance,
      dateEntretien: dateEntretien ?? this.dateEntretien,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class Capture {
  final int? id;
  final int applicationId;
  final String imagePath;
  final String? ocrText;
  final DateTime createdAt;

  Capture({
    this.id,
    required this.applicationId,
    required this.imagePath,
    this.ocrText,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'applicationId': applicationId,
      'imagePath': imagePath,
      'ocrText': ocrText,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Capture.fromMap(Map<String, dynamic> map) {
    return Capture(
      id: map['id'] as int?,
      applicationId: map['applicationId'] as int,
      imagePath: map['imagePath'] as String,
      ocrText: map['ocrText'] as String?,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
    );
  }
}

class StatusHistory {
  final int? id;
  final int applicationId;
  final AppStatus oldStatus;
  final AppStatus newStatus;
  final String? note;
  final DateTime createdAt;

  StatusHistory({
    this.id,
    required this.applicationId,
    required this.oldStatus,
    required this.newStatus,
    this.note,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'applicationId': applicationId,
      'oldStatus': oldStatus.name,
      'newStatus': newStatus.name,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory StatusHistory.fromMap(Map<String, dynamic> map) {
    return StatusHistory(
      id: map['id'] as int?,
      applicationId: map['applicationId'] as int,
      oldStatus: AppStatus.fromString(map['oldStatus'] as String),
      newStatus: AppStatus.fromString(map['newStatus'] as String),
      note: map['note'] as String?,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
    );
  }
}
