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

    final result = await CloudinaryService.uploadFile(
      _pickedFile!,
      resourceType: resourceType,
    );

    if (!result.isSuccess) {
      setState(() {
        _uploading = false;
        _error = result.errorMessage ?? 'حصل خطأ في الرفع, حاول تاني';
      });
      return;
    }

    final item = ContentItem(
      id: '',
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      type: _type,
      url: result.url!,
      uploadedBy: widget.user.name,
      teacherId: widget.user.uid,
      stage: _stage,
      createdAt: DateTime.now(),
    );

    try {
      await FirestoreService().addContent(item);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() {
          _uploading = false;
          _error = 'اترفع الملف لكن حصل خطأ في حفظ البيانات: $e';
        });
      }
    }
}
