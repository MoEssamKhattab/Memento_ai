import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../services/response_generator.dart';
import 'database_service.dart';
import 'schemas.dart';
import 'prompts.dart';
import 'state.dart';
import '/utils/notification_helper.dart';

/// Agent nodes for processing different types of tasks
/// These nodes use the ResponseGenerator and DatabaseService to handle user requests
class AgentNodes {
  final ResponseGenerator _responseGenerator;
  final DatabaseService _databaseService;

  AgentNodes({
    required ResponseGenerator responseGenerator,
    required DatabaseService databaseService,
  })  : _responseGenerator = responseGenerator,
        _databaseService = databaseService;

  /// Router node - classifies user input and routes to appropriate subtasks
  Future<RouteOutput> routeSubtasks({
    required String userMessage,
    required AgentState state,
  }) async {
    try {
      // Prepare the prompt with context
      final promptWithContext = Prompts.routeSubtasksPrompt
          .replaceAll('{messages}', userMessage)
          .replaceAll('{waiting_subtasks}', _formatWaitingSubtasks(state.waitingSubtasks))
          .replaceAll('{current_datetime}', state.currentDateTime.toIso8601String());

      debugPrint('[Router] Processing user message: $userMessage');

      // Generate response using the LLM
      final result = await _responseGenerator.generateResponse(text: promptWithContext);
      
      // Collect the full response
      String fullResponse = '';
      await for (final token in result.responseStream) {
        fullResponse += token;
      }

      debugPrint('[Router] Raw LLM response: $fullResponse');

      // Parse the JSON response
      final jsonResponse = _extractJsonFromResponse(fullResponse);
      final routeOutput = RouteOutput.fromJson(jsonResponse);

      debugPrint('[Router] Parsed ${routeOutput.subTasks.length} subtasks');
      
      return routeOutput;
    } catch (e) {
      debugPrint('[Router] Error: $e');
      // Return a fallback conversation task
      return RouteOutput(
        subTasks: [
          SubTask(
            query: userMessage,
            type: 'conversation',
          )
        ],
        reply: 'I encountered an error processing your request. Could you please try again?',
      );
    }
  }

  /// Schedule node - handles scheduling new events
  Future<String> scheduleEvent({
    required String query,
    required AgentState state,
  }) async {
    try {
      debugPrint('[Schedule] Processing query: $query');

      // Prepare the prompt
      final promptWithContext = Prompts.scheduleEventPrompt
          .replaceAll('{request}', query)
          .replaceAll('{current_datetime}', state.currentDateTime.toIso8601String());

      // Generate response using the LLM
      final result = await _responseGenerator.generateResponse(text: promptWithContext);
      
      // Collect the full response
      String fullResponse = '';
      await for (final token in result.responseStream) {
        fullResponse += token;
      }

      debugPrint('[Schedule] Raw LLM response: $fullResponse');

      // Parse the JSON response
      final jsonResponse = _extractJsonFromResponse(fullResponse);
      final scheduleResult = ScheduleEventResult.fromJson(jsonResponse);

      if (scheduleResult.success && scheduleResult.event != null) {
        // Insert into database
        final eventId = await _databaseService.insertEvent(
          scheduleResult.event!.toDatabaseMap()
        );

        await NotificationHelper.scheduleNotification(
          id: eventId,
          title: scheduleResult.event?.title,
          body: "You have a ${scheduleResult.event?.title} after 5 minutes.",
          scheduledTime: scheduleResult.event?.startTime ?? DateTime.now()
        );

        debugPrint('[Schedule] Event created with ID: $eventId');
        
        return 'Successfully scheduled "${scheduleResult.event!.title}" for ${_formatDateTime(scheduleResult.event!.startTime)}. Event ID: $eventId';
      } else {
        return scheduleResult.message;
      }
    } catch (e) {
      debugPrint('[Schedule] Error: $e');
      return 'I encountered an error while trying to schedule your event. Please try again with more specific details.';
    }
  }

