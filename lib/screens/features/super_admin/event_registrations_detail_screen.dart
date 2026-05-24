import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../models/event_registration_model.dart';
import '../../../core/theme/app_colors.dart';
import 'event_registration_logs_screen.dart'; // To reuse eventRegistrationsProvider

class EventRegistrationsDetailScreen extends ConsumerStatefulWidget {
  final String eventId;
  final String eventTitle;

  const EventRegistrationsDetailScreen({
    super.key,
    required this.eventId,
    required this.eventTitle,
  });

  @override
  ConsumerState<EventRegistrationsDetailScreen> createState() =>
      _EventRegistrationsDetailScreenState();
}

class _EventRegistrationsDetailScreenState
    extends ConsumerState<EventRegistrationsDetailScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final registrationsAsync =
        ref.watch(eventRegistrationsProvider(widget.eventId));

    return Scaffold(
      backgroundColor: const Color(0xFFFAF2E6),
      appBar: AppBar(
        title: Text(widget.eventTitle),
        backgroundColor: AppColors.primaryMaroon,
        foregroundColor: Colors.white,
      ),
      body: registrationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (registrations) {
          if (registrations.isEmpty) {
            return const Center(
                child: Text('No users registered for this event yet.'));
          }

          // Filter registrations based on search query
          final query = _searchQuery.toLowerCase();
          final filteredRegistrations = registrations.where((reg) {
            if (query.isEmpty) return true;
            final nameMatch =
                reg.userName?.toLowerCase().contains(query) ?? false;
            final idMatch = reg.userId.toLowerCase().contains(query);
            return nameMatch || idMatch;
          }).toList();

          return Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by Name or User ID...',
                    prefixIcon: const Icon(Icons.search,
                        color: AppColors.primaryMaroon),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color: AppColors.primaryGold.withValues(alpha: 0.5)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: AppColors.primaryMaroon, width: 2),
                    ),
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
              ),

              // Count info
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Text(
                      '${filteredRegistrations.length} of ${registrations.length} registrations',
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Registrations List
              Expanded(
                child: filteredRegistrations.isEmpty
                    ? const Center(
                        child: Text('No matching registrations found.'))
                    : ListView.builder(
                        itemCount: filteredRegistrations.length,
                        itemBuilder: (context, index) {
                          final reg = filteredRegistrations[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 6),
                            elevation: 1,
                            child: ExpansionTile(
                              title: Text(
                                reg.userName ?? 'Unknown Name',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                'User ID: ${reg.userId}',
                                style: const TextStyle(
                                    fontSize: 11, color: Colors.grey),
                              ),
                              leading: CircleAvatar(
                                backgroundColor:
                                    AppColors.primaryMaroon.withValues(alpha: 0.1),
                                child: const Icon(Icons.person,
                                    color: AppColors.primaryMaroon),
                              ),
                              children: [
                                Container(
                                  color: Colors.grey.shade50,
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Registered: ${DateFormat('MMM dd, yyyy – hh:mm a').format(reg.registrationDate.toLocal())}',
                                        style: const TextStyle(
                                            fontSize: 12, color: Colors.grey),
                                      ),
                                      const Divider(),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceAround,
                                        children: [
                                          _DetailStat(
                                              icon: Icons.group,
                                              label: 'Adults',
                                              value: reg.numberOfAdults
                                                  .toString()),
                                          _DetailStat(
                                              icon: Icons.child_care,
                                              label: 'Children',
                                              value: reg.numberOfChildren
                                                  .toString()),
                                          _DetailStat(
                                              icon: Icons.check_circle,
                                              label: 'Status',
                                              value: reg.status.name
                                                  .toUpperCase()),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceAround,
                                        children: [
                                          _DetailStat(
                                            icon: Icons.how_to_reg,
                                            label: 'Attended',
                                            value:
                                                reg.attended ? 'Yes' : 'No',
                                            color: reg.attended
                                                ? Colors.green
                                                : Colors.grey,
                                          ),
                                          _DetailStat(
                                            icon: Icons.restaurant,
                                            label: 'Food Claimed',
                                            value: reg.foodClaimed
                                                ? 'Yes'
                                                : 'No',
                                            color: reg.foodClaimed
                                                ? Colors.orange
                                                : Colors.grey,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DetailStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? color;

  const _DetailStat(
      {required this.icon,
      required this.label,
      required this.value,
      this.color});

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.primaryMaroon;
    return Column(
      children: [
        Icon(icon, color: effectiveColor, size: 24),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.bold, color: effectiveColor)),
      ],
    );
  }
}
