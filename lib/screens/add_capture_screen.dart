import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import '../app.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../services/ocr_service.dart';

class AddCaptureScreen extends StatefulWidget {
  final int applicationId;

  const AddCaptureScreen({super.key, required this.applicationId});

  @override
  State<AddCaptureScreen> createState() => _AddCaptureScreenState();
}

class _AddCaptureScreenState extends State<AddCaptureScreen> {
  final _picker = ImagePicker();
  String? _imagePath;
  bool _processing = false;
  String? _ocrText;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajouter une capture')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_processing)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_imagePath != null)
              _buildResult()
            else
              _buildPickerOptions(),
          ],
        ),
      ),
    );
  }

  Widget _buildPickerOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 20),
        Card(
          margin: EdgeInsets.zero,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _pickImage(ImageSource.gallery),
            child: const Padding(
              padding: EdgeInsets.all(18),
              child: Row(
                children: [
                  Icon(Icons.photo_library, color: AppTheme.primaryColor, size: 32),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Choisir depuis la galerie',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Importez une capture existante',
                          style: TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 2000,
        maxHeight: 2000,
        imageQuality: 85,
      );
      if (picked == null) return;

      setState(() => _processing = true);

      final appDir = await getApplicationDocumentsDirectory();
      final captureDir = Directory(p.join(appDir.path, 'captures'));
      if (!await captureDir.exists()) await captureDir.create(recursive: true);

      final filename = 'capture_${DateTime.now().millisecondsSinceEpoch}.png';
      final destFile = File(p.join(captureDir.path, filename));
      await File(picked.path).copy(destFile.path);

      final ocrText = await OcrService.instance.recognizeText(destFile.path);

      if (mounted) {
        setState(() {
          _imagePath = destFile.path;
          _ocrText = ocrText;
          _processing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _processing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Widget _buildResult() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            File(_imagePath!),
            height: 300,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Container(
              height: 300,
              color: Colors.grey.withOpacity(0.1),
              child: const Center(child: Icon(Icons.broken_image, size: 64, color: Colors.grey)),
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (_ocrText != null && _ocrText!.isNotEmpty)
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                _ocrText!
                    .split('\n')
                    .take(8)
                    .join('\n'),
                maxLines: 8,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() {
                  _imagePath = null;
                  _ocrText = null;
                }),
                child: const Text('Annuler'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.check),
                label: const Text('Enregistrer'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _save() async {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final capture = Capture(
      applicationId: widget.applicationId,
      imagePath: _imagePath!,
      ocrText: _ocrText,
    );

    try {
      await provider.addCapture(capture);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Capture enregistrée ✓'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }
}
