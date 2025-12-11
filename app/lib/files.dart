import 'package:app/api/account.dart';
import 'package:app/api/application.dart';
import 'package:app/api/files.dart';
import 'package:app/api/types.dart';
import 'package:app/util/loadable.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:app/util/url.dart';
import 'package:pdfx/pdfx.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Main widget
class Files extends StatefulWidget {
  final bool isReadOnly;
  final String? clientEmail;
  const Files({
    super.key,
    this.isReadOnly = false,
    this.clientEmail,
  });

  @override
  State<Files> createState() => _FilesState();
}

class _FilesState extends State<Files> {
  List<FileResponse> _uploadedFiles = [];
  bool _isLoading = false;
  bool _isUploading = false;
  bool _apiUrlReady = false;
  String? _error;
  late String
      _apiUrl; // assigned asynchronously after startup, meaning later, it's needed to suppress a warning

  final _expandedSections = {
    'id': false,
    'proof_income': false,
    'ssn': false,
    'statements': false,
  };

  @override
  void initState() {
    super.initState();
    _init();
  }

  // Initialize API URL and fetch uploaded files
  Future<void> _init() async {
    _apiUrl = await getApiUrl();
    setState(() => _apiUrlReady = true);
    await _fetchFiles();
  }

  // Show a quick snack bar message
  void _showSnack(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  // Show an error dialog with a message
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }

  // Fetch uploaded files from server
  Future<void> _fetchFiles() async {
    setState(() => _isLoading = true);
    var files = await getFiles(widget.clientEmail);
    if (files == null) {
      if (mounted) setState(() => _error = "Failed to load files");
    } else {
      _uploadedFiles = files;
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Pick and upload a new file
  Future<void> _pickFile(String fileType) async {
    const int maxFileSize = 10 * 1024 * 1024;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      // TODO: Add more file types if needed
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      withData: true,
    );

    if (result == null || result.files.single.bytes == null) {
      _showSnack('File selection cancelled.');
      return;
    }

    final file = result.files.single;

    if (file.size > maxFileSize) {
      _showSnack('File too large. Maximum allowed is 10MB.');
      return;
    }

    // Handles file uploading via api
    setState(() => _isUploading = true);

    final res = await uploadFile(file, fileType, widget.clientEmail);
    if (res) {
      _showSnack('File uploaded successfully.');
      _fetchFiles(); // Refresh file list
      if (mounted) setState(() => _isUploading = false);
    } else {
      _showErrorDialog('Failed to upload file.');
    }
  }

  // Delete a file
  Future<void> _deleteFile(String id) async {
    final res = await deleteFile(id);
    if (!res) {
      _showErrorDialog('Failed to delete file.');
      return;
    }
    _showSnack('File deleted successfully.');
    _fetchFiles();
  }

  // Confirm dialog
  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete File?'),
        content: const Text('Are you sure you want to delete this file?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteFile(id);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // Open image viewer or PDF viewer
  void _openFile(FileResponse file) async {
    final mime = (file.mimeType).toLowerCase();
    final url = await getFileUrl(file.id);

    if (mounted) {
      if (mime.startsWith('image/')) {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => ImageViewerScreen(imageUrl: url)));
      } else if (mime == 'application/pdf') {
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => PdfViewerScreen(pdfUrl: url)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_apiUrlReady) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            if (_isUploading)
              const LinearProgressIndicator(), // Show upload progress
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator()) // Loading spinner
                  : _error != null
                      ? Center(
                          // Error view
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline,
                                  size: 60, color: Colors.redAccent),
                              const SizedBox(height: 10),
                              Text('Something went wrong.\n$_error',
                                  textAlign: TextAlign.center),
                            ],
                          ),
                        )
                      : ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            // Render each FileSection
                            FileSection(
                              title: 'Identification',
                              type: 'id',
                              icon: Icons.perm_identity,
                              files: _uploadedFiles,
                              expanded: _expandedSections['id'] ?? false,
                              onToggle: () => setState(() =>
                                  _expandedSections['id'] =
                                      !_expandedSections['id']!),
                              onPickFile: () => _pickFile('id'),
                              onDeleteFile: _confirmDelete,
                              onOpenFile: _openFile,
                              apiUrl: _apiUrl,
                              isReadOnly: widget.isReadOnly,
                            ),
                            FileSection(
                              title: 'Proof of Income',
                              type: 'proof_income',
                              icon: Icons.attach_money,
                              files: _uploadedFiles,
                              expanded:
                                  _expandedSections['proof_income'] ?? false,
                              onToggle: () => setState(() =>
                                  _expandedSections['proof_income'] =
                                      !_expandedSections['proof_income']!),
                              onPickFile: () => _pickFile('proof_income'),
                              onDeleteFile: _confirmDelete,
                              onOpenFile: _openFile,
                              apiUrl: _apiUrl,
                              isReadOnly: widget.isReadOnly,
                            ),
                            FileSection(
                              title: 'SSN',
                              type: 'ssn',
                              icon: Icons.security,
                              files: _uploadedFiles,
                              expanded: _expandedSections['ssn'] ?? false,
                              onToggle: () => setState(() =>
                                  _expandedSections['ssn'] =
                                      !_expandedSections['ssn']!),
                              onPickFile: () => _pickFile('ssn'),
                              onDeleteFile: _confirmDelete,
                              onOpenFile: _openFile,
                              apiUrl: _apiUrl,
                              isReadOnly: widget.isReadOnly,
                            ),
                            FileSection(
                              title: 'Statements',
                              type: 'statements',
                              icon: Icons.folder,
                              files: _uploadedFiles,
                              expanded:
                                  _expandedSections['statements'] ?? false,
                              onToggle: () => setState(() =>
                                  _expandedSections['statements'] =
                                      !_expandedSections['statements']!),
                              onPickFile: () => _pickFile('statements'),
                              onDeleteFile: _confirmDelete,
                              onOpenFile: _openFile,
                              apiUrl: _apiUrl,
                              isReadOnly: widget.isReadOnly,
                            ),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