  /// Query node - handles searching and retrieving events
  Future<String> queryEvents({
    required String query,
    required AgentState state,
  }) async {
    try {

      debugPrint('[Query] Processing query: $query');
      // final events = await _databaseService.getAllEvents();
      
      // if (events.isEmpty) {
      //   debugPrint('📭 No events found in database');
      //   debugPrint('='*60 + '\n');
      // }

      // debugPrint('📊 Total Events: ${events.length}');
      // debugPrint('-'*60);

      // for (int i = 0; i < events.length; i++) {
      //   final event = events[i];
      //   debugPrint('📅 Event #${i + 1} (ID: ${event['id']})');
      //   debugPrint('   Title: ${event['title'] ?? 'N/A'}');
      //   debugPrint('   Description: ${event['description'] ?? 'N/A'}');
      //   debugPrint('   Start: ${event['start_time']}');
      //   debugPrint('   End: ${event['end_time']}');
      //   debugPrint('   Location: ${event['location'] ?? 'N/A'}');
      //   // debugPrint('   Created: ${event['created_at']}');
      //   // debugPrint('   Updated: ${event['updated_at']}');
        
      //   if (i < events.length - 1) {
      //     debugPrint('   ' + '-'*50);
      //   }
      // }
      
      // First, generate SQL query using LLM
      final sqlPrompt = Prompts.generateSqlPrompt
          .replaceAll('{query}', query)
          .replaceAll('{current_datetime}', state.currentDateTime.toIso8601String());

      final result = await _responseGenerator.generateResponse(text: sqlPrompt);
      
      String fullResponse = '';
      await for (final token in result.responseStream) {
        fullResponse += token;
      }

      debugPrint('[Query] Raw SQL generation response: $fullResponse');

      final jsonResponse = _extractJsonFromResponse(fullResponse);
      final sqlResult = SqlQueryResult.fromJson(jsonResponse);

      if (!sqlResult.isValid) {
        return 'I could not generate a proper query for your request. Please try rephrasing it.';
      }

      debugPrint('[Query] Generated SQL: ${sqlResult.sqlQuery}');

      // Execute the SQL query
      final queryResults = await _databaseService.executeQuery(sqlResult.sqlQuery);
      
      if (queryResults.isEmpty) {
        return 'No events found matching your criteria.';
      }

      // Format the results for display
      final formattedResults = _formatQueryResults(queryResults);
      return 'I found ${queryResults.length} event(s):\n\n$formattedResults';

    } catch (e) {
      debugPrint('[Query] Error: $e');
      return 'I encountered an error while searching for events. Please try a different query.';
    }
  }

  /// Update node - handles updating existing events
  Future<String> updateEvent({
    required String query,
    required AgentState state,
  }) async {
    try {
      debugPrint('[Update] Processing query: $query');

      // First, we need to find the event to update
      // For simplicity, we'll assume the query contains event information
      // In a more sophisticated system, this would involve multiple steps

      // Extract event ID or search criteria from the query
      final eventId = _extractEventIdFromQuery(query);
      
      if (eventId == null) {
        return 'Please specify which event you want to update. You can reference it by ID or provide more details.';
      }

      // Get the current event
      final currentEvent = await _databaseService.getEventById(eventId);
      if (currentEvent == null) {
        return 'Event with ID $eventId not found.';
      }

      // Generate update instructions using LLM
      final updatePrompt = Prompts.updateEventPrompt
          .replaceAll('{current_event}', jsonEncode(currentEvent))
          .replaceAll('{update_request}', query)
          .replaceAll('{current_datetime}', state.currentDateTime.toIso8601String());

      final result = await _responseGenerator.generateResponse(text: updatePrompt);
      
      String fullResponse = '';
      await for (final token in result.responseStream) {
        fullResponse += token;
      }

      debugPrint('[Update] Raw LLM response: $fullResponse');

      final jsonResponse = _extractJsonFromResponse(fullResponse);
      final updateResult = UpdateEventResult.fromJson(jsonResponse);

      if (updateResult.updates.isEmpty) {
        return 'No updates were identified from your request. Please be more specific about what you want to change.';
      }

      // Apply the updates
      final rowsAffected = await _databaseService.updateEvent(
        eventId,
        updateResult.toDatabaseMap(),
      );

      if (rowsAffected > 0) {
        debugPrint('[Update] Event $eventId updated successfully');
        return 'Successfully updated the event. ${updateResult.explanation}';
      } else {
        return 'Failed to update the event. It may have been deleted.';
      }

    } catch (e) {
      debugPrint('[Update] Error: $e');
      return 'I encountered an error while trying to update the event. Please try again.';
    }
  }

