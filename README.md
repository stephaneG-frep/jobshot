# JobShot

**JobShot** est une application Flutter Android permettant d'enregistrer et de suivre vos candidatures à partir de simples **captures d'écran**.

Le principe :

```
CAPTURE D'ÉCRAN
  → IMPORT DANS JOBSHOT
  → OCR
  → ANALYSE DU TEXTE
  → EXTRACTION DES INFORMATIONS
  → CRÉATION D'UNE FICHE CANDIDATURE
  → CONSERVATION DE LA CAPTURE COMME PREUVE
```

Prise en charge : emails de candidature, accusés de réception, réponses recruteur, refus, convocations à entretien, annonces France Travail, Indeed, LinkedIn, HelloWork, SMS, etc.

---

## 📦 Fonctionnalités

- **Import de captures** : galerie, fichiers, plusieurs captures par candidature
- **OCR local** : extraction automatique du texte visible (Google ML Kit, fonctionne hors ligne)
- **Analyse automatique** : entreprise, poste, recruteur, email, date, source, référence, lieu, type de message, date d'entretien
- **9 statuts** : À préparer, Candidature envoyée, Accusé de réception, En attente, Relance nécessaire, Entretien, Refusée, Acceptée, Archivée
- **Regroupement intelligent** : détection qu'une nouvelle capture concerne une candidature existante
- **Fiches candidatures complètes** avec preuves, texte OCR et historique chronologique
- **Tableau de bord** avec statistiques et section « À faire aujourd'hui »
- **Recherche & filtres** (statut, période, source, entreprise) et tri
- **Stockage local offline** (SQLite) avec persistance après redémarrage
- **Export PDF** des démarches (semaine, mois, période personnalisée)
- **Sauvegarde / restauration** complète des données
- **Mode clair + sombre**, Material 3, design premium adapté aux petits écrans

## 🔒 Confidentialité

- Traitement **100 % local** sur votre appareil
- Aucune capture envoyée vers un serveur
- Aucune télémétrie intrusive
- Les fonctionnalités IA externes (si activées plus tard) demanderaient votre autorisation explicite

## 🖥️ Écrans

Splash · Onboarding · Accueil/Dashboard · Importer capture · Aperçu capture · Analyse OCR · Validation des informations · Liste candidatures · Détail candidature · Timeline · Galerie des preuves · Recherche · Calendrier · Export PDF · Sauvegarde/Restauration · Paramètres · À propos / Mode d'emploi

---

## 🚀 Installation sur smartphone Android

1. Téléchargez le fichier `JobShot_v1.0.0_arm64.apk` (ou `app-release.apk`)
2. Copiez-le sur votre smartphone (par ex. dans `Download/JobShot/`)
3. Ouvrez le fichier APK avec votre gestionnaire de fichiers
4. Autorisez l'installation d'applications inconnues si demandé
5. Lancez **JobShot**

> ⚠️ L'APK est signé avec une clé de débug. Pour une distribution officielle, générez une clé de signature de release (voir plus bas).

---

## 🛠️ Compilation depuis le code source

### Prérequis

- Flutter SDK (3.44 ou ultérieur)
- Android SDK (platform android-36, build-tools)
- Java 17

### Étapes

```bash
# 1. Clone / placez le projet
cd jobshot

# 2. Récupérez les dépendances
flutter pub get

# 3. Analyse statique
flutter analyze

# 4. Tests
flutter test

# 5. Build APK (toutes architectures)
flutter build apk --release

# 6. Build APK ARM64 uniquement (plus léger, recommandé smartphone)
flutter build apk --release --target-platform android-arm64
```

L'APK généré se trouve dans :

```
build/app/outputs/flutter-apk/app-release.apk
```

### Personnalisation de l'identité

`android/app/build.gradle.kts` : l'`applicationId` est `com.jobshot.app`.

### Signature de release (obligatoire pour distribuable)

```bash
# Générer une clé
keytool -genkey -v -keystore ~/upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload

# Créer android/key.properties
storePassword=<mot de passe>
keyPassword=<mot de passe>
keyAlias=upload
storeFile=<chemin complet vers upload-keystore.jks>

# Puis référencer la signature dans android/app/build.gradle.kts
```

---

## 🧪 Tests

Tous les tests passent (`flutter test`). Ils couvrent :
- Le modèle de données (Application, Capture, AppStatus)
- L'analyse de texte (email, source, statut, date)

## 📁 Structure du projet

```
lib/
├── main.dart                 # Point d'entrée
├── app.dart                  # Thème Material 3, couleurs de l'appli
├── models/
│   └── models.dart           # Application, Capture, StatusHistory, enums
├── database/
│   └── database_helper.dart  # SQLite (sqflite)
├── providers/
│   ├── app_provider.dart     # État global, logique métier
│   └── theme_provider.dart   # Thème clair/sombre
├── screens/                  # Tous les écrans
├── services/
│   ├── ocr_service.dart      # OCR Google ML Kit
│   ├── text_analyzer.dart    # Analyse automatique de texte
│   └── pdf_export_service.dart # Génération PDF
└── widgets/
    └── common_widgets.dart   # Widgets réutilisables
```

---

## 🔌 Architecture IA future (optionnelle)

L'analyse de base fonctionne **sans API payante** (analyses par expressions régulières et heuristiques dans `text_analyzer.dart`).

Pour ajouter une analyse IA avancée (OpenAI, Claude, Gemini, Mistral) :
- Ajoutez un nouveau service `AIService`
- Implémentez l'interface avec votre fournisseur
- **Aucune clé API n'est codée en dur** : les clés seront stockées de manière sécurisée dans les Réglages
- L'envoi de texte à un service externe nécessitera toujours une confirmation explicite de l'utilisateur

---

## 📄 Licence

Projet privé — JobShot.
