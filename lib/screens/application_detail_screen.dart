import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../app.dart';
import '../widgets/common_widgets.dart';
import 'add_capture_screen.dart';

class ApplicationDetailScreen extends StatefulWidget {
  final int applicationId;

  const ApplicationDetailScreen({super.key, required this.applicationId});

  @override
  State<ApplicationDetailScreen> createState() => _ApplicationDetailScreenState();
}

class _ApplicationDetailScreenState extends State<ApplicationDetailScreen> {
  Application? _application;
  List<Capture> _captures = [];
  List<StatusHistory> _history = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final provider = Provider.of<AppProvider>(context, listen: false);
    _application = await _getApplication(provider);
    _captures = await provider.getCaptures(widget.applicationId);
    _history = await provider.getHistory(widget.applicationId);
    if (mounted) setState(() => _loading = false);
  }

  Future<Application?> _getApplication(AppProvider provider) async {
    for (final app in provider.applications) {
      if (app.id == widget.applicationId) return app;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _application == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final app = _application!;

    return Scaffold(
      appBar: AppBar(
        title: Text(app.entreprise),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  _editApplication(app);
                  break;
                case 'export_pdf':
                  _exportPdf(app);
                  break;
                case 'delete':
                  _deleteApplication(app);
                  break;
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'edit', child: Text('Modifier')),
              PopupMenuItem(value: 'export_pdf', child: Text('Exporter en PDF')),
              PopupMenuItem(value: 'delete', child: Text('Supprimer')),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, app),
              const SizedBox(height: 24),
              const SectionTitle(title: 'Informations'),
              _buildInfoCard(context, app),
              const SizedBox(height: 24),
              const SectionTitle(title: 'Statut'),
              _buildStatusCard(context, app),
              const SizedBox(height: 24),
              const SectionTitle(title: 'Preuves'),
              _buildCaptureSection(context),
              const SizedBox(height: 24),
              const SectionTitle(title: 'Historique'),
              _buildTimeline(context),
              const SizedBox(height: 24),
              _buildNextActionsCard(context, app),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Application app) {
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text(
              app.entreprise.isNotEmpty ? app.entreprise[0].toUpperCase() : '?',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                app.entreprise,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                app.poste,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(BuildContext context, Application app) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            InfoRow(
              icon: Icons.calendar_today,
              label: 'Date de candidature',
              value: DateFormat('dd/MM/yyyy', 'fr_FR').format(app.dateCandidature),
            ),
            if (app.source != Source.autre)
              InfoRow(icon: Icons.web, label: 'Source', value: app.source.label),
            if (app.localisation != null && app.localisation!.isNotEmpty)
              InfoRow(icon: Icons.location_on, label: 'Localisation', value: app.localisation!),
            if (app.recruteur != null && app.recruteur!.isNotEmpty)
              InfoRow(icon: Icons.person, label: 'Recruteur', value: app.recruteur!),
            if (app.email != null && app.email!.isNotEmpty)
              InfoRow(icon: Icons.email, label: 'Email', value: app.email!),
            if (app.telephone != null && app.telephone!.isNotEmpty)
              InfoRow(icon: Icons.phone, label: 'Téléphone', value: app.telephone!),
            if (app.referenceOffre != null && app.referenceOffre!.isNotEmpty)
              InfoRow(icon: Icons.tag, label: 'Référence offre', value: app.referenceOffre!),
            if (app.url != null && app.url!.isNotEmpty)
              InfoRow(icon: Icons.link, label: 'URL', value: app.url!),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context, Application app) {
    final statusItems = [
      AppStatus.envoyee,
      AppStatus.accuseReception,
      AppStatus.enAttente,
      AppStatus.relanceNecessaire,
      AppStatus.entretien,
      AppStatus.acceptee,
      AppStatus.refusee,
      AppStatus.archivee,
    ];

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StatusBadge(status: app.statut),
            const SizedBox(height: 12),
            const Text(
              'Mettre à jour le statut',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: statusItems.map((s) => ChoiceChip(
                label: Text(s.label),
                selected: app.statut == s,
                onSelected: (_) async {
                  await Provider.of<AppProvider>(context, listen: false)
                      .changeStatus(app.id!, s);
                  if (mounted) _load();
                },
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCaptureSection(BuildContext context) {
    if (_captures.isEmpty) {
      return Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
              const SizedBox(height: 12),
              const Text('Aucune preuve ajoutée'),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => _addCapture(),
                icon: const Icon(Icons.add_a_photo),
                label: const Text('Ajouter une capture'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _captures.length,
            itemBuilder: (context, index) {
              final capture = _captures[index];
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: InkWell(
                  onTap: () => _viewCapture(capture),
                  onLongPress: () => _deleteCapture(capture),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 100,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Image.file(
                              _captureFile(capture.imagePath),
                              width: 100,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Center(
                                child: Icon(Icons.broken_image, size: 32, color: Colors.grey),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('dd/MM', 'fr_FR').format(capture.createdAt),
                            style: const TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: _addCapture,
          icon: const Icon(Icons.add_a_photo),
          label: const Text('Ajouter une capture'),
        ),
      ],
    );
  }

  File _captureFile(String path) {
    return File(path);
  }

  Future<void> _viewCapture(Capture capture) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CaptureGalleryScreen(captures: _captures, initialIndex: _captures.indexOf(capture)),
      ),
    );
  }

  Future<void> _addCapture() async {
    final result = await Navigator.push<Capture>(
      context,
      MaterialPageRoute(
        builder: (_) => AddCaptureScreen(applicationId: widget.applicationId),
      ),
    );
    if (result != null) _load();
  }

  Future<void> _deleteCapture(Capture capture) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer cette capture ?'),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await Provider.of<AppProvider>(context, listen: false).deleteCapture(capture.id!);
      _load();
    }
  }

  Widget _buildTimeline(BuildContext context) {
    if (_history.isEmpty && _captures.isEmpty) {
      return Card(
        margin: EdgeInsets.zero,
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Text('Aucun événement enregistré'),
        ),
      );
    }

    final events = <({DateTime date, String title, String subtitle, IconData icon, Color color})>[];

    for (final h in _history) {
      events.add((
        date: h.createdAt,
        title: '${h.oldStatus.label} → ${h.newStatus.label}',
        subtitle: h.note ?? '',
        icon: Icons.sync,
        color: AppTheme.primaryColor,
      ));
    }

    for (final c in _captures) {
      events.add((
        date: c.createdAt,
        title: 'Capture ajoutée',
        subtitle: c.ocrText != null
            ? '${c.ocrText!.length} caractères reconnus'
            : 'Aucun texte reconnu',
        icon: Icons.photo,
        color: AppTheme.secondaryColor,
      ));
    }

    events.sort((a, b) => b.date.compareTo(a.date));

    return Column(
      children: events.take(20).map((e) => _buildTimelineItem(context, e)).toList(),
    );
  }

  Widget _buildTimelineItem(
    BuildContext context,
    ({DateTime date, String title, String subtitle, IconData icon, Color color}) event,
  ) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: event.color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(event.icon, size: 18, color: event.color),
              ),
              Expanded(
                child: Container(
                  width: 2,
                  color: event.color.withOpacity(0.2),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  if (event.subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      event.subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('dd/MM/yyyy HH:mm', 'fr_FR').format(event.date),
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextActionsCard(BuildContext context, Application app) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Prochaines actions',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (app.dateRelance != null)
              Row(
                children: [
                  const Icon(Icons.alarm, size: 18, color: AppTheme.warningColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Relance prévue le ${DateFormat('dd/MM/yyyy', 'fr_FR').format(app.dateRelance!)}',
                    ),
                  ),
                ],
              ),
            if (app.dateEntretien != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    const Icon(Icons.event, size: 18, color: Color(0xFF7B1FA2)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Entretien le ${DateFormat('dd/MM/yyyy HH:mm', 'fr_FR').format(app.dateEntretien!)}',
                      ),
                    ),
                  ],
                ),
              ),
            if (app.prochainesActions != null && app.prochainesActions!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  app.prochainesActions!,
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ),
            if (app.dateRelance == null && app.dateEntretien == null &&
                (app.prochainesActions == null || app.prochainesActions!.isEmpty))
              Text(
                'Rien de prévu',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => _editApplication(app),
              child: const Text('Modifier les prochaines actions'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editApplication(Application app) async {
    final formKey = GlobalKey<FormState>();
    final entreprise = TextEditingController(text: app.entreprise);
    final poste = TextEditingController(text: app.poste);
    final localisation = TextEditingController(text: app.localisation ?? '');
    final recruteur = TextEditingController(text: app.recruteur ?? '');
    final email = TextEditingController(text: app.email ?? '');
    final telephone = TextEditingController(text: app.telephone ?? '');
    final reference = TextEditingController(text: app.referenceOffre ?? '');
    final url = TextEditingController(text: app.url ?? '');
    final notes = TextEditingController(text: app.notes ?? '');
    final actions = TextEditingController(text: app.prochainesActions ?? '');
    var statut = app.statut;
    var source = app.source;

    DateTime? dateRelance = app.dateRelance;
    DateTime? dateEntretien = app.dateEntretien;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Modifier la candidature',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: entreprise,
                      decoration: const InputDecoration(labelText: 'Entreprise'),
                      validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: poste,
                      decoration: const InputDecoration(labelText: 'Poste'),
                      validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: localisation,
                      decoration: const InputDecoration(labelText: 'Localisation'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: recruteur,
                      decoration: const InputDecoration(labelText: 'Recruteur'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: email,
                      decoration: const InputDecoration(labelText: 'Email'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: telephone,
                      decoration: const InputDecoration(labelText: 'Téléphone'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: reference,
                      decoration: const InputDecoration(labelText: 'Référence offre'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: url,
                      decoration: const InputDecoration(labelText: 'URL'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<Source>(
                      value: source,
                      decoration: const InputDecoration(labelText: 'Source'),
                      items: Source.values.map((s) => DropdownMenuItem(
                        value: s,
                        child: Text(s.label),
                      )).toList(),
                      onChanged: (v) => setModalState(() => source = v!),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<AppStatus>(
                      value: statut,
                      decoration: const InputDecoration(labelText: 'Statut'),
                      items: AppStatus.values.map((s) => DropdownMenuItem(
                        value: s,
                        child: Text(s.label),
                      )).toList(),
                      onChanged: (v) => setModalState(() => statut = v!),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.alarm, color: AppTheme.warningColor),
                      title: Text(
                        dateRelance == null
                            ? 'Date de relance: Aucune'
                            : 'Date de relance: ${DateFormat('dd/MM/yyyy').format(dateRelance!)}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.event),
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: dateRelance ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (date != null) setModalState(() => dateRelance = date);
                        },
                      ),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.event, color: Color(0xFF7B1FA2)),
                      title: Text(
                        dateEntretien == null
                            ? 'Date d\'entretien: Aucune'
                            : 'Date d\'entretien: ${DateFormat('dd/MM/yyyy').format(dateEntretien!)}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.event),
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: dateEntretien ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (date != null) setModalState(() => dateEntretien = date);
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: notes,
                      decoration: const InputDecoration(labelText: 'Notes personnelles'),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: actions,
                      decoration: const InputDecoration(labelText: 'Prochaines actions'),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) return;
                          final updated = app.copyWith(
                            entreprise: entreprise.text,
                            poste: poste.text,
                            statut: statut,
                            source: source,
                            localisation: localisation.text,
                            recruteur: recruteur.text,
                            email: email.text,
                            telephone: telephone.text,
                            referenceOffre: reference.text,
                            url: url.text,
                            notes: notes.text,
                            prochainesActions: actions.text,
                            dateRelance: dateRelance,
                            dateEntretien: dateEntretien,
                            updatedAt: DateTime.now(),
                          );
                          await Provider.of<AppProvider>(context, listen: false)
                              .updateApplication(updated);
                          if (context.mounted) Navigator.pop(context);
                          _load();
                        },
                        child: const Text('Enregistrer'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _exportPdf(Application app) async {
    final provider = Provider.of<AppProvider>(context, listen: false);

    final history = await provider.getHistory(app.id!);
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

    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          pw.Text(
            '${app.entreprise} — ${app.poste}',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Date: ${DateFormat('dd/MM/yyyy').format(app.dateCandidature)}   '
            'Statut: ${app.statut.label}   '
            'Source: ${app.source.label}',
            style: const pw.TextStyle(fontSize: 11),
          ),
          if (app.localisation != null)
            pw.Text('Localisation: ${app.localisation}', style: const pw.TextStyle(fontSize: 11)),
          if (app.recruteur != null)
            pw.Text('Recruteur: ${app.recruteur}', style: const pw.TextStyle(fontSize: 11)),
          if (app.email != null)
            pw.Text('Email: ${app.email}', style: const pw.TextStyle(fontSize: 11)),
          if (app.telephone != null)
            pw.Text('Téléphone: ${app.telephone}', style: const pw.TextStyle(fontSize: 11)),
          if (app.url != null)
            pw.Text('URL: ${app.url}', style: const pw.TextStyle(fontSize: 11)),
          if (app.referenceOffre != null)
            pw.Text('Référence: ${app.referenceOffre}', style: const pw.TextStyle(fontSize: 11)),
          if (app.notes != null) ...[
            pw.SizedBox(height: 8),
            pw.Text('Notes: ${app.notes}', style: const pw.TextStyle(fontSize: 11)),
          ],
          if (history.isNotEmpty) ...[
            pw.SizedBox(height: 12),
            pw.Text('Historique:',
                style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
            ...history.map((h) => pw.Text(
                  '• ${DateFormat('dd/MM/yyyy').format(h.createdAt)}: ${h.oldStatus.label} → ${h.newStatus.label}',
                  style: const pw.TextStyle(fontSize: 10),
                )),
          ],
          if (images.isNotEmpty) ...[
            pw.SizedBox(height: 12),
            pw.Text('Captures:',
                style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),
            pw.Wrap(
              spacing: 8,
              runSpacing: 8,
              children: images.map((image) => pw.Image(image, height: 200)).toList(),
            ),
          ],
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => doc.save(),
      name: 'jobshot_${app.entreprise}',
    );
  }

  Future<void> _deleteApplication(Application app) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Supprimer ${app.entreprise} ?'),
        content: const Text('Toutes les captures et l\'historique seront supprimés.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await Provider.of<AppProvider>(context, listen: false)
          .deleteApplication(app.id!);
      if (mounted) Navigator.pop(context, true);
    }
  }
}

class CaptureGalleryScreen extends StatelessWidget {
  final List<Capture> captures;
  final int initialIndex;

  const CaptureGalleryScreen({super.key, required this.captures, required this.initialIndex});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Preuves')),
      body: PageView.builder(
        controller: PageController(initialPage: initialIndex),
        itemCount: captures.length,
        itemBuilder: (context, index) {
          final capture = captures[index];
          return Column(
            children: [
              Expanded(
                child: InteractiveViewer(
                  maxScale: 5,
                  child: Image.file(
                    File(capture.imagePath),
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Center(
                      child: Icon(Icons.broken_image, size: 64, color: Colors.grey),
                    ),
                  ),
                ),
              ),
              if (capture.ocrText != null && capture.ocrText!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Texte OCR',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          capture.ocrText!,
                          maxLines: 8,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
