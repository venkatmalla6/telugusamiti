import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/event_registration_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/event_providers.dart';
import '../../../repositories/event_repository.dart';

class EventRegistrationScreen extends ConsumerStatefulWidget {
  final String eventId;
  const EventRegistrationScreen({super.key, required this.eventId});

  @override
  ConsumerState<EventRegistrationScreen> createState() => _EventRegistrationScreenState();
}

class _EventRegistrationScreenState extends ConsumerState<EventRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  int _adultCount = 0;
  int _childrenCount = 0;
  bool _isLoading = false;

  bool _isInit = false;
  EventRegistrationModel? _existingReg;

  @override
  void initState() {
    super.initState();
    _loadExistingRegistration();
  }

  Future<void> _loadExistingRegistration() async {
    final reg = await ref.read(eventRegistrationProvider(widget.eventId).future);
    if (reg != null && mounted) {
      setState(() {
        _existingReg = reg;
        _adultCount = reg.numberOfAdults;
        _childrenCount = reg.numberOfChildren;
        _isInit = true;
      });
    } else if (mounted) {
      setState(() {
        _isInit = true;
      });
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final user = ref.read(currentUserProvider).value;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to register')),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      final repo = ref.read(eventRepositoryProvider);
      
      final registrationId = _existingReg?.id ?? const Uuid().v4();
      final registration = EventRegistrationModel(
        id: registrationId,
        eventId: widget.eventId,
        userId: user.uid,
        userName: user.displayName,
        registrationDate: _existingReg?.registrationDate ?? DateTime.now(),
        status: RegistrationStatus.confirmed,
        numberOfGuests: _adultCount + _childrenCount,
        numberOfAdults: _adultCount,
        numberOfChildren: _childrenCount,
        foodClaimed: _existingReg?.foodClaimed ?? false,
        foodClaimedAt: _existingReg?.foodClaimedAt,
      );

      await repo.registerForEvent(widget.eventId, registration);

      // Invalidate the registration provider so that previous screens refresh
      ref.invalidate(eventRegistrationProvider(widget.eventId));

      if (mounted) {
        context.pushReplacement('/events/${widget.eventId}/ticket/$registrationId');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final eventAsync = ref.watch(eventDetailProvider(widget.eventId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Registration'),
      ),
      body: eventAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(child: Text('Error loading event: $err')),
        data: (event) {
          if (event == null) return const Center(child: Text('Event not found'));

          if (!_isInit) return const Center(child: CircularProgressIndicator());

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryMaroon,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _existingReg != null 
                      ? 'Update your registration details below.'
                      : 'You are registering for this event. Please enter the details below.',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 24),
                  
                  // Guest count selector
                  const Text(
                    'Additional Guests',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'How many family members/guests will accompany you?',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  
                  const Text(
                    'Adults',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: _adultCount > 0 
                            ? () => setState(() => _adultCount--) 
                            : null,
                        icon: const Icon(Icons.remove_circle_outline),
                        color: AppColors.primaryMaroon,
                        iconSize: 32,
                      ),
                      const SizedBox(width: 16),
                      Text(
                        '$_adultCount',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        onPressed: () => setState(() => _adultCount++),
                        icon: const Icon(Icons.add_circle_outline),
                        color: AppColors.primaryMaroon,
                        iconSize: 32,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Children',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: _childrenCount > 0 
                            ? () => setState(() => _childrenCount--) 
                            : null,
                        icon: const Icon(Icons.remove_circle_outline),
                        color: AppColors.primaryMaroon,
                        iconSize: 32,
                      ),
                      const SizedBox(width: 16),
                      Text(
                        '$_childrenCount',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        onPressed: () => setState(() => _childrenCount++),
                        icon: const Icon(Icons.add_circle_outline),
                        color: AppColors.primaryMaroon,
                        iconSize: 32,
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 48),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: FilledButton(
                      onPressed: _isLoading ? null : _register,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primaryMaroon,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLoading 
                          ? const CircularProgressIndicator(color: const Color(0xFF5C0A0A))
                          : Text(
                              _existingReg != null ? 'Update Registration' : 'Confirm Registration',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
}
