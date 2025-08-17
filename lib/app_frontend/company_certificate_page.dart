import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'models/company_certificate.dart';
import 'services/profile_service.dart';

class CompanyCertificatePage extends StatefulWidget {
  final int employerId;
  const CompanyCertificatePage({Key? key, required this.employerId})
      : super(key: key);

  @override
  State<CompanyCertificatePage> createState() => _CompanyCertificatePageState();
}

class _CompanyCertificatePageState extends State<CompanyCertificatePage> {
  final _descController = TextEditingController();
  File? _selectedFile;
  bool _isUploading = false;
  String? _uploadError;
  List<CompanyCertificate> _certificates = [];
  bool _loading = true;
  final _service = CompanyCertificateService();

  // Colors
  final Color bgColor = const Color(0xFFEBF1FE);
  final Color cardColor = const Color(0xFFCFDFFE);
  final Color blue = const Color(0xFF0044CC);
  final Color green = const Color(0xFF33CC33);
  final Color red = const Color(0xFFDF0101);

  @override
  void initState() {
    super.initState();
    _fetchCertificates();
  }

  Future<void> _fetchCertificates() async {
    setState(() => _loading = true);
    try {
      final certs = await _service.fetchCertificates(widget.employerId);
      setState(() {
        _certificates = certs;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _pickFile() async {
    setState(() => _uploadError = null);
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true,
    );
    if (result != null && result.files.single.bytes != null) {
      final file = File(result.files.single.path!);
      if (await file.length() > 4 * 1024 * 1024) {
        setState(() => _uploadError = 'File size exceeds 4MB.');
        return;
      }
      setState(() => _selectedFile = file);
    }
  }

  Future<void> _uploadCertificate() async {
    if (_selectedFile == null || _descController.text.isEmpty) {
      setState(
          () => _uploadError = 'Please select a file and enter a description.');
      return;
    }
    setState(() {
      _isUploading = true;
      _uploadError = null;
    });
    try {
      await _service.uploadCertificate(
        employerId: widget.employerId,
        file: _selectedFile!,
        description: _descController.text,
      );
      setState(() {
        _selectedFile = null;
        _descController.clear();
      });
      await _fetchCertificates();
    } catch (e) {
      setState(() => _uploadError = e.toString());
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _deleteCertificate(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Certificate'),
        content:
            const Text('Are you sure you want to delete this certificate?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Delete', style: TextStyle(color: red))),
        ],
      ),
    );
    if (confirm == true) {
      await _service.deleteCertificate(id);
      await _fetchCertificates();
    }
  }

  void _viewCertificate(String url) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: Container(
          width: 350,
          height: 500,
          color: Colors.white,
          child: url.endsWith('.pdf')
              ? const Center(
                  child: Text('PDF preview not supported in this demo.'))
              : Image.network(url, fit: BoxFit.contain),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0044CC),
        elevation: 0,
        title: const Text('Company Certificates',
            style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: blue, width: 1),
                ),
                child: Column(
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.info_outline, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Upload your business certificates and provide descriptions for each document',
                            style:
                                TextStyle(fontSize: 15, color: Colors.black87),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: green,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: blue, width: 1),
                        ),
                      ),
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Upload Certificate',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: _isUploading ? null : _pickFile,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _descController,
                      decoration: const InputDecoration(
                        hintText: 'Enter certificate description',
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                    if (_selectedFile != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                            'Selected: ${_selectedFile!.path.split('/').last}'),
                      ),
                    if (_uploadError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child:
                            Text(_uploadError!, style: TextStyle(color: red)),
                      ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: blue,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(40),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: _isUploading ? null : _uploadCertificate,
                        child: _isUploading
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Text('Submit'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (_loading)
                const Center(child: CircularProgressIndicator())
              else if (_certificates.isEmpty)
                const Center(child: Text('No certificates uploaded yet.'))
              else
                Column(
                  children: _certificates
                      .map((cert) => Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: blue, width: 1),
                            ),
                            child: ListTile(
                              leading: Icon(Icons.insert_drive_file,
                                  color: green, size: 32),
                              title: Text(cert.certificateUrl.split('/').last,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              subtitle: Text(cert.description),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon:
                                        Icon(Icons.remove_red_eye, color: blue),
                                    onPressed: () =>
                                        _viewCertificate(cert.certificateUrl),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete, color: red),
                                    onPressed: () =>
                                        _deleteCertificate(cert.id),
                                  ),
                                ],
                              ),
                            ),
                          ))
                      .toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
