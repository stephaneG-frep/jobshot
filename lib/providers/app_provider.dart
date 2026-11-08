import 'package:flutter/material.dart';
import '../models/models.dart';
import '../database/database_helper.dart';

class AppProvider extends ChangeNotifier {
  final DatabaseHelper _db;
  List<Application> _applications = [];
  List<Application> _filteredApplications = [];
  bool _isLoading = false;
  String _searchQuery = '';
  AppStatus? _filterStatus;
  String? _filterSource;

  AppProvider(this._db) {
    loadApplications();
  }

  List<Application> get applications =>
      _filteredApplications.isNotEmpty || _searchQuery.isNotEmpty || _filterStatus != null || _filterSource != null
          ? _filteredApplications
          : _applications;
  bool get isLoading => _isLoading;
  int get totalCount => _applications.length;

  int getCountByStatus(AppStatus status) {
    return _applications.where((a) => a.statut == status).length;
  }

  List<Application> get applicationsNeedingRelance {
    final now = DateTime.now();
    return _applications.where((a) {
      if (a.dateRelance == null) return false;
      return a.dateRelance!.isBefore(now.add(const Duration(days: 1)));
    }).toList();
  }

  List<Application> get upcomingEntretiens {
    final now = DateTime.now();
    return _applications.where((a) {
      if (a.dateEntretien == null) return false;
      return a.dateEntretien!.isAfter(now);
    }).toList()
      ..sort((a, b) => a.dateEntretien!.compareTo(b.dateEntretien!));
  }

  Future<void> loadApplications() async {
    _isLoading = true;
    notifyListeners();
    _applications = await _db.getAllApplications();
    _applyFilters();
    _isLoading = false;
    notifyListeners();
  }

  Future<int> addApplication(Application app) async {
    final id = await _db.insertApplication(app);
    await loadApplications();
    return id;
  }

  Future<void> updateApplication(Application app) async {
    await _db.updateApplication(app);
    await loadApplications();
  }

  Future<void> deleteApplication(int id) async {
    await _db.deleteApplication(id);
    await loadApplications();
  }

  Future<void> changeStatus(int appId, AppStatus newStatus, {String? note}) async {
    final app = await _db.getApplication(appId);
    if (app == null) return;

    final history = StatusHistory(
      applicationId: appId,
      oldStatus: app.statut,
      newStatus: newStatus,
      note: note,
    );

    await _db.insertStatusHistory(history);
    await _db.updateApplication(
      app.copyWith(statut: newStatus, updatedAt: DateTime.now()),
    );
    await loadApplications();
  }

  void search(String query) {
    _searchQuery = query;
    if (query.isEmpty) {
      _filteredApplications = List.from(_applications);
    } else {
      final q = query.toLowerCase();
      _filteredApplications = _applications.where((a) {
        return a.entreprise.toLowerCase().contains(q) ||
            a.poste.toLowerCase().contains(q) ||
            (a.recruteur?.toLowerCase().contains(q) ?? false) ||
            (a.email?.toLowerCase().contains(q) ?? false) ||
            (a.notes?.toLowerCase().contains(q) ?? false);
      }).toList();
    }
    notifyListeners();
  }

  void filterByStatus(AppStatus? status) {
    _filterStatus = status;
    _applyFilters();
    notifyListeners();
  }

  void filterBySource(String? source) {
    _filterSource = source;
    _applyFilters();
    notifyListeners();
  }

  void _applyFilters() {
    _filteredApplications = _applications.where((a) {
      if (_filterStatus != null && a.statut != _filterStatus) return false;
      if (_filterSource != null && a.source.name != _filterSource) return false;
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        return a.entreprise.toLowerCase().contains(q) ||
            a.poste.toLowerCase().contains(q) ||
            (a.recruteur?.toLowerCase().contains(q) ?? false);
      }
      return true;
    }).toList();
  }

  Future<List<Capture>> getCaptures(int appId) async {
    return await _db.getCapturesForApplication(appId);
  }

  Future<int> addCapture(Capture capture) async {
    return await _db.insertCapture(capture);
  }

  Future<void> updateCaptureOcr(int captureId, String text) async {
    await _db.updateCaptureOcr(captureId, text);
  }

  Future<void> deleteCapture(int id) async {
    await _db.deleteCapture(id);
    await loadApplications();
  }

  Future<List<StatusHistory>> getHistory(int appId) async {
    return await _db.getHistoryForApplication(appId);
  }

  Application? findMatchingApplication(String ocrText) {
    final lowerText = ocrText.toLowerCase();
    for (final app in _applications) {
      final entreprise = app.entreprise.toLowerCase();
      if (entreprise.length >= 3 && lowerText.contains(entreprise)) {
        return app;
      }
      final email = app.email?.toLowerCase();
      if (email != null && lowerText.contains(email)) {
        return app;
      }
      final ref = app.referenceOffre?.toLowerCase();
      if (ref != null && ref.isNotEmpty && lowerText.contains(ref)) {
        return app;
      }
    }
    return null;
  }

  Future<Map<String, dynamic>> exportData() async {
    return await _db.exportAll();
  }

  Future<void> importData(Map<String, dynamic> data) async {
    await _db.importAll(data);
    await loadApplications();
  }
}
