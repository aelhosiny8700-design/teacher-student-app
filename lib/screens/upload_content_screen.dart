import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_model.dart';
import '../models/content_model.dart';
import '../services/cloudinary_service.dart';
import '../services/firestore_service.dart';

class UploadContentScreen extends StatefulWidget {
  final AppUser user;
  const UploadContentScreen({super.key, required this.user});

  @override
  State<UploadContentScreen> createState() => _UploadContentScreenState();
}

class _UploadContentScreenState extends State<UploadContentScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  File? _pickedFile;
  String _type = 'file'; // file, image, video
  String _stage = EduStage.all.first; // المرحلة الدراسية المختارة
  bool _uploading = false;
  String? _error;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      setState(() {
        _pickedFile = File(result.files.single.path!);
        _type = 'file';
      });
    }
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _pickedFile = File(picked.path);
        _type = 'image';
      });
    }
  }

  Future<void> _pickVideo() async {
    final picked = await ImagePicker().pickVideo(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _pickedFile = File(picked.path);
        _type = 'video';
      });
    }
  }

  Future<void> _upload() async {
    if (_pickedFile == null) {
      setState(() => _error = 'اختار ملف الأول');
      return;
    }
    if (_titleController.text.trim().isEmpty) {
      setState(() => _error = 'اكتب عنوان للمحتوى');
      return;
    }

    setState(() {
      _uploading = true;
      _error = null;
    });

    final resourceType = _type == 'image'
        ? 'image'
        : _type == 'video'
            ? 'video'
            : 'raw';

    final url = await CloudinaryService.uploadFile(
      _pickedFile!,
      resourceType: resourceType,
    );

    if (url == null) {
      setState(() {
        _uploading = false;
        _error = 'حصل خطأ في الرفع, حاول تاني';
      });
      return;
    }

    final item = ContentItem(
      id: '',
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      type: _type,
      url: url,
      uploadedBy: widget.user.name,
      teacherId: widget.user.uid,
      stage: _stage,
      createdAt: DateTime.now(),
    );

    await FirestoreService().addContent(item);

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('رفع محتوى جديد'),
        backgroundColor: const Color(0xFF2E5AAC),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'عنوان المحتوى',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'وصف مختصر (اختياري)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _stage,
              decoration: const InputDecoration(
                labelText: 'المرحلة الدراسية',
                border: OutlineInputBorder(),
              ),
              items: EduStage.all
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _stage = value);
              },
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickFile,
                    icon: const Icon(Icons.insert_drive_file),
                    label: const Text('ملف'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.image),
                    label: const Text('صورة'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickVideo,
                    icon: const Icon(Icons.videocam),
                    label: const Text('فيديو'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_pickedFile != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_pickedFile!.path.split('/').last),
                    ),
                  ],
                ),
              ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _uploading ? null : _upload,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: const Color(0xFF2E5AAC),
              ),
              child: _uploading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('رفع المحتوى', style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}


