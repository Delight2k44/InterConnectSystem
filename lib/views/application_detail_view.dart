import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/application_model.dart';
import '../viewmodels/application_viewmodel.dart';

class ApplicationDetailView extends StatelessWidget {
  final StudentApplication application;

  const ApplicationDetailView({super.key, required this.application});

  void _confirmDelete(BuildContext context) {
    final viewModel = context.read<ApplicationViewModel>();
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: colorScheme.errorContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.delete_forever_outlined,
            color: colorScheme.error,
            size: 28,
          ),
        ),
        iconPadding: const EdgeInsets.only(top: 24, bottom: 16),
        title: const Text("Delete Application"),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
        content: const Text(
          "This action cannot be undone. The application and any uploaded documents will be permanently removed.",
          textAlign: TextAlign.center,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        actions: [
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(dialogContext),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Cancel"),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: viewModel.isDeleting
                  ? null
                  : () async {
                      final success = await viewModel.deleteApplication(
                        application.id!,
                        confirmed: true,
                      );
                      if (success && dialogContext.mounted) {
                        Navigator.pop(dialogContext);
                        if (context.mounted) {
                          Navigator.pop(context);
                        }
                      } else if (dialogContext.mounted && viewModel.errorMessage != null) {
                        Navigator.pop(dialogContext);
                        _showError(context, viewModel.errorMessage!);
                      }
                    },
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.error,
                foregroundColor: colorScheme.onError,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: viewModel.isDeleting
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(colorScheme.onError),
                      ),
                    )
                  : const Text("Delete", style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  void _showError(BuildContext context, String message) {
    final colorScheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: colorScheme.onErrorContainer),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: colorScheme.errorContainer,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Color _getStatusColor(ColorScheme colorScheme) {
    switch (application.status) {
      case 'approved':
        return colorScheme.tertiary;
      case 'rejected':
        return colorScheme.error;
      case 'pending':
      default:
        return colorScheme.primary;
    }
  }

  Color _getStatusContainerColor(ColorScheme colorScheme) {
    switch (application.status) {
      case 'approved':
        return colorScheme.tertiaryContainer;
      case 'rejected':
        return colorScheme.errorContainer;
      case 'pending':
      default:
        return colorScheme.primaryContainer;
    }
  }

  IconData _getStatusIcon() {
    switch (application.status) {
      case 'approved':
        return Icons.check_circle_rounded;
      case 'rejected':
        return Icons.cancel_rounded;
      case 'pending':
      default:
        return Icons.pending_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ApplicationViewModel>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final statusColor = _getStatusColor(colorScheme);
    final statusBg = _getStatusContainerColor(colorScheme);
    final isPending = application.isPending;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        title: const Text(
          "Application Details",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: false,
        actions: [
          if (isPending)
            IconButton(
              icon: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.delete_outline, color: colorScheme.error, size: 20),
              ),
              tooltip: "Delete application",
              onPressed: () => _confirmDelete(context),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Status Card
          Card(
            elevation: 0,
            color: statusBg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(_getStatusIcon(), color: statusColor, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          application.statusLabel,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: statusColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isPending
                              ? "Awaiting admin review"
                              : application.isApproved
                                  ? "Your application has been approved"
                                  : "Your application was not approved",
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: statusColor.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

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
              child: Column(
                children: [
                  _buildInfoRow(
                    icon: Icons.calendar_today_outlined,
                    label: "Year of Study",
                    value: application.yearOfStudy,
                    colorScheme: colorScheme,
                  ),
                  const Divider(height: 24),
                  _buildInfoRow(
                    icon: Icons.schedule_outlined,
                    label: "Submitted",
                    value: application.formattedDate,
                    colorScheme: colorScheme,
                  ),
                  if (application.hasDocument) ...[
                    const Divider(height: 24),
                    _buildInfoRow(
                      icon: Icons.attach_file_outlined,
                      label: "Document",
                      value: "Uploaded",
                      colorScheme: colorScheme,
                      trailing: IconButton(
                        icon: Icon(Icons.open_in_new, size: 18, color: colorScheme.primary),
                        tooltip: "View document",
                        onPressed: () {
                          // TODO: Open document URL
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Modules Section
          _buildSectionHeader(
            icon: Icons.book_outlined,
            title: "Selected Modules",
            subtitle: "${application.moduleCount} module${application.moduleCount != 1 ? 's' : ''}",
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
              padding: const EdgeInsets.all(12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: application.modules.map((module) {
                  return Chip(
                    avatar: CircleAvatar(
                      backgroundColor: colorScheme.primaryContainer,
                      child: Text(
                        module.substring(0, 1),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                    label: Text(
                      module,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    backgroundColor: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.3)),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Action Buttons
          if (isPending) ...[
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Logic to navigate to Edit Form (Requirement 95)
                  Navigator.pushNamed(
                    context,
                    '/edit-application',
                    arguments: application,
                  );
                },
                icon: const Icon(Icons.edit_outlined),
                label: const Text(
                  "Edit Information",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: viewModel.isDeleting ? null : () => _confirmDelete(context),
                icon: Icon(Icons.delete_outline, color: colorScheme.error),
                label: Text(
                  "Delete Application",
                  style: TextStyle(
                    color: colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: colorScheme.error.withOpacity(0.5)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.lock_outline, size: 20, color: colorScheme.outline),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "This application is ${application.status} and cannot be modified.",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
        ],
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

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required ColorScheme colorScheme,
    Widget? trailing,
  }) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}

