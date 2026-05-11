import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/application_viewmodel.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';

class ApplicationFormView extends StatefulWidget {
  const ApplicationFormView({super.key});

  @override
  State<ApplicationFormView> createState() => _ApplicationFormViewState();
}

class _ApplicationFormViewState extends State<ApplicationFormView> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedYear;
  final List<String> _availableModules = ['TPG316C', 'ITP216C', 'ISS316C', 'NWS216C'];
  final List<String> _selectedModules = [];
  File? _selectedFile;
  String? _fileName;

  void _toggleModule(String module) {
    setState(() {
      if (_selectedModules.contains(module)) {
        _selectedModules.remove(module);
      } else {
        // Requirement 1.3: Limit to no more than two modules
        if (_selectedModules.length < 2) {
          _selectedModules.add(module);
        } else {
          _showSnackBar("Maximum 2 modules allowed", isError: true);
        }
      }
    });
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final size = await file.length();

        if (size > 10 * 1024 * 1024) {
          _showSnackBar("File too large. Maximum 10MB allowed", isError: true);
          return;
        }

        setState(() {
          _selectedFile = file;
          _fileName = result.files.single.name;
        });
      }
    } catch (e) {
      _showSnackBar("Failed to pick file: $e", isError: true);
    }
  }

  void _removeFile() {
    setState(() {
      _selectedFile = null;
      _fileName = null;
    });
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.info_outline,
              color: isError ? Colors.red[100] : Colors.blue[100],
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red[800] : Colors.grey[900],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'DISMISS',
          textColor: Colors.white70,
          onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedModules.isEmpty) {
      _showSnackBar("Please select at least one module", isError: true);
      return;
    }

    final viewModel = context.read<ApplicationViewModel>();
    viewModel.clearMessages();

    final success = await viewModel.submitApplication(
      year: _selectedYear!,
      selectedModules: List.from(_selectedModules),
      file: _selectedFile,
    );

    if (success && mounted) {
      _showSnackBar("Application submitted successfully!");
      Navigator.pop(context);
    } else if (mounted && viewModel.errorMessage != null) {
      _showSnackBar(viewModel.errorMessage!, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ApplicationViewModel>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        title: const Text(
          "New Application",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: false,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Academic Information Section
            _buildSectionHeader(
              icon: Icons.school_outlined,
              title: "Academic Information",
              colorScheme: colorScheme,
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: DropdownButtonFormField<String>(
                  value: _selectedYear,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: "Current Year of Study",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                  icon: const Icon(Icons.keyboard_arrow_down),
                  items: ['1st Year', '2nd Year', '3rd Year'].map((y) =>
                      DropdownMenuItem(
                        value: y,
                        child: Text(y, style: const TextStyle(fontSize: 16)),
                      )
                  ).toList(),
                  onChanged: (val) => setState(() => _selectedYear = val),
                  validator: (val) => val == null ? "Please select your year of study" : null,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Module Selection Section
            _buildSectionHeader(
              icon: Icons.book_outlined,
              title: "Select Modules",
              subtitle: "Maximum 2 modules allowed",
              colorScheme: colorScheme,
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: _availableModules.map((module) {
                    final isSelected = _selectedModules.contains(module);
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: isSelected ? colorScheme.primaryContainer.withOpacity(0.3) : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: isSelected
                            ? Border.all(color: colorScheme.primary.withOpacity(0.3))
                            : null,
                      ),
                      child: CheckboxListTile(
                        title: Text(
                          module,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                          ),
                        ),
                        subtitle: Text(
                          isSelected ? "Selected" : "Tap to select",
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isSelected ? colorScheme.primary : colorScheme.outline,
                          ),
                        ),
                        value: isSelected,
                        activeColor: colorScheme.primary,
                        checkColor: colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        onChanged: (_) => _toggleModule(module),
                        secondary: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? colorScheme.primaryContainer
                                : colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            isSelected ? Icons.check : Icons.code,
                            color: isSelected ? colorScheme.primary : colorScheme.outline,
                            size: 20,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            // Validation hint
            if (_selectedModules.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12, left: 4),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: colorScheme.outline),
                    const SizedBox(width: 8),
                    Text(
                      "Select up to 2 modules",
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.outline,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(top: 12, left: 4),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, size: 16, color: colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      "${_selectedModules.length} of 2 modules selected",
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 32),

            // Document Upload Section
            _buildSectionHeader(
              icon: Icons.upload_file_outlined,
              title: "Supporting Documents",
              subtitle: "Optional - PDF, DOC, or images up to 10MB",
              colorScheme: colorScheme,
            ),
            const SizedBox(height: 16),
            _buildFileUploadCard(colorScheme, theme),
            const SizedBox(height: 40),

            // Submit Button
            if (viewModel.isSubmitting) ...[
              LinearProgressIndicator(
                value: viewModel.uploadProgress > 0 ? viewModel.uploadProgress : null,
                backgroundColor: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 16),
              Text(
                viewModel.uploadProgress > 0
                    ? "Uploading... ${(viewModel.uploadProgress * 100).toInt()}%"
                    : "Submitting application...",
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
            ],
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: viewModel.isSubmitting ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: viewModel.isSubmitting
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.onPrimary),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            "Submitting...",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ],
                      )
                    : const Text(
                        "Submit Application",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    String? subtitle,
    required ColorScheme colorScheme,
  }) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: colorScheme.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFileUploadCard(ColorScheme colorScheme, ThemeData theme) {
    if (_selectedFile != null) {
      return Card(
        elevation: 0,
        color: colorScheme.primaryContainer.withOpacity(0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colorScheme.primary.withOpacity(0.3)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.insert_drive_file, color: colorScheme.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _fileName ?? "Document",
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Ready to upload",
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _removeFile,
                icon: Icon(Icons.close, color: colorScheme.error),
                tooltip: "Remove file",
              ),
            ],
          ),
        ),
      );
    }

    return InkWell(
      onTap: _pickFile,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: colorScheme.outlineVariant,
            style: BorderStyle.solid,
          ),
        ),
        child: Container(
          height: 120,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.cloud_upload_outlined,
                  color: colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Tap to upload document",
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "PDF, DOC, JPG up to 10MB",
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

