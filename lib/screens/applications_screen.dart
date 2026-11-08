import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../app.dart';
import '../widgets/common_widgets.dart';
import 'application_detail_screen.dart';

class ApplicationsScreen extends StatefulWidget {
  final int? initialId;

  const ApplicationsScreen({super.key, this.initialId});

  @override
  State<ApplicationsScreen> createState() => _ApplicationsScreenState();
}

class _ApplicationsScreenState extends State<ApplicationsScreen> {
  final _searchController = TextEditingController();
  AppStatus? _filterStatus;
  String? _filterSource;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final applications = provider.applications;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Candidatures'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilters,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => provider.search(value),
              decoration: InputDecoration(
                hintText: 'Rechercher...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          provider.search('');
                        },
                      )
                    : null,
                isDense: true,
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          if (_filterStatus != null || _filterSource != null)
            _buildFilterBar(context, provider),
          Expanded(
            child: applications.isEmpty
                ? EmptyState(
                    icon: Icons.view_list,
                    title: 'Aucune candidature',
                    message: 'Importez vos premières captures d\'écran pour créer des fiches de candidature.',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: applications.length,
                    itemBuilder: (context, index) {
                      return _buildCard(context, applications[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(BuildContext context, AppProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          if (_filterStatus != null)
            Chip(
              label: Text('Statut: ${_filterStatus!.label}'),
              onDeleted: () {
                setState(() => _filterStatus = null);
                provider.filterByStatus(null);
              },
            ),
          if (_filterSource != null)
            Chip(
              label: Text('Source: ${_filterSource}'),
              onDeleted: () {
                setState(() => _filterSource = null);
                provider.filterBySource(null);
              },
            ),
        ],
      ),
    );
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Filtres',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const Text('Statut', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: AppStatus.values.map((s) => ChoiceChip(
                    label: Text(s.label),
                    selected: _filterStatus == s,
                    onSelected: (_) {
                      setState(() => _filterStatus = s);
                      Provider.of<AppProvider>(context, listen: false).filterByStatus(s);
                      Navigator.pop(context);
                    },
                  )).toList(),
                ),
                const SizedBox(height: 20),
                const Text('Source', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: Source.values.map((s) => ChoiceChip(
                    label: Text(s.label),
                    selected: _filterSource == s.name,
                    onSelected: (_) {
                      setState(() => _filterSource = s.name);
                      Provider.of<AppProvider>(context, listen: false).filterBySource(s.name);
                      Navigator.pop(context);
                    },
                  )).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCard(BuildContext context, Application app) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => ApplicationDetailScreen(applicationId: app.id!),
            ),
          );
          Provider.of<AppProvider>(context, listen: false).loadApplications();
        },
        child: Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          app.entreprise.isNotEmpty ? app.entreprise[0].toUpperCase() : '?',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            app.entreprise,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            app.poste,
                            style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    StatusBadge(status: app.statut),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    SourceChip(source: app.source),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.calendar_today,
                      size: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${app.dateCandidature.day}/${app.dateCandidature.month}/${app.dateCandidature.year}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    if (app.dateRelance != null)
                      Row(
                        children: [
                          const Icon(Icons.alarm, size: 14, color: AppTheme.warningColor),
                          const SizedBox(width: 4),
                          Text(
                            'Relance: ${app.dateRelance!.day}/${app.dateRelance!.month}',
                            style: const TextStyle(fontSize: 11, color: AppTheme.warningColor),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
