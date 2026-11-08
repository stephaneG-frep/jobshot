import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../app.dart';
import 'applications_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calendrier')),
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          final events = _getEventsForDate(provider, _selectedDate);

          return Column(
            children: [
              _buildMonthView(context, provider),
              const Divider(),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(_selectedDate),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              Expanded(
                child: events.isEmpty
                    ? const Center(
                        child: Text(
                          'Aucun événement ce jour',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: events.length,
                        itemBuilder: (context, index) {
                          final event = events[index];
                          return _buildEventCard(context, event);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<_CalendarEvent> _getEventsForDate(AppProvider provider, DateTime date) {
    final events = <_CalendarEvent>[];
    final p = (int year, int month, int day) =>
        '${year}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
    final target = p(date.year, date.month, date.day);

    for (final app in provider.applications) {
      final relanceDate = app.dateRelance;
      if (relanceDate != null) {
        final relanceStr = p(relanceDate.year, relanceDate.month, relanceDate.day);
        if (relanceStr == target) {
          events.add(_CalendarEvent(
            title: 'Relance ${app.entreprise}',
            subtitle: app.poste,
            color: AppTheme.warningColor,
            icon: Icons.alarm,
            appId: app.id,
          ));
        }
      }

      final entretienDate = app.dateEntretien;
      if (entretienDate != null) {
        final entretienStr = p(entretienDate.year, entretienDate.month, entretienDate.day);
        if (entretienStr == target) {
          events.add(_CalendarEvent(
            title: 'Entretien ${app.entreprise}',
            subtitle: app.poste,
            color: const Color(0xFF7B1FA2),
            icon: Icons.event,
            appId: app.id,
          ));
        }
      }

      final candDate = app.dateCandidature;
      final candStr = p(candDate.year, candDate.month, candDate.day);
      if (candStr == target) {
        events.add(_CalendarEvent(
          title: 'Candidature envoyée',
          subtitle: '${app.entreprise} — ${app.poste}',
          color: AppTheme.primaryColor,
          icon: Icons.send,
          appId: app.id,
        ));
      }
    }

    return events;
  }

  Widget _buildMonthView(BuildContext context, AppProvider provider) {
    final now = DateTime.now();
    final first = DateTime(_selectedDate.year, _selectedDate.month, 1);
    final firstWeekday = first.weekday;
    final daysInMonth = DateTime(_selectedDate.year, _selectedDate.month + 1, 0).day;

    final items = <Widget>[];
    for (int i = 1; i < firstWeekday; i++) {
      items.add(const SizedBox.shrink());
    }

    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_selectedDate.year, _selectedDate.month, day);
      final hasEvent = _hasEvent(provider, date);
      final isSelected = date.year == _selectedDate.year &&
          date.month == _selectedDate.month &&
          date.day == _selectedDate.day;
      final isToday = date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;

      items.add(
        InkWell(
          onTap: () => setState(() => _selectedDate = date),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primaryColor : null,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$day',
                  style: TextStyle(
                    fontSize: 13,
                    color: isSelected
                        ? Colors.white
                        : isToday
                            ? AppTheme.primaryColor
                            : Theme.of(context).colorScheme.onSurface,
                    fontWeight: isToday ? FontWeight.bold : null,
                  ),
                ),
                if (hasEvent)
                  Container(
                    width: 5,
                    height: 5,
                    margin: const EdgeInsets.only(top: 2),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : AppTheme.accentColor,
                      shape: BoxShape.circle,
                    ),
                  )
                else
                  const SizedBox(height: 7),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => setState(() {
                  _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1, 1);
                }),
              ),
              Text(
                DateFormat('MMMM yyyy', 'fr_FR').format(_selectedDate),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => setState(() {
                  _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1, 1);
                }),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Row(
            children: [
              _DayHeader('L'),
              _DayHeader('M'),
              _DayHeader('M'),
              _DayHeader('J'),
              _DayHeader('V'),
              _DayHeader('S'),
              _DayHeader('D'),
            ],
          ),
          const SizedBox(height: 4),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: items,
          ),
        ],
      ),
    );
  }

  bool _hasEvent(AppProvider provider, DateTime date) {
    for (final app in provider.applications) {
      if (app.dateRelance != null &&
          app.dateRelance!.year == date.year &&
          app.dateRelance!.month == date.month &&
          app.dateRelance!.day == date.day) return true;
      if (app.dateEntretien != null &&
          app.dateEntretien!.year == date.year &&
          app.dateEntretien!.month == date.month &&
          app.dateEntretien!.day == date.day) return true;
      if (app.dateCandidature.year == date.year &&
          app.dateCandidature.month == date.month &&
          app.dateCandidature.day == date.day) return true;
    }
    return false;
  }

  Widget _buildEventCard(BuildContext context, _CalendarEvent event) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: event.color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(event.icon, color: event.color),
        ),
        title: Text(event.title),
        subtitle: Text(event.subtitle),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ApplicationsScreen(initialId: event.appId),
            ),
          );
        },
      ),
    );
  }
}

class _DayHeader extends StatelessWidget {
  final String label;
  const _DayHeader(this.label);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _CalendarEvent {
  final String title;
  final String subtitle;
  final Color color;
  final IconData icon;
  final int? appId;

  _CalendarEvent({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.icon,
    this.appId,
  });
}
