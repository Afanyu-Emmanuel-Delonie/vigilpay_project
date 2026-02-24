import 'package:flutter/foundation.dart';

import '../../../../core/constants/endpoint_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/request_state.dart';
import '../../../auth/domain/entities/session_entity.dart';

class SupportController extends ChangeNotifier {
  SupportController({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  RequestState _state = RequestState.idle;
  RequestState _complaintSubmitState = RequestState.idle;
  RequestState _surveySubmitState = RequestState.idle;
  String? _errorMessage;

  List<Map<String, dynamic>> _complaints = const [];
  List<Map<String, dynamic>> _surveys = const [];
  List<Map<String, dynamic>> _notifications = const [];

  RequestState get state => _state;
  RequestState get complaintSubmitState => _complaintSubmitState;
  RequestState get surveySubmitState => _surveySubmitState;
  String? get errorMessage => _errorMessage;
  List<Map<String, dynamic>> get complaints => _complaints;
  List<Map<String, dynamic>> get surveys => _surveys;
  List<Map<String, dynamic>> get notifications => _notifications;

  Future<void> loadAll() async {
    _state = RequestState.loading;
    _errorMessage = null;
    notifyListeners();

    var hadAnyFailure = false;

    try {
      final complaintsPayload = await _apiClient.getAny(EndpointConstants.complaints);
      _complaints = _parseCollection(complaintsPayload);
    } catch (_) {
      hadAnyFailure = true;
      _complaints = const [];
    }

    try {
      final surveysPayload = await _apiClient.getAny(EndpointConstants.surveys);
      _surveys = _parseCollection(surveysPayload);
    } catch (_) {
      hadAnyFailure = true;
      _surveys = const [];
    }

    try {
      final notificationsPayload = await _apiClient.getAny(EndpointConstants.notifications);
      _notifications = _parseCollection(notificationsPayload);
    } catch (_) {
      hadAnyFailure = true;
      _notifications = const [];
    }

    _state = hadAnyFailure ? RequestState.error : RequestState.success;
    _errorMessage = hadAnyFailure
        ? 'Some support data failed to load. Pull to refresh.'
        : null;
    notifyListeners();
  }

  Future<bool> submitComplaint(String text) async {
    _complaintSubmitState = RequestState.loading;
    notifyListeners();
    try {
      await _apiClient.post(
        EndpointConstants.complaints,
        body: <String, dynamic>{'text': text.trim()},
      );
      _complaintSubmitState = RequestState.success;
      await loadAll();
      return true;
    } catch (_) {
      _complaintSubmitState = RequestState.error;
      notifyListeners();
      return false;
    }
  }

  Future<bool> submitSurvey({
    required SessionEntity? session,
    required int rating,
    required String reason,
    required String improvement,
    required String additionalFeedback,
    required bool contactPermission,
  }) async {
    _surveySubmitState = RequestState.loading;
    notifyListeners();
    try {
      final feedback = _buildSurveyFeedback(
        session: session,
        reason: reason,
        improvement: improvement,
        additionalFeedback: additionalFeedback,
        contactPermission: contactPermission,
      );
      await _apiClient.post(
        EndpointConstants.surveys,
        body: <String, dynamic>{
          'rating': rating,
          'feedback': feedback,
        },
      );
      _surveySubmitState = RequestState.success;
      await loadAll();
      return true;
    } catch (_) {
      _surveySubmitState = RequestState.error;
      notifyListeners();
      return false;
    }
  }

  static String _buildSurveyFeedback({
    required SessionEntity? session,
    required String reason,
    required String improvement,
    required String additionalFeedback,
    required bool contactPermission,
  }) {
    final tier = (session?.riskTier ?? '').toLowerCase();
    final probability = session?.riskProbability ?? 0;
    final isHighRisk = tier.contains('high') || probability >= 0.65;

    if (!isHighRisk) {
      return additionalFeedback;
    }

    final b = StringBuffer();
    b.writeln('[Retention Survey]');
    b.writeln('Reason: ${reason.isEmpty ? 'Not provided' : reason}');
    b.writeln(
      'Requested improvement: ${improvement.isEmpty ? 'Not provided' : improvement}',
    );
    b.writeln('Contact permission: ${contactPermission ? 'Yes' : 'No'}');
    if (additionalFeedback.isNotEmpty) {
      b.writeln('Additional feedback: $additionalFeedback');
    }
    return b.toString().trim();
  }

  static List<Map<String, dynamic>> _parseCollection(dynamic payload) {
    if (payload is List) {
      return payload
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    if (payload is Map<String, dynamic>) {
      final results = payload['results'];
      if (results is List) {
        return results
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    }
    return <Map<String, dynamic>>[];
  }
}