// FileSection widget to display and manage file uploads. It includes a title, icon, and a list of files with options to upload, delete, and view files.
class FileSection extends StatelessWidget {
  final String title;
  final String type;
  final IconData icon;
  final List<FileResponse> files;
  final bool expanded;
  final VoidCallback onToggle;
  final VoidCallback onPickFile;
  final void Function(String id) onDeleteFile;
  final void Function(FileResponse file) onOpenFile;
  final String apiUrl;
  final bool isReadOnly;

  const FileSection({
    super.key,
    required this.title,
    required this.type,
    required this.icon,
    required this.files,
    required this.expanded,
    required this.onToggle,
    required this.onPickFile,
    required this.onDeleteFile,
    required this.onOpenFile,
    required this.apiUrl,
    required this.isReadOnly,
  });

  @override
  Widget build(BuildContext context) {
    final sectionFiles = files.where((f) => f.fileType == type).toList();

    return Card(
      color: const Color(0xFFF8F8F8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 5,
      child: Column(
        children: [
          ListTile(
            leading: Icon(icon, size: 32),
            title: Text('Upload $title',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            trailing: AnimatedRotation(
              turns: expanded ? 0.5 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: const Icon(Icons.expand_more),
            ),
            onTap: onToggle, // Expand or collapse
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(), // Collapsed state
            secondChild: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Column(
                children: [
                  if (!isReadOnly) ...[
                    ElevatedButton.icon(
                      onPressed: onPickFile,
                      icon: const Icon(Icons.upload, color: Colors.white),
                      label: const Text('Select File'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  sectionFiles.isEmpty
                      ? const Text('No files uploaded.',
                          style: TextStyle(fontSize: 14, color: Colors.black54))
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: sectionFiles.length,
                          itemBuilder: (_, i) => ListTile(
                            leading: SizedBox(
                              width: 80,
                              height: 80,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: _buildPreview(sectionFiles[i]),
                              ),
                            ),
                            title: Text(sectionFiles[i].fileName,
                                style: const TextStyle(fontSize: 16)),
                            trailing: !isReadOnly
                                ? IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () =>
                                        onDeleteFile(sectionFiles[i].id),
                                  )
                                : null,
                            onTap: () => onOpenFile(sectionFiles[i]),
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                ],
              ),
            ),
            crossFadeState:
                expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }

// Build a preview of the file based on its MIME type
  Widget _buildPreview(FileResponse file) {
    final mime = (file.mimeType).toLowerCase();

    if (mime == 'application/pdf') {
      return const Icon(Icons.picture_as_pdf, size: 50);
    }
    return const Icon(Icons.insert_drive_file, size: 50);
  }
}

void showFilesBottomSheet(
  BuildContext context,
  bool isReadOnly,
  String? clientEmail,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.95,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with close (X) button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Viewing Uploaded Files",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: Icon(Icons.close, size: 24),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Divider(height: 1),

          // Form content scrolls
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Files(
                          isReadOnly: isReadOnly,
                          clientEmail: clientEmail,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

// PDF viewer screen
class PdfViewerScreen extends StatefulWidget {
  final String pdfUrl;
  const PdfViewerScreen({super.key, required this.pdfUrl});

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  PdfControllerPinch? _pdfController;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  Future<void> _loadPdf() async {
    try {
      final response =
          await http.get(Uri.parse(widget.pdfUrl), headers: await authHeader());
      if (response.statusCode == 200) {
        final document = await PdfDocument.openData(response.bodyBytes);
        _pdfController = PdfControllerPinch(document: Future.value(document));
      } else {
        _hasError = true;
      }
    } catch (_) {
      _hasError = true;
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _pdfController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PDF Viewer')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasError || _pdfController == null
              ? const Center(child: Text('Failed to load PDF'))
              : PdfViewPinch(controller: _pdfController!),
    );
  }
}

// Image viewer screen
class ImageViewerScreen extends StatefulWidget {
  final String imageUrl;
  const ImageViewerScreen({super.key, required this.imageUrl});

  @override
  State<ImageViewerScreen> createState() => _ImageViewerScreenState();
}

class _ImageViewerScreenState extends State<ImageViewerScreen> {
  Map<String, String>? headers;

  @override
  void initState() {
    super.initState();

    Future(() async {
      headers = await authHeader();
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Image Viewer'),
        foregroundColor: Colors.white,
        backgroundColor: Colors.black,
      ),
      body: Center(
        child: Loadable(
          isLoading: headers == null,
          widgetBuilder: (context) => InteractiveViewer(
            child: Image.network(
              widget.imageUrl,
              headers: headers!,
            ),
          ),
        ),
      ),
    );
  }
}
