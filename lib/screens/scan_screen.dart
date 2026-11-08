import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import '../app.dart';
import '../services/ocr_service.dart';
import '../services/text_analyzer.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import 'validation_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final _picker = ImagePicker();
  String? _imagePath;
  bool _processing = false;
  String? _ocrText;
  AnalyzedData? _analysis;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final permissions = await _checkPermissions();
      if (!permissions) {
        _showPermissionDialog();
        return;
      }

      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 2000,
        maxHeight: 2000,
        imageQuality: 85,
      );

      if (picked != null && mounted) {
        await _processImage(File(picked.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible d\'importer l\'image')),
        );
      }
    }
  }

  Future<bool> _checkPermissions() async {
    return true;
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission requise'),
        content: const Text('Veuillez autoriser l\'accès aux photos pour importer vos captures.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _processImage(File originalFile) async {
    setState(() {
      _processing = true;
      _imagePath = null;
    });

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final captureDir = Directory(p.join(appDir.path, 'captures'));
      if (!await captureDir.exists()) await captureDir.create(recursive: true);

      final filename = 'capture_${DateTime.now().millisecondsSinceEpoch}.png';
      final destFile = File(p.join(captureDir.path, filename));
      await originalFile.copy(destFile.path);

      if (mounted) {
        setState(() {
          _imagePath = destFile.path;
          _ocrText = null;
          _analysis = null;
        });

        final ocrText = await OcrService.instance.recognizeText(destFile.path);

        if (mounted) {
          setState(() {
            _ocrText = ocrText;
            _analysis = TextAnalyzer.instance.analyze(ocrText);
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du traitement: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Importer une capture')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_processing)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 12),
                      Text('Analyse de l\'image...'),
                    ],
                  ),
                ),
              )
            else if (_imagePath != null)
              _buildPreview()
            else
              _buildImportOptions(),
          ],
        ),
      ),
    );
  }

  Widget _buildImportOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 20),
        _buildOptionCard(
          icon: Icons.photo_library,
          title: 'Choisir depuis la galerie',
          subtitle: 'Importez une capture existante',
          color: AppTheme.primaryColor,
          onTap: () => _pickImage(ImageSource.gallery),
        ),
        const SizedBox(height: 16),
        _buildOptionCard(
          icon: Icons.folder_open,
          title: 'Choisir depuis les fichiers',
          subtitle: 'Parcourez vos fichiers',
          color: AppTheme.secondaryColor,
          onTap: () => _pickImage(ImageSource.gallery),
        ),
        const SizedBox(height: 32),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Comment ça marche ?',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const _StepRow(step: '1', title: 'Importez votre capture', icon: Icons.add_photo_alternate),
                const _StepRow(step: '2', title: 'Le texte est extrait automatiquement', icon: Icons.document_scanner),
                const _StepRow(step: '3', title: 'Corrigez les informations', icon: Icons.edit),
                const _StepRow(step: '4', title: 'Suivez votre démarche', icon: Icons.timeline),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 28, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            File(_imagePath!),
            height: 400,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Container(
              height: 400,
              color: Colors.grey.withOpacity(0.1),
              child: const Center(
                child: Icon(Icons.broken_image, size: 64, color: Colors.grey),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (_ocrText != null && _ocrText!.isNotEmpty) ...[
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.check_circle, color: AppTheme.successColor),
                      SizedBox(width: 8),
                      Text(
                        'Texte extrait',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _ocrText!,
                      maxLines: 10,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_analysis != null) ...[
            const SizedBox(height: 16),
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Informations détectées',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    _buildAnalysisRow('Entreprise', _analysis!.entreprise),
                    _buildAnalysisRow('Poste', _analysis!.poste),
                    _buildAnalysisRow('Statut', _analysis!.statutProbable.label),
                    _buildAnalysisRow('Source', _analysis!.source.label),
                    if (_analysis!.recruteur != null) _buildAnalysisRow('Recruteur', _analysis!.recruteur!),
                    if (_analysis!.email != null) _buildAnalysisRow('Email', _analysis!.email!),
                    if (_analysis!.localisation != null) _buildAnalysisRow('Lieu', _analysis!.localisation!),
                    if (_analysis!.referenceOffre != null) _buildAnalysisRow('Réf.', _analysis!.referenceOffre!),
                  ],
                ),
              ),
            ),
          ],
        ] else if (_ocrText != null)
          const Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.warning, color: AppTheme.warningColor),
                  SizedBox(width: 8),
                  Expanded(child: Text('Aucun texte reconnu sur cette image. Vous pouvez quand même enregistrer la capture comme preuve.')),
                ],
              ),
            ),
          ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickImage(ImageSource.gallery),
                icon: const Icon(Icons.replay),
                label: const Text('Autre image'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _ocrText != null
                    ? () => _proceedToValidation()
                    : null,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Continuer'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAnalysisRow(String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _proceedToValidation() async {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final match = provider.findMatchingApplication(_ocrText ?? '');

    if (match != null) {
      final action = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Candidature détectée'),
          content: Text(
            'Cette capture semble concerner ${match.entreprise} — ${match.poste}.\n\n'
            'Voulez-vous l\'ajouter à cette candidature ou créer une nouvelle candidature ?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, 'new'),
              child: const Text('Nouvelle candidature'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, 'existing'),
              child: const Text('Ajouter à cette candidature'),
            ),
          ],
        ),
      );

      if (action == 'existing' && mounted) {
        final capture = Capture(
          applicationId: match.id!,
          imagePath: _imagePath!,
          ocrText: _ocrText,
        );
        await provider.addCapture(capture);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Capture ajoutée à ${match.entreprise}')),
          );
          Navigator.pop(context);
        }
        return;
      }
    }

    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ValidationScreen(
            imagePath: _imagePath!,
            ocrText: _ocrText ?? '',
            analysis: _analysis,
          ),
        ),
      );
    }
  }
}

class _StepRow extends StatelessWidget {
  final String step;
  final String title;
  final IconData icon;

  const _StepRow({required this.step, required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: AppTheme.primaryColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                step,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Icon(icon, size: 16, color: AppTheme.primaryColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(title, style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
