/// State management for the agent system
/// This represents the short-term memory of the agent
class SubtaskDetails {
  final int id;
  final String query;
  final String progress;
  final String type;
  final DateTime currentDateTime;

  SubtaskDetails({
    required this.id,
    required this.query,
    required this.progress,
    required this.type,
    required this.currentDateTime,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'query': query,
    'progress': progress,
    'type': type,
    'current_datetime': currentDateTime.toIso8601String(),
  };

  factory SubtaskDetails.fromJson(Map<String, dynamic> json) => SubtaskDetails(
    id: json['id'],
    query: json['query'],
    progress: json['progress'],
    type: json['type'],
    currentDateTime: DateTime.parse(json['current_datetime']),
  );
}

/// Overall state of the agent system (short-term memory)
class AgentState {
  final List<String> historySummary;
  final List<String> recentMessages;
  final List<SubtaskDetails> waitingSubtasks;
  final int recentId;
  final int existingSubtasksCount;
  final String tenantId;
  final Map<String, dynamic>? scheduledEvent;
  final DateTime currentDateTime;

  AgentState({
    this.historySummary = const [],
    this.recentMessages = const [],
    this.waitingSubtasks = const [],
    this.recentId = 0,
    this.existingSubtasksCount = 0,
    this.tenantId = 'default',
    this.scheduledEvent,
    DateTime? currentDateTime,
  }) : currentDateTime = currentDateTime ?? DateTime.now();

  AgentState copyWith({
    List<String>? historySummary,
    List<String>? recentMessages,
    List<SubtaskDetails>? waitingSubtasks,
    int? recentId,
    int? existingSubtasksCount,
    String? tenantId,
    Map<String, dynamic>? scheduledEvent,
    DateTime? currentDateTime,
  }) {
    return AgentState(
      historySummary: historySummary ?? this.historySummary,
      recentMessages: recentMessages ?? this.recentMessages,
      waitingSubtasks: waitingSubtasks ?? this.waitingSubtasks,
      recentId: recentId ?? this.recentId,
      existingSubtasksCount: existingSubtasksCount ?? this.existingSubtasksCount,
      tenantId: tenantId ?? this.tenantId,
      scheduledEvent: scheduledEvent ?? this.scheduledEvent,
      currentDateTime: currentDateTime ?? this.currentDateTime,
    );
  }

  Map<String, dynamic> toJson() => {
    'history_summary': historySummary,
    'recent_messages': recentMessages,
    'waiting_subtasks': waitingSubtasks.map((e) => e.toJson()).toList(),
    'recent_id': recentId,
    'existing_subtasks_count': existingSubtasksCount,
    'tenant_id': tenantId,
    'scheduled_event': scheduledEvent,
    'current_datetime': currentDateTime.toIso8601String(),
  };
}

/// Subtask state for individual task processing
class SubtaskState {
  final String id;
  final String query;
  final String progress;
  final int existingSubtasksCount;
  final String tenantId;
  final DateTime currentDateTime;

  SubtaskState({
    required this.id,
    required this.query,
    required this.progress,
    required this.existingSubtasksCount,
    required this.tenantId,
    DateTime? currentDateTime,
  }) : currentDateTime = currentDateTime ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'query': query,
    'progress': progress,
    'existing_subtasks_count': existingSubtasksCount,
    'tenant_id': tenantId,
    'current_datetime': currentDateTime.toIso8601String(),
  };
}
