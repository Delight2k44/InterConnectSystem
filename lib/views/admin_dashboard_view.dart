import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/application_model.dart';
import '../viewmodels/admin_viewmodel.dart';


class AdminDashboardView extends StatefulWidget {
  const AdminDashboardView({super.key});

  @override
  State<AdminDashboardView> createState() => _AdminDashboardViewState();
}

class _AdminDashboardViewState extends State<AdminDashboardView> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<AdminViewModel>().fetchAllApplications());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showStatusSnackBar(String message, {bool isError = false}) {
    final colorScheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: isError ? colorScheme.onErrorContainer : colorScheme.onPrimaryContainer,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? colorScheme.errorContainer : colorScheme.primaryContainer,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _handleApprove(String appId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _buildConfirmDialog(
        title: 'Approve Application',
        content: 'Are you sure you want to approve this application?',
        confirmColor: Colors.green,
        icon: Icons.check_circle,
      ),
    );

    if (confirmed == true) {
      final viewModel = context.read<AdminViewModel>();
      final success = await viewModel.approveApplication(appId);
      if (success && mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 64,
                ),
                const SizedBox(height: 16),
                const Text(
                  "Success!",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "The application status has been updated to Approved.",
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: const Text("Done"),
                  ),
                ),
              ],
            ),
          ),
        );
      } else if (mounted && viewModel.errorMessage != null) {
        _showStatusSnackBar(viewModel.errorMessage!, isError: true);
      }
    }
  }

  Future<void> _handleReject(String appId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _buildConfirmDialog(
        title: 'Reject Application',
        content: 'Are you sure you want to reject this application? This action cannot be undone.',
        confirmColor: Colors.red,
        icon: Icons.cancel,
      ),
    );

    if (confirmed == true) {
      final viewModel = context.read<AdminViewModel>();
      final success = await viewModel.rejectApplication(appId);
      if (success && mounted) {
        _showStatusSnackBar('Application rejected');
      } else if (mounted && viewModel.errorMessage != null) {
        _showStatusSnackBar(viewModel.errorMessage!, isError: true);
      }
    }
  }

  Widget _buildConfirmDialog({
    required String title,
    required String content,
    required Color confirmColor,
    required IconData icon,
  }) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      icon: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(color: confirmColor.withOpacity(0.1), shape: BoxShape.circle),
        child: Icon(icon, color: confirmColor, size: 28),
      ),
      title: Text(title),
      content: Text(content),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context, false),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Cancel'),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: confirmColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Confirm', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AdminViewModel>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        title: const Text('Admin Dashboard', style: TextStyle(fontWeight: FontWeight.w600)),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            tooltip: 'Refresh applications',
            onPressed: viewModel.isLoading ? null : () => viewModel.fetchAllApplications(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          _buildStatsCards(viewModel, colorScheme),
          _buildSearchFilterBar(viewModel, colorScheme),
          Expanded(
            child: viewModel.isLoading
                ? const Center(child: CircularProgressIndicator())
                : viewModel.filteredApplications.isEmpty
                    ? _buildEmptyState(viewModel, colorScheme, theme)
                    : RefreshIndicator(
                        onRefresh: () => viewModel.fetchAllApplications(),
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: viewModel.filteredApplications.length,
                          itemBuilder: (context, index) {
                            final app = viewModel.filteredApplications[index];
                            return _ApplicationCard(
                              application: app,
                              onApprove: () => _handleApprove(app.id!),
                              onReject: () => _handleReject(app.id!),
                              onReview: () => _showAppDetails(context, app),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards(AdminViewModel viewModel, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          _StatCard(
            label: 'Total',
            value: viewModel.totalCount,
            color: colorScheme.primary,
            icon: Icons.folder_outlined,
          ),
          const SizedBox(width: 12),
          _StatCard(
            label: 'Pending',
            value: viewModel.pendingCount,
            color: colorScheme.primary,
            icon: Icons.pending_outlined,
          ),
          const SizedBox(width: 12),
          _StatCard(
            label: 'Approved',
            value: viewModel.approvedCount,
            color: Colors.green,
            icon: Icons.check_circle_outlined,
          ),
          const SizedBox(width: 12),
          _StatCard(
            label: 'Rejected',
            value: viewModel.rejectedCount,
            color: Colors.red,
            icon: Icons.cancel_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchFilterBar(AdminViewModel viewModel, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: viewModel.setSearchQuery,
            decoration: InputDecoration(
              hintText: 'Search by module, year, or status...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        viewModel.clearFilters();
                      },
                    )
                  : null,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colorScheme.outlineVariant),
              ),
              filled: true,
              fillColor: colorScheme.surface,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ApplicationFilter.values.map((filter) {
                final isSelected = viewModel.currentFilter == filter;
                final label = filter.name[0].toUpperCase() + filter.name.substring(1);
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(label),
                    selected: isSelected,
                    onSelected: (_) => viewModel.setFilter(filter),
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    selectedColor: colorScheme.primaryContainer,
                    checkmarkColor: colorScheme.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AdminViewModel viewModel, ColorScheme colorScheme, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: colorScheme.outline),
          const SizedBox(height: 16),
          Text(
            viewModel.searchQuery.isNotEmpty ? 'No matching applications' : 'No applications found',
            style: theme.textTheme.titleMedium?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
          if (viewModel.searchQuery.isNotEmpty)
            TextButton(
              onPressed: viewModel.clearFilters,
              child: const Text('Clear filters'),
            ),
        ],
      ),
    );
  }

  void _showAppDetails(BuildContext context, StudentApplication app) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _getStatusColor(app.status, colorScheme).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getStatusIcon(app.status),
                        color: _getStatusColor(app.status, colorScheme),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Application Review',
                            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            'Submitted ${app.timeAgo}',
                            style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _getStatusColor(app.status, colorScheme).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getStatusIcon(app.status),
                        size: 16,
                        color: _getStatusColor(app.status, colorScheme),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        app.status.toUpperCase(),
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: _getStatusColor(app.status, colorScheme),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                _buildDetailSection(
                  'Academic Information',
                  [
                    _buildDetailRow(Icons.school_outlined, 'Year of Study', app.yearOfStudy),
                    _buildDetailRow(Icons.calendar_today_outlined, 'Submitted On', app.formattedDate),
                  ],
                  colorScheme,
                ),
                const SizedBox(height: 20),

                _buildDetailSection(
                  'Selected Modules',
                  [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: app.modules.map((module) {
                        return Chip(
                          label: Text(module),
                          backgroundColor: colorScheme.secondaryContainer,
                          side: BorderSide.none,
                        );
                      }).toList(),
                    ),
                  ],
                  colorScheme,
                ),
                const SizedBox(height: 20),

                if (app.hasDocument) ...[
                  _buildDetailSection(
                    'Documentation',
                    [
                      ElevatedButton.icon(
                        onPressed: () {
                          if (app.documentPath.isNotEmpty) {
                            html.window.open(app.documentPath, '_blank');
                          } else {
                            _showStatusSnackBar(
                              'No document found for this application',
                              isError: true,
                            );
                          }
                        },
                        icon: const Icon(Icons.open_in_new),
                        label: const Text('View Supporting Document'),
                        style: ElevatedButton.styleFrom(

                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                      ),
                    ],
                    colorScheme,
                  ),
                  const SizedBox(height: 24),
                ],

                if (app.isPending) ...[
                  const Divider(),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _handleApprove(app.id!);
                          },
                          icon: const Icon(Icons.check),
                          label: const Text('Approve'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _handleReject(app.id!);
                          },
                          icon: const Icon(Icons.close),
                          label: const Text('Reject'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurfaceVariant,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
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
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
                Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status, ColorScheme colorScheme) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
      default:
        return colorScheme.primary;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      case 'pending':
      default:
        return Icons.pending;
    }
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Icon(icon, size: 18, color: color),
                ),
                const Spacer(),
                Text(
                  value.toString(),
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: color),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  final StudentApplication application;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onReview;

  const _ApplicationCard({
    required this.application,
    required this.onApprove,
    required this.onReject,
    required this.onReview,
  });

  Color _getStatusColor(ColorScheme colorScheme) {
    switch (application.status) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
      default:
        return colorScheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final statusColor = _getStatusColor(colorScheme);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: InkWell(
        onTap: onReview,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      application.isApproved ? Icons.check : application.isRejected ? Icons.close : Icons.pending,
                      color: statusColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Student ID: ${application.userId}',

                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          application.timeAgo,
                          style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                    child: Text(
                      application.status.toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: application.modules.map((module) {
                  return Chip(
                    label: Text(module, style: theme.textTheme.labelSmall),
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    side: BorderSide.none,
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.school_outlined, size: 16, color: colorScheme.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Text(
                    application.yearOfStudy,
                    style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                  const Spacer(),
                  if (application.isPending) ...[
                    _ActionButton(
                      icon: Icons.check,
                      color: Colors.green,
                      tooltip: 'Approve',
                      onPressed: onApprove,
                    ),
                    const SizedBox(width: 8),
                    _ActionButton(
                      icon: Icons.close,
                      color: Colors.red,
                      tooltip: 'Reject',
                      onPressed: onReject,
                    ),
                  ] else
                    TextButton.icon(
                      onPressed: onReview,
                      icon: const Icon(Icons.visibility_outlined, size: 18),
                      label: const Text('Review'),
                      style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12)),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            child: Icon(icon, size: 18, color: color),
          ),
        ),
      ),
    );
  }
}

