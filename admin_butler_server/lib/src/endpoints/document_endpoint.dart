import "package:serverpod/serverpod.dart";
import "package:google_generative_ai/google_generative_ai.dart";
import "dart:convert";
import "dart:typed_data";
import "package:admin_butler_server/src/generated/protocol.dart";

class DocumentEndpoint extends Endpoint {
  // Store documents in memory (for hackathon demo if DB is not available)
  final List<Document> _documents = [];

  Future<String> hello(Session session, String name) async {
    return "Hello $name from AdminButler!";
  }

  Future<Document> scanDocument(Session session, String imageBase64) async {
    try {
      final imageBytes = base64Decode(imageBase64);
      final fileName = "scan_${DateTime.now().millisecondsSinceEpoch}.jpg";
      
      // Get Gemini API key
      final geminiApiKey = session.passwords["geminiApiKey"];
      if (geminiApiKey == null) {
        throw Exception("Gemini API key not configured");
      }

      final model = GenerativeModel(
        model: "gemini-3-pro-image-preview",
        apiKey: geminiApiKey,
      );

      final prompt = '''
Extract the following information from this document image:
- summary: a 1-sentence summary of what the document is
- dueDate: the due date if found (format: YYYY-MM-DD), otherwise null
- amount: the total amount if found (number), otherwise null
- category: one of [bill, receipt, letter, other]
- draft: a professional 2-3 sentence draft response or action recommendation based on the document.

Return ONLY a JSON object.
''';

      // 1. Save to Serverpod File Storage
      String? fileUrl;
      try {
        await session.storage.storeFile(
          storageId: 'public',
          path: 'documents/$fileName',
          byteData: ByteData.view(imageBytes.buffer),
        );
        final publicUrl = await session.storage.getPublicUrl(
          storageId: 'public',
          path: 'documents/$fileName',
        );
        fileUrl = publicUrl?.toString();
      } catch (e) {
        session.log("Storage failed: $e", level: LogLevel.warning);
      }

      // 2. Call Gemini
      final response = await model.generateContent([
        Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', imageBytes),
        ]),
      ]);

      final text = response.text;
      if (text == null) throw Exception("No response from Gemini");

      // 3. Parse JSON
      Map<String, dynamic> data = {};
      try {
        final jsonStart = text.indexOf('{');
        final jsonEnd = text.lastIndexOf('}') + 1;
        if (jsonStart >= 0 && jsonEnd > jsonStart) {
          data = jsonDecode(text.substring(jsonStart, jsonEnd));
        }
      } catch (e) {
        session.log("Error parsing JSON: $e");
      }

      // 4. Create document
      final document = Document(
        fileName: fileName,
        fileUrl: fileUrl,
        summary: data['summary'] ?? text,
        dueDate: data['dueDate'] != null
            ? DateTime.tryParse(data['dueDate'])
            : null,
        amount: data['amount']?.toDouble(),
        category: data['category'] ?? "other",
        replyDraft: data['draft'],
        status: "processed",
        createdAt: DateTime.now().toUtc(),
        userId: 0,
      );

      // 5. Save to DB
      try {
        final inserted = await Document.db.insertRow(session, document);
        _documents.insert(0, inserted);
        return inserted;
      } catch (e) {
        session.log("Database insert failed: $e");
        _documents.insert(0, document);
        return document;
      }
    } catch (e) {
      session.log("Error scanning document: $e", level: LogLevel.error);
      return Document(
        fileName: "error.jpg",
        summary: "Error: $e",
        category: "error",
        status: "error",
        createdAt: DateTime.now().toUtc(),
        userId: 0,
      );
    }
  }

  Future<List<Document>> getDocuments(Session session) async {
    // Return combined or fallback
    try {
      final dbDocs = await Document.db.find(session);
      if (dbDocs.isNotEmpty) return dbDocs;
    } catch (e) {
      // Ignore DB errors in fallback mode
    }
    return _documents;
  }
}
