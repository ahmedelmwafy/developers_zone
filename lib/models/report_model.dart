import 'package:cloud_firestore/cloud_firestore.dart';

class ReportModel {
  final String id;
  final String postId;
  final String reporterId;
  final String reason;
  final DateTime createdAt;

  ReportModel({
    required this.id,
    required this.postId,
    required this.reporterId,
    required this.reason,
    required this.createdAt,
  });

  factory ReportModel.fromMap(Map<String, dynamic> data, String docId) {
    return ReportModel(
      id: docId,
      postId: data['postId'] ?? '',
      reporterId: data['reporterId'] ?? '',
      reason: data['reason'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'postId': postId,
      'reporterId': reporterId,
      'reason': reason,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
