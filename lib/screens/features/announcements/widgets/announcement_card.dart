import 'package:flutter/material.dart';
import '../../../../models/announcement_model.dart';
import 'package:intl/intl.dart';

class AnnouncementCard extends StatelessWidget {
  final AnnouncementModel announcement;

  const AnnouncementCard({super.key, required this.announcement});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (announcement.imageUrl != null && announcement.imageUrl!.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(
                announcement.imageUrl!,
                height: 180,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => 
                    Container(height: 180, color: Colors.grey[300], child: const Icon(Icons.broken_image, color: Colors.grey)),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  announcement.title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  DateFormat.yMMMd().add_jm().format(announcement.createdAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 12),
                Text(
                  announcement.message,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
