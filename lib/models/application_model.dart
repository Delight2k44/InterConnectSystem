import 'package:flutter/foundation.dart';

class StudentApplication {
  final String? id;
  final String userId;
  final String yearOfStudy;
  final List<String> modules;
  final String status;
  final String documentPath;
  final DateTime createdAt;

  const StudentApplication({
    this.id,
    required this.userId,
    required this.yearOfStudy,
    required this.modules,
    required this.status,
    required this.documentPath,
    required this.createdAt,
  });


  // ─── Computed Properties ───

  /// Whether this application is awaiting review
  bool get isPending => status.toLowerCase() == 'pending';

  /// Whether this application has been approved
  bool get isApproved => status.toLowerCase() == 'approved';

  /// Whether this application has been rejected
  bool get isRejected => status.toLowerCase() == 'rejected';


  /// Whether this is a new unsaved application
  bool get isNew => id == null || id!.isEmpty;

  /// Whether a document has been uploaded
  bool get hasDocument => documentPath.isNotEmpty;


  /// Human-readable status label with capitalization
  String get statusLabel {
    if (status.isEmpty) return 'Unknown';
    return status[0].toUpperCase() + status.substring(1);
  }

  /// Total number of selected modules
  int get moduleCount => modules.length;

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    return '${diff.inMinutes}m ago';
  }

  String get formattedDate => "${createdAt.day}/${createdAt.month}/${createdAt.year}";


  // ─── Factory Constructors ───

  factory StudentApplication.fromMap(Map<String, dynamic> map) {
    return StudentApplication(
      id: map['id'],
      // MATCH THESE TO YOUR DB COLUMNS EXACTLY:
      userId: map['user_id'] ?? '',
      yearOfStudy: map['year_of_study'] ?? '',
      // 'modules' is a JSON array in your DB, so we cast it:
      modules: List<String>.from(map['modules'] ?? []),
      status: map['status'] ?? 'pending',
      documentPath: map['document_path'] ?? '',
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : DateTime.now(),
    );
  }


  /// Create from Supabase with default fallback values (for partial data)
  factory StudentApplication.fromMapSafe(Map<String, dynamic> map) {
    return StudentApplication(
      id: map['id']?.toString(),
      userId: map['user_id']?.toString() ?? '',
      yearOfStudy: map['year_of_study']?.toString() ?? '',
      modules:
          (map['modules'] as List?)?.map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).toList() ?? const [],
      status: map['status']?.toString() ?? 'pending',
      documentPath: map['document_path']?.toString() ?? '',
      createdAt: map['created_at'] != null
          ? (map['created_at'] is DateTime
              ? map['created_at']
              : DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now())
          : DateTime.now(),
    );
  }


  // ─── Serialization ───

  Map<String, dynamic> toMap({bool includeId = false}) {
    final map = <String, dynamic>{
      'user_id': userId,
      'year_of_study': yearOfStudy,
      'modules': modules,
      'status': status,
      'document_path': documentPath,
      'created_at': createdAt.toIso8601String(),
    };


    if (includeId && id != null) {
      map['id'] = id;
    }

    return map;
  }

  /// Convert to map for Supabase insert (excludes id, lets DB generate it)
  Map<String, dynamic> toInsertMap() => toMap(includeId: false);

  /// Convert to map for Supabase update (includes id for WHERE clause)
  Map<String, dynamic> toUpdateMap() => toMap(includeId: true);

  // ─── Copy & Update ───

  /// Create a copy with optional field changes
  StudentApplication copyWith({
    ValueGetter<String?>? id,
    String? userId,
    String? yearOfStudy,
    List<String>? modules,
    String? status,
    String? documentPath,
    DateTime? createdAt,
  }) {
    return StudentApplication(
      id: id != null ? id() : this.id,
      userId: userId ?? this.userId,
      yearOfStudy: yearOfStudy ?? this.yearOfStudy,
      modules: modules ?? this.modules,
      status: status ?? this.status,
      documentPath: documentPath ?? this.documentPath,
      createdAt: createdAt ?? this.createdAt,
    );
  }


  /// Create a copy with updated status
  StudentApplication withStatus(String newStatus) => copyWith(status: newStatus);

  /// Create a copy with added module (if not already present)
  StudentApplication addModule(String module) {
    if (modules.contains(module)) return this;
    return copyWith(modules: [...modules, module]);
  }

  /// Create a copy with removed module
  StudentApplication removeModule(String module) {
    return copyWith(modules: modules.where((m) => m != module).toList());
  }

  /// Create a copy with document path
  StudentApplication withDocument(String path) => copyWith(documentPath: path);

  /// Create a copy with cleared document
  StudentApplication clearDocument() => copyWith(documentPath: '');


  // ─── Equality & Debug ───

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StudentApplication &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userId == other.userId &&
          yearOfStudy == other.yearOfStudy &&
          listEquals(modules, other.modules) &&
          status == other.status;

  @override
  int get hashCode => Object.hash(
        id,
        userId,
        yearOfStudy,
        Object.hashAll(modules),
        status,
      );

  @override
  String toString() {
    return 'StudentApplication(id: $id, status: $status, yearOfStudy: $yearOfStudy, modules: $moduleCount, hasDocument: $hasDocument)';
  }

  // ─── Private Helpers ───

  static String _monthName(int month) {
    const names = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return names[month - 1];
  }

  static String _formatTimeAgo(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        if (diff.inMinutes < 1) return 'Just now';
        return '${diff.inMinutes}m ago';
      }
      return '${diff.inHours}h ago';
    }
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}mo ago';

    final years = (diff.inDays / 365).floor();
    return '${years}y ago';
  }
}

