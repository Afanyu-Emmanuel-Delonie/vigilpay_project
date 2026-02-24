import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import 'support_shared_widgets.dart';

class SupportComplaintsTab extends StatelessWidget {
  const SupportComplaintsTab({
    required this.controller,
    required this.isSubmitting,
    required this.complaints,
    required this.onSubmitComplaint,
    required this.onRefresh,
    super.key,
  });

  final TextEditingController controller;
  final bool isSubmitting;
  final List<Map<String, dynamic>> complaints;
  final Future<void> Function() onSubmitComplaint;
  final Future<void> Function() onRefresh;

  void _openComposeSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ComplaintComposeSheet(
        controller: controller,
        isSubmitting: isSubmitting,
        onSubmit: () async {
          await onSubmitComplaint();
          if (context.mounted) Navigator.maybePop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: onRefresh,
          color: VigilColors.red,
          child: complaints.isEmpty
              ? const _EmptyListScrollable(
                  icon: Icons.report_problem_outlined,
                  message: 'No complaints yet.\nTap + to submit your first one.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                  itemCount: complaints.length,
                  itemBuilder: (_, i) => _ComplaintCard(complaint: complaints[i]),
                ),
        ),
        Positioned(
          right: 20,
          bottom: 20,
          child: _PrimaryFab(
            label: 'New Complaint',
            icon: Icons.edit_outlined,
            isLoading: isSubmitting,
            onTap: () => _openComposeSheet(context),
          ),
        ),
      ],
    );
  }
}

class _ComplaintComposeSheet extends StatelessWidget {
  const _ComplaintComposeSheet({
    required this.controller,
    required this.isSubmitting,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final bool isSubmitting;
  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 0, 20, inset + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: VigilColors.redMuted,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(Icons.report_problem_outlined, size: 18, color: VigilColors.red),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Submit a Complaint',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: VigilColors.navy,
                    ),
                  ),
                  Text(
                    'We respond within 24 hours',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      color: Color(0xFF999999),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          _TextArea(
            controller: controller,
            hint: 'Describe your issue in detail...',
            minLines: 4,
            autofocus: true,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: isSubmitting ? null : onSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: VigilColors.red,
                disabledBackgroundColor: VigilColors.stoneMid,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text(
                      'Submit Complaint',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ComplaintCard extends StatelessWidget {
  const _ComplaintCard({required this.complaint});
  final Map<String, dynamic> complaint;

  @override
  Widget build(BuildContext context) {
    final status = (complaint['status']?.toString() ?? 'open').toUpperCase();
    final text = complaint['text']?.toString() ?? '';
    final category = complaint['category']?.toString() ?? 'support';

    return SupportPanel(
      margin: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            status,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
              fontSize: 10.5,
              color: VigilColors.red,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            text,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: VigilColors.navy,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Category: ${category.toUpperCase()}',
            style: supportMutedStyle,
          ),
        ],
      ),
    );
  }
}

class _EmptyListScrollable extends StatelessWidget {
  const _EmptyListScrollable({required this.icon, required this.message});
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.25),
        Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: VigilColors.redMuted,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, size: 28, color: VigilColors.red),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w500,
                fontSize: 13,
                color: Color(0xFF999999),
                height: 1.55,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PrimaryFab extends StatelessWidget {
  const _PrimaryFab({
    required this.label,
    required this.icon,
    required this.isLoading,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: isLoading ? VigilColors.stoneMid : VigilColors.red,
          borderRadius: BorderRadius.circular(999),
          boxShadow: isLoading
              ? []
              : [
                  BoxShadow(
                    color: VigilColors.red.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TextArea extends StatelessWidget {
  const _TextArea({
    required this.controller,
    required this.hint,
    required this.minLines,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final String hint;
  final int minLines;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: VigilColors.stone,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: VigilColors.stoneMid),
      ),
      child: TextField(
        controller: controller,
        minLines: minLines,
        maxLines: minLines + 4,
        autofocus: autofocus,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 13,
          color: VigilColors.navy,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            color: Color(0xFFBBBBBB),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(14),
        ),
      ),
    );
  }
}
