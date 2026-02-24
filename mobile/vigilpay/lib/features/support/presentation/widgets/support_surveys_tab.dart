import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import 'support_shared_widgets.dart';

class SupportSurveysTab extends StatelessWidget {
  const SupportSurveysTab({
    required this.isHighRisk,
    required this.rating,
    required this.selectedReason,
    required this.contactPermission,
    required this.isSubmitting,
    required this.feedbackController,
    required this.improvementController,
    required this.surveys,
    required this.onRatingChanged,
    required this.onReasonChanged,
    required this.onContactChanged,
    required this.onSubmitSurvey,
    required this.onRefresh,
    super.key,
  });

  final bool isHighRisk;
  final double rating;
  final String? selectedReason;
  final bool contactPermission;
  final bool isSubmitting;
  final TextEditingController feedbackController;
  final TextEditingController improvementController;
  final List<Map<String, dynamic>> surveys;
  final ValueChanged<double> onRatingChanged;
  final ValueChanged<String?> onReasonChanged;
  final ValueChanged<bool> onContactChanged;
  final Future<void> Function() onSubmitSurvey;
  final Future<void> Function() onRefresh;

  void _openComposeSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SurveyComposeSheet(
        isHighRisk: isHighRisk,
        feedbackController: feedbackController,
        improvementController: improvementController,
        rating: rating,
        onRatingChanged: onRatingChanged,
        selectedReason: selectedReason,
        onReasonChanged: onReasonChanged,
        contactPermission: contactPermission,
        onContactChanged: onContactChanged,
        isSubmitting: isSubmitting,
        onSubmit: () async {
          await onSubmitSurvey();
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
          child: surveys.isEmpty
              ? const _EmptyListScrollable(
                  icon: Icons.rate_review_outlined,
                  message: 'No surveys yet.\nTap + to share your experience.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                  itemCount: surveys.length,
                  itemBuilder: (_, i) => _SurveyCard(survey: surveys[i]),
                ),
        ),
        Positioned(
          right: 20,
          bottom: 20,
          child: _PrimaryFab(
            label: 'New Survey',
            icon: Icons.star_outline_rounded,
            isLoading: isSubmitting,
            onTap: () => _openComposeSheet(context),
          ),
        ),
      ],
    );
  }
}

class _SurveyComposeSheet extends StatefulWidget {
  const _SurveyComposeSheet({
    required this.isHighRisk,
    required this.feedbackController,
    required this.improvementController,
    required this.rating,
    required this.onRatingChanged,
    required this.selectedReason,
    required this.onReasonChanged,
    required this.contactPermission,
    required this.onContactChanged,
    required this.isSubmitting,
    required this.onSubmit,
  });

  final bool isHighRisk;
  final TextEditingController feedbackController;
  final TextEditingController improvementController;
  final double rating;
  final ValueChanged<double> onRatingChanged;
  final String? selectedReason;
  final ValueChanged<String?> onReasonChanged;
  final bool contactPermission;
  final ValueChanged<bool> onContactChanged;
  final bool isSubmitting;
  final Future<void> Function() onSubmit;

  @override
  State<_SurveyComposeSheet> createState() => _SurveyComposeSheetState();
}

class _SurveyComposeSheetState extends State<_SurveyComposeSheet> {
  late double _localRating;
  late String? _localReason;
  late bool _localContact;

  @override
  void initState() {
    super.initState();
    _localRating = widget.rating;
    _localReason = widget.selectedReason;
    _localContact = widget.contactPermission;
  }

