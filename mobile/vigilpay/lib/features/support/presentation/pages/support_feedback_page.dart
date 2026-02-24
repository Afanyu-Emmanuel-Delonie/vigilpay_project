import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/route_constants.dart';
import '../../../../core/utils/request_state.dart';
import '../../../../core/widgets/main_bottom_nav.dart';
import '../../../../core/widgets/vigil_page_app_bar.dart';
import '../../../auth/presentation/provider/auth_controller.dart';
import '../provider/support_controller.dart';
import '../widgets/support_complaints_tab.dart';
import '../widgets/support_responses_tab.dart';
import '../widgets/support_surveys_tab.dart';

class SupportFeedbackPage extends StatefulWidget {
  const SupportFeedbackPage({super.key});

  @override
  State<SupportFeedbackPage> createState() => _SupportFeedbackPageState();
}

class _SupportFeedbackPageState extends State<SupportFeedbackPage> {
  final _complaintController = TextEditingController();
  final _surveyFeedbackController = TextEditingController();
  final _surveyImprovementController = TextEditingController();
  double _surveyRating = 4;
  String? _selectedReason;
  bool _contactPermission = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SupportController>().loadAll();
    });
  }

  @override
  void dispose() {
    _complaintController.dispose();
    _surveyFeedbackController.dispose();
    _surveyImprovementController.dispose();
    super.dispose();
  }

  Future<void> _submitComplaint() async {
    final controller = context.read<SupportController>();
    final text = _complaintController.text.trim();
    if (text.isEmpty) {
      _snack('Please describe your complaint first.');
      return;
    }
    final ok = await controller.submitComplaint(text);
    if (ok) {
      _complaintController.clear();
      _snack('Complaint submitted.');
    } else {
      _snack('Unable to submit complaint.');
    }
  }

  Future<void> _submitSurvey() async {
    final support = context.read<SupportController>();
    final auth = context.read<AuthController>();
    final session = auth.session;
    final tier = (session?.riskTier ?? '').toLowerCase();
    final probability = session?.riskProbability ?? 0;
    final isHighRisk = tier.contains('high') || probability >= 0.65;
    if (isHighRisk && (_selectedReason == null || _selectedReason!.isEmpty)) {
      _snack('Please select why your interest reduced.');
      return;
    }

    final ok = await support.submitSurvey(
      session: session,
      rating: _surveyRating.round(),
      reason: _selectedReason ?? '',
      improvement: _surveyImprovementController.text.trim(),
      additionalFeedback: _surveyFeedbackController.text.trim(),
      contactPermission: _contactPermission,
    );
    if (ok) {
      _surveyFeedbackController.clear();
      _surveyImprovementController.clear();
      setState(() {
        _surveyRating = 4;
        _selectedReason = null;
        _contactPermission = false;
      });
      _snack('Survey submitted. Thank you.');
    } else {
      _snack('Unable to submit survey.');
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final support = context.watch<SupportController>();
    final auth = context.watch<AuthController>();
    final session = auth.session;
    final tier = (session?.riskTier ?? '').toLowerCase();
    final probability = session?.riskProbability ?? 0;
    final isHighRisk = tier.contains('high') || probability >= 0.65;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: VigilPageAppBar(
          title: 'Support & Feedback',
          automaticallyImplyLeading: true,
          actions: [
            IconButton(
              onPressed: () => context.read<SupportController>().loadAll(),
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Refresh',
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Complaints'),
              Tab(text: 'Surveys'),
              Tab(text: 'Responses'),
            ],
          ),
        ),
        bottomNavigationBar: const MainBottomNav(
          currentRoute: RouteConstants.supportFeedback,
        ),
        body: support.state == RequestState.loading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  SupportComplaintsTab(
                    controller: _complaintController,
                    isSubmitting:
                        support.complaintSubmitState == RequestState.loading,
                    complaints: support.complaints,
                    onSubmitComplaint: _submitComplaint,
                    onRefresh: support.loadAll,
                  ),
                  SupportSurveysTab(
                    isHighRisk: isHighRisk,
                    rating: _surveyRating,
                    selectedReason: _selectedReason,
                    contactPermission: _contactPermission,
                    isSubmitting:
                        support.surveySubmitState == RequestState.loading,
                    feedbackController: _surveyFeedbackController,
                    improvementController: _surveyImprovementController,
                    surveys: support.surveys,
                    onRatingChanged: (value) =>
                        setState(() => _surveyRating = value),
                    onReasonChanged: (value) =>
                        setState(() => _selectedReason = value),
                    onContactChanged: (value) =>
                        setState(() => _contactPermission = value),
                    onSubmitSurvey: _submitSurvey,
                    onRefresh: support.loadAll,
                  ),
                  SupportResponsesTab(
                    complaints: support.complaints,
                    notifications: support.notifications,
                    errorMessage: support.errorMessage,
                    onRefresh: support.loadAll,
                  ),
                ],
              ),
      ),
    );
  }
}
