import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../app.dart';
import '../widgets/common_widgets.dart';
import 'applications_screen.dart';
import 'scan_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bonjour 👋',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              DateFormat('EEEE d MMMM', 'fr_FR').format(DateTime.now()),
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Pas de nouvelle notification')),
              );
            },
          ),
        ],
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.totalCount == 0) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: () => provider.loadApplications(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (provider.totalCount > 0) ...[
                    _buildStatsGrid(context, provider),
                    const SizedBox(height: 24),
                    _buildTodoSection(context, provider),
                    const SizedBox(height: 24),
                    _buildRecentApplications(context, provider),
                  ] else
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.6,
                      child: EmptyState(
                        icon: Icons.camera_alt,
                        title: 'Bienvenue dans JobShot',
                        message: 'Importez votre première capture d\'écran pour commencer à suivre vos candidatures.',
                        action: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const ScanScreen()),
                            );
                          },
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Importer une capture'),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, AppProvider provider) {
    final stats = [
      (Icons.description, 'Total', provider.totalCount, AppTheme.primaryColor),
      (Icons.send, 'Envoyées', provider.getCountByStatus(AppStatus.envoyee), AppTheme.successColor),
      (Icons.hourglass_empty, 'En attente', provider.getCountByStatus(AppStatus.enAttente), AppTheme.warningColor),
      (Icons.alarm, 'Relances', provider.getCountByStatus(AppStatus.relanceNecessaire), AppTheme.errorColor),
      (Icons.event, 'Entretiens', provider.getCountByStatus(AppStatus.entretien), const Color(0xFF7B1FA2)),
      (Icons.cancel, 'Refus', provider.getCountByStatus(AppStatus.refusee), const Color(0xFFD32F2F)),
    ];

    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        mainAxisExtent: 128,
      ),
      children: stats.map((s) => StatCard(
        icon: s.$1,
        label: s.$2,
        value: s.$3,
        color: s.$4,
      )).toList(),
    );
  }

  Widget _buildTodoSection(BuildContext context, AppProvider provider) {
    final relances = provider.applicationsNeedingRelance;
    final entretiens = provider.upcomingEntretiens;

    if (relances.isEmpty && entretiens.isEmpty) {
      return _card(
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: AppTheme.successColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Aucune action requise aujourd\'hui 🎉',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.today, color: AppTheme.primaryColor),
              SizedBox(width: 8),
              Text(
                'À faire aujourd\'hui',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...relances.map((app) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.alarm, color: AppTheme.warningColor),
            title: Text('Relancer ${app.entreprise}'),
            subtitle: Text(app.poste),
            dense: true,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ApplicationsScreen(initialId: app.id),
                ),
              );
            },
          )),
          ...entretiens.take(5).map((app) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.event, color: Color(0xFF7B1FA2)),
            title: Text('Entretien ${app.entreprise}'),
            subtitle: Text(app.dateEntretien != null
                ? DateFormat('dd/MM/yyyy HH:mm', 'fr_FR').format(app.dateEntretien!)
                : ''),
            dense: true,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ApplicationsScreen(initialId: app.id),
                ),
              );
            },
          )),
        ],
      ),
    );
  }

  Widget _buildRecentApplications(BuildContext context, AppProvider provider) {
    final recent = provider.applications.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(title: 'Candidatures récentes'),
        const SizedBox(height: 8),
        ...recent.map((app) => _buildApplicationCard(context, app)),
        const SizedBox(height: 8),
        Center(
          child: TextButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ApplicationsScreen()),
              );
            },
            child: const Text('Voir toutes les candidatures'),
          ),
        ),
      ],
    );
  }

  Widget _buildApplicationCard(BuildContext context, Application app) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ApplicationsScreen(initialId: app.id),
            ),
          );
        },
        child: Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
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
                        style: const TextStyle(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        app.poste,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      StatusBadge(status: app.statut),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    );
  }
}
