import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../app.dart';
import '../providers/app_provider.dart';
import '../providers/theme_provider.dart';
import '../models/models.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Réglages')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(
            title: 'Apparence',
            children: [
              _buildThemeTile(context),
            ],
          ),
          _buildSection(
            title: 'Rapports',
            children: [
              _buildSettingTile(
                icon: Icons.picture_as_pdf,
                title: 'Exporter le rapport PDF',
                subtitle: 'Générer un rapport de vos démarches',
                color: AppTheme.errorColor,
                onTap: () => _exportPdf(context),
              ),
            ],
          ),
          _buildSection(
            title: 'Sauvegarde',
            children: [
              _buildSettingTile(
                icon: Icons.save_alt,
                title: 'Sauvegarder',
                subtitle: 'Exporter toutes les données',
                color: AppTheme.successColor,
                onTap: () => _exportBackup(context),
              ),
              _buildSettingTile(
                icon: Icons.restore,
                title: 'Restaurer',
                subtitle: 'Importer une sauvegarde',
                color: AppTheme.warningColor,
                onTap: () => _restoreBackup(context),
              ),
            ],
          ),
          _buildSection(
            title: 'À propos',
            children: [
              _buildSettingTile(
                icon: Icons.info,
                title: 'Mode d\'emploi',
                subtitle: 'Comment utiliser JobShot',
                color: AppTheme.primaryColor,
                onTap: () => _showGuide(context),
              ),
              const ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                leading: Icon(Icons.shield_outlined, color: AppTheme.successColor),
                title: Text('Confidentialité'),
                subtitle: Text('Vos données restent sur votre appareil'),
                dense: true,
              ),
              const ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                leading: Icon(Icons.verified_user_outlined, color: AppTheme.primaryColor),
                title: Text('Version 1.0.0'),
                dense: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 16, 0, 8),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Card(
          margin: EdgeInsets.zero,
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildThemeTile(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          leading: const Icon(Icons.brightness_6, color: AppTheme.primaryColor),
          title: const Text('Thème'),
          subtitle: Text(
            switch (themeProvider.themeMode) {
              ThemeMode.light => 'Clair',
              ThemeMode.dark => 'Sombre',
              ThemeMode.system => 'Système',
            },
          ),
          trailing: DropdownButton<ThemeMode>(
            value: themeProvider.themeMode,
            underline: const SizedBox.shrink(),
            items: const [
              DropdownMenuItem(value: ThemeMode.light, child: Text('Clair')),
              DropdownMenuItem(value: ThemeMode.dark, child: Text('Sombre')),
              DropdownMenuItem(value: ThemeMode.system, child: Text('Système')),
            ],
            onChanged: (mode) {
              if (mode != null) themeProvider.setThemeMode(mode);
            },
          ),
        );
      },
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
      dense: true,
    );
  }

  Future<void> _exportPdf(BuildContext context) async {
    final provider = Provider.of<AppProvider>(context, listen: false);

    final apps = provider.applications;

    if (apps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucune candidature à exporter')),
      );
      return;
    }

    try {
      final historyMap = <int, List<StatusHistory>>{};
      final captureImagesMap = <int, List<pw.MemoryImage>>{};
      for (final app in apps) {
        historyMap[app.id!] = await provider.getHistory(app.id!);
        final captures = await provider.getCaptures(app.id!);
        final images = <pw.MemoryImage>[];
        for (final capture in captures) {
          try {
            final file = File(capture.imagePath);
            if (await file.exists()) {
              images.add(pw.MemoryImage(await file.readAsBytes()));
            }
          } catch (_) {}
        }
        captureImagesMap[app.id!] = images;
      }

      final doc = pw.Document();
      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          header: (context) => pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(bottom: 16),
            child: pw.Text(
              'Généré le ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
            ),
          ),
          build: (context) => [
            pw.Text(
              'Rapport de démarches JobShot',
              style: const pw.TextStyle(
                fontSize: 22,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue800,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              '${apps.length} candidatures',
              style: const pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
            ),
            pw.Divider(color: PdfColors.blue200, thickness: 1.5),
            pw.SizedBox(height: 12),
            ...apps.map((app) => _buildPdfApp(
                  app,
                  historyMap[app.id] ?? [],
                  captureImagesMap[app.id] ?? [],
                )),
          ],
        ),
      );

      await Printing.layoutPdf(
        onLayout: (format) async => doc.save(),
        name: 'jobshot_report',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur d\'export: $e')),
      );
    }
  }

  pw.Widget _buildPdfApp(
    Application app,
    List<StatusHistory> history,
    List<pw.MemoryImage> captureImages,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: PdfColors.blue50,
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                '${app.entreprise} — ${app.poste}',
                style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue900,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'Date: ${DateFormat('dd/MM/yyyy').format(app.dateCandidature)}   '
                'Statut: ${app.statut.label}   '
                'Source: ${app.source.label}',
                style: const pw.TextStyle(fontSize: 10),
              ),
              if (app.localisation != null)
                pw.Text('Localisation: ${app.localisation}',
                    style: const pw.TextStyle(fontSize: 10)),
              if (app.recruteur != null)
                pw.Text('Recruteur: ${app.recruteur}',
                    style: const pw.TextStyle(fontSize: 10)),
              if (app.email != null)
                pw.Text('Email: ${app.email}',
                    style: const pw.TextStyle(fontSize: 10)),
              if (app.url != null)
                pw.Text('URL: ${app.url}',
                    style: const pw.TextStyle(fontSize: 10)),
              if (app.referenceOffre != null)
                pw.Text('Référence: ${app.referenceOffre}',
                    style: const pw.TextStyle(fontSize: 10)),
              if (app.notes != null)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 4),
                  child: pw.Text('Notes: ${app.notes}',
                      style: const pw.TextStyle(fontSize: 10)),
                ),
              if (history.isNotEmpty) ...[
                pw.SizedBox(height: 4),
                pw.Text('Historique:',
                    style: pw.TextStyle(
                        fontSize: 10, fontWeight: pw.FontWeight.bold)),
                ...history.map((h) => pw.Text(
                      '• ${DateFormat('dd/MM/yyyy').format(h.createdAt)}: ${h.oldStatus.label} → ${h.newStatus.label}',
                      style: const pw.TextStyle(fontSize: 9),
                    )),
              ],
              if (captureImages.isNotEmpty) ...[
                pw.SizedBox(height: 8),
                pw.Text('Captures:',
                    style: pw.TextStyle(
                        fontSize: 10, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 4),
                pw.Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: captureImages
                      .map((image) => pw.Image(image, height: 150))
                      .toList(),
                ),
              ],
            ],
          ),
        ),
        pw.SizedBox(height: 12),
      ],
    );
  }

  Future<void> _exportBackup(BuildContext context) async {
    final provider = Provider.of<AppProvider>(context, listen: false);
    try {
      final data = await provider.exportData();
      final jsonString = _encodeBackup(data);
      final bytes = Uint8List.fromList(jsonString.codeUnits);

      await Printing.sharePdf(
        bytes: bytes,
        filename: 'jobshot_backup.txt',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sauvegarde partagée')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur de sauvegarde: $e')),
      );
    }
  }

  String _encodeBackup(dynamic data) {
    final buffer = StringBuffer();
    buffer.writeln('JOBSHOT_BACKUP_V1');
    buffer.writeln((data['exportDate'] as String?) ?? DateTime.now().toIso8601String());
    buffer.writeln('---APPLICATIONS---');
    for (final app in data['applications'] as List) {
      buffer.writeln('APP|${app['id']}|${app['entreprise']}|${app['poste']}|${app['statut']}|${app['dateCandidature']}|${app['source']}');
    }
    buffer.writeln('---CAPTURES---');
    for (final cap in data['captures'] as List) {
      buffer.writeln('CAP|${cap['id']}|${cap['applicationId']}|${cap['imagePath']}');
    }
    buffer.writeln('---HISTORY---');
    for (final hist in data['status_history'] as List) {
      buffer.writeln('HIST|${hist['applicationId']}|${hist['oldStatus']}|${hist['newStatus']}|${hist['createdAt']}');
    }
    return buffer.toString();
  }

  Future<void> _restoreBackup(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        dialogTitle: 'Choisir une sauvegarde JobShot',
      );
      if (result == null || result.files.isEmpty) return;

      final file = File(result.files.single.path!);
      final content = await file.readAsString();
      if (!content.startsWith('JOBSHOT_BACKUP_V1')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fichier de sauvegarde invalide')),
        );
        return;
      }

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Restaurer la sauvegarde ?'),
          content: const Text('Toutes les données actuelles seront remplacées.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Restaurer'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      final data = _decodeBackup(content);
      if (data == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible de lire la sauvegarde')),
        );
        return;
      }

      final provider = Provider.of<AppProvider>(context, listen: false);
      await provider.importData(data);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sauvegarde restaurée ✓'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur de restauration: $e')),
      );
    }
  }

  Map<String, dynamic>? _decodeBackup(String content) {
    try {
      final lines = content.split('\n');
      final apps = <Map<String, dynamic>>[];
      final captures = <Map<String, dynamic>>[];
      final history = <Map<String, dynamic>>[];

      String currentSection = '';
      for (final line in lines) {
        if (line == '---APPLICATIONS---') {
          currentSection = 'apps';
          continue;
        }
        if (line == '---CAPTURES---') {
          currentSection = 'captures';
          continue;
        }
        if (line == '---HISTORY---') {
          currentSection = 'history';
          continue;
        }
        if (line.isEmpty) continue;

        final parts = line.split('|');
        if (parts.isEmpty) continue;

        switch (currentSection) {
          case 'apps':
            if (parts[0] == 'APP') {
              apps.add({
                'id': int.parse(parts[1]),
                'entreprise': parts[2],
                'poste': parts[3],
                'statut': parts[4],
                'dateCandidature': parts[5],
                'source': parts[6],
              });
            }
            break;
          case 'captures':
            if (parts[0] == 'CAP') {
              captures.add({
                'id': int.parse(parts[1]),
                'applicationId': int.parse(parts[2]),
                'imagePath': parts.sublist(3).join('|'),
              });
            }
            break;
          case 'history':
            if (parts[0] == 'HIST') {
              history.add({
                'applicationId': int.parse(parts[1]),
                'oldStatus': parts[2],
                'newStatus': parts[3],
                'createdAt': parts[4],
              });
            }
            break;
        }
      }

      return {
        'applications': apps,
        'captures': captures,
        'status_history': history,
      };
    } catch (e) {
      return null;
    }
  }

  void _showGuide(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: GuideContent(),
        ),
      ),
    );
  }
}