  /// Delete node - handles deleting events
  Future<String> deleteEvent({
    required String query,
    required AgentState state,
  }) async {
    try {
      debugPrint('[Delete] Processing query: $query');

      // First, find events that match the deletion criteria
      final eventId = _extractEventIdFromQuery(query);
      
      if (eventId != null) {
        // Direct deletion by ID
        final rowsAffected = await _databaseService.deleteEvent(eventId);
        
        if (rowsAffected > 0) {
          debugPrint('[Delete] Event $eventId deleted successfully');
          return 'Successfully deleted the event with ID $eventId.';
        } else {
          return 'Event with ID $eventId not found or already deleted.';
        }
      } else {
        // Search for events to delete
        // For simplicity, we'll search by title keywords
        final searchTerms = _extractSearchTermsFromQuery(query);
        
        if (searchTerms.isEmpty) {
          return 'Please specify which event you want to delete. You can provide the event ID or keywords from the event title.';
        }

        final events = await _databaseService.searchEventsByTitle(searchTerms.join(' '));
        
        if (events.isEmpty) {
          return 'No events found matching your deletion criteria.';
        }

        if (events.length == 1) {
          final event = events.first;
          final eventId = event['id'] as int;
          
          await _databaseService.deleteEvent(eventId);
          debugPrint('[Delete] Event $eventId deleted successfully');
          
          return 'Successfully deleted "${event['title']}" scheduled for ${_formatDateTime(DateTime.parse(event['start_time']))}.';
        } else {
          // Multiple matches - ask for clarification
          final eventsList = events.map((event) => 
            '- ID ${event['id']}: "${event['title']}" on ${_formatDateTime(DateTime.parse(event['start_time']))}'
          ).join('\n');
          
          return 'I found multiple events matching your criteria:\n\n$eventsList\n\nPlease specify the ID of the event you want to delete.';
        }
      }
    } catch (e) {
      debugPrint('[Delete] Error: $e');
      return 'I encountered an error while trying to delete the event. Please try again.';
    }
  }

  /// Conversation node - handles general conversation
  Future<String> handleConversation({
    required String query,
    required AgentState state,
  }) async {
    // For now, return a simple response
    // This could be enhanced with more sophisticated conversation handling
    return 'I\'m here to help you manage your calendar. I can help you schedule events, find existing ones, update them, or delete them. What would you like to do?';
  }

  // Helper methods

  String _formatWaitingSubtasks(List<SubtaskDetails> subtasks) {
    if (subtasks.isEmpty) return 'None';
    
    return subtasks.map((task) => 
      'ID ${task.id}: ${task.query} (${task.type}) - ${task.progress}'
    ).join('\n');
  }

  Map<String, dynamic> _extractJsonFromResponse(String response) {
    try {
      // Try to find JSON in the response
      final jsonStart = response.indexOf('{');
      final jsonEnd = response.lastIndexOf('}');
      
      if (jsonStart != -1 && jsonEnd != -1 && jsonEnd > jsonStart) {
        final jsonString = response.substring(jsonStart, jsonEnd + 1);
        return jsonDecode(jsonString);
      }
      
      // If no JSON brackets found, try to parse the entire response
      return jsonDecode(response);
    } catch (e) {
      debugPrint('[JSON Parse] Error parsing JSON from response: $e');
      debugPrint('[JSON Parse] Response was: $response');
      
      // Return a fallback JSON structure
      return {
        'error': 'Failed to parse JSON response',
        'raw_response': response,
      };
    }
  }

  String _formatQueryResults(List<Map<String, dynamic>> results) {
    return results.map((event) {
      final startTime = DateTime.parse(event['start_time']);
      final endTime = DateTime.parse(event['end_time']);
      
      String result = '📅 ${event['title']}';
      result += '\n   📍 ${_formatDateTime(startTime)} - ${_formatTime(endTime)}';
      
      if (event['location'] != null && event['location'].toString().isNotEmpty) {
        result += '\n   🌍 ${event['location']}';
      }
      
      if (event['description'] != null && event['description'].toString().isNotEmpty) {
        result += '\n   📝 ${event['description']}';
      }
      
      result += '\n   🆔 ID: ${event['id']}';
      
      return result;
    }).join('\n\n');
  }

  int? _extractEventIdFromQuery(String query) {
    // Simple regex to extract ID from query like "event 123" or "ID 123"
    final idRegex = RegExp(r'\b(?:id|event)\s+(\d+)\b', caseSensitive: false);
    final match = idRegex.firstMatch(query);
    return match != null ? int.tryParse(match.group(1)!) : null;
  }

  List<String> _extractSearchTermsFromQuery(String query) {
    // Remove common words and extract meaningful terms
    final stopWords = {'delete', 'remove', 'cancel', 'event', 'meeting', 'the', 'a', 'an', 'with', 'for', 'on', 'at'};
    
    return query
        .toLowerCase()
        .split(RegExp(r'\W+'))
        .where((word) => word.isNotEmpty && !stopWords.contains(word))
        .toList();
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${_formatTime(dateTime)}';
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final amPm = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    
    return '$displayHour:$minute $amPm';
  }
}
