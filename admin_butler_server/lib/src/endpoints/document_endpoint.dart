import "package:serverpod/serverpod.dart";
import "package:google_generative_ai/google_generative_ai.dart";
import "dart:convert";
import "package:admin_butler_server/src/generated/protocol.dart";

class DocumentEndpoint extends Endpoint {
  // Store documents in memory (for hackathon demo if DB is not available)
  final List<Document> _documents = [];

  Future<String> hello(Session session, String name) async {
    return "Hello $name from AdminButler!";
  }

  Future<Document> scanDocument(Session session, String imageBase64) async {
    try {
      // Get Gemini API key from session
      final geminiApiKey = session.passwords["geminiApiKey"];
      if (geminiApiKey == null) {
        throw Exception(
          "Gemini API key not configured. Add it to config/passwords.yaml",
        );
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

Return ONLY a JSON object.
''';

      // Call Gemini API
      final response = await model.generateContent([
        Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', base64Decode(imageBase64)),
        ]),
      ]);

      final text = response.text;
      if (text == null) throw Exception("No response from Gemini");

      // Simple JSON parsing
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

      // Create document
      final document = Document(
        fileName: "scan_${DateTime.now().millisecondsSinceEpoch}.jpg",
        summary: data['summary'] ?? text,
        dueDate: data['dueDate'] != null
            ? DateTime.tryParse(data['dueDate'])
            : null,
        amount: data['amount']?.toDouble(),
        category: data['category'] ?? "other",
        status: "pending",
        createdAt: DateTime.now().toUtc(),
        userId: 0,
      );

      _documents.add(document);

      // Try to save to DB, but skip if it fails (for demo without DB)
      try {
        await Document.db.insertRow(session, document);
      } catch (e) {
        session.log("Database insert failed (using in-memory): $e");
      }

      return document;
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
