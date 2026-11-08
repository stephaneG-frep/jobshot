import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../app.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../services/text_analyzer.dart';

class ValidationScreen extends StatefulWidget {
  final String imagePath;
  final String ocrText;
  final AnalyzedData? analysis;

  const ValidationScreen({
    super.key,
    required this.imagePath,
    required this.ocrText,
    this.analysis,
  });

  @override
  State<ValidationScreen> createState() => _ValidationScreenState();
}

class _ValidationScreenState extends State<ValidationScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _entrepriseController;
  late TextEditingController _posteController;
  late TextEditingController _recruteurController;
  late TextEditingController _emailController;
  late TextEditingController _telephoneController;
  late TextEditingController _referenceController;
  late TextEditingController _urlController;
  late TextEditingController _localisationController;
  late TextEditingController _notesController;
  late TextEditingController _actionsController;
  late TextEditingController _ocrTextController;

  late AppStatus _statut;
  late Source _source;
  DateTime _dateCandidature;
  DateTime? _dateRelance;
  DateTime? _dateEntretien;

  _ValidationScreenState()
      : _dateCandidature = DateTime.now();

  @override
  void initState() {
    super.initState();
    _entrepriseController = TextEditingController(text: widget.analysis?.entreprise ?? '');
    _posteController = TextEditingController(text: widget.analysis?.poste ?? '');
    _recruteurController = TextEditingController(text: widget.analysis?.recruteur ?? '');
    _emailController = TextEditingController(text: widget.analysis?.email ?? '');
    _telephoneController = TextEditingController(text: widget.analysis?.telephone ?? '');
    _referenceController = TextEditingController(text: widget.analysis?.referenceOffre ?? '');
    _urlController = TextEditingController(text: widget.analysis?.url ?? '');
    _localisationController = TextEditingController(text: widget.analysis?.localisation ?? '');
    _notesController = TextEditingController();
    _actionsController = TextEditingController();
    _ocrTextController = TextEditingController(text: widget.ocrText);
    _statut = widget.analysis?.statutProbable ?? AppStatus.envoyee;
    _source = widget.analysis?.source ?? Source.autre;

    if (widget.analysis?.dateRelance != null) _dateRelance = widget.analysis!.dateRelance;
    if (widget.analysis?.dateEntretien != null) _dateEntretien = widget.analysis!.dateEntretien;

    if (widget.analysis?.dateStr != null) {
      final dateMatch = RegExp(r'(\d{1,2})[/\-.](\d{1,2})[/\-.](\d{2,4})').firstMatch(widget.analysis!.dateStr!);
      if (dateMatch != null) {
        try {
          final day = int.parse(dateMatch.group(1)!);
          final month = int.parse(dateMatch.group(2)!);
          var year = int.parse(dateMatch.group(3)!);
          if (year < 100) year += 2000;
          _dateCandidature = DateTime(year, month, day);
        } catch (_) {}
      }
    }
  }

  @override
  void dispose() {
    _entrepriseController.dispose();
    _posteController.dispose();
    _recruteurController.dispose();
    _emailController.dispose();
    _telephoneController.dispose();
    _referenceController.dispose();
    _urlController.dispose();
    _localisationController.dispose();
    _notesController.dispose();
    _actionsController.dispose();
    _ocrTextController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = Provider.of<AppProvider>(context, listen: false);

    final application = Application(
      entreprise: _entrepriseController.text,
      poste: _posteController.text,
      statut: _statut,
      dateCandidature: _dateCandidature,
      source: _source,
      url: _urlController.text.isEmpty ? null : _urlController.text,
      localisation: _localisationController.text.isEmpty ? null : _localisationController.text,
      recruteur: _recruteurController.text.isEmpty ? null : _recruteurController.text,
      email: _emailController.text.isEmpty ? null : _emailController.text,
      telephone: _telephoneController.text.isEmpty ? null : _telephoneController.text,
      referenceOffre: _referenceController.text.isEmpty ? null : _referenceController.text,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
      prochainesActions: _actionsController.text.isEmpty ? null : _actionsController.text,
      dateRelance: _dateRelance,
      dateEntretien: _dateEntretien,
    );

    try {
      final appId = await provider.addApplication(application);

      final capture = Capture(
        applicationId: appId,
        imagePath: widget.imagePath,
        ocrText: _ocrTextController.text,
      );
      await provider.addCapture(capture);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Candidature enregistrée ✓'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'enregistrement: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Valider les informations'),
        actions: [
          TextButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.check),
            label: const Text('Enregistrer'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(widget.imagePath),
                  height: 150,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 150,
                    color: Colors.grey.withOpacity(0.1),
                    child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Informations de la candidature',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _entrepriseController,
                decoration: const InputDecoration(labelText: 'Entreprise *'),
                validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _posteController,
                decoration: const InputDecoration(labelText: 'Poste *'),
                validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _recruteurController,
                decoration: const InputDecoration(labelText: 'Recruteur'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _telephoneController,
                decoration: const InputDecoration(labelText: 'Téléphone'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _referenceController,
                decoration: const InputDecoration(labelText: 'Référence offre'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _urlController,
                decoration: const InputDecoration(labelText: 'URL de l\'offre'),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _localisationController,
                decoration: const InputDecoration(labelText: 'Localisation'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<AppStatus>(
                      value: _statut,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Statut'),
                      items: AppStatus.values.map((s) => DropdownMenuItem(
                        value: s,
                        child: Text(s.label, overflow: TextOverflow.ellipsis),
                      )).toList(),
                      onChanged: (v) => setState(() => _statut = v!),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<Source>(
                      value: _source,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Source'),
                      items: Source.values.map((s) => DropdownMenuItem(
                        value: s,
                        child: Text(s.label, overflow: TextOverflow.ellipsis),
                      )).toList(),
                      onChanged: (v) => setState(() => _source = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today, color: AppTheme.primaryColor),
                title: Text('Date de candidature'),
                subtitle: Text(DateFormat('dd/MM/yyyy', 'fr_FR').format(_dateCandidature)),
                trailing: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _dateCandidature,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (date != null) setState(() => _dateCandidature = date);
                  },
                ),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.alarm, color: AppTheme.warningColor),
                title: const Text('Date de relance'),
                subtitle: Text(
                  _dateRelance == null
                      ? 'Aucune'
                      : DateFormat('dd/MM/yyyy', 'fr_FR').format(_dateRelance!),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_dateRelance != null)
                      IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () => setState(() => _dateRelance = null),
                      ),
                    IconButton(
                      icon: const Icon(Icons.event),
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _dateRelance ?? DateTime.now().add(const Duration(days: 7)),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (date != null) setState(() => _dateRelance = date);
                      },
                    ),
                  ],
                ),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event, color: Color(0xFF7B1FA2)),
                title: const Text('Date d\'entretien'),
                subtitle: Text(
                  _dateEntretien == null
                      ? 'Aucune'
                      : DateFormat('dd/MM/yyyy', 'fr_FR').format(_dateEntretien!),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_dateEntretien != null)
                      IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () => setState(() => _dateEntretien = null),
                      ),
                    IconButton(
                      icon: const Icon(Icons.event),
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _dateEntretien ?? DateTime.now().add(const Duration(days: 7)),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (date != null) setState(() => _dateEntretien = date);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: 'Notes personnelles'),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _actionsController,
                decoration: const InputDecoration(labelText: 'Prochaines actions'),
                maxLines: 2,
              ),
              const SizedBox(height: 20),
              const Text(
                'Texte OCR (corrigeable)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _ocrTextController,
                maxLines: 8,
                decoration: const InputDecoration(
                  hintText: 'Texte extrait de l\'image...',
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.check),
                label: const Text('Enregistrer la candidature'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