class GuideContent extends StatelessWidget {
  const GuideContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Mode d\'emploi JobShot',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        const _GuideStep(
          number: 1,
          icon: Icons.camera_alt,
          title: 'Importez une capture',
          text: 'Prenez une capture d\'écran de votre candidature (email, annonce, réponse) et importez-la via l\'onglet "Importer" ou le bouton central.',
        ),
        const _GuideStep(
          number: 2,
          icon: Icons.document_scanner,
          title: 'Vérifiez le texte reconnu',
          text: 'Le texte est extrait automatiquement par OCR. Vous pouvez le corriger sur l\'écran de validation.',
        ),
        const _GuideStep(
          number: 3,
          icon: Icons.edit,
          title: 'Validez les informations',
          text: 'Vérifiez et corrigez l\'entreprise, le poste, le statut et toutes les autres informations détectées, puis enregistrez.',
        ),
        const _GuideStep(
          number: 4,
          icon: Icons.timeline,
          title: 'Suivez vos démarches',
          text: 'Ajoutez d\'autres captures à la même candidature, changez le statut, planifiez des relances et des entretiens.',
        ),
        const _GuideStep(
          number: 5,
          icon: Icons.picture_as_pdf,
          title: 'Exportez vos rapports',
          text: 'Générez un rapport PDF de vos démarches' ,
        ),
      ],
    );
  }
}

class _GuideStep extends StatelessWidget {
  final int number;
  final IconData icon;
  final String title;
  final String text;

  const _GuideStep({
    required this.number,
    required this.icon,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              color: AppTheme.primaryColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$number',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 18, color: AppTheme.primaryColor),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
