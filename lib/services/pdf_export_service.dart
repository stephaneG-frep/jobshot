import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../models/models.dart';

class PdfExportService {
  PdfExportService._();
  static final PdfExportService instance = PdfExportService._();

  Future<Uint8List> createReport(
    List<Application> applications,
    Map<int, List<StatusHistory>> historyMap,
    {required DateTime from, required DateTime to, required String title}) async {
    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        header: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(bottom: 16),
          child: pw.Text(
            'Généré le ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
        ),
        build: (context) => [
          pw.Text(
            'Rapport de démarches',
            style: const pw.TextStyle(
              fontSize: 22,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue800,
            ),
          ),
          pw.Text(
            title,
            style: const pw.TextStyle(fontSize: 13, color: PdfColors.grey600),
          ),
          pw.SizedBox(height: 12),
          pw.Divider(color: PdfColors.blue200, thickness: 1.5),
          pw.SizedBox(height: 8),
          pw.Text(
            '${applications.length} candidatures',
            style: const pw.TextStyle(
              fontSize: 11,
              color: PdfColors.grey700,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 16),
          ...applications.map((app) => _buildAppSection(app, historyMap[app.id] ?? [])),
        ],
      ),
    );

    return doc.save();
  }

  pw.Widget _buildAppSection(Application app, List<StatusHistory> history) {
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
              pw.Table(
                columnWidths: {0: const pw.FlexColumnWidth(1), 1: const pw.FlexColumnWidth(2)},
                children: [
                  _row('Date', _formatDate(app.dateCandidature)),
                  _row('Statut', app.statut.label),
                  _row('Source', app.source.label),
                  if (app.localisation != null) _row('Localisation', app.localisation!),
                  if (app.recruteur != null) _row('Recruteur', app.recruteur!),
                  if (app.email != null) _row('Email', app.email!),
                  if (app.referenceOffre != null) _row('Référence', app.referenceOffre!),
                  if (app.url != null) _row('URL', app.url!),
                ],
              ),
            ],
          ),
        ),
        if (history.isNotEmpty) ...[
          pw.SizedBox(height: 8),
          pw.Text(
            'Historique',
            style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 4),
          ...history.map((h) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 3),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  '• ${_formatDate(h.createdAt)}: ',
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                ),
                pw.Expanded(
                  child: pw.Text(
                    '${h.oldStatus.label} → ${h.newStatus.label}',
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                ),
              ],
            ),
          )),
        ],
        if (app.notes != null && app.notes!.isNotEmpty) ...[
          pw.SizedBox(height: 6),
          pw.Text('Notes: ${app.notes}', style: const pw.TextStyle(fontSize: 9)),
        ],
        pw.SizedBox(height: 16),
      ],
    );
  }

  pw.TableRow _row(String label, String value) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 3),
          child: pw.Text(label, style: const pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 3),
          child: pw.Text(value, style: const pw.TextStyle(fontSize: 10)),
        ),
      ],
    );
  }

  String _formatDate(DateTime d) {
    return '${d.day}/${d.month}/${d.year}';
  }
}
