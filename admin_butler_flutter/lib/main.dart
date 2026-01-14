import 'dart:convert';
import 'package:admin_butler_client/admin_butler_client.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:serverpod_flutter/serverpod_flutter.dart';

// Sets up a global client object that can be used to talk to the server from
// anywhere in our app.
late final Client client;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // The server URL is fetched from the `assets/config.json` file or
  // defaults to http://10.0.2.2:8080/ if not found (on Android emulator).
  final serverUrl = await getServerUrl();

  client = Client(serverUrl)
    ..connectivityMonitor = FlutterConnectivityMonitor();

  runApp(const AdminButlerApp());
}

class AdminButlerApp extends StatelessWidget {
  const AdminButlerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AdminButler',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const DashboardPage(),
    );
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  List<Document> _documents = [];
  bool _isLoading = false;
  String _butlerStatus = "At your service, sir.";
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _refreshDocuments();
  }

  Future<void> _refreshDocuments() async {
    setState(() => _isLoading = true);
    try {
      final documents = await client.document.getDocuments();
      setState(() {
        _documents = documents;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching documents: $e");
      setState(() {
        _isLoading = false;
        _butlerStatus = "Apologies, I couldn't reach the archives.";
      });
    }
  }

  Future<void> _scanDocument() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (image == null) return;

    setState(() {
      _isLoading = true;
      _butlerStatus = "Analyzing document, please wait...";
    });

    try {
      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);

      final result = await client.document.scanDocument(base64Image);

      setState(() {
        _documents.insert(0, result);
        _butlerStatus = "Document processed successfully.";
      });
      
      // Reset status after a few seconds
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) setState(() => _butlerStatus = "At your service, sir.");
      });
    } catch (e) {
      debugPrint("Error scanning document: $e");
      setState(() {
        _butlerStatus = "Something went wrong during analysis.";
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "AdminButler",
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _refreshDocuments,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          ),
        ),
        child: Column(
          children: [
            _buildButlerHeader(),
            Expanded(
              child: _isLoading && _documents.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : _documents.isEmpty
                      ? _buildEmptyState()
                      : _buildDocumentList(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _scanDocument,
        label: const Text("Scan Document"),
        icon: const Icon(Icons.camera_alt_rounded),
        backgroundColor: const Color(0xFF6366F1),
      ),
    );
  }

  Widget _buildButlerHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Color(0xFF6366F1),
            radius: 28,
            child: Icon(Icons.person, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Butler George",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  _butlerStatus,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 80, color: Colors.white.withOpacity(0.2)),
          const SizedBox(height: 16),
          Text(
            "No documents yet.",
            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 18),
          ),
          const SizedBox(height: 8),
          const Text("Try scanning a bill or receipt."),
        ],
      ),
    );
  }

  Widget _buildDocumentList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
      itemCount: _documents.length,
      itemBuilder: (context, index) {
        final doc = _documents[index];
        return _buildDocumentCard(doc);
      },
    );
  }

  Widget _buildDocumentCard(Document doc) {
    final bool isError = doc.status == "error";
    final Color categoryColor = _getCategoryColor(doc.category);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: categoryColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: categoryColor.withOpacity(0.5)),
                  ),
                  child: Text(
                    doc.category.toUpperCase(),
                    style: TextStyle(color: categoryColor, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
                const Spacer(),
                Text(
                  DateFormat('MMM dd, yyyy').format(doc.createdAt),
                  style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              doc.summary,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            if (doc.amount != null || doc.dueDate != null)
              Row(
                children: [
                  if (doc.amount != null)
                    _buildInfoChip(Icons.attach_money, "\${doc.amount!.toStringAsFixed(2)}", Colors.green),
                  if (doc.dueDate != null)
                    _buildInfoChip(
                      Icons.calendar_today,
                      "Due: \${DateFormat('MMM dd').format(doc.dueDate!)}",
                      Colors.amber,
                    ),
                ],
              ),
            if (isError)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  "Processing Failed",
                  style: TextStyle(color: Colors.redAccent, fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13)),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'bill':
        return Colors.redAccent;
      case 'receipt':
        return Colors.greenAccent;
      case 'letter':
        return Colors.blueAccent;
      default:
        return Colors.purpleAccent;
    }
  }
}
