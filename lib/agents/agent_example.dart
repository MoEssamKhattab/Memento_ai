/// Example of how to integrate the Agent system into your existing UI
/// This shows how to modify the TranslatorScreen to use the new Agent

/*
To integrate the Agent into your existing TranslatorScreen, you would:

1. Import the agent:
```dart
import 'package:offline_menu_translator/agents/agent.dart';
```

2. Replace the ResponseGenerator with the Agent:
```dart
class _TranslatorScreenState extends State<TranslatorScreen> {
  late final Agent _agent;
  
  @override
  void initState() {
    super.initState();
    _agent = Agent();
    _initializeAgent();
  }
  
  Future<void> _initializeAgent() async {
    try {
      await _agent.initialize();
      setState(() {
        _isModelLoading = false;
      });
    } catch (e) {
      // Handle error
      setState(() {
        _isModelLoading = false;
      });
    }
  }
```

3. Update the _sendMessage method:
```dart
void _sendMessage() async {
  final text = _textController.text.trim();

  if (text.isEmpty) return;
  if (_isAwaitingResponse || !_agent.isReady) return;

  setState(() {
    _isAwaitingResponse = true;
  });

  // Clear input
  _textController.clear();
  FocusScope.of(context).unfocus();

  try {
    // Add user message to UI
    final userMessage = Message.text(text: text, isUser: true);
    setState(() {
      _messages.add(userMessage);
    });

    // Process with agent
    final response = await _agent.processMessage(text);

    // Add agent response to UI
    final agentMessage = Message.text(text: response, isUser: false);
    setState(() {
      _messages.add(agentMessage);
    });

  } catch (e) {
    // Handle error
    final errorMessage = Message.text(text: 'Error: $e', isUser: false);
    setState(() {
      _messages.add(errorMessage);
    });
  } finally {
    setState(() {
      _isAwaitingResponse = false;
    });
  }
}
```

4. Update the dispose method:
```dart
@override
void dispose() {
  _agent.dispose();
  _textController.dispose();
  super.dispose();
}
```

5. Example usage commands the user can try:
- "Schedule a meeting tomorrow at 3pm"
- "What meetings do I have this week?"
- "Update my meeting at 2pm to 3pm instead"
- "Delete the team standup meeting"
- "Show me all events for today"

The agent will automatically:
1. Parse the user's intent (schedule, query, update, delete)
2. Use the Gemma model to understand the details
3. Execute the appropriate database operations
4. Return a natural language response

*/

// Example standalone usage of the Agent system:

import '../agents/agent.dart';

class AgentExample {
  late final Agent _agent;

  Future<void> runExample() async {
    // Initialize agent
    _agent = Agent();
    await _agent.initialize();

    // Example interactions
    await _testScheduling();
    await _testQuerying();
    await _testUpdating();
    await _testDeleting();

    // Cleanup
    await _agent.dispose();
  }

  Future<void> _testScheduling() async {
    print('=== Testing Scheduling ===');
    
    final response1 = await _agent.processMessage(
      'Schedule a team meeting tomorrow at 2pm for 1 hour in Conference Room A'
    );
    print('Response: $response1');

    final response2 = await _agent.processMessage(
      'Book a doctor appointment next Monday at 10am'
    );
    print('Response: $response2');
  }

  Future<void> _testQuerying() async {
    print('\\n=== Testing Querying ===');
    
    final response1 = await _agent.processMessage(
      'What meetings do I have tomorrow?'
    );
    print('Response: $response1');

    final response2 = await _agent.processMessage(
      'Show me all my appointments this week'
    );
    print('Response: $response2');
  }

  Future<void> _testUpdating() async {
    print('\\n=== Testing Updating ===');
    
    final response1 = await _agent.processMessage(
      'Change my team meeting tomorrow to 3pm instead of 2pm'
    );
    print('Response: $response1');

    final response2 = await _agent.processMessage(
      'Update event ID 1 to move it to Conference Room B'
    );
    print('Response: $response2');
  }

  Future<void> _testDeleting() async {
    print('\\n=== Testing Deleting ===');
    
    final response1 = await _agent.processMessage(
      'Cancel my doctor appointment'
    );
    print('Response: $response1');

    final response2 = await _agent.processMessage(
      'Delete event ID 2'
    );
    print('Response: $response2');
  }

  Future<void> _printDatabaseStats() async {
    final stats = await _agent.getDatabaseStats();
    print('\\n=== Database Stats ===');
    print('Total events: ${stats['total_events']}');
    print('Database pages: ${stats['database_pages']}');
  }
}
