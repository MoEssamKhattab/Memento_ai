import 'package:flutter/foundation.dart';
import '/services/gemma_service.dart';

/// A dedicated class for handling AI response generation
/// This class abstracts the complexity of message handling and response generation
/// from the UI layer, providing a clean interface for chat interactions.
class ResponseGenerator {
  final GemmaService _gemmaService;
  
  ResponseGenerator(this._gemmaService);

  /// Generates a response from the AI model based on user text input
  /// 
  /// [text] - The text input from the user
  /// 
  /// Returns a [ResponseGenerationResult] containing the user message and response stream
  Future<ResponseGenerationResult> generateResponse({
    required String text,
  }) async {
    if (!_gemmaService.isModelInitialized) {
      throw Exception('Model is not initialized');
    }

    // Create the user's message object (text only)
    final userMessage = Message.text(text: text, isUser: true);
    
    try {
      // Send the user's message to the Gemma chat instance
      await _gemmaService.addMessageToChat(userMessage);
      
      // Get the response stream
      final responseStream = _gemmaService.generateResponse();
      
      return ResponseGenerationResult(
        userMessage: userMessage,
        responseStream: responseStream,
      );
    } catch (e) {
      debugPrint("Error generating response: $e");
      rethrow;
    }
  }

  /// Checks if the generator is ready to process requests
  bool get isReady => _gemmaService.isModelInitialized;
}

/// Result of response generation containing the user message and AI response stream
class ResponseGenerationResult {
  final Message userMessage;
  final Stream<String> responseStream;

  ResponseGenerationResult({
    required this.userMessage,
    required this.responseStream,
  });
}
