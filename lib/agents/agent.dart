import 'package:flutter/foundation.dart';
import '../services/gemma_service.dart';
import '../services/response_generator.dart';
import 'database_service.dart';
import 'agent_nodes.dart';
import 'schemas.dart';
import 'state.dart';

/// Main Agent class that orchestrates the entire agent system
/// This implements the pipeline: Router -> Appropriate Node -> Response
class Agent {
  late final GemmaService _gemmaService;
  late final ResponseGenerator _responseGenerator;
  late final DatabaseService _databaseService;
  late final AgentNodes _agentNodes;
  
  AgentState _currentState;

  Agent({
    AgentState? initialState,
  }) : _currentState = initialState ?? AgentState();

  /// Initialize the agent system
  Future<void> initialize() async {
    try {
      debugPrint('[Agent] Initializing agent system...');
      
      // Initialize Gemma service
      _gemmaService = GemmaService();
      await _gemmaService.initializeModel(
        onStatusUpdate: (message) {
          debugPrint('[Agent] Model status: $message');
        },
        onProgressUpdate: (progress) {
          if (progress != null) {
            debugPrint('[Agent] Model progress: ${(progress * 100).toInt()}%');
          }
        },
      );

      // Initialize response generator
      _responseGenerator = ResponseGenerator(_gemmaService);

      // Initialize database service
      _databaseService = DatabaseService();

      // Initialize agent nodes
      _agentNodes = AgentNodes(
        responseGenerator: _responseGenerator,
        databaseService: _databaseService,
      );

      debugPrint('[Agent] Agent system initialized successfully');
    } catch (e) {
      debugPrint('[Agent] Failed to initialize: $e');
      rethrow;
    }
  }

  /// Process a user message through the agent pipeline
  Future<String> processMessage(String userMessage) async {
    try {
      debugPrint('[Agent] Processing message: "$userMessage"');
      
      // Update state with new message
      _currentState = _currentState.copyWith(
        recentMessages: [..._currentState.recentMessages, userMessage],
        currentDateTime: DateTime.now(),
      );

      // Step 1: Route the message to determine subtasks
      final routeOutput = await _agentNodes.routeSubtasks(
        userMessage: userMessage,
        state: _currentState,
      );

      debugPrint('[Agent] Router identified ${routeOutput.subTasks.length} subtasks');

      // Step 2: Process each subtask
      final responses = <String>[];
      
      for (final subtask in routeOutput.subTasks) {
        final response = await _processSubtask(subtask);
        responses.add(response);
      }

      // Step 3: Combine responses
      String finalResponse;
      if (responses.isEmpty) {
        finalResponse = routeOutput.reply ?? 
            'I processed your message but couldn\'t generate a specific response.';
      } else if (responses.length == 1) {
        finalResponse = responses.first;
      } else {
        finalResponse = 'I handled multiple tasks:\n\n${responses.asMap().entries.map((e) => '${e.key + 1}. ${e.value}').join('\n\n')}';
      }

      // Update state with processing results
      _updateStateAfterProcessing(routeOutput, responses);

      debugPrint('[Agent] Final response: $finalResponse');
      return finalResponse;

    } catch (e) {
      debugPrint('[Agent] Error processing message: $e');
      return 'I encountered an error while processing your request. Please try again.';
    }
  }

  /// Process a single subtask based on its type
  Future<String> _processSubtask(SubTask subtask) async {
    debugPrint('[Agent] Processing ${subtask.type} subtask: "${subtask.query}"');
    
    switch (subtask.type) {
      case 'schedule':
        return await _agentNodes.scheduleEvent(
          query: subtask.query,
          state: _currentState,
        );
        
      case 'query':
        return await _agentNodes.queryEvents(
          query: subtask.query,
          state: _currentState,
        );
        
      case 'update':
        return await _agentNodes.updateEvent(
          query: subtask.query,
          state: _currentState,
        );
        
      case 'delete':
        return await _agentNodes.deleteEvent(
          query: subtask.query,
          state: _currentState,
        );
        
      case 'conversation':
        return await _agentNodes.handleConversation(
          query: subtask.query,
          state: _currentState,
        );
        
      default:
        debugPrint('[Agent] Unknown subtask type: ${subtask.type}');
        return 'I\'m not sure how to handle that type of request: ${subtask.type}';
    }
  }

  /// Update the agent state after processing
  void _updateStateAfterProcessing(RouteOutput routeOutput, List<String> responses) {
    // Update recent ID counter
    int newRecentId = _currentState.recentId + routeOutput.subTasks.length;
    
    // For now, we don't create waiting subtasks unless they need clarification
    // This could be enhanced based on the specific needs of your application
    final newWaitingSubtasks = <SubtaskDetails>[];

    // Update the state
    _currentState = _currentState.copyWith(
      recentId: newRecentId,
      waitingSubtasks: newWaitingSubtasks,
      existingSubtasksCount: _currentState.existingSubtasksCount + routeOutput.subTasks.length,
    );
  }

  /// Get the current agent state
  AgentState get currentState => _currentState;

  /// Check if the agent is ready to process messages
  bool get isReady => _responseGenerator.isReady;

  /// Get database statistics
  Future<Map<String, dynamic>> getDatabaseStats() async {
    return await _databaseService.getDatabaseStats();
  }

  /// Clear all events from the database (for testing)
  Future<void> clearAllEvents() async {
    await _databaseService.clearAllEvents();
    debugPrint('[Agent] All events cleared from database');
  }

  /// Get all events (for debugging/admin purposes)
  Future<List<Map<String, dynamic>>> getAllEvents() async {
    return await _databaseService.getAllEvents();
  }

  /// Add a test event (for debugging)
  Future<void> addTestEvent() async {
    final testEvent = {
      'title': 'Test Meeting',
      'description': 'A test meeting for debugging purposes',
      'start_time': DateTime.now().add(Duration(hours: 1)).toIso8601String(),
      'end_time': DateTime.now().add(Duration(hours: 2)).toIso8601String(),
      'location': 'Conference Room A',
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };

    final eventId = await _databaseService.insertEvent(testEvent);
    debugPrint('[Agent] Added test event with ID: $eventId');
  }

  /// Dispose of resources
  Future<void> dispose() async {
    debugPrint('[Agent] Disposing agent resources...');
    
    _gemmaService.dispose();
    await _databaseService.close();
    
    debugPrint('[Agent] Agent resources disposed');
  }

  /// Reset the agent state (useful for testing)
  void resetState() {
    _currentState = AgentState();
    debugPrint('[Agent] Agent state reset');
  }

  /// Get a summary of the current state
  Map<String, dynamic> getStateSummary() {
    return {
      'recent_messages_count': _currentState.recentMessages.length,
      'waiting_subtasks_count': _currentState.waitingSubtasks.length,
      'recent_id': _currentState.recentId,
      'existing_subtasks_count': _currentState.existingSubtasksCount,
      'tenant_id': _currentState.tenantId,
      'is_ready': isReady,
      'current_datetime': _currentState.currentDateTime.toIso8601String(),
    };
  }
}
