import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import '/backend/handle_query.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:real_volume/real_volume.dart';
import '/utils/notification_helper.dart';
import 'package:geolocator/geolocator.dart';
import '../widgets/memento_drawer.dart';
import 'package:http/http.dart' as http;
import 'package:animated_text_kit/animated_text_kit.dart';

import '/agents/agent.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _queryController = TextEditingController();

  // Agent system
  late final Agent _agent;
  bool _isAgentInitialized = false;
  bool _isInitializingAgent = true;
  String _initializationStatus = 'Starting agent...';

  // Speech and UI state
  bool isListeningQuery = false;
  bool showStopQueryButton = false;
  String _queryText = '';
  final List<Map<String, dynamic>> replies = [];
  bool isLoading = false;
  final List<Map<String, String>> _conversation = [];
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _initializeAgent();
    _queryController.addListener(() {
      setState(() {
        _queryText = _queryController.text.trim();
      });
    });
  }

  Future<void> _initializeAgent() async {
    try {
      setState(() {
        _initializationStatus = 'Creating agent instance...';
      });

      _agent = Agent();

      setState(() {
        _initializationStatus = 'Initializing AI model...';
      });

      await _agent.initialize();

      setState(() {
        _isAgentInitialized = true;
        _isInitializingAgent = false;
        _initializationStatus = 'Agent ready!';
      });

      // Add welcome message
      addReply(
        'Hello! Memento with you. I can help you schedule meetings, find events, update them, or delete them. What would you like to do?',
        isUser: false,
      );
    } catch (e) {
      setState(() {
        _isAgentInitialized = false;
        _isInitializingAgent = false;
        _initializationStatus = 'Failed to initialize agent: $e';
      });

      // Add error message to chat
      addReply('Error initializing AI assistant: $e', isUser: false);
    }
  }

  Future<void> _showDatabaseStats() async {
    if (!_isAgentInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agent not initialized yet')),
      );
      return;
    }

    try {
      final stats = await _agent.getDatabaseStats();
      final events = await _agent.getAllEvents();

      if (!mounted) return;

      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Database Statistics'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total Events: ${stats['total_events']}'),
                  Text('Database Pages: ${stats['database_pages']}'),
                  Text('Database Name: ${stats['database_name']}'),
                  const SizedBox(height: 16),
                  const Text(
                    'Recent Events:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (events.isEmpty)
                    const Text('No events found')
                  else
                    ...events
                        .take(5)
                        .map(
                          (event) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              '${event['id']}: ${event['title']} (${event['start_time']})',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error getting stats: $e')));
    }
  }

  Future<void> _clearDatabase() async {
    if (!_isAgentInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agent not initialized yet')),
      );
      return;
    }

    try {
      await _agent.clearAllEvents();
      addReply('Database cleared successfully', isUser: false);
    } catch (e) {
      addReply('Error clearing database: $e', isUser: false);
    }
  }

  Future<void> _sendMessage() async {
    setState(() {
      _isProcessing = true;
    });
    _addMessage('You', _queryText);

    try {
      final response = await _agent.processMessage(_queryText);
      _addMessage('Agent', response);
    } catch (e) {
      _addMessage('Agent', 'Error: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
      _queryController.clear();
      setState(() {
        _queryText = '';
      });
    }
  }

  void _addMessage(String sender, String message) {
    setState(() {
      _conversation.add({
        'sender': sender,
        'message': message,
        'time': DateTime.now().toString().substring(11, 19), // HH:MM:SS
      });
    });
  }

  void addReply(String text, {required bool isUser}) {
    setState(() {
      replies.add({"text": text, "isUser": isUser});
      isLoading = isUser;
    });
  }

  void setLoading(bool value) {
    setState(() {
      isLoading = value;
    });
  }

  Future<void> _requestPermissions() async {
    // Mic
    final status = await Permission.microphone.status;
    if (!status.isGranted) {
      final result = await Permission.microphone.request();
      if (result.isGranted) {
        print('Microphone permission granted');
      } else {
        print('Microphone permission not granted');
      }
    }

    // Don't Disturb
    bool? isPermissionDNDGranted = await RealVolume.isPermissionGranted();
    if (!isPermissionDNDGranted!) {
      await RealVolume.openDoNotDisturbSettings();
    }
  }

  @override
  void dispose() {
    if (_isAgentInitialized) {
      _agent.dispose();
    }
    _queryController.dispose();
    super.dispose();
  }

  Widget _buildLogoHeader() => Padding(
    padding: const EdgeInsets.only(top: 40),
    child: Column(
      children: [
        ClipOval(
          child: Image.asset(
            'assets/images/memento_logo.png',
            height: 160,
            width: 160,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: 4),
        Center(
          child: AnimatedTextKit(
            isRepeatingAnimation: false,
            totalRepeatCount: 1,
            animatedTexts: [
              TypewriterAnimatedText(
                'Life Remembers Itself!',
                textStyle: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                ),
                speed: const Duration(milliseconds: 100),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('Memento'),
        backgroundColor: const Color(0xFF00B3FF),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        actions: [
          if (_isAgentInitialized) ...[
            IconButton(
              icon: const Icon(Icons.info),
              onPressed: _showDatabaseStats,
              tooltip: 'Database Stats',
            ),
            IconButton(
              icon: const Icon(Icons.clear_all),
              onPressed: _clearDatabase,
              tooltip: 'Clear Database',
            ),
          ],
        ],
      ),
      drawer: const MementoDrawer(),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              children: [
                if (_isInitializingAgent)
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.orange.shade100,
                    child: Row(
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(width: 16),
                        Expanded(child: Text(_initializationStatus)),
                      ],
                    ),
                  ),

                if (_isProcessing && !_isInitializingAgent)
                  Container(
                    padding: const EdgeInsets.all(8),
                    color: Colors.blue.shade100,
                    child: const Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text('Processing...'),
                      ],
                    ),
                  ),

                _buildLogoHeader(),
                const SizedBox(height: 8),

                // Replies List (scrollable and resizes with keyboard)
                Expanded(
                  child: ListView.builder(
                    reverse: false,
                    padding: const EdgeInsets.all(8),
                    itemCount: _conversation.length,
                    itemBuilder: (context, index) {
                      final message = _conversation[index];
                      final isUser = message['sender'] == 'You';
                      final isSystem = message['sender'] == 'System';
                      final isTest = message['sender'] == 'Test';

                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color:
                              isUser
                                  ? Colors.blue.shade600
                                  : isSystem
                                  ? Colors.grey.shade600
                                  : isTest
                                  ? Colors.orange.shade600
                                  : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  message['sender']!,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color:
                                        (isUser || isSystem || isTest)
                                            ? Colors.white
                                            : Colors.black87,
                                  ),
                                ),
                                Text(
                                  message['time']!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color:
                                        (isUser || isSystem || isTest)
                                            ? Colors.white70
                                            : Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              message['message']!,
                              style: TextStyle(
                                color:
                                    (isUser || isSystem || isTest)
                                        ? Colors.white
                                        : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                if (!_isInitializingAgent)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _queryController,
                          style: const TextStyle(fontSize: 16),
                          enabled: _isAgentInitialized,
                          decoration: InputDecoration(
                            hintText:
                                _isAgentInitialized
                                    ? 'Type your query...'
                                    : 'Initializing AI assistant...',
                            hintStyle: const TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                            ),
                            filled: true,
                            fillColor:
                                _isAgentInitialized
                                    ? Colors.white
                                    : Colors.grey.shade100,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 14,
                              horizontal: 16,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (!showStopQueryButton)
                              ElevatedButton(
                                onPressed:
                                    (isListeningQuery || !_isAgentInitialized)
                                        ? null
                                        : () async {
                                          await Future.delayed(
                                            const Duration(seconds: 2),
                                          );
                                          setState(() {
                                            isListeningQuery = true;
                                            showStopQueryButton = true;
                                          });
                                          await HandleQuery.startListening(
                                            context,
                                          );
                                        },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.black,
                                  shape: const CircleBorder(),
                                  padding: const EdgeInsets.all(14),
                                ),
                                child: const Icon(
                                  Icons.mic_none_outlined,
                                  color: Colors.white,
                                ),
                              ),
                            if (showStopQueryButton)
                              ElevatedButton(
                                onPressed: () async {
                                  final queryText =
                                      await HandleQuery.stopListening();
                                  setState(() {
                                    isListeningQuery = false;
                                    showStopQueryButton = false;
                                    _queryText = queryText.trim();
                                  });

                                  if (queryText.trim().isNotEmpty &&
                                      _isAgentInitialized) {
                                    addReply(queryText.trim(), isUser: true);
                                    setLoading(true);

                                    try {
                                      final response = await _agent
                                          .processMessage(queryText.trim());
                                      addReply(response, isUser: false);
                                    } catch (e) {
                                      addReply(
                                        'Error processing request: $e',
                                        isUser: false,
                                      );
                                    } finally {
                                      setLoading(false);
                                    }

                                    _queryController.clear();
                                    setState(() {
                                      _queryText = '';
                                    });
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  shape: const CircleBorder(),
                                  padding: const EdgeInsets.all(14),
                                ),
                                child: const Icon(
                                  Icons.stop_circle_outlined,
                                  color: Colors.white,
                                ),
                              ),
                            if (_queryText.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: _isProcessing ? null : _sendMessage,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  shape: const CircleBorder(),
                                  padding: const EdgeInsets.all(14),
                                ),
                                child: const Icon(
                                  Icons.send,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
