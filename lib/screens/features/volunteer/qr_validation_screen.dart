import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/event_providers.dart';
import '../../../repositories/event_repository.dart';
import '../../../models/event_model.dart';
import '../../../models/event_registration_model.dart';

// We need a specific provider to get the registration directly since eventRegistrationProvider 
// might be scoped to the current user in some contexts. Let's create a future provider for this.
final qrValidationProvider = FutureProvider.family.autoDispose<EventRegistrationModel?, String>((ref, eventAndRegId) async {
  final parts = eventAndRegId.split(':');
  if (parts.length != 2) return null;
  final eventId = parts[0];
  final registrationId = parts[1];
  
  final repo = ref.watch(eventRepositoryProvider);
  return repo.getRegistrationById(eventId, registrationId);
});

class QRValidationScreen extends ConsumerStatefulWidget {
  final String eventId;
  final String registrationId;

  const QRValidationScreen({
    super.key,
    required this.eventId,
    required this.registrationId,
  });

  @override
  ConsumerState<QRValidationScreen> createState() => _QRValidationScreenState();
}

class _QRValidationScreenState extends ConsumerState<QRValidationScreen> {
  bool _isProcessing = false;

  Future<void> _markFoodClaimed(EventRegistrationModel reg) async {
    setState(() => _isProcessing = true);
    try {
      final repo = ref.read(eventRepositoryProvider);
      await repo.markFoodClaimed(widget.eventId, widget.registrationId);
      
      // Invalidate so UI refreshes
      ref.invalidate(qrValidationProvider('${widget.eventId}:${widget.registrationId}'));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Food marked as claimed!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _markAttended(EventRegistrationModel reg) async {
    try {
      final repo = ref.read(eventRepositoryProvider);
      await repo.markAttended(widget.eventId, widget.registrationId);
      ref.invalidate(qrValidationProvider('${widget.eventId}:${widget.registrationId}'));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Attendance logged automatically.'), backgroundColor: Colors.blue),
        );
      }
    } catch (e) {
      debugPrint('Failed to mark attended: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(qrValidationProvider('${widget.eventId}:${widget.registrationId}'), (previous, next) {
      final reg = next.value;
      if (reg != null && !reg.attended) {
        Future.microtask(() => _markAttended(reg));
      }
    });

    final validationAsync = ref.watch(qrValidationProvider('${widget.eventId}:${widget.registrationId}'));
    final eventAsync = ref.watch(eventDetailProvider(widget.eventId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Validation Result'),
        backgroundColor: AppColors.primaryMaroon,
        foregroundColor: Colors.white,
      ),
      body: eventAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (event) {
          if (event == null) {
            return const Center(child: Text('Event not found.'));
          }

          return validationAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (registration) {
              if (registration == null) {
                return _buildErrorResult('Invalid QR Code. Registration not found.');
              }

              return _buildSuccessResult(event, registration);
            },
          );
        },
      ),
    );
  }

  Widget _buildErrorResult(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 80),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: () => context.pop(),
            child: const Text('Scan Another'),
          )
        ],
      ),
    );
  }

  Widget _buildSuccessResult(EventModel event, EventRegistrationModel reg) {
    final int totalMembers = 1 + reg.numberOfAdults + reg.numberOfChildren;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 80),
          const SizedBox(height: 16),
          const Text(
            'Valid Registration',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildRow('Name', reg.userName ?? 'N/A'),
                  const Divider(),
                  _buildRow('Event', event.title),
                  const Divider(),
                  _buildRow('Total Members', '$totalMembers'),
                  const SizedBox(height: 8),
                  Text('Self: 1, Adults: ${reg.numberOfAdults}, Children: ${reg.numberOfChildren}', 
                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  const Divider(),
                  _buildRow('Attendance', reg.attended ? 'Logged' : 'Logging...'),
                  if (reg.attendedAt != null) ...[
                    const SizedBox(height: 4),
                    Text('Time: ${reg.attendedAt!.toLocal().toString().split('.')[0]}', 
                      style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),
          
          if (event.hasFood) ...[
            if (reg.foodClaimed)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade300),
                ),
                child: Column(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.orange.shade800, size: 40),
                    const SizedBox(height: 8),
                    Text(
                      'Food Already Claimed!',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange.shade900),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Claimed at: ${reg.foodClaimedAt != null ? reg.foodClaimedAt!.toLocal().toString().split('.')[0] : 'Unknown'}',
                      style: TextStyle(color: Colors.orange.shade900),
                    ),
                  ],
                ),
              )
            else
              FilledButton.icon(
                onPressed: _isProcessing ? null : () => _markFoodClaimed(reg),
                icon: _isProcessing 
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.restaurant),
                label: const Text('Mark Food Claimed'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryGold,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'This event does not have food arranged.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
            ),
          ],
          
          const Spacer(),
          OutlinedButton(
            onPressed: () => context.pop(),
            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
            child: const Text('Scan Another QR Code'),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }
}
