import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path/path.dart' as path;

class ScreenshotDetailScreen extends StatelessWidget {
  final Map<String, dynamic> screenshot;

  const ScreenshotDetailScreen({Key? key, required this.screenshot}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text('Screenshot Details'),
          actions: [
            IconButton(
              icon: Icon(Icons.share),
              onPressed: _shareScreenshot,
            ),
            IconButton(
              icon: Icon(Icons.copy),
              onPressed: _copyText,
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              _buildImageSection(),
              _buildActionButtons(),
              _buildDetectedTextCard(),
              _buildInfoCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Container(
      width: double.infinity,
      height: 400,
      child: Image.file(
        File(screenshot['path']),
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[300],
            child: Icon(Icons.broken_image, size: 100),
          );
        },
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _shareScreenshot,
              icon: Icon(Icons.share),
              label: Text('Share'),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _copyText,
              icon: Icon(Icons.copy),
              label: Text('Copy All Text'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetectedTextCard() {
    return Card(
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detected Text',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                screenshot['text_content'] ?? 'No text detected',
                style: TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    final file = File(screenshot['path']);
    final fileName = path.basename(file.path);
    
    return Card(
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Info',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            _buildInfoRow('File Name', fileName),
            _buildInfoRow('File Size', _getFileSize(file)),
            _buildInfoRow('Location', file.path),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(fontWeight: FontWeight.w500, color: Colors.grey[600]),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  String _getFileSize(File file) {
    try {
      final bytes = file.lengthSync();
      if (bytes < 1024) return '$bytes B';
      if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } catch (e) {
      return 'Unknown';
    }
  }

  void _shareScreenshot() {
    Share.shareXFiles([XFile(screenshot['path'])]);
  }

  void _copyText() {
    final text = screenshot['text_content'] ?? '';
    if (text.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: text));
      Get.snackbar('Copied', 'Text copied to clipboard');
    } else {
      Get.snackbar('No Text', 'No text available to copy');
    }
  }
}