  String _ratingLabel(double v) {
    switch (v.round()) {
      case 1:
        return 'Very poor';
      case 2:
        return 'Poor';
      case 3:
        return 'Fair';
      case 4:
        return 'Good';
      case 5:
        return 'Excellent';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 0, 20, inset + 24),
      child: SingleChildScrollView(
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
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(Icons.rate_review_outlined, size: 18, color: VigilColors.gold),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rate Your Experience',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: VigilColors.navy,
                      ),
                    ),
                    Text(
                      'Your feedback helps us improve',
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
            const SizedBox(height: 20),
            if (widget.isHighRisk) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: VigilColors.redMuted,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: VigilColors.red.withValues(alpha: 0.18)),
                ),
                child: const Text(
                  'We noticed reduced engagement on your account. Help us improve with a few quick answers.',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 11.5,
                    color: VigilColors.redDark,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                final filled = i < _localRating.round();
                return GestureDetector(
                  onTap: () {
                    setState(() => _localRating = (i + 1).toDouble());
                    widget.onRatingChanged(_localRating);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(
                      filled ? Icons.star_rounded : Icons.star_outline_rounded,
                      size: 38,
                      color: filled ? VigilColors.gold : const Color(0xFFDDDDDD),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 6),
            Center(
              child: Text(
                _ratingLabel(_localRating),
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: VigilColors.gold,
                ),
              ),
            ),
            const SizedBox(height: 18),
            if (widget.isHighRisk) ...[
              const _SheetLabel('Why has your interest reduced?'),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: VigilColors.stone,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: VigilColors.stoneMid),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _localReason,
                    hint: const Text(
                      'Select a reason',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        color: Color(0xFFBBBBBB),
                      ),
                    ),
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: 'Service is too slow', child: Text('Service is too slow')),
                      DropdownMenuItem(value: 'App is hard to use', child: Text('App is hard to use')),
                      DropdownMenuItem(value: 'Fees are too high', child: Text('Fees are too high')),
                      DropdownMenuItem(value: 'Not enough useful offers', child: Text('Not enough useful offers')),
                      DropdownMenuItem(value: 'Support response is slow', child: Text('Support response is slow')),
                    ],
                    onChanged: (v) {
                      setState(() => _localReason = v);
                      widget.onReasonChanged(v);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const _SheetLabel('What could we improve?'),
              const SizedBox(height: 8),
              _TextArea(
                controller: widget.improvementController,
                hint: 'Tell us what we could do better...',
                minLines: 2,
              ),
              const SizedBox(height: 14),
              GestureDetector(
                onTap: () {
                  setState(() => _localContact = !_localContact);
                  widget.onContactChanged(_localContact);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: _localContact ? VigilColors.redMuted : VigilColors.stone,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _localContact
                          ? VigilColors.red.withValues(alpha: 0.25)
                          : VigilColors.stoneMid,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _localContact
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked_rounded,
                        size: 20,
                        color: _localContact ? VigilColors.red : const Color(0xFFBBBBBB),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Allow the team to contact me about this feedback',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                            color: Color(0xFF555555),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
            ],
            const _SheetLabel('Additional comments'),
            const SizedBox(height: 8),
            _TextArea(
              controller: widget.feedbackController,
              hint: 'Anything else you would like to share...',
              minLines: 3,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: widget.isSubmitting ? null : widget.onSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: VigilColors.red,
                  disabledBackgroundColor: VigilColors.stoneMid,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: widget.isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text(
                        'Submit Survey',
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
      ),
    );
  }
}

class _SurveyCard extends StatelessWidget {
  const _SurveyCard({required this.survey});
  final Map<String, dynamic> survey;

  @override
  Widget build(BuildContext context) {
    final rating = survey['rating']?.toString() ?? '-';
    final feedback = survey['feedback']?.toString() ?? '';
    return SupportPanel(
      margin: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rating: $rating/5',
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
              fontSize: 12,
              color: VigilColors.navy,
            ),
          ),
          if (feedback.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(feedback, style: supportMutedStyle),
          ],
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

class _SheetLabel extends StatelessWidget {
  const _SheetLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w700,
        fontSize: 12,
        color: VigilColors.navy,
      ),
    );
  }
}

class _TextArea extends StatelessWidget {
  const _TextArea({
    required this.controller,
    required this.hint,
    required this.minLines,
  });

  final TextEditingController controller;
  final String hint;
  final int minLines;

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
