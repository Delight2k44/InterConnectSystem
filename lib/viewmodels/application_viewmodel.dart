import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/application_model.dart';

class ApplicationViewModel extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  bool _isSubmitting = false;
  bool _isDeleting = false;
  String? _errorMessage;
  String? _successMessage;
  double _uploadProgress = 0.0;

  // ─── Getters ───
  bool get isSubmitting => _isSubmitting;
  bool get isDeleting => _isDeleting;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  double get uploadProgress => _uploadProgress;
  bool get hasError => _errorMessage != null;

  // ─── State Management ───

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  void _setSubmitting(bool value) {
    _isSubmitting = value;
    notifyListeners();
  }

  // _setError/_setSuccess already exist above

  void _setUploadProgress(double value) {
    _uploadProgress = value.clamp(0.0, 1.0);
    notifyListeners();
  }

  // ─── Validation ───

  String? validateApplication({
    required String year,
    required List<String> selectedModules,
    PlatformFile? file,
  }) {
    if (year.isEmpty) return 'Please select a year of study';
    if (selectedModules.isEmpty) return 'Please select at least one module';
    if (selectedModules.length > 6) return 'Maximum 6 modules allowed';

    if (file != null) {
      final ext = file.name.split('.').last.toLowerCase();
      final validExts = ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'];
      if (!validExts.contains(ext)) {
        return 'Invalid file format. Use PDF, DOC, or image';
      }

      final size = file.size;
      if (size > 10 * 1024 * 1024) return 'File too large. Maximum 10MB allowed';

      // On web, bytes are required for upload.
      if (file.bytes == null) {
        return 'File bytes missing (web upload requires bytes). Please re-select the file.';
      }
    }

    return null;
  }

  // ─── Submission ───

  /// Handles uploading the supporting document to Supabase Storage and
  /// creating the application record in the `applications` table.
  Future<bool> submitApplication({
    required String year,
    required List<String> selectedModules,
    PlatformFile? file,
  }) async {
    // Clear previous state
    clearMessages();

    // Validate inputs
    final validationError = validateApplication(
      year: year,
      selectedModules: selectedModules,
      file: file,
    );
    if (validationError != null) {
      _setError(validationError);
      return false;
    }

    _setSubmitting(true);
    _setUploadProgress(0.0);

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        _setError('You must be logged in to submit an application');
        _setSubmitting(false);
        return false;
      }

      String? fileUrl;
      String? fileName;

      // Requirement 3 & 118: Upload supporting documentation to Supabase Storage
      if (file != null) {
        final ext = file.name.split('.').last.toLowerCase();
        fileName = '${user.id}_${DateTime.now().millisecondsSinceEpoch}.$ext';

        // Supabase doesn't support stream upload progress yet.
        _setUploadProgress(0.3);

        final bytes = file.bytes;
        if (bytes == null) {
          _setError('File bytes missing. Please re-select the file.');
          _setSubmitting(false);
          return false;
        }

        // Use uploadBinary for web support (file.path can be null)
        await _supabase.storage.from('docs').uploadBinary(
          fileName,
          bytes,
          fileOptions: const FileOptions(upsert: true),
        );


        _setUploadProgress(0.8);

        fileUrl = _supabase.storage.from('docs').getPublicUrl(fileName);

        _setUploadProgress(1.0);
      }

      final app = StudentApplication(
        userId: user.id,
        yearOfStudy: year,
        modules: selectedModules,
        status: 'pending',
      documentPath: fileUrl ?? '',

        createdAt: DateTime.now(),
      );

      // Requirement 1.3: Save record to Database
      await _supabase.from('applications').insert(app.toInsertMap());

      _setSuccess('Application submitted successfully!');
      _setSubmitting(false);
      return true;
    } on StorageException catch (e) {
      debugPrint('Storage Error: ${e.message}');
      _setError('File upload failed: ${e.message}');
      _setSubmitting(false);
      return false;
    } on PostgrestException catch (e) {
      debugPrint('Database Error: ${e.message}');
      _setError('Failed to save application: ${e.message}');
      _setSubmitting(false);
      return false;
    } catch (e, stackTrace) {
      debugPrint('Submission Error: $e');
      debugPrint(stackTrace.toString());
      _setError('An unexpected error occurred. Please try again.');
      _setSubmitting(false);
      return false;
    }
  }

  // ─── Editing & Deleting Records ───

  // ─── State Helpers ───

  void _setDeleting(bool value) {
    _isDeleting = value;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    _successMessage = null;
    notifyListeners();
  }

  void _setSuccess(String message) {
    _successMessage = message;
    _errorMessage = null;
    notifyListeners();
  }

  // ─── Validation ───

  /// Validate that application can be edited (only pending apps)
  String? validateEdit(StudentApplication app) {
    if (app.isApproved) return 'Approved applications cannot be edited';
    if (app.isRejected) return 'Rejected applications cannot be edited';
    if (!app.isPending) return 'Only pending applications can be edited';
    return null;
  }

  // ─── Requirement 1.4: Update Operation (Edit while pending) ───

  Future<bool> updateApplication(String appId, Map<String, dynamic> updates) async {
    clearMessages();

    // Guard: Validate inputs
    if (appId.isEmpty) {
      _setError('Invalid application ID');
      return false;
    }

    if (updates.isEmpty) {
      _setError('No changes to save');
      return false;
    }

    // Prevent status manipulation through updates
    final sanitizedUpdates = Map<String, dynamic>.from(updates);
    sanitizedUpdates.remove('status'); // Status changes require admin approval
    sanitizedUpdates.remove('user_id'); // Cannot change ownership
    sanitizedUpdates.remove('created_at'); // Cannot change creation date

    if (sanitizedUpdates.isEmpty) {
      _setError('No valid fields to update');
      return false;
    }

    _setSubmitting(true);

    try {
      // Requirement 1.4: Verify application is still pending before update
      final existing = await _supabase
          .from('applications')
          .select('status')
          .eq('id', appId)
          .single();

      if (existing['status'] != 'pending') {
        _setError('This application can no longer be edited');
        _setSubmitting(false);
        return false;
      }

      // Add updated timestamp
      sanitizedUpdates['updated_at'] = DateTime.now().toIso8601String();

      await _supabase.from('applications').update(sanitizedUpdates).eq('id', appId);

      _setSuccess('Application updated successfully');
      _setSubmitting(false);
      return true;
    } on PostgrestException catch (e) {
      debugPrint("Update Error: ${e.message}");
      _setError('Failed to update: ${e.message}');
      _setSubmitting(false);
      return false;
    } catch (e, stackTrace) {
      debugPrint("Update Error: $e");
      debugPrint(stackTrace.toString());
      _setError('An unexpected error occurred. Please try again.');
      _setSubmitting(false);
      return false;
    }
  }

  // ─── Requirement 1.4: Delete Operation (With confirmation) ───

  Future<bool> deleteApplication(String appId, {bool confirmed = false}) async {
    clearMessages();

    // Guard: Require explicit confirmation
    if (!confirmed) {
      _setError('Please confirm deletion');
      return false;
    }

    if (appId.isEmpty) {
      _setError('Invalid application ID');
      return false;
    }

    _setDeleting(true);

    try {
      // Verify ownership before deletion
      final user = _supabase.auth.currentUser;
      if (user == null) {
        _setError('You must be logged in');
        _setDeleting(false);
        return false;
      }

      // Check application exists and belongs to user
      final app = await _supabase
          .from('applications')
          .select('id, user_id, status, document_path')
          .eq('id', appId)
          .single();

      if (app['user_id'] != user.id) {
        _setError('You can only delete your own applications');
        _setDeleting(false);
        return false;
      }

      // Prevent deletion of approved applications
      if (app['status'] == 'approved') {
        _setError('Approved applications cannot be deleted');
        _setDeleting(false);
        return false;
      }

      // Delete associated document from storage if exists
      final docPath = app['document_path'] as String?;
      if (docPath != null && docPath.isNotEmpty) {
        try {
          final fileName = Uri.parse(docPath).pathSegments.last;
await _supabase.storage.from('docs').remove([fileName]);
        } catch (e) {
          debugPrint("Failed to delete document: $e");
          // Continue with deletion even if file removal fails
        }
      }

      // Delete from database
      await _supabase.from('applications').delete().eq('id', appId);

      _setSuccess('Application deleted successfully');
      _setDeleting(false);
      return true;
    } on PostgrestException catch (e) {
      debugPrint("Delete Error: ${e.message}");
      _setError('Failed to delete: ${e.message}');
      _setDeleting(false);
      return false;
    } catch (e, stackTrace) {
      debugPrint("Delete Error: $e");
      debugPrint(stackTrace.toString());
      _setError('An unexpected error occurred. Please try again.');
      _setDeleting(false);
      return false;
    }
  }

  // ─── Convenience: Full Application Update ───

  Future<bool> updateApplicationFull(StudentApplication app) async {
    final validationError = validateEdit(app);
    if (validationError != null) {
      _setError(validationError);
      return false;
    }

    return updateApplication(
      app.id!,
      app.toUpdateMap()..remove('id'), // Remove id from updates
    );
  }

  // ─── File Operations ───

  /// Delete uploaded document from storage.
  Future<bool> deleteDocument(String fileName) async {
    try {
await _supabase.storage.from('docs').remove([fileName]);
      return true;
    } catch (e) {
      debugPrint('Delete Error: $e');
      return false;
    }
  }

  /// Get public URL for a document.
  String? getDocumentUrl(String? fileName) {
    if (fileName == null || fileName.isEmpty) return null;
    try {
return _supabase.storage.from('docs').getPublicUrl(fileName);
    } catch (e) {
      debugPrint('URL Error: $e');
      return null;
    }
  }


  @override
  void dispose() {
    clearMessages();
    super.dispose();
  }
}

