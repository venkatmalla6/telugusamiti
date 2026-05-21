import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/event_model.dart';
import '../../../providers/event_providers.dart';
import '../../../repositories/event_repository.dart';

class CreateEventScreen extends ConsumerStatefulWidget {
  final String? eventId;
  const CreateEventScreen({super.key, this.eventId});

  @override
  ConsumerState<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends ConsumerState<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _titleCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _locationCtrl;
  late TextEditingController _capacityCtrl;
  late TextEditingController _imageCtrl;

  DateTime _startDate = DateTime.now().add(const Duration(days: 7));
  DateTime _endDate = DateTime.now().add(const Duration(days: 7, hours: 2));
  bool _isPublished = false;
  bool _hasFood = false;

  bool _isInit = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController();
    _descCtrl = TextEditingController();
    _locationCtrl = TextEditingController();
    _capacityCtrl = TextEditingController(text: '0');
    _imageCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    _capacityCtrl.dispose();
    _imageCtrl.dispose();
    super.dispose();
  }

  void _loadEvent(EventModel event) {
    if (_isInit) return;
    _titleCtrl.text = event.title;
    _descCtrl.text = event.description;
    _locationCtrl.text = event.location;
    _capacityCtrl.text = event.maxCapacity.toString();
    _imageCtrl.text = event.imageUrl ?? '';
    _startDate = event.startDate;
    _endDate = event.endDate;
    _isPublished = event.isPublished;
    _hasFood = event.hasFood;
    _isInit = true;
  }

  Future<void> _selectDateTime(bool isStart) async {
    final initialDate = isStart ? _startDate : _endDate;
    
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
    );
    if (time == null) return;

    setState(() {
      final selected = DateTime(date.year, date.month, date.day, time.hour, time.minute);
      if (isStart) {
        _startDate = selected;
        if (_endDate.isBefore(_startDate)) {
          _endDate = _startDate.add(const Duration(hours: 2));
        }
      } else {
        _endDate = selected;
      }
    });
  }

  bool _isLoading = false;

  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final event = EventModel(
        id: widget.eventId ?? '',
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        location: _locationCtrl.text.trim(),
        imageUrl: _imageCtrl.text.trim().isEmpty ? null : _imageCtrl.text.trim(),
        maxCapacity: int.tryParse(_capacityCtrl.text) ?? 0,
        startDate: _startDate,
        endDate: _endDate,
        isPublished: _isPublished,
        hasFood: _hasFood,
      );

      final repo = ref.read(eventRepositoryProvider);
      if (event.id.isEmpty) {
        await repo.createEvent(event);
      } else {
        await repo.updateEvent(event.id, event.toMap());
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event saved successfully')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving event: $e')),
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
    final isEditing = widget.eventId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Event' : 'Create Event'),
      ),
      body: isEditing 
        ? ref.watch(eventDetailProvider(widget.eventId!)).when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (event) {
              if (event != null) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  setState(() {
                    _loadEvent(event);
                  });
                });
              }
              return _buildForm();
            },
          )
        : _buildForm(),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: 'Event Title', border: OutlineInputBorder()),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descCtrl,
              decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
              maxLines: 4,
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _locationCtrl,
              decoration: const InputDecoration(labelText: 'Location', border: OutlineInputBorder()),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _capacityCtrl,
              decoration: const InputDecoration(labelText: 'Max Capacity (0 for unlimited)', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _imageCtrl,
              decoration: const InputDecoration(labelText: 'Image URL (optional)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    title: const Text('Start Date'),
                    subtitle: Text(DateFormat.yMd().add_jm().format(_startDate)),
                    onTap: () => _selectDateTime(true),
                  ),
                ),
                Expanded(
                  child: ListTile(
                    title: const Text('End Date'),
                    subtitle: Text(DateFormat.yMd().add_jm().format(_endDate)),
                    onTap: () => _selectDateTime(false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Publish Event'),
              subtitle: const Text('If true, users can see and register'),
              value: _isPublished,
              activeColor: AppColors.primaryMaroon,
              onChanged: (val) => setState(() => _isPublished = val),
            ),
            SwitchListTile(
              title: const Text('Food Arranged'),
              subtitle: const Text('If true, food tokens will be included in the registration QR'),
              value: _hasFood,
              activeColor: AppColors.primaryMaroon,
              onChanged: (val) => setState(() => _hasFood = val),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: _isLoading ? null : _saveEvent,
                style: FilledButton.styleFrom(backgroundColor: AppColors.primaryMaroon),
                child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Save Event'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
