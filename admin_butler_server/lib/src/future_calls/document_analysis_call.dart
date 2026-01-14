import 'dart:convert';
import 'package:serverpod/serverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'protocol.dart';

class DocumentAnalysisCall extends FutureCall<Document> {
  @override
  Future<void> invoke(Session session, Document? document) async {
    if (document == null || document.id == null) return;

    try {
      session.log("Starting background analysis for document: ${document.id}");
      
      final geminiApiKey = session.passwords["geminiApiKey"];
      if (geminiApiKey == null) throw Exception("Gemini API key missing");

      final model = GenerativeModel(
        model: "gemini-3-pro-image-preview",
        apiKey: geminiApiKey,
      );

      // Download file from storage
      final fileUri = Uri.parse(document.fileUrl!);
      // Note: In a real production app we'd fetch the bytes from storage. 
      // For the demo, we assume the fileUrl is accessible or we use the session.storage.
      
      final byteData = await session.storage.retrieveFile(
        storageId: 'public',
        path: 'documents/${document.fileName}',
      );

      if (byteData == null) throw Exception("Could not retrieve file from storage");

      final prompt = '''
Analyze this document and extract:
- summary: a 1-sentence summary of what the document is
- dueDate: the due date if found (format: YYYY-MM-DD), otherwise null
- amount: the total amount if found (number), otherwise null
- category: one of [bill, receipt, letter, other]
- draft: a professional 2-3 sentence draft response or action recommendation based on the document.

Return ONLY a JSON object.
''';

      final response = await model.generateContent([
        Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', byteData.buffer.asUint8List()),
        ]),
      ]);

      final text = response.text;
      if (text == null) throw Exception("No response from Gemini");

      // Simple JSON parsing
      Map<String, dynamic> data = {};
      final jsonStart = text.indexOf('{');
      final jsonEnd = text.lastIndexOf('}') + 1;
      if (jsonStart >= 0 && jsonEnd > jsonStart) {
        data = jsonDecode(text.substring(jsonStart, jsonEnd));
      }

      // Update document with results
      final updatedDocument = document.copyWith(
        summary: data['summary'] ?? text,
        dueDate: data['dueDate'] != null ? DateTime.tryParse(data['dueDate']) : null,
        amount: data['amount']?.toDouble(),
        category: data['category'] ?? "other",
        replyDraft: data['draft'],
        status: "processed",
      );

      await Document.db.updateRow(session, updatedDocument);
      
      session.log("Background analysis complete for document: ${document.id}");
      
    } catch (e) {
      session.log("Analysis failed for document ${document.id}: $e", level: LogLevel.error);
      final errorDocument = document.copyWith(
        status: "error",
        summary: "Analysis failed: $e",
      );
      await Document.db.updateRow(session, errorDocument);
    }
  }
}
