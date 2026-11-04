class SafetyReport {
  final String id;
  final String reportedBy;
  final String? reportedUserId;
  final String? requestId;
  final String reason;
  final String details;
  final String status; // 'PENDING', 'INVESTIGATING', 'RESOLVED', 'DISMISSED'
  final String? adminAction;
  final DateTime createdAt;

  SafetyReport({
    required this.id,
    required this.reportedBy,
    this.reportedUserId,
    this.requestId,
    required this.reason,
    required this.details,
    this.status = 'PENDING',
    this.adminAction,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory SafetyReport.fromJson(Map<String, dynamic> json) {
    return SafetyReport(
      id: json['id'] as String? ?? '',
      reportedBy: json['reported_by'] as String? ?? '',
      reportedUserId: json['reported_user_id'] as String?,
      requestId: json['request_id'] as String?,
      reason: json['reason'] as String? ?? 'Suspicious Activity',
      details: json['details'] as String? ?? '',
      status: json['status'] as String? ?? 'PENDING',
      adminAction: json['admin_action'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reported_by': reportedBy,
      'reported_user_id': reportedUserId,
      'request_id': requestId,
      'reason': reason,
      'details': details,
      'status': status,
      'admin_action': adminAction,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
