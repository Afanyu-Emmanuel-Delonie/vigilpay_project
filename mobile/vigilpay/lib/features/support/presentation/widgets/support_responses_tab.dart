import 'package:flutter/material.dart';

import 'support_shared_widgets.dart';

class SupportResponsesTab extends StatelessWidget {
  const SupportResponsesTab({
    required this.complaints,
    required this.notifications,
    required this.errorMessage,
    required this.onRefresh,
    super.key,
  });

  final List<Map<String, dynamic>> complaints;
  final List<Map<String, dynamic>> notifications;
  final String? errorMessage;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final resolved = complaints.where((c) {
      final note = c['resolution_note']?.toString() ?? '';
      final status = (c['status']?.toString() ?? '').toLowerCase();
      return note.isNotEmpty || status == 'resolved';
    }).toList(growable: false);

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (errorMessage != null)
            SupportPanel(
              child: Text(
                errorMessage!,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: 11.5,
                  color: Colors.red,
                ),
              ),
            ),
          const Text('Complaint responses', style: supportHeadingStyle),
          const SizedBox(height: 8),
          if (resolved.isEmpty)
            const SupportPanel(
              child: Text('No complaint responses yet.', style: supportMutedStyle),
            )
          else
            ...resolved.map(_responseItem),
          const SizedBox(height: 14),
          const Text('Notifications', style: supportHeadingStyle),
          const SizedBox(height: 8),
          if (notifications.isEmpty)
            const SupportPanel(
              child: Text('No notifications yet.', style: supportMutedStyle),
            )
          else
            ...notifications.map(_notificationItem),
        ],
      ),
    );
  }

  Widget _responseItem(Map<String, dynamic> c) {
    final text = c['text']?.toString() ?? '';
    final note = c['resolution_note']?.toString() ?? '';
    final status = c['status']?.toString() ?? '';
    return SupportPanel(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Complaint: $text', style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 11.5)),
          const SizedBox(height: 6),
          Text(note.isEmpty ? 'Status: $status' : 'Response: $note', style: supportMutedStyle),
        ],
      ),
    );
  }

  Widget _notificationItem(Map<String, dynamic> n) {
    final title = n['title']?.toString() ?? 'Notification';
    final message = n['message']?.toString() ?? '';
    return SupportPanel(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 12)),
          if (message.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(message, style: supportMutedStyle),
          ],
        ],
      ),
    );
  }
}
