import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../models/announcement_model.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../repositories/communication_repository.dart';
import '../../../../providers/notification_providers.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/snackbar_utils.dart';

class CreateAnnouncementScreen extends ConsumerStatefulWidget {
  const CreateAnnouncementScreen({super.key});

  @override
  ConsumerState<CreateAnnouncementScreen> createState() => _CreateAnnouncementScreenState();
}

class _CreateAnnouncementScreenState extends ConsumerState<CreateAnnouncementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isLoading = false;

  Future<void> _submitAnnouncement() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    
    try {
      final user = ref.read(currentUserProvider).value;
      if (user == null) throw Exception('Must be logged in');

      final announcement = AnnouncementModel(
        id: '', // Firestore will generate this
        title: _titleController.text.trim(),
        message: _messageController.text.trim(),
        createdAt: DateTime.now(),
        authorId: user.uid,
      );

      final repo = ref.read(communicationRepositoryProvider);
      final docId = await repo.postAnnouncement(announcement);

      // Trigger the workflow to notify all users of the new announcement
      final announcementWithId = AnnouncementModel(
        id: docId,
        title: announcement.title,
        message: announcement.message,
        createdAt: announcement.createdAt,
        authorId: announcement.authorId,
      );
      await ref.read(notificationWorkflowServiceProvider).sendAnnouncementNotification(announcementWithId);

      if (mounted) {
        SnackbarUtils.showSuccess(context, 'Announcement posted successfully!');
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(context, e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Announcement')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CustomTextField(
                controller: _titleController,
                labelText: 'Title',
                prefixIcon: Icons.title,
                validator: (value) => value == null || value.isEmpty ? 'Title is required' : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _messageController,
                labelText: 'Message',
                prefixIcon: Icons.message,
                maxLines: 5,
                validator: (value) => value == null || value.isEmpty ? 'Message is required' : null,
              ),
              const SizedBox(height: 32),
              PrimaryButton(
                text: 'Post Announcement',
                isLoading: _isLoading,
                onPressed: _submitAnnouncement,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
