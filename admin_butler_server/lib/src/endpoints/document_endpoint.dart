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
      
      // 1. Save to Serverpod File Storage (Immediate)
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

      // 2. Create Initial "Processing" Document
      final document = Document(
        fileName: fileName,
        fileUrl: fileUrl,
        summary: "Butler George is analyzing this for you, sir...",
        category: "pending",
        status: "processing",
        createdAt: DateTime.now().toUtc(),
        userId: 0,
      );

      // Save to DB
      final inserted = await Document.db.insertRow(session, document);
      
      // 3. Schedule Background Analysis (Asynchronous)
      // This will call DocumentAnalysisCall.invoke in the background
      await session.serverpod.futureCallWithDelay(
        'documentAnalysisCall',
        inserted,
        const Duration(milliseconds: 100),
      );

      // 4. Return immediately to the client
      _documents.insert(0, inserted);
      return inserted;
    } catch (e) {
      session.log("Error starting scan: $e", level: LogLevel.error);
      return Document(
        fileName: "error.jpg",
        summary: "Error starting scan: $e",
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
