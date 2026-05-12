import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../viewmodels/application_viewmodel.dart';
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
  PlatformFile? _selectedFile;
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

      if (result != null) {
        final platformFile = result.files.single;

        final bytesLength = platformFile.bytes?.length;
        if (bytesLength != null && bytesLength > 10 * 1024 * 1024) {
          _showSnackBar("File too large. Maximum 10MB allowed", isError: true);
          return;
        }

        setState(() {
          _selectedFile = platformFile;
          _fileName = platformFile.name;
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

  // ============================================
  // ENHANCED SUCCESS DIALOG
  // ============================================
  void _showEnhancedSuccessDialog(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withOpacity(0.6),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, animation, secondaryAnimation) {
        return const SizedBox.shrink();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: animation, curve: Curves.elasticOut),
          child: FadeTransition(
            opacity: animation,
            child: const _SuccessDialogContent(),
          ),
        );
      },
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
      _showEnhancedSuccessDialog(context);
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
                  initialValue: _selectedYear,
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
                  items: ['1st Year', '2nd Year', '3rd Year']
                      .map((y) => DropdownMenuItem(
                            value: y,
                            child: Text(y, style: const TextStyle(fontSize: 16)),
                          ))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedYear = val),
                  validator: (val) => val == null ? "Please select your year of study" : null,
                ),
              ),
            ),
            const SizedBox(height: 32),

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

            _buildSectionHeader(
              icon: Icons.upload_file_outlined,
              title: "Supporting Documents",
              subtitle: "Optional - PDF, DOC, or images up to 10MB",
              colorScheme: colorScheme,
            ),
            const SizedBox(height: 16),
            _buildFileUploadCard(colorScheme, theme),
            const SizedBox(height: 40),

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
                style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
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
                      style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.primary),
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
                style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SuccessDialogContent extends StatelessWidget {
  const _SuccessDialogContent();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.2),
              blurRadius: 40,
              spreadRadius: 0,
              offset: const Offset(0, 16),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              spreadRadius: -5,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTopDecoration(),
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
                child: Column(
                  children: [
                    const SizedBox(height: 32),
                    _buildAnimatedIcon(),
                    const SizedBox(height: 28),
                    _buildTitle(theme),
                    const SizedBox(height: 12),
                    _buildSubtitle(theme),
                    const SizedBox(height: 32),
                    _buildPrimaryButton(context, colorScheme),
                    const SizedBox(height: 12),
                    _buildSecondaryButton(context),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopDecoration() {
    return Container(
      height: 8,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green.shade400,
            Colors.green.shade600,
          ],
        ),
      ),
    ).animate().scaleX(

          duration: 600.ms,
          curve: Curves.easeOutExpo,
          alignment: Alignment.centerLeft,
        );
  }

  Widget _buildAnimatedIcon() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.green.shade200,
          width: 2,
        ),
      ),
      child: Icon(
        Icons.check_circle_rounded,
        color: Colors.green.shade600,
        size: 72,
      ),
    )
        .animate()
        .scale(duration: 500.ms, curve: Curves.elasticOut)
        .then()
        .shimmer(duration: 1200.ms, color: Colors.white.withOpacity(0.3));
  }

  Widget _buildTitle(ThemeData theme) {
    return Text(
      "Application Submitted!",
      textAlign: TextAlign.center,
      style: theme.textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w800,
        color: theme.colorScheme.onSurface,
        letterSpacing: -0.5,
        height: 1.2,
      ),
    )
        .animate()
        .fadeIn(delay: 200.ms)
        .slideY(begin: 0.3, end: 0, curve: Curves.easeOutQuad);
  }

  Widget _buildSubtitle(ThemeData theme) {
    return Text(
      "Your documents have been uploaded successfully. Track your application status anytime from your dashboard.",
      textAlign: TextAlign.center,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        height: 1.5,
      ),
    )
        .animate()
        .fadeIn(delay: 300.ms)
        .slideY(begin: 0.2, end: 0, curve: Curves.easeOutQuad);
  }

  Widget _buildPrimaryButton(BuildContext context, ColorScheme colorScheme) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          // Haptic feedback is optional; keep dialog logic working even if not supported.
          // HapticFeedback.mediumImpact();
          Navigator.of(context).pop();
          Navigator.pushReplacementNamed(context, '/home');
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green.shade600,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          elevation: 0,
          shadowColor: Colors.green.withOpacity(0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ).copyWith(
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return Colors.white.withOpacity(0.15);
            }
            return null;
          }),
        ),
        icon: const Icon(Icons.home_rounded, size: 20),
        label: const Text(
          "Back to Home",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.3),
        ),
      )
          .animate()
          .fadeIn(delay: 400.ms)
          .slideY(begin: 0.2, end: 0, curve: Curves.easeOutQuad),
    );
  }

  Widget _buildSecondaryButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: () {
          // HapticFeedback.lightImpact();
          Navigator.of(context).pop();
          Navigator.pushNamed(context, '/dashboard');
        },
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(
          "View Dashboard",
          style: TextStyle(
            color: Colors.green.shade700,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      )
          .animate()
          .fadeIn(delay: 500.ms),
    );
  }
}

