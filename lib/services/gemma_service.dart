import 'package:flutter/foundation.dart';
import 'package:flutter_gemma/core/chat.dart';
import 'package:flutter_gemma/core/model.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma/pigeon.g.dart';
import 'package:permission_handler/permission_handler.dart';

// Export the Message class from flutter_gemma
export 'package:flutter_gemma/flutter_gemma.dart' show Message;

class GemmaService {
  InferenceModel? _inferenceModel;
  InferenceChat? _chat;

  bool get isModelInitialized => _inferenceModel != null && _chat != null;

  Future<void> initializeModel({
    required Function(String) onStatusUpdate,
    required Function(double?) onProgressUpdate,
  }) async {
    try {
      final gemma = FlutterGemmaPlugin.instance;
      
      // Check for storage permission
      if (await Permission.manageExternalStorage.request().isDenied) {
        throw Exception("Storage permission denied");
      }

      onStatusUpdate('Initializing model...');
      onProgressUpdate(null);

      final modelManager = gemma.modelManager;
      // Set the model path - assuming the model is downloaded to Downloads folder
      await modelManager.setModelPath(
        '/storage/emulated/0/Download/gemma-3n-E2B-it-int4.task',
      );

      _inferenceModel = await gemma.createModel(
        modelType: ModelType.gemmaIt,
        maxTokens: 2048,
        preferredBackend: PreferredBackend.gpu,
      );

      _chat = await _inferenceModel!.createChat(supportImage: false);

      debugPrint("Gemma model initialized successfully");
    } catch (e) {
      debugPrint("Error initializing Gemma model: $e");
      rethrow;
    }
  }

  Future<void> addMessageToChat(Message message) async {
    if (_chat == null) {
      throw Exception("Chat not initialized. Call initializeModel first.");
    }
    await _chat!.addQueryChunk(message);
  }

  Stream<String> generateResponse() {
    if (_chat == null) {
      throw Exception("Chat not initialized. Call initializeModel first.");
    }
    return _chat!.generateChatResponseAsync();
  }

  void dispose() {
    // Clean up resources if needed
    _inferenceModel = null;
    _chat = null;
  }
}
