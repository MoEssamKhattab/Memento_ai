/// Schema classes for structured LLM outputs
/// These classes help parse and validate JSON responses from the language model

/// Represents a subtask identified by the router
class SubTask {
  final String query;
  final String type;

  SubTask({
    required this.query,
    required this.type,
  });

  factory SubTask.fromJson(Map<String, dynamic> json) {
    return SubTask(
      query: json['query'] ?? '',
      type: json['type'] ?? 'conversation',
    );
  }

  Map<String, dynamic> toJson() => {
    'query': query,
    'type': type,
  };

  bool get isValid => query.isNotEmpty && _validTypes.contains(type);

  static const Set<String> _validTypes = {
    'schedule',
    'query', 
    'update',
    'delete',
    'conversation'
  };
}

/// Router output containing classified subtasks and reply
class RouteOutput {
  final List<SubTask> subTasks;
  final String? reply;

  RouteOutput({
    required this.subTasks,
    this.reply,
  });

  factory RouteOutput.fromJson(Map<String, dynamic> json) {
    final subTasksList = json['sub_tasks'] as List? ?? [];
    return RouteOutput(
      subTasks: subTasksList
          .map((task) => SubTask.fromJson(task as Map<String, dynamic>))
          .where((task) => task.isValid)
          .toList(),
      reply: json['reply'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'sub_tasks': subTasks.map((task) => task.toJson()).toList(),
    'reply': reply,
  };
}

/// SQL query generation result
class SqlQueryResult {
  final String sqlQuery;
  final String explanation;

  SqlQueryResult({
    required this.sqlQuery,
    required this.explanation,
  });

  factory SqlQueryResult.fromJson(Map<String, dynamic> json) {
    return SqlQueryResult(
      sqlQuery: json['sql_query'] ?? '',
      explanation: json['explanation'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'sql_query': sqlQuery,
    'explanation': explanation,
  };

  bool get isValid => sqlQuery.isNotEmpty;
}

/// Event details for scheduling
class EventDetails {
  final String title;
  final String? description;
  final DateTime startTime;
  final DateTime endTime;
  final String? location;

  EventDetails({
    required this.title,
    this.description,
    required this.startTime,
    required this.endTime,
    this.location,
  });

  factory EventDetails.fromJson(Map<String, dynamic> json) {
    return EventDetails(
      title: json['title'] ?? '',
      description: json['description'],
      startTime: DateTime.parse(json['start_time']),
      endTime: DateTime.parse(json['end_time']),
      location: json['location'],
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'start_time': startTime.toIso8601String(),
    'end_time': endTime.toIso8601String(),
    'location': location,
  };

  Map<String, dynamic> toDatabaseMap() => {
    'title': title,
    'description': description,
    'start_time': startTime.toIso8601String(),
    'end_time': endTime.toIso8601String(),
    'location': location,
    'created_at': DateTime.now().toIso8601String(),
    'updated_at': DateTime.now().toIso8601String(),
  };
}

/// Schedule event result
class ScheduleEventResult {
  final EventDetails? event;
  final bool success;
  final String message;

  ScheduleEventResult({
    this.event,
    required this.success,
    required this.message,
  });

  factory ScheduleEventResult.fromJson(Map<String, dynamic> json) {
    EventDetails? event;
    if (json['event'] != null) {
      try {
        event = EventDetails.fromJson(json['event'] as Map<String, dynamic>);
      } catch (e) {
        // Invalid event format
      }
    }

    return ScheduleEventResult(
      event: event,
      success: json['success'] ?? false,
      message: json['message'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'event': event?.toJson(),
    'success': success,
    'message': message,
  };
}

/// Update event result
class UpdateEventResult {
  final Map<String, dynamic> updates;
  final String explanation;

  UpdateEventResult({
    required this.updates,
    required this.explanation,
  });

  factory UpdateEventResult.fromJson(Map<String, dynamic> json) {
    return UpdateEventResult(
      updates: json['updates'] as Map<String, dynamic>? ?? {},
      explanation: json['explanation'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'updates': updates,
    'explanation': explanation,
  };

  Map<String, dynamic> toDatabaseMap() {
    final dbMap = Map<String, dynamic>.from(updates);
    dbMap['updated_at'] = DateTime.now().toIso8601String();
    return dbMap;
  }
}

/// Delete event result
class DeleteEventResult {
  final int? eventId;
  final String? confirmationMessage;
  final bool multipleMatches;
  final List<Map<String, dynamic>>? events;
  final String? message;

  DeleteEventResult({
    this.eventId,
    this.confirmationMessage,
    this.multipleMatches = false,
    this.events,
    this.message,
  });

  factory DeleteEventResult.fromJson(Map<String, dynamic> json) {
    return DeleteEventResult(
      eventId: json['event_id'],
      confirmationMessage: json['confirmation_message'],
      multipleMatches: json['multiple_matches'] ?? false,
      events: (json['events'] as List?)?.cast<Map<String, dynamic>>(),
      message: json['message'],
    );
  }

  Map<String, dynamic> toJson() => {
    'event_id': eventId,
    'confirmation_message': confirmationMessage,
    'multiple_matches': multipleMatches,
    'events': events,
    'message': message,
  };
}
